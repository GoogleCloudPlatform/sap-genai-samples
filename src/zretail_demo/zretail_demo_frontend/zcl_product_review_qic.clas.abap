CLASS zcl_product_review_qic DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      BEGIN OF t_product_review,
        entity_id         TYPE string,
        last_updated      TYPE string,
        product_id        TYPE string,
        review_text       TYPE string,
        product_rating    TYPE i,
        feature_timestamp TYPE string,
      END OF t_product_review.

    INTERFACES if_rap_query_provider .
  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.



CLASS ZCL_PRODUCT_REVIEW_QIC IMPLEMENTATION.


  METHOD if_rap_query_provider~select.

    DATA lt_data   TYPE STANDARD TABLE OF zce_product_reviews.
    DATA(lv_top)  = io_request->get_paging( )->get_page_size( ).
    DATA(lv_skip) = io_request->get_paging( )->get_offset( ).
    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA(ld_is_data_requested) = io_request->is_data_requested( ).
    DATA(lt_sort_order) = CORRESPONDING abap_sortorder_tab( io_request->get_sort_elements( ) MAPPING name = element_name ).

    DATA(lt_filter) = io_request->get_filter( )->get_as_ranges( ).

    DATA(lv_product_id) = VALUE #( lt_filter[ name = 'PRODUCTID' ]-range[ 1 ]-low OPTIONAL ).

    DATA: lo_bq_client TYPE REF TO /goog/cl_bigquery_v2.
    DATA: ls_input_bq TYPE /goog/cl_bigquery_v2=>ty_103.



    IF lv_product_id IS NOT INITIAL.

      TRY .
          CREATE OBJECT lo_bq_client
            EXPORTING
              iv_key_name = 'RETAIL_DEMO'.
          ls_input_bq-query  = |SELECT * FROM gcpsaptesting.epm_shop.product_reviews_sap WHERE product_id = '{ lv_product_id }'|.

          CALL METHOD lo_bq_client->query_jobs
            EXPORTING
              iv_p_projects_id = CONV #( lo_bq_client->gv_project_id )
              is_input         = ls_input_bq
            IMPORTING
              es_output        = DATA(ls_output).

          DATA(lv_index) = 0.
          LOOP AT ls_output-rows REFERENCE INTO DATA(ls_rows).
            lv_index = lv_index + 1.
            DATA(ls_product_review) = VALUE t_product_review( ).
            LOOP AT ls_rows->f ASSIGNING FIELD-SYMBOL(<ls_field>).
              DATA(lv_tabix_field) = sy-tabix.
              ASSIGN COMPONENT lv_tabix_field OF STRUCTURE ls_product_review
              TO FIELD-SYMBOL(<ls_target_field>).

              IF <ls_field>-v IS BOUND AND
                 <ls_target_field> IS ASSIGNED.
                <ls_target_field> = <ls_field>-v->*.
              ENDIF.

            ENDLOOP.

            APPEND VALUE #( productid = ls_product_review-product_id
                            reviewno = lv_index
                            reviewtext = ls_product_review-review_text
                            rating = ls_product_review-product_rating
               )
              TO  lt_data.
          ENDLOOP.

        CATCH cx_root.

      ENDTRY.
    ENDIF.

    DATA(lv_max_index) = 0.
    IF lv_top IS NOT INITIAL.
      lv_max_index = lv_top + lv_skip.
    ENDIF.

    IF lines( lt_data ) > lv_max_index.
      DELETE lt_data FROM lv_max_index.
    ENDIF.

    IF lv_skip IS NOT INITIAL.
      DELETE lt_data TO lv_skip.
    ENDIF.

    io_response->set_total_number_of_records( lines( lt_data ) ).
    io_response->set_data( lt_data ).


  ENDMETHOD.
ENDCLASS.
