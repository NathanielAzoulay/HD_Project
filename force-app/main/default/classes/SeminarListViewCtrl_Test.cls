@isTest
private class SeminarListViewCtrl_Test {
    @isTest(seeAllData=false)
    static void createNewTTPayment() {

      	//ObjectCreator.initializeCustomSetting();
	    Account acc2 = ObjectCreator.getNewAccount();
        insert acc2;

		Contact teacherContact2 = ObjectCreator.getNewContact(acc2.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        teacherContact2.TT_Qualified__c= 'TT';
        insert teacherContact2;

		User u2 = ObjectCreator.getNewUser(teacherContact2.Id);
    	insert u2;

    	Seminar__c seminar = ObjectCreator.getNewSeminar();
      	seminar.Status__c = 'Completed';
      	seminar.Teacher_Trainer__c = teacherContact2.Id;
      	insert seminar;

		SeminarListViewCtrl.createNewTTPayment(new List<String>{seminar.Id});

		seminar.Status__c = 'Evaluated';
		update seminar;

		SeminarListViewCtrl.createNewTTPayment(new List<String>{seminar.Id});

		Seminar__Share ss = new Seminar__Share();
		ss.ParentId = seminar.Id;
		ss.UserOrGroupId = u2.Id;
		ss.AccessLevel = 'Edit';
		insert ss;

		ContactShare cs = new ContactShare();
		cs.ContactId = teacherContact2.Id;
		cs.UserOrGroupId = u2.Id;
		cs.ContactAccessLevel = 'Edit';
		insert cs;

		/*seminar.TT_Payment__c = null;
		update seminar;
		
		SeminarListViewCtrl.createNewTTPayment(new List<String>{seminar.Id});*/

    	System.runAs(u2){
    		System.debug(LoggingLevel.ERROR, '*** runAs: ');
        	try{
        		SeminarListViewCtrl.createNewTTPayment(new List<String>{seminar.Id});
        	    System.debug(LoggingLevel.ERROR, '*** runAs2: ');
			}catch(Exception e){
        		System.debug(LoggingLevel.ERROR, '*** e: ' + e.getMessage());
        	}
    	}

    }
}