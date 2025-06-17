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
REPORT zdemo_load_product_data_to_bq.

SELECT a~product_id,
  SUM( b~quantity ) AS stock_quantity,
  b~quantity_unit AS quantity_unit,
  c~text AS product_name,
  MAX( d~id ) AS imageid
  FROM snwd_pd AS a
  INNER JOIN snwd_stock AS b
  ON b~product_guid = a~node_key
  INNER JOIN snwd_texts AS c
  ON c~parent_key = a~name_guid
  LEFT OUTER JOIN sepmracshimage AS d
  ON a~product_id = d~productid
  INTO TABLE @DATA(lt_product)
  WHERE c~language = 'E'
  GROUP BY a~product_id, b~quantity_unit, c~text.


DATA(lo_client) =
NEW /goog/cl_bigquery_v2( iv_key_name = 'ABAP_SDK_DEMO' ).

DATA:
  lv_p_dataset_id TYPE string,
  lv_p_project_id TYPE string,
  lv_p_table_id   TYPE string,
  ls_input        TYPE /goog/cl_bigquery_v2=>ty_133.


TYPES:
  BEGIN OF t_product,
    entity_id         TYPE string,
    last_updated      TYPE string,
    product_id        TYPE string,
    product_rating    TYPE string,
    stock_quantity    TYPE string,
    quantity_unit     TYPE string,
    product_name      TYPE string,
    imageid           TYPE string,
    feature_timestamp TYPE string,
  END OF t_product.


TYPES:
  BEGIN OF t_reviews,
    product_id  TYPE snwd_product_id,
    sentiment   TYPE string,
    rating_text TYPE snwd_rating_text,
  END OF t_reviews,

  tt_reviews TYPE STANDARD TABLE OF t_reviews WITH DEFAULT KEY.


LOOP AT lt_product INTO DATA(ls_product).


  APPEND INITIAL LINE TO ls_input-rows ASSIGNING FIELD-SYMBOL(<ls_row>).
  CREATE DATA <ls_row>-json TYPE t_product.
  FIELD-SYMBOLS: <lfs_json> TYPE t_product.
  ASSIGN <ls_row>-json->* TO <lfs_json> CASTING.
  MOVE-CORRESPONDING ls_product TO  <lfs_json>.
  <lfs_json>-entity_id = ls_product-product_id.

  <lfs_json>-feature_timestamp = sy-datum && sy-uzeit.

  CONCATENATE <lfs_json>-feature_timestamp+0(4)  '-' <lfs_json>-feature_timestamp+4(2)  '-'
                  <lfs_json>-feature_timestamp+6(2)  'T' <lfs_json>-feature_timestamp+8(2)  ':'
                  <lfs_json>-feature_timestamp+10(2) ':' <lfs_json>-feature_timestamp+12(2) '.' '0000000Z'
             INTO <lfs_json>-feature_timestamp.

  <lfs_json>-last_updated = <lfs_json>-feature_timestamp.

  PERFORM f_get_product_rating USING ls_product-product_id
                                     lo_client
                               CHANGING <lfs_json>-product_rating.

ENDLOOP.

lo_client->add_json_name_mapping( iv_abap = 'ENTITY_ID' iv_json = 'entity_id' ).
lo_client->add_json_name_mapping( iv_abap = 'PRODUCT_ID' iv_json = 'product_id' ).
lo_client->add_json_name_mapping( iv_abap = 'PRODUCT_NAME' iv_json = 'product_name' ).
lo_client->add_json_name_mapping( iv_abap = 'FEATURE_TIMESTAMP' iv_json = 'feature_timestamp' ).
lo_client->add_json_name_mapping( iv_abap = 'STOCK_QUANTITY' iv_json = 'stock_quantity' ).
lo_client->add_json_name_mapping( iv_abap = 'QUANTITY_UNIT' iv_json = 'quantity_unit' ).
lo_client->add_json_name_mapping( iv_abap = 'LAST_UPDATED' iv_json = 'last_updated' ).
lo_client->add_json_name_mapping( iv_abap = 'PRODUCT_RATING' iv_json = 'product_rating' ).

CALL METHOD lo_client->insert_all_tabledata
  EXPORTING
    iv_p_dataset_id = 'epm_shop'
    iv_p_project_id = 'your-project-id'
    iv_p_table_id   = 'product_info_sap'
    is_input        = ls_input
  IMPORTING
*   es_raw          =
    es_output       = DATA(ls_output)
    ev_ret_code     = DATA(lv_ret_code)
    ev_err_text     = DATA(lv_err_text)
    es_err_resp     = DATA(ls_err_resp).

* Close HTTP Connection
lo_client->close( ).
*&---------------------------------------------------------------------*
*& Form f_get_product_rating
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
FORM f_get_product_rating USING iv_product_id TYPE snwd_product_id
                                io_client TYPE REF TO /goog/cl_bigquery_v2
                          CHANGING cv_rating TYPE string.

  DATA lo_client          TYPE REF TO /goog/cl_aiplatform_v1.
  DATA lv_p_projects_id   TYPE string.
  DATA lv_p_locations_id  TYPE string.
  DATA lv_p_publishers_id TYPE string.
  DATA lv_p_models_id     TYPE string.
  DATA ls_input           TYPE /goog/cl_aiplatform_v1=>ty_726.
  DATA ls_raw             TYPE REF TO data.
  DATA ls_output          TYPE /goog/cl_aiplatform_v1=>ty_727.
  DATA lv_ret_code        TYPE i.
  DATA lv_err_text        TYPE string.
  DATA ls_err_resp        TYPE /goog/err_resp.
  DATA lv_msg             TYPE string.
  DATA lo_exception       TYPE REF TO /goog/cx_sdk.
  DATA es_raw             TYPE string.

  DATA lt_reviews TYPE STANDARD TABLE OF t_reviews WITH DEFAULT KEY.

  FIELD-SYMBOLS <fs_review> TYPE t_reviews.

  TRY.

      " Open HTTP Connection
      lo_client = NEW #( iv_key_name = 'ABAP_SDK_DEMO' ).

      " Populate relevant parameters
      lv_p_projects_id = lo_client->gv_project_id.
      lv_p_locations_id = 'us-central1'.
      lv_p_publishers_id = 'google'.
      lv_p_models_id = 'gemini-2.0-pro'.

      SELECT a~product_id AS product_id c~rating_text
        FROM ( ( snwd_pd AS a
        INNER JOIN snwd_rev_head AS b ON a~node_key = b~entity_key )
        INNER JOIN snwd_rev_item AS c ON b~node_key = c~parent_key )
        INTO CORRESPONDING FIELDS OF TABLE lt_reviews
        WHERE product_id = iv_product_id.

      DATA: lv_rating_tot TYPE i.
      LOOP AT lt_reviews ASSIGNING <fs_review>.

        " Construct the prompt
        DATA(lv_prompt) = |DO NOT EXPLAIN and your response should not have more than one word.| &&
                          |Generare the overall product rating based on the following user reviews as ONLY ONE of| &&
                          | the following: 1, 2, 3, 4, 5. Rating Scale: 1 = Poor · 2 = Fair · 3 = Good · 4 = Very Good · 5 = Excellent. | &&
                          cl_abap_char_utilities=>newline &&
                          'Review text: ' && <fs_review>-rating_text.

        " Set the Model Parameters and Prompt
        ls_input = VALUE #( generation_config = VALUE #( max_output_tokens = 10
                                                         temperature       = '0.2'
                                                         top_p             = '0.8'
                                                         top_k             = '40' )
                            contents          = VALUE #( ( role  = 'user'
                                                           parts = VALUE #( ( text = lv_prompt ) ) ) ) ).


        " Call Gemini Pro to identify sentiments.
        lo_client->generate_content_models( EXPORTING iv_p_projects_id   = lv_p_projects_id
                                                          iv_p_locations_id  = lv_p_locations_id
                                                          iv_p_publishers_id = lv_p_publishers_id
                                                          iv_p_models_id     = lv_p_models_id
                                                          is_input           = ls_input
                                                IMPORTING es_raw             = es_raw
                                                          es_output          = ls_output
                                                          ev_ret_code        = lv_ret_code
                                                          ev_err_text        = lv_err_text
                                                          es_err_resp        = ls_err_resp ).


        IF lo_client->is_success( lv_ret_code ) = abap_true.

          LOOP AT ls_output-candidates INTO DATA(ls_candidate).
            LOOP AT ls_candidate-content-parts INTO DATA(ls_part).

              <fs_review>-sentiment = ls_part-text.
              lv_rating_tot = lv_rating_tot + ls_part-text.
              EXIT.
            ENDLOOP.
            EXIT.
          ENDLOOP.

        ELSE.
          MESSAGE lv_err_text TYPE 'E'.
        ENDIF.

      ENDLOOP.

      PERFORM f_save_review_bq USING lt_reviews
                                     io_client.

      " Close HTTP Connection
      lo_client->close( ).

    CATCH /goog/cx_sdk INTO lo_exception.
      lv_msg = lo_exception->get_text( ).
      MESSAGE lv_msg TYPE 'E'.
  ENDTRY.

  DATA: lv_lines TYPE i.

  lv_lines = lines( lt_reviews ).

  DATA: lv_rating TYPE i.
  IF lv_lines > 0.
    lv_rating = lv_rating_tot / lv_lines.
  ENDIF.

  cv_rating = lv_rating.
  IF cv_rating IS INITIAL.
    cv_rating = '0'.
  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form f_save_review_bq
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
FORM f_save_review_bq  USING pt_review TYPE tt_reviews
                             io_client TYPE REF TO /goog/cl_bigquery_v2.

  DATA:
    lv_p_dataset_id TYPE string,
    lv_p_project_id TYPE string,
    lv_p_table_id   TYPE string,
    ls_input        TYPE /goog/cl_bigquery_v2=>ty_133.

  TYPES:
    BEGIN OF t_product_review,
      entity_id         TYPE string,
      last_updated      TYPE string,
      product_id        TYPE string,
      review_text       TYPE string,
      product_rating    TYPE i,
      feature_timestamp TYPE string,
    END OF t_product_review.


  LOOP AT pt_review INTO DATA(ls_review).


    APPEND INITIAL LINE TO ls_input-rows ASSIGNING FIELD-SYMBOL(<ls_row>).
    CREATE DATA <ls_row>-json TYPE t_product_review.
    FIELD-SYMBOLS: <lfs_json> TYPE t_product_review.
    ASSIGN <ls_row>-json->* TO <lfs_json> CASTING.
    MOVE-CORRESPONDING ls_review TO  <lfs_json>.
    <lfs_json>-entity_id = ls_review-product_id.

    <lfs_json>-feature_timestamp = sy-datum && sy-uzeit.

    CONCATENATE <lfs_json>-feature_timestamp+0(4)  '-' <lfs_json>-feature_timestamp+4(2)  '-'
                    <lfs_json>-feature_timestamp+6(2)  'T' <lfs_json>-feature_timestamp+8(2)  ':'
                    <lfs_json>-feature_timestamp+10(2) ':' <lfs_json>-feature_timestamp+12(2) '.' '0000000Z'
               INTO <lfs_json>-feature_timestamp.

    <lfs_json>-last_updated = <lfs_json>-feature_timestamp.
    <lfs_json>-product_rating = ls_review-sentiment.
    <lfs_json>-review_text = ls_review-rating_text.

  ENDLOOP.

  io_client->add_json_name_mapping( iv_abap = 'ENTITY_ID' iv_json = 'entity_id' ).
  io_client->add_json_name_mapping( iv_abap = 'PRODUCT_ID' iv_json = 'product_id' ).
  io_client->add_json_name_mapping( iv_abap = 'FEATURE_TIMESTAMP' iv_json = 'feature_timestamp' ).
  io_client->add_json_name_mapping( iv_abap = 'LAST_UPDATED' iv_json = 'last_updated' ).
  io_client->add_json_name_mapping( iv_abap = 'PRODUCT_RATING' iv_json = 'product_rating' ).
  io_client->add_json_name_mapping( iv_abap = 'REVIEW_TEXT' iv_json = 'review_text' ).

  CALL METHOD io_client->insert_all_tabledata
    EXPORTING
      iv_p_dataset_id = 'epm_shop'
      iv_p_project_id = 'your-project-id'
      iv_p_table_id   = 'product_reviews_sap'
      is_input        = ls_input
    IMPORTING
*     es_raw          =
      es_output       = DATA(ls_output)
      ev_ret_code     = DATA(lv_ret_code)
      ev_err_text     = DATA(lv_err_text)
      es_err_resp     = DATA(ls_err_resp).

ENDFORM.
