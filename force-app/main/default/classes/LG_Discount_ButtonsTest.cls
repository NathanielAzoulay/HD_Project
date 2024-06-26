/******************************************************************************* 
Name              : LG_Buttons
Description       : Contains general Methods for buttons on LG Discount object 
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan                   02/07/2017              
*******************************************************************************/
@isTest
private class LG_Discount_ButtonsTest {

    @isTest(seeAllData=false)
    static void approveDiscounts_test(){

        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

        insert new HD_Settings_List__c(Name = 'Approve_Zero_Monthly_Payment_Profiles', Value__c = String.valueOf(Userinfo.getProfileId()));
            
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
        
        lg.Price_per_Session__c = 0;
        lg.Price_per_Month__c  = 1;
        lg.Course_Price__c  = 1;
        lg.Gap_between_Price_Payments__c = 2;
        update lg;
        
        Test.startTest();
        
        LG_Student__c student2 = ObjectCreator.getNewLGStudent(studentContact2.Id, lg.Id);
        student2.Number_of_Payments__c = null;
        student2.Approved_Price__c = 1; 
        student2.Student_Start_Paying_Date__c = system.today();
        insert new List<LG_Student__c>{student2};

        LG_Student__c st = new LG_Student__c(Id = testEnv.studentId);
        st.Billing_Type__c = 'Price per Month';
        update st;
        
        LG_Payment__c payment = ObjectCreator.getNewLGPayment(testEnv.lgId, testEnv.studentId, testEnv.studentContactId);
        insert payment;
        
        LG_Discount__c lgDisc = ObjectCreator.getNewLGDiscount(testEnv.studentId, lg.Id);
        lgDisc.Requested_Price_per_Month__c = 0;
        lgDisc.Requested_Price_per_Session__c = 0;
        lgDisc.Requested_Course_Price__c = 1;
        insert lgDisc;
        
        //LG__c lg_DB = [SELECT LG_Code__c FROM LG__c WHERE Id =: lg.Id];
        LG_Discount__c  lgDisc_DB = [SELECT /*LG_Code__c*/ LG_Student_Code__c, LG_Student__r.Name FROM LG_Discount__c WHERE Id =: lgDisc.Id];
        
        LG_Discount_Buttons.approveDiscounts(lgDisc_DB.id);
        
        test.stopTest();
        
        delete [SELECT Id FROM HD_Settings_List__c WHERE Name = 'Approve_Zero_Monthly_Payment_Profiles' LIMIT 1] ;
        
        LG_Discount_Buttons.approveDiscounts(lgDisc_DB.id);
    }
    
    @isTest(seeAllData=false)
    static void rejectDiscounts_test(){

        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

        insert new HD_Settings_List__c(Name = 'Reject_Zero_Monthly_Payment_Profiles', Value__c = String.valueOf(Userinfo.getProfileId()));

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
        
        lg.Price_per_Session__c = 1;
        lg.Price_per_Month__c  = 1;
        lg.Course_Price__c  = 1;
        lg.Gap_between_Price_Payments__c = 2;
        update lg;
        
        Test.startTest();
        
        LG_Student__c student2 = ObjectCreator.getNewLGStudent(studentContact2.Id, lg.Id);
        student2.Number_of_Payments__c = null;
        student2.Approved_Price__c = 1; 
        student2.Student_Start_Paying_Date__c = system.today();
        insert new List<LG_Student__c>{student2};

        LG_Student__c st = new LG_Student__c(Id = testEnv.studentId);
        st.Billing_Type__c= 'Course Price';
        update st;
        
        LG_Payment__c payment = ObjectCreator.getNewLGPayment(testEnv.lgId, testEnv.studentId, testEnv.studentContactId);
        insert payment;
        
        LG_Discount__c lgDisc = ObjectCreator.getNewLGDiscount(testEnv.studentId, lg.Id);
        insert lgDisc;
        
        //LG__c lg_DB = [SELECT LG_Code__c FROM LG__c WHERE Id =: lg.Id];
        LG_Discount__c  lgDisc_DB = [SELECT /*LG_Code__c*/ LG_Student_Code__c, LG_Student__r.Name FROM LG_Discount__c WHERE Id =: lgDisc.Id];
        
        LG_Discount_Buttons.rejectDiscounts(lgDisc_DB.id);
        
        test.stopTest();
        
        delete [SELECT Id FROM HD_Settings_List__c WHERE Name = 'Reject_Zero_Monthly_Payment_Profiles' LIMIT 1];
        LG_Discount_Buttons.rejectDiscounts(lgDisc_DB.id);
    }
}