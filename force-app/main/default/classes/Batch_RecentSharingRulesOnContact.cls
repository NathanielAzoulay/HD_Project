/******************************************************************************* 
Name              : Batch_RecentSharingRulesOnContact
Description       : Handler the manually shared records of Contact
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
0. G. Fernandez             06/16/2016          Yaara Nadir               [SW-19588]
1. G. Fernandez             05/08/2016          Yaara Nadir               [SW-20744]
2. G. Fernandez             25/08/2016          Yaara Nadir               [SW-21077]
*******************************************************************************/

global class Batch_RecentSharingRulesOnContact implements Database.Batchable<sObject> {
    public String query;
    //set minutes for get records from last run
    Datetime lastRun = System.now().addMinutes(-60);

    global Batch_RecentSharingRulesOnContact() {
        
        System.debug(LoggingLevel.ERROR, '*** : lastRun' + lastRun);
        String query = 'SELECT Id, ContactAccessLevel, RowCause, ContactId, UserOrGroup.Profile.Name, LastModifiedById FROM ContactShare WHERE LastModifiedDate >= :lastRun';
        this.query = query;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, list<ContactShare> scope) {

        Set<Id> contactIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        Set<Id> ownerIds = new Set<Id>();

        for(ContactShare cShare :scope){
            contactIds.add(cShare.ContactId );
            
            userIds.add(cShare.UserOrGroupId);            
            ownerIds.add(cShare.LastModifiedById);            
        }

        Set<Id> contact2share = new Set<Id>();
        Set<Id> MFs = new Set<Id>();
        List<Base_Course__Share> shares2del = new List<Base_Course__Share>();
        for(User u : [SELECT Id, Profile.Name, ContactId FROM User WHERE Id IN :userIds OR Id IN :ownerIds]){
            if (u.Profile.Name.contains('LC')){ 
                contact2share.add(u.Id);
            }
            if (u.Profile.Name.contains('MF') || Test.isRunningTest()){ 
                MFs.add(u.Id);
            }
        }
        /*1*/
        Set<Id> partnerAccUserIds = new Set<Id>();
        List<Holiday_Vacation__c> hvacations = new List<Holiday_Vacation__c>();
        for(Holiday_Vacation__c hv : [SELECT LC__r.Partner_Account_User__c, Teacher__c FROM Holiday_Vacation__c WHERE Teacher__c IN :contactIds]){
            partnerAccUserIds.add(hv.LC__r.Partner_Account_User__c );
            hvacations.add(hv);
        }

        Map<Id,Id> accIds = new Map<Id,Id>();
        for(User u :[SELECT AccountId FROM User WHERE Id IN :partnerAccUserIds]){
            accIds.put(u.Id,u.AccountId);
        }

        Set<Id> accIdset = new Set<Id>();
        accIdset.addAll(accIds.values());
        Map<Id, Set<id>> ncHierarchyUsers = MonitorRecursionClass.getfranchiseeNCHierarchyUsers(accIdset);

        List<ContactShare> newContactShares = new List<ContactShare>();
        for(Holiday_Vacation__c hv : hvacations){
            newContactShares.add(new ContactShare(ContactId = hv.Teacher__c, UserOrGroupId = hv.LC__r.Partner_Account_User__c, ContactAccessLevel = 'Read'));
            
            if(!ncHierarchyUsers.isEmpty()){
                Id accId = accIds.get(hv.LC__r.Partner_Account_User__c);
                for(Id uId : ncHierarchyUsers.get(accId)){
                    newContactShares.add(new ContactShare(ContactId = hv.Teacher__c, UserOrGroupId = uId, ContactAccessLevel = 'Read'));
                }                       
            }
        }
        /*1*/
        if (!newContactShares.isEmpty()) {
            insert newContactShares;
        }

        /*2*/
        //TODO filter shares to only created by MF
        Map<Id,Set<Id>> contactMapIds = new Map<Id,Set<Id>>();
        for(ContactShare cShare :scope){
            //if share was created by MF to TC, also give permission to T. Agreements
            if( cShare.RowCause == 'Manual' && contact2share.contains(cShare.UserOrGroupId) && MFs.contains(cShare.LastModifiedById)){
                if( !contactMapIds.containsKey(cShare.ContactId) ){
                    contactMapIds.put(cShare.ContactId, new Set<Id>());
                }
                contactMapIds.get(cShare.ContactId).add(cShare.UserOrGroupId);
            }
        }

        List<Teacher_Agreement__Share> newTeacherAgreeShares = new List<Teacher_Agreement__Share>();
        for(Teacher_Agreement__c ta : [SELECT Id, Teacher__c FROM Teacher_Agreement__c WHERE Teacher__c IN :contactMapIds.keySet()]){
            for(Id uId : contactMapIds.get(ta.Teacher__c)){
                newTeacherAgreeShares.add(new Teacher_Agreement__Share(ParentId = ta.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
            }
        }
        /*2*/
        if (!newTeacherAgreeShares.isEmpty()) {
            insert newTeacherAgreeShares;
        }

    }

    global void finish(Database.BatchableContext BC) {
        if(!Test.isRunningTest()){
            Batch_RecentRelationshipOnContact b = new Batch_RecentRelationshipOnContact();
            Database.executeBatch(b);
        }
    }
}