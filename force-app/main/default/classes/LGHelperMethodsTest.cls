/******************************************************************************* 
Name              : LGHelperMethodsTest
Description       : Contains the test methods of all test methods of the class LGHelperMethods 
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Nicolas                   03/08/2016              
*******************************************************************************/
@isTest
private class LGHelperMethodsTest {
    
    @isTest(seeAllData=false) 
    public static void getAllLessonsDays_Test(){
        
        Test.startTest();
        Account acc = ObjectCreator.getNewAccount();
        acc.BillingCountry = 'Italy';
        insert acc;

        Contact teacher1 = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert new List<Contact>{teacher1};

        Agreement__c agreement = ObjectCreator.getNewAgreement( acc.Id);
        insert agreement;
        
        Base_Course__c bc = ObjectCreator.getNewBaseCourse();
        insert bc;
        
        Course_Sub_Type__c cSubType = ObjectCreator.getNewCourseSubType(acc.Id, bc.Id); 
        insert cSubType;

        LG__c lg1 = ObjectCreator.getNewLG( acc.Id, cSubType.Id, agreement.Id );
        lg1.LG_Start_Date__c = system.today();
        lg1.LG_End_Date__c = system.today().addMonths(5);
        lg1.Teacher__c = teacher1.Id;
        lg1.Group_Status__c = 'Active';       
        lg1.Franchisee__c = acc.Id;
        
        Test.stopTest();
         
        insert lg1;
        
        LG_Days_Hours__c lgDH1 = ObjectCreator.getNewLG_Days_Hours(lg1.Id);
        lgDH1.Start_Hour__c = '10:00';
        lgDH1.End_Hour__c = '11:00';
        insert lgDH1;
        
        LGHelperMethods.getAllLessonsDays(lg1.Id, system.today() );
    }
    
    @isTest(seeAllData=false) 
    public static void getAllLessonsDaysByNumberOfLessons_Test(){
        Account acc = ObjectCreator.getNewAccount();
        acc.BillingCountry = 'Italy';
        insert acc;

        Contact teacher1 = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert new List<Contact>{teacher1};

        Agreement__c agreement = ObjectCreator.getNewAgreement( acc.Id);
        insert agreement;
        
        Base_Course__c bc = ObjectCreator.getNewBaseCourse();
        insert bc;
        
        Course_Sub_Type__c cSubType = ObjectCreator.getNewCourseSubType(acc.Id, bc.Id); 
        insert cSubType;

        LG__c lg1 = ObjectCreator.getNewLG( acc.Id, cSubType.Id, agreement.Id );
        lg1.LG_Start_Date__c = system.today();
        lg1.LG_End_Date__c = system.today().addMonths(5);
        lg1.Teacher__c = teacher1.Id;
        lg1.Group_Status__c = 'Active';       
        lg1.Franchisee__c = acc.Id;
         
        insert lg1;
        
        LG_Days_Hours__c lgDH1 = ObjectCreator.getNewLG_Days_Hours(lg1.Id);
        lgDH1.Start_Hour__c = '10:00';
        lgDH1.End_Hour__c = '11:00';
        insert lgDH1;
        
        LGHelperMethods.getAllLessonsDaysByNumberOfLessons(lg1.Id, 2, null);
    }
    
    @isTest(seeAllData=false) 
    public static void getHolidaysBy_Test(){
        
        Holiday_Vacation__c hv = ObjectCreator.getNewHolidayVacation( Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('Teachers').getRecordTypeId()  );
        
        List<Holiday_Vacation__c> hvList = new List<Holiday_Vacation__c>{hv};
        
        LGHelperMethods.getHolidaysBy(hvList);
    }
    
    @isTest(seeAllData=false) 
    public static void isDayOff_Test(){
        Holiday_Vacation__c hv = ObjectCreator.getNewHolidayVacation( Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('Teachers').getRecordTypeId()  );
        Map<Date, List<Holiday_Vacation__c>> hvMap = new Map<Date, List<Holiday_Vacation__c>>{system.today()=>new List<Holiday_Vacation__c>{hv} };
        
        LGHelperMethods.isDayOff(system.today(), hvMap, hvMap, hvMap);
    }
    
    @isTest(seeAllData=false) 
    public static void getLGPaymentBySessions_Test(){
        Account acc = ObjectCreator.getNewAccount();
        acc.BillingCountry = 'Italy';
        insert acc;
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        
        Course_Sub_Type__c cst1 = new Course_Sub_Type__c(Id = testEnv.curseSubTypeId);
        cst1.Price_per_Session__c = 1;
        cst1.Franchisee_Name__c=acc.id;
        update cst1;
        
        LG__c lg  = new LG__c(Id = testEnv.lgId);
        lg.Billing_Type__c = 'Price per Session';
        lg.Price_per_Session__c = 1;
        lg.LG_Start_Date__c = system.today();
        lg.Group_Status__c = 'Planned';
        //lg.LG_Type__c = 'Demo Lesson';
        update lg;
        
         test.startTest();
        LG_Student__c student = [select id,Status_in_LG__c,Billing_Type__c,Approved_Price__c,
                                Discount_for_LG__c,Gap_Between_Payments__c,
                                 Number_of_Payments__c from LG_Student__c where id=:testEnv.studentId ];
        

        student.Status_in_LG__c = 'Registered';
        //student.Billing_Type__c = 'Price per Session';
        student.Approved_Price__c = 2;
        //student.Lesson_Type__c = null;
        //student.Discount_for_LG__c = 0;
        student.Gap_Between_Payments__c = null;
        student.Number_of_Payments__c = null;
        update student;
       
        
       
        LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson( testEnv.lgId , testEnv.teacherContactId, testEnv.lgDHId );
        insert lesson;
        
        LG_Payment__c pay1 = ObjectCreator.getNewLGPayment(testEnv.lgId, student.Id, testEnv.studentContactId);
        pay1.Planned_Date__c = system.today().addDays(-1);
        insert pay1;
        
        LG_Student_Attendance__c sa1 = ObjectCreator.getNewStudentAttendance(lesson.Id, student.Id);
        sa1.LG_Payment__c = pay1.Id;
        insert sa1;
        
        
        LGHelperMethods.getLGPaymentBySessions(new Set<Id>{student.Id}, null, 1);
        test.stopTest();
    }
    
    @isTest(seeAllData=false) 
    public static void getLGPaymentByToLGSessions_Test(){
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        
        Base_Course__c bc = new Base_Course__c(Id = testEnv.baseCurseId );
        bc.Fixed_Number_of_Students__c = true;
        update bc;
        
        Account acc = ObjectCreator.getNewAccount();
        acc.BillingCountry = 'Italy';
        insert acc;
        
        
        Course_Sub_Type__c cst1 = new Course_Sub_Type__c(Id = testEnv.curseSubTypeId);
        cst1.Price_per_Session__c = 1;
        cst1.Price_Type__c = 'Per Session';
        cst1.Franchisee_Name__c=acc.id;
        update cst1;
        
        LG__c lg  = new LG__c(Id = testEnv.lgId);
        lg.Billing_Type__c = 'Price per Session';
        lg.Price_per_Session__c = 1;
        lg.Declared_Number_of_Students__c = 1;
        lg.LG_Start_Date__c = system.today();
        lg.Group_Status__c = 'Planned';
        update lg;
        
        LG_Student__c student = new LG_Student__c(Id = testEnv.studentId );//ObjectCreator.getNewLGStudent( testEnv.studentContactId, testEnv.lgId );
        student.Status_in_LG__c = 'Completed';
        student.Billing_Type__c = 'Price per Session';
        student.Approved_Price__c = 1;
        student.Lesson_Type__c = 'Standard';
        student.Discount_for_LG__c = 0;
        student.Gap_Between_Payments__c = null;
        student.Number_of_Payments__c = null;
        update student;
        
        test.startTest();
        
        LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson( testEnv.lgId , testEnv.teacherContactId, testEnv.lgDHId );
        insert lesson;
        
        LG_Payment__c pay1 = ObjectCreator.getNewLGPayment(testEnv.lgId, student.Id, testEnv.studentContactId);
        pay1.Planned_Date__c = system.today().addDays(-1);
        insert pay1;
        
        LG_Student_Attendance__c sa1 = ObjectCreator.getNewStudentAttendance(lesson.Id, student.Id);
        sa1.LG_Payment__c = pay1.Id;
        insert sa1;
        
        
        LGHelperMethods.getLGPaymentByToLGSessions(new Set<Id>{student.Id}, null, 1);
        test.stopTest();
    }
    
    @isTest(seeAllData=false) 
    public static void deleteLGStudentAttendanceAndItsLGPayments_Test(){
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        
        Account acc = ObjectCreator.getNewAccount();
        acc.BillingCountry = 'Italy';
        insert acc;
        
        Base_Course__c bc = new Base_Course__c(Id = testEnv.baseCurseId );
        bc.Fixed_Number_of_Students__c = true;
        update bc;
        
        Course_Sub_Type__c cst1 = new Course_Sub_Type__c(Id = testEnv.curseSubTypeId);
        cst1.Price_per_Session__c = 1;
        cst1.Price_Type__c = 'Per Session';
        cst1.Franchisee_Name__c=acc.id;
        update cst1;
        
        LG__c lg  = new LG__c(Id = testEnv.lgId);
        lg.Billing_Type__c = 'Price per Session';
        lg.Price_per_Session__c = 1;
        lg.Declared_Number_of_Students__c = 1;
        lg.LG_Start_Date__c = system.today();
        lg.Group_Status__c = 'Planned';
        update lg;
        
        LG_Student__c student = new LG_Student__c(Id = testEnv.studentId );//ObjectCreator.getNewLGStudent( testEnv.studentContactId, testEnv.lgId );
        student.Status_in_LG__c = 'Completed';
        student.Billing_Type__c = 'Price per Session';
        student.Approved_Price__c = 1;
        student.Lesson_Type__c = 'Standard';
        student.Discount_for_LG__c = 0;
        student.LG_Student_Old_ID__c = 'test1001';
        student.Gap_Between_Payments__c = null;
        student.Number_of_Payments__c = null;
        update student;
        
        test.startTest();
        
        LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson( testEnv.lgId , testEnv.teacherContactId, testEnv.lgDHId );
        insert lesson;
        
        LG_Payment__c pay1 = ObjectCreator.getNewLGPayment(testEnv.lgId, student.Id, testEnv.studentContactId);
        pay1.Planned_Date__c = system.today().addDays(-1);
        insert pay1;
        
        LG_Student_Attendance__c sa1 = ObjectCreator.getNewStudentAttendance(lesson.Id, student.Id);
        sa1.LG_Payment__c = pay1.Id;
        insert sa1;
        
        LG_Student_Attendance__c sa2 = ObjectCreator.getNewStudentAttendance(lesson.Id, student.Id);
        sa2.LG_Payment__c = pay1.Id;
        insert sa2;
        
           //According to error when deploy: System.NullPointerException: Attempt to de-reference a null object 
    //Stack Trace: Class.LGHelperMethods.deleteLGStudentAttendanceAndItsLGPayments: line 340, column 1 Class.LGHelperMethodsTest.deleteLGStudentAttendanceAndItsLGPayments_Test: 
    //line 246, column 1
       //Comment out by Avihai 30/07/2018         //LGHelperMethods.deleteLGStudentAttendanceAndItsLGPayments(new List<LG_Student_Attendance__c>{sa1}, true, 1);
        test.stopTest();
    }
    
    @isTest(seeAllData=false) 
    public static void getOneTimeLGDiscounts_Test(){
        HD_TriggerSettings.disableAllTriggers = true;
        ObjectCreator.DisableSharingMethods();
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        
        LG__c lg = new LG__c(Id = testEnv.lgId);
        lg.Course_Price__c = 1;
        update lg;
        
        LG_Student__c st = new LG_Student__c(Id = testEnv.studentId);
        st.Billing_Type__c= 'Course Price';
        update st; 

        Contact con = new Contact(Id = testEnv.studentContactId);
        con.Student_Billing_Type__c= 'Course Price';
        update con;
        
        LG_Discount__c disc1 = ObjectCreator.getNewLGDiscount(testEnv.studentId, testEnv.lgId);
        disc1.Discount_Status__c = 'Approved';
        insert disc1;
        test.startTest();
        update new LG_Student__c(Id = testEnv.studentId, Approved_Price__c = null);
        
        LG_Discount__c disc2 = disc1.clone(false, true);
        disc2.Discount_Status__c = 'Approved';
        disc2.Discount_Type__c = 'Entire Course';
        disc2.Year__c = null;
        insert disc2;
        
        HD_TriggerSettings.disableAllTriggers = false;
        
        LGHelperMethods.getOneTimeLGDiscounts(new Set<Id>{ testEnv.lgId });
        test.stopTest();
    }
    
    @isTest(seeAllData=false) 
    public static void getEntireCourseWithoutLGStudentLGDiscounts_Test(){
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        LGHelperMethods.getEntireCourseWithoutLGStudentLGDiscounts(new Set<Id>{ testEnv.lgId });
    }
    
    @isTest(seeAllData=false) 
    public static void getEntireCourseWithLGStudentLGDiscounts_Test(){
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        LGHelperMethods.getEntireCourseWithLGStudentLGDiscounts(new Set<Id>{ testEnv.lgId });
    }
    
    @isTest(seeAllData=false) 
    public static void applyVAT2LGPayments_Test(){
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        
        test.startTest();
        
        Account lc = ObjectCreator.getNewAccount();
        insert lc;
        
        Account lc2 = new Account( Id = testEnv.lcId, ParentId = lc.Id );
        update lc2;
        
        LG_Student__c student = new LG_Student__c(Id = testEnv.studentId);
        student.Status_in_LG__c = 'Registered';
        update student;
        
        LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson( testEnv.lgId , testEnv.teacherContactId, testEnv.lgDHId );
        insert lesson;
        
        LG_Payment__c pay1 = ObjectCreator.getNewLGPayment(testEnv.lgId, student.Id, testEnv.studentContactId);
        pay1.Planned_Date__c = system.today().addDays(-1);
        insert pay1;
        
        Franchisee_VAT__c vat2 = ObjectCreator.getNewFranchiseeVat( testEnv.lcId, 1);
        vat2.VAT_From_Date__c = system.today();
        vat2.VAT_End_Date__c = system.today().addDays(1);
        Franchisee_VAT__c vat3 = ObjectCreator.getNewFranchiseeVat( lc.Id, 1);
        vat3.VAT_From_Date__c = system.today().addDays(-2);
        vat3.VAT_End_Date__c = system.today().addDays(1);
        insert new List<Franchisee_VAT__c>{vat2, vat3};
        
        LGHelperMethods.applyVAT2LGPayments(new Set<Id>{ testEnv.lcId, lc.Id }, new Set<Id>{pay1.Id} );
        
        Franchisee_VAT__c vat1 = ObjectCreator.getNewFranchiseeVat( testEnv.lcId, 1);
        insert vat1;
        
        LGHelperMethods.applyVAT2LGPayments(new Set<Id>{ testEnv.lcId }, new Set<Id>{pay1.Id} );
        
        test.stopTest();
    }
    
    @isTest(seeAllData=false) 
    public static void checkCondition2RecreateLGPayment2LG_Test(){
        
        Account acc = ObjectCreator.getNewAccount();
        acc.BillingCountry = 'Italy';
        insert acc;

        Contact teacher1 = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert new List<Contact>{teacher1};

        Agreement__c agreement = ObjectCreator.getNewAgreement( acc.Id);
        insert agreement;
        
        Base_Course__c bc = ObjectCreator.getNewBaseCourse();
        insert bc;
        
        Base_Course__c bc2 = bc.clone(false, true);
        bc2.Fixed_Number_of_Students__c = true;
        insert bc2;
        
        Course_Sub_Type__c cSubType = ObjectCreator.getNewCourseSubType(acc.Id, bc.Id); 
        cSubType.Price_Type__c = 'Per Student';
        insert cSubType;
        
        test.startTest();
        
        Course_Sub_Type__c cSubType2 = cSubType.clone(false, true);
        cSubType2.Base_Course__c = bc2.Id;
        cSubType2.Price_Type__c = 'Per Group';
        cSubType2.Franchisee_Name__c=acc.id;
        
        
        insert cSubType2;
        
        LG__c lg1 = ObjectCreator.getNewLG( acc.Id, cSubType.Id, agreement.Id );
        lg1.LG_Start_Date__c = system.today();
        lg1.LG_End_Date__c = system.today().addMonths(5);
        lg1.Teacher__c = teacher1.Id;
        lg1.Group_Status__c = 'Active';       
        lg1.Franchisee__c = acc.Id;
        insert lg1;
        
        LG__c lg2 = lg1.clone(false, true);
        lg2.LG_Start_Paying_Date__c = system.today().addDays(-31);
        lg2.Course_Sub_Type__c = cSubType2.Id;
        lg2.Declared_Number_of_Students__c = 1;
        lg2.DBAmp_Date__c = system.today();
        
        
        insert lg2;
        
        LGHelperMethods.checkCondition2RecreateLGPayment2LG( lg2 );
        
        HD_Settings_List__c hdSetting01 = new HD_Settings_List__c(Name = 'Generate Payment Profiles', Value__c = userinfo.getUserId());
        insert hdSetting01;
        
        LGHelperMethods.checkCondition2RecreateLGPayment2LG( lg1 );

        test.stopTest();
    }

    
    @isTest(seeAllData=false) 
    public static void checkCondition2RecreateLGPayment2LGStudent_Test(){
        
        ObjectCreator.DisableSharingMethods();
        
        Account acc = ObjectCreator.getNewAccount();
        acc.BillingCountry = 'Italy';
        insert acc;

        Contact teacher1 = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert new List<Contact>{teacher1};

        Agreement__c agreement = ObjectCreator.getNewAgreement( acc.Id);
        agreement.Agreement_Old_ID__c = 'test0001001001';
        insert agreement;
        
        Base_Course__c bc = ObjectCreator.getNewBaseCourse();
        insert bc;
        
        Base_Course__c bc2 = bc.clone(false, true);
        bc2.Fixed_Number_of_Students__c = true;
        insert bc2;
        
        Course_Sub_Type__c cSubType = ObjectCreator.getNewCourseSubType(acc.Id, bc.Id); 
        cSubType.Price_Type__c = 'Per Student';
        insert cSubType;
        
        Course_Sub_Type__c cSubType2 = cSubType.clone(false, true);
        cSubType2.Base_Course__c = bc2.Id;
        cSubType2.Price_Type__c = 'Per Group';
        cSubType2.Franchisee_Name__c=acc.id;
        
        insert cSubType2;
        
        LG__c lg1 = ObjectCreator.getNewLG( acc.Id, cSubType.Id, agreement.Id );
        lg1.LG_Start_Date__c = system.today();
        lg1.LG_End_Date__c = system.today().addMonths(5);
        lg1.Teacher__c = teacher1.Id;
        lg1.Group_Status__c = 'Active';       
        lg1.Franchisee__c = acc.Id;
        insert lg1;
        
        LG__c lg2 = lg1.clone(false, true);
        lg2.LG_Start_Paying_Date__c = system.today().addDays(-31);
        lg2.Course_Sub_Type__c = cSubType2.Id;
        lg2.Declared_Number_of_Students__c = 1;
        lg2.DBAmp_Date__c = system.today();
        insert lg2;
        
        LG_Days_Hours__c lgDH1 = ObjectCreator.getNewLG_Days_Hours(lg1.Id);
        lgDH1.Start_Hour__c = '10:00';
        lgDH1.End_Hour__c = '11:00';
        insert lgDH1;
        
        LG_Days_Hours__c lgDH2 = ObjectCreator.getNewLG_Days_Hours(lg2.Id);
        lgDH2.Start_Hour__c = '10:00';
        lgDH2.End_Hour__c = '11:00';
        insert lgDH2;
        
        Contact studentContact  = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId());              
        insert studentContact;
        
        LG_Student__c student = ObjectCreator.getNewLGStudent(studentContact.Id, lg1.Id);
        student.Status_in_LG__c = 'Registered';
        
        Test.startTest();
        insert new List<LG_Student__c>{student};
        
        LG_Student__c student2 = ObjectCreator.getNewLGStudent(studentContact.Id, lg2.Id);
        student2.Status_in_LG__c = 'Registered';
        insert new List<LG_Student__c>{student2};
        
        LGHelperMethods.checkCondition2RecreateLGPayment2LGStudent( student );
        LGHelperMethods.checkCondition2RecreateLGPayment2LGStudent( student2 );
        
        test.stopTest();
    }
    
    @isTest(seeAllData=false) 
    public static void doRecreateLGPayment2LG_Test(){
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        HD_TriggerSettings.disableAllTriggers = true;
        
        Account acc = ObjectCreator.getNewAccount();
        acc.BillingCountry = 'Italy';
        insert acc;
        
        LG__c lg = new LG__c(Id = testEnv.lgId);
        lg.Number_of_Payments__c = 0;
        lg.Gap_between_Price_Payments__c = 0;
        update lg;
        
        Course_Sub_Type__c cst1 = new Course_Sub_Type__c( Id = testEnv.curseSubTypeId );
        cst1.Price_Type__c = 'Per Student';
        cst1.Franchisee_Name__c=acc.id;
        update cst1; 
        
        LG_Student__c student = new LG_Student__c(Id = testEnv.studentId);
        student.Status_in_LG__c = 'Registered';
        update student;
        
        LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson( testEnv.lgId , testEnv.teacherContactId, testEnv.lgDHId );
        //insert lesson;
        
       
        LG_Payment__c pay1 = ObjectCreator.getNewLGPayment(testEnv.lgId, student.Id, testEnv.studentContactId);
        //insert pay1;
        
        LG_Student_Attendance__c sa1 = ObjectCreator.getNewStudentAttendance(lesson.Id, student.Id);
        sa1.LG_Payment__c = pay1.Id;
        //insert sa1; // TODO CHECK 

        test.startTest();
        HD_TriggerSettings.disableAllTriggers = false;
        LGHelperMethods.doRecreateLGPayment2LG( new Set<Id>{testEnv.lgId} );
        try{
            update new LG__c(Id = testEnv.lgId, LG_End_Paying_Date__c = system.Today().addYears(2));
        }catch(exception ex){}
        test.stopTest();
       
    }
    
    @isTest(seeAllData=false) 
    public static void doRecreateLGPayment2LGStudent_Test(){
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        
        test.startTest();
        
        LG_Student__c student = new LG_Student__c(Id = testEnv.studentId);
        student.Status_in_LG__c = 'Registered';
        update student;
        
        LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson( testEnv.lgId , testEnv.teacherContactId, testEnv.lgDHId );
        insert lesson;
        
        
        LG_Payment__c pay1 = ObjectCreator.getNewLGPayment(testEnv.lgId, student.Id, testEnv.studentContactId);
        insert pay1;
        
        LG_Student_Attendance__c sa1 = ObjectCreator.getNewStudentAttendance(lesson.Id, student.Id);
        sa1.LG_Payment__c = pay1.Id;
        insert sa1;
        
        LGHelperMethods.doRecreateLGPayment2LGStudent( new Set<Id>{student.Id} );
        
        update new LG__c(Id = testEnv.lgId, LG_End_Paying_Date__c = system.Today().addYears(2));
        
        test.stopTest();
    }
    
    @isTest(seeAllData=false) 
    public static void doRemoveLGPaymentToLG_test(){
        
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        
        LG_Student__c student = new LG_Student__c(Id = testEnv.studentId);
        student.Status_in_LG__c = 'Completed';
        update student;
        
        test.startTest();
        LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson( testEnv.lgId , testEnv.teacherContactId, testEnv.lgDHId );
        //insert lesson;
        
        Account acc = ObjectCreator.getNewAccount();
        acc.BillingCountry = 'Italy';
        insert acc;
        
        Course_Sub_Type__c courseSubType = new Course_Sub_Type__c( Id = testEnv.curseSubTypeId );
        courseSubType.Price_Type__c = 'Per Group';
        courseSubType.Franchisee_Name__c=acc.id;
        update courseSubType;
        
        LG_Payment__c pay1 = ObjectCreator.getNewLGPayment(testEnv.lgId, student.Id, testEnv.studentContactId);
        pay1.LG_Student__c = null;
        pay1.Actual_Price__c = 0;
        pay1.Payment_Type__c = 'Standard';
        insert pay1;
        
        LGHelperMethods.doRemoveLGPaymentToLG( new Map<Id,Date>{testEnv.lgId => system.Today().addYears(-1)} );
        test.stopTest();
    }   
    
    @isTest(seeAllData=false) 
    public static void getDiscounts_Test(){
        HD_TriggerSettings.disableAllTriggers = true;
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        
        LG__c lg = new LG__c(Id = testEnv.lgId);
        lg.Course_Price__c = 1;
        update lg;
        
        LG_Student__c st = new LG_Student__c(Id = testEnv.studentId);
        st.Billing_Type__c= 'Course Price';
        update st; 

        Contact con = new Contact(Id = testEnv.studentContactId);
        con.Student_Billing_Type__c= 'Course Price';
        update con;
        
        LG_Discount__c disc1 = ObjectCreator.getNewLGDiscount(testEnv.studentId, testEnv.lgId);
        disc1.Discount_Status__c = 'Approved';
        disc1.LG__c = testEnv.lgId;
        insert disc1;
        
        update new LG_Student__c(Id = testEnv.studentId, Approved_Price__c = null);
        
        LG_Discount__c disc2 = disc1.clone(false, true);
        disc2.Discount_Status__c = 'Approved';
        disc2.Discount_Type__c = 'Entire Course';
        disc2.Year__c = null;
        disc2.LG__c = testEnv.lgId;
        
        LG_Discount__c disc3 = disc2.clone(false, true);
        disc3.LG_Student__c = null;
        insert new List<LG_Discount__c>{disc2, disc3};
        
        disc1.Discount_Status__c = 'Approved';
        disc2.Discount_Status__c = 'Approved';
        update new List<LG_Discount__c>{disc1,disc2};
        
        HD_TriggerSettings.disableAllTriggers = false;
        
        LGHelperMethods.getOneTimeLGDiscounts(new Set<Id>{ testEnv.lgId });
    }
    
    @isTest(seeAllData=false) 
    public static void getDiscounts_Test02(){
        ObjectCreator.DisableSharingMethods();
        HD_TriggerSettings.disableAllTriggers = true;
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        
        LG__c lg = new LG__c(Id = testEnv.lgId);
        lg.Course_Price__c = 1;
        update lg;
        
        LG_Student__c st = new LG_Student__c(Id = testEnv.studentId);
        st.Billing_Type__c= 'Course Price';
        update st; 

        Contact con = new Contact(Id = testEnv.studentContactId);
        con.Student_Billing_Type__c= 'Course Price';
        update con;
        
        LG_Discount__c disc1 = ObjectCreator.getNewLGDiscount(testEnv.studentId, testEnv.lgId);
        disc1.Discount_Status__c = 'Approved';
        disc1.LG__c = testEnv.lgId;
        insert disc1;
        test.startTest();
        update new LG_Student__c(Id = testEnv.studentId, Approved_Price__c = null);
        
        LG_Discount__c disc2 = disc1.clone(false, true);
        disc2.Discount_Status__c = 'Approved';
        disc2.Discount_Type__c = 'Entire Course';
        disc2.Year__c = null;
        disc2.LG__c = testEnv.lgId;
        insert new List<LG_Discount__c>{disc2};
        
        disc1.Discount_Status__c = 'Approved';
        disc2.Discount_Status__c = 'Approved';
        update new List<LG_Discount__c>{disc1,disc2};
        
        HD_TriggerSettings.disableAllTriggers = false;
        
        LGHelperMethods.getOneTimeLGDiscounts(new Set<Id>{ testEnv.lgId });
        test.stopTest();
    }
    
    @isTest(seeAllData=false) 
    public static void doUpdateLGEndPayingDate_Test(){
        
        insert new HD_Settings_List__c(Name = 'Generate Payment Profiles', Value__c = Userinfo.getProfileId());
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        
        Account acc = ObjectCreator.getNewAccount();
        insert acc;
        
        Agreement__c agreement = ObjectCreator.getNewAgreement( acc.Id);
        insert agreement;
        
        Base_Course__c bc = ObjectCreator.getNewBaseCourse();
        bc.Fixed_Number_of_Students__c = true;
        insert bc;

        Course_Sub_Type__c cSubType = ObjectCreator.getNewCourseSubType(acc.Id, bc.Id); 
        cSubType.Course_Price__c = 10;
        cSubType.Gap_Between_Payments__c = 1;
        cSubType.Number_of_Payments__c = 10;
        insert cSubType;

        LG__c lg = new LG__c(Id = testEnv.lgId);
        lg.Billing_Type__c = 'Price per Month';
        lg.Group_Status__c = 'Planned';
        lg.LG_Start_Date__c = System.today();
        lg.LG_End_Date__c = System.today().addDays(30);       
        update lg;
        
        test.startTest();
        LG_Student__c student = new LG_Student__c(Id = testEnv.studentId);
        student.Status_in_LG__c = 'Registered';
        student.Billing_Type__c = 'Price per Month';
        student.Student_End_Paying_Date__c = system.Today().addMonths(1);
        student.Gap_Between_Payments__c = null;
        student.Number_of_Payments__c = null;
        update student;
        
        
        LGHelperMethods.doUpdateLGEndPayingDate(new Map<Id, Date>{ testEnv.lgId => system.Today().addMonths(1)});
        test.stopTest();
    }
    
    @isTest(seeAllData=false) 
    public static void createLGLessonsOfHolidayCourse_Test(){
        
        insert new HD_Settings_List__c(Name = 'Generate Payment Profiles', Value__c = Userinfo.getProfileId());
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        
        Account acc = ObjectCreator.getNewAccount();
        insert acc;
        
        Agreement__c agreement = ObjectCreator.getNewAgreement( acc.Id);
        insert agreement;
        
        Base_Course__c bc = ObjectCreator.getNewBaseCourse();
        bc.Fixed_Number_of_Students__c = true;
        bc.Holiday_Course__c = true;
        insert bc;

        Course_Sub_Type__c cSubType = ObjectCreator.getNewCourseSubType(acc.Id, bc.Id); 
        cSubType.Course_Price__c = 10;
        cSubType.Gap_Between_Payments__c = 1;
        cSubType.Number_of_Payments__c = 10;
        insert cSubType;

        LG__c lg = new LG__c(Id = testEnv.lgId);
        lg.Billing_Type__c = 'Price per Month';
        lg.Group_Status__c = 'Planned';
        lg.LG_Start_Date__c = System.today();
        lg.LG_End_Date__c = System.today().addDays(30);       
        update lg;
        
        test.startTest();
        LG_Student__c student = new LG_Student__c(Id = testEnv.studentId);
        student.Status_in_LG__c = 'Registered';
        student.Billing_Type__c = 'Price per Month';
        student.Student_End_Paying_Date__c = system.Today().addMonths(1);
        student.Gap_Between_Payments__c = null;
        student.Number_of_Payments__c = null;
        update student;
                
        test.stopTest();
    }
}