/******************************************************************************* 
Name              : LG_Student_TriggerHandlerTest
Description       : Contains the test methods of all triggers on LG Students object
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Nicolas                   03/07/2016              
*******************************************************************************/
@isTest
private class LG_Student_TriggerHandlerTest {
  
  /******************************************************************************* 
  Description       : Populate fields before duplicatecheck
            1) Update LG Number before insert and when edited
  Revision History  :-
  Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
  ----------------------------------------------------------------------------------------
  1. G. Fernandez         02/08/2016          Ella  Bernachik           [SW-17616]
  *******************************************************************************/
  
  @isTest(seeAllData=false)
    static void LGStudent_PopulateBefore_test(){

        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

        System.debug([SELECT LG_Number__c FROM LG_Student__c WHERE Id = :testEnv.studentId]);
    }
    
    
    @isTest(seeAllData=false)
    static void CreateGroupIncomePerMonth_test(){
      ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
      HD_TriggerSettings.disableTriggersFromTest.remove('recreateLGPayment2LGStudentBillingTypeChange');
    
      test.startTest();

        LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson(testEnv.lgId, testEnv.teacherContactId, testEnv.lgDHId);  
        lesson.Lesson_Status__c= 'Done';              
        insert lesson;
      
        LG_Student__c student = new LG_Student__c(Id = testEnv.studentId);
        student.Status_in_LG__c = 'Registered';
        student.Billing_Type__c= 'Course Price';
        update student;

        LG_Discount__c lgDisc = ObjectCreator.getNewLGDiscount(testEnv.studentId, testEnv.lgId);
        insert lgDisc;

        LG_Discount_TriggerHandler.lgDiscountStudentApproved.add(lgDisc);
        
        student.Student_Course_Start_Date__c = system.today().addDays(-1);
        update student;
        
      test.stopTest();
    }
    
    @isTest(seeAllData=false)
    static void DeleteGroupIncomePerMonth_test(){

      ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        
        Base_Course__c bc = new Base_Course__c(Id = testEnv.baseCurseId);
        bc.Fixed_Number_of_Students__c = false;
        update bc;
        
        test.startTest();

        LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson(testEnv.lgId, testEnv.teacherContactId, testEnv.lgDHId);  
        lesson.Lesson_Status__c= 'Done';              
        insert lesson;
           
        LG_Student__c student = new LG_Student__c(Id = testEnv.studentId);
        student.Status_in_LG__c = 'Registered';
        update student;
        
        student.Student_Course_End_Date__c = system.today().addDays(2);
        student.Status_in_LG__c = 'Moved';
        update student;
        
        test.stopTest();
    
    }
    
    @isTest(seeAllData=false)
    static void createLGPaymentToStudent_test(){

      ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

      LG__c lg = new LG__c(Id = testEnv.lgId);
      lg.Group_Status__c = 'Planned';
      lg.LG_Start_Date__c = System.today();
      lg.LG_End_Date__c = System.today().addDays(30);
      lg.Course_Price__c = 10;
      update lg;

      LG_Days_Hours__c lgDH = new LG_Days_Hours__c(Id = testEnv.lgDHId);
      lgDH.End_Hour__c = '19:30';       
      update lgDH;

      LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson(lg.Id, testEnv.teacherContactId, lgDH.Id);  
      lesson.Lesson_Status__c= 'Done';              
      insert lesson;
      
      Test.startTest();

      LG_Student__c lgS = new LG_Student__c(id = testEnv.studentId, Status_in_LG__c = 'Registered', Billing_Type__c = 'Course Price');
      update lgS;
      
      lg = new LG__c(Id = testEnv.lgId, Group_Status__c = 'Active');
      update lg;
      
      Contact studentContact  = ObjectCreator.getNewContact(testEnv.accId, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId());              
      insert studentContact;
      
      LG_Student__c studentLG = ObjectCreator.getNewLGStudent(studentContact.Id, testEnv.lgId);
      studentLG.Status_in_LG__c = 'Registered';
      studentLG.Billing_Type__c = 'Course Price';
      studentLG.Approved_Price__c = 100;
      studentLG.Number_of_Payments__c = 2;
      studentLG.Student_Start_Paying_Date__c = system.today();
      studentLG.Gap_Between_Payments__c = 2;
      studentLG.Approved_Price__c = 10;
      studentLG.Lesson_Type__c = 'Standard';
      studentLG.Billing_Type__c = 'Course Price';
      insert studentLG;
      
      Test.stopTest();
    }
}