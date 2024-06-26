@isTest
public class RsProps_Test {
    @isTest
    private static void test_Teacher(){
         Test.startTest();
        RestRequest testRestRequest = new RestRequest();
        RestResponse testRestResponse = new RestResponse();
      
        Account Acc= ObjectCreator.getNewAccount();
        insert Acc;
        Id RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();
        Contact con = new Contact(Status__c='Active',Kangi_Status__c='Active',FirstName = 'name', LastName = 'name', AccountId = acc.id, RecordTypeId = RecordTypeId,Kangi_User_Name__c='123456',Kangi_Password__c='123456');
        //Contact con1 = new Contact(FirstName = 'name', LastName = 'name', AccountId = acc.id, RecordTypeId = RecordTypeId,Kangi_User_Name__c='Rashad',Kangi_Password__c='saeed');

        insert con ;
        con.Kangi_Password__c ='123456';
        con.Kangi_User_Name__c ='123456';
        con.Status__c = 'Not Active';
        Update con;
        //insert con1 ;
        testRestRequest.requestBody = blob.valueOf('{"username" : "123456","password" : "123456","appname" : "Kangi"}');
        testRestRequest.requestURI = '/services/apexrest/RsProps/';
        testRestRequest.httpMethod = 'POST';
        RestContext.request = testRestRequest;
        RestContext.response = testRestResponse;
      
        RsProps.doPost('123456',null, 'appname');
        RsProps.doPost(null,'123456', 'appname');
        RsProps.doPost('123456','123456', null);
        RsProps.doPost('123456','123456', 'Props');
        RsProps.doPost('Rashad','saeed', 'Props');
        RsProps.doPost('123456','saeed1', 'Props');
        Test.stopTest();
    }
}