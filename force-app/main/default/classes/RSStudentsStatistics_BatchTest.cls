/*--------------------------------------------------------------------------------------------------------
Name:            RSStudentsStatistics_BatchTest.cls
Description:     Test class for RSStudentsStatistics_Batch.cls
----------------------------------------------------------------------------------------------------------
Date             Author          Summary of Changes 
----------------------------------------------------------------------------------------------------------
06-Feb-2018     Shivram Saini    Initial Implementation 
----------------------------------------------------------------------------------------------------------*/
@isTest
public class RSStudentsStatistics_BatchTest {
  @isTest
    static void testExcecuteBatchMethod(){
        Id studentRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId();
        Id teacherRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();
        //Insert Account
         Account acc = ObjectCreator.getNewAccount();
    insert acc;
        
        //Insert Contact--Teacher
        Contact con2 = new Contact(FirstName = 'Dues',LastName = 'Daniel', AccountId = acc.Id, Status__c = 'Prospect', Email = 'example@mail.co', RecordTypeId = teacherRecordTypeId, Teacher__c = true);
        insert con2;
        
        
        //Insert Agreement
        Agreement__c agree = ObjectCreator.getNewAgreement(acc.Id);        
    insert agree;
        
        //Insert Base Course
    Base_Course__c baseCurse = ObjectCreator.getNewBaseCourse();
        baseCurse.Large_Group__c = true;
    insert baseCurse;
    
        //Insert course sub type
    Course_Sub_Type__c curseSubType = ObjectCreator.getNewCourseSubType(acc.Id, baseCurse.Id);        
    insert curseSubType;
    
        //Insert LG
        LG__c lg = ObjectCreator.getNewLG(acc.Id, curseSubType.Id, agree.Id);
    lg.LG_Start_Date__c = System.today();
    lg.LG_End_Date__c = System.today().addDays(10);
        lg.Teacher__c = con2.Id;
        
        insert lg;
    
        LG__c lg2 = ObjectCreator.getNewLG(acc.Id, curseSubType.Id, agree.Id);
    lg2.LG_Start_Date__c = System.today().addYears(-1);
    lg2.LG_End_Date__c = System.today().addYears(-1).addDays(25);
        lg2.Teacher__c = con2.Id;
        insert lg2;
        
        LG_Days_Hours__c lgDH = ObjectCreator.getNewLG_Days_Hours(lg.Id);        
    insert lgDH;
        
        LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson(lg.Id, con2.Id, lgDH.Id);
        insert lesson;  
        
        //Insert Contact--Student
        Contact con = new Contact(FirstName = 'Dues', LastName = 'Daniel', AccountId = acc.Id, Status__c = 'Prospect', Email = 'example@mail.co', RecordTypeId = studentRecordTypeId, Last_LG__c = lg2.Id, LG_for_New_Student__c = lg.Id);
        insert con;
        
        //Insert LG Student
        LG_Student__c lgStudent = new LG_Student__c();
        lgStudent.Student__c = con.Id;
        lgStudent.LG__c = lg.Id;
        lgStudent.Status_in_LG__c = 'Signed for Demo';
        lgStudent.CurrencyIsoCode = 'INR';
        lgStudent.Student_Course_Start_Date__c = System.today().adddays(1);
        lgStudent.Student_Course_End_Date__c = System.today().adddays(7);
    insert lgStudent;
        
        LG_Student__c student = ObjectCreator.getNewLGStudent(con.Id, lg.Id);
        student.Approved_Price__c = 22;
        //student.Lesson_Type__c = 'Standard';
        student.Status_in_LG__c = 'Signed for Demo';
        student.Student_Start_Paying_Date__c = System.today();
        insert student;
        
        Test.startTest();
        LG_Student__c student3 = ObjectCreator.getNewLGStudent(con.Id, lg.Id);
        student3.Approved_Price__c = 25;
        //student.Lesson_Type__c = 'Standard';
        student3.Status_in_LG__c = 'Registered';
        student3.Student_Start_Paying_Date__c = System.today().addDays(2); 
        insert student3;
        //Execute Batch
        RSStudentsStatistics_Batch uca = new RSStudentsStatistics_Batch();
        Id batchId = Database.executeBatch(uca,1);
        Test.stopTest();        
          
    }
}