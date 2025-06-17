CLASS zcl_product_search_qic DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      BEGIN OF t_product_attr,
        entity_id         TYPE string,
        last_updated      TYPE string,
        product_id        TYPE c LENGTH 10,
        product_rating    TYPE i,
        stock_quantity    TYPE string,
        quantity_unit     TYPE string,
        product_name      TYPE string,
        imageid           TYPE string,
        feature_timestamp TYPE string,
      END OF t_product_attr,

      BEGIN OF t_product_distance,
        product_id        TYPE c LENGTH 10,
        distance          TYPE string,
      END OF t_product_distance,

      tt_product_distance TYPE HASHED TABLE OF t_product_distance WITH UNIQUE KEY product_id,

      tt_product_attr TYPE HASHED TABLE OF t_product_attr WITH UNIQUE KEY product_id.

      CONSTANTS: c_q TYPE c VALUE `'`.

    INTERFACES if_rap_query_provider .
  PROTECTED SECTION.
private section.

  methods GET_TABLE_DEF
    importing
      !IO_CLIENT type ref to /GOOG/CL_BIGQUERY_V2
    exporting
      !ES_DEF type /GOOG/CL_BIGQUERY_V2=>TY_131
    returning
      value(RV_DEF) type STRING .
  methods GET_SQL_FOR_ATTR_SEARCH
    importing
      !IV_PROMPT type STRING
    returning
      value(RV_QUERY) type STRING .
  methods GET_PRODUCT_ATTR
    importing
      !IO_CLIENT type ref to /GOOG/CL_BIGQUERY_V2
      !IV_PRODUCT_IDS type STRING
    returning
      value(RT_ATTR) type TT_PRODUCT_ATTR .
ENDCLASS.



CLASS ZCL_PRODUCT_SEARCH_QIC IMPLEMENTATION.


  METHOD get_product_attr.

    DATA: ls_input_bq TYPE /goog/cl_bigquery_v2=>ty_103.

    TRY.
        ls_input_bq-query  = |SELECT * from `{ io_client->gv_project_id }.epm_shop.product_info_sap`|.
        IF iv_product_ids IS NOT INITIAL.
          ls_input_bq-query = ls_input_bq-query && | WHERE PRODUCT_ID IN ( { iv_product_ids } )|.
        ENDIF.

        CALL METHOD io_client->query_jobs
          EXPORTING
            iv_p_projects_id = CONV #( io_client->gv_project_id )
            is_input         = ls_input_bq
          IMPORTING
            es_output        = DATA(ls_output).

        LOOP AT ls_output-rows REFERENCE INTO DATA(ls_rows).
          DATA(ls_product_attr) = VALUE t_product_attr( ).
          LOOP AT ls_rows->f ASSIGNING FIELD-SYMBOL(<ls_field>).
            DATA(lv_tabix_field) = sy-tabix.
            ASSIGN COMPONENT lv_tabix_field OF STRUCTURE ls_product_attr
            TO FIELD-SYMBOL(<ls_target_field>).

            IF <ls_field>-v IS BOUND AND
               <ls_target_field> IS ASSIGNED.
              <ls_target_field> = <ls_field>-v->*.
            ENDIF.

          ENDLOOP.

          INSERT ls_product_attr INTO TABLE rt_attr.
        ENDLOOP.


      CATCH /goog/cx_sdk.
    ENDTRY.

  ENDMETHOD.


  METHOD get_sql_for_attr_search.

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


    TRY.

        " Open HTTP Connection
        lo_client = NEW #( iv_key_name = 'RETAIL_DEMO' ).

        " Populate relevant parameters
        lv_p_projects_id = lo_client->gv_project_id.
        lv_p_locations_id = 'us-central1'.
        lv_p_publishers_id = 'google'.
        lv_p_models_id = 'gemini-1.5-pro-preview-0514'.


        " Set the Model Parameters and Prompt
        ls_input = VALUE #( generation_config = VALUE #( max_output_tokens = 8000
                                                         temperature       = '1'
                                                         top_p             = '0.8'
                                                         top_k             = '40' )
                            contents          = VALUE #( ( role  = 'user'
                                                           parts = VALUE #( ( text = iv_prompt ) ) ) ) ).


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
              rv_query = ls_part-text.
              REPLACE ALL OCCURRENCES OF 'sql' IN rv_query WITH space.
              REPLACE ALL OCCURRENCES OF '`' IN rv_query WITH space.
              REPLACE ALL OCCURRENCES OF '#' IN rv_query WITH space.
              EXIT.
            ENDLOOP.
            EXIT.
          ENDLOOP.
        ENDIF.


        " Close HTTP Connection
        lo_client->close( ).

      CATCH /goog/cx_sdk.
    ENDTRY.

  ENDMETHOD.


  METHOD get_table_def.

    TRY.

        CALL METHOD io_client->get_tables
          EXPORTING
            iv_p_datasets_id    = 'epm_shop'
            iv_p_projects_id    = CONV #( io_client->gv_project_id )
            iv_p_tables_id      = 'product_info_sap'
            iv_q_selectedfields = 'product_id,product_rating,stock_quantity'
          IMPORTING
            es_raw              = rv_def
            es_output           = es_def.

      CATCH /goog/cx_sdk .
    ENDTRY.


  ENDMETHOD.


METHOD if_rap_query_provider~select.

  DATA lt_data   TYPE STANDARD TABLE OF zce_product_read.
  DATA(lv_top)  = io_request->get_paging( )->get_page_size( ).
  DATA(lv_skip) = io_request->get_paging( )->get_offset( ).
  " TODO: variable is assigned but never used (ABAP cleaner)
  DATA(ld_is_data_requested) = io_request->is_data_requested( ).
  DATA(lt_sort_order) = CORRESPONDING abap_sortorder_tab( io_request->get_sort_elements( ) MAPPING name = element_name ).

  DATA(lt_filter) = io_request->get_filter( )->get_as_ranges( ).

  DATA(lv_vector_search) = VALUE #( lt_filter[ name = 'VECTORSEARCHSTRING' ]-range[ 1 ]-low OPTIONAL ).

  DATA: lo_bq_client TYPE REF TO /goog/cl_bigquery_v2.
  DATA: ls_input_bq TYPE /goog/cl_bigquery_v2=>ty_103.
  DATA: lt_product TYPE HASHED TABLE OF string WITH UNIQUE KEY table_line.
  DATA: lv_product_ids TYPE string.

  CREATE OBJECT lo_bq_client
    EXPORTING
      iv_key_name = 'RETAIL_DEMO'.


  IF lv_vector_search IS NOT INITIAL.
    lv_vector_search = substring( val = lv_vector_search
                                  off = 1
                                  len = strlen( lv_vector_search ) - 2  ).


    DATA(ls_table_def) = VALUE /goog/cl_bigquery_v2=>ty_131( ).

    DATA(lv_table_definition) =
       get_table_def( EXPORTING io_client = lo_bq_client
                      IMPORTING es_def    = ls_table_def ).

    IF ls_table_def-num_rows EQ 0.
      ls_table_def-num_rows = ls_table_def-streaming_buffer-estimated_rows.
    ENDIF.

    DATA(lv_gemini_prompt) =
      | ONLY GIVE SQL STATEMENT AS OUTPUT. Given Bigquery table definition '{ lv_table_definition }', | &&
      | generate SQL query to select product_id from the table for prompt '{ lv_vector_search }'. | &&
      | DO NOT ADD WHERE CLAUSE IF NO MATCHING CONDITIONS ARE FOUND IN PROMPT. | &&
      | Rating scale is 1 (Poor) to 5 (Excellent) | &&
      | Assume quanity 0 = Out of stock and > 0 = in stock |.

    TRY.

        ls_input_bq-query  = get_sql_for_attr_search( lv_gemini_prompt ).

        CALL METHOD lo_bq_client->query_jobs
          EXPORTING
            iv_p_projects_id = CONV #( lo_bq_client->gv_project_id )
            is_input         = ls_input_bq
          IMPORTING
            es_output        = DATA(ls_output_attr).

        LOOP AT ls_output_attr-rows REFERENCE INTO DATA(ls_rows_attr).

          LOOP AT ls_rows_attr->f ASSIGNING FIELD-SYMBOL(<ls_field_attr>).
            INSERT <ls_field_attr>-v->* INTO TABLE lt_product.
          ENDLOOP.

        ENDLOOP.

      CATCH /goog/cx_sdk.
    ENDTRY.

    IF lt_product IS INITIAL.
      io_response->set_total_number_of_records( 0 ).
      io_response->set_data( lt_data ).
      RETURN.
    ENDIF.


    DATA(lv_product_count) = lines( lt_product ).
    IF lt_product IS NOT INITIAL.
      DATA: lt_distance TYPE tt_product_distance.

      TRY.

          ls_input_bq-query           =
            | SELECT base.product_id, distance | &&
            | FROM VECTOR_SEARCH( | &&
            | TABLE `{ lo_bq_client->gv_project_id }.epm_shop.merch_store_embeddings`, 'ml_generate_embedding_result', | &&
            | ( | &&
            | SELECT ml_generate_embedding_result AS embedding_col | &&
            | FROM ML.GENERATE_EMBEDDING | &&
            | ( | &&
            | MODEL `{ lo_bq_client->gv_project_id }.epm_shop.mm_embedding`, | &&
            | (SELECT "{ lv_vector_search }" AS content), | &&
            | STRUCT(TRUE AS flatten_json_output) | &&
            | ) | &&
            | ) | &&
            | , top_k => { ls_table_def-num_rows } | &&
            | ); | .

          ls_input_bq-use_legacy_sql  = abap_false.
          ls_input_bq-use_query_cache = abap_false.

          ls_input_bq-default_dataset-dataset_id = 'epm_shop'.
          ls_input_bq-default_dataset-project_id =  lo_bq_client->gv_project_id.

          CALL METHOD lo_bq_client->query_jobs
            EXPORTING
              iv_p_projects_id = CONV #( lo_bq_client->gv_project_id )
              is_input         = ls_input_bq
            IMPORTING
              es_output        = DATA(ls_output_vector).

          LOOP AT ls_output_vector-rows REFERENCE INTO DATA(ls_rows_vector).

            DATA(ls_distance) = VALUE t_product_distance( ).
            LOOP AT ls_rows_vector->f ASSIGNING FIELD-SYMBOL(<ls_field_vector>).
              DATA(lv_index) = sy-tabix.

              IF lv_index = 1.
                IF NOT line_exists( lt_product[ table_line =  <ls_field_vector>-v->* ] ).
                  EXIT.
                ENDIF.

                ls_distance-product_id = <ls_field_vector>-v->*.
                IF lv_product_ids IS INITIAL.
                  lv_product_ids = c_q && <ls_field_vector>-v->* && c_q.
                ELSE.
                  lv_product_ids = lv_product_ids && ',' && c_q && <ls_field_vector>-v->* && c_q.
                ENDIF.
              ELSE.
                ls_distance-distance = <ls_field_vector>-v->*.
                INSERT ls_distance INTO TABLE lt_distance.
              ENDIF.
            ENDLOOP.
          ENDLOOP.

        CATCH /goog/cx_sdk.
      ENDTRY.


      IF lv_product_ids IS INITIAL.
        io_response->set_total_number_of_records( 0 ).
        io_response->set_data( lt_data ).
        RETURN.
      ENDIF.

    ENDIF.
  ELSE.
    DATA(lv_product_id) = VALUE #( lt_filter[ name = 'PRODUCTID' ]-range[ 1 ]-low OPTIONAL ).
    IF lv_product_id IS INITIAL.
      io_response->set_total_number_of_records( 0 ).
      io_response->set_data( lt_data ).
      RETURN.
    ENDIF.

    lv_product_ids = c_q && lv_product_id && c_q.

  ENDIF.

  DATA(lt_product_attr) =
      get_product_attr( io_client = lo_bq_client
                        iv_product_ids = lv_product_ids ).

  LOOP AT lt_product_attr REFERENCE INTO DATA(ls_product_attr).

    APPEND VALUE #(
     productid = ls_product_attr->product_id
     imageurl = |https://34.172.115.13:50001/sap/opu/odata/sap/SEPMRA_SHOP/Images(ProductId='{ ls_product_attr->product_id }',Id='{ ls_product_attr->imageid }')/$value|
*       imageurl = |http://gcdfs4dev.sapdev.google.com:8000/sap/opu/odata/sap/SEPMRA_SHOP/Images(ProductId='{ ls_product_attr->product_id }',Id='DUMMY')/$value|
     productname = ls_product_attr->product_name
     stockquantity = ls_product_attr->stock_quantity
     quantityunit = ls_product_attr->quantity_unit
     rating = ls_product_attr->product_rating
     vectorsearchstring = VALUE #( lt_distance[ product_id = ls_product_attr->product_id ]-distance OPTIONAL ) )
     TO lt_data.
  ENDLOOP.

  SORT lt_data BY vectorsearchstring ASCENDING.

  DATA(lv_max_index) = 0.
  IF lv_top IS NOT INITIAL.
    lv_max_index = lv_top + lv_skip.
  ENDIF.

  lv_max_index = 7.

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
