/******************************************************************************* 
Name              : Batch_AgreementUpdateDates
Description       : change the due date on active Agreements once a year
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez             06/24/2016          Yaara Nadir               [SW-19977]
*******************************************************************************/

global class Batch_AgreementUpdateDates implements Database.Batchable<sObject> {
    public String query;
    public List<HD_Log__c> errorLogs = new List<HD_Log__c>();
    public Set<Id> filteredIds = new Set<Id>();

    global Batch_AgreementUpdateDates() {
        query = 'SELECT Due_Date_Q1__c,Due_Date_Q2__c,Due_Date_Q3__c,Due_Date_Q4__c FROM Agreement__c WHERE Agreement_Status__c= \'Active\' ';
        this.query = query;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        if(!filteredIds.isEmpty()){
           query += ' AND Id IN :filteredIds';
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, list<Sobject> scope) {
        try {
            List<Agreement__c> agree2up = new List<Agreement__c>();
            for(Agreement__c agree :(List<Agreement__c>) scope) {
                if(agree.Due_Date_Q1__c != null && agree.Due_Date_Q2__c != null && agree.Due_Date_Q3__c != null && agree.Due_Date_Q4__c != null){
                    System.debug(LoggingLevel.ERROR, '*** before: ' + agree);

                    agree.Due_Date_Q1__c = Date.newInstance(System.today().year(), agree.Due_Date_Q1__c.month(), agree.Due_Date_Q1__c.day());
                
                    agree.Due_Date_Q2__c = Date.newInstance(System.today().year(), agree.Due_Date_Q2__c.month(), agree.Due_Date_Q2__c.day());
                
                    agree.Due_Date_Q3__c = Date.newInstance(System.today().year(), agree.Due_Date_Q3__c.month(), agree.Due_Date_Q3__c.day());
                    
                    agree.Due_Date_Q4__c = Date.newInstance(System.today().year(), agree.Due_Date_Q4__c.month(), agree.Due_Date_Q4__c.day());
                    
                    if( System.today() > agree.Due_Date_Q1__c){
                        agree.Due_Date_Q4__c = Date.newInstance(System.today().addYears(1).year(), agree.Due_Date_Q4__c.month(), agree.Due_Date_Q4__c.day());
                    }                
                    System.debug(LoggingLevel.ERROR, '*** after: ' + agree);
                    agree2up.add(agree);
                }
            }

            Database.SaveResult[] srl = Database.update(agree2up, false);
            for(Integer i = 0; i < srl.size(); i++){
                Database.SaveResult sr = srl.get(i);
                if(!sr.isSuccess()){
                    errorLogs.add(new HD_Log__c(Process_Name__c = 'Batch_AgreementUpdateDates', Error_Description__c = sr.getErrors()[0].getMessage(), Status__c = 'Fail', Agreement__c = sr.getId() ));
                }
            }  
        }catch (Exception e) {
            errorLogs.add(new HD_Log__c(Process_Name__c = 'Batch_AgreementUpdateDates', Error_Description__c = e.getMessage(), Status__c = 'Fail'));
        } 
        
    }

    global void finish(Database.BatchableContext BC) {
        if(!errorLogs.isEmpty()){
            HD_Log__c log = new HD_Log__c(/*Send_Result__c = true, */ Process_Name__c = 'Batch_AgreementUpdateDates', Status__c = 'Fail');
            insert log;
            for(HD_Log__c hl : errorLogs){
                hl.Parent_Log__c = log.Id;
            }
            insert errorLogs;
        }
    }

    webService static void runBatchProcess() {
        Batch_AgreementUpdateDates batch = new Batch_AgreementUpdateDates();
        Database.executeBatch(batch,100);
    } 
}