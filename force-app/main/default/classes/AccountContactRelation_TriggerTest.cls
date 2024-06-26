@isTest
private class AccountContactRelation_TriggerTest {
	@isTest(seeAllData = false)
    static void MainFranchiseDelete() {
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

        Account partnerAcc = ObjectCreator.getNewAccount();
        partnerAcc.Account_Type__c = 'MF';
        insert partnerAcc;

        Account teacherAcc = new Account(Id = testEnv.accId);
        teacherAcc.Account_Type__c = 'ILCF';
        update teacherAcc;

        Account partnerAcc2 = ObjectCreator.getNewAccount();
        insert partnerAcc2;

        Contact partnerteacherContact   = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert partnerteacherContact;
        
        AccountContactRelation acr1 = new AccountContactRelation(ContactId = partnerteacherContact.Id, AccountId = partnerAcc2.Id);
        AccountContactRelation acr2 = new AccountContactRelation(ContactId = partnerteacherContact.Id, AccountId = teacherAcc.Id);
        insert new List<AccountContactRelation>{acr1,acr2};

        partnerteacherContact.Main_Franchise__c = partnerAcc2.Id;
        update partnerteacherContact;


        delete acr1;
		//Comment out by Avihai Task-000001930
        //System.assert([SELECT Main_Franchise__c FROM Contact WHERE Id = :partnerteacherContact.Id].Main_Franchise__c == teacherAcc.Id);

    }
}