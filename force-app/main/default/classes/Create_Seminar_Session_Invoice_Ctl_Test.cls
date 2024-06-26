@isTest
private class Create_Seminar_Session_Invoice_Ctl_Test {
    
    @isTest(seeAllData=false)
    static void Create_Seminar_Session_Invoice_Ctl_Test() {
    	Account acc2 = ObjectCreator.getNewAccount();
        insert acc2;
        
        Contact seminarContact 	= ObjectCreator.getNewContact(acc2.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
	    seminarContact.TT_Qualified__c= 'TT'; 
	    insert seminarContact;
        
    	Seminar__c seminar = ObjectCreator.getNewSeminar();
    	seminar.Teacher_Trainer__c = seminarContact.Id;
    	seminar.Hosting_Franchisee__c = acc2.Id;
    	seminar.TTC_Seminar_Name__c = 'Test';
    	seminar.Start_Date__c = system.today();
    	seminar.End_Date__c = system.today().addDays(1);
    	seminar.Venue_City__c = 'Test';
    	seminar.TT_Status__c = 'Approved by TT';
    	insert seminar;

		seminar.Status__c = 'Confirmed';
		update seminar;

    	Seminar_Session__c sSession = new Seminar_Session__c();
    	sSession.Invoice_Number_Priority__c = '6';
    	sSession.Order_Number_Priority__c = '6';
    	//sSession.First_Seminar_Start_Date__c = System.today();
    	//sSession.Last_Seminar_Start_Date__c = System.today();
    	insert sSession;

		Account acc3 = acc2.clone(false, true, false, false);
		acc3.Name = 'Test03';
        insert acc3;
        
		Seminar__c seminar2 = seminar.clone( false, true, false, false );
    	seminar2.Status__c = 'Confirmed';
    	seminar2.Hosting_Franchisee__c = acc3.Id;
    	insert seminar2;
		
    	ApexPages.StandardController sc = new ApexPages.StandardController( seminar );
    	//Test not same account error
		Apexpages.currentPage().getParameters().put('ids', String.valueOf(seminar.Id)+','+String.valueOf(seminar2.Id));

    	Create_Seminar_Session_Invoice_Ctl ctrl = new Create_Seminar_Session_Invoice_Ctl(sc);
    	
    	//Test success scenario
    	Apexpages.currentPage().getParameters().put('ids', String.valueOf(seminar.Id));
    	
    	ctrl = new Create_Seminar_Session_Invoice_Ctl(sc);
    	ctrl.doContinue();

    	ctrl.dummySeminar.Hidden_Seminar_Session_Filtered__c = seminar.Id;
    	ctrl.RetrieveSeminarSession();

    	ctrl.dummySession = sSession;
    	
    	ctrl.dummySession.Name = 'Test';
    	
    	ctrl.setNewSession( 'xxxx' );
    	ctrl.doContinue();    	
    	ctrl.setNewSession( 'false' );
    	
    	ctrl.doContinue();
    	ctrl.getNewSession();

    	seminar.Seminar_Session__c = sSession.Id;
    	update seminar;
		
		//Test error for already assigned to a seminar
    	ctrl = new Create_Seminar_Session_Invoice_Ctl(sc);
    	
    	//Test Status not confirmed error
    	seminar.Status__c = 'Postponed';
    	update seminar;
    	
    	ctrl = new Create_Seminar_Session_Invoice_Ctl(sc);
    }

}