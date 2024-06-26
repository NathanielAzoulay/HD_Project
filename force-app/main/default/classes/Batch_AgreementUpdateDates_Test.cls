@isTest
private class Batch_AgreementUpdateDates_Test {
    @isTest(seeAllData=false)
    static void Batch_AgreementUpdateDates_Test() {
		ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

		Agreement__c agree = new Agreement__c(Id = testEnv.agreeId);
		agree.Agreement_Status__c = 'Active';
		agree.Due_Date_Q1__c = Date.newInstance(System.today().addYears(-1).year(), 2, 1);
		agree.Due_Date_Q2__c = System.today().addYears(-1);
		agree.Due_Date_Q3__c = System.today().addYears(-1);
		agree.Due_Date_Q4__c = System.today().addYears(-1);
        agree.Expiry_Date__c = system.today().addDays(1);
		update agree;

        Test.startTest();
            HD_Log__c hd =  new HD_Log__c(Process_Name__c = 'Batch_AgreementUpdateDates', Error_Description__c = 'Test', Status__c = 'Fail');
            Batch_AgreementUpdateDates b = new Batch_AgreementUpdateDates();
            b.errorLogs = new List<HD_Log__c>{hd};
            Database.executeBatch(b,10);

        Test.stopTest();

        agree = [SELECT Due_Date_Q1__c, Due_Date_Q2__c, Due_Date_Q3__c, Due_Date_Q4__c FROM Agreement__c WHERE Id = :agree.Id];
        System.assertEquals(System.today().year(), agree.Due_Date_Q1__c.year());
        System.assertEquals(System.today().year(), agree.Due_Date_Q2__c.year());
        System.assertEquals(System.today().year(), agree.Due_Date_Q3__c.year());
        if( System.today() > agree.Due_Date_Q1__c){
            System.assertEquals(System.today().year() + 1, agree.Due_Date_Q4__c.year());
        }else{
            System.assertEquals(System.today().year() , agree.Due_Date_Q4__c.year());
        }

        //Batch_AgreementUpdateDates.runBatchProcess();

    }
}