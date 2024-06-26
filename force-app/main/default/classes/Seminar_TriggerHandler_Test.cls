@isTest
private class Seminar_TriggerHandler_Test {
    
    @isTest(seeAllData=false)
    static void MaintainManualShares_Test() {

        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        HD_TriggerSettings.disableTriggersFromTest.remove( 'MaintainManualShares' );
        HD_TriggerSettings.disableTriggersFromTest.remove( 'seminarCreateSharingRules' );

        Test.startTest();

        Contact ttcontact = ObjectCreator.getNewContact(testEnv.accId, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());
        ttcontact.TT_Qualified__c = 'TT';              
        insert ttcontact;

        User ttu = ObjectCreator.getNewUser(ttcontact.Id);
        insert ttu;

        Account partnerAcc = ObjectCreator.getNewAccount();
        insert partnerAcc;

        Contact partnerteacherContactNC = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert partnerteacherContactNC;

        User uNC = ObjectCreator.getNewUser(partnerteacherContactNC.Id);
        insert uNC;

        partnerAcc.Partner_Account_NC__c = uNC.Id;
        update partnerAcc;

        insert new AccountShare(AccountId = partnerAcc.Id, AccountAccessLevel = 'Edit', UserOrGroupId = ttu.Id, OpportunityAccessLevel = 'Edit', ContactAccessLevel = 'Edit' );
            
        Seminar__c seminar = new Seminar__c();      
        seminar.Hosting_Franchisee__c = partnerAcc.Id; 
        insert seminar;

        insert new Seminar__Share(ParentId = seminar.Id, UserOrGroupId = ttu.Id ,AccessLevel = 'Edit');

        System.runAs(ttu){

                List<Seminar__Share> ss = [SELECT Id, UserOrGroupId FROM Seminar__Share WHERE ParentId = :seminar.Id];
                System.assert(ss.size() > 0);

                seminar.OwnerId = ttu.Id;
                update seminar;

                Set<Id> oldShares = new Set<Id>();
                for(Seminar__Share sShare : ss){
                    oldShares.add(sShare.UserOrGroupId);
                }

                /*List<Seminar__Share> sharesKeeped = [SELECT Id, UserOrGroupId FROM Seminar__Share WHERE ParentId = :seminar.Id AND UserOrGroupId IN : oldShares];
                System.assert(sharesKeeped.size() == oldShares.size());*/

        }
        
        Test.stopTest();
    }
}