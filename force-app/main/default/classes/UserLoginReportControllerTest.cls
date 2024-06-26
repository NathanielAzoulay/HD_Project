@isTest
private class UserLoginReportControllerTest {
  /******************************************************************************* 
  Name              : UserLoginReportControllerTest 
  Description       : 
  Revision History  :-
  Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
  ----------------------------------------------------------------------------------------
  1. Aparna             26/06/2017                Rashad Saeed
  *******************************************************************************/
  @isTest(seeAllData=false)
    static void UnitTest1(){
        test.startTest();
        Account acc = ObjectCreator.getNewAccount();
        insert acc;
        
        Contact cont = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId());              
        insert cont;
        
        //user u = ObjectCreator.getNewUser(cont.Id);
        Id partnerCommunityProfile = [SELECT Id FROM Profile WHERE Name='HDC MF Logistic'].Id;
        User user = new User(alias = 'CFMUser', email='CFMUserTest@noemail.com',
                emailencodingkey='UTF-8', lastname='CFMUserTest', languagelocalekey='en_US',
                localesidkey='en_US', profileid = partnerCommunityProfile, country='United States',IsActive =true,
                ContactId = cont.Id,
                timezonesidkey='America/Los_Angeles', username='CFMUserTest@noemail.com');
    
        insert user;
        
        UserLoginReportController userLRC = new UserLoginReportController (); 
        
    
        test.stopTest();
    }
}