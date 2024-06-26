@isTest
public class AWS_Upload_Test {
@isTest
private static void AWS_Upload(){

   
       Account acc = new Account(Name = 'test account', BillingCountry = 'France');
       insert acc;
       Contact c= new Contact(AccountId = acc.Id, FirstName = 'TestContactF', LastName = 'TestContactL', Email = 'none@navinet.net');
       insert c;
       insert new AWS_Keys__c(AWS_AccessKey_Id__c = '123',AWS_Secret_Key__c='Testing',Name__c='Helen doron group');
       PageReference pageRef = ApexPages.currentPage();
       pageRef.getParameters().put('parentIdForRedirect',c.id); 
       AWS_Upload aws = new AWS_Upload (); 
       AWS.getPolicy();
       aws.getSignedPolicy();
       AWS_Upload.createNewDocument(C.ID, 'uploadedFilename', 'bucketName');
    }    
}