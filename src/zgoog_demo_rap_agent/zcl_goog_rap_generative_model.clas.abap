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
class ZCL_GOOG_RAP_GENERATIVE_MODEL definition
  public
  inheriting from /GOOG/CL_GENERATIVE_MODEL
  final
  create public .

public section.

  types:
    tt_string TYPE STANDARD TABLE OF string WITH EMPTY KEY .
  types:
    BEGIN OF t_execution_plan,
      step TYPE i,
      details TYPE tt_string,
    END OF t_execution_plan .
  types:
    tt_execution_plan TYPE HASHED TABLE OF t_execution_plan WITH UNIQUE KEY step .

  data GT_EXECUTION_PLAN type TT_EXECUTION_PLAN read-only .

  methods SET_RAP_TOOLS
    importing
      !IT_RAP_TOOLS type ZCL_GOOG_RAP_AGENT_BASE=>TT_TOOL_DEFINITIONS .
  methods GET_RANGE_TABLE
    importing
      !PI_TYPE type STRING
      !PI_VALUE type STRING
    returning
      value(PR_DATA) type ref to DATA .
  methods CLEAR_EXECUTION_PLAN .
protected section.

  methods INVOKE_SAP_FUNCTION
    redefinition .
private section.

  data GT_RAP_TOOLS type ZCL_GOOG_RAP_AGENT_BASE=>TT_TOOL_DEFINITIONS .

  methods RAP_CALL
    importing
      !IV_FUNCTION_NAME type STRING
      !IT_FUNCTION_PARAMETERS type /GOOG/T_FUNCTION_PARAMETERS
    exporting
      !EV_FUNCTION_RESPONSE type STRING
    changing
      !CV_PROMPT type STRING .
ENDCLASS.



CLASS ZCL_GOOG_RAP_GENERATIVE_MODEL IMPLEMENTATION.


  METHOD invoke_sap_function.

    DATA:
      lv_function_response    TYPE string,
      lv_function_module_name TYPE rs38l_fnam,
      lv_prompt_text          TYPE string,
      lv_error_text           TYPE string,
      lo_cx_root              TYPE REF TO cx_root.


    lv_function_module_name = iv_function_name.
    lv_prompt_text = iv_prompt_text.

    TRY.
        rap_call(
          EXPORTING
            iv_function_name       = iv_function_name
            it_function_parameters = it_function_parameters
          IMPORTING
            ev_function_response   = lv_function_response
          CHANGING
            cv_prompt              = lv_prompt_text ).

        IF lv_function_response IS NOT INITIAL.
          es_content_response = set_function_call( iv_function_name       = iv_function_name
                                                   it_function_parameters = it_function_parameters
                             )->set_function_response( iv_function_name     = iv_function_name
                                                       iv_function_response = lv_function_response
                             )->generate_content( iv_prompt_text = lv_prompt_text
                             )->get_response( ).
        ELSE.
          lv_error_text = TEXT-003.
          CALL METHOD /goog/cl_vertex_ai_sdk_utility=>raise_error
            EXPORTING
              iv_ret_code = /goog/cl_http_client=>c_ret_code_461
              iv_err_text = lv_error_text.

        ENDIF.
      CATCH cx_root INTO lo_cx_root.
        lv_error_text = lo_cx_root->get_text( ).
        CALL METHOD /goog/cl_vertex_ai_sdk_utility=>raise_error
          EXPORTING
            iv_ret_code = /goog/cl_http_client=>c_ret_code_461
            iv_err_text = lv_error_text.

    ENDTRY.

  ENDMETHOD.


  METHOD rap_call.

    DATA(ls_rap_tool) = REF #( gt_rap_tools[ name = iv_function_name ] OPTIONAL ).
    DATA: lo_client_proxy TYPE REF TO /iwbep/if_cp_client_proxy.

    TRY.
        CASE ls_rap_tool->implementation-version.
          WHEN 'V2'.

            lo_client_proxy =
               /iwbep/cl_cp_client_proxy_fact=>create_v2_local_proxy(
                 VALUE #( service_id = ls_rap_tool->implementation-service service_version =  '0001' ) ).

          WHEN 'V4'.

            lo_client_proxy =
                /iwbep/cl_cp_client_proxy_fact=>create_v4_local_proxy(
                   VALUE #( service_id = ls_rap_tool->implementation-service service_version = '0001' repository_id = 'SRVD_A2X' ) ).

          WHEN OTHERS.
        ENDCASE.

        CASE ls_rap_tool->implementation-operation.
          WHEN 'GET'.
            DATA: lo_read_request TYPE REF TO /iwbep/if_cp_request_read_list.
            DATA: lo_read_response TYPE REF TO /iwbep/if_cp_response_read_lst.

            lo_read_request =
              lo_client_proxy->create_resource_for_entity_set(
                 CONV #( ls_rap_tool->implementation-entity )
                 )->create_request_for_read( ).

            DATA(lo_filter_factory) = lo_read_request->create_filter_factory( ).

            LOOP AT it_function_parameters REFERENCE INTO DATA(ls_function_param).
              DATA(lr_range_func) =
              get_range_table(
                EXPORTING
                  pi_type  = CONV #( ls_rap_tool->implementation-cds_name && '-' && ls_function_param->parameter_name )
                  pi_value = ls_function_param->parameter_value ).

              FIELD-SYMBOLS: <lt_range_func> TYPE STANDARD TABLE.

              ASSIGN lr_range_func->* TO <lt_range_func>.

              DATA(lo_filter_func)  =
                lo_filter_factory->create_by_range(
                 iv_property_path = ls_function_param->parameter_name
                 it_range         = <lt_range_func> ).

              lo_read_request->set_filter( lo_filter_func ).

            ENDLOOP.

            LOOP AT ls_rap_tool->implementation-const_qp REFERENCE INTO DATA(ls_const_qp).
              DATA(lr_range_const) =
              get_range_table(
                EXPORTING
                  pi_type  = CONV #( ls_rap_tool->implementation-cds_name && '-' && ls_const_qp->name )
                  pi_value = ls_const_qp->value ).

              FIELD-SYMBOLS: <lt_range_const> TYPE STANDARD TABLE.

              ASSIGN lr_range_const->* TO <lt_range_const>.

              DATA(lo_filter_const)  =
                lo_filter_factory->create_by_range(
                 iv_property_path = ls_const_qp->name
                 it_range         = <lt_range_const> ).

              lo_read_request->set_filter( lo_filter_const ).
            ENDLOOP.

            DATA: lr_data TYPE REF TO data.
            CREATE DATA lr_data TYPE STANDARD TABLE OF (ls_rap_tool->implementation-cds_name).
            FIELD-SYMBOLS: <lt_data> TYPE STANDARD TABLE.
            ASSIGN lr_data->* TO <lt_data>.

            lo_read_request->set_top( iv_top = 10 ).
            lo_read_response = lo_read_request->execute( ).

            "Retrieve the business data
            lo_read_response->get_business_data( IMPORTING et_business_data = <lt_data> ).
            IF <lt_data> IS INITIAL.
              RETURN.
            ENDIF.

            ev_function_response = |List of { ls_rap_tool->implementation-cds_column }: |.
            LOOP AT <lt_data> ASSIGNING FIELD-SYMBOL(<ls_data>).
              ASSIGN COMPONENT ls_rap_tool->implementation-cds_column
                     OF STRUCTURE <ls_data> TO  FIELD-SYMBOL(<lv_column>).
              ev_function_response = ev_function_response && space && <lv_column>.
            ENDLOOP.

          WHEN 'PATCH'.

            DATA: lo_update_request TYPE REF TO /iwbep/if_cp_request_update.
            DATA: lo_entity_resource TYPE REF TO /iwbep/if_cp_resource_entity.

            DATA: lr_upd_data TYPE REF TO data.

            CREATE DATA lr_upd_data TYPE (ls_rap_tool->implementation-cds_name).

            ASSIGN lr_upd_data->* TO FIELD-SYMBOL(<ls_upd_data>).
            ASSIGN COMPONENT ls_rap_tool->implementation-cds_column OF STRUCTURE <ls_upd_data> TO FIELD-SYMBOL(<lv_upd_key>).
            <lv_upd_key> = VALUE #( it_function_parameters[ 1 ]-parameter_value OPTIONAL ).

            lo_entity_resource =
             lo_client_proxy->create_resource_for_entity_set(
               CONV #( ls_rap_tool->implementation-entity ) )->navigate_with_key( <ls_upd_data> ).

            lo_update_request = lo_entity_resource->create_request_for_update( /iwbep/if_cp_request_update=>gcs_update_semantic-patch ).

            LOOP AT ls_rap_tool->implementation-upd_param REFERENCE INTO DATA(ls_upd_param).
              ASSIGN COMPONENT ls_upd_param->name OF STRUCTURE <ls_upd_data> TO FIELD-SYMBOL(<lv_upd_prop>).
              <lv_upd_prop> = ls_upd_param->value.
            ENDLOOP.

            lo_update_request->set_business_data(
               is_business_data = <ls_upd_data>
               it_provided_property = VALUE #( FOR <wa_prop> IN ls_rap_tool->implementation-upd_param
                                                 ( <wa_prop>-name ) ) ).

            DATA(lo_update_response) = lo_update_request->execute( ).
            lo_update_response->get_business_data( IMPORTING es_business_data = <ls_upd_data> ).

            ev_function_response = |Update Performed successfully |.

          WHEN OTHERS.
        ENDCASE.


      CATCH /iwbep/cx_cp_remote INTO DATA(lx_cp_remote).
        " Error handling
        DATA(lv_text) = lx_cp_remote->get_longtext( ).
      CATCH /iwbep/cx_gateway INTO DATA(lx_gateway).
        " Error Handling
        DATA(lv_text1) = lx_gateway->get_longtext( ).
    ENDTRY.

    INSERT VALUE #( step = lines( gt_execution_plan[] ) + 1 ) INTO TABLE gt_execution_plan
           REFERENCE INTO DATA(ls_execution_plan) .
    APPEND CONV #( |Calling tool { ls_rap_tool->name }| ) TO ls_execution_plan->details.
    APPEND CONV #( |  - Implemented by API { ls_rap_tool->implementation-service } | ) TO ls_execution_plan->details.
    APPEND CONV #( |  - Perfoming operation { ls_rap_tool->implementation-operation } on entity { ls_rap_tool->implementation-entity } | ) TO ls_execution_plan->details.
    LOOP AT it_function_parameters REFERENCE INTO DATA(ls_func_param_output).
      APPEND CONV #( |  - With Parameters name { ls_func_param_output->parameter_name } and Value { ls_func_param_output->parameter_value } | ) TO ls_execution_plan->details.
    ENDLOOP.
    APPEND CONV #( |  - Tool response: { ev_function_response } | ) TO ls_execution_plan->details.

  ENDMETHOD.


  METHOD set_rap_tools.

    gt_rap_tools = it_rap_tools.

  ENDMETHOD.


  METHOD get_range_table.

    DATA:
      lo_typedescr   TYPE REF TO cl_abap_typedescr,
      lo_structdescr TYPE REF TO cl_abap_structdescr,
      lo_tabledescr  TYPE REF TO cl_abap_tabledescr,
      lt_components  TYPE cl_abap_structdescr=>component_table,
      ls_component   LIKE LINE OF lt_components.

    FIELD-SYMBOLS:
      <lt_any_table> TYPE STANDARD TABLE. " To hold the final table reference

    " 1. Get type description for the field for which range is needed
    TRY.
        lo_typedescr = cl_abap_typedescr=>describe_by_name( pi_type ).
    ENDTRY.

    " 2. Define components for the range line structure
    CLEAR lt_components.

    " SIGN component
    ls_component-name = 'SIGN'.
    ls_component-type = cl_abap_elemdescr=>get_c( p_length = 1 ). " Character length 1
    APPEND ls_component TO lt_components.

    " OPTION component
    ls_component-name = 'OPTION'.
    ls_component-type = cl_abap_elemdescr=>get_c( p_length = 2 ). " Character length 2
    APPEND ls_component TO lt_components.

    " LOW component (using the dynamically determined type)
    ls_component-name = 'LOW'.
    ls_component-type ?= lo_typedescr. " Use the descriptor obtained earlier
    APPEND ls_component TO lt_components.

    " HIGH component (using the dynamically determined type)
    ls_component-name = 'HIGH'.
    ls_component-type ?= lo_typedescr. " Use the descriptor obtained earlier
    APPEND ls_component TO lt_components.

    " 3. Create the structure descriptor for the range line
    TRY.
        lo_structdescr = cl_abap_structdescr=>create( lt_components ).
    ENDTRY.

    " 4. Create the table descriptor for the range table (standard table)
    TRY.
        lo_tabledescr = cl_abap_tabledescr=>create(
                          p_line_type  = lo_structdescr
                          p_table_kind = cl_abap_tabledescr=>tablekind_std " Standard table
                          p_key_kind   = cl_abap_tabledescr=>keydefkind_default ). " Default key
    ENDTRY.

    " 5. Create the actual data object (internal table)
    CREATE DATA pr_data TYPE HANDLE lo_tabledescr.

    FIELD-SYMBOLS: <lt_range> TYPE STANDARD TABLE.

    ASSIGN pr_data->* TO <lt_range>.
    APPEND INITIAL LINE TO <lt_range> ASSIGNING FIELD-SYMBOL(<ls_range>).
    ASSIGN COMPONENT 'LOW' OF STRUCTURE <ls_range> TO FIELD-SYMBOL(<lv_comp>).
    <lv_comp> = pi_value.
    ASSIGN COMPONENT 'SIGN' OF STRUCTURE <ls_range> TO FIELD-SYMBOL(<lv_sign>).
    <lv_sign> = 'I'.
    ASSIGN COMPONENT 'OPTION' OF STRUCTURE <ls_range> TO FIELD-SYMBOL(<lv_option>).
    <lv_option> = 'EQ'.

  ENDMETHOD.


  METHOD clear_execution_plan.

    CLEAR gt_execution_plan.

  ENDMETHOD.
ENDCLASS.
