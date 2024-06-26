@isTest
public class AccountInfoPage_Test {

   @isTest static void testAccountInfo() {

    ObjectCreator.initializeCustomSetting();
        
        Account acc = ObjectCreator.getNewAccount();
    	acc.Account_Status__c = 'Active';
    	acc.Account_No_in_Infoman__c = 666;
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();
	    insert acc;
        
        // Créer une page avec les paramètres
        PageReference pageRef = Page.HDCAccountInfo;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('acountId', acc.Id); // Remplacez "acountId" par la clé de paramètre correcte
        
        // Instancier la classe controller
        AccountInfoPage controller = new AccountInfoPage();
    }
}