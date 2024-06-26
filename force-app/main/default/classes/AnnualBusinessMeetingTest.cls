@isTest
public class AnnualBusinessMeetingTest {
    @isTest static void testAnnualBusinessMeeting() {
        // Create a test account

        ObjectCreator.initializeCustomSetting();
        
        Account acc = ObjectCreator.getNewAccount();
    	acc.Account_Status__c = 'Active';
    	acc.Account_No_in_Infoman__c = 666;
        acc.Email__c = 'test@test.fr';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();
	    insert acc;
        
        // Créer une page avec les paramètres
        PageReference pageRef = Page.AnnualBusinessMeeting; 
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('acountId', acc.Id); 
        
        // Instancier la classe controller
        AnnualBusinessMeeting controller = new AnnualBusinessMeeting();
    }
}