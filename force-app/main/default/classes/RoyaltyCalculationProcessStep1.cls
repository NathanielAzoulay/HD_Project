/**************************************************************************************** 
	Name              : RoyaltyCalculationProcessStep1
	Description 	  : Step 1 - The process will delete records that doesn't have checkbox field:  Allow to Delete = True in Royalty Calculation
	Revision History  :-
	Created/Modified by   		Created/Modified Date     Requested by      Related Task/Issue  
	----------------------------------------------------------------------------------------
	1. Hernan (Created)			06/16/2016                Yaara		           [SW-18002] / [SW-19971]
	----------------------------------------------------------------------------------------	
****************************************************************************************/
global class RoyaltyCalculationProcessStep1 implements Database.Batchable<sObject>, Database.Stateful{

	global String processName 					{get; set;}
	global Decimal rollback_key					{get; set;}
	global List<HD_Log__c> errorLogs			{get; set;}
	global Set<Id> filterIds					{get; set;}
	global Boolean runJustThisBatchFromTest		{get; set;}
	
	global Database.QueryLocator start(Database.BatchableContext bc) {
        
        errorLogs = new List<HD_Log__c>();
    
        String query = 'SELECT Id FROM Royalties_Calculation__c WHERE (Royalty_Type__c = \'1 - Standard\' OR Royalty_Type__c = null) AND Allow_to_Delete__c = true';  // 07/06/2016 yaara defined that if Royalty_Type__c == null then consier as 1- Standard
        if(filterIds <> null && !filterIds.isEmpty()){
        	query += ' AND Id IN: filterIds';
        }
        return Database.getQueryLocator(query);
    }
	
	
	global void execute(Database.BatchableContext BC, List<Royalties_Calculation__c> scope){
		
		try{
			delete scope;  
			/*
			// Reset all calcaulted values....
			for(Royalties_Calculation__c r : scope){
				//r.Calculated_Percent__c     = null;
				r.Calculated_Students__c    = 0;
        		r.Actual_Students__c        = 0;
        		r.Calculated_Income__c      = 0;
        		r.Calculated_Royalties__c   = 0;
				r.Needs_transfer_to_Direct__c = false;
				r.Process_Key__c = null;
			}			
			update scope;
			*/  
    	}catch(Exception ex){
			errorLogs.add(new HD_Log__c(Process_Key__c = rollback_key, Process_Name__c = processName, Error_Description__c = ex.getMessage(), Status__c = 'Fail'));
		}
	}
	
	global void finish(Database.BatchableContext BC){
		
		if(errorLogs.isEmpty()){
			// If the is not error on this step will pass the control to the next one!!!
			RoyaltyCalculationProcessStep2 b = new RoyaltyCalculationProcessStep2();
			b.rollback_key 				= rollback_key;
			b.processName 				= processName;
			if(runJustThisBatchFromTest != true){
				Database.executeBatch(b);
			}
		}else{									
			insertErrors(errorLogs, 'Error on Step 1', rollback_key, processName);
		}
	}
	
	// <<<HELPER METHODs>>>
	
	public static void insertErrors(List<HD_Log__c> errorLogs, String errorMessage, Decimal rollback_key, String processName){
		
		HD_Log__c log = new HD_Log__c(Send_Result__c = true, Process_Key__c = rollback_key, Process_Name__c = processName, Status__c = 'Fail', Error_Description__c = errorMessage);
		insert log;
		for(HD_Log__c hl : errorLogs){
			hl.Parent_Log__c = log.Id;
		}
		insert errorLogs;
	}
	
	public static Map<String, Map<Date, Average_Exchange_Rate__c>> getAverageExchangeRates(Date lessDate){
		
		if(lessDate == null){
			lessDate = system.today().addYears(-1);
		}
				
		Map<String, Map<Date, Average_Exchange_Rate__c>> eRates = new Map<String, Map<Date, Average_Exchange_Rate__c>>(); 
        for(Average_Exchange_Rate__c aer : [SELECT Id, Exchange_Rate_Start_Date__c, CurrencyIsoCode, To_Currency__c, Average_Rate__c FROM Average_Exchange_Rate__c WHERE Exchange_Rate_Start_Date__c >=: lessDate]){
            
            String key = aer.CurrencyIsoCode + '_' + aer.To_Currency__c;
            if(!eRates.containsKey(key)){
                eRates.put(key, new Map<Date, Average_Exchange_Rate__c>());
            }
            eRates.get(key).put(aer.Exchange_Rate_Start_Date__c, aer);
        } 
		
		return eRates;
	}
}