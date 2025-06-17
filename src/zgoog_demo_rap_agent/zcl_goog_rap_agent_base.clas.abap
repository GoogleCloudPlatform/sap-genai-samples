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
class ZCL_GOOG_RAP_AGENT_BASE definition
  public
  abstract
  create public .

public section.

  types:
      "! Structure for defining agent tools (ABAP Functions/Methods)
    BEGIN OF ty_tool_parameter,
        name        TYPE string,
        type        TYPE string, " e.g., 'string', 'number', 'integer', 'boolean', 'array', 'object'
        description TYPE string,
        is_required TYPE abap_boolean,
      END OF ty_tool_parameter .
  types:
    tt_tool_parameters TYPE STANDARD TABLE OF ty_tool_parameter WITH EMPTY KEY .
  types:
    BEGIN OF ty_entity_param,
        name        TYPE string,
        value       TYPE string,
      END OF ty_entity_param .
  types:
    tt_entity_param TYPE STANDARD TABLE OF ty_entity_param WITH EMPTY KEY .
  types:
    BEGIN OF t_tool_implementation,
      service TYPE string, "Service ID
      version TYPE string,  "V2 Or V4 OData
      entity TYPE string, "Odata Entity
      cds_name TYPE string, "CDS Name
      cds_column TYPE string,
      operation TYPE string, "Odata Operation
      const_qp TYPE tt_entity_param,
      upd_param TYPE tt_entity_param,
    END OF  t_tool_implementation .
  types:
    BEGIN OF ty_tool_definition,
        name           TYPE string,             " Name of the Function Module or Method (as registered)
        description    TYPE string,
        parameters     TYPE tt_tool_parameters,
        implementation TYPE t_tool_implementation, " Function Module name or Class-Method name (for reference)
      END OF ty_tool_definition .
  types:
    tt_tool_definitions TYPE STANDARD TABLE OF ty_tool_definition WITH EMPTY KEY .

  constants:
      "! <p>Agent specific constants</p>
    BEGIN OF model_keys,
        gemini_flash TYPE /goog/model_key VALUE 'gemini-flash-2', " Or other desired model key
        " gemini_pro   TYPE /GOOG/MODEL_KEY VALUE 'gemini-1.5-pro-latest',
      END OF model_keys .

  methods PROCESS_PROMPT
    importing
      !IV_PROMPT type STRING
    returning
      value(R_RESULT) type STRING
    raising
      /GOOG/CX_SDK .
  methods CLOSE .
    "! <p>ABSTRACT: Subclass must provide the specific system instructions.</p>
    "! @parameter r_result | The system instruction string<p></p>
  methods GET_SYSTEM_INSTRUCTION
  abstract
    returning
      value(R_RESULT) type STRING .
    "! <p>ABSTRACT: Subclass must provide the specific tool definitions.</p>
    "! @parameter r_result | Table of tool definitions | <p></p>
  methods GET_TOOL_DEFINITIONS
  abstract
    returning
      value(R_RESULT) type TT_TOOL_DEFINITIONS .
    "! <p>ABSTRACT: Subclass must provide the model ID to use.</p>
    "! @parameter r_result | The Google Cloud Model ID string |<p></p>
  methods GET_MODEL_ID
  abstract
    returning
      value(R_RESULT) type /GOOG/MODEL_KEY .
  methods INITIALIZE_AGENT
    raising
      /GOOG/CX_SDK .
  methods GET_EXECUTION_PLAN
    returning
      value(RT_PLAN) type ZCL_GOOG_RAP_GENERATIVE_MODEL=>TT_EXECUTION_PLAN .
protected section.

  data MO_MODEL type ref to ZCL_GOOG_RAP_GENERATIVE_MODEL .
  data MV_LAST_RESPONSE type STRING .
  data MT_TOOLS_REGISTERED type TT_TOOL_DEFINITIONS .
  data MV_IS_INITIALIZED type ABAP_BOOLEAN value ABAP_FALSE ##NO_TEXT.
  PRIVATE SECTION.
    "! Helper method to register tools with the SDK model
    "!
    "! @parameter it_tool_definitions | Tool definitions
    "! @raising   /goog/cx_sdk        | Google Cloud SDK Exception
    METHODS register_tools
      IMPORTING it_tool_definitions TYPE tt_tool_definitions
      RAISING   /goog/cx_sdk.
ENDCLASS.



CLASS ZCL_GOOG_RAP_AGENT_BASE IMPLEMENTATION.


  METHOD CLOSE.
    " Ensure the model object exists and close the connection
    IF me->mo_model IS BOUND.
      mo_model->close( ).
      CLEAR me->mo_model. " Release the reference
    ENDIF.
  ENDMETHOD.


  METHOD initialize_agent.
    IF mv_is_initialized = abap_true.
      RETURN.
    ENDIF.

    DATA(lv_model_id) = get_model_id( ). " Call abstract method
    DATA(lv_system_instruction) = get_system_instruction( ). " Call abstract method
    DATA(lt_tools) = get_tool_definitions( ). " Call abstract method

    TRY.
        " 1. Create the Model Instance
        me->mo_model = NEW #( iv_model_key = lv_model_id ).

        " 2. Set System Instructions
        mo_model->set_system_instructions( lv_system_instruction ).

        " 3. Register Tools (Function Declarations) if any
        IF lt_tools IS NOT INITIAL.
          register_tools( lt_tools ).
          mo_model->set_auto_invoke_sap_function( abap_true ).
        ENDIF.

        mv_is_initialized = abap_true.

      CATCH /goog/cx_sdk INTO DATA(lx_sdk).
        " Log exception or handle appropriately
        RAISE EXCEPTION lx_sdk.
    ENDTRY.
  ENDMETHOD.


  METHOD PROCESS_PROMPT.
    CLEAR me->mv_last_response.
    TRY.
        " Generate content using the prompt
        " The SDK handles the conversation history and potential tool calls internally
        DATA(lo_response) = mo_model->generate_content( iv_prompt_text = iv_prompt ).

        " Get the final text response
        r_result = lo_response->get_text( ).
        mv_last_response = r_result.

      CATCH /goog/cx_sdk INTO DATA(lx_sdk).
        " Log exception or handle appropriately
        RAISE EXCEPTION lx_sdk.
    ENDTRY.
  ENDMETHOD.


  METHOD register_tools.
    LOOP AT it_tool_definitions ASSIGNING FIELD-SYMBOL(<fs_tool>).
      DATA(lt_sdk_params) = VALUE /goog/cl_generative_model=>tt_parameter_properties( ).

      " Convert tool parameters to SDK format
      LOOP AT <fs_tool>-parameters ASSIGNING FIELD-SYMBOL(<fs_param>).
        APPEND VALUE #( parameter_name = <fs_param>-name
                        type           = <fs_param>-type
                        description    = <fs_param>-description
                        is_required    = <fs_param>-is_required )
               TO lt_sdk_params.
      ENDLOOP.

      " Add the function declaration to the SDK model
      mo_model->add_function_declaration( iv_name        = <fs_tool>-name        " Must match the FM name if using auto-invoke
                                          iv_description = <fs_tool>-description
                                          it_parameters  = lt_sdk_params ).
    ENDLOOP.

    mo_model->set_rap_tools( it_tool_definitions ).
    mo_model->clear_execution_plan( ).

  ENDMETHOD.


  method GET_EXECUTION_PLAN.

    rt_plan = mo_model->gt_execution_plan.

  endmethod.
ENDCLASS.
