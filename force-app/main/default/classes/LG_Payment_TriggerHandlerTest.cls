/******************************************************************************* 
Name              : LG_Payment_TriggerHandlerTest
Description       : Contains the test methods of all triggers on LG Payment object
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Nicolas                   03/08/2016              
*******************************************************************************/
@isTest
private class LG_Payment_TriggerHandlerTest {
    
    @isTest(seeAllData=false) 
    static void updateLGStudentPaymentOnInserth_test(){
        
        Account acc = ObjectCreator.getNewAccount();
        insert acc;

        Account lc = ObjectCreator.getNewAccount();
        lc.Name = 'lc test';
        insert lc;

        Agreement__c agree = ObjectCreator.getNewAgreement(acc.Id);             
        insert agree;

        Base_Course__c baseCurse = ObjectCreator.getNewBaseCourse();     
        baseCurse.Fixed_Number_of_Students__c = true;           
        insert baseCurse;

        Course_Sub_Type__c curseSubType = ObjectCreator.getNewCourseSubType(acc.Id, baseCurse.Id);   
        curseSubType.Price_Type__c = 'Per Group';           
        insert curseSubType;

        LG__c lg = ObjectCreator.getNewLG(acc.Id, curseSubType.Id, agree.Id);
        lg.Franchisee__c = lc.Id;      
        lg.Declared_Number_of_Students__c = 10; 
        insert lg;

        LG_Days_Hours__c lgDH = ObjectCreator.getNewLG_Days_Hours(lg.Id);
        insert lgDH;
        
        
        LG_Payment__c payment = new LG_Payment__c();
        payment.LG__c = lg.Id;
        payment.Payment_Type__c = 'Standard';
        payment.Planned_Date__c = system.today();
        insert payment;
    }
    
    @isTest(seeAllData=false) 
    static void CreateGroupIncomePerMonth_test(){
        
        Account acc = ObjectCreator.getNewAccount();
        insert acc;

        Account lc = ObjectCreator.getNewAccount();
        lc.Name = 'lc test';
        insert lc;

        Contact studentContact = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId());              
        insert studentContact;
        
        Agreement__c agree = ObjectCreator.getNewAgreement(acc.Id);             
        insert agree;

        Base_Course__c baseCurse = ObjectCreator.getNewBaseCourse();                
        insert baseCurse;

        Course_Sub_Type__c curseSubType = ObjectCreator.getNewCourseSubType(acc.Id, baseCurse.Id);              
        insert curseSubType;

        LG__c lg = ObjectCreator.getNewLG(acc.Id, curseSubType.Id, agree.Id);
        lg.Franchisee__c = lc.Id;       
        insert lg;

        LG_Days_Hours__c lgDH = ObjectCreator.getNewLG_Days_Hours(lg.Id);
        insert lgDH;
        
        test.startTest();
        
        LG_Student__c student = new LG_Student__c( LG__c = lg.Id, Student__c = studentContact.Id );
        insert student;
        
        LG_Payment__c payment = new LG_Payment__c();
        payment.LG__c = lg.Id;
        payment.Payment_Type__c = 'Standard';
        payment.Planned_Date__c = system.today();
        payment.LG_Student__c = student.Id;
        payment.Student__c = studentContact.Id;
        insert payment;
                    
        LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson(lg.Id, null, lgDH.Id);                      
        insert lesson;

        LG_Payment__c payment2 = ObjectCreator.getNewLGPayment(lg.Id, student.Id, studentContact.Id);
        insert payment2;        
        
        LG_Student_Attendance__c studentAtt = ObjectCreator.getNewStudentAttendance(lesson.Id, student.Id);
        studentAtt.LG_Payment__c = payment.Id;
        insert studentAtt;

        test.stopTest();  
    }

    @isTest(seeAllData=false) 
    static void deleteIncomeGroupOnPaymentDel_Test(){
        
        Account acc = ObjectCreator.getNewAccount();
        insert acc;

        Account lc = ObjectCreator.getNewAccount();
        lc.Name = 'lc test';
        insert lc;

        Contact studentContact = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId());              
        insert studentContact;
        
        Agreement__c agree = ObjectCreator.getNewAgreement(acc.Id);             
        insert agree;

        Base_Course__c baseCurse = ObjectCreator.getNewBaseCourse();                
        insert baseCurse;

        Course_Sub_Type__c curseSubType = ObjectCreator.getNewCourseSubType(acc.Id, baseCurse.Id);              
        insert curseSubType;

        LG__c lg = ObjectCreator.getNewLG(acc.Id, curseSubType.Id, agree.Id);
        lg.Franchisee__c = lc.Id;       
        insert lg;

        test.startTest();
        
        LG_Days_Hours__c lgDH = ObjectCreator.getNewLG_Days_Hours(lg.Id);
        insert lgDH;
        
        LG_Student__c student = new LG_Student__c( LG__c = lg.Id, Student__c = studentContact.Id );
        insert student;
        
        LG_Payment__c payment = new LG_Payment__c();
        payment.LG__c = lg.Id;
        payment.Payment_Type__c = 'Standard';
        payment.Planned_Date__c = system.today();
        payment.LG_Student__c = student.Id;
        payment.Student__c = studentContact.Id;
        insert payment;

        System.assert([SELECT Id FROM Group_Income_Per_Month__c WHERE LG_Payment__c = :payment.Id AND RecordTypeId =:Schema.SObjectType.Group_Income_Per_Month__c.getRecordTypeInfosByName().get('Price').getRecordTypeId()].size() == 1);

        delete payment;

        System.assert([SELECT Id FROM Group_Income_Per_Month__c WHERE LG_Payment__c = :payment.Id AND RecordTypeId =:Schema.SObjectType.Group_Income_Per_Month__c.getRecordTypeInfosByName().get('Price').getRecordTypeId()].size() == 0);
        
        test.stopTest();  
        
    }

    @isTest(seeAllData=false)
    static void updateLGPaymentWhenLGDiscountIsApproved_test(){

        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        HD_TriggerSettings.disableTriggersFromTest.remove('updateLGStudentPaymentOnInsert');

        Account accParent = new Account(Id = testEnv.lcId);
        accParent.Partner_Account_User__c = UserInfo.getUserId();
        update accParent;
        
        Account acc = new Account(Id = testEnv.accId);
        acc.ParentId = testEnv.lcId;
        update acc;

        Contact studentContact2 = ObjectCreator.getNewContact(testEnv.accId, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId());              
        insert studentContact2;             

        LG__c lg = new LG__c(Id = testEnv.lgId);
        lg.Franchisee__c = acc.Id;       
        update lg;
        
        lg.Price_per_Session__c = 12;
        lg.Price_per_Month__c  = 1;
        lg.Course_Price__c  = 1;
        lg.Gap_between_Price_Payments__c = 2;
        update lg;
        
        Test.startTest();
        
        LG_Student__c student2 = ObjectCreator.getNewLGStudent(studentContact2.Id, lg.Id);
        student2.Number_of_Payments__c = null;
        student2.Approved_Price__c = 1; 
        student2.Student_Start_Paying_Date__c = system.today();
        student2.Billing_Type__c = 'Price per Session';
        insert new List<LG_Student__c>{student2};
        
        LG_Payment__c payment = ObjectCreator.getNewLGPayment(testEnv.lgId, testEnv.studentId, testEnv.studentContactId);
        insert payment;
        
        LG_Student__c st = new LG_Student__c(Id = testEnv.studentId);
        st.Billing_Type__c = 'Price per Session';
        update st; 

        Contact con = new Contact(Id = testEnv.studentContactId);
        con.Student_Billing_Type__c= 'Course Price';
        update con;
        
        LG_Discount__c lgDisc = ObjectCreator.getNewLGDiscount(student2.Id, lg.Id);
        lgDisc.Requested_Price_per_Session__c = 3;
        lgDisc.Approved_Price_per_Session__c = 1;
        lgDisc.Discount_Type__c = 'Entire Course';
        lgDisc.Approved_Course_Price__c = null;
        lgDisc.Requested_Course_Price__c = null;
        insert lgDisc;

        LG_Days_Hours__c lgDH = ObjectCreator.getNewLG_Days_Hours(lg.Id);
        insert lgDH;

        LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson(lg.Id, null, lgDH.Id);                      
        insert lesson;

        LG_Student_Attendance__c studentAtt = ObjectCreator.getNewStudentAttendance(lesson.Id, st.Id);
        studentAtt.LG_Payment__c = payment.Id;
        insert studentAtt;
        
        //LG__c lg_DB = [SELECT LG_Code__c FROM LG__c WHERE Id =: lg.Id];
        LG_Discount__c  lgDisc_DB = [SELECT Billing_Type__c, LG_Student_Code__c, LG_Student__r.Name FROM LG_Discount__c WHERE Id =: lgDisc.Id];
        
        lgDisc_DB.Approved_Course_Price__c = 1;
        lgDisc_DB.Approved_Price_per_Month__c = 1;
        lgDisc_DB.Approved_Price_per_Session__c = 1;
        
        Course_Sub_Type__c curseSubType = new Course_Sub_Type__c(Id = testEnv.curseSubTypeId, Price_Type__c = 'Per Student');
        update curseSubType;
        
        LG__c newLG = [SELECT Price_for_Payment__c, Price_Type__c FROM LG__C WHERE Id =: lg.Id];  
        newLG.Declared_Number_of_Students__c = null;
        newLG.Number_of_Payments__c = 10;
        
        LG_Payment_TriggerHandler.testValue4testMethod = 'Course Price';
        LG_Payment_TriggerHandler.discountValue(lgDisc_DB, newLG, 'Course Price', 1, 1); 
        
        LG_Payment_TriggerHandler.testValue4testMethod = 'Price per Month';
        LG_Payment_TriggerHandler.discountValue(lgDisc_DB, newLG, 'Price per Month', 1, 1);
        
        LG_Payment_TriggerHandler.testValue4testMethod = 'Price per Session';
        LG_Payment_TriggerHandler.discountValue(lgDisc_DB, newLG, 'Price per Session', 1, 1);
        
        newLG.Declared_Number_of_Students__c = 10;
        
        LG_Payment_TriggerHandler.testValue4testMethod = 'Course Price';
        LG_Payment_TriggerHandler.discountValue(lgDisc_DB, newLG, 'Course Price', 1, 1); 
        
        LG_Payment_TriggerHandler.testValue4testMethod = 'Price per Month';
        LG_Payment_TriggerHandler.discountValue(lgDisc_DB, newLG, 'Price per Month', 1, 1);
        
        LG_Payment_TriggerHandler.testValue4testMethod = 'Price per Session';
        LG_Payment_TriggerHandler.discountValue(lgDisc_DB, newLG, 'Price per Session', 1, 1);
        
        lgDisc_DB.Discount_Type__c = 'Entire Course';
                
        LG_Payment_TriggerHandler.testValue4testMethod = 'Course Price';
        LG_Payment_TriggerHandler.discountValue(lgDisc_DB, newLG, 'Course Price', 1, 1); 
        
        LG_Payment_TriggerHandler.testValue4testMethod = 'Price per Month';
        LG_Payment_TriggerHandler.discountValue(lgDisc_DB, newLG, 'Price per Month', 1, 1);
        
        LG_Payment_TriggerHandler.testValue4testMethod = 'Price per Session';
        LG_Payment_TriggerHandler.discountValue(lgDisc_DB, newLG, 'Price per Session', 1, 1);
        
        test.stopTest();
    }
}