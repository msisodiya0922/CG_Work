CREATE OR REPLACE PACKAGE BODY AR_CUST_BAL_RPT_PKG
AS
   FUNCTION BeforeReport RETURN BOOLEAN
   IS
    l_count1 number;
    l_count2 number;
   BEGIN
      P_CONC_REQUEST_ID := FND_GLOBAL.CONC_REQUEST_ID;
      P_SORT_BY_PHONETICS := FND_PROFILE.VALUE('RA_CUSTOMERS_SORT_BY_PHONETICS');

      IF P_SORT_BY_PHONETICS = 'Y'
      THEN
         P_SORT := 'HZP.ORGANIZATION_NAME_PHONETIC';
      ELSE
         P_SORT := 'HZP.PARTY_NAME';
      END IF;

      RETURN (TRUE);
   EXCEPTION
      WHEN OTHERS THEN
         P_SORT_BY_PHONETICS := 'N';
         P_SORT := 'HZP.PARTY_NAME';
   END;

   FUNCTION AfterReport RETURN BOOLEAN
   IS
   l_count1 number;
   l_count2 number;
   l_appl_id NUMBER;
   l_request_id NUMBER;
   p_status   VARCHAR2 (200);
   p_created_by VARCHAR2(100) ;
   
   BEGIN
        -------------------------------------------------------------------------------
	-- Start Of Update For Modification of MOD287 - Customer Statement Report 
	-------------------------------------------------------------------------------
	     P_CONC_REQUEST_ID := APPS.FND_GLOBAL.CONC_REQUEST_ID;
	     p_created_by      := APPS.FND_GLOBAL.USER_NAME;
	  
		 xxccms_logging_util.log_audit_msg
		         (p_transaction_request_id      => P_CONC_REQUEST_ID,
		          p_component_type              => xxccms_logging_util.c_comp_type_conc,
		          p_transaction_name            => 'MOD287 - DT02-107 - Customer Statement Report',
		          p_source_system               => xxccms_logging_util.c_message_type_ebs,
		          p_source_name                 => xxccms_logging_util.c_message_type_ccms,
		          p_target_system               => xxccms_logging_util.c_message_type_ebs,
		          p_target_name                 => xxccms_logging_util.c_message_type_ccms,
		          p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
		          p_process_name                => 'AR_CUST_BAL_RPT_PKG.AfterReport',
		          p_process_stage               => xxccms_logging_util.c_message_type_start,
		          p_log_type                    => xxccms_logging_util.c_message_type_info,
		          p_record_ref_key              => '- Request Id - ',
		          p_record_ref_value            => P_CONC_REQUEST_ID,
		          p_message_code                => '1',
		          p_message_description         => 'Start of After Report Trigger Function',
		          p_send_email                  => 'N',
		          p_email_id                    => NULL,
		          p_time_stamp                  => SYSDATE,
		          p_user_name                   => p_created_by,
		          p_status                      => p_status
		         );
				 
 
	  BEGIN
	  	
	  	-------------------------------------------------------
	  	-- Fetches the Application Id for Custom Application
	  	-------------------------------------------------------
	          
	            SELECT application_id
	            INTO l_appl_id
		    FROM fnd_application
		    WHERE application_short_name = 'XXCCMS';
		  
		  EXCEPTION
		  WHEN OTHERS THEN
		  
		    xxccms_logging_util.log_audit_msg
			    (p_transaction_request_id      => P_CONC_REQUEST_ID,
			     p_component_type              => xxccms_logging_util.c_comp_type_conc,
			     p_transaction_name            => 'MOD287 - DT02-107 - Customer Statement Report',
			     p_source_system               => xxccms_logging_util.c_message_type_ebs,
			     p_source_name                 => xxccms_logging_util.c_message_type_ccms,
			     p_target_system               => xxccms_logging_util.c_message_type_ebs,
			     p_target_name                 => xxccms_logging_util.c_message_type_ccms,
			     p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
			     p_process_name                => 'AR_CUST_BAL_RPT_PKG.AfterReport',
			     p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
			     p_log_type                    => xxccms_logging_util.c_message_type_error,
			     p_record_ref_key              => '- Request Id - ',
			     p_record_ref_value            => P_CONC_REQUEST_ID,
			     p_message_code                => '2',
			     p_message_description         =>    'Unknown error occurred while Fetching Application id - '
							      || ' ,refer logs for details'
							      || SUBSTR (SQLERRM, 1, 250),
			     p_send_email                  => 'N',
			     p_email_id                    => NULL,
			     p_time_stamp                  => SYSDATE,
			     p_user_name                   => p_created_by,
			     p_status                      => p_status
			    );
	  END;
	  
	           xxccms_logging_util.log_audit_msg
		         (p_transaction_request_id      => P_CONC_REQUEST_ID,
		          p_component_type              => xxccms_logging_util.c_comp_type_conc,
		          p_transaction_name            => 'MOD287 - DT02-107 - Customer Statement Report',
		          p_source_system               => xxccms_logging_util.c_message_type_ebs,
		          p_source_name                 => xxccms_logging_util.c_message_type_ccms,
		          p_target_system               => xxccms_logging_util.c_message_type_ebs,
		          p_target_name                 => xxccms_logging_util.c_message_type_ccms,
		          p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
		          p_process_name                => 'AR_CUST_BAL_RPT_PKG.AfterReport',
		          p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
		          p_log_type                    => xxccms_logging_util.c_message_type_info,
		          p_record_ref_key              => '- Request Id - ',
		          p_record_ref_value            => P_CONC_REQUEST_ID,
		          p_message_code                => '3',
		          p_message_description         => 'Submiting Concurrent Program XML Report Publisher For Generation of report',
		          p_send_email                  => 'N',
		          p_email_id                    => NULL,
		          p_time_stamp                  => SYSDATE,
		          p_user_name                   => p_created_by,
		          p_status                      => p_status
		         );
				
		-------------------------------------------------------------------------------------
		-- Submits the Concurrent Program XML Report Publisher to generate PDF report.
		-------------------------------------------------------------------------------------
	  
	             l_request_id := fnd_request.submit_request ( application      => 'XDO',
								  program          => 'XDOREPPB',
								  sub_request      => FALSE,
								  argument1        => 'Y',
								  argument2        => P_CONC_REQUEST_ID,
								  argument3        => l_appl_id,
								  argument4        => 'XXCCMSMOD287',
								  argument5        => NULL,
								  argument6        => 'N',
								  argument7        => 'RTF',
								  argument8        => 'PDF'
								 );
		    COMMIT;									
				  
			IF  l_request_id IS NOT NULL
			THEN
			      xxccms_logging_util.log_audit_msg
						 (p_transaction_request_id      => P_CONC_REQUEST_ID,
						  p_component_type              => xxccms_logging_util.c_comp_type_conc,
						  p_transaction_name            => 'MOD287 - DT02-107 - Customer Statement Report',
						  p_source_system               => xxccms_logging_util.c_message_type_ebs,
						  p_source_name                 => xxccms_logging_util.c_message_type_ccms,
						  p_target_system               => xxccms_logging_util.c_message_type_ebs,
						  p_target_name                 => xxccms_logging_util.c_message_type_ccms,
						  p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
						  p_process_name                => 'AR_CUST_BAL_RPT_PKG.AfterReport',
						  p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
						  p_log_type                    => xxccms_logging_util.c_message_type_info,
						  p_record_ref_key              => '- Request Id - ',
						  p_record_ref_value            => P_CONC_REQUEST_ID,
						  p_message_code                => '4',
						  p_message_description         => 'Submitted Concurrent Program XML Report Publisher with Request ID '||l_request_id ,
						  p_send_email                  => 'N',
						  p_email_id                    => NULL,
						  p_time_stamp                  => SYSDATE,
						  p_user_name                   => p_created_by,
						  p_status                      => p_status
						 );
			
			ELSE
			
			 xxccms_logging_util.log_audit_msg
					 (p_transaction_request_id      => P_CONC_REQUEST_ID,
					  p_component_type              => xxccms_logging_util.c_comp_type_conc,
					  p_transaction_name            => 'MOD287 - DT02-107 - Customer Statement Report',
					  p_source_system               => xxccms_logging_util.c_message_type_ebs,
					  p_source_name                 => xxccms_logging_util.c_message_type_ccms,
					  p_target_system               => xxccms_logging_util.c_message_type_ebs,
					  p_target_name                 => xxccms_logging_util.c_message_type_ccms,
					  p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
					  p_process_name                => 'AR_CUST_BAL_RPT_PKG.AfterReport',
					  p_process_stage               => xxccms_logging_util.c_message_type_intermediate,
					  p_log_type                    => xxccms_logging_util.c_message_type_warning,
					  p_record_ref_key              => '- Request Id - ',
					  p_record_ref_value            => P_CONC_REQUEST_ID,
					  p_message_code                => '5',
					  p_message_description         => 'Concurrent Program XML Report Publisher is not Submitted' ,
					  p_send_email                  => 'N',
					  p_email_id                    => NULL,
					  p_time_stamp                  => SYSDATE,
					  p_user_name                   => p_created_by,
					  p_status                      => p_status
					 );
					 
			END IF;
		
		
		  xxccms_logging_util.log_audit_msg
				 (p_transaction_request_id      => P_CONC_REQUEST_ID,
				  p_component_type              => xxccms_logging_util.c_comp_type_conc,
				  p_transaction_name            => 'MOD287 - DT02-107 - Customer Statement Report',
				  p_source_system               => xxccms_logging_util.c_message_type_ebs,
				  p_source_name                 => xxccms_logging_util.c_message_type_ccms,
				  p_target_system               => xxccms_logging_util.c_message_type_ebs,
				  p_target_name                 => xxccms_logging_util.c_message_type_ccms,
				  p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
				  p_process_name                => 'AR_CUST_BAL_RPT_PKG.AfterReport',
				  p_process_stage               => xxccms_logging_util.c_message_type_end,
				  p_log_type                    => xxccms_logging_util.c_message_type_info,
				  p_record_ref_key              => '- Request Id - ',
				  p_record_ref_value            => P_CONC_REQUEST_ID,
				  p_message_code                => '6',
				  p_message_description         => 'End of After Report Trigger Function',
				  p_send_email                  => 'N',
				  p_email_id                    => NULL,
				  p_time_stamp                  => SYSDATE,
				  p_user_name                   => p_created_by,
				  p_status                      => p_status
				 );
	      xxccms_logging_util.update_audit_status
	                    (p_component_type              => xxccms_logging_util.c_comp_type_conc,
	                     p_transaction_request_id      => P_CONC_REQUEST_ID,
	                     p_status                      => xxccms_logging_util.c_message_type_complete
	                    );									  
		
											  
      RETURN (TRUE);
	  
	  EXCEPTION
	  WHEN OTHERS 
	  THEN
	  RETURN (FALSE);
	    xxccms_logging_util.log_audit_msg
			    (p_transaction_request_id      => P_CONC_REQUEST_ID,
			     p_component_type              => xxccms_logging_util.c_comp_type_conc,
			     p_transaction_name            => 'MOD287 - DT02-107 - Customer Statement Report',
			     p_source_system               => xxccms_logging_util.c_message_type_ebs,
			     p_source_name                 => xxccms_logging_util.c_message_type_ccms,
			     p_target_system               => xxccms_logging_util.c_message_type_ebs,
			     p_target_name                 => xxccms_logging_util.c_message_type_ccms,
			     p_message_source_type         => xxccms_logging_util.c_message_type_plsql,
			     p_process_name                => 'AR_CUST_BAL_RPT_PKG.AfterReport',
			     p_process_stage               => xxccms_logging_util.c_message_type_end,
			     p_log_type                    => xxccms_logging_util.c_message_type_error,
			     p_record_ref_key              => '- Request Id - ',
			     p_record_ref_value            => P_CONC_REQUEST_ID,
			     p_message_code                => '7',
			     p_message_description         =>    'Unknown error occurred in After Report Trigger - '
							      || ' ,refer logs for details'
							      || SUBSTR (SQLERRM, 1, 250),
			     p_send_email                  => 'N',
			     p_email_id                    => NULL,
			     p_time_stamp                  => SYSDATE,
			     p_user_name                   => p_created_by,
			     p_status                      => p_status
			    );
         xxccms_logging_util.update_audit_status
                    (p_component_type              => xxccms_logging_util.c_comp_type_conc,
                     p_transaction_request_id      => P_CONC_REQUEST_ID,
                     p_status                      => xxccms_logging_util.c_message_type_error
                    );
	  
	 ------------------------------------------------------------------------------
	-- End of update for Modification of MOD287 - Customer Statement Report 
	-------------------------------------------------------------------------------
   END;

END AR_CUST_BAL_RPT_PKG;
/

Show Err;
