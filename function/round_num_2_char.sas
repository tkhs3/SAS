/*
    OBJECT
        Round numeric value to the specified digit and convert to character value

    CREATED BY
        tkhs3

    DATE
        2017/12/14

    ARGUMENTS/INPUTS
        val:
            required
                Yes
            data-type
                Numeric
            contents
                SAS Numeric variable name to round
        round:
            required
                Yes
            data-type
                Character/Numeric
            contents
                the number of digit to displey
                when adding "S"  as prefix to the number, round the value to significant digit
                    e.g.
                        3
                        "S3"
                        -3
                    
    SAMPLE
        options cmplib=work.funcs;
        data test_1 ;
            num = 123456789.123456789 ;
            char_1 = F_ROUND_NUM_2_CHAR( num, "3" ) ;
            char_2 = F_ROUND_NUM_2_CHAR( num, "S3" ) ;
            char_3 = F_ROUND_NUM_2_CHAR( num, "-3" ) ;

            put char_1 ;
            put char_2 ;
            put char_3 ;
        run ;
        /*
        Result

        123457000
        123000000
        123456789.123
        */
*/


proc fcmp outlib = WORK.FUNCS.INTEGER ;

    /*
        return rounding digit for siginicant digit
    */
    function F_GET_DIGIT_SIG( val , sig )  ;

        if int( val ) ^= 0 then do ;
            round =  
                    (  
                        int( 
                            log10( abs( val ) ) 
                        ) 
                        -
                        ( sig - 1 ) 
                    ) 
            ;
        end ;
        else if val = 0 then do ;
            round =  -( sig - 1 ) ;
        end ;
        else do ;
            round =  
                        -1 
                        * 
                        (   abs(
                                int( 
                                    log10( abs( val ) ) 
                                ) 
                            )
                            +
                            ( sig )
                        )
            ;
        end ;


        return( round ) ;
    endsub ;

run ;

proc fcmp outlib = WORK.FUNCS.STRING ;

    /*
        round the value and convet character
    */
    function F_ROUND_NUM_2_CHAR( val , round $ ) $ 32 ;

        /*for significant digit*/
        if index( upcase( round ) , "S" ) then do ;
            r = F_GET_DIGIT_SIG( 
                    val , 
                    input( compress( round , "" , "kd" ) , best. ) 
                ) 
            ;
        end ;
        else do ;
            r = input( round , best. ) ;
        end ;

        /*convert to character*/
        length f $ 32 ;
        f = cats( 
                "19." , 
                put( 
                    ifn( r >= 0 , 0 , abs( r ) , 0 )  , 
                    best.  
                )
            ) 
        ;
            

        return( left( putn( round( val , 10**r ) , f ) ) ) ;

    endsub ;

run ;



