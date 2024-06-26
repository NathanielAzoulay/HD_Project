/**************************************************************************************** 
Name : LGCreateLessonWithoutBatch_test
Description : Test the Apex Class LGCreateLessonWithoutBatch 
Create LG Leassons and its related objects on sync mode.
Revision History :-
Created/Modified by Created/Modified Date Requested by Related Task/Issue 
----------------------------------------------------------------------------------------
1. Avihai Shindelman 03/07/2018 Avihai SHindelman Task-000001699
---------------------------------------------------------------------------------------- 
****************************************************************************************/
@isTest
private with sharing class LGCreateLessonWithoutBatch_test {
    
    @isTest(seeAllData=false) 
    static void createLGLessonWOBatch_test(){ 
        
        ObjectCreator.DisableSharingMethods();
        //HD_TriggerSettings.disableTriggersFromTest.remove('createLGPaymentToLG'); 
        Account acc = ObjectCreator.getNewAccount();
        acc.DBAmp_Stop_Migration_MF__c = 'Yes';
        acc.Account_Type__c = 'MF';
        insert acc;
        
        Contact con = new Contact(FirstName = 'TestAvihai',LastName = 'Test01', AccountId = acc.Id);
        insert con;
        
        Agreement__c agreement = ObjectCreator.getNewAgreement(acc.Id);
        insert agreement;
        
        Base_Course__c bc = ObjectCreator.getNewBaseCourse();
        bc.Fixed_Number_of_Students__c = true;
        bc.Holiday_Course__c = false;
        insert bc;
        
        Course_Sub_Type__c cSubType = ObjectCreator.getNewCourseSubType(acc.Id, bc.Id); 
        insert cSubType;
        
        LG__c lg = new LG__c();
        lg.Agreement__c = agreement.Id;
        lg.Course_Sub_Type__c = cSubType.Id;
        lg.Group_Status__c = 'Active';
        //lg.Parent_Franchisee__c = acc.Id;
        lg.Declared_Number_of_Students__c = 1;
        lg.LG_Start_Date__c = system.today();
        lg.LG_End_Date__c = system.today().addMonths(5);
        lg.Teacher_Permission_on_LG__c = 'Read – Can view LG details as read only';
        insert new List<LG__c>{lg};
            lg.Group_Status__c = 'Completed';
        update lg; 
        
        LG__c lg1 = new LG__c();
        lg1.Agreement__c = agreement.Id;
        lg1.Course_Sub_Type__c = cSubType.Id;
        lg1.Group_Status__c = 'Active';
        lg1.Parent_Franchisee__c = acc.Id;
        lg1.Declared_Number_of_Students__c = 1;
        lg1.LG_Start_Date__c = system.today();
        lg1.LG_End_Date__c = system.today().addMonths(5);
        lg1.Teacher_Permission_on_LG__c = 'Read – Can view LG details as read only';
        
        List<LG__c> lg_list = new List<LG__c>(); 
        lg_list.add(lg1); 
        
        LG__c lg2 = ObjectCreator.getNewLG(acc.Id, cSubType.Id, agreement.Id);
        lg_list.add(lg2); 
        insert lg_list;
        
        LG_Days_Hours__c lgDH = ObjectCreator.getNewLG_Days_Hours(lg.Id);
        insert lgDH;
        LG_Days_Hours__c lgDH1 = ObjectCreator.getNewLG_Days_Hours(lg1.Id);
        lgDH1.Day__c = 'Tue';
        lgDH1.Start_Hour__c = '08:00'; 
        insert lgDH1;
        LG_Days_Hours__c lgDH2 = ObjectCreator.getNewLG_Days_Hours(lg2.Id);
        lgDH2.Day__c = 'Fri';
        lgDH2.Start_Hour__c = '08:00';
        insert lgDH2;
        
        Contact studentContact = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId()); 
        insert studentContact;
        
        LG_Student__c student = ObjectCreator.getNewLGStudent(studentContact.Id, lg.Id);
        student.Approved_Price__c = 22;
        student.Lesson_Type__c = 'Standard';
        student.Status_in_LG__c = 'Completed';
        student.Student_Start_Paying_Date__c = System.today();
        student.Student_Course_Start_Date__c = system.today();
        student.Student_Course_End_Date__c = system.today().addDays(2);
        
        //insert student;
        List<LG_Student__c> lgs_list = new List<LG_Student__c>();
        lgs_list.add(student);
        insert lgs_list;
        
        lg.Group_Status__c = 'Active';
        lg.LG_End_Date__c = system.today().addMonths(6);
        lg.Teacher_Permission_on_LG__c = 'No Permissions – can’t view LG details';
        update lg;
        
        cSubType.Course_Price__c = 1;
        cSubType.Gap_between_Payments__c = 1;
        cSubType.Number_of_Payments__c = 1;
        update cSubType;
        
        lg.Billing_Type__c = 'Course Price';
        lg.Course_Price__c = 41;
        lg.Gap_between_Price_Payments__c = 1;
        update lg; 
        
        Contact teacherContact = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId()); 
        teacherContact.Program_Type__c = 'HDE';
        teacherContact.DBAmp_Date__c = Date.today();
        insert teacherContact;
        
        LG_Lesson__c lg_lesson = ObjectCreator.getNewLG_Lesson(lg.Id, studentContact.Id, lgDH.Id);
        lg_lesson.Lesson_Teacher__c = teacherContact.Id;
        lg_lesson.Lesson_Status__c = 'Day Off';
        lg_lesson.Lesson_Date_Hour__c = system.now();
        lg_lesson.Lesson_Date_Time__c = 'test';
        
        LG_Lesson__c lg_lesson2 = ObjectCreator.getNewLG_Lesson(lg1.Id, studentContact.Id, lgDH.Id);
        lg_lesson2.Lesson_Teacher__c = teacherContact.Id; 
        lg_lesson2.Rollback_Key__c = 1;
        lg_lesson2.Lesson_Status__c = 'Done';
        lg_lesson2.Lesson_Date_Hour__c = system.now().addDays(2);
        lg_lesson.Lesson_Date_Time__c = 'test2';
        
        List<LG_Lesson__c> lg_lesson_list = new List<LG_Lesson__c>();
        lg_lesson_list.add(lg_lesson);
        lg_lesson_list.add(lg_lesson2);
        bc.Holiday_Course__c = true;
        update bc;
        insert lg_lesson_list; 
        
        List<LG_Student_Attendance__c> LGSA_list = new List<LG_Student_Attendance__c>();
        LG_Student_Attendance__c lgs_att1 = ObjectCreator.getNewStudentAttendance(lg_lesson.Id, student.Id);
        lgs_att1.Rollback_Key__c = 1;
        LG_Student_Attendance__c lgs_att2 = ObjectCreator.getNewStudentAttendance(lg_lesson2.Id, student.Id);
        LGSA_list.add(lgs_att1);
        LGSA_list.add(lgs_att2);
        insert LGSA_list;
        
        Database.BatchableContext batch_con;
        test.startTest(); 
        LGCreateLessonBatch create_lg_lesson_batch = new LGCreateLessonBatch();
        create_lg_lesson_batch.selectedDate = Date.today();
        //create_lg_lesson_batch.doInsert = false;
        create_lg_lesson_batch.records2process = lg_lesson_list;
        create_lg_lesson_batch.lgStudents = lgs_list;
        create_lg_lesson_batch.doInsert = true;
        create_lg_lesson_batch.processName = 'Batch - Update LG Days & Hour';
        create_lg_lesson_batch.rollback_key = 1;
        Database.executeBatch(create_lg_lesson_batch);
        //create_lg_lesson_batch.execute(batch_con, lg_lesson_list);
        LGCreateLessonBatch.theLessonWasCreatedDueToChangeLGEndDate = false;
        
        LGCreateLessonBatch.createStudentsAttAndLGPayments(lg_lesson_list, lgs_list, null , null, MonitorRecursionClass.GetProcessKey(), false);
        LGCreateLessonBatch.theLessonWasCreatedDueToChangeLGEndDate = true;
        LG_Payment__c lgp = ObjectCreator.getNewLGPayment (lg.Id, student.Id, studentContact.Id);
        lgp.Rollback_Key__c = 1;
        insert lgp;
        
        //Shivram 1 Aug 2018
        LGCreateLessonWithoutBatch wBatchObj = new LGCreateLessonWithoutBatch();
        wBatchObj.records2process = lg_lesson_list;
        wBatchObj.doInsert = false;
        wBatchObj.selectedDate = System.today();
        wBatchObj.lgStudents = lgs_list;
        wBatchObj.doSyncTask(lg_lesson_list);
        
        wBatchObj.doInsert = true;
        wBatchObj.doSyncTask(lg_lesson_list);
        
        wBatchObj.doInsert = true;
        wBatchObj.rollback_key = 1;//Avihai 1/8/2018
        wBatchObj.doSyncTask(lg_lesson_list);
        
        //create_lg_lesson_batch.execute(batch_con, lg_lesson_list);
        // Database.executeBatch(create_lg_lesson_batch);
        //create_lg_lesson_batch.start(batch_con); 
        
        /*
LGCreateLessonWithoutBatch create_lg_lesson = new LGCreateLessonWithoutBatch();
create_lg_lesson.lgStudents = lgs_list;
Database.executeBatch(create_lg_lesson);*/
        test.stopTest();
    }
}