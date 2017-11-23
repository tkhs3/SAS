/*
    OBJECT
        Compare datasets between different libraries, performing proc compare with the same dataset

    CREATED BY
        tkhs3

    DATE
        2017/11/15

    ARGUMENTS/INPUTS
        lib_base:
            required
                Yes
            data-type
                Character
            contents
                SAS library name in 1 level
                    e.g. work
        lib_comp:
            required
                Yes
            data-type
                Character
            contents
                SAS library name in 1 level
                    e.g. user
                    
        is_sorting:
            required
                No
            data-type
                Character/Integer
            contents
                0 (default) -> perform proc compare without id-statement
                others      -> perform proc compare with id-statement specifying sort-variables in the first library
                    e.g. 1
        is_delete:
            required
                No
            data-type
                Character/Integer
            contents
                1 (default) -> perform deletion of intermidiate datasets, using proc datasets
                others      -> do not perform deletion of intermidiate datasets
                    e.g. 1

        is_out_dif:
            required
                No
            data-type
                Character/Integer
            contents
                1 (default) -> perform proc compare with outnoequal-option      i.e. output datasets containing difference in datasets
                others      -> perform proc compare without outnoequal-option   i.e. do not output datasets containing difference in datasets
                    e.g. 1

    OUTPUTS
        SAS html results
            produced by proc compare
            sent to the SAS Results window
        datasets (optional)
            resulted from proc compare with outnoequal option
            named _res_comp_X (e.g. _res_comp_1, _res_comp_2, _res_comp_3, ...)

    SAMPLE
        data work.test1 ;
            test = 1 ;
            output ;
        run ;
        data user.test1 ;
            test = 1 ;
            output ;
        run ;
        %comp_ds(
            lib_base = work ,
            lib_comp = user
        );

*/



%macro COMP_DS(
        LIB_BASE    = ,
        LIB_COMP    = 
    ,   IS_SORTING  = 0 
    ,   IS_DELETE   = 1 
    ,   IS_OUT_DIF  = 1
);



/*
    create macro variables storing dataset names
*/

/*create list of datasets have same name*/
proc sql noprint ;
    create table WORK._LST_DS as
        select  memname
        from    DICTIONARY.TABLES
        where   libname = upper("&LIB_BASE.") and 
                memname in ( select memname from DICTIONARY.TABLES where libname = upper("&LIB_COMP.") )
    ;
quit ;

/*total number of datasets*/
%let MAX_DSN = &SQLOBS. ;

/*convert to macro variables*/
proc sql noprint ;
    select      
                memname 
        into    
                :DSN_1 - :DSN_&MAX_DSN. 
        from    WORK._LST_DS
    ;
quit ;



/*
    create macro variables storing variable names used when sorting for each datasets
*/
%if &IS_SORTING. ^= 0 %then %do ;

    /*create datasets storing sorting variables*/
    ods html close ;
    ods output Sortedby = WORK._SORT_DS ;
/*  ods select Sortedby ;*/
    proc datasets lib = &LIB_BASE. nolist nowarn;
        contents    
            data = _all_
        ;
    quit ;

    /*merge*/
    proc sql ;
        create table WORK._LST_DS_2 as
            select  monotonic() as id , memname , vars_sort
            from    WORK._LST_DS
                    natural left join (
                        select
                            btrim( upper( scan( member , -1 , "." ) ) ) as memname ,
                            cValue1 as vars_sort
                        from
                            WORK._SORT_DS
                        where label1 = "Sortedby"
                    )
        ;
    quit ;

    /*convert to macro variables*/
    proc sql noprint ;
        select      
                    vars_sort
            into    
                    :SORTS_1 - :SORTS_&MAX_DSN. 
            from    WORK._LST_DS_2
        ;
    quit ;

%end ;



/*delete intermediate datasets*/
%if &IS_DELETE. = 1 %then %do ; 

    proc datasets nolist nowarn library = work ;
        delete
            _SORT_DS:
            _LST_DS:
        ;
    quit ;

%end ;



/*
    perform proc compare
*/
ods html ;
%do I_DS = 1 %to &MAX_DSN. ;

    /*sort dataset in the library specified in LIB_COMP argument*/
    %if &IS_SORTING. ^= 0 %then %do ;
        %if &&SORTS_&I_DS. ^= %then %do ;
            proc sort data = &LIB_COMP..&&DSN_&I_DS. ;
                by &&SORTS_&I_DS. ;
            run ;
        %end ;
    %end ;

    title "Comparison for &&DSN_&I_DS." ;
    proc compare 
        base    = &LIB_BASE..&&DSN_&I_DS. 
        comp    = &LIB_COMP..&&DSN_&I_DS.

        %if &IS_OUT_DIF. = 1 %then %do ; 
            out     = WORK._RES_COMP_&I_DS. 
            outnoequal
        %end ;

/*      briefsummary*/

        listall
    ;
        %if &IS_SORTING. ^= 0 %then %do ;
            %if &&SORTS_&I_DS. ^= %then %do ;
                id &&SORTS_&I_DS. ;
            %end ;
        %end ;
    run ;

%end ;

title " " ;



%mend COMP_DS ;
