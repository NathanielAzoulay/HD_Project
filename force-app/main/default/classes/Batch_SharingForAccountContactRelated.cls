/******************************************************************************* 
Name              : Batch_SharingForAccountContactRelated
Description       : Need batch process that will give permissions on Contact Account Relathanship
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez             11/01/2017          Yaara Nadir               [SW-23178]
*******************************************************************************/

global class Batch_SharingForAccountContactRelated implements Database.Batchable<sObject>, Database.Stateful {
    public String query;

    public List<Id> contactIds = new List<Id>();
    Id recTypeTeacherId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();

    global Batch_SharingForAccountContactRelated() {
        String query = 'SELECT Id, ContactId, AccountId, LastModifiedById FROM AccountContactRelation';

        this.query = query;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        if (!contactIds.isEmpty()) {
            query += ' WHERE ContactId IN :contactIds';
        }

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, list<AccountContactRelation> scope) {

        Map<Id,Set<Id>> accIds = new Map<Id,Set<Id>>();
        Map<Id,Set<Id>> conAccIds = new Map<Id,Set<Id>>();
        System.debug(LoggingLevel.ERROR, '*** : scope' + scope);
        
        for(AccountContactRelation cRelation : scope){
            if (!accIds.containsKey(cRelation.AccountId)) {
                accIds.put(cRelation.AccountId,new Set<Id>());
            }
            accIds.get(cRelation.AccountId).add(cRelation.ContactId);

            if (!conAccIds.containsKey(cRelation.ContactId)) {
                conAccIds.put(cRelation.ContactId,new Set<Id>());
            }
            conAccIds.get(cRelation.ContactId).add(cRelation.AccountId);           
        }

        //getting contact users
        Map<Id,Id> conUsers = new Map<Id,Id>(); 
        for (Contact con : [SELECT Contact_Partner_User__c FROM Contact WHERE Id IN :conAccIds.keySet() AND RecordTypeId =:recTypeTeacherId]) {
            if(con.Contact_Partner_User__c != null){
                conUsers.put(con.Id ,con.Contact_Partner_User__c);
            }    
        }

        //getting account users
        Map<Id,Id> accUsers = new Map<Id,Id>(); 
        for (Account acc : [SELECT Partner_Account_User__c FROM Account WHERE Id IN :accIds.keySet()]) {
            if(acc.Partner_Account_User__c != null){
                accUsers.put(acc.Id ,acc.Partner_Account_User__c);
            }    
        }

        //mapping agreements by contacts
        Map<Id,Set<Id>> teacherAgreements = new Map<Id,Set<Id>>();
        for(Teacher_Agreement__c ta : [SELECT Teacher__c FROM Teacher_Agreement__c WHERE Teacher__c IN :conAccIds.keySet() AND Agreement_Status__c = 'Approved']){
            if(!teacherAgreements.containsKey(ta.Teacher__c)){
                teacherAgreements.put(ta.Teacher__c,new Set<Id>());
            }
            teacherAgreements.get(ta.Teacher__c).add(ta.Id);
        }

        List<AccountShare> newSharesOnAccount = new List<AccountShare>();
        List<ContactShare> newContactShares = new List<ContactShare>();
        List<Teacher_Agreement__Share> newSharesTA = new List<Teacher_Agreement__Share>();
        Set<String> newSharesTAkey = new Set<String>();

        for(AccountContactRelation cRelation : scope){
            if(conUsers.containsKey(cRelation.ContactId)){
                newSharesOnAccount.add(new AccountShare(AccountId = cRelation.AccountId, UserOrGroupId = conUsers.get(cRelation.ContactId), AccountAccessLevel = 'Read', OpportunityAccessLevel = 'None' )); 
            }

            if(accUsers.containsKey(cRelation.AccountId)){
                Id uId = accUsers.get(cRelation.AccountId);
                newContactShares.add(new ContactShare(ContactId = cRelation.ContactId, UserOrGroupId = uId, ContactAccessLevel = 'Edit'));
            
                if(teacherAgreements.containsKey(cRelation.ContactId)){
                    for(Id taId : teacherAgreements.get(cRelation.ContactId)){
                        String key = taId +'_'+ uId;
                        if(!newSharesTAkey.contains(key)){
                            newSharesTAkey.add(key);
                            newSharesTA.add(new Teacher_Agreement__Share(ParentId = taId, UserOrGroupId = uId, AccessLevel = 'Read'));
                        }
                    }
                }
            }
        }

        System.debug(LoggingLevel.ERROR, '***newSharesOnAccount: ' + newSharesOnAccount);
        if(!newSharesOnAccount.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(newSharesOnAccount, false); // TODO: talk with Dana & Yaara for knowing how to report the errors...
            System.debug(LoggingLevel.ERROR, '***newSharingData: ' + newSharingData);
        }

        System.debug(LoggingLevel.ERROR, '***newContactShares: ' + newContactShares);
        if(!newContactShares.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(newContactShares, false); // TODO: talk with Dana & Yaara for knowing how to report the errors...
            System.debug(LoggingLevel.ERROR, '***newSharingData: ' + newSharingData);
        }

        System.debug(LoggingLevel.ERROR, '***newSharesTA: ' + newSharesTA);
        if(!newSharesTA.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(newSharesTA, false); // TODO: talk with Dana & Yaara for knowing how to report the errors...
        }

    }

    global void finish(Database.BatchableContext BC) {

    }
}