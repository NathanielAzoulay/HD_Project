/*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name:            RSRoyaltyCalculationTEST.cls
Description:    Test class
Date             Author          Summary of Changes 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
15-OCT-2017     Rashad Saeed  Initial Implementation 
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/


@isTest
public class RSRoyaltyCalculationTest {
    @isTest()  
    static void RSRoyaltyCalculation() {
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        Map<String, Map<Date, Average_Exchange_Rate__c>> eRates = RoyaltyCalculationProcessStep1.getAverageExchangeRates(system.today().addMonths(-1));
        Set <Id> AggsId = new Set <Id>();
        List<Royalties_Calculation__c> rc2Ins = new List<Royalties_Calculation__c>();
        List<Agreement__c> ag2Up = new List<Agreement__c>();
        for(Agreement__c ag : [SELECT Id, From_Franchisee__c, From_Franchisee__r.Currency__c, Direct_Franchisee__c, Direct_Franchisee__r.CurrencyIsoCode, From_Franchisee__r.CurrencyIsoCode, CurrencyIsoCode FROM Agreement__c]){
            rc2Ins.add(RoyaltyCalculationProcessStep2.createRoyaltiesCalculation(ag, system.today().addMonths(1), eRates));
            ag.Royalty_Type__c = '1 - Standard';
            Ag.Expiry_Date__c = System.today().addYears(1);
            ag2Up.add(ag);
            AggsId.add(ag.ID);
        }
        insert rc2Ins;
        update ag2Up;
    
        Id recordTypeId = Schema.SObjectType.Group_Income_Per_Month__c.getRecordTypeInfosByName().get('Calculated Student').getRecordTypeId();
        
        Group_Income_Per_Month__c gipm1 = ObjectCreator.getNewGroupIncomePerMonth(testEnv.agreeId, testEnv.lgId);
        gipm1.RecordTypeId = recordTypeId;
        gipm1.Student__c = testEnv.studentContactId;
        gipm1.Actual_Student__c = 1;
        Group_Income_Per_Month__c gipm2 = gipm1.clone(false, true, false, false);
        gipm2.Actual_Student__c = 0;
        
        Account ParentAcc = ObjectCreator.getNewAccount();
        Insert ParentAcc;
        Account ChiledAcc = ObjectCreator.getNewAccount();
        ChiledAcc.ParentId =ParentAcc.id; 
        Insert ChiledAcc;
        
        Agreement__c ParentAgg =ObjectCreator.getNewAgreement(ParentAcc.Id);
        ParentAgg.Royalty_Type__c = '1 - Standard';
        ParentAgg.Expiry_Date__c = System.today().addYears(1);
        Insert ParentAgg;
        Agreement__c ChiledAgg =ObjectCreator.getNewAgreement(ChiledAcc.Id);
        ChiledAgg.Direct_Franchisee_Agreement__c = ParentAgg.Id;
        ChiledAgg.Direct_Franchisee__c = ParentAcc.id;
        ChiledAgg.Royalty_Type__c = '1 - Standard';
        ChiledAgg.Expiry_Date__c = System.today().addYears(1);
        Insert ChiledAgg ;
        insert ObjectCreator.getNewAgreementParametersByStudents(ChiledAgg.Id);
        insert ObjectCreator.getNewAgreementParametersByType(ChiledAgg.Id, 'LCF');
        Royalties_Calculation__c chRc = new Royalties_Calculation__c (
                        Calculated_Income__c=25 ,
                        Actual_Students__c=20,
                        Calculated_Students__c=30,
                        Agreement__c=ChiledAgg.id,
                        From_Franchisee__c=ChiledAcc.Id,
                        Direct_Franchisee__c=ParentAcc.Id,
                        Royalty_Month__c = System.today(),
                        Process_Key__c=system.now().getTime(),
                        Calculated_Royalties__c = 360,
                        GIPM_Income__c =1000);
        insert chRc;
       
        
        insert new List<Group_Income_Per_Month__c>{gipm1, gipm2};
        Test.StartTest();
        RSRoyaltyCalculation b = new RSRoyaltyCalculation();
        b.ReGenerate=true;
        Database.executeBatch(b);
        Test.StopTest(); 
       
    }
     @isTest(seeAllData=false)  
    static void RSRoyaltyCalculation2() {
      ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        Map<String, Map<Date, Average_Exchange_Rate__c>> eRates = RoyaltyCalculationProcessStep1.getAverageExchangeRates(system.today().addMonths(-1));
        Set <Id> AggsId = new Set <Id>();
        List<Royalties_Calculation__c> rc2Ins = new List<Royalties_Calculation__c>();
        List<Agreement__c> ag2Up = new List<Agreement__c>();
        for(Agreement__c ag : [SELECT Id, From_Franchisee__c, From_Franchisee__r.Currency__c, Direct_Franchisee__c, Direct_Franchisee__r.CurrencyIsoCode, From_Franchisee__r.CurrencyIsoCode, CurrencyIsoCode FROM Agreement__c]){
            rc2Ins.add(RoyaltyCalculationProcessStep2.createRoyaltiesCalculation(ag, system.today().addMonths(1), eRates));
            ag.Royalty_Type__c = '1 - Standard';
            Ag.Expiry_Date__c = System.today().addYears(1);
            ag2Up.add(ag);
            AggsId.add(ag.ID);
        }
        insert rc2Ins;
        update ag2Up;
    
        Id recordTypeId = Schema.SObjectType.Group_Income_Per_Month__c.getRecordTypeInfosByName().get('Calculated Student').getRecordTypeId();
        
        Group_Income_Per_Month__c gipm1 = ObjectCreator.getNewGroupIncomePerMonth(testEnv.agreeId, testEnv.lgId);
        gipm1.RecordTypeId = recordTypeId;
        gipm1.Student__c = testEnv.studentContactId;
        gipm1.Actual_Student__c = 1;
        Group_Income_Per_Month__c gipm2 = gipm1.clone(false, true, false, false);
        gipm2.Actual_Student__c = 0;
        
        Account ParentAcc = ObjectCreator.getNewAccount();
        Insert ParentAcc;
        Account ChiledAcc = ObjectCreator.getNewAccount();
        ChiledAcc.ParentId =ParentAcc.id; 
        Insert ChiledAcc;
        
        Agreement__c ParentAgg =ObjectCreator.getNewAgreement(ParentAcc.Id);
        ParentAgg.Royalty_Type__c = '1 - Standard';
        ParentAgg.Expiry_Date__c = System.today().addYears(1);
        Insert ParentAgg;
        Agreement__c ChiledAgg =ObjectCreator.getNewAgreement(ChiledAcc.Id);
        ChiledAgg.Direct_Franchisee_Agreement__c = ParentAgg.Id;
        ChiledAgg.Direct_Franchisee__c = ParentAcc.id;
        ChiledAgg.Royalty_Type__c = '1 - Standard';
        ChiledAgg.Expiry_Date__c = System.today().addYears(1);
        ChiledAgg.Signing_Date__c = System.today().addYears(-2);
        Insert ChiledAgg ;
        insert ObjectCreator.getNewAgreementParametersByStudents(ParentAgg.Id);
        insert ObjectCreator.getNewAgreementParametersByType(ParentAgg.Id, 'LCF');
        Royalties_Calculation__c chRc = new Royalties_Calculation__c (
                        Calculated_Income__c=25 ,
                        Actual_Students__c=20,
                        Calculated_Students__c=30,
                        Agreement__c=ChiledAgg.id,
                        From_Franchisee__c=ChiledAcc.Id,
                        Direct_Franchisee__c=ParentAcc.Id,
                        Royalty_Month__c = System.today(),
                        Process_Key__c=system.now().getTime(),
                        Calculated_Royalties__c = 360,
                        GIPM_Income__c =1000);
        insert chRc;

        Royalties_Calculation__c ParentRc = new Royalties_Calculation__c (
                        Calculated_Income__c=0 ,
                        Actual_Students__c=0,
                        Calculated_Students__c=0,
                        Agreement__c=ParentAgg.id,
                        From_Franchisee__c=ParentAcc.Id,
                        Royalty_Month__c = System.today(),
                        Process_Key__c=system.now().getTime(),
                        Calculated_Royalties__c = 360,
                        RC_Income__c =1000,
                        Direct_Royalties_Calculation__c=chRc.Id);
        insert ParentRc;
        
        insert new List<Group_Income_Per_Month__c>{gipm1, gipm2};
        Test.StartTest();
        RSRoyaltyCalculation2 b = new RSRoyaltyCalculation2();
        Database.executeBatch(b);
        Test.StopTest(); 
       
    }
     @isTest(seeAllData=false)  
    static void RSRoyaltyCalculation3() {
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        Map<String, Map<Date, Average_Exchange_Rate__c>> eRates = RoyaltyCalculationProcessStep1.getAverageExchangeRates(system.today().addMonths(-1));
        
        List<Royalties_Calculation__c> rc2Ins = new List<Royalties_Calculation__c>();
        List<Agreement__c> ag2Up = new List<Agreement__c>();
        for(Agreement__c ag : [SELECT Id, From_Franchisee__c, From_Franchisee__r.Currency__c, Direct_Franchisee__c, Direct_Franchisee__r.CurrencyIsoCode, From_Franchisee__r.CurrencyIsoCode, CurrencyIsoCode FROM Agreement__c]){
            rc2Ins.add(RoyaltyCalculationProcessStep2.createRoyaltiesCalculation(ag, system.today().addMonths(1), eRates));
            ag.Royalty_Type__c = '1 - Standard';
            Ag.Expiry_Date__c = System.today().addYears(1);
            ag2Up.add(ag); 
        }
        
        Account ParentAcc = ObjectCreator.getNewAccount();
        Insert ParentAcc;
        Account ChiledAcc = ObjectCreator.getNewAccount();
        ChiledAcc.ParentId =ParentAcc.id; 
        Insert ChiledAcc;
        
       
        insert rc2Ins;
        update ag2Up;

        Id recordTypeId = Schema.SObjectType.Group_Income_Per_Month__c.getRecordTypeInfosByName().get('Calculated Student').getRecordTypeId();
        
        Group_Income_Per_Month__c gipm1 = ObjectCreator.getNewGroupIncomePerMonth(testEnv.agreeId, testEnv.lgId);
        gipm1.RecordTypeId = recordTypeId;
        gipm1.Student__c = testEnv.studentContactId;
        gipm1.Actual_Student__c = 1;
        Group_Income_Per_Month__c gipm2 = gipm1.clone(false, true, false, false);
        gipm2.Actual_Student__c = 0;
        
        insert new List<Group_Income_Per_Month__c>{gipm1, gipm2};
        Test.StartTest();
        RSRoyaltyCalculation3 b = new RSRoyaltyCalculation3();
        Database.executeBatch(b,2000); 
        Test.StopTest(); 
       
    }
}