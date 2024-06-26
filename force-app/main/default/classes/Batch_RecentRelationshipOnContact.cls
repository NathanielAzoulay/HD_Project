/******************************************************************************* 
Name              : Batch_RecentRelationshipOnContact
Description       : Handler the manually relationships of Contact
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez             25/08/2016          Yaara Nadir               [SW-21077]
2. G. Fernandez             25/08/2016          Yaara Nadir               [SW-22748]
*******************************************************************************/

global class Batch_RecentRelationshipOnContact implements Database.Batchable<sObject>, Database.Stateful {
    public String query;
    //set minutes for get records from last run
    Datetime lastRun = System.now().addMinutes(-65);

    public List<Id> contactIds = new List<Id>();

    global Batch_RecentRelationshipOnContact() {
        String query = 'SELECT Id, ContactId, AccountId, LastModifiedById FROM AccountContactRelation WHERE LastModifiedDate >= :lastRun';

        this.query = query;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        if (!contactIds.isEmpty()) {
            query = 'SELECT Id, ContactId, AccountId, LastModifiedById FROM AccountContactRelation WHERE ContactId IN :contactIds';
        }

        System.debug(LoggingLevel.ERROR, '*** : lastRun' + lastRun);
        System.debug(LoggingLevel.ERROR, '*** query: ' + query);
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

        Map<String,Map<Id, Set<id>>> hierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(accIds.keySet(),true,true,false);
        Map<Id, Set<id>> franchiseeHierarchyUsers = hierarchyUsers.get('franchisee');
        Map<Id, Set<id>> accUsers = hierarchyUsers.get('account');

        System.debug(LoggingLevel.ERROR, '*** : franchiseeHierarchyUsers' + franchiseeHierarchyUsers);
        System.debug(LoggingLevel.ERROR, '*** : accUsers' + accUsers);
        
        List<ContactShare> newContactShares = new List<ContactShare>();

        if(!franchiseeHierarchyUsers.isEmpty()){
            for(AccountContactRelation cRelation : scope){
                for(Id uId : franchiseeHierarchyUsers.get(cRelation.AccountId)){
                    newContactShares.add(new ContactShare(ContactId = cRelation.ContactId, UserOrGroupId = uId, ContactAccessLevel = 'Edit'));
                }
            }
        }

        //SW-22748
        List<Seminar_Teachers__Share> newSharesST = new List<Seminar_Teachers__Share>();
        List<Teacher_Agreement__Share> newSharesTA = new List<Teacher_Agreement__Share>();
        Map<String,Seminar__Share> newSharesSeminar = new Map<String,Seminar__Share>();
        if(!accUsers.isEmpty()){
            
            Map<Id,Id> seminar = new Map<Id,Id>();
            for(Seminar_Teachers__c st : [SELECT Seminar__c, Teacher__c FROM Seminar_Teachers__c WHERE Teacher__c IN :conAccIds.keySet() AND Teacher_Status_in_seminar__c = 'Registered']){
                for(Id accId : conAccIds.get(st.Teacher__c)){
                    for(Id uId : accUsers.get(accId)){
                        newSharesST.add(new Seminar_Teachers__Share(ParentId = st.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
                        String key = st.Seminar__c + '_' + uId;
                        if (!newSharesSeminar.containsKey(key)) {
                            newSharesSeminar.put(key, new Seminar__Share(ParentId = st.Seminar__c, UserOrGroupId = uId, AccessLevel = 'Read'));
                        }
                    }
                }
            }

            for(Teacher_Agreement__c ta : [SELECT Teacher__c FROM Teacher_Agreement__c WHERE Teacher__c IN :conAccIds.keySet() AND Expired__c = false]){
                for(Id accId : conAccIds.get(ta.Teacher__c)){
                    for(Id uId : accUsers.get(accId)){
                        newSharesTA.add(new Teacher_Agreement__Share(ParentId = ta.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
                    }
                }
            }
        }

        System.debug(LoggingLevel.ERROR, '***newContactShares: ' + newContactShares);
        if(!newContactShares.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(newContactShares, false); // TODO: talk with Dana & Yaara for knowing how to report the errors...
            System.debug(LoggingLevel.ERROR, '***newSharingData: ' + newSharingData);
        }

        System.debug(LoggingLevel.ERROR, '***newSharesST: ' + newSharesST);
        if(!newSharesST.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(newSharesST, false); // TODO: talk with Dana & Yaara for knowing how to report the errors...
        }

        System.debug(LoggingLevel.ERROR, '***newSharesSeminar: ' + newSharesSeminar);
        if(!newSharesSeminar.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(newSharesSeminar.values(), false); // TODO: talk with Dana & Yaara for knowing how to report the errors...
        }

        System.debug(LoggingLevel.ERROR, '***newSharesTA: ' + newSharesTA);
        if(!newSharesTA.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(newSharesTA, false); // TODO: talk with Dana & Yaara for knowing how to report the errors...
        }

        

    }

    global void finish(Database.BatchableContext BC) {

    }
}