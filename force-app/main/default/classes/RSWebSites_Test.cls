/**************************************************************
Name              : RSWebSites test 
Description       : Code Coverage 92% 
Created/Modified by   Created/Modified Date                       
-------------------------------------------------------------
1. Rashad Saeed        19/02/2017                 
*************************************************************/
@isTest
public class RSWebSites_Test {

    @isTest
   private static void test_get(){
      
        Test.startTest();
        RestRequest testRestRequest = new RestRequest();
        RestResponse testRestResponse = new RestResponse();
        Id FranchiseeRecordType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();   
        Id MfRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();   
        Id LcRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId();
        Account Acc= ObjectCreator.getNewAccount();
        insert Acc;
        Acc.RecordTypeId=LcRecordType;
        Acc.BillingCountry='Israel';
        Acc.BillingCity = 'Karmeil';
        
        Contact con = new Contact(recordtypeID = FranchiseeRecordType ,FirstName = 'name', LastName = 'name', AccountId = acc.id,Kangi_User_Name__c='123456',Kangi_Password__c='123456', Status__c ='Active');
        //Contact con1 = new Contact(FirstName = 'name', LastName = 'name', AccountId = acc.id, RecordTypeId = RecordTypeId,Kangi_User_Name__c='Rashad',Kangi_Password__c='saeed');

        insert con ;
        User u = ObjectCreator.getNewUser(con.Id);
        insert u;
        Acc.Partner_Account_User__c = u.id;
        Update Acc;
        Update con;
        //insert con1 ;
        testRestRequest.requestBody = blob.valueOf('{"username" : "123456","password" : "123456","appname" : "Kangi"}');
        testRestRequest.requestURI = '/services/apexrest/RSWebSites/';
        testRestRequest.httpMethod = 'POST';
        RestContext.request = testRestRequest;
        RestContext.response = testRestResponse;
      
        RSWebSites.Dopost();
       
        Test.stopTest();
    }
}