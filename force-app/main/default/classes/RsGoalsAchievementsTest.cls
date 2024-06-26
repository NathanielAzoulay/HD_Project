@isTest
private class RsGoalsAchievementsTest {
    @isTest
    static void unitTest1(){
        Id accountRTypeMF = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();
        Account acc1 = ObjectCreator.getNewAccount();
        acc1.Account_Type__c = 'MF';
        acc1.RecordTypeId = accountRTypeMF;
        insert acc1;
        //rAccount
        Account acc = ObjectCreator.getNewAccount();
        acc.ParentId=acc1.id;
        acc.RecordTypeId = accountRTypeMF;
        acc.Account_Type__c = 'MF';
        insert acc;
        
        Id rt = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();
        Contact c = ObjectCreator.getNewContact(acc.id , rt);
        c.Email     = 'test@test.com';
        c.Teacher__c=true;
        insert c;
        
        Agreement__c agr = ObjectCreator.getNewAgreement(acc.id);
        agr.Name                = 'Test Agreement';
        agr.Royalty_Type__c     = '1 - Standard';
        agr.Agreement_Status__c = 'Active';
        agr.Program_Type__c     = 'HDE';
        agr.Signing_Date__c     = System.today();
        agr.Expiry_Date__c      = System.today().addDays(2);
        agr.From_Franchisee__c = acc.Id;
        insert agr;
        
        Agreement_Goal__c  agGoal = new Agreement_Goal__c();
        agGoal.Agreement__c     = agr.Id;
        agGoal.Goal_Type__c     = 'Students Goal';
        agGoal.Goal__c          = 100;
        agGoal.Start_Date__c    = System.today();
        insert agGoal;
        
        Base_Course__c bc = ObjectCreator.getNewBaseCourse();
        bc.Name = 'Test Base Course';
        bc.Fixed_Number_of_Students__c = False;
        insert bc;
        
        Course_Sub_Type__c course = ObjectCreator.getNewCourseSubType(acc.id, bc.id);
        course.Name                 = 'test Course';
        course.Price_Type__c        = 'Per Student';
        course.Course_Price__c      = 12;
        course.Price_per_Month__c   = 1;
        course.Price_per_Session__c = 2;
        course.Number_of_Payments__c = 1;
        course.Gap_between_Payments__c = 2;
        insert course;
        
        Id rt1 = Schema.SObjectType.LG__c.getRecordTypeInfosByName().get('Completed LG').getRecordTypeId();
        
        LG__c lgData = ObjectCreator.getNewLG(acc.id,course.id,agr.id );
        lgData.RecordTypeId = rt1;
        lgData.Name = 'Test LG';
        lgData.LG_Type__c                  = 'Standard';
        lgData.Group_Status__c             ='Planned';
        lgData.Teacher__c                  = c.Id;
        lgData.Teacher_Permission_on_LG__c = 'Read – Can view LG details as read only';
        
        insert lgData;
        Id rtgipm = Schema.SObjectType.Group_Income_Per_Month__c.getRecordTypeInfosByName().get('Calculated Student').getRecordTypeId();
        
        Group_Income_Per_Month__c  gipm  = ObjectCreator.getNewGroupIncomePerMonth(agr.id,lgData.id);
        gipm.RecordTypeId = rtgipm;
        gipm.Royalty_Start_Date__c       = System.today();
        insert gipm;
        
        Royalties_Calculation__c calculation = new Royalties_Calculation__c(
            Agreement__c = agr.Id,
            From_Franchisee__c   = acc.Id,
            Royalty_Month__c = System.today()
            
        );
        insert calculation;
        
        Agreement_Goal__c goal = new Agreement_Goal__c(
            Agreement__c = agr.Id,
            Goal_Type__c = 'Students Goal',
            Goal__c = 5,
            Start_Date__c = System.today()
        );
        insert goal;
        
        Analytics__c analytics = new Analytics__c(
            AccountId__c = 'acc.Id',
            Actual_students_LKG__c = 5,
            Actual_students_Non_LKG__c   = 2,
            Agreement__c = agr.Id,
            Calculated_Students_LKG__c = 5,
            Calculated_Students_NON_LKG__c = 2,
            Date__c = System.today(),
            Drop_Out__c   = 1,
            Goals__c = 2,
            Key__c  = 'KEY01',
            MF_ID__c = acc.Id,
            School_Year__c = String.valueOf(System.today().year()),
            Type__c  = '1',
            Royalties_Calculation__c = calculation.Id
            
        );
        insert analytics;
        Analytics__c analytics2 = new Analytics__c(
            AccountId__c = 'acc1.Id',
            Actual_students_LKG__c = 5,
            Actual_students_Non_LKG__c   = 2,
            Agreement__c = agr.Id,
            Calculated_Students_LKG__c = 5,
            Calculated_Students_NON_LKG__c = 2,
            Date__c = System.today().addMonths(-1),
            Drop_Out__c   = 1,
            Goals__c = 2,
            Key__c  = 'KEY02',
            MF_ID__c = acc.Id,
            School_Year__c = String.valueOf(System.today().year()),
            Type__c  = '1',
            Royalties_Calculation__c = calculation.Id
            
        );
        insert analytics2;
        Test.startTest();
        PageReference pageRef = Page.RsGoalsAchievementsGlobal;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id',acc.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(acc);
        RsGoalsAchievements controller = new RsGoalsAchievements(sc);
        controller.ClacParam();
    controller.displaychart();
        Test.stopTest();
    }
    
    @isTest
    static void unitTest2(){
        Id teacherRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();
        Id studentRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId();
        Id Calculated_Student = Schema.SObjectType.Group_Income_Per_Month__c.getRecordTypeInfosByName().get('Calculated Student').getRecordTypeId();
        //Insert Account
        Account acc = ObjectCreator.getNewAccount();
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();
        acc.Account_Type__c = 'LCF';
        insert acc;
        system.assertEquals(true, acc.id != NULL);
        
        
        //Insert Agreement
        Agreement__c agree = ObjectCreator.getNewAgreement(acc.Id);  
        agree.School_Year_Start_Month__c  = System.today().month();
        insert agree;
        system.assertEquals(true, agree.id != NULL);
        
        
        //Insert Base Course
        Base_Course__c baseCurse = ObjectCreator.getNewBaseCourse();
        baseCurse.Large_Group__c = true;
        baseCurse.Fixed_Number_of_Students__c = true;
        insert baseCurse;
        system.assertEquals(true, baseCurse.id != NULL);
        
        
        //Insert course sub type
        Course_Sub_Type__c curseSubType = ObjectCreator.getNewCourseSubType(acc.Id, baseCurse.Id);        
        insert curseSubType;
        system.assertEquals(true, curseSubType.id != NULL);
        
        
        //Insert Contact--Teacher
        Contact teacher = new Contact(FirstName = 'Dues',LastName = 'Daniel', AccountId = acc.Id, Status__c = 'Prospect', Email = 'example@mail.co', RecordTypeId = teacherRecordTypeId, Teacher__c = true);
        insert teacher;
        system.assertEquals(true, teacher.id != NULL);
        
        
        //Insert Contact--Student
        Contact student = new Contact(FirstName = 'Dues',LastName = 'Daniel', AccountId = acc.Id, Status__c = 'Prospect', Email = 'example@mail.co', RecordTypeId = studentRecordTypeId);
        insert student;
        system.assertEquals(true, student.id != NULL);
        
        
        //Insert Agreement Goals
        Agreement_Goal__c goal = new Agreement_Goal__c(
            Agreement__c = agree.Id,
            Goal_Type__c = 'Students Goal',
            Goal__c = 5,
            Start_Date__c = System.today()
        );
        insert goal;
        system.assertEquals(true, goal.id != NULL);
        
        
        //Insert Royalties_Calculation__c
        Royalties_Calculation__c calculation = new Royalties_Calculation__c(
            Agreement__c = agree.Id,
            From_Franchisee__c   = acc.Id,
            Royalty_Month__c = System.today()
            
        );
        insert calculation;
        system.assertEquals(true, calculation.id != NULL);
        
        
        //Insert Analytics
        
        //Insert LG
        LG__c lg = ObjectCreator.getNewLG(acc.Id, curseSubType.Id, agree.Id);
        lg.LG_Start_Date__c = System.today();
        lg.LG_End_Date__c = System.today().addDays(10);
        lg.Teacher__c = teacher.Id;
        //lg.Declared_Number_of_Students__c = 4;
        insert lg;
        system.assertEquals(true, lg.id != NULL);
        
        
        LG__c lg2 = ObjectCreator.getNewLG(acc.Id, curseSubType.Id, agree.Id);
        lg2.LG_Start_Date__c = System.today();
        lg2.LG_End_Date__c = System.today().addDays(10);
        lg.Teacher__c = teacher.Id;
        lg2.Declared_Number_of_Students__c = 4;
        insert lg2;
        system.assertEquals(true, lg2.id != NULL);
        
        
        LG_Days_Hours__c lgDH = ObjectCreator.getNewLG_Days_Hours(lg.Id);        
        insert lgDH;
        system.assertEquals(true, lgDH.id != NULL);
        
        
        LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson(lg.Id, teacher.Id, lgDH.Id);
        insert lesson;
        system.assertEquals(true, lesson.id != NULL);
        
        
        //Insert Group_Income_Per_Month__c
        Group_Income_Per_Month__c income = ObjectCreator.getNewGroupIncomePerMonth(agree.Id, lg.Id);
        income.Royalty_Start_Date__c = System.today();
        income.RecordTypeId = Calculated_Student;
        income.Student__c = student.Id;
        insert income;
        system.assertEquals(true, income.id != NULL);
        
        
        Group_Income_Per_Month__c income2 = ObjectCreator.getNewGroupIncomePerMonth(agree.Id, lg2.Id);
        income2.Royalty_Start_Date__c = System.today();
        income2.RecordTypeId = Calculated_Student;
        income2.Student__c = student.Id;
        insert income2;
        system.assertEquals(true, income2.id != NULL);
        
        
        //Insert LG Student
        LG_Student__c lgStudent = new LG_Student__c();
        lgStudent.Student__c = student.Id;
        lgStudent.LG__c = lg.Id;
        lgStudent.Status_in_LG__c = 'Drop-Out';
        lgStudent.CurrencyIsoCode = 'INR';
        lgStudent.Student_Course_Start_Date__c = System.today().adddays(1);
        lgStudent.Student_Course_End_Date__c = System.today().adddays(7);
        insert lgStudent;
        system.assertEquals(true, lgStudent.id != NULL);
        
        
        Analytics__c analytics = new Analytics__c(
            AccountId__c = acc.Id,
            Actual_students_LKG__c = 5,
            Actual_students_Non_LKG__c   = 2,
            Agreement__c = agree.Id,
            Calculated_Students_LKG__c = 5,
            Calculated_Students_NON_LKG__c = 2,
            Date__c = System.today().addMonths(-1),
            Drop_Out__c   = 1,
            Goals__c = 2,
            Key__c  = 'KEY01',
            MF_ID__c = 'MFID001',
            School_Year__c = String.valueOf(System.today().addYears(-1).year()),
            Type__c  = '1',
            Royalties_Calculation__c = calculation.Id
            
        );
        insert analytics;
        system.assertEquals(true, analytics.id != NULL);
        
        Analytics__c analytics2 = new Analytics__c(
            AccountId__c = acc.Id,
            Actual_students_LKG__c = 5,
            Actual_students_Non_LKG__c   = 2,
            Agreement__c = agree.Id,
            Calculated_Students_LKG__c = 5,
            Calculated_Students_NON_LKG__c = 2,
            Date__c = System.today(),
            Drop_Out__c   = 1,
            Goals__c = 2,
            Key__c  = 'KEY012S',
            MF_ID__c = 'MFID001',
            School_Year__c = String.valueOf(System.today().year()),
            Type__c  = '1',
            Royalties_Calculation__c = calculation.Id
           
            
        );
        insert analytics2;
        system.assertEquals(true, analytics2.id != NULL);
        Test.startTest();
        PageReference pageRef = Page.RsGoalsAchievementsGlobal;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id',acc.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(acc);
        RsGoalsAchievements controller = new RsGoalsAchievements(sc);
        controller.getViewOption();
        controller.ClacParam();
        controller.exportToExcel();
        Test.stopTest();
    }
    
}