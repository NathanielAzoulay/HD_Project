@isTest
public class RunRSRoyaltyCalculationBatchTest { 
    static testMethod void testRunBatchMethod() {
       Account acc = new Account(Name = 'Test Record',
                                 Account_Type__c = 'Acting MF',
                                 Account_Status__c = 'Prospect',
                                 CurrencyIsoCode = 'EUR',
                                 BillingCountry = 'India'
                                ); 
        insert acc;
        Test.setCurrentPage(Page.RunRSRoyaltyCalculationBatchVF);
        RunRSRoyaltyCalculationBatch controller = new RunRSRoyaltyCalculationBatch();
        controller.runBatch();
        controller.con.accountId= acc.Id;
        controller.reGenerate = true;
        controller.runBatch();
         
    }

}