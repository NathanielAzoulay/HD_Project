/*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name:            RSRoyaltyCalculation3.cls
Description:     Link GIPM to RCs . 
Date             Author          Summary of Changes 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
15-OCT-2017     Rashad Saeed  Initial Implementation 
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
global class  RSRoyaltyCalculation3 implements Database.Batchable<sObject> , Database.Stateful {
    global String MFID {get; set;} 
    global List<HD_Log__c> errorLogs  {get; set;}
    global Database.QueryLocator start(Database.BatchableContext bc) {
         errorLogs = new List<HD_Log__c>();
        String query = 'select Id,Royalties_Calculation__c,Agreement__c,Royalty_Start_Date__c,GIPMRCKey__c from Group_Income_Per_Month__c where Royalties_Calculation__c = Null'; 
        query+=' And Royalty_Start_Date__c <=NEXT_YEAR And Royalty_Start_Date__c >=LAST_YEAR';
        if (MFID<>null)
             query+=' And Agreement__r.MF_ID__c='+'\''+MFID+'\'';
        query+=' And Agreement__r.Expiry_Date__c >=LAST_YEAR';
        return Database.getQueryLocator(query); 
    }
    global void execute(Database.BatchableContext BC, List<Group_Income_Per_Month__c> scope){
        Set <String>Keys = new  Set <String>();
        Map <String ,Id> RCKeyId  = new Map <String ,Id>();
        Set <Id>AggsIds = new Set <Id>();
        for (Group_Income_Per_Month__c GIPM : scope)
        {
            Keys.add(GIPM.GIPMRCKey__c);  
            AggsIds.add((Id)GIPM.Agreement__c);
        }
        Map <Id,Royalties_Calculation__c> allNewRC = new Map <Id,Royalties_Calculation__c>([select Id,RCUniqKey__c from Royalties_Calculation__c 
                                                                                            where RCUniqKey__c in : Keys
                                                                                            and Agreement__c in:AggsIds
                                                                                            And Royalty_Month__c<=NEXT_YEAR
                                                                                            And Royalty_Month__c>=LAST_YEAR
                                                                                           ]);   
        for (Royalties_Calculation__c Rc : allNewRC.values()){
            RCKeyId.put(Rc.RCUniqKey__c, (Id)RC.id);
        }
        
        if (!RCKeyId.iSEmpty())
            for (Group_Income_Per_Month__c GIPM : scope)
        {
            
            GIPM.Royalties_Calculation__c = RCKeyId.get(GIPM.GIPMRCKey__c) ;
        }
        try{
            Update Scope;
        }catch(Exception ex){
            errorLogs.add(new HD_Log__c(Process_Key__c = 0, Process_Name__c = 'Batch - Create Royalty Calculation', Error_Description__c = ex.getMessage() + ' Trace: ' + ex.getStackTraceString(), Status__c = 'Fail')); 
        } 
        
    }
    global void finish(Database.BatchableContext BC){
         
    } 
}