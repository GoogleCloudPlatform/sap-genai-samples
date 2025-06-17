*&---------------------------------------------------------------------*
*& Include          ZDEMO_USE_INVOICE_AGENT_PMP
*&---------------------------------------------------------------------*

DATA(lv_prompt0) = 'Please extract the following fields from the attached:' &&
                   cl_abap_char_utilities=>newline &&
                   'From Page1:' &&
                   cl_abap_char_utilities=>newline &&
                   'a) SB No' &&
                   cl_abap_char_utilities=>newline &&
                   'From "PART - I - SHIPPING BILL SUMMARY" section:' &&
                   cl_abap_char_utilities=>newline &&
                   'a) 6.DBK' &&
                   cl_abap_char_utilities=>newline &&
                   'b) 7.RODTP' &&
                   cl_abap_char_utilities=>newline &&
                   'c) 5.COM' &&
                   cl_abap_char_utilities=>newline &&
                   'd) 1.DBK CLAIM' &&
                   cl_abap_char_utilities=>newline &&
                   'f) 5.RODTEP AMT' &&
                   cl_abap_char_utilities=>newline &&
                   'g) 2.INV NO.'.

DATA(lv_prompt1) = 'Please extract the following fields from the attached:' &&
                   cl_abap_char_utilities=>newline &&
                   'From Page1:' &&
                   cl_abap_char_utilities=>newline &&
                   'a) SB No' &&
                   cl_abap_char_utilities=>newline &&
                   'From "PART - I - SHIPPING BILL SUMMARY" section:' &&
                   cl_abap_char_utilities=>newline &&
                   'a) 6.DBK' &&
                   cl_abap_char_utilities=>newline &&
                   'b) 7.RODTP' &&
                   cl_abap_char_utilities=>newline &&
                   'c) 5.COM' &&
                   cl_abap_char_utilities=>newline &&
                   'd) 1.DBK CLAIM' &&
                   cl_abap_char_utilities=>newline &&
                   'f) 5.RODTEP AMT' &&
                   cl_abap_char_utilities=>newline &&
                   'g) 2.INV NO.' &&
                   cl_abap_char_utilities=>newline &&
                   'h) 4.CURRENC' &&
                   cl_abap_char_utilities=>newline &&
                   'From "PART - IV - EXPORT SCHEME DETAILS" section under "A. DRAWBACK & ROSL CLAIM":' &&
                   cl_abap_char_utilities=>newline &&
                   'a) 1.INV SNO' &&
                   cl_abap_char_utilities=>newline &&
                   'b) 2.ITEM SNO' &&
                   cl_abap_char_utilities=>newline &&
                   'c) 6.RATE.'.


DATA(lv_prompt2) = 'Please extract the following fields from the attached:' &&
                    cl_abap_char_utilities=>newline &&
                    'From Page1:' &&
                    cl_abap_char_utilities=>newline &&
                    'a) SB No' &&
                    cl_abap_char_utilities=>newline &&
                    'From "PART - I - SHIPPING BILL SUMMARY" section:' &&
                    cl_abap_char_utilities=>newline &&
                    'a) 6.DBK' &&
                    cl_abap_char_utilities=>newline &&
                    'b) 7.RODTP' &&
                    cl_abap_char_utilities=>newline &&
                    'c) 5.COM' &&
                    cl_abap_char_utilities=>newline &&
                    'd) 1.DBK CLAIM' &&
                    cl_abap_char_utilities=>newline &&
                    'f) 5.RODTEP AMT' &&
                    cl_abap_char_utilities=>newline &&
                    'g) 2.INV NO.' &&
                    cl_abap_char_utilities=>newline &&
                    'h) 4.CURRENC' &&
                    cl_abap_char_utilities=>newline &&
                    'From "PART - IV - EXPORT SCHEME DETAILS" section under "A. DRAWBACK & ROSL CLAIM":' &&
                    cl_abap_char_utilities=>newline &&
                    'a) 1.INV SNO' &&
                    cl_abap_char_utilities=>newline &&
                    'b) 2.ITEM SNO' &&
                    cl_abap_char_utilities=>newline &&
                    'c) 6.RATE' &&
                    cl_abap_char_utilities=>newline &&
                    'd) ABC' &&
                    cl_abap_char_utilities=>newline &&
                    'e) XYZ'.

DATA(lv_prompt3) = 'From "PART - IV - EXPORT SCHEME DETAILS" section under "H.INVOICE DETAILS". ' &&
                   'If there are multiple record under this section please extract all.'.
