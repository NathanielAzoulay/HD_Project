/******************************************************************************* 
Name              : Seminar_Teachers_ButtonsTest
Description       : Contains the test methods of all custom buttons on Seminar Teacher object
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio                   06/06/2016              
*******************************************************************************/

@isTest 
public class Seminar_Teachers_ButtonsTest {
	
	/******************************************************************************* 
	Name              : Seminar_Teachers_Buttons
	Description       : On pressing "Register Teachers" button on the Seminar Teachers related list, updates the selected Seminar Teachers status in seminar
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Sergio             		06/06/2016          Ella  Bernachik           [SW-19806]
	*******************************************************************************/
	static testmethod void Register_Teachers_Test(){
		ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
		
		Seminar_Type__c seminarType = new Seminar_Type__c(Name = 'test ' + String.valueOf(Math.random()) );
    	seminarType.Active__c = true;
	    seminarType.Program_Type__c = 'HDE';
		insert seminarType;
		
		Account acc1 = ObjectCreator.getNewAccount();
	    insert acc1;
	    
	    Contact teacher1 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert new List<Contact>{teacher1};
        test.startTest();
        Seminar__c seminar = ObjectCreator.getNewSeminar();
        seminar.Seminar_Type__c = seminarType.Id;
        seminar.Hosting_Franchisee__c = acc1.Id;
        insert seminar;

        Seminar_Teachers__c st = ObjectCreator.getNewSeminarTeacher(seminar.Id, testEnv.teacherContactId);
        st.Teacher__c = teacher1.Id;
        insert st;
        
        Seminar_Teachers_Buttons.Register_Teachers('');
        Seminar_Teachers_Buttons.Register_Teachers(String.valueOf(st.Id));
        test.stopTest();
	}
	
	/******************************************************************************* 
	Name              : Mass_Passed
	Description       : On pressing "Mass Passed" button on the Seminar Teachers related list, updates Teachers final evaluation based on if they were selected or not
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Sergio             		06/07/2016          Ella  Bernachik           [SW-20282]
	*******************************************************************************/
	static testmethod void Mass_Passed_Test(){
		ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

        Seminar_Type__c seminarType = new Seminar_Type__c(Name = 'test ' + String.valueOf(Math.random()) );
    	seminarType.Active__c = true;
	    seminarType.Program_Type__c = 'HDE';
		insert seminarType;
		
		Account acc1 = ObjectCreator.getNewAccount();
	    insert acc1;
	    
	    Contact teacher1 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert new List<Contact>{teacher1};
        
        Seminar__c seminar = ObjectCreator.getNewSeminar();
        seminar.Seminar_Type__c = seminarType.Id;
        seminar.Hosting_Franchisee__c = acc1.Id;
        insert seminar;

		Test.startTest();	
        Seminar_Teachers__c st = ObjectCreator.getNewSeminarTeacher(seminar.Id, testEnv.teacherContactId);
        st.Teacher__c = teacher1.Id;
        insert st;
  		      
        Seminar_Teachers_Buttons.Mass_Passed('', '');
        Seminar_Teachers_Buttons.Mass_Passed('' , String.valueOf( seminar.Id ) );
        
        Seminar_Teachers_Buttons.Mass_Passed(String.valueOf(st.Id) , String.valueOf( seminar.Id ) );
        
        seminarType.Type__c = 'Mass Training';
        update seminarType;
        
        Seminar_Teachers_Buttons.Mass_Passed(String.valueOf(st.Id) , String.valueOf( seminar.Id ) );
        
        //User us = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        Test.stopTest();
	}
    /*
     *@Description: Test method for new button "Mass Printed"
	  @Date: 23/04/2018
	  @Done by Avihai Shindelman
*/
    static testmethod void Mass_Printed_Test(){
		ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

        Seminar_Type__c seminarType = new Seminar_Type__c(Name = 'test ' + String.valueOf(Math.random()) );
    	seminarType.Active__c = true;
	    seminarType.Program_Type__c = 'HDE';
		insert seminarType;
		
		Account acc1 = ObjectCreator.getNewAccount();
	    insert acc1;
	    
	    Contact teacher1 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert new List<Contact>{teacher1};
        
        Seminar__c seminar = ObjectCreator.getNewSeminar();
        seminar.Seminar_Type__c = seminarType.Id;
        seminar.Hosting_Franchisee__c = acc1.Id;
        insert seminar;

		Test.startTest();	
        Seminar_Teachers__c st = ObjectCreator.getNewSeminarTeacher(seminar.Id, testEnv.teacherContactId);
        st.Teacher__c = teacher1.Id;
        insert st;
  		      
        Seminar_Teachers_Buttons.Mass_Printed('', '');
        Seminar_Teachers_Buttons.Mass_Printed('' , String.valueOf( seminar.Id ) );
        
        Seminar_Teachers_Buttons.Mass_Printed(String.valueOf(st.Id) , String.valueOf( seminar.Id ) );
        
        update seminarType;
        
        Seminar_Teachers_Buttons.Mass_Printed(String.valueOf(st.Id) , String.valueOf( seminar.Id ) );
        
        User us = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        Test.stopTest();
	}
}