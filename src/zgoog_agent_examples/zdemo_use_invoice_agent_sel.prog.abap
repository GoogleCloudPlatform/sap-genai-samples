*&---------------------------------------------------------------------*
*& Include          ZDEMO_USE_INVOICE_AGENT_SEL
*&---------------------------------------------------------------------*

" -----------------------------------------------------------------------
" Selection Screen
" -----------------------------------------------------------------------
"PARAMETERS: p_prompt TYPE string DEFAULT  'From "PART - IV - EXPORT SCHEME DETAILS" section under "H.INVOICE DETAILS". If there are multiple record under this section please extract all'.
PARAMETERS: p_file TYPE rlgrap-filename OBLIGATORY. "File path

" -----------------------------------------------------------------------
" Main Processing Block
" -----------------------------------------------------------------------

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  CALL FUNCTION 'F4_FILENAME'
    IMPORTING
      file_name = p_file.
