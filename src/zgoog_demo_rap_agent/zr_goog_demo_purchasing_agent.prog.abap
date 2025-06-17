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
REPORT zr_goog_demo_purchasing_agent.

" -----------------------------------------------------------------------
" Selection Screen
" -----------------------------------------------------------------------
PARAMETERS p_prompt TYPE string DEFAULT 'Cancel all open purchase orders for vendors that are blocked' LOWER CASE.

" -----------------------------------------------------------------------
" Main Processing Block
" -----------------------------------------------------------------------

START-OF-SELECTION.

  DATA(lo_out) = cl_demo_output=>new( ).

  TRY.
      " 1. Instantiate the specific Agent class
      "    The constructor of zcl_goog_rap_purchasing_agent calls super->constructor(),
      "    which in turn calls the redefined GET_... methods to configure
      "    the agent within the base class logic.
      DATA(lo_purchasing_agent) = NEW zcl_goog_rap_purchasing_agent( ).
      lo_purchasing_agent->initialize_agent( ).

      " 2. Process the user's prompt
      "    The process_prompt method is inherited from the base class
      "    and uses the fully configured mo_model instance.
      DATA(lv_response) = lo_purchasing_agent->process_prompt( iv_prompt = p_prompt ).

      " 3. Display the result
      lo_out->begin_section( 'User Prompt:' ).
      lo_out->write_text( p_prompt ).
      lo_out->begin_section( 'Agent Response:' ).
      lo_out->write_text( lv_response  ).

      DATA(lt_plan) = lo_purchasing_agent->get_execution_plan( ).

      lo_out->begin_section( 'Agent Execution plan:' ).
      LOOP AT lt_plan REFERENCE INTO data(ls_plan).
         lo_out->begin_section( |Step { ls_plan->step }| ).

         LOOP AT ls_plan->details REFERENCE INTO data(ls_plan_details) .
            lo_out->write_text( ls_plan_details->* ).
         ENDLOOP.
      ENDLOOP.

      lo_out->display( ).

    CATCH /goog/cx_sdk INTO DATA(lx_sdk).
      " Handle potential SDK errors (authentication, API issues, etc.)
      lo_out->begin_section( |!!! Error occurred !!!| ).
      lo_out->write_text( lx_sdk->get_text( ) ).
      lo_out->display( ).

  ENDTRY.

  " 4. IMPORTANT: Clean up the agent resources
  "    Always ensure the close method is called to release the
  "    SDK connection and resources, even if errors occurred.
  IF lo_purchasing_agent IS BOUND.
    lo_purchasing_agent->close( ).
  ENDIF.
