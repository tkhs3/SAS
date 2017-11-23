/*
    OBJECT
        Compare MS-Excel files between different folders,
            creating the report of results from comparing each files

    CREATED BY
        tkhs3

    DATE
        2017/11/23

    ARGUMENTS/INPUTS
        fol_base:
            required
                Yes
            data-type
                Character
            contents
                full path of Windows Folder in which the base version of MS-Excel files to compare stored
                    e.g. C:\base
        fol_comp:
            required
                Yes
            data-type
                Character
            contents
                full path of Windows Folder in which the another version of MS-Excel files to compare stored
                    e.g. C:\comp
        fol_out:
            required
                No
            data-type
                Character
            contents
                full path of Windows Folder in which the report of comparing save 
                    e.g. C:\results
                default -> Windows home directory
        nm_file_out:
            required
                No
            data-type
                Character
            contents
                the name of file with which the report of comparing save
                    e.g. TFL
                default -> TFL
        prefix_out:
            required
                No
            data-type
                Character
            contents
                the prefix that is added to the name of file of the report
                    e.g. COMP_
                default -> COMP_
        suffix_out:
            required
                No
            data-type
                Character
            contents
                the prefix that is added to the name of file of the report
                    e.g. _20171123T000000
                default -> _yyyymmddThhmmss (i.e. datetime represented in ISO 8601 notation)
        easy_comp:
            required
                No
            data-type
                Integer
            contents
                Integer value corresponds to the method of comparing for each cells value in MS-Excel sheet
                1           ->  perform comparing after conveting text with
                                    case-insensitive + DBCS-incensitive for alphanumeric + trim leading and trailing spaces + compression for spaces in the middle of text
                2 (default) ->  perform comparing after conveting text with
                                    case-insensitive + DBCS-incensitive for alphanumeric + space-incensitive
                others      ->  perform comparing with no-conversion

    OUTPUTS
        SAS Listing File
            with the same name of MS-Excel file compared using this macro
                adding prefix and suffix specified in the arguments "prefix_out" or "suffix_out"
                e.g. COMP_filename_yyyymmddThhmmss.lst
                
        MS-Excel File
            with the name specified in the arguments "nm_file_out"
                adding prefix and suffix specified in the arguments "prefix_out" or "suffix_out"
                e.g. COMP_TFL_yyyymmddThhmmss.xlsx

    SAMPLE
        %let fol_home = C:\Users\username
        data 
            test1 
            test2
        ;
            _e = 1.0e-2 ;
            do _ds=1 to 2;
                do id=1 to 100 ;
                    if ranuni( 3 ) >= _e then one   = id ;
                    if ranuni( 3 ) >= _e then two   = id**2 ;
                    if ranuni( 3 ) >= _e then three = id**3 ;

                    if _ds = 1 then output test1 ;
                    if _ds = 2 then output test2 ;
                    call missing( of one -- three ) ;
                end ;
            end ;
            drop : ;
        run ;

        proc export
            data    = test1
            outfile = "&fol_home.\test1\test.xlsx"
            dbms    = xlsx
            replace
        ;
        run ;
        proc export
            data    = test2
            outfile = "&fol_home.\test2\test.xlsx"
            dbms    = xlsx
            replace
        ;
        run ;

        %COMP_EXCEL(
            FOL_BASE    = &fol_home.\test1 ,
            FOL_COMP    = &fol_home.\test2 ,
            FOL_OUT     = &fol_home.
        );
*/



%macro COMP_EXCEL(
    FOL_BASE    = ,
    FOL_COMP    = ,
    FOL_OUT     = ,

    ,   NM_FILE_OUT = TFL
    ,   PREFIX_OUT  = COMP_ 
    ,   SUFFIX_OUT  = _%cmpres(%sysfunc( datetime() , B8601DT. )) 
    .   EASY_COMP   = 2
) ;



/*
    format when specifing dataset name in statements such as "set" or "proc sql"
*/
%let FMT_DSN_4_DBCS = "@@@"n ;



/*
    セルの値比較用マクロ
*/
%if &EASY_COMP. = 1 %then %do ;
    %macro _FMT_COMP( STR );

        ktrim(
            kleft(
                compbl(
                    kupcase(
                        ktranslate( 
                            kpropcase( &STR. , "FULL-ALPHABET, HALF-ALPHABET" ) , 
                            &STR. ,
                            " " , 
                            "　" 
                        )
                    )
                )
            )
        )

    %mend _FMT_COMP ;
%end ;
%else %if &EASY_COMP. = 2 %then %do ;
    %macro _FMT_COMP( STR );

        kcompress(
            kupcase(
                ktranslate( 
                    kpropcase( &STR. , "FULL-ALPHABET, HALF-ALPHABET" ) , 
                    &STR. ,
                    " " , 
                    "　" 
                )
            )
        )

    %mend _FMT_COMP ;
%end ;
%else %do ;
    %macro _FMT_COMP( STR );
        &STR.
    %mend _FMT_COMP ;
%end ;



/*
    search files to compare
*/
filename lst_base   pipe " where /R &FOL_BASE. /T *.xlsx " lrecl = 4096 ;
filename lst_comp   pipe " where /R &FOL_COMP. /T *.xlsx " lrecl = 4096 ;

data WORK._LIST_BASE ;

    infile lst_base ;
    input ;

    length
        p   $ 512
        f   $ 512
        fp  $ 512
        d   $ 512
        t   $ 512
        s   $ 512
    ;

    s   = kscan( _infile_ , 1 , " " ) ;
    d   = kscan( _infile_ , 2 , " " ) ;
    t   = kscan( _infile_ , 3 , " " ) ;
    fp  = kscan( _infile_ , 4 , " " ) ;
    f   = kscan( fp , -1 , "\" ) ;
    p   = tranwrd( fp , cats( "\" , f ) , "" ) ;

    /*only files exist in specified folder*/
    if kstrip( kupcase( p ) ) = kstrip( kupcase( "&FOL_BASE." ) ) ;

run ;

data WORK._LIST_COMP ;

    infile lst_comp ;
    input ;

    length
        p   $ 512
        f   $ 512
        fp  $ 512
        d   $ 512
        t   $ 512
        s   $ 512
    ;

    s   = kscan( _infile_ , 1 , " " ) ;
    d   = kscan( _infile_ , 2 , " " ) ;
    t   = kscan( _infile_ , 3 , " " ) ;
    fp  = kscan( _infile_ , 4 , " " ) ;
    f   = kscan( fp , -1 , "\" ) ;
    p   = tranwrd( fp , cats( "\" , f ) , "" ) ;

    /*only files exist in specified folder*/
    if kstrip( kupcase( p ) ) = kstrip( kupcase( "&FOL_COMP." ) ) ;

run ;

proc sql ;

    create table WORK._LIST_TFL_2_COMP as

        select  base.p as p_base , comp.p as p_comp ,
                base.*

        from    WORK._LIST_BASE as base
                
                inner join
                    WORK._LIST_COMP as comp
                        on base.f = comp.f

        order by base.f

    ;

quit ;



/*
    create macro variables
*/
data WORK._LIST_TFL_2_COMP_2 ;

    /*no_obs*/
    _id = _n_ ;

    set WORK._LIST_TFL_2_COMP end = e ;

    /*full path*/
    fp_base = ktrim(p_base) || "\" || ktrim(f)  ;
    fp_comp = ktrim(p_comp) || "\" || ktrim(f)  ;

    length nm_file $ 256 ;
    _nm_file    = kscan( f , 1 , "." ) ;                    /*ファイル名から拡張子の除去*/
    __nm_file = _nm_file ;
    if klength( _nm_file ) >= 13 then __nm_file = kcompress( ktranslate( _nm_file , "" , "0123456789" ) ) ; /*数字の除去*/
    ___nm_file  = ksubstr( __nm_file , 1 , 13 ) ;           /*最大長23bitに打ち切り*/
    nm_file     = ktranslate( ___nm_file , "_" , "-" ) ;    /*データセット名に使用不可能な文字の変換*/

    /*マクロ変数の作成*/
    call symputx( "FP_BASE_" || put( _n_ , best. -l ) , fp_base ) ;
    call symputx( "FP_COMP_" || put( _n_ , best. -l ) , fp_comp ) ;
    call symputx( "NM_FILE_" || put( _n_ , best. -l ) , nm_file ) ;

    if e then do ;

        call symputx( "MAX_FILE"  , _n_ ) ;
    end ;
run ;



/*
    compare per MS-Excel file per Sheet
*/
ods html close ;
title " " ;
options validmemname = extend ;
/*output distination of the report*/;
ods excel 
    file = "&FOL_OUT.\&PREFIX_OUT.&NM_FILE_OUT.&SUFFIX_OUT..xlsx" 
;
/*options linesize = 169 ;*/

%do I_FILE = 1 %to &MAX_FILE. ;



    /*assign libref for each files*/
/*  libname BASE pcfiles path = "&&FP_BASE_&I_FILE." access = readonly ;*/
/*  libname COMP pcfiles path = "&&FP_COMP_&I_FILE." access = readonly ;*/
    libname BASE xlsx  "&&FP_BASE_&I_FILE." access = readonly ;
    libname COMP xlsx  "&&FP_COMP_&I_FILE." access = readonly ;


    /*extract the sheet name in the same file*/
    proc sql ;

        create table WORK."_LIST_&&NM_FILE_&I_FILE."n as

                select  memname
                from    DICTIONARY.TABLES
                where   libname = "BASE"

            intersect 

                select  memname
                from    DICTIONARY.TABLES
                where   libname = "COMP"
        ;

    quit ;



    /*continue if any same sheets*/
    %let MAX_SHEET = &SQLOBS. ;
    %if &MAX_SHEET. ^= 0 %then %do ;

        /*create macro variables for sheet name*/
        data WORK."__LIST_&&NM_FILE_&I_FILE."n ;
            set WORK."_LIST_&&NM_FILE_&I_FILE."n end = e ;

            /*exclude #Print_Area*/
/*          if ^kindex( memname , "#" ) and ^kindex( memname , "Print" ) ;*/
            if ^kindex( memname , "#" ) and ^kindex( memname , "_xlnm" ) ;

            /*count the number of sheet*/
            cnt_sheet + 1 ;

            length dsn_fmt $ 32 ;
            dsn_fmt =   tranwrd( 
                            trim( symget("FMT_DSN_4_DBCS" ) ) ,
                            "@@@" ,
                            ktrim( memname )   
                        ) 
            ;

            /*convet unavailable characters for dataset name*/
            _nm_sds = memname ;
            if klength( _nm_sds ) >= 13 then _nm_sds = kcompress( ktranslate( _nm_sds , "" , "0123456789" ) ) ; /*digits*/
            __nm_sds    = ksubstr( _nm_sds , 1 , 13 ) ;         /*truncate for dataset name*/
            nm_sds = ktranslate( __nm_sds , "_" , "-" ) ;

            call symputx( "NM_SDS_" || put( cnt_sheet , best. -l ) , nm_sds ) ; /*dataset name for creating intermediate dataset*/
            call symputx( "NM_DS_" || put( cnt_sheet , best. -l ) , memname ) ; /*dataset name for reference to original dataset*/
            call symputx( "NM_SHEET_" || put( cnt_sheet , best. -l ) , dsn_fmt ) ;


            call symputx( "MAX_SHEET_2"  , cnt_sheet ) ;

        run ;



        /* 
            output distination for SAS Lisiting file
            <output path>\<file name><Suffix>.lst 
        */
        ods listing file = "&FOL_OUT.\&PREFIX_OUT.&&NM_FILE_&I_FILE..&SUFFIX_OUT..lst" ;

        /*perform proc compare for each sheet*/
        %do I_SHEET = 1 %to &MAX_SHEET_2. ;

            ods excel select none ;
            proc compare 
                base    = BASE.&&NM_SHEET_&I_SHEET.
                comp    = COMP.&&NM_SHEET_&I_SHEET.
                /* _RES_COMP_<No_file>_<No_sheet> */
                out     = WORK._DIF_COMP_&I_FILE._&I_SHEET.
                briefsummary
                outnoequal
            ;
            run ;


            /*create dataset for difference*/
            proc sql ;

                create table  WORK._RES_COMP_TFL_&I_FILE._&I_SHEET. as


                    select
                        &I_FILE. as _id ,
                        "&&NM_FILE_&I_FILE." as nm_file length = 256 ,
                        "&&NM_DS_&I_SHEET." as nm_sheet length = 32 ,
                        coalesce( nobs , 0 ) as dif 

                    from    DICTIONARY.TABLES 

                    where   trim(upcase(memname)) = trim(upcase("_DIF_COMP_&I_FILE._&I_SHEET."))

                ;

            quit ;



            /*the number of record in the dataset resulted from proc compare*/
            proc sql noprint ;
                select  1
                        from WORK._DIF_COMP_&I_FILE._&I_SHEET.
                ;
            quit ;



            /*continue if any difference in the sheet*/
            %if &SQLOBS ^= 0 %then %do ;

                /*create macro variable for columns*/
                proc sql noprint ;
                    select  count(*)
                            into    :MAX_VAR_B
                            from    DICTIONARY.COLUMNS
                            where   libname = "BASE" and memname = "&&NM_DS_&I_SHEET."
                    ;
                    select  count(*)
                            into    :MAX_VAR_C
                            from    DICTIONARY.COLUMNS
                            where   libname = "COMP" and memname = "&&NM_DS_&I_SHEET."
                    ;
                    /*the max number of variables in sheets*/
                    %let MAX_VAR = %cmpres( %sysfunc( min( &MAX_VAR_B. , &MAX_VAR_C. ) ) ) ;
                    select  name
                            into    :NM_VAR_1 - :NM_VAR_&MAX_VAR.
                            from    DICTIONARY.COLUMNS
                            where   libname = "BASE" and memname = "&&NM_DS_&I_SHEET."
                    ;
                quit ;



                /*add surrogate key*/
                proc sql ;
                    
                    create table WORK._BASE as
                        select  monotonic() as _id , *
                        from    BASE.&&NM_SHEET_&I_SHEET.
                    ;
                quit ;
                proc sql ;
                    create table WORK._COMP as
                        select  monotonic() as _id , *
                        from    COMP.&&NM_SHEET_&I_SHEET.
                    ;
                quit ;



                /*create dataset for reporting, align columns*/
                proc sql ;
                    
                    create table WORK."_&&NM_FILE_&I_FILE..@&&NM_SDS_&I_SHEET.."n as

                        select
                                /*id*/
                                coalesce( B._id , C._id ) as _id , 

                                %do I_VAR = 1 %to &MAX_VAR. ;

                                    %if &I_VAR ^= 1 %then %do ;
                                        ,
                                    %end ;

                                    B.&&NM_VAR_&I_VAR.. as COL_&I_VAR._B , /*Base column*/
                                    C.&&NM_VAR_&I_VAR.. as COL_&I_VAR._C   /*Comp column*/

                                %end ;


                        from    WORK._BASE as B

                                full join
                                    WORK._COMP as C
                                    on B._id = C._id 
                    ;
                quit ;



                /*create flags for each same columns*/
                data WORK."__&&NM_FILE_&I_FILE..@&&NM_SDS_&I_SHEET.."n ;
                    set WORK."_&&NM_FILE_&I_FILE..@&&NM_SDS_&I_SHEET.."n ;
                    /* flag of dif*/ 
                    %do I_VAR = 1 %to &MAX_VAR. ;
                        _flg_COL_&I_VAR.    =
                                                ^( 
                                                    %_FMT_COMP( vvalue( COL_&I_VAR._B ) ) 
                                                    = 
                                                    %_FMT_COMP( vvalue( COL_&I_VAR._C ) ) 
                                                ) 
                        ;
                    %end ;
                run ;



                /*create dataset for repoting*/
                data WORK._DATA_REP ;

                    /*flag for difference*/
                    flg_dif = . ;

                    set WORK."__&&NM_FILE_&I_FILE..@&&NM_SDS_&I_SHEET.."n ;

                    /*exclude all missing rows*/
/*                  if cats( of _character_ ) ^= "" ;*/

                    flg_dif = sum( of _flg_col: ) ;

                run ;



                /*output sheet*/
                ods excel select all ;
                ods excel 
                    style = htmlBlue 
                    options(
                        autofilter = "1" /*filter for n_dif*/
                        sheet_interval= "proc"
                        sheet_name = "&&NM_FILE_&I_FILE..>&&NM_DS_&I_SHEET.."
                        frozen_headers='3'
                    )
                ;
                ods listing select none ;
                proc report data = WORK._DATA_REP nowd ;

                    /*variable to use*/
                    column
                        ("N_dif" flg_dif) 

                        %do I_VAR = 1 %to &MAX_VAR. ;
                            /*create spans for eash same columns*/
                            ( "COL_&I_VAR." COL_&I_VAR._B COL_&I_VAR._C _flg_COL_&I_VAR.  )
                        %end ;
                    ;

                    define flg_dif / display " " ;

                    /*define for each same variables*/
                    %do I_VAR = 1 %to &MAX_VAR. ;

                        /*functionality, label*/
                        define COL_&I_VAR._B / display "B" ;
                        define COL_&I_VAR._C / display "C" ;
                        define _flg_COL_&I_VAR. / display noprint ;

                        /*highlight difference cells*/
                        compute _flg_COL_&I_VAR ;
                            if _flg_COL_&I_VAR = 1 then do ;
                                call define("COL_&I_VAR._B", "style", "style= [ background = red ]") ; 
                                call define("COL_&I_VAR._C", "style", "style= [ background = red ]") ; 
                            end ;
                        endcomp ;
                    %end ;
                    

                quit ;
                ods excel select none ;
                ods listing select all ;




            %end ;  /*SQLOBS*/

        %end ; /*I_SHEET*/

        ods listing close ;

    %end ; /*MAX_SHEET*/

%end ; /*I_FILE*/



/*
    summarize the results of comparing for each sheet
*/
data WORK.RES_COMP ;
    set WORK._RES_COMP_TFL_: ;
run ;
proc sort ;
    by _id ;
run ;



/*
    output summary report
*/
ods excel 
    style = htmlBlue 
    options(
        autofilter = "none"
        sheet_interval= "proc"
        sheet_name = "SUMMARY"
        frozen_headers='1'
    )
;
proc print data = WORK.RES_COMP label noobs ;
    title "the summary of comparing" ;
    label
        nm_file     = "file name"
        nm_sheet    = "sheet name"
        dif         = "number of difference"
    ;
run ;



/*close ods*/
ods excel close ;
ods html ;



/*releace libref*/
libname BASE clear ;
libname COMP clear ;



%mend COMP_EXCEL ;