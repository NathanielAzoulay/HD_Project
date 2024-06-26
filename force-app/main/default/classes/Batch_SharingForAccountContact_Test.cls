@isTest
private class Batch_SharingForAccountContact_Test {

    @isTest(seeAllData=false)
    static void Batch_SharingForAccountContactRelated_Test() {
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

        Account partnerAcc = ObjectCreator.getNewAccount();
        insert partnerAcc;

        Contact partnerteacherContact   = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert partnerteacherContact;

        User u2 = ObjectCreator.getNewUser(testEnv.teacherContactId);
        insert u2;

        Contact ttcontact = ObjectCreator.getNewContact(testEnv.accId, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());
        ttcontact.TT_Qualified__c = 'TT';              
        insert ttcontact;

        Test.startTest();

            Teacher_Agreement__c tAgree = new Teacher_Agreement__c();
            tAgree.Teacher__c = partnerteacherContact.Id;
            tAgree.Agreement_Status__c = 'Approved';
            insert tAgree;

            Account teacherAcc = new Account(Id = testEnv.accId);
            teacherAcc.Partner_Account_User__c = u2.Id;
            update teacherAcc;
            
            insert new AccountContactRelation(ContactId = partnerteacherContact.Id, AccountId = teacherAcc.Id);

            Batch_SharingForAccountContactRelated b = new Batch_SharingForAccountContactRelated();
            Database.executeBatch(b);

        Test.stopTest();

        System.debug(LoggingLevel.ERROR, [SELECT Id FROM ContactShare WHERE ContactId = :partnerteacherContact.Id AND UserOrGroupId = :u2.id]);             
        System.assert([SELECT Id FROM ContactShare WHERE ContactId = :partnerteacherContact.Id AND UserOrGroupId = :u2.id].size() == 1);
        
    }
}