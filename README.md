### SAS library

Overview

    This is SAS macro/function library.
    
  
Lisf of file

    FUNCTION
        fmt_date
            Convert date or datetime represented in numeric to arbitrarily formatted string using format elements
        round_num_2_char
            Round numeric value to the specified digit and convert to character value
            
    MACRO
        comp_ds
            Compare datasets between different libraries, performing proc compare with the same dataset
            
        comp_excel
            Compare MS-Excel files between different folders, creating the report of results from comparing each files
            
        copy_ds_2_new_nm
            Copy and rename specified dataset to the same library, adding a serial number as suffix to the original name

        crt_ds_4_mi
            Impute missing value of variables in specified dataset

        out_ds_2_msword
            output a dataset to the pre-existing table in the MS-Word file which is typically separate mock-up file composing an entire report
