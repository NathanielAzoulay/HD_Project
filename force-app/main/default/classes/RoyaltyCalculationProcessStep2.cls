/**************************************************************************************** 
    Name              : RoyaltyCalculationProcessStep2
    Description       : Step 2 - Summarize Group income per Month (Calculate the sum of all payments and all students' number (calculated Students) of Agreement) 
    Revision History  :-
    Created/Modified by         Created/Modified Date     Requested by      Related Task/Issue  
    ----------------------------------------------------------------------------------------
    1. Hernan (Created)         06/16/2016                Yaara                [SW-18002] / [SW-19971]
    1. Hernan (Created)         08/04/2016                Yaara                [SW-19971]
    ----------------------------------------------------------------------------------------    
****************************************************************************************/
global class RoyaltyCalculationProcessStep2 implements Database.Batchable<sObject>, Database.Stateful{

	global Set<Id> filterIds                    {get; set;}
    global String processName                   {get; set;}
    global Decimal rollback_key                 {get; set;}
    global List<HD_Log__c> errorLogs            {get; set;}
    global Boolean runJustThisBatchFromTest		{get; set;}
    global Datetime startProcess				{get; set;}
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        errorLogs = new List<HD_Log__c>();
        
        String query = GlobalHelperMethods.getQueryString(new Group_Income_Per_Month__c()) + ' WHERE (Royalty_Type__c = \'1 - Standard\' OR Royalty_Type__c = null) AND For_Royalty_Calculation__c = true'; // 07/06/2016 yaara defined that if Royalty_Type__c == null then consier as 1- Standard
        if(filterIds <> null && !filterIds.isEmpty()){
        	query += ' AND Id IN: filterIds'; 
        }
        
        startProcess = system.now();
        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Group_Income_Per_Month__c> scope){
        
        try{
            
            Date lessDate;
            Map<Id, List<Group_Income_Per_Month__c>> relatedAgreements = new Map<Id, List<Group_Income_Per_Month__c>>();                        
            for(Group_Income_Per_Month__c r : scope){
            
                if(!relatedAgreements.containsKey(r.Agreement__c)){
                    relatedAgreements.put(r.Agreement__c, new List<Group_Income_Per_Month__c>());
                }
                relatedAgreements.get(r.Agreement__c).add(r);
                
                if(lessDate == null || lessDate > r.Royalty_Start_Date__c){
                    lessDate = r.Royalty_Start_Date__c;
                }
            }
            
            if(lessDate <> null){
            	lessDate = lessDate.toStartOfMonth();
            }
            
            Map<String, Map<Date, Average_Exchange_Rate__c>> eRates = RoyaltyCalculationProcessStep1.getAverageExchangeRates(lessDate);
            
            Id rtGI_Student = Schema.SObjectType.Group_Income_Per_Month__c.getRecordTypeInfosByName().get('Calculated Student').getRecordTypeId();
            Id rtGI_Price   = Schema.SObjectType.Group_Income_Per_Month__c.getRecordTypeInfosByName().get('Price').getRecordTypeId();
            
            Map<String, Royalties_Calculation__c> rc2Insert = new Map<String, Royalties_Calculation__c>();
            Map<String, Royalties_Calculation__c> rc2Update = new Map<String, Royalties_Calculation__c>();
            Map<String, Royalties_Calculation__c> royalties = new Map<String, Royalties_Calculation__c>();  
            
            for(Agreement__c ag : getAgreementsInformation(relatedAgreements.keySet()).values()){
                // For each agreement we will sum the Income or Calculated_Students depend of the GI per Month Record Type
                
                // Get existing parcial calculated records (from other possible iteration) 
                for(Royalties_Calculation__c rc : ag.Royalties_Calculation__r){
                    String key = ag.Id + '_' + rc.Royalty_Month__c; // This is our identifier key for each Royalty under specific Agreement (It means
                    // that we could just have 1 Royalties_Calculation__c per month per agreement).
                    royalties.put(key, rc);
                }
                
                for(Group_Income_Per_Month__c gi : relatedAgreements.get(ag.Id)){
                    
                    Date sDate = gi.Royalty_Start_Date__c.toStartOfMonth();
                    String key = ag.Id + '_' + sDate;
                    
                    if(!royalties.containsKey(key)){ // Check if exist partial royalties calculated...
                        
                        Royalties_Calculation__c newRC  = RoyaltyCalculationProcessStep2.createRoyaltiesCalculation(ag, sDate, eRates);
                        rc2Insert.put(key, newRC);
                        royalties.put(key, newRC);
                        newRC.Hidden_RoyaltyKey__c = key; 
                    }else if(!rc2Insert.containsKey(key) && !rc2Update.containsKey(key)){
                        
                        rc2Update.put(key, royalties.get(key));
                    }
                    
                    Royalties_Calculation__c rc = royalties.get(key);
                    if(gi.RecordTypeId == rtGI_Student){
                        
                        rc.Calculated_Students__c   += GlobalHelperMethods.ifnull(gi.Calculated_Student__c);
                        rc.Actual_Students__c       += GlobalHelperMethods.ifnull(gi.Actual_Student_Number__c);
                    }else if(gi.RecordTypeId == rtGI_Price){
                        
                        rc.Calculated_Income__c     += GlobalHelperMethods.ifnull(gi.Income__c);
                    }
                    
                    rc.Needs_transfer_to_Direct__c = true;
                    rc.Process_Key__c = rollback_key; 
                }
            }
            
            if(!rc2Insert.isEmpty()){
                insert rc2Insert.values();
            }
            
            if(!rc2Update.isEmpty()){
                update rc2Update.values();
            }   
            
            // Save the reference of the new royalties on the related GIs
            List<Group_Income_Per_Month__c> gi2Up = new List<Group_Income_Per_Month__c>();
            for(Agreement__c ag : getAgreementsInformation(relatedAgreements.keySet()).values()){
                for(Group_Income_Per_Month__c gi : relatedAgreements.get(ag.Id)){
             		
             		// Take the inserted Royalty calculation and attach to the related GI.       
                    Date sDate = gi.Royalty_Start_Date__c.toStartOfMonth();
                    String key = ag.Id + '_' + sDate;
                    if(rc2Insert.containsKey(key)){ // if the royalties was created on this transaction...
	                    gi.Royalties_Calculation__c = rc2Insert.get(key).Id;
	                }else if(rc2Update.containsKey(key)){
                    	gi.Royalties_Calculation__c = rc2Update.get(key).Id;
                    }
                    gi2Up.add(gi);
                }
            }        
            
            if(!gi2Up.isEmpty()){
            	database.update(gi2Up, false);
            }            
        }catch(Exception ex){
        	System.debug(system.LoggingLevel.ERROR, 'MSG: ' + ex.getMessage() + ' Trace: ' + ex.getStackTraceString());
            errorLogs.add(new HD_Log__c(Process_Key__c = rollback_key, Process_Name__c = processName, Error_Description__c = ex.getMessage() + ' Trace: ' + ex.getStackTraceString(), Status__c = 'Fail'));
        }        
    }
    
    global void finish(Database.BatchableContext BC){
        
        if(errorLogs.isEmpty()){
            
            RoyaltyCalculationProcessStep2Bis b = new RoyaltyCalculationProcessStep2Bis();
            b.rollback_key              = rollback_key;
            b.processName               = processName;
            b.restrictByNews			= true;  
            b.startProcess 				= startProcess;
            if(runJustThisBatchFromTest != true){
            	Database.executeBatch(b);       
            }
        }else{          
            RoyaltyCalculationProcessStep1.insertErrors(errorLogs, 'Error on Step 2', rollback_key, processName);
        }
    }
    
    //<<<HELPER METHODs>>>
    
    // Description: method for retrieving common agreement information on all batches...
	public static Map<Id, Agreement__c> getAgreementsInformation(Set<Id> agreementIds){
		
		String  qAgreement =  'SELECT ';
				qAgreement +=  '(Select Month__c, Royalty_Percent__c From Royalties_Fixed_Student_Number_in_del__r Where Royalty_Percent__c != null), ';
				qAgreement +=  '(SELECT Id, Agreement__r.Direct_Franchisee__c, Agreement__r.Direct_Franchisee__r.Account_Type__c, Agreement__c, Royalty_Month__c, Calculated_Students__c, Actual_Students__c, Calculated_Income__c, Calculated_Percent__c FROM Royalties_Calculation__r WHERE (Royalty_Type__c = \'1 - Standard\' OR Royalty_Type__c = null) AND Allow_to_Delete__c = true), '; // 07/06/2016 yaara defined that if Royalty_Type__c == null then consier as 1- Standard
				qAgreement += ' Id, From_Franchisee__c, From_Franchisee__r.Account_Type__c, From_Franchisee__r.CurrencyIsoCode, From_Franchisee__r.HD_Currency__c, Direct_Franchisee__c, Direct_Franchisee__r.CurrencyIsoCode, Direct_Franchisee__r.Account_Type__c, CurrencyIsoCode FROM Agreement__c WHERE (Royalty_Type__c = \'1 - Standard\' OR Royalty_Type__c = null) AND Id IN: agreementIds'; // 07/06/2016 yaara defined that if Royalty_Type__c == null then consier as 1- Standard  
		
		Map<Id, Agreement__c> agreements = new Map<Id, Agreement__c>();
		for(Agreement__c ag : database.query(qAgreement)){
			agreements.put(ag.Id, ag);
		}
		
		return agreements;
	}
    
    public static Royalties_Calculation__c createRoyaltiesCalculation(Agreement__c ag, Date sDate, Map<String, Map<Date, Average_Exchange_Rate__c>> eRates){
		
		// Note from Yaara: between Franchise and HQ you should check the From Franchise.CurrencyIsoCode and From Franchise.HD Currency
		
		String keyCurrency = ag.From_Franchisee__r.CurrencyIsoCode + '_' + ag.From_Franchisee__r.CurrencyIsoCode;
		if(ag.Direct_Franchisee__r.Account_Type__c == 'HQ'){
			keyCurrency = ag.From_Franchisee__r.CurrencyIsoCode + '_' + ag.From_Franchisee__r.HD_Currency__c;
		}
		
        List<Date> allExistingAVGRecords = new List<Date>();
        if(eRates.containsKey(keyCurrency)){
            allExistingAVGRecords = new List<Date>(eRates.get(keyCurrency).keySet());
            allExistingAVGRecords.sort();
        }
		
		Royalties_Calculation__c newRC  = new Royalties_Calculation__c();
        newRC.Agreement__c              = ag.Id;
        newRC.From_Franchisee__c        = ag.From_Franchisee__c;
        newRC.Direct_Franchisee__c      = ag.Direct_Franchisee__c;
        newRC.CurrencyIsoCode           = ag.CurrencyIsoCode;
        newRC.Royalty_Month__c          = sDate;
        newRC.RecordTypeId				= Schema.SObjectType.Royalties_Calculation__c.getRecordTypeInfosByName().get('Planned').getRecordTypeId();
        
        if(sDate <= system.today().toStartOfMonth()/*current month*/){
        	// Iter the list to get the correct convert rate by date
            for(Integer i=0; i < allExistingAVGRecords.size(); i++){ 
                Date d = allExistingAVGRecords[i]; 
                if(d.toStartOfMonth() <= sDate){ // TODO CHECK
                    newRC.Exchange_Rate__c = eRates.get(keyCurrency).get(d).Average_Rate__c;
                }   
            }       
        }else if(!allExistingAVGRecords.isEmpty()){
            newRC.Exchange_Rate__c = eRates.get(keyCurrency).get(allExistingAVGRecords[allExistingAVGRecords.size()-1]).Average_Rate__c;
        }   
        
        newRC.Calculated_Students__c    = 0;
        newRC.Actual_Students__c        = 0;
        newRC.Calculated_Income__c      = 0;
        newRC.Calculated_Royalties__c   = 0;
        
        return newRC;
	}
}