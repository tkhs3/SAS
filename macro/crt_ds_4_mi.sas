/*
	OBJECT
		Impute missing value of variables in specified dataset

	CREATED BY
		tkhs3

	DATE
		2017/11/17

	ARGUMENTS/INPUTS
		ds_in:
			required
				Yes
			data-type
				Character
			contents
				SAS Dataset name (1-level or 2-level) from which the dataset to impute is read
					e.g. work.test
		ds_out:
			required
				No
			data-type
				Character
			contents
				SAS Dataset name (1-level or 2-level) with which imputed datasets is created
					e.g. work.test_mi
				default		-> create imputed dataset with same name specified in the argument "ds_in"
		num:
			required
				No
			data-type
				Integer
			contents
				default		-> do not impute interger variables
				Integer		-> assign this specified value to the variables specifying "var_num" or "vars" in arguments
					e.g. 0
		char:
			required
				No
			data-type
				Character
			contents
				default		-> do not impute character variables
				Integer		-> assign this specified value to the variables specifying "var_char" or "vars" in arguments
					e.g. NA
		vars:
			required
				No
			data-type
				Character
			contents
				SAS Variable names to impute, separated by white-space, for both Numeric and Character Variable
				default			-> impute variables specifying "var_num" or "var_char" in the arguments
				Variable names	-> impute only variables specified in this argument
					e.g. test_num_1 test_char_1
					
		var_num:
			required
				No
			data-type
				Character
			contents
				SAS Variable names to impute, separated by white-space, only for Numeric Variable
				able to specify Variable Lists
				default 		-> impute all missing numeric variables
				Variable names	-> impute only variables specified in this argument
					e.g. test_num_1 test_num_2
					
		var_char:
			required
				No
			data-type
				Character
			contents
				SAS Variable names to impute, separated by white-space, only for Character Variable
				able to specify Variable Lists
				default 		-> impute all missing character variables
				Variable names	-> impute only variables specified in this argument
					e.g. test_char_1 test_char_2

	OUTPUTS
		SAS Dataset
			with the name specified in the argument "ds_out"
			imputed by the value specified in the arguments "num" or "char" for variables specified in the arguments "vars", "var_num" or "var_char"

	SAMPLE
		data test ;
			test_num_1 = 1 ;
			test_num_2 = . ;
			test_char_1 = "1" ;
			test_char_2 = "  " ;
			output ;
		run ;
		%crt_ds_4_mi(
		    ds_in       = test ,
		    ds_out      = test_mi_1
		,	num         = 0
		,	char        = NA
		);
		%crt_ds_4_mi(
		    ds_in       = test ,
		    ds_out      = test_mi_2
		,	char        = NA
		);
		%crt_ds_4_mi(
		    ds_in       = test ,
		    ds_out      = test_mi_3
		,	num         = 0
		);
		%crt_ds_4_mi(
		    ds_in       = test ,
		    ds_out      = test_mi_4
		,	vars		= test_num_2 test_char_2
		,	num         = 0
		,	char        = NA
		);
		%crt_ds_4_mi(
		    ds_in       = test 
		,	num         = 0
		,	char        = NA
		);
*/



%macro CRT_DS_4_MI(
    	DS_IN       = ,
    	DS_OUT      =

    ,	VARS        =
    ,	VAR_NUM     = _numeric_
    ,	VAR_CHAR    = _character_
    
    ,	NUM         =
    ,	CHAR        = 
); 



/*create macro variables, storing variable names and number of variables*/
%if &VARS ^= %then %do ;
    %let VARS =    %sysfunc(
                        compbl(
                            &VARS.
                        )
                    ) 
    ;
    %let MAX_VARS =    %sysfunc(
                            countc( 
                                &VARS. ,
                                %str( )
                            )
                        )
    ;
    %let MAX_VARS = %eval( &MAX_VARS. + 1 ) ;
    %do I_VAR = 1 %to &MAX_VARS. ;
        %let VARS_&I_VAR. = %scan(&VARS.,&I_VAR.,%str( )) ;
    %end ;
%end ;

/*set "DS_OUT" if not specified*/
%if &DS_OUT. = %then %do ;
	%let DS_OUT = &DS_IN. ;
%end ;



/*
	impute dataset
*/
data &DS_OUT. ;
    set &DS_IN. ;

    /*process all variable types*/
    %if &VARS. ^= %then %do ;
        %do I_VAR = 1 %to &MAX_VARS. ;
            
            if missing( &&VARS_&I_VAR. ) then do ;
            
            	%if &CHAR. ^= %then %do ;
	                if vtype( &&VARS_&I_VAR. ) = "C" then do ;
	                    &&VARS_&I_VAR. = "&CHAR." ;
	                end ;
                %end ;
                
                %if &NUM. ^= %then %do ;
	                if vtype( &&VARS_&I_VAR. ) = "N" then do ;
						if index( vvalue( &&VARS_&I_VAR. ) , "." ) then do ;
	                    	&&VARS_&I_VAR. = &NUM. ;
						end ;
	                end ;
                %end ;
                
            end ;
            
        %end ;
    %end ;
    
    /*process by each variable types*/
    %else %do ;
        %if &NUM. ^= %then %do ;
			array nums[*] &VAR_NUM. ;
			drop i ;
            do i = 1 to hbound( nums ) ;
                if missing( nums[ i ] ) then
                    nums[ i ] = &NUM. ;
            end ;
        %end ;

        %if &CHAR. ^= %then %do ;
			array chars[*] &VAR_CHAR. ;
			drop i ;
            do i = 1 to hbound( chars ) ;
                if chars[ i ] in ( "" "." ) then
                    chars[ i ] = "&CHAR." ;
            end ;
        %end ;

    %end ;

run ;

%mend CRT_DS_4_MI ;

