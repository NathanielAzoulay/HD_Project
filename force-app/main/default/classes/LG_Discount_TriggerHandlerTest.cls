/******************************************************************************* 
Name              : LG_Discount_TriggerHandlerTest
Description       : Contains the test methods of all triggers on LG Discount object
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Nicolas                   03/07/2016              
*******************************************************************************/
@isTest
private class LG_Discount_TriggerHandlerTest {

    /******************************************************************************* 
    Description       : Populate fields before duplicatecheck
                        1) Update LG Code before insert and when edited
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. Nicolas              03/07/2016          Ella  Bernachik             [SW-18074]
    2. Nicolas              03/14/2016          Ella  Bernachik             [SW-18074]
    *******************************************************************************/
    @isTest(seeAllData=false)
    static void updateLGPaymentWhenLGDiscountIsApproved_test(){

        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

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
        
        // Validating the trigger logic of auto populate field 'LG_Code__c'.
        system.assertEquals(lgDisc_DB.LG_Student__r.Name, lgDisc_DB.LG_Student_Code__c);
        
        lgDisc.Discount_Status__c = 'Approved';
        update lgDisc;
        
        test.stopTest();
    }
}