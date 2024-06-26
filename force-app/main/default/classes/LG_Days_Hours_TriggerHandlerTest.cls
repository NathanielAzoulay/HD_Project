/******************************************************************************* 
Name              : LG_Days_Hours_TriggerHandlerTest
Description       : Contains the test methods of all triggers on LG_Days_Hours__c
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio         	11/03/2016          	
*******************************************************************************/
@isTest 
private class LG_Days_Hours_TriggerHandlerTest {
    
    @isTest(seeAllData=false) 
    static void MaxLessonsForADayOnBefore_Test(){

        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

        LG_Days_Hours__c lgDH1 = ObjectCreator.getNewLG_Days_Hours(testEnv.lgId);
        lgDH1.Day__c = 'Sun';
        LG_Days_Hours__c lgDH2 = ObjectCreator.getNewLG_Days_Hours(testEnv.lgId);               
        lgDH2.Day__c = 'Sun';
        insert new List<LG_Days_Hours__c>{lgDH1, lgDH2};

        LG_Days_Hours__c lgDH3 = ObjectCreator.getNewLG_Days_Hours(testEnv.lgId);
        lgDH3.Day__c = 'Sun';
        try{
        	insert lgDH3;
        	//Shouldn't reach this line
        	system.assertEquals( false, true);
        }catch(Exception e){
        }
        
        lgDH3.Day__c = 'Mon';
        insert lgDH3;
        
        try{
        	lgDH3.Day__c = 'Sun';
        	update lgDH3;
        	//Shouldn't reach this line
        	system.assertEquals( false, true);
        }catch(Exception e){
        	
        }
    }

    @isTest(seeAllData=false) 
    static void changeTeacherLessons_Test(){

        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

        LG_Days_Hours__c lgDH = ObjectCreator.getNewLG_Days_Hours(testEnv.lgId);               
        insert lgDH;

        LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson(testEnv.lgId, testEnv.teacherContactId, lgDH.Id);                        
        insert lesson;

        Contact teacher2 = ObjectCreator.getNewContact(testEnv.accId, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        teacher2.LastName = 'Teacher 2';
        insert teacher2;

        lgDH.Teacher__c = teacher2.Id;
        update lgDh;

        System.assert([SELECT Lesson_Teacher__c FROM LG_Lesson__c WHERE Id = :lesson.Id].Lesson_Teacher__c == teacher2.Id);
    }
    
}