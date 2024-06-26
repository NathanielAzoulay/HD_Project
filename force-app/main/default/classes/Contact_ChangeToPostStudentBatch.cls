/******************************************************************************* 
Name              : Contact_ChangeToPostStudentBatch
Description       : 
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez         26/04/2016              Yaara Nadir              [SW-19189]
*******************************************************************************/

global class Contact_ChangeToPostStudentBatch implements Database.Batchable<sObject> {
    public String query;
    public List<Id> contactIds = new List<Id>();
    Id studentRecordTypeID = Contact.sObjectType.getDescribe().getRecordTypeInfosByName().get('Student').getRecordTypeId();

    global Database.QueryLocator start(Database.BatchableContext bc) {
        query = 'SELECT Id, ( SELECT Id FROM LG_Students__r WHERE Completed__c = false AND Status_in_LG__c = \'Registered\') FROM Contact WHERE Status__c = \'Active\' AND RecordTypeId = :studentRecordTypeID';

        if(!contactIds.isEmpty()){
            query += ' AND Id IN :contactIds';
        }        

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, list<Sobject> scope) {

        try{ 
            List<Contact> contacts2up = new List<Contact>();
            for(Contact con : (List<Contact>) scope){
                if(con.LG_Students__r.size() == 0){
                    con.Status__c = 'Post Student';
                    contacts2up.add(con);
                }
            }

            if(!contacts2up.isEmpty()){
                List<Database.SaveResult> slr = Database.update(contacts2up,false);
                for(Integer i = 0; i < slr.size(); i++){
                    Database.SaveResult sr = slr.get(i);
                    if(!sr.isSuccess()){
                        System.debug(System.LoggingLevel.ERROR, 'Contact Update Error --> ' + contacts2up[i] + ' ' + sr.getErrors());
                    }
                }
            }

        }catch(Exception e){
            System.debug(e.getMessage());
        }
        
    }

    global void finish(Database.BatchableContext BC) {

    }
}