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
REPORT zdemo_use_invoice_agent.

INCLUDE zdemo_use_invoice_agent_pmp.

INCLUDE zdemo_use_invoice_agent_sel.



START-OF-SELECTION.

  DATA(lo_out) = cl_demo_output=>new( ).

  data(lv_prompt) = lv_prompt2.

  TRY.
      DATA(lo_invoice_agent) = NEW zcl_cust_inv_ind_agent( ).
      lo_invoice_agent->upload_file( p_file ).
      lo_invoice_agent->initialize_agent( ).


      DATA(lv_response) = lo_invoice_agent->process_prompt( iv_prompt = lv_prompt ).

      " Display the result
      lo_out->begin_section( 'User Prompt:' ).
      lo_out->write_text( lv_prompt ).
      lo_out->begin_section( 'Agent Response:' ).
      lo_out->write_text( lv_response ).
      lo_out->display( ).

    CATCH /goog/cx_sdk INTO DATA(lx_sdk).
      " Handle potential SDK errors (authentication, API issues, etc.)
      lo_out->begin_section( |!!! Error occurred !!!| ).
      lo_out->write_text( lx_sdk->get_text( ) ).
      lo_out->display( ).

  ENDTRY.

  " Clean up the agent resources
  IF lo_invoice_agent IS BOUND.
    lo_invoice_agent->close( ).
  ENDIF.
