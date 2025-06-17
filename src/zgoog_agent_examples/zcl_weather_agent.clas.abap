CLASS zcl_weather_agent DEFINITION
  PUBLIC
  INHERITING FROM zcl_gemini_agent_base
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS get_system_instruction REDEFINITION.
    METHODS get_tool_definitions   REDEFINITION.
    METHODS get_model_id           REDEFINITION.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_WEATHER_AGENT IMPLEMENTATION.


  METHOD get_model_id.
    r_result = model_keys-gemini_flash. " Or a specific model
  ENDMETHOD.


  METHOD get_system_instruction.
    r_result =
    |You are a helpful weather and environmental | &&
    |information assistant bot. Your capabilities | &&
    |include:{ cl_abap_char_utilities=>newline }| &&
    |1.  Weather Information:{  cl_abap_char_utilities=>newline }| &&
    |    * Identify the location mention in the prompt and use the tool to get geocode | &&
    |    * Retrieve and provide current weather  | &&
    |      information, including air quality.{ cl_abap_char_utilities=>newline }| &&
    |2.  Natural Disaster Alerts:{ cl_abap_char_utilities=>newline }| &&
    |    * Alert the user about significant     | &&
    |      earthquakes.{ cl_abap_char_utilities=>newline }| &&
    |    * Alert the user about significant     | &&
    |      storms.{ cl_abap_char_utilities=>newline }| &&
    |3.  Air Quality Information:{ cl_abap_char_utilities=>newline }| &&
    |    * Provide air quality information for a | &&
    |      specified location.{ cl_abap_char_utilities=>newline }| &&
    cl_abap_char_utilities=>newline &&
    |Please use the tools to get any missing information. | &&
    |You are strictly limited to these tasks. Do | &&
    | not perform any other actions or provide    | &&
    |information outside of weather, earthquakes, | &&
    |storms, and air quality.|.
  ENDMETHOD.


  METHOD get_tool_definitions.
    r_result = VALUE #(
        ( name           = 'Z_TOOL_GET_CURRENT_LOCATION'      " Tool-1
          description    = 'Get the current geographical location of the user'
          implementation = 'Z_TOOL_GET_CURRENT_LOCATION'
          parameters     = VALUE tt_tool_parameters( ) )
        ( name           = 'Z_TOOL_GET_GEOCODE'               " Tool-2
          description    = 'Get geocodes in the form of latitude and longitude coordinates for a specified location'
          implementation = 'Z_TOOL_GET_GEOCODE' " For reference
          parameters     = VALUE tt_tool_parameters(
                                     type        = 'string'
                                     is_required = abap_true
                                     ( name = 'LOCATION'  description = 'Location details to identify Geocode' ) ) )
        ( name           = 'Z_TOOL_GET_AIR_QUALITY'            " Tool-3
          description    = 'Gets air quality information for a given location specified by latitude and longitude'
          implementation = 'Z_TOOL_GET_AIR_QUALITY' " For reference
          parameters     = VALUE tt_tool_parameters( type        = 'string'
                                                     is_required = abap_true
                                                     ( name = 'LOCATION'  description = 'Location details' )
                                                     ( name = 'LATITUDE'  description = 'Latitude of the location' )
                                                     ( name = 'LONGITUDE' description = 'Longitude of the location' ) ) ) ).
  ENDMETHOD.
ENDCLASS.
