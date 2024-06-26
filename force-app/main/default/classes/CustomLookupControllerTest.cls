/******************************************************************************* 
Name              : CustomLookupControllerTest
Description       : Test Class for CustomLookupController.
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Aparna             11/07/2017                Gidi          
*******************************************************************************/
@isTest
public class CustomLookupControllerTest{
    @isTest
    static void UnitTest1(){
        
        Id studentRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId();
        Id teacherRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();
        Id lgRecordTypeId = Schema.SObjectType.LG__c.getRecordTypeInfosByName().get('HD LG').getRecordTypeId();
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
        baseCurse.Large_Group__c = false;
        baseCurse.Fixed_Number_of_Students__c = false;
        baseCurse.Has_Demo_Lesson__c = true;
        insert baseCurse;
        
        //Insert course sub type
        Course_Sub_Type__c curseSubType = ObjectCreator.getNewCourseSubType(acc.Id, baseCurse.Id); 
        curseSubType.Price_Type__c  = 'Per Group';
        curseSubType.Course_Price__c = 100;
        curseSubType.Price_per_Month__c = 100;
        curseSubType.Price_per_Session__c = 100;
        curseSubType.Number_of_Payments__c = 5;
        curseSubType.Gap_between_Payments__c = 2;
        
        insert curseSubType;
        
        //Insert LG
        LG__c lg = ObjectCreator.getNewLG(acc.Id, curseSubType.Id, agree.Id);
        lg.RecordTypeId = lgRecordTypeId;
        lg.LG_Start_Date__c = System.today();
        lg.Franchisee__c = acc.Id;
        lg.LG_End_Date__c = System.today().addDays(10);
        lg.LG_Type__c   = 'Standard';
        lg.Group_Status__c = 'Active';
        lg.Teacher__c = con2.Id;
        lg.Billing_Type__c = 'Course Price';
        //lg.Declared_Number_of_Students__c = 5;
        lg.Gap_between_Price_Payments__c = 2;
        lg.Number_of_Payments__c = 5;
        lg.Teacher_Permission_on_LG__c = 'Update – can update Attendance, Lessons and Assessments.';
        lg.LG_Start_Paying_Date__c = System.today().addDays(2);
        lg.LG_End_Paying_Date__c = System.today().addDays(5);
        lg.Course_Price__c = 100;
        lg.Price_per_Month__c = 100;
        lg.Price_per_Session__c = 100;
        test.startTest();
        insert lg;
        test.stopTest();
        
        
        //Insert Lg Days and Hours
        LG_Days_Hours__c lgDH = ObjectCreator.getNewLG_Days_Hours(lg.Id);        
        insert lgDH;
        
        //Insert LG Lessons
        LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson(lg.Id, con2.Id, lgDH.Id);
        insert lesson;  
        
        //Insert Contact--Student
        Contact con = new Contact(FirstName = 'Dues', LastName = 'Daniel', AccountId = acc.Id, Status__c = 'Prospect', Email = 'example@mail.co', RecordTypeId = studentRecordTypeId, LG_for_New_Student__c = lg.Id);
        insert con;
        
        User u1 = ObjectCreator.getNewUser(con2.Id);
        u1.Bypass_Automation__c = false;
        insert u1;
        
        //Insert LG Special Price
        Id rt8 = Schema.SObjectType.LG_Discount__c.getRecordTypeInfosByName().get('Requested Discount').getRecordTypeId();
        LG_Discount__c lgdisc = new LG_Discount__c(); 
        lgdisc.RecordTypeId = rt8;
        lgdisc.Discount_Status__c = 'Requested';
        //lgdisc.Special_Price_Applies_to__c = 'Entire Group';
        lgdisc.LG__c = lg.Id;
        lgdisc.Discount_Type__c = 'Entire Course';
        lgdisc.Requested_Course_Price__c = 80;
        lgdisc.Requested_Price_per_Month__c = 80;
        lgdisc.Requested_Price_per_Session__c = 80;
        insert lgdisc;
        //update Lg Special Price
        lgdisc.Requested_Course_Price__c= 20;
        update lgdisc;
        
        List<LG_Discount__c> lstDis = new List<LG_Discount__c>();
        lstDis.add(lgdisc);
        
        //test.startTest();
        ApexPages.currentPage().getParameters().put('parentname','testuser');
        ApexPages.currentPage().getParameters().put('parentid','Test_VF');
        ApexPages.currentPage().getParameters().put('SelectedIds',lgdisc.Id);
        CustomLookupController clc = new CustomLookupController();
        clc.getRecords();
        clc.onkeyupAction();
        //test.stopTest();
    }
}