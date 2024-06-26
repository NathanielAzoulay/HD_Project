@isTest
private class Batch_SeminarTypesCreateSharingRulesTest {

    @isTest(seeAllData=false)
    static void Batch_SeminarTypesCreateSharingRulesTest() {
        HD_TriggerSettings.disableAllTriggers = true;
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        
        Account partnerAcc = ObjectCreator.getNewAccount();
        insert partnerAcc;

        test.startTest();

	        Contact seminarContact  = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());
	        seminarContact.TT_Qualified__c= 'TT';           
	        insert seminarContact;

	        User u3 = ObjectCreator.getNewUser(seminarContact.Id);
	        insert u3;

            Seminar_Type__c seminarType = new Seminar_Type__c(Name = 'test ' + String.valueOf(Math.random()) );
            seminarType.Active__c = true;
            seminarType.Program_Type__c = 'HDE';
			insert seminarType;
//insert new Seminar_Type__Share(UserOrGroupId = u3.Id, ParentId = seminarType.Id, AccessLevel = 'Read');//Comment out by Avihai 17/07/2018
            insert new Seminar_Type__Share(UserOrGroupId = u3.Id, ParentId = seminarType.Id, AccessLevel = 'Edit');

            Seminar__c seminar = new Seminar__c();      
            seminar.Seminar_Type__c = seminarType.Id;
            insert seminar;
            
            Batch_SeminarTypesCreateSharingRules b = new Batch_SeminarTypesCreateSharingRules();
            Database.executeBatch(b);
            
        test.stopTest();
    }
}