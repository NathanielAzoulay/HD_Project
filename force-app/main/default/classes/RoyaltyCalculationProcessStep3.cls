/**************************************************************************************** 
	Name              : RoyaltyCalculationProcessStep3
	Description 	  : Step 3 - this step will RUN ON ALL Royalty Calculation new records and calculate the Calculated Percent, according to Agreement Parameters, 
						Calculated students and Account Type and save the Calculated Percent in Royalty calculation record.
							a.	The process will calculate the Calculated Royalties for each Agreement per Month as the Calculated Percent * Calculated Income.
 	Revision History  :-
	Created/Modified by   		Created/Modified Date     Requested by      Related Task/Issue  
	----------------------------------------------------------------------------------------
	1. Hernan (Created)			06/17/2016                Yaara		           [SW-18002]
	1. Hernan 					09/03/2016                Yaara		           [SW-19971] QA - Number of Students = 0
	----------------------------------------------------------------------------------------	
****************************************************************************************/
global class RoyaltyCalculationProcessStep3 implements Database.Batchable<sObject>, Database.Stateful{
	
	public static Decimal DEFAULT_FROM_MF = 50;
	public static Decimal DEFAULT_FROM_OTHER = 14;

	global String processName 					{get; set;}
	global Decimal rollback_key					{get; set;}
	global List<HD_Log__c> errorLogs			{get; set;}
	public Boolean restrictByNews 				{get; set;}
	global Boolean runJustThisBatchFromTest		{get; set;}
	global Datetime startProcess				{get; set;}

	global Database.QueryLocator start(Database.BatchableContext bc) {
        
        errorLogs = new List<HD_Log__c>();
        
        String query = 'SELECT Id, Hidden_RoyaltyKey__c, Calculated_Percent__c, Agreement__c, Agreement__r.From_Franchisee_Type__c, Agreement__r.Direct_Franchisee_Agreement__r.GIPM_Counter__c, Agreement__r.Direct_Franchisee_Agreement__r.Direct_Franchisee_Type__c, Agreement__r.Direct_Franchisee_Agreement__r.From_Franchisee_Type__c, Royalty_Month__c, Calculated_Students__c, Actual_Students__c, Calculated_Income__c, From_Franchisee_Account_Type__c FROM Royalties_Calculation__c WHERE (Royalty_Type__c = \'1 - Standard\' OR Royalty_Type__c = null) AND Allow_to_Delete__c = true'; // 07/06/2016 yaara defined that if Royalty_Type__c == null then consier as 1- Standard
        if(restrictByNews == true){ // When the batch was called from the RoyaltyCalculationProcessStep2
        	query += ' AND Needs_transfer_to_Direct__c = true';
        }        
        return Database.getQueryLocator(query);
    }
	
	global void execute(Database.BatchableContext BC, List<Royalties_Calculation__c> scope){
		
		try{
			
			// Unckeching.... 
			for(Royalties_Calculation__c s : scope){
				s.Needs_transfer_to_Direct__c = false;
			}
			update scope;
			
			// Comment, since on the previous step (RoyaltyCalculationProcessStep2) we summarized the amount of Income and Students, now we should start the 
			// calculation of the Royalties to pay to the direct Franchisee (in the low level we could have different kind of calculation).
			 
			// Get the related Agreement Ids from the GI per months
			Set<Id> relatedAgreementIds = new Set<Id>();
			for(Royalties_Calculation__c r : scope){
				relatedAgreementIds.add(r.Agreement__c);
			}
			
			// Get the agreement information
			Map<Id, Agreement__c> agreements = RoyaltyCalculationProcessStep2.getAgreementsInformation(relatedAgreementIds);
			
			// Get the agreement parameter information	
			Map<Id, Map<String, List<Agreement_Parameter__c>>> agreementParameterByType = getAgreementParameterByType(agreements.keySet());
			
			// Get the agreement fixed percent information
			Map<Id, Map<Date, Royalties_Fixed_Student__c>> fixPercent = new Map<Id, Map<Date, Royalties_Fixed_Student__c>>();
			for(Id agId : agreements.keySet()){
				fixPercent.put(agId, new Map<Date, Royalties_Fixed_Student__c>());
				for(Royalties_Fixed_Student__c fp : agreements.get(agId).Royalties_Fixed_Student_Number_in_del__r){
					fixPercent.get(agId).put(fp.Month__c.toStartOfMonth(), fp);
				}
			}
			
			for(Royalties_Calculation__c r : scope){ // Iter for calculation...
				
				Agreement__c relatedAgreement = agreements.get(r.Agreement__c);	
				
				// CALCULATE THE PERCENT
				
				// First Priority is by fixed percent if exist...
				if(fixPercent.containsKey(r.Agreement__c) && fixPercent.get(r.Agreement__c).containsKey(r.Royalty_Month__c)){ // We know that the date is check on the 1 day of the month
				
					r.Calculated_Percent__c = fixPercent.get(r.Agreement__c).get(r.Royalty_Month__c).Royalty_Percent__c;
				}else{
					
					// If not exist fixed percent, we need to identify which kind of percent calculation we should apply... 
					if(!agreementParameterByType.get(r.Agreement__c).get('By Student').isEmpty()){ 
						// if we are on By Student (when the Student_Count_Revenue__c <> null on the parameter exist) - The % is decreasing when the number 
						// of calculated students is rising.
						
						if(r.Calculated_Students__c == null){
							r.Calculated_Students__c = 0;
						}
						
						List<Agreement_Parameter__c> params = agreementParameterByType.get(r.Agreement__c).get('By Student');
						Integer nroOfRows = 1;
						List<Decimal> calculatedRows = new List<Decimal>();						
						for(Integer i = 0; i < params.size(); i++){
							
							Decimal nroOfStudent = params[i].Student_Count_Revenue__c;
							if(i+1 == params.size() /*we are on the last row*/ || params[i].Student_Count_Revenue__c > r.Calculated_Students__c /*We reach the threshold*/){
								// if we are on the last or the calculated student is less that the nro student (Student_Count_Revenue__c) defined on the parameter 
								nroOfStudent = r.Calculated_Students__c;
							}
							
							if(i == 0){							
								calculatedRows.add(params[0].Royalty_Percent__c * nroOfStudent);
							}else{
								calculatedRows.add(params[i].Royalty_Percent__c * (nroOfStudent - params[i-1].Student_Count_Revenue__c));
							}
							
							if(params[i].Student_Count_Revenue__c > r.Calculated_Students__c || i+1 == params.size()){
								break; // We cut the iteration since we already calculate all possible percent (depending by the nro of Calculated_Students__c)
							}
							nroOfRows++;
						}
						
						Decimal percent = 0;
						for(Integer i = 0; i < nroOfRows; i++){
							percent += calculatedRows[i];
						}	
											
						if(r.Calculated_Students__c == 0){
							r.Calculated_Percent__c = 0; 
							if(r.Calculated_Income__c > 0){
								r.Calculated_Percent__c = 14; // By Default 
							}
						}else{
							r.Calculated_Percent__c = percent / r.Calculated_Students__c;
						}
					} else {
						
						r.Calculated_Percent__c = getPercentByType(r.From_Franchisee_Account_Type__c, agreementParameterByType.get(r.Agreement__c));
						
						String espType;
						if(!agreementParameterByType.get(r.Agreement__c).get('By Type').isEmpty()){

							List<Agreement_Parameter__c> params = agreementParameterByType.get(r.Agreement__c).get('By Type');					
							for(Integer i = 0; i < params.size(); i++){
								
								if(params[i].Account_Type__c == r.From_Franchisee_Account_Type__c){
									espType = params[i].Account_Type__c;
								}
							}
						}
						r.Special_Parameter__c = espType;
						
						if((r.Calculated_Students__c == null || r.Calculated_Students__c == 0) && r.Calculated_Income__c > 0 && r.Calculated_Percent__c == 0){
							r.Calculated_Percent__c = 14; // By Default 
						}
						
					}								
				}	
				
				// CALCULATE THE ROYALTIES
				r.Calculated_Royalties__c = (r.Calculated_Percent__c / 100) * r.Calculated_Income__c;	
				if(r.Don_t_Propagate__c == false){ // SW-25525 
					r.Needs_transfer_to_Direct__c = true;
				}					
				
				String keyUp = r.Hidden_RoyaltyKey__c + '-';
				if(r.Calculated_Percent__c <> null){
					 keyUp += '-' + r.Calculated_Percent__c.setScale(4);
				}else{
					 keyUp += '-' + r.Calculated_Percent__c;
				}
				r.Hidden_RoyaltyKey__c = keyUp;				
			}	
			
			update scope;
						
    	}catch(Exception ex){
			errorLogs.add(new HD_Log__c(Process_Key__c = rollback_key, Process_Name__c = processName, Error_Description__c = GlobalHelperMethods.IncludeAllErrorMessage(ex), Status__c = 'Fail'));
		}
	}
	
	global void finish(Database.BatchableContext BC){
		
		if(errorLogs.isEmpty()){			
			RoyaltyCalculationProcessStep4 b = new RoyaltyCalculationProcessStep4();
            b.rollback_key              = rollback_key;
            b.processName               = processName;
            b.restrictByNews			= true; 
            b.startProcess 				= startProcess;   
            if(runJustThisBatchFromTest != true){
            	Database.executeBatch(b);       
            } 
		}else{			
			RoyaltyCalculationProcessStep1.insertErrors(errorLogs, 'Error on Step 3', rollback_key, processName);
		}
	}
	
	//<<<HELPER METHODs>>>
	
	public static Map<Id, Map<String, List<Agreement_Parameter__c>>> getAgreementParameterByType(Set<Id> agreementIds){
    	
    	Map<Id, Map<String, List<Agreement_Parameter__c>>> agreementParameterByType = new Map<Id, Map<String, List<Agreement_Parameter__c>>>();
    	for(Agreement__c ag : [SELECT Id, (Select Id, Agreement__c, CurrencyIsoCode, Royalty_Type__c, From_Franchisee__c, Royalty_Percent__c, Student_Count_Revenue__c, Max_Number_of_Students_per_month__c, Agreement_Parameter_Old_ID__c, Fixed_Level__c, Direct_Franchisee__c, Account_Type__c From Agreement_Parameters__r WHERE (Royalty_Type__c = '1 - Standard' OR Royalty_Type__c = null) ORDER BY Student_Count_Revenue__c NULLS LAST)  FROM Agreement__c WHERE Id IN: agreementIds]){  // 07/06/2016 yaara defined that if Royalty_Type__c == null then consier as 1- Standard
    		
    		agreementParameterByType.put(ag.Id, new Map<String, List<Agreement_Parameter__c>>{'By Student' => new List<Agreement_Parameter__c>(), 'By Type' => new List<Agreement_Parameter__c>(), 'By None' => new List<Agreement_Parameter__c>()});
    		
    		for(Agreement_Parameter__c ap : ag.Agreement_Parameters__r){
    	
		    	// Get the possible Type of percents
				if(ap.Account_Type__c <> null){
					agreementParameterByType.get(ap.Agreement__c).get('By Type').add(ap);	
				}

				if( (ap.Student_Count_Revenue__c <> null || !agreementParameterByType.get(ap.Agreement__c).get('By Student').isEmpty()) || ag.Agreement_Parameters__r.size() == 1){ 
					// The last one could have null if the are more than one by studen row
					// If the is just one parameter, it like discount by student but with just 1 element...
					agreementParameterByType.get(ap.Agreement__c).get('By Student').add(ap);
				}
				if(ap.Account_Type__c == null){
					agreementParameterByType.get(ap.Agreement__c).get('By None').add(ap);
				}
	    	}
    			
    	}		
		return agreementParameterByType;
    }
    
    public static Decimal getPercentByType(String accType, Map<String, List<Agreement_Parameter__c>> parameters){
    	
    	Decimal percent;
    	if(!parameters.get('By Type').isEmpty()){
			
			List<Agreement_Parameter__c> params = parameters.get('By Type');					
			for(Integer i = 0; i < params.size(); i++){
				
				if(params[i].Account_Type__c == accType){
					percent = params[i].Royalty_Percent__c;
					break;
				}
			}	
		}  
		
		if(percent == null && parameters.get('By None').size() == 1){ // When exist untagged row (by account type)
			// so, Empty will be : all the others except for the lines with Account Type
			system.debug('parameters.get(By None)[0]: ' + parameters.get('By None')[0]);
			percent = parameters.get('By None')[0].Royalty_Percent__c;
		}
		
		if(percent == null){ 
			// IF doesn't exist parameter records...
			
			//  If From Franchisee Type is not MF
			//    Take 14%
			//  Else 
			//    take 50%.	
			percent   = DEFAULT_FROM_OTHER;
			if(accType == 'MF'){
				percent   = DEFAULT_FROM_MF;
			}
		}	    	
    	return percent;
    } 
}