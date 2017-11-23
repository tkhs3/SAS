/*
    NAME
        copy_ds_2_new_nm
    
    OBJECT
        Copy and rename specified dataset to the same library, adding a serial number as suffix to the original name
            e.g. deposit_data -> deposit_data_1, deposit_data -> deposit_data_2

    CREATED BY
        tkhs3

    DATE
        2017/11/09

    ARGUMENTS/INPUTS
        ds_in:
            required
                Yes
            data-type
                Character
            contents
                SAS dataset name in 2level
                    e.g. work.deposit_data

    OUTPUTS
        SAS dataset

    SAMPLE
        data work.test1 ;
            test = 1 ;
            output ;
        run ;
        %copy_ds_2_new_nm(
            ds_in = work.test1
        );
        %copy_ds_2_new_nm(
            ds_in = work.test1
        );

*/



%macro copy_ds_2_new_nm(
    ds_in =
) ;



proc sql noprint ;

    select  
            count(*)
            into    :n_same_ds trimmed
            from    dictionary.tables
            where       btrim( upper( libname ) ) = btrim( upper( scan( "&ds_in." , 1 , "."  ) ) )
                    and index( btrim( upper( memname ) ) , btrim( upper( scan( "&ds_in." , -1 , "."  ) ) ) )
    ;
quit ;

proc append
    base = &ds_in._%eval(&n_same_ds.)
    data = &ds_in.
;
run;



%mend copy_ds_2_new_nm ;

