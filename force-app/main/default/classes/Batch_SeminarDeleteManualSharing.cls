global class Batch_SeminarDeleteManualSharing implements Database.Batchable<Id>, Database.Stateful {
    public String query;
    public List<Seminar__c> seminarCancelled;
    public List<Id> userShareIds;
    public Map<Id,Set<Seminar__Share>> shares;
    public Map<Id,Id> notDeleteTrainer;

    global Iterable<Id> start(Database.BatchableContext bc) {

        shares = new Map<Id,Set<Seminar__Share>>();
        userShareIds = new List<Id>();
        notDeleteTrainer = new Map<Id,Id>();
        Set<Id> seminarCancelledIds = new Set<Id>();
        for (Seminar__c seminar : seminarCancelled) {
            seminarCancelledIds.add(seminar.Id);
            notDeleteTrainer.put(seminar.Id, seminar.Teacher_Trainer__c);
        }
        
        //getting shares on canceled seminars
        for(Seminar__Share sShare : [SELECT Id, UserOrGroupId, ParentId FROM Seminar__Share WHERE ParentId IN :seminarCancelledIds AND RowCause = 'Manual']){
            if (!shares.containsKey(sShare.UserOrGroupId)) {
                shares.put(sShare.UserOrGroupId, new Set<Seminar__Share>());                        
                userShareIds.add(sShare.UserOrGroupId);
            }                   
            shares.get(sShare.UserOrGroupId).add(sShare);
        }

        return userShareIds;
    }

    global void execute(Database.BatchableContext BC, list<Id> users2delShare) {

            Map<Id,Set<Seminar__Share>> mapshares2del = new Map<Id,Set<Seminar__Share>>();
            //getting contact from users with share
            Map<Id,Id> contactUser = new Map<Id,Id>();
            for(User u : [SELECT ContactId FROM User WHERE Id IN :users2delShare OR ContactId IN :notDeleteTrainer.values()]){
                contactUser.put(u.ContactId, u.Id);
                if (shares.containsKey(u.Id)) {
                    mapshares2del.put(u.Id, shares.get(u.Id));
                }
            }

            //avoid to delete seminar teachers
            for(Seminar_Teachers__c st : [SELECT Id, Teacher__r.Contact_Partner_User__c, Seminar__c, Seminar__r.Hosting_Franchisee__r.Partner_Account_User__c, Teacher_Status_in_seminar__c FROM Seminar_Teachers__c WHERE (Teacher_Status_in_seminar__c = 'Registered' AND Teacher__r.Contact_Partner_User__c IN :users2delShare) OR Seminar__r.Hosting_Franchisee__r.Partner_Account_User__c IN :users2delShare]){
                if(mapshares2del.containsKey(st.Seminar__r.Hosting_Franchisee__r.Partner_Account_User__c)){
                    Set<Seminar__Share> sSet = mapshares2del.get(st.Seminar__r.Hosting_Franchisee__r.Partner_Account_User__c);
                    Set<Seminar__Share> sSet2 = new Set<Seminar__Share>();
                    for (Seminar__Share sShare : sSet) {                    
                        if(sShare.ParentId != st.Seminar__c){
                            sSet2.add(sShare);
                        }                        
                    }
                    mapshares2del.put(st.Seminar__r.Hosting_Franchisee__r.Partner_Account_User__c, sSet2);
                }

                if(mapshares2del.containsKey(st.Teacher__r.Contact_Partner_User__c) && st.Teacher_Status_in_seminar__c == 'Registered'){
                    Set<Seminar__Share> sSet = mapshares2del.get(st.Teacher__r.Contact_Partner_User__c);
                    Set<Seminar__Share> sSet2 = new Set<Seminar__Share>();
                    for (Seminar__Share sShare : sSet) {                    
                        if(sShare.ParentId != st.Seminar__c){
                            sSet2.add(sShare);
                        }                        
                    }
                    mapshares2del.put(st.Teacher__r.Contact_Partner_User__c, sSet2);
                }

            }

            //avoid to delete teacher trainers
            for (Id sId : notDeleteTrainer.keySet()) {
                Id teacherTrainerId = notDeleteTrainer.get(sId);
                Id uId = contactUser.get(teacherTrainerId);
                //check teacher trainer shares
                if(mapshares2del.containsKey(uId)){
                    Set<Seminar__Share> sSet = mapshares2del.get(uId);
                    Set<Seminar__Share> sSet2 = new Set<Seminar__Share>();
                    for(Seminar__Share ss : sSet){
                        Boolean cond = notDeleteTrainer.containsKey(ss.ParentId);

                        if(cond){
                            Id tId = notDeleteTrainer.get(ss.ParentId);
                            cond = teacherTrainerId==tId;
                        }

                        //only delete shares were he isnt trainer
                        if(!cond){
                            sSet2.add(ss);
                        }
                    }
                    mapshares2del.put(uId, sSet2);
                }
            }

            List<Seminar__Share> shares2del = new List<Seminar__Share>();
            for (Id uId : mapshares2del.keySet()) {
                shares2del.addAll(mapshares2del.get(uId));
            }

            /*for(User u : [SELECT UserType FROM User WHERE UserType='PowerPartner' AND Id IN :shares.keySet()]){
                shares2del.addAll(shares.get(u.Id));
            }*/

            if(!shares2del.isEmpty()){
                Database.DeleteResult[] delSharingResult = Database.delete(shares2del, false);          
            }
    }

    global void finish(Database.BatchableContext BC) {

    }
}