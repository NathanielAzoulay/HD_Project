@isTest
private class Batch_ManageObjectManualSharing_Test {
    
    @isTest(seeAllData=false)
    static void Batch_ManageObjectManualSharing_Test(){
         
        /******* COVERING CUSTOM OBJECT *******/
        String ParentObjAPIName = 'Course_Sub_Type__c';
        String objParentSharingToDelete = 'Course_Sub_Type__Share';
        String objChildSharingToInsert = 'Course_Sub_Type_Sharing__c';
        String ParentLookupFieldAPIName = 'Course_Sub_Type__c';
        String AccountLookupFieldAPIName = 'Account__c';
        //String cause = 'Manual';        
        Base_Course__c bc = new Base_Course__c(Name='Fun with Flupe', Program_Type__c = 'HDE', Status__c = 'Active');
        insert bc;        
        List<Course_Sub_Type__c> List_CourseSubType = new List<Course_Sub_Type__c>();
        // Add all required field for List_CourseSubType
        Course_Sub_Type__c cst = new Course_Sub_Type__c(Name='Course Sub Type Name', Base_Course__c = bc.Id, Course_Price__c = 100,Price_per_Month__c = 1000,Price_per_Session__c=150,Number_of_Payments__c=4,Gap_between_Payments__c=1);
        
        List_CourseSubType.add(cst);
        insert List_CourseSubType;
        
        Account acc = new Account(Name = 'test account', BillingCountry = 'Israel');
        insert acc;
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();
        acc.Account_Type__c = 'MF';
        update acc;
        
        Id typeConId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();
        Contact con = ObjectCreator.getNewContact(acc.Id, typeConId);
        insert con;
        User u = ObjectCreator.getNewUser(con.Id);
        insert u;
        Course_Sub_Type__c cst2 = new Course_Sub_Type__c(Name='Course Sub Type Name', Base_Course__c = bc.Id, Course_Price__c = 100,Price_per_Month__c = 1000,Price_per_Session__c=150,Number_of_Payments__c=4,Gap_between_Payments__c=1, Franchisee_Name__c = acc.Id);
        insert cst2;
        
        /*******CREATE MANUAL SHARING RECORDS ******************/
        
        List<Course_Sub_Type__Share> sharing2Insert = new List<Course_Sub_Type__Share>();
        sharing2Insert.add(new Course_Sub_Type__Share(ParentId = cst2.Id, UserOrGroupId = u.Id, RowCause = 'Manual', AccessLevel = 'Read'));
        insert sharing2Insert;     
        Test.startTest();
        Batch_ManageObjectManualSharing bdt = new Batch_ManageObjectManualSharing(ParentObjAPIName,objParentSharingToDelete, objChildSharingToInsert, ParentLookupFieldAPIName, AccountLookupFieldAPIName);
        Database.executeBatch(bdt,200);
        //SObject obj = bdt.getNewSobject(ParentObjAPIName);
        //Test.stopTest();
        
       /******* COVERING STANDARD OBJECT ********/   
        ParentObjAPIName = 'Account';
        objParentSharingToDelete = 'AccountShare';
        objChildSharingToInsert = 'Course_Sub_Type_Sharing__c';
        ParentLookupFieldAPIName = 'Course_Sub_Type__c';
        AccountLookupFieldAPIName = 'Account__c';
        
        bdt = new Batch_ManageObjectManualSharing(ParentObjAPIName,objParentSharingToDelete, objChildSharingToInsert, ParentLookupFieldAPIName, AccountLookupFieldAPIName);
        Database.executeBatch(bdt,200);    
        
        /******* COVERING EXCEPTION WITH NON_EXIST OBJECT ********/   
        ParentObjAPIName = 'Account';
        objParentSharingToDelete = 'AccountShare';
        objChildSharingToInsert = 'Course_Sub_Type_Sharing_c';
        ParentLookupFieldAPIName = 'Course_Sub__c';
        AccountLookupFieldAPIName = 'Account__c';
        try{
            bdt = new Batch_ManageObjectManualSharing(ParentObjAPIName,objParentSharingToDelete, objChildSharingToInsert, ParentLookupFieldAPIName, AccountLookupFieldAPIName);
        }
        catch(Exception ex){
           system.debug(' ex==' +ex.getMessage());
        }          
        Test.stopTest();
        Database.executeBatch(bdt,200);        
        
    }
}