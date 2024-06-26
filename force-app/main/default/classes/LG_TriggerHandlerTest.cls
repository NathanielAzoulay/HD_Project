/******************************************************************************* 
Name              : 
Description       : Contains the test methods of all triggers on LG object
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan Sinclair            03/08/2016              
*******************************************************************************/
@isTest
private class LG_TriggerHandlerTest {
    
    @isTest(seeAllData=false) 
    static void createLGPaymentToLG_test(){
        
        ObjectCreator.DisableSharingMethods();
        HD_TriggerSettings.disableTriggersFromTest.remove('createLGPaymentToLG');
        
        Account acc = ObjectCreator.getNewAccount();
        insert acc;
        //Remove comment out by Avihai Task-000001930
        Contact con = new Contact(FirstName = 'TestAvihai',LastName = 'Test01', AccountId = acc.Id);
        insert con;
        
        Agreement__c agreement = ObjectCreator.getNewAgreement( acc.Id);
        insert agreement;
        
        Base_Course__c bc = ObjectCreator.getNewBaseCourse();
        bc.Fixed_Number_of_Students__c = true;
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
        
        test.startTest();        
        
        LG_Days_Hours__c lgDH = ObjectCreator.getNewLG_Days_Hours(lg.Id);
        insert lgDH;
        
        Contact studentContact  = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId());              
        insert studentContact;
        
        LG_Student__c student = ObjectCreator.getNewLGStudent(studentContact.Id, lg.Id);
        student.Approved_Price__c = 22;
        student.Lesson_Type__c = 'Standard';
        student.Status_in_LG__c = 'Completed';
        student.Student_Start_Paying_Date__c = System.today();
        insert student;
        
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
        
        test.stopTest();
        
    }
    
    @isTest(seeAllData=false) 
    static void CreateGroupIncomePerMonth_test(){
        ObjectCreator.DisableSharingMethods();
        
        Account acc = ObjectCreator.getNewAccount();
        insert acc;
        
        //Contact con = new Contact(LastName = 'Test01', AccountId = acc.Id);
        //insert con;
        
        Agreement__c agreement = ObjectCreator.getNewAgreement( acc.Id);
        insert agreement;
        
        Base_Course__c bc = ObjectCreator.getNewBaseCourse();
        bc.Fixed_Number_of_Students__c = true;
        insert bc;
        
        Course_Sub_Type__c cSubType = ObjectCreator.getNewCourseSubType(acc.Id, bc.Id); 
        insert cSubType;
        
        test.startTest();
        
        LG__c lg = new LG__c();
        lg.Agreement__c = agreement.Id;
        lg.Course_Sub_Type__c = cSubType.Id;
        lg.Group_Status__c = 'Active';
        //lg.Parent_Franchisee__c = acc.Id;
        lg.Declared_Number_of_Students__c = 1;
        lg.LG_Start_Date__c = system.today();
        lg.LG_End_Date__c = system.today().addMonths(5);
        insert new List<LG__c>{lg};
            
            lg.Group_Status__c = 'Completed';
        update lg;
        
        
        LG_Days_Hours__c lgDH = ObjectCreator.getNewLG_Days_Hours(lg.Id);
        insert lgDH;
        
        Contact studentContact  = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId());              
        insert studentContact;
        
        LG_Student__c student = ObjectCreator.getNewLGStudent(studentContact.Id, lg.Id);
        student.Approved_Price__c = 22;
        student.Lesson_Type__c = 'Standard';
        student.Status_in_LG__c = 'Completed';
        student.Student_Start_Paying_Date__c = System.today();
        insert student;
        
        LG_TriggerHandler.lgsNotToRun.clear();
        
        lg.Group_Status__c = 'Active';
        lg.RecordTypeId = Schema.SObjectType.LG__c.getRecordTypeInfosByName().get('HD LG').getRecordTypeId();
        lg.LG_End_Date__c = system.today().addMonths(6);
        update lg;
        
        student.Status_in_LG__c = 'Registered';
        update student;
        
        lg.LG_End_Date__c = system.today().addMonths(10);
        update lg;
        
        lg.LG_End_Date__c = system.today().addMonths(1);
        update lg;
        test.stopTest();
    }
    
    @isTest(seeAllData=false) 
    static void maintenaceLGLesson_test(){
        
        test.startTest();
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        
        LG__c lg = new LG__c(Id = testEnv.lgId);
        lg.Group_Status__c = 'Planned';
        lg.Billing_Type__c = 'Course Price';
        lg.LG_Start_Date__c = System.today();
        lg.LG_End_Date__c = System.today().addDays(17);
        lg.LG_Lessons__c = 2;
        update lg;
        
        LG_Days_Hours__c lgDH = new LG_Days_Hours__c(Id = testEnv.lgDHId);
        lgDH.End_Hour__c = '19:30';             
        update lgDH;
        
        LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson(lg.Id, testEnv.teacherContactId, lgDH.Id);                      
        insert lesson;
        
        LG_Payment__c payment = ObjectCreator.getNewLGPayment(testEnv.lgId, testEnv.studentId, testEnv.studentContactId);
        //insert payment;
        
        LG_Student_Attendance__c studentAtt = ObjectCreator.getNewStudentAttendance(lesson.Id, testEnv.studentId);
        studentAtt.LG_Payment__c = payment.Id;
        insert studentAtt;
        
        LG_Lesson_TriggerHandler.lgLessonsThatNeedReCalculationLGPayments.add(lesson.Id);
        update lesson;
        
        test.stopTest();
        
        lg.Group_Status__c = 'Active';
        lg.LG_End_Date__c = system.today().addDays(16);
        update lg;
        
        HD_TriggerSettings.disableTriggersFromTest.add('createLGPaymentToLG');
        
        lg.LG_End_Date__c = system.today().addDays(18);
        update lg;
        
        lg.Create_LG_Lessons_By__c = 'Number of Lessons';
        lg.LG_Lessons__c = 1;
        
        update lg;
        
        lg.LG_Lessons__c = [SELECT Id, Recommended_Lessons__c FROM LG__c WHERE Id = :lg.Id LIMIT 1][0].Recommended_Lessons__c;
        update lg;
        
        lg.Create_LG_Lessons_By__c = 'LG End Date';
        lg.Group_Status__c = 'Cancelled';
        lg.Cancellation_Date__c = system.today();
        lg.Cancel_Reason__c = 'Test';
        update lg;
    }
    
    @isTest(seeAllData=false) 
    static void DeleteGroupIncomePerMonth_test(){
        Account acc = ObjectCreator.getNewAccount();
        insert acc;
        
        //Contact con = new Contact(LastName = 'Test01', AccountId = acc.Id);
        //insert con;
        
        Agreement__c agreement = ObjectCreator.getNewAgreement( acc.Id);
        insert agreement;
        
        Base_Course__c bc = ObjectCreator.getNewBaseCourse();
        bc.Fixed_Number_of_Students__c = true;
        insert bc;
        
        Course_Sub_Type__c cSubType = ObjectCreator.getNewCourseSubType(acc.Id, bc.Id); 
        insert cSubType;
        
        LG__c lg = new LG__c();
        lg.Agreement__c = agreement.Id;
        lg.Course_Sub_Type__c = cSubType.Id;
        lg.Group_Status__c = 'Active';
        //lg.Parent_Franchisee__c = acc.Id;
        lg.DBAmp_Date__c = system.today();
        lg.Declared_Number_of_Students__c = 1;
        lg.LG_Start_Date__c = system.today();
        lg.Course_Price__c = 2000;
        lg.LG_End_Date__c = system.today().addMonths(5);
        insert new List<LG__c>{lg};
        
        LG_Days_Hours__c lgDH = ObjectCreator.getNewLG_Days_Hours(lg.Id);
        insert lgDH;
        
        Contact studentContact  = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId());              
        insert studentContact;
        
        LG_Student__c student = ObjectCreator.getNewLGStudent(studentContact.Id, lg.Id);
        student.Approved_Price__c = 22;
        student.Lesson_Type__c = 'Standard';
        student.Status_in_LG__c = 'Registered';
        student.Billing_Type__c = 'Course Price';
        student.Student_Start_Paying_Date__c = System.today();
        student.Student_Course_End_Date__c = system.today().addMonths(5);
        insert student;   
           
            lg.LG_End_Date__c = system.today().addMonths(2);
        lg.Group_Status__c = 'Cancelled';
        lg.Cancel_Reason__c = 'Test';
        lg.Cancellation_Date__c = system.today();
        try{
            update lg;
            
            student.Student_Course_End_Date__c = system.today().addMonths(2);
        	update student; 
            
            lg.LG_End_Date__c = system.today().addYears(1);
            update lg;
        }catch(Exception ex){           
        }
    }
    
    @isTest(seeAllData=false) 
    static void DeleteGroupIncomePerMonth_2_test(){
        Account acc = ObjectCreator.getNewAccount();
        insert acc;
        
        //Contact con = new Contact(LastName = 'Test01', AccountId = acc.Id);
        //insert con;
        
        Agreement__c agreement = ObjectCreator.getNewAgreement( acc.Id);
        insert agreement;
        
        Base_Course__c bc = ObjectCreator.getNewBaseCourse();
        bc.Fixed_Number_of_Students__c = true;
        insert bc;
        
        Course_Sub_Type__c cSubType = ObjectCreator.getNewCourseSubType(acc.Id, bc.Id); 
        insert cSubType;
        
        LG__c lg = new LG__c();
        lg.Agreement__c = agreement.Id;
        lg.Course_Sub_Type__c = cSubType.Id;
        lg.Group_Status__c = 'Active';
        //lg.Parent_Franchisee__c = acc.Id;
        lg.DBAmp_Date__c = system.today();
        lg.Declared_Number_of_Students__c = 1;
        lg.Create_LG_Lessons_By__c = 'LG End Date';
        lg.LG_Lessons__c = 10;
        lg.LG_Start_Date__c = system.today();
        lg.Course_Price__c = 2000;
        lg.LG_End_Date__c = system.today().addMonths(5);
        insert new List<LG__c>{lg};
        
        LG_Days_Hours__c lgDH = ObjectCreator.getNewLG_Days_Hours(lg.Id);
        lgDH.End_Hour__c = '07:45';
        insert lgDH;
        
        Contact studentContact  = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId());              
        insert studentContact;
        
        Contact teacherContact  = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact;
        
        LG_Lesson__c lesson = new LG_Lesson__c();
        lesson.LG__c = lg.Id;
        lesson.Lesson_Teacher__c = teacherContact.Id;
        lesson.Lesson_Date_Hour__c = System.today().addDays(1);
        insert lesson;
        
        LG_Student__c student = ObjectCreator.getNewLGStudent(studentContact.Id, lg.Id);
        student.Approved_Price__c = 22;
        student.Lesson_Type__c = 'Standard';
        student.Status_in_LG__c = 'Registered';
        student.Billing_Type__c = 'Course Price';
        student.Student_Start_Paying_Date__c = System.today();
        student.Student_Course_End_Date__c = system.today().addMonths(5);
        insert student;   
           
            lg.LG_End_Date__c = system.today().addMonths(2);
        lg.Group_Status__c = 'Cancelled';
        lg.Cancel_Reason__c = 'Test';
        lg.Cancellation_Date__c = system.today();
        try{
            Test.startTest();
            update lg;
            
            student.Student_Course_End_Date__c = system.today().addMonths(2);
        	update student; 
            
            LG_Lesson__c lesson2 = new LG_Lesson__c();
            lesson2.LG__c = lg.Id;
            lesson2.Lesson_Teacher__c = teacherContact.Id;
            lesson2.Lesson_Date_Hour__c = System.today().addDays(1);
            insert lesson2;
            
            lg.LG_End_Date__c = system.today().addYears(1);
            update lg;
            
            LG_Lesson__c lesson1 = new LG_Lesson__c();
            lesson1.LG__c = lg.Id;
            lesson1.Lesson_Teacher__c = teacherContact.Id;
            lesson1.Lesson_Date_Hour__c = System.today().addDays(1);
            insert lesson1;
            
            LG__c lg1 = new LG__c();
            lg1.Agreement__c = agreement.Id;
            lg1.Course_Sub_Type__c = cSubType.Id;
            lg1.Group_Status__c = 'Active';
            //lg.Parent_Franchisee__c = acc.Id;
            lg1.DBAmp_Date__c = system.today();
            lg1.Declared_Number_of_Students__c = 1;
            lg1.Create_LG_Lessons_By__c = 'LG End Date';
            lg1.LG_Lessons__c = 10;
            lg1.LG_Start_Date__c = system.today();
            lg1.Course_Price__c = 2000;
            lg1.LG_End_Date__c = system.today().addMonths(5);
            insert new List<LG__c>{lg1};
            
            lg1.Create_LG_Lessons_By__c = 'Number of Lessons';
        	lg1.LG_Lessons__c = 5;
            update lg;
            
            LG_Lesson__c lesson3 = new LG_Lesson__c();
            lesson3.LG__c = lg1.Id;
            lesson3.Lesson_Teacher__c = teacherContact.Id;
            lesson3.Lesson_Date_Hour__c = System.today().addDays(1);
            insert lesson3;
            
            LG__c lg2 = new LG__c();
            lg2.Agreement__c = agreement.Id;
            lg2.Course_Sub_Type__c = cSubType.Id;
            lg2.Group_Status__c = 'Active';
            //lg.Parent_Franchisee__c = acc.Id;
            lg2.DBAmp_Date__c = system.today();
            lg2.Declared_Number_of_Students__c = 1;
            lg2.Create_LG_Lessons_By__c = 'LG End Date';
            lg2.LG_Lessons__c = 10;
            lg2.LG_Start_Date__c = system.today();
            lg2.Course_Price__c = 2000;
            lg2.LG_End_Date__c = system.today().addMonths(5);
            insert new List<LG__c>{lg2};
            
            lg2.Create_LG_Lessons_By__c = 'Number of Lessons';
        	lg2.LG_Lessons__c = 50;
            update lg2;
            
            Test.stopTest();
        }catch(Exception ex){           
        }
    }
    
    @isTest(seeAllData=false) 
    static void DeleteGroupIncomePerMonth_3_test(){
        Account acc = ObjectCreator.getNewAccount();
        insert acc;
        
        //Contact con = new Contact(LastName = 'Test01', AccountId = acc.Id);
        //insert con;
        
        Agreement__c agreement = ObjectCreator.getNewAgreement( acc.Id);
        insert agreement;
        
        Base_Course__c bc = ObjectCreator.getNewBaseCourse();
        bc.Fixed_Number_of_Students__c = true;
        insert bc;
        
        Course_Sub_Type__c cSubType = ObjectCreator.getNewCourseSubType(acc.Id, bc.Id); 
        insert cSubType;
        
        LG__c lg = new LG__c();
        lg.Agreement__c = agreement.Id;
        lg.Course_Sub_Type__c = cSubType.Id;
        lg.Group_Status__c = 'Active';
        //lg.Parent_Franchisee__c = acc.Id;
        lg.DBAmp_Date__c = system.today();
        lg.Declared_Number_of_Students__c = 1;
        lg.Create_LG_Lessons_By__c = 'Number of Lessons';
        lg.LG_Lessons__c = 10;
        lg.LG_Start_Date__c = system.today();
        lg.Course_Price__c = 2000;
        lg.LG_End_Date__c = system.today().addMonths(5);
        insert new List<LG__c>{lg};
        
        LG_Days_Hours__c lgDH = ObjectCreator.getNewLG_Days_Hours(lg.Id);
        lgDH.End_Hour__c = '07:45';
        insert lgDH;
        
        
        Contact teacherContact  = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact;
        
        LG_Lesson__c lesson = new LG_Lesson__c();
        lesson.LG__c = lg.Id;
        lesson.Lesson_Teacher__c = teacherContact.Id;
        lesson.Lesson_Date_Hour__c = System.today().addDays(1);
        insert lesson;  
        
        try{
            Test.startTest();
            lg.Create_LG_Lessons_By__c = 'Number of Lessons';
            lg.LG_Lessons__c = 5;
            update lg;
            
            Test.stopTest();
        }catch(Exception ex){           
        }
    }
    
    @isTest(seeAllData=false) 
    static void DeleteGroupIncomePerMonth_4_test(){
        Account acc = ObjectCreator.getNewAccount();
        insert acc;
        
        //Contact con = new Contact(LastName = 'Test01', AccountId = acc.Id);
        //insert con;
        
        Agreement__c agreement = ObjectCreator.getNewAgreement( acc.Id);
        insert agreement;
        
        Base_Course__c bc = ObjectCreator.getNewBaseCourse();
        bc.Fixed_Number_of_Students__c = true;
        insert bc;
        
        Course_Sub_Type__c cSubType = ObjectCreator.getNewCourseSubType(acc.Id, bc.Id); 
        insert cSubType;
        
        LG__c lg = new LG__c();
        lg.Agreement__c = agreement.Id;
        lg.Course_Sub_Type__c = cSubType.Id;
        lg.Group_Status__c = 'Active';
        //lg.Parent_Franchisee__c = acc.Id;
        lg.DBAmp_Date__c = system.today();
        lg.Declared_Number_of_Students__c = 1;
        lg.Create_LG_Lessons_By__c = 'Number of Lessons';
        lg.LG_Lessons__c = 10;
        lg.LG_Start_Date__c = system.today();
        lg.Course_Price__c = 2000;
        lg.LG_End_Date__c = system.today().addMonths(5);
        insert new List<LG__c>{lg};
        
        LG_Days_Hours__c lgDH = ObjectCreator.getNewLG_Days_Hours(lg.Id);
        lgDH.End_Hour__c = '07:45';
        insert lgDH;
        
        
        Contact teacherContact  = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact;
        
        LG_Lesson__c lesson = new LG_Lesson__c();
        lesson.LG__c = lg.Id;
        lesson.Lesson_Teacher__c = teacherContact.Id;
        lesson.Lesson_Date_Hour__c = System.today().addDays(1);
        insert lesson;  
        
        try{
            Test.startTest();
            lg.Create_LG_Lessons_By__c = 'Number of Lessons';
            lg.LG_Lessons__c = 50;
            update lg;
            
            Test.stopTest();
        }catch(Exception ex){           
        }
    }
    
    @isTest(seeAllData=false) 
    static void checkTeacherQualifications_Test(){
        Account acc = ObjectCreator.getNewAccount();
        insert acc;
        
        Contact teacher1 = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        Contact teacher2 = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());
        Contact teacher3 = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());
        insert new List<Contact>{teacher1,teacher2};
            
            Agreement__c agreement = ObjectCreator.getNewAgreement( acc.Id);
        insert agreement;
        
        Base_Course__c bc = ObjectCreator.getNewBaseCourse();
        insert bc;
        
        Teacher_Qualification__c teacherQ = ObjectCreator.getNewTeacherQualification(teacher1.Id,bc.Id);
        insert teacherQ;
        
        Course_Sub_Type__c cSubType = ObjectCreator.getNewCourseSubType(acc.Id, bc.Id); 
        insert cSubType;
        
        LG__c lg1 = ObjectCreator.getNewLG( acc.Id, cSubType.Id, agreement.Id );
        lg1.LG_Start_Date__c = system.today();
        lg1.LG_End_Date__c = system.today().addMonths(5);
        lg1.Teacher__c = teacher1.Id;
        lg1.Group_Status__c = 'Active';        
        
        insert lg1;
        
        LG__c lg2 = ObjectCreator.getNewLG( acc.Id, cSubType.Id, agreement.Id );
        lg2.LG_Start_Date__c = system.today();
        lg2.LG_End_Date__c = system.today().addMonths(5);
        lg2.Teacher__c = teacher2.Id;
        lg2.Group_Status__c = 'Active';
        insert lg2;
        
        lg2.Teacher__c = teacher3.Id;
        update lg2;
        
        lg1 = [SELECT Teacher_is_not_Qualified_for_Base_Course__c FROM LG__c WHERE Id = :lg1.Id];
        
        System.assert(lg1.Teacher_is_not_Qualified_for_Base_Course__c == false);
        
        lg2 = [SELECT Teacher_is_not_Qualified_for_Base_Course__c FROM LG__c WHERE Id = :lg2.Id];
        
        
        System.assert(lg2.Teacher_is_not_Qualified_for_Base_Course__c == true);
        
        
    }
    
    @isTest(seeAllData=false)
    static void maintenaceLGStudents_test(){
        
        //HD_TriggerSettings.disableAllTriggers = true;
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        
        LG__c lg = new LG__c(Id = testEnv.lgId);
        lg.LG_End_Date__c = System.today().addMonths(8);
        lg.Teacher_Permission_on_LG__c = 'Read – Can view LG details as read only';
        update lg;
        
        
        
        Test.startTest();
        
        LG_Student__c student = new LG_Student__c(Id = testEnv.studentId);
        student.Status_in_LG__c = 'Registered';
        student.Student_Course_End_Date__c = lg.LG_End_Date__c;
        update student;
        
        lg.LG_End_Date__c = System.today().addMonths(6);
        update lg;
        
        lg.LG_End_Date__c = lg.LG_End_Date__c.addMonths(8);
        update lg;
   
        //System.assert([SELECT Student_Course_End_Date__c FROM LG_Student__c WHERE Id =: lg.Id AND Status_in_LG__c = 'Registered'].Student_Course_End_Date__c == lg.LG_End_Date__c);
        
        lg.LG_End_Date__c = lg.LG_End_Date__c.addDays(-1);
        try{
            update lg;
        }catch(exception ex){
        }
        
        test.stopTest();
        
        //System.assert([SELECT Student_Course_End_Date__c FROM LG_Student__c WHERE Id =: lg.Id AND Status_in_LG__c = 'Registered'].Student_Course_End_Date__c == lg.LG_End_Date__c);
    }
    
    
    @isTest(seeAllData=false) 
    static void updateCompletedLGStudentWhenCompletedLGIsBeingActivatedAgain_Test(){
        
        
        
        insert new HD_Settings_List__c(Name = 'Generate Payment Profiles', Value__c = Userinfo.getProfileId());
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        HD_TriggerSettings.disableTriggersFromTest.remove('updateCompletedLGStudentWhenCompletedLGIsBeingActivatedAgain');
        
        Account acc = ObjectCreator.getNewAccount();
        insert acc;
        
        Agreement__c agreement = ObjectCreator.getNewAgreement( acc.Id);
        insert agreement;
        
        Base_Course__c bc = ObjectCreator.getNewBaseCourse();
        bc.Fixed_Number_of_Students__c = true;
        insert bc;
        test.startTest();
        Course_Sub_Type__c cSubType = ObjectCreator.getNewCourseSubType(acc.Id, bc.Id); 
        cSubType.Course_Price__c = 10;
        cSubType.Gap_Between_Payments__c = 1;
        cSubType.Number_of_Payments__c = 10;
        insert cSubType;
        
        
        
        update new Base_Course__c(Id = testEnv.baseCurseId, Fixed_Number_of_Students__c = true);
        
        LG__c lg = new LG__c(Id = testEnv.lgId);
        lg.Group_Status__c = 'Completed';   
        update lg;
        
        LG_Student__c lgs = new LG_Student__c(Id = testEnv.studentId);
        lgs.Status_in_LG__c = 'Completed';
        update lgs;
        
        
        lg.Declared_Number_of_Students__c = 10;
        lg.LG_Start_Date__c = System.today();
        lg.LG_End_Date__c = System.today().addDays(30);   
        lg.Group_Status__c = 'Active';    
        update lg;
        test.stopTest();
        
    }
    
    @isTest(seeAllData=false) 
    static void updateRelatedRecordsOnChangeLGTeacher_Test(){
        
        Account acc = ObjectCreator.getNewAccount();
        insert acc;
        
        Contact teacher1 = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        Contact teacher2 = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert new List<Contact>{teacher1,teacher2};
            
            ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        HD_TriggerSettings.disableTriggersFromTest.remove('updateRelatedRecordsOnChangeLGTeacher');
        
        Test.startTest();
        
        System.debug(LoggingLevel.ERROR, '*** Query: ' + [SELECT Id FROM LG_Lesson__c WHERE LG__c = :testEnv.lgId]);
        
        LG_Lesson__c lesson = new LG_Lesson__c();
        lesson.LG__c = testEnv.lgId;
        lesson.Lesson_Teacher__c = teacher1.Id;
        lesson.Lesson_Date_Hour__c = System.today().addDays(1);
        insert lesson;
        
        LG__c lg = new LG__c(Id = testEnv.lgId);
        lg.Group_Status__c = 'Planned';
        lg.LG_Start_Date__c = System.today();
        lg.LG_End_Date__c = System.today().addDays(30);
        lg.Teacher__c = teacher1.Id;
        update lg;
        
        LG_Days_Hours__c lgDH = new LG_Days_Hours__c(Id = testEnv.lgDHId);
        lgDH.End_Hour__c = '21:30';   
        lgDH.Teacher__c = teacher1.Id;          
        update lgDH;
        
        LGCreateLessonBatch b = new LGCreateLessonBatch();
        
        b.records2process = LGHelperMethods.getAllLessonsDays(testEnv.lgId, System.today());
        b.records2process[0].Lesson_Date_Hour__c = System.today().addDays(-2);
        b.rollback_key = b.records2process[0].Rollback_Key__c;                        
        b.doInsert = true;            
        Database.executeBatch(b);
        
        lg.Teacher__c = teacher2.Id;
        update lg;
        
        Test.stopTest();
        
        //System.assert([SELECT Teacher__c FROM LG_Days_Hours__c WHERE Id =: lgDH.Id].Teacher__c == teacher2.Id);
    }
    
    @isTest(seeAllData=false) 
    static void maintenanceLGPaymentsAndGIMRecordsOnDeclaredNroChanged_Test(){
        
        
        
        insert new HD_Settings_List__c(Name = 'Generate Payment Profiles', Value__c = Userinfo.getProfileId());
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        HD_TriggerSettings.disableTriggersFromTest.remove('updateRelatedRecordsOnChangeLGTeacher');
        
        Account acc = ObjectCreator.getNewAccount();
        insert acc;
        
        Agreement__c agreement = ObjectCreator.getNewAgreement( acc.Id);
        /*Avihai : those MISSING FIELDS appear in TEST and not in MFC. Might need to consider before upload\overrride
agreement.Name = 'Test';
agreement.Royalty_Type__c = '1 - Standard';
agreement.Agreement_type__c = 'MF';
agreement.Program_Type__c = 'HDE';
agreement.Signing_Date__c = system.today();
agreement.Expiry_Date__c = system.today().addDays(10);
*/
        insert agreement;
        
        Base_Course__c bc = ObjectCreator.getNewBaseCourse();
        bc.Fixed_Number_of_Students__c = true;
        insert bc;
        test.startTest();
        Course_Sub_Type__c cSubType = ObjectCreator.getNewCourseSubType(acc.Id, bc.Id); 
        cSubType.Course_Price__c = 10;
        cSubType.Gap_Between_Payments__c = 1;
        cSubType.Number_of_Payments__c = 10;
        insert cSubType;
        
        
        
        update new Base_Course__c(Id = testEnv.baseCurseId, Fixed_Number_of_Students__c = true);
        
        LG__c lg = new LG__c(Id = testEnv.lgId);
        lg.Declared_Number_of_Students__c = 0;
        lg.LG_Start_Date__c = System.today();
        lg.LG_End_Date__c = System.today().addDays(30);       
        update lg;
        
        LG_Payment__c lgPayment = new LG_Payment__c();
        lgPayment.LG__c = testEnv.lgId;
        lgPayment.Actual_Price__c = null;
        lgPayment.LG_Student__c = testEnv.studentId;
        insert lgPayment;
        
        
        
        LG_Student__c lstudent = new LG_Student__c(Id = testEnv.studentId);
        lstudent.Status_in_LG__c = 'Registered';
        update lstudent;
        
        Id recordTypeId = Schema.SObjectType.Group_Income_Per_Month__c.getRecordTypeInfosByName().get('Calculated Student').getRecordTypeId();
        Group_Income_Per_Month__c gipm1 = ObjectCreator.getNewGroupIncomePerMonth(agreement.Id, lg.Id);
        gipm1.RecordTypeId = recordTypeId;
        gipm1.LG__c = lg.Id;
        gipm1.Agreement__c = agreement.Id;
        gipm1.Royalty_Start_Date__c = Date.newInstance(2017, 12, 1);
        gipm1.Royalty_End_Date__c = null;
        
        insert gipm1;
        
        
        lg.Declared_Number_of_Students__c = 10;
        update lg;
        
        lg.Declared_Number_of_Students__c = null;
        update lg;
        test.stopTest();
    }
    
    @isTest(seeAllData=false) 
    static void reCallTheDiscountLogic_test(){
        test.startTest();
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        HD_TriggerSettings.disableTriggersFromTest.remove('updateLGPaymentWhenLGDiscountIsApproved');
        
        LG__c lg = new LG__c(Id = testEnv.lgId);
        lg.Course_Price__c = 1;
        update lg;
        
        LG_Student__c st = new LG_Student__c(Id = testEnv.studentId);
        st.Billing_Type__c= 'Course Price';
        update st; 
        
        test.stopTest();
        
        Contact con = new Contact(Id = testEnv.studentContactId);
        con.Student_Billing_Type__c= 'Course Price';
        update con;
        
        LG_Discount__c disc1 = ObjectCreator.getNewLGDiscount(testEnv.studentId, testEnv.lgId);
        disc1.Discount_Status__c = 'Approved';
        insert disc1;
        
        LG_Discount_TriggerHandler.lgDiscountApproved.add(disc1);
        
        lg.Price_per_Month__c = 2;
        update lg;
    }
    
    @isTest(seeAllData=false) 
    static void recreateLGPayment2LGBillingTypeChange_Test(){
        
        insert new HD_Settings_List__c(Name = 'Generate Payment Profiles', Value__c = Userinfo.getProfileId());
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        HD_TriggerSettings.disableTriggersFromTest.remove('recreateLGPayment2LGBillingTypeChange');
        
        Account acc = ObjectCreator.getNewAccount();
        insert acc;
        
        Contact studentContact  = ObjectCreator.getNewContact(testEnv.accId, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId());              
        insert studentContact;
        
        Agreement__c agreement = ObjectCreator.getNewAgreement( acc.Id);
        //insert agreement;
        
        Base_Course__c bc = ObjectCreator.getNewBaseCourse();
        bc.Fixed_Number_of_Students__c = true;
        insert bc;
        test.startTest();
        Course_Sub_Type__c curseSubType = new Course_Sub_Type__c(Id = testEnv.curseSubTypeId);
        curseSubType.Price_per_Session__c = 10;
        update curseSubType;
        
        LG__c lg = new LG__c(Id = testEnv.lgId);
        lg.Billing_Type__c= 'Price per Session';
        lg.Price_per_Session__c = 1;
        lg.Group_Status__c = 'Planned';
        lg.LG_Start_Date__c = System.today();
        lg.LG_End_Date__c = System.today().addDays(30);   
        lg.Last_Month_Price__c = 10;
        update lg;
        /*
        LG_Student__c studentLG = ObjectCreator.getNewLGStudent(studentContact.Id, lg.Id);
        studentLG.Status_in_LG__c = 'Registered';
        studentLG.Billing_Type__c = 'Course Price';
        studentLG.Approved_Price__c = 100;
        //studentLG.Number_of_Payments__c = 2;
        studentLG.Student_Start_Paying_Date__c = system.today();
        //studentLG.Gap_Between_Payments__c = 2;
        studentLG.Approved_Price__c = 10;
        studentLG.Lesson_Type__c = 'Standard';
        studentLG.Billing_Type__c = 'Price per Session';
        insert studentLG;
        */
        test.stopTest();
    }
    
}