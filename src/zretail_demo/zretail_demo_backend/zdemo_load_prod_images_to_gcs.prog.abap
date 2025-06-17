**********************************************************************
*  Copyright 2024 Google LLC                                         *
*                                                                    *
*  Licensed under the Apache License, Version 2.0 (the "License");   *
*  you may not use this file except in compliance with the License.  *
*  You may obtain a copy of the License at                           *
*      https://www.apache.org/licenses/LICENSE-2.0                   *
*  Unless required by applicable law or agreed to in writing,        *
*  software distributed under the License is distributed on an       *
*  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,      *
*  either express or implied.                                        *
*  See the License for the specific language governing permissions   *
*  and limitations under the License.                                *
**********************************************************************
REPORT zdemo_load_prod_images_to_gcs.


TYPES:
  BEGIN OF t_product_meta,
    product_id   TYPE snwd_product_id,
    stock        TYPE snwd_quantity,
    product_name TYPE snwd_desc,
  END OF t_product_meta.

DATA: lo_http TYPE REF TO if_http_client.

cl_http_client=>create_internal(
  IMPORTING client = lo_http ).


SELECT a~product_id,
  SUM( b~quantity ) AS stock,
  c~text AS product_name
  FROM snwd_pd AS a
  INNER JOIN snwd_stock AS b
  ON b~product_guid = a~node_key
  INNER JOIN snwd_texts AS c
  ON c~parent_key = a~name_guid
  INTO TABLE @DATA(lt_product_meta)
  GROUP BY a~product_id, c~text.

SELECT product_id,
       product_pic_url
  FROM snwd_pd
  INTO TABLE @DATA(lt_product).

LOOP AT lt_product REFERENCE INTO DATA(ls_product).

  cl_http_utility=>set_request_uri(
    request = lo_http->request
    uri     = CONV #( ls_product->product_pic_url ) ).

  lo_http->request->set_method( EXPORTING method = 'GET' ).

  CALL METHOD lo_http->send
    EXCEPTIONS
      http_communication_failure = 1
      http_invalid_state         = 2
      http_processing_failed     = 3
      http_invalid_timeout       = 4
      OTHERS                     = 5.

  CALL METHOD lo_http->receive
    EXCEPTIONS
      http_communication_failure = 1
      http_invalid_state         = 2
      http_processing_failed     = 3
      OTHERS                     = 4.

  lo_http->response->get_status( IMPORTING code = DATA(lv_http_return_code) ).
  lo_http->response->get_status( IMPORTING reason = DATA(lv_http_error_descr) ).


*   Response
  DATA(lv_json_result_str) = lo_http->response->get_cdata( ).
  DATA(lv_result_xstring) = lo_http->response->get_data( ).

  DATA: lv_name TYPE string.

  lv_name = ls_product->product_id && '.jpg'.
  CONDENSE lv_name NO-GAPS.

  DATA: ls_product_meta TYPE t_product_meta.
  READ TABLE lt_product_meta INTO ls_product_meta
   WITH KEY Product_id = ls_product->product_id.

  PERFORM f_insert_gcs USING ls_product_meta
                             lv_name lv_result_xstring.

ENDLOOP.



*&---------------------------------------------------------------------*
*& Form f_insert_gcs
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
FORM f_insert_gcs USING is_meta TYPE t_product_meta
                        iv_name TYPE string
                        iv_data TYPE xstring.



  DATA lv_file_length TYPE i.
  DATA lv_msg         TYPE string.
  DATA lv_dset        TYPE string.
  DATA lv_data        TYPE string.
  DATA ls_data        TYPE xstring.
  DATA lo_storage     TYPE REF TO /goog/cl_storage_v1.

  DATA ls_input TYPE  /goog/cl_storage_v1=>ty_013.

  TRY.

      lo_storage = NEW #( iv_key_name = 'ABAP_SDK_DEMO' ).

      GET REFERENCE OF is_meta INTO ls_input-metadata.

      lo_storage->insert_objects( EXPORTING iv_q_name       = iv_name
                                            iv_p_bucket     = 'your-gcs-bucket-name'
                                            is_input         =  ls_input
                                            is_data         = iv_data
                                            iv_content_type = 'image/jpeg'
                                  IMPORTING es_output       = DATA(ls_output)
                                            ev_ret_code     = DATA(lv_ret_code)
                                            ev_err_text     = DATA(lv_err_text)
                                            es_err_resp     = DATA(ls_err_resp) ).

    CATCH /goog/cx_sdk INTO DATA(lo_sdk_excp).
      lv_msg = lo_sdk_excp->get_text( ).
      MESSAGE lv_msg TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
  ENDTRY.

  lo_storage->close( ).

ENDFORM.
