@IsTest public with sharing class ContactTransferOwnership_CtrlTest{
    @IsTest(SeeAllData=false) 
    public static void ContactTransferOwnership_CtrlTest() {
        Account acc = ObjectCreator.getNewAccount();
        acc.Partner_Account_User__c = userinfo.getUserId();
        insert acc;
        
        Contact con  = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert con;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(con);
        ContactTransferOwnership_Ctrl controller = new ContactTransferOwnership_Ctrl(sc);
        //Test Fail Scenario, because no Account is being assigned.
        controller.Save();
        
        //Test Success Scenario.
        controller.contact.Transfer_to_Franchise__c = acc.Id;
        controller.Save();
    }
}