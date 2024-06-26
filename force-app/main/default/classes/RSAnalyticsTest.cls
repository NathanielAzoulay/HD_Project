/****
Name:            RSAnalyticsTest.cls
Description:     Test class for RSAnalytics.cls
Date             19-Feb-2018             
Created By:       Shivram Saini 
*/
@isTest
public class RSAnalyticsTest {
  @isTest
    static void testExecuteMethod(){
        Id teacherRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();
        Id studentRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId();
        Id Calculated_Student = Schema.SObjectType.Group_Income_Per_Month__c.getRecordTypeInfosByName().get('Calculated Student').getRecordTypeId();
      //Insert Account
      Account acc = ObjectCreator.getNewAccount();
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId();
        acc.Account_Type__c = 'LCF';
    insert acc;
        
        //Insert Agreement
        Agreement__c agree = ObjectCreator.getNewAgreement(acc.Id);  
        agree.School_Year_Start_Month__c  = System.today().month();
    insert agree;
        
        //Insert Base Course
    Base_Course__c baseCurse = ObjectCreator.getNewBaseCourse();
        baseCurse.Large_Group__c = true;
        baseCurse.Fixed_Number_of_Students__c = true;
    insert baseCurse;
    
        //Insert course sub type
    Course_Sub_Type__c curseSubType = ObjectCreator.getNewCourseSubType(acc.Id, baseCurse.Id);        
    insert curseSubType;
        
        //Insert Contact--Teacher
        Contact teacher = new Contact(FirstName = 'Dues',LastName = 'Daniel', AccountId = acc.Id, Status__c = 'Prospect', Email = 'example@mail.co', RecordTypeId = teacherRecordTypeId, Teacher__c = true);
        insert teacher;
        
        //Insert Contact--Student
        Contact student = new Contact(FirstName = 'Dues',LastName = 'Daniel', AccountId = acc.Id, Status__c = 'Prospect', Email = 'example@mail.co', RecordTypeId = studentRecordTypeId);
        insert student;
        
        //Insert Agreement Goals
        Agreement_Goal__c goal = new Agreement_Goal__c(
          Agreement__c = agree.Id,
            Goal_Type__c = 'Students Goal',
            Goal__c = 5,
            Start_Date__c = System.today()
        );
      insert goal;
        
        //Insert Royalties_Calculation__c
        Royalties_Calculation__c calculation = new Royalties_Calculation__c(
          Agreement__c = agree.Id,
            From_Franchisee__c   = acc.Id,
            Royalty_Month__c = System.today()
             
        );
        insert calculation;
        
        //Insert Analytics
        Analytics__c analytics = new Analytics__c(
          AccountId__c = 'AC001',
            Actual_students_LKG__c = 5,
            Actual_students_Non_LKG__c   = 2,
            Agreement__c = agree.Id,
            Calculated_Students_LKG__c = 5,
            Calculated_Students_NON_LKG__c = 2,
            Date__c = System.today(),
            Drop_Out__c   = 1,
            Goals__c = 2,
            Key__c  = 'KEY01',
            MF_ID__c = 'MFID001',
            School_Year__c = String.valueOf(System.today().year()),
            Type__c  = '1',
            Royalties_Calculation__c = calculation.Id
            
        );
        insert analytics;
        
        //Insert LG
        LG__c lg = ObjectCreator.getNewLG(acc.Id, curseSubType.Id, agree.Id);
    lg.LG_Start_Date__c = System.today();
    lg.LG_End_Date__c = System.today().addDays(10);
        lg.Teacher__c = teacher.Id;
        //lg.Declared_Number_of_Students__c = 4;
        insert lg;
        
        LG__c lg2 = ObjectCreator.getNewLG(acc.Id, curseSubType.Id, agree.Id);
    lg2.LG_Start_Date__c = System.today();
    lg2.LG_End_Date__c = System.today().addDays(10);
        lg.Teacher__c = teacher.Id;
        lg2.Declared_Number_of_Students__c = 4;
        insert lg2;
        
        LG_Days_Hours__c lgDH = ObjectCreator.getNewLG_Days_Hours(lg.Id);        
    insert lgDH;
        
        LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson(lg.Id, teacher.Id, lgDH.Id);
        insert lesson;
        
        //Insert Group_Income_Per_Month__c
        Group_Income_Per_Month__c income = ObjectCreator.getNewGroupIncomePerMonth(agree.Id, lg.Id);
        income.Royalty_Start_Date__c = System.today();
        income.RecordTypeId = Calculated_Student;
        income.Student__c = student.Id;
        insert income;
        
        Group_Income_Per_Month__c income2 = ObjectCreator.getNewGroupIncomePerMonth(agree.Id, lg2.Id);
        income2.Royalty_Start_Date__c = System.today();
        income2.RecordTypeId = Calculated_Student;
        income2.Student__c = student.Id;
        insert income2;
        
        //Insert LG Student
        LG_Student__c lgStudent = new LG_Student__c();
        lgStudent.Student__c = student.Id;
        lgStudent.LG__c = lg.Id;
        lgStudent.Status_in_LG__c = 'Drop-Out';
        lgStudent.CurrencyIsoCode = 'INR';
        lgStudent.Student_Course_Start_Date__c = System.today().adddays(1);
        lgStudent.Student_Course_End_Date__c = System.today().adddays(7);
    insert lgStudent;
        
        Test.startTest();
        RSAnalytics uca = new RSAnalytics();
        Id batchId = Database.executeBatch(uca,1);
        Test.stopTest();        
        
        
    }
}