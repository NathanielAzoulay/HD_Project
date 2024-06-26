@isTest
public class AWSstdContr_Test {
@isTest
private static void AWSstdContr(){

   
       Account acc = new Account(Name = 'test account', BillingCountry = 'France');
       insert acc;
       Contact c= new Contact(AccountId = acc.Id, FirstName = 'TestContactF', LastName = 'TestContactL', Email = 'none@navinet.net');
       insert c;
       insert new AWS_Keys__c(AWS_AccessKey_Id__c = '123',AWS_Secret_Key__c='Testing',Name__c='Helen doron group');
       ApexPages.StandardController sc = new ApexPages.StandardController(C);
       AWSstdContr AWS = NEW AWSstdContr (sc);
    }    
}