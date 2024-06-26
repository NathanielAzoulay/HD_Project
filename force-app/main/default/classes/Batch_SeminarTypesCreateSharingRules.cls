/******************************************************************************* 
Name              : Batch_SeminarTypesCreateSharingRules
Description       : Recreate Seminar sharing according to Existent Seminar Types shares
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez                21/05/2017             Yaara Nadir               [SW-24965]
*******************************************************************************/

global class Batch_SeminarTypesCreateSharingRules implements Database.Batchable<sObject>, Database.Stateful{
    
    public String query = 'SELECT Id, ParentId, UserOrGroupId FROM Seminar_Type__Share';
    public List<String> profile = new List<String>();
    public Set<Id> userIds = new Set<Id>();

    public Batch_SeminarTypesCreateSharingRules(){
        
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {

        if(!profile.isEmpty()){
            Map<Id,User> userFromProfile = new Map<Id,User>([SELECT Id FROM User WHERE Profile.Name IN :profile]);
            userIds = userFromProfile.keySet(); 
            query += ' WHERE UserOrGroupId IN :userIds';
        }

        System.debug(query);

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Seminar_Type__Share> scope) {
        
        Savepoint sp = Database.setSavepoint();
        
        try{
            List<Seminar__Share> sh2Ins = new List<Seminar__Share>();
            Map<Id, Set<Id>> sh2check = new Map<Id, Set<Id>>();
            Map<Id,Set<Id>> stUsersShare = new Map<Id,Set<Id>>();
            Set<Id> stsIds = new Set<Id>();
            //group semtypes and users
            for(Seminar_Type__Share sts : scope){
                if(!stUsersShare.containsKey(sts.ParentId)){
                    stUsersShare.put(sts.ParentId,new Set<Id>());
                }
                stUsersShare.get(sts.ParentId).add(sts.UserOrGroupId);

                stsIds.add(sts.UserOrGroupId);
            }

            Set<Id> hostIds = new Set<Id>();
            Map<Id,Id> conUserIds = new Map<Id,Id>();
            //geting seminars info, hosting franchise
            Map<Id,Seminar__c> lsem = new Map<Id,Seminar__c>([SELECT Id, Seminar_Type__c, Hosting_Franchisee__c, Teacher_Trainer__c FROM Seminar__c WHERE Seminar_Type__c IN :stUsersShare.keySet()]);
            for (Seminar__c sem : lsem.values()) {
                hostIds.add(sem.Hosting_Franchisee__c);
                conUserIds.put(sem.Teacher_Trainer__c,null);
                if (!sh2check.containsKey(sem.Id)) {
                    sh2check.put(sem.Id, new Set<Id>()); 
                }
            }

            Map<Id,Id> hostUserIds = new Map<Id,Id>();
            //hosting users
            for(List<Account> lacc :[SELECT Partner_Account_User__c FROM Account WHERE Id IN :hostIds]){
                for(Account acc : lacc){
                    hostUserIds.put(acc.Id, acc.Partner_Account_User__c);
                }
            }

            //teacher trainers users
            for(List<User> lu :[SELECT AccountId, ContactId FROM User WHERE ContactId IN :conUserIds.keySet()]){
                for(User u : lu){
                    conUserIds.put(u.ContactId,u.Id);
                }
            }

            for (Seminar__c sem : lsem.values()) {
                if (stUsersShare.containsKey(sem.Seminar_Type__c)){
                    for (Id stsUserOrGroupId : stUsersShare.get(sem.Seminar_Type__c)) {
                        Id tId = null;
                        if (conUserIds.containsKey(sem.Teacher_Trainer__c) && conUserIds.get(sem.Teacher_Trainer__c) != null) {
                            tId = conUserIds.get(sem.Teacher_Trainer__c); 
                        }
                        Id hId = null;
                        if (hostUserIds.containsKey(sem.Hosting_Franchisee__c) && conUserIds.get(sem.Hosting_Franchisee__c) != null) {
                            hId = hostUserIds.get(sem.Hosting_Franchisee__c);
                        }

                        //Except (additional logic) : 
                        //(a) TTC/Seminar. Hosting Franchise. Partner Account User (already have R/W Permissions from #1) 
                        //(b) TTC/Seminar. Teacher Trainer (already gets R/W permissions from #3) 
                        if(tId != stsUserOrGroupId && hId != stsUserOrGroupId){
                            sh2Ins.add(new Seminar__Share(ParentId = sem.Id, UserOrGroupId = stsUserOrGroupId, AccessLevel = 'Read'));
                            sh2check.get(sem.Id).add(stsUserOrGroupId);
                        }
                    }
                }
            }

            if(!sh2Ins.isEmpty()){
                Database.SaveResult[] newSharingData = database.insert(sh2Ins, false);
            }

            /*if(!sh2Ins.isEmpty()){
                List<Seminar__Share> ssh2Ins = new List<Seminar__Share>();
                Map<Id, Set<Id>> ssh2check = new Map<Id, Set<Id>>();

                //looking and mapping existent shares
                for (List<Seminar__Share> lss : [SELECT ParentId, UserOrGroupId FROM Seminar__Share WHERE ParentId IN :sh2check.keySet()]) {
                    for (Seminar__Share ss : lss) {
                        if (!ssh2check.containsKey(ss.ParentId)) {
                            ssh2check.put(ss.ParentId, new Set<Id>()); 
                        }
                        ssh2check.get(ss.ParentId).add(ss.UserOrGroupId);
                    }
                }

                //filtering already existent shares
                for (Seminar__Share seminar2share : sh2Ins) { 
                    //checking for each user  
                    for (Id user2share : sh2check.get(seminar2share.ParentId)) {  
                        //if already have sharing 
                        if(!ssh2check.get(seminar2share.ParentId).contains(user2share)){
                            ssh2Ins.add(seminar2share);
                        }
                    }
                }

                if(!ssh2Ins.isEmpty()){
                    Database.SaveResult[] newSharingData = database.insert(ssh2Ins, false);
                }
            }*/


        }catch(Exception ex){
            Database.rollback(sp);
            GlobalHelperMethods.debugErrorMsg(ex);
        }

    }

    global void finish(Database.BatchableContext BC) {

    }
}