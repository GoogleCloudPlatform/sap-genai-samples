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
class ZCL_GOOG_RAP_PURCHASING_AGENT definition
  public
  inheriting from ZCL_GOOG_RAP_AGENT_BASE
  final
  create public .

public section.

  methods GET_SYSTEM_INSTRUCTION
    redefinition .
  methods GET_TOOL_DEFINITIONS
    redefinition .
  methods GET_MODEL_ID
    redefinition .
protected section.
private section.
ENDCLASS.



CLASS ZCL_GOOG_RAP_PURCHASING_AGENT IMPLEMENTATION.


  method GET_MODEL_ID.

    r_result = model_keys-gemini_flash. " Or a specific model

  endmethod.


  METHOD get_system_instruction.

    r_result =
    |You are a helpful Purchasing Bot  | &&
    |Your capabilities | &&
    |include:{ cl_abap_char_utilities=>newline }| &&
    |    * Getting a list and details of vendors & their current block status | &&
    |    * Getting a list of Purchase Orders and its corresponding details  | &&
    |    * Performing various CRUD operations on Purchase Orders. { cl_abap_char_utilities=>newline }| &&
    cl_abap_char_utilities=>newline &&
    |Please use the tools to get any missing information. | &&
    |You are strictly limited to these tasks. Do | &&
    | not perform any other actions or provide    | &&
    |information outside of purchasing related operations. |.

  ENDMETHOD.


  METHOD get_tool_definitions.

    r_result = VALUE #(
        ( name           = 'API_BLOCKED_VENDORS'                   " Tool-1
          description    = 'API returns a list of vendors that are blocked'
          implementation =
            VALUE #( service = 'API_BUSINESS_PARTNER'
                     version =  'V2'
                     entity = 'A_BusinessPartner'
                     cds_name = 'A_BUSINESSPARTNER'
                     cds_column = 'SUPPLIER'
                     operation = 'GET'
                     const_qp = VALUE #( (
                      name = 'BUSINESSPARTNERISBLOCKED' value = 'X' ) ) )
          parameters     = VALUE tt_tool_parameters( ) )
        ( name           = 'API_PURCHASE_ORDER_READ'               " Tool-2
          description    = 'Get a list of purchase orders for a given set of vendors'
          implementation =
            VALUE #( service = 'API_PURCHASEORDER_2'
                     version =  'V4'
                     cds_name = 'A_PURCHASEORDER_2'
                     cds_column = 'PURCHASEORDER'
                     entity = 'PURCHASEORDER'
                     operation = 'GET' )
          parameters     = VALUE tt_tool_parameters(
                                     type        = 'string'
                                     is_required = abap_true
                                     ( name = 'SUPPLIER'  description = 'Business partner who offers or provides materials or services' ) ) )
        ( name           = 'API_PURCHASE_ORDER_CANCEL'            " Tool-3
          description    = 'Cancel Purchase Orders'
          implementation =
            VALUE #( service = 'API_PURCHASEORDER_2'
                     version =  'V4'
                     cds_name = 'A_PURCHASEORDER_2'
                     cds_column = 'PURCHASEORDER'
                     entity = 'PURCHASEORDER'
                     operation = 'PATCH'
                     upd_param = VALUE #( (
                      name = 'PURCHASEORDERDELETIONCODE' value = 'X' ) ) ) "Deletion
          parameters     = VALUE tt_tool_parameters( type        = 'string'
                                                     is_required = abap_true
                                                     ( name = 'PURCHASEORDER'  description = 'Purchase Order Number' ) ) ) ).

  ENDMETHOD.
ENDCLASS.
