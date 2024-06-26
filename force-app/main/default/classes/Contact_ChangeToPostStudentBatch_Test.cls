@isTest
private class Contact_ChangeToPostStudentBatch_Test {
   
    @isTest(seeAllData=false)
	static void Contact_ChangeToPostStudentBatch_Test() {
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

        LG__c lg = new LG__c(Id = testEnv.lgId);
        lg.LG_Start_Date__c = System.today().addDays(-20);
        lg.LG_End_Date__c = System.today().addDays(-2);
        lg.Group_Status__c = 'Planned';
        update lg;

        lg.Group_Status__c = 'Active';
        lg.LG_End_Date__c = System.today().addDays(-2);
        update lg;

        Contact studentContact = new Contact(Id = testEnv.studentContactId);
        studentContact.RecordTypeId = Contact.sObjectType.getDescribe().getRecordTypeInfosByName().get('Student').getRecordTypeId();
		studentContact.Status__c = 'Active';
        update studentContact;

        LG_Student__c student = new LG_Student__c(Id = testEnv.studentId);
        student.Status_in_LG__c = 'Registered';
        student.Student_Start_Paying_Date__c = System.today().addDays(-20);
        student.Student_End_Paying_Date__c = System.today().addDays(-2);
        student.Student_Course_Start_Date__c = System.today().addDays(-20);
        student.Student_Course_End_Date__c = System.today().addDays(-2);
        update student;

        System.assert(1==[SELECT Id FROM Contact WHERE Id = :studentContact.Id AND Status__c = 'Active'].size());
		
        Test.startTest();
	        Contact_ChangeToPostStudentBatch batch = new Contact_ChangeToPostStudentBatch();
	        batch.contactIds.add(studentContact.Id);

	        Database.executeBatch(batch);
	    Test.stopTest();

	    System.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :studentContact.Id AND Status__c = 'Post Student'].size());

    }
}