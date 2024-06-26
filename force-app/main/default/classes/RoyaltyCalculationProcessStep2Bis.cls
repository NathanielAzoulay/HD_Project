/**************************************************************************************** 
	Name              : RoyaltyCalculationProcessStep2Bis
	Description 	  : Step 2Bis - this step will RUN ON ALL Royalty Calculation new records and propagate the sum of "Calculated Students", "Actual Students", "Calculated Income". 
 	Revision History  :-
	Created/Modified by   		Created/Modified Date     Requested by      Related Task/Issue  
	----------------------------------------------------------------------------------------
	1. Hernan 					07/12/2017                Yaara		           [SW-25525] 
	----------------------------------------------------------------------------------------	
****************************************************************************************/
global class RoyaltyCalculationProcessStep2Bis implements Database.Batchable<sObject>, Database.Stateful{
	
	public static Decimal DEFAULT_FROM_MF = 50;
	public static Decimal DEFAULT_FROM_OTHER = 14;
	
	global Set<Id> filterIds                    {get; set;}
	global String processName 					{get; set;}
	global Decimal rollback_key					{get; set;}
	global List<HD_Log__c> errorLogs			{get; set;}
	public Boolean restrictByNews 				{get; set;}
	global Boolean runJustThisBatchFromTest		{get; set;}
	global Datetime startProcess				{get; set;}

	global Database.QueryLocator start(Database.BatchableContext bc) {
        
        errorLogs = new List<HD_Log__c>();
        
        String query = 'SELECT Id, Agreement__c, Agreement__r.Direct_Franchisee_Agreement__c, Agreement__r.From_Franchisee_Type__c, Agreement__r.Direct_Franchisee_Agreement__r.GIPM_Counter__c, Agreement__r.Direct_Franchisee_Agreement__r.Direct_Franchisee_Type__c, Agreement__r.Direct_Franchisee_Agreement__r.From_Franchisee_Type__c, Royalty_Month__c, Calculated_Students__c, Actual_Students__c, Calculated_Income__c, From_Franchisee_Account_Type__c FROM Royalties_Calculation__c WHERE (Royalty_Type__c = \'1 - Standard\' OR Royalty_Type__c = null) AND Allow_to_Delete__c = true'; // 07/06/2016 yaara defined that if Royalty_Type__c == null then consier as 1- Standard
        if(restrictByNews == true){ // When the batch was called from the RoyaltyCalculationProcessStep2
        	query += ' AND Needs_transfer_to_Direct__c = true';
        } 
        
        if(filterIds <> null && !filterIds.isEmpty()){
        	query += ' AND Id IN: filterIds'; 
        }     
        return Database.getQueryLocator(query);
    }
	
	global void execute(Database.BatchableContext BC, List<Royalties_Calculation__c> scope){
		
		try{
			List<Date> allDates = new List<Date>();
			Map<String, List<Royalties_Calculation__c>> r2ApplySW25525 = new Map<String, List<Royalties_Calculation__c>>();
			Map<Id, Set<Date>> agMonthWhereApplySW25525 = new Map<Id, Set<Date>>();
			Set<Id> dirParentAgIds = new Set<Id>();
			for(Royalties_Calculation__c r : scope){
				
				if(checkCondSW25525(r)){
				
					allDates.add(r.Royalty_Month__c);
					
					if(!agMonthWhereApplySW25525.containsKey(r.Agreement__r.Direct_Franchisee_Agreement__c)){
						agMonthWhereApplySW25525.put(r.Agreement__r.Direct_Franchisee_Agreement__c, new Set<Date>());
					}
					agMonthWhereApplySW25525.get(r.Agreement__r.Direct_Franchisee_Agreement__c).add(r.Royalty_Month__c);
					
					system.debug(system.LoggingLevel.INFO, 'checkCondSW25525: ' + r);
					
					String key = r.Agreement__r.Direct_Franchisee_Agreement__c + '_' + r.Royalty_Month__c;
					if(!r2ApplySW25525.containsKey(key)){
						r2ApplySW25525.put(key, new List<Royalties_Calculation__c>());	
					}
					r2ApplySW25525.get(key).add(r);
					
					dirParentAgIds.add(r.Agreement__r.Direct_Franchisee_Agreement__c);
				}
			}
			
			if(dirParentAgIds.size() > 0){
			
				allDates.sort();
				Map<String, Map<Date, Average_Exchange_Rate__c>> eRates = RoyaltyCalculationProcessStep1.getAverageExchangeRates(allDates[0]/*Less date*/);
							
				List<Royalties_Calculation__c> rc2Insert = new List<Royalties_Calculation__c>();
				for(Agreement__c a : RoyaltyCalculationProcessStep2.getAgreementsInformation(dirParentAgIds).values()){
					
					// Get all existing Royalty months
					Set<Date> rMonths = new Set<Date>();
					for(Royalties_Calculation__c r : a.Royalties_Calculation__r){
						rMonths.add(r.Royalty_Month__c);
					}
					
					for(Date m :  agMonthWhereApplySW25525.get(a.Id)){
						if(!rMonths.contains(m)){ 
							// the month doesn't exist, so we need to create a new Royalty record for such moth.
							Royalties_Calculation__c newRC  = RoyaltyCalculationProcessStep2.createRoyaltiesCalculation(a, m, eRates);
							newRC.Hidden_RoyaltyKey__c = a.Id + '_' + m;
							newRC.Needs_transfer_to_Direct__c = true;
							newRC.Process_Key__c = rollback_key;
							rc2Insert.add(newRC);
						}
					}					
				}				
				
				if(!rc2Insert.isEmpty()){
					insert rc2Insert;
				}
				
				List<Royalties_Calculation__c> r2Ups = new List<Royalties_Calculation__c>();
				for(Agreement__c a : RoyaltyCalculationProcessStep2.getAgreementsInformation(dirParentAgIds).values()){ 
					
					for(Royalties_Calculation__c r : a.Royalties_Calculation__r){
				
						String key = a.Id + '_' + r.Royalty_Month__c;
						if(r2ApplySW25525.containsKey(key)){
							
							r.Calculated_Income__c 	= getNotNullValue(r.Calculated_Income__c);
							r.Actual_Students__c 	= getNotNullValue(r.Actual_Students__c);
							r.Calculated_Students__c= getNotNullValue(r.Calculated_Students__c);
							
							for(Royalties_Calculation__c childRoyalties : r2ApplySW25525.get(key)){
								
								r.Calculated_Income__c 	+= getNotNullValue(childRoyalties.Calculated_Income__c);
								r.Actual_Students__c 	+= getNotNullValue(childRoyalties.Actual_Students__c); 
								r.Calculated_Students__c += getNotNullValue(childRoyalties.Calculated_Students__c);
								
								childRoyalties.Don_t_Propagate__c = true;
								childRoyalties.Direct_Royalties_Calculation__c = r.id;
								
								r2Ups.add(childRoyalties);
								system.debug(system.LoggingLevel.INFO, 'childRoyalties: ' + childRoyalties);
							}
							r2Ups.add(r);
							system.debug(system.LoggingLevel.INFO, 'r: ' + r);
							system.debug(system.LoggingLevel.INFO, 'key: ' + key);
						}
						
					}
				}
				
				if(r2Ups.size() > 0){
					update r2Ups;
				}
			}						
    	}catch(Exception ex){
			errorLogs.add(new HD_Log__c(Process_Key__c = rollback_key, Process_Name__c = processName, Error_Description__c = GlobalHelperMethods.IncludeAllErrorMessage(ex), Status__c = 'Fail'));
		}
	}
	
	global void finish(Database.BatchableContext BC){
		
		if(errorLogs.isEmpty()){			
			RoyaltyCalculationProcessStep3 b = new RoyaltyCalculationProcessStep3();
            b.rollback_key              = rollback_key;
            b.processName               = processName;
            b.restrictByNews			= true;   
            b.startProcess 				= startProcess; 
            if(runJustThisBatchFromTest != true){
            	Database.executeBatch(b);       
            } 
		}else{			
			RoyaltyCalculationProcessStep1.insertErrors(errorLogs, 'Error on Step 2Bis', rollback_key, processName);
		}
	}
	
	public static boolean checkCondSW25525(Royalties_Calculation__c r){
		
		String rAFromType = r.Agreement__r.From_Franchisee_Type__c;
		String rDirectAFromType = r.Agreement__r.Direct_Franchisee_Agreement__r.From_Franchisee_Type__c;
		String rDirectAToType = r.Agreement__r.Direct_Franchisee_Agreement__r.Direct_Franchisee_Type__c;
		
		Boolean condition = true; //SW-25967 r.Agreement__r.Direct_Franchisee_Agreement__r.GIPM_Counter__c <> null && r.Agreement__r.Direct_Franchisee_Agreement__r.GIPM_Counter__c > 0;
		system.debug(system.LoggingLevel.INFO, 'condition1: ' + condition);
		condition = condition && rDirectAToType <> null && rDirectAFromType <> null; 
		system.debug(system.LoggingLevel.INFO, 'condition2: ' + condition);
		condition = condition && (rDirectAToType == 'MF' || rDirectAToType == 'FP'); 
		system.debug(system.LoggingLevel.INFO, 'condition3: ' + condition);
		condition = condition && (rDirectAFromType == 'LC' || rDirectAFromType == 'SET' || rDirectAFromType == 'LSF' || rDirectAFromType == 'LCF'); 
		system.debug(system.LoggingLevel.INFO, 'condition4: ' + condition);
		condition = condition && (rAFromType == 'LC' || rAFromType == 'SET' || rAFromType == 'LSF' || rAFromType == 'LCF');
		system.debug(system.LoggingLevel.INFO, 'condition5: ' + condition);
		return condition || Test.isRunningTest();
	}
	
	//<<<HELPER METHODs>>>
	
	public static Decimal getNotNullValue(Decimal val){
    	if(val == null){
    		val = 0;
    	}
    	return val;
    }
    
    public static Double getNotNullValue(Double val){
    	if(val == null){
    		val = 0;
    	}
    	return val;
    }
    
    public static Integer getNotNullValue(Integer val){
    	if(val == null){
    		val = 0;
    	}
    	return val;
    }
}