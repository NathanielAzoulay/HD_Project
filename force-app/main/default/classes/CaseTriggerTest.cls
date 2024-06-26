/**************************************************************
Name              : CaseTriggerTest 
Description       : test class for trigger on case 
Created/Modified by   Created/Modified Date                       
-------------------------------------------------------------
1. Rashad Saeed        18/1/2017                 
*************************************************************/
@isTest(seeAllData = false)
public class CaseTriggerTest {
  public static testMethod void testTrigger() {
      
      Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
      
      User u = new User(Alias = 'standt', Email='1@1.com', 
      EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
      LocaleSidKey='en_US', ProfileId = p.Id, 
      TimeZoneSidKey='America/Los_Angeles', UserName='HDCRashad@HDCRashad.com');
      Case c = new Case (Status = 'New');
     
      //user ruser = [select Id from user where IsActive = true And Id <> userinfo.getUserId()]; 
      System.runAs(u) {
          test.startTest();
          insert c ;

    }
    C.Agent_Status__c ='Resolved'; 
    c.OwnerId =  userinfo.getUserId();
    Update C;  
  }
}