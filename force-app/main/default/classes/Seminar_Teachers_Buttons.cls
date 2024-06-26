/******************************************************************************* 
Name              : Seminar_Teachers_Buttons
Description       : Handler the custom buttons on Seminar Teachers
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio         			06/06/2016          	
*******************************************************************************/

global class Seminar_Teachers_Buttons {
	
	/******************************************************************************* 
	Name              : Register_Teachers
	Description       : On pressing "Register Teachers" button on the Seminar Teachers related list, updates the selected Seminar Teachers status in seminar
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Sergio             		06/06/2016          Ella  Bernachik           [SW-19806]
	*******************************************************************************/
	static webservice string Register_Teachers(String ids){
		try{
			system.debug( 'ids: ' + ids );
			if( String.isBlank(ids) ){
				return 'No records selected';
			}
			
			Set<String> semTchIds = new Set<String>();
			semTchIds.addAll(ids.split( ',' ));
			
			List<Seminar_Teachers__c> st2Upd = new List<Seminar_Teachers__c>();
			
			for( Seminar_Teachers__c st : [SELECT Id FROM Seminar_Teachers__c WHERE Id IN :semTchIds ] ){
				st.Teacher_Status_in_seminar__c = 'Registered';
				st2Upd.add(st);
			}
			
			if( st2Upd.isEmpty() == false ){
				update st2Upd;
			}
			
		}catch(Exception e){
			return 'Error: ' + e.getMessage();
		}
		return '';
	}
	
	/******************************************************************************* 
	Name              : Mass_Passed
	Description       : On pressing "Mass Passed" button on the Seminar Teachers related list, updates Teachers final evaluation based on if they were selected or not
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Sergio             		06/07/2016          Ella  Bernachik           [SW-20282]
	2. Hernan             		19/12/2016          Ella  Bernachik           [SW-22760]
	3. Sergio             		15/06/2017          Dafna Margalit            [SW-25390]
	*******************************************************************************/
	static webservice string Mass_Passed(String ids, String seminarId ){
        Savepoint sp = Database.setSavepoint();
		
		try{
			
			Seminar__c s = [SELECT Teacher_Trainer__c, Seminar_Type__r.Type__c FROM Seminar__c WHERE Id =: seminarId];
			User currentUser = [SELECT Id, ContactId, Profile.Name, TT_Coordinator__c FROM User WHERE Id =: UserInfo.getUserId()];
			
			// SW-22760 - > Additional logic item 3
			if(!( (currentUser.ContactId <> null && currentUser.ContactId == s.Teacher_Trainer__c) || currentUser.Profile.Name == 'System Administrator' || currentUser.TT_Coordinator__c == true)){
				return Label.Seminar_MassPassed_UsedBy_Teacher_Trainer;
			}
			
			if( String.isBlank(ids) ){
				return Label.Seminar_MassPassed_Choose_Seminar_Teacher_Record;
			}		
			
			if( s.Seminar_Type__r.Type__c != 'Mass Training'){
				return Label.Seminar_MassPassed_Only_Mass_Training;
			}
			
			Set<Id> semTchIds = new Set<Id>();
			semTchIds.addAll((List<Id>)ids.split( ',' ));
			
			List<Seminar_Teachers__c> st2Upd = new List<Seminar_Teachers__c>();
			
			for( Seminar_Teachers__c st : [SELECT Id, Final_Evaluation__c FROM Seminar_Teachers__c WHERE Seminar__c = :seminarId ] ){
				String prevValue = st.Final_Evaluation__c;
				
				st.Final_Evaluation__c = 'Did Not Participate';
				
				if( semTchIds.contains(st.Id) ){
					st.Final_Evaluation__c = 'Passed';
					st.Evaluation_Date__c = system.today();
				}
				
				if( prevValue != st.Final_Evaluation__c ){
					st2Upd.add(st);
				}
			}
			
			if( st2Upd.isEmpty() == false ){
				update st2Upd;
                
                //Update the Seminar's Status to 'Evaluated'
                update new Seminar__c(Id = seminarId, Status__c = 'Evaluated' );
			}
			
		}catch(Exception e){
            Database.rollback(sp);
			return 'Error: ' + e.getMessage();
		}
		return '';
	}
    
    /*	 
	@Method Description: Mass_Printed button - when click on "Mass Printed" button in Seminar Teachers related list, the checkbox "Printed" will be checked for each selected record.
	@Date: 22/04/2018
	@Author: Avihai Shindelman
	*/
	static webservice string Mass_Printed(String ids, String seminarId ){
        boolean AtLeastOneNotPass = false;
        Savepoint sp = Database.setSavepoint();		
		try{			
			//Seminar__c s = [SELECT Teacher_Trainer__c FROM Seminar__c WHERE Id =: seminarId];
			//After asking Eden only herwe should let other users to access this method
            User currentUser = [SELECT Id, ContactId, Profile.Name, TT_Coordinator__c FROM User WHERE Id =: UserInfo.getUserId()];		
			//if(!( (currentUser.ContactId <> null && currentUser.ContactId == s.Teacher_Trainer__c) || currentUser.Profile.Name == 'System Administrator' || currentUser.TT_Coordinator__c == true)){currentUser.Profile.Name == 'HD AM' ||
			//return Label.Seminar_MassPassed_UsedBy_Teacher_Trainer;
			if(!(currentUser.Profile.Name == 'System Administrator' || currentUser.TT_Coordinator__c == true ||  currentUser.Profile.Name == 'HDC TT Admin')){
				return 'Sorry but only TT Coordinator and HDC TT Admin are allowed to use this button.';
			}
			if( String.isBlank(ids) ){
				return 'Please select at least one record of seminar teacher.';
			}			
			AtLeastOneNotPass = false;
			Set<Id> semTchIds = new Set<Id>();
			semTchIds.addAll((List<Id>)ids.split( ',' ));
			
			List<Seminar_Teachers__c> list_seminarTeachersToUpdate = new List<Seminar_Teachers__c>();
            List<String> list_seminarTeachersToEvalauateFirst = new List<String>();
			for( Seminar_Teachers__c st : [SELECT Id, Printed__c, Final_Evaluation__c,Name FROM Seminar_Teachers__c WHERE Seminar__c = :seminarId ] ){
				boolean prevValue = st.Printed__c;
				
				if( semTchIds.contains(st.Id)){
                    if (st.Final_Evaluation__c != null && st.Final_Evaluation__c == 'Passed'){
						st.Printed__c = true;
						st.When_Printed__c = system.now();
                    }
                    else{
                        list_seminarTeachersToEvalauateFirst.add(st.Name);
                    }
                    if (st.Final_Evaluation__c != 'Passed')//Flag for 'at least one' seminar teacher record is not pass - Present a message to user
                    	AtLeastOneNotPass = true;
				}
                
				if( prevValue != st.Printed__c ){
					list_seminarTeachersToUpdate.add(st);
				}
			}
			
			if(!list_seminarTeachersToUpdate.isEmpty()){
				update list_seminarTeachersToUpdate; 
                //Update the Seminar's Status to 'Printed'
                List<Seminar_Teachers__c> list_SeminarTeacherCount = [SELECT Id FROM Seminar_Teachers__c WHERE Seminar__c = :seminarId];
                List<Seminar_Teachers__c> list_SeminarTeacherPrintedCount = [SELECT Id FROM Seminar_Teachers__c WHERE Seminar__c = :seminarId AND Printed__c =: true];
                if (list_SeminarTeacherCount.size() == list_SeminarTeacherPrintedCount.size())
                	update new Seminar__c(Id = seminarId, Status__c = 'Printed');
			}
            else{
                if (!list_seminarTeachersToEvalauateFirst.isEmpty())
                	return 'Note: Only Teachers with Evaluation status ‘Passed’ can be marked as Printed.';
            }
			
		}catch(Exception e){
            Database.rollback(sp);
			return 'Error: ' + e.getMessage();
		}
        if (AtLeastOneNotPass)
            return 'Note: Only Teachers with Evaluation status ‘Passed’ can be marked as Printed.';
		return '';
	}
}