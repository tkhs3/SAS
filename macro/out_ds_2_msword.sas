/*
    OBJECT
        Output a dataset to the pre-existing table in the MS-Word file
            which is typically separate mock-up file composing an entire report

    CREATED BY
        tkhs3

    DATE
        2017/12/01

    ARGUMENTS/INPUTS
        ds_in:
            required
                Yes
            data-type
                Character
            contents
                SAS Dataset name (1-level or 2-level) of which contents is outputted to the pre-existing table in the MS-Word file 
                    e.g. work.test
        vars:
            required
                No
            data-type
                Character
            contents
                SAS Variable names in the dataset specified in the argument "ds_in" to output
                    e.g. _all_
                default -> output all variables in the dataset
                others  -> output only specified variables in the dataset

    REQUIREMENTS
        1:
            the MS-Word file containing a table should be opened prior executing this macro
    
    COMPLEMENTARIES
        It is highly recommended to use this macro with other utility macros for MS-Word
            e.g.
                author
                    Koen Vyverman(1999)
                file
                    DDE Word Macros R2.sas
                source
                    "Fancy MS Word Reports Made Easy: Harnessing the Power of Dynamic Data Exchange — Against All ODS, Part II." 
                    Proceedings of the 28th SAS Users Group International Conference, 2003.
                    http://www.sas-consultant.com/professional/papers.html
                    
    SAMPLE
        %out_ds_2_msword(
                ds_in = work.test
        );
*/


%macro out_ds_2_msword(
    ds_in     = 
,   vars      = _all_
)  ;

    data work._out_4_word;
        _id = _n_;
        set &ds_in(keep=&vars.);
    run;

    proc sort;
        by descending _id;
    run;

    filename sas2word dde 'winword|system';
    data work._res_out;
        set work._out_4_word end=e ;
        file sas2word;
  
    /*
      move to the rightmost and lowermost cell
    */
    if _n_ = 1 then do;

        /*move to the first table*/
        put '[EditGoto.Destination="t"]';
        put '[EditGoto.Destination="t"]';
        put '[TableSelectTable]';

        /*first cell*/
        put '[StartOfRow]';

        /*move to the last row*/
        put '[EndOfColumn]';

        /*move to the last column*/
        put '[EndOfRow]';

    end;

    /* output data in row-wise from right to left */
    array vars[*] &vars. ;
    max_vars = hbound(vars) ;
    do i=max_vars to 1 by -1 ;

        /*select last cell*/
        if i=max_vars then do ;
            put '[PrevCell]' ;
            put '[NextCell]' ;
        end ;
        
        length cmd $ 256 ;
        cmd = '[Insert ' || quote(strip(vars[i])) || ']';
        put cmd;
        
        /*move to next column if any*/
        if i ^= 1 then do ;
            put '[PrevCell]' ;
            put '[PrevCell]' ;
            put '[NextCell]' ;
        end ;
    end ;

    /*
      move to upward
    */
    put '[StartOfRow]';
    put '[PrevCell]';

  run;

%mend out_ds_2_msword;

