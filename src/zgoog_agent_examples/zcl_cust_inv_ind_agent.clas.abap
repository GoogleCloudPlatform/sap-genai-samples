class ZCL_CUST_INV_IND_AGENT definition
  public
  inheriting from ZCL_GEMINI_AGENT_BASE
  create public .

public section.

  methods UPLOAD_FILE
    importing
      !IV_FILE_PATH type RLGRAP-FILENAME
    raising
      /GOOG/CX_SDK .

  methods GET_INLINE_DATA
    redefinition .
  methods GET_MODEL_ID
    redefinition .
  methods GET_SYSTEM_INSTRUCTION
    redefinition .
  methods GET_TOOL_DEFINITIONS
    redefinition .
protected section.
private section.

  data MV_FILE_DATA type STRING .
  data MS_SCHEMA type /goog/cl_generative_model=>ty_response_schema .
ENDCLASS.



CLASS ZCL_CUST_INV_IND_AGENT IMPLEMENTATION.


  METHOD get_inline_data.

    r_result-mime_type = 'application/pdf'.
    r_result-file_data = mv_file_data.

  ENDMETHOD.


  METHOD get_model_id.
    r_result = model_keys-gemini_flash. " Or a specific model
  ENDMETHOD.


METHOD get_system_instruction.


  r_result = |You are an intelligent agent designed to extract arbitrary data fields from supplied PDF documents. | &&
             |Your primary goal is to identify fields based on their labels, extract corresponding values using | &&
             |contextual information, and deliver the output in a JSON format with lowercase-first camel case | &&
             |field names. You must **ignore any text or images identified as watermarks** during the entire process, | &&
             |and if a watermark affects an extracted value, that value should also be ignored/not included. | &&
             cl_abap_char_utilities=>newline &&
             |Your capabilities include:| && cl_abap_char_utilities=>newline &&
             |1.  Thorough Document Review: Carefully read and understand the entire PDF document's structure and layout.| && cl_abap_char_utilities=>newline &&
             |2.  Watermark Handling: Before any other processing, identify and isolate watermarks (faint, repetitive, overlaid patterns). | &&
             |    **Crucially, ignore all watermark content and any values affected by watermarks.**| && cl_abap_char_utilities=>newline &&
             |3.  Field Identification by Label: Locate data fields by identifying their labels within the document. Do not extract field data is labels do not exactly match.| && cl_abap_char_utilities=>newline &&
             |4.  Contextual Value Extraction: Determine how the value is related to the label (e.g., directly below, to the right, or several words/lines away but associated) and extract it reliably.| && cl_abap_char_utilities=>newline &&
             |5.  Missing Data Handling: If a label cannot be located, return it as an error field within the 'errors' array in the output JSON.| && cl_abap_char_utilities=>newline &&
             |6.  Completeness Score Calculation: Calculate (Number of Successfully Extracted Fields) / (Total Number of Expected Fields) * 100. | &&
             cl_abap_char_utilities=>newline &&
             |Step-by-Step Processing:| && cl_abap_char_utilities=>newline &&
             |* Step 1: Watermark Recognition and Isolation. Identify and isolate faint or repetitive patterns that don't align from the same location. This is the first action to perform.| && cl_abap_char_utilities=>newline &&
             |* Step 2: Label Identification. Locate any field by its label to extract the corresponding value.| && cl_abap_char_utilities=>newline &&
             |* Step 3: Value Context Determination. Determine the relationship between the label and its value (e.g., directly below, to the right, or associated despite distance).| && cl_abap_char_utilities=>newline &&
             |* Step 4: Value Extraction. Reliably grab the information from the correct value field.| && cl_abap_char_utilities=>newline &&
             cl_abap_char_utilities=>newline &&
             |Output Format: JSON with lowercase-first camel case field names. The structure must include 'extractedData', 'completenessScore', and an 'errors' array. | && cl_abap_char_utilities=>newline &&
             |```json | && cl_abap_char_utilities=>newline &&
             |\{ | && cl_abap_char_utilities=>newline &&
             |"extractedData": \{ | && cl_abap_char_utilities=>newline &&
             |"sbNo": "8376965", | && cl_abap_char_utilities=>newline &&
             |"dbk": "N", | && cl_abap_char_utilities=>newline &&
             |"rodtp": "Y", | && cl_abap_char_utilities=>newline &&
             |"com": "392", | && cl_abap_char_utilities=>newline &&
             |"dbkClaim": "52356", | && cl_abap_char_utilities=>newline &&
             |"rodtepAmt": "0", | && cl_abap_char_utilities=>newline &&
             |"invNo": "9253101384", | && cl_abap_char_utilities=>newline &&
             |"currenc": "USD", | && cl_abap_char_utilities=>newline &&
             |"invSno": "1", | && cl_abap_char_utilities=>newline &&
             |"itemSno": "1", | && cl_abap_char_utilities=>newline &&
             |"rate": "2.1", | && cl_abap_char_utilities=>newline &&
             |"dbkAmt": "7278.51" | && cl_abap_char_utilities=>newline &&
             |\}, | && cl_abap_char_utilities=>newline &&
             |"completenessScore": 100, | && cl_abap_char_utilities=>newline &&
             |"errors": [] // List of fields that failed to extract due to missing labels or is the label was not found | && cl_abap_char_utilities=>newline &&
             |\} | && cl_abap_char_utilities=>newline &&
             |``` | && cl_abap_char_utilities=>newline

             .








"  {
" "extractedData": {
" "sbNo": "8376965",
" "dbk": "N",
" "rodtp": "Y",
" "com": "392",
" "dbkClaim": "52356",
" "rodtpAmt": "0",
" "invNo": "9253101384"
" },
" "completenessScore": 100,
" "errors": []
"}

*
*  r_result = |You are an intelligent agent designed to extract arbitrary data fields from supplied PDF documents. | &&
*             |Your primary goal is to identify fields based on their labels, extract corresponding values using | &&
*             |contextual information, and deliver the output in a text statement. | &&
*             |You must **ignore any text or images identified as watermarks** during the entire process, | &&
*             |and if a watermark affects an extracted value, that value should also be ignored/not included. | &&
*             |If field name has '.' then remove the '.' and also remove any preceeding number in your output. E.g. 6.DBK will change to DBK. | &&
*             cl_abap_char_utilities=>newline &&
*             |Your capabilities include:| && cl_abap_char_utilities=>newline &&
*             |1.  Thorough Document Review: Carefully read and understand the entire PDF document's structure and layout.| && cl_abap_char_utilities=>newline &&
*             |2.  Watermark Handling: Before any other processing, identify and isolate watermarks (faint, repetitive, overlaid patterns). | &&
*             |    **Crucially, ignore all watermark content and any values affected by watermarks.**| && cl_abap_char_utilities=>newline &&
*             |3.  Field Identification by Label: Locate data fields by identifying their labels within the document.| && cl_abap_char_utilities=>newline &&
*             |4.  Contextual Value Extraction: Determine how the value is related to the label (e.g., directly below, to the right, or several words/lines away but associated) and extract it reliably.|.
ENDMETHOD.


  method GET_TOOL_DEFINITIONS.
  endmethod.


  METHOD upload_file.
    DATA:
      lt_bin_data    TYPE STANDARD TABLE OF char1024,
      lv_file        TYPE string,
      lv_file_length TYPE i,
      lv_xfile       TYPE xstring.


    lv_file = iv_file_path.

* Call function module to upload the file contents
    CALL FUNCTION 'GUI_UPLOAD'
      EXPORTING
        filename   = lv_file
        filetype   = 'BIN'
      IMPORTING
        filelength = lv_file_length
      TABLES
        data_tab   = lt_bin_data.

* Call function module to convert file contents from 'BIN' to 'XSTRIG' format
    CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
      EXPORTING
        input_length = lv_file_length
      IMPORTING
        buffer       = lv_xfile
      TABLES
        binary_tab   = lt_bin_data.

* Call function module to convert the file contents from 'XSTRING' to 'base-64 encoded' format
    CALL FUNCTION 'SCMS_BASE64_ENCODE_STR'
      EXPORTING
        input  = lv_xfile
      IMPORTING
        output = mv_file_data.


  ENDMETHOD.
ENDCLASS.
