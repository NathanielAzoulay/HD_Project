/******************************************************************************* 
Name              : Seminar_Teachers_TriggerHandlerTest
Description       : Contains the test methods of all triggers on Seminar Teacher object
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Nicolas                   03/07/2016              
*******************************************************************************/
@isTest
private class Seminar_Teachers_TriggerHandlerTest {

	/******************************************************************************* 
	Name              : SeminarTeacher_PopulateBefore
	Description       : Populate fields before duplicatecheck
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G.Fernandez             10/02/2016          Ella  Bernachik           [SW-17367]
	*******************************************************************************/
	@isTest(seeAllData=false)
    static void SeminarTeacher_PopulateBeforeTest(){

        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
		
		Seminar_Type__c seminarType = ObjectCreator.getNewSeminarType();
		insert seminarType;
		
        Seminar__c seminar = ObjectCreator.getNewSeminar();
        seminar.Seminar_Type__c = seminarType.Id;
        seminar.Hosting_Franchisee__c = testEnv.accId; 
        insert seminar;
        
        Seminar_Teachers__c st = ObjectCreator.getNewSeminarTeacher(seminar.Id, testEnv.teacherContactId);
        st.Teacher__c = testEnv.teacherContactId;
        insert st;
        
        // Added by Rashad 31/12/2017
        /*Contact ttcontact = ObjectCreator.getNewContact(testEnv.accId, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());
        ttcontact.TT_Qualified__c = 'TT';              
        insert ttcontact;
        User ttu = ObjectCreator.getNewUser(ttcontact.Id);
        insert ttu;
        ttcontact.Contact_Partner_User__c = ttu.id;
        Update ttcontact;
        
        seminar.Teacher_Trainer__c = ttcontact.Id; */
       
        Account acc1 = ObjectCreator.getNewAccount();
        insert acc1;
        test.startTest();
        seminar.Hosting_Franchisee__c = acc1.id;
        Update seminar; 
        test.stopTest();
        

    }




}