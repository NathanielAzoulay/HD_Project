@isTest
private class Batch_AverageExchangeRate_Test {
	@isTest(seeAllData=false) 
    static void Test01() {
        Average_Exchange_Rate__c aer1 = new Average_Exchange_Rate__c(To_Currency__c = 'USD', Exchange_Rate_Start_Date__c = system.today().addMonths(-1).toStartOfMonth());
        Average_Exchange_Rate__c aer2 = new Average_Exchange_Rate__c(To_Currency__c = 'EUR', Exchange_Rate_Start_Date__c = system.today().addMonths(-1).toStartOfMonth());
        insert new List<Average_Exchange_Rate__c>{aer1, aer2};
        
        Batch_AverageExchangeRate b = new Batch_AverageExchangeRate();
        database.executeBatch(b);
    }
    
    @isTest(seeAllData=false) 
    static void Sched_AverageExchangeRate_Test() {        
        Test.startTest();
        String jobId = System.schedule('testBasicScheduledApex', '0 0 0 3 9 ? 2042', new Sched_AverageExchangeRate());
        Test.stopTest();        
    }
}