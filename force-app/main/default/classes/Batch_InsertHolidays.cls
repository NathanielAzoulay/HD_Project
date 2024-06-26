/******************************************************************************* 
Name              : Batch_AgreementUpdateDates
Description       : change the due date on active Agreements once a year
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan	             01/23/2017          	Yaara Nadir               [SW-23290]
*******************************************************************************/
global class Batch_InsertHolidays implements Database.Batchable<Holiday_Vacation__c> {
	
	/* This list MUST be filled before call the batch */
	public List<Holiday_Vacation__c> holidays2Insert;
	
	public List<HD_Log__c> errorLogs = new List<HD_Log__c>();
	
	global Iterable<Holiday_Vacation__c> start(Database.BatchableContext bc) {
        return holidays2Insert;
    }
	
	global void execute(Database.BatchableContext BC, list<Holiday_Vacation__c> scope) {
		Database.SaveResult[] srl = Database.insert(scope, false);
        for(Integer i = 0; i < srl.size(); i++){
            Database.SaveResult sr = srl.get(i);
            if(!sr.isSuccess()){
                errorLogs.add(new HD_Log__c(Process_Name__c = 'BatchInsertHolidays', Error_Description__c = sr.getErrors()[0].getMessage(), Status__c = 'Fail'));
            }
        }
	}
	
	global void finish(Database.BatchableContext BC) {
		if(!errorLogs.isEmpty() || Test.isRunningTest()){
            insert errorLogs;
        }
	}
}