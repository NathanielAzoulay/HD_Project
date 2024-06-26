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
global class RoyaltyCalculationProcessStep5 implements Database.Batchable<sObject>, Database.Stateful{

	global Set<Id> filterIds                    {get; set;}
    global String processName                   {get; set;}
    global Decimal rollback_key                 {get; set;}
    global List<HD_Log__c> errorLogs            {get; set;}
    global Boolean runJustThisBatchFromTest		{get; set;}
    global Integer nroIteration					{get; set;}
    global Datetime startProcess				{get; set;}
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        if(nroIteration == null){
        	nroIteration = 0;
        }
        
        errorLogs = new List<HD_Log__c>();
        
        String query = GlobalHelperMethods.getQueryString(new Group_Income_Per_Month__c()) + ' WHERE CreatedDate <=: startProcess AND Royalty_Type__c = \'1 - Standard\' AND For_Royalty_Calculation__c = true AND Royalties_Calculation__c = null' ;
        if(filterIds <> null && !filterIds.isEmpty()){
        	query += ' AND Id IN: filterIds'; 
        }
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Group_Income_Per_Month__c> scope){
        
        try{
        	
        	Map<Id, List<Group_Income_Per_Month__c>> relatedAgreements = new Map<Id, List<Group_Income_Per_Month__c>>();                        
            for(Group_Income_Per_Month__c r : scope){
            
                if(!relatedAgreements.containsKey(r.Agreement__c)){
                    relatedAgreements.put(r.Agreement__c, new List<Group_Income_Per_Month__c>());
                }
                relatedAgreements.get(r.Agreement__c).add(r);
            }
            
            // Save the reference of the new royalties on the related GIs
            List<Group_Income_Per_Month__c> gi2Up = new List<Group_Income_Per_Month__c>();
            for(Agreement__c ag : RoyaltyCalculationProcessStep2.getAgreementsInformation(relatedAgreements.keySet()).values()){
            
            	Map<String, Royalties_Calculation__c> royalties = new Map<String, Royalties_Calculation__c>(); 
            	
            	// Get existing parcial calculated records (from other possible iteration) 
                for(Royalties_Calculation__c rc : ag.Royalties_Calculation__r){
                    String key = ag.Id + '_' + rc.Royalty_Month__c; // This is our identifier key for each Royalty under specific Agreement (It means
                    // that we could just have 1 Royalties_Calculation__c per month per agreement).
                    royalties.put(key, rc);
                }
                
                for(Group_Income_Per_Month__c gi : relatedAgreements.get(ag.Id)){
             		
             		// Take the inserted Royalty calculation and attach to the related GI.       
                    Date sDate = gi.Royalty_Start_Date__c.toStartOfMonth();
                    String key = ag.Id + '_' + sDate;
                    if(royalties.containsKey(key)){ // if the royalties was created on this transaction...
	                    gi.Royalties_Calculation__c = royalties.get(key).Id;
	                    gi2Up.add(gi);
	                }
                }
            } 
            
            if(!gi2Up.isEmpty()){
            	update gi2Up;
            }                   		
        }catch(Exception ex){
        	System.debug('Error: ' + ex.getMessage() + ' Trace: ' + ex.getStackTraceString());
            errorLogs.add(new HD_Log__c(Process_Key__c = rollback_key, Process_Name__c = processName, Error_Description__c = ex.getMessage() + ' Trace: ' + ex.getStackTraceString(), Status__c = 'Fail'));
        } 
    }

	global void finish(Database.BatchableContext BC){
        
        nroIteration = nroIteration + 1;
        
        if(!errorLogs.isEmpty()){
            RoyaltyCalculationProcessStep1.insertErrors(errorLogs, 'Error on Step 5 (' + nroIteration + ')', rollback_key, processName);
        }
        
        if([SELECT Id FROM Group_Income_Per_Month__c WHERE CreatedDate <=: startProcess AND Royalty_Type__c = '1 - Standard' AND For_Royalty_Calculation__c = true AND Royalties_Calculation__c = null].size()>0){
        	if(nroIteration <=3 ){
        		RoyaltyCalculationProcessStep5 b = new RoyaltyCalculationProcessStep5();
	            b.rollback_key              = rollback_key;
	            b.processName               = processName;
	            b.nroIteration				= nroIteration;  
	            b.startProcess 				= startProcess;
	            if(runJustThisBatchFromTest != true){
	            	Database.executeBatch(b,50);       
	            }
        	}
        }
    }
}