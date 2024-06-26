@isTest
private class Franchisee_VAT_TriggerHandler_Test {

	@isTest(seeAllData=false)
	static void updatePaymentOnVatChange_Test(){

		ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

        LG_Payment__c payment = ObjectCreator.getNewLGPayment(testEnv.lgId, testEnv.studentId, testEnv.studentContactId);
        insert payment;

        Test.startTest();

		Franchisee_VAT__c franchiseeVat = ObjectCreator.getNewFranchiseeVat(testEnv.lcId, 11);
		insert franchiseeVat;

        Test.stopTest();

		payment = [SELECT VAT__c FROM LG_Payment__c WHERE Id =:payment.Id];
		System.assert(payment.VAT__c == franchiseeVat.VAT__c);

	}

    @isTest(seeAllData=false)
    static void updateOtherVatsOnSameFranchise_Test(){

        Account lc = ObjectCreator.getNewAccount();
        insert lc;

        Franchisee_VAT__c franchiseeVat = ObjectCreator.getNewFranchiseeVat(lc.Id, 11);        
        franchiseeVat.VAT_End_Date__c = Null;
        franchiseeVat.VAT_From_Date__c = System.today().addDays(-1);
        insert franchiseeVat;

        System.assert(null == [SELECT VAT_End_Date__c FROM Franchisee_VAT__c WHERE Id =:franchiseeVat.Id].VAT_End_Date__c);

        Franchisee_VAT__c franchiseeVat2 = ObjectCreator.getNewFranchiseeVat(lc.Id, 12);        
        franchiseeVat2.VAT_End_Date__c = System.today().addDays(3);
        franchiseeVat2.VAT_From_Date__c = System.today().addDays(1);
        insert franchiseeVat2;

        System.assert(franchiseeVat2.VAT_From_Date__c.addDays(-1) == [SELECT VAT_End_Date__c FROM Franchisee_VAT__c WHERE Id =:franchiseeVat.Id].VAT_End_Date__c);       

    }
    
}