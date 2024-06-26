/******************************************************************************* 
Name              : SeminarListViewCtrl
Description       : Logic for Create New TT Payment
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez             07/21/2016          Ella Bernachick               [SW-20509]
*******************************************************************************/

global class SeminarListViewCtrl {
    
	webService static String createNewTTPayment(List<String> seminarIds) {
    	Boolean validSelection = false;
    	String retMsg = Label.TT_Payment_choose_record;
    	User currentUser = [SELECT Id, ContactId FROM User WHERE Id =:UserInfo.getUserId()];

	    Decimal salarySummary = 0;
	    System.debug(LoggingLevel.ERROR, '*** createNewTTPayment: ' + UserInfo.getUserId());
	    System.debug(LoggingLevel.ERROR, '*** seminarIds: ' + seminarIds);
		
		try{
			List<Seminar__c> seminarSelected = [SELECT Id, Status__c, Teacher_Trainer__c, TT_Payment__c, TT_Salary__c FROM Seminar__c WHERE Id IN :seminarIds];
	    	System.debug(LoggingLevel.ERROR, '*** seminarSelected: ' + seminarSelected);
			
			for (Seminar__c seminar : seminarSelected ) {
				System.debug(LoggingLevel.ERROR, '*** seminar: ' + seminar);
				System.debug(LoggingLevel.ERROR, '*** currentUser.ContactId: ' + currentUser.ContactId);
				System.debug(LoggingLevel.ERROR, '*** currentUser.Id: ' + currentUser.Id);
				
	    		//validations
		    	//2.9.2.3 Check that at least one TTC Seminar record is chosen and click on "Create New TT Payment"
				//2.9.2.2 Check if all chosen TTC/Seminars are in Status=Evaluated
				if(seminar.Status__c != 'Evaluated'){
					retMsg = Label.TT_Payment_status_evaluated;
					break;
				}
				//2.9.2.5 Check that all checked TTC/Seminars has a blank value in TTC/Seminar. TT Payment = null (lookup field) – shows if the TTC/Seminar is already a part of a TT Payment record and cannot be added to another one
				if(seminar.TT_Payment__c != null){
					retMsg = Label.TT_Payment_lookup_not_null;	
					break;
				}
				//2.9.2.4 Check that all chosen records belong to this relevant user (Seminar. Teacher Trainer = login user)
				if(seminar.Teacher_Trainer__c != currentUser.ContactId){
					retMsg = Label.TT_Payment_Teacher_Trainer;
					break;
				}
				if(seminar.TT_Salary__c != null){
					salarySummary += seminar.TT_Salary__c;
				}
				
				validSelection = true;
	    	}

    	
	    	if(validSelection){
				TT_Payment__c newTTPayment = new TT_Payment__c();
				newTTPayment.Payment_Amount__c = salarySummary;
				newTTPayment.Payment_Status__c = 'Request';
				newTTPayment.Teacher_Trainer__c = currentUser.ContactId;
				
				newTTPayment.Payment_Requested_Date__c = system.today();
				
				insert newTTPayment;
				retMsg = Label.TT_Payment_Created_Successfully;

				List<Seminar__c> seminar2up = new List<Seminar__c>();
				for (Seminar__c seminar : seminarSelected ) {
    				Seminar__c seminarUp = new Seminar__c(Id = seminar.Id);
    				seminarUp.TT_Payment__c = newTTPayment.Id;
    				seminar2up.add(seminarUp);
				}

				update seminar2up; 
	    	}
    	}catch(Exception e){
    		retMsg = 'Fatal Internal Error';
			System.debug(LoggingLevel.ERROR, '*** : ' + e.getMessage() + ' ' + e.getStackTraceString());
    	}

    	return retMsg;    	
    }

}