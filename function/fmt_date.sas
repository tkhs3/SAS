/*
    OBJECT
        Convert date or datetime represented in numeric to arbitrarily formatted string using format elements.

    CREATED BY
        tkhs3

    DATE
        2017/12/08

    ARGUMENTS/INPUTS
        str:
            required
                Yes
            data-type
                Character
            contents
                SAS Character variable or Character literal represent date or datetime
                it is recommended to comply formats like SAS YMDDTTM informat or ISO 8601 notation to represent date or datetime
                    e.g. 
                        20171208
                        20171208T000000
        fmt:
            required
                Yes
            data-type
                Character
            contents
                SAS Character literal represent formatted date or datetime using format elements
                    format elements
                        date elements
                            YYYY
                                4-digit year(e.g. 2017)
                            YY
                                2-digit year(e.g. 17)
                            MMM
                                3-character month(e.g. DEC)
                            MM
                                2-digit month(e.g. 12)
                            DDD
                                3-digit day(e.g. 342)
                                    i.e. the number of the day in that year
                            DD
                                2-digit day(e.g. 08)
                        
                        time elements
                            HH
                                2-digit hour(e.g. 12)
                            MM
                                2-digit minute(e.g. 33)
                            SS
                                2-digit second(e.g. 39)
                    e.g.
                        yyyy : mm : dd
                        yyyy : mm : dd / hh : mm : ss
                    
    SAMPLE
        options cmplib = work.funcs ;
        data test_1 ;

            date = "20110311" ;
            date_fmt = F_FMT_DATE( date, "yyyy : mm : dd" ) ;

            datetime = "20110311T123339" ;
            datetime_fmt = F_FMT_DATE( datetime, "yyyy : mm : dd / hh : mm : ss" ) ;

            put date_fmt ;
            put datetime_fmt ;
        run ;
        
        /* 
            result
            
            2011 : 03 : 11
            2011 : 03 : 11 / 12 : 33 : 39
        */
*/

proc fcmp outlib = WORK.FUNCS.STRING ;

    function F_FMT_DATE( str $ , fmt $ ) $ 32 ;

        /*informat prototype*/
        array tp_dttm[7] $ 32 (
            "xxxx-xx-xx xx:xx:xx"       /*YMDDTTM*/
            "xx-xx-xxxx xx:xx:xx AM"    /*MDYAMPM*/
            "xxxxxxx xx:xx:xx"          /*DATETIME*/
            "xxxx-xx-xxTxx:xx:xx"       /*E8601DT*/
            "xxxxxxxxTxxxxxx"           /*B8601DT*/
            "xxxx-xx-xx"                /*E8601DN*/
            "xxxxxxxx"                  /*B8601DN*/
        ) ;

        /*informat name*/
        array nm_dttm[7] $ 32 (
            "YMDDTTM"                   /*YMDDTTM*/
            "MDYAMPM"                   /*MDYAMPM*/
            "DATETIME"                  /*DATETIME*/
            "E8601DT"                   /*E8601DT*/
            "B8601DT"                   /*B8601DT*/
            "E8601DN"                   /*E8601DN*/
            "B8601DN"                   /*B8601DN*/
        ) ;

        /*convert digits*/
        str_tp    = translate( str , "xxxxxxxxxx" , "0123456789" ) ;

        /*exception for non-digit input*/
        if index( str_tp , "x" ) = 0 then do ;
            return( "" );
        end ;

        /*calculate similarity between informat and input*/
        array sim_dttm[7] _temporary_ ;
        do i = 1 to hbound( tp_dttm ) ;

            sim_dttm[ i ] = compged( str_tp , tp_dttm[ i ] ,":l" ) ;
/*            put sim_dttm[ i ] = ;*/
        end ;

        /*select best matching format*/
        max_sim =   min( sim_dttm[1] , sim_dttm[2] , sim_dttm[3] , sim_dttm[4] , sim_dttm[5] , sim_dttm[6] , sim_dttm[7] ) ;
        i_max   =   whichn( max_sim ,  sim_dttm[1] , sim_dttm[2] , sim_dttm[3] , sim_dttm[4] , sim_dttm[5] , sim_dttm[6] , sim_dttm[7]  ) ;

        /*use anydtdtm informat if similariy below threshold*/
        if max_sim < 190 then do ;
            dttm    = 
                        inputn( 
                            str , 
                            cats( nm_dttm[ i_max ] ,  "." ) 
                        ) 
            ;
        end ;
        else do ;
            dttm    = 
                        inputn( 
                            str , 
                            "ANYDTDTM." 
                        ) 
            ;
        end ;
        date    =   datepart( dttm ) ;
        time    =   timepart( dttm ) ;

/*        put dttm= date= time= ;*/
        /*convert date format elements*/
        length f $ 32 ;
        f = strip( fmt ) ;
        yyyy    =   put( year( date ) , z4. ) ;
        yy      =   put( date , year2. ) ;
        mmm     =   upcase( put( date , monname3. ) ) ;
        mm      =   put( month( date ) , z2. ) ;
        ddd     =   put( date , julday3. ) ;
        dd      =   put( day( date ) , z2. ) ;
        array dates[*] yyyy -- dd ;
        array nm_dates[6] $ 8 _temporary_ ( "yyyy" , "yy" , "mmm" , "mm" , "ddd" , "dd" ) ;
/*        put f= yyyy= ;*/
        do i = 1 to hbound( nm_dates ) ;
            pos = find( f , nm_dates[ i ]  , "IT" ) ;
/*            pos = index( f , strip( upcase( vname( dates[ i ] ) ) )  ) ;*/
            if pos ^= 0 then do ;
                f = kupdate( f , pos , length( nm_dates[ i ] ) , strip( dates[ i ] ) ) ;
                /*skip if long format is used*/
                if mod( i , 2 ) = 1 then do ;
                    i + 1 ;
                end ;
            end ;
        end ;

        /*convert time format elements*/
        hh      =   put( hour( time ) , z2. ) ;
        mm      =   put( minute( time ) , z2. ) ;
        ss      =   put( second( time ) , z2. ) ; 
        array times[*] hh mm ss ;
        array nm_times[3] $ 8 _temporary_ ( "hh" , "mm" , "ss" ) ;
        do i = 1 to hbound( times ) ;
            pos = find( f , nm_times[ i ] , "IT" ) ;
            if pos ^= 0 then do ;
                f = kupdate( f , pos , length( nm_times[ i ] ) , strip( times[ i ] ) ) ;
            end ;
        end ;

        return( f ) ;

    endsub ;

run ;


