/**************************************************************************************** 
    Name              : RoyaltyCalculationProcessStepTest
    Description       : Step  - The process will delete records that doesn't have checkbox field:  Allow to Delete = True in Royalty Calculation
    Revision History  :-
    Created/Modified by         Created/Modified Date     Requested by      Related Task/Issue  
    ----------------------------------------------------------------------------------------
    1. Hernan (Created)         07/07/2016                Yaara                
    ----------------------------------------------------------------------------------------    
****************************************************************************************/
@isTest
private class RoyaltyCalculationProcessStepTest {
    
    @isTest(seeAllData=false)
    static void RoyaltyCalculationProcessStep1Test() {
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        
        Average_Exchange_Rate__c aer1 = new Average_Exchange_Rate__c(To_Currency__c = 'USD', Exchange_Rate_Start_Date__c = system.today().addMonths(-1).toStartOfMonth());
        Average_Exchange_Rate__c aer2 = new Average_Exchange_Rate__c(To_Currency__c = 'EUR', Exchange_Rate_Start_Date__c = system.today().addMonths(-1).toStartOfMonth());
        insert new List<Average_Exchange_Rate__c>{aer1, aer2};
        
        Map<String, Map<Date, Average_Exchange_Rate__c>> eRates = RoyaltyCalculationProcessStep1.getAverageExchangeRates(system.today().addMonths(-1));
        
        Agreement__c ag = [SELECT Id, From_Franchisee__c, From_Franchisee__r.Currency__c, Direct_Franchisee__c, Direct_Franchisee__r.CurrencyIsoCode, From_Franchisee__r.CurrencyIsoCode, CurrencyIsoCode FROM Agreement__c WHERE Id =: testEnv.agreeId];
        Royalties_Calculation__c r = RoyaltyCalculationProcessStep2.createRoyaltiesCalculation(ag, system.today().addMonths(1), eRates);
        insert r;
        
        system.assertEquals(1, [SELECT Id FROM Royalties_Calculation__c].size());
        
        Test.StartTest();
        RoyaltyCalculationProcessStep1 b = new RoyaltyCalculationProcessStep1();
        b.rollback_key              = system.now().getTime();
        b.processName               = 'testprocess';
        b.filterIds                 = new Set<Id>{r.Id};
        b.runJustThisBatchFromTest  = true;
        Database.executeBatch(b,1);
        Test.StopTest(); 
        
        system.assertEquals(0, [SELECT Id FROM Royalties_Calculation__c].size());
        
        RoyaltyCalculationProcessStep1.insertErrors(new List<HD_Log__c>{new HD_Log__c()}, 'test', system.now().getTime(),'test');
        RoyaltyCalculationProcessStep1.getAverageExchangeRates(null);
    }
       
    
    @isTest(seeAllData=false)
    static void RoyaltyCalculationProcessStep2Test() {
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        Map<String, Map<Date, Average_Exchange_Rate__c>> eRates = RoyaltyCalculationProcessStep1.getAverageExchangeRates(system.today().addMonths(-1));
        
        List<Royalties_Calculation__c> rc2Ins = new List<Royalties_Calculation__c>();
        List<Agreement__c> ag2Up = new List<Agreement__c>();
        for(Agreement__c ag : [SELECT Id, From_Franchisee__c, From_Franchisee__r.Currency__c, Direct_Franchisee__c, Direct_Franchisee__r.CurrencyIsoCode, From_Franchisee__r.CurrencyIsoCode, CurrencyIsoCode FROM Agreement__c]){
            rc2Ins.add(RoyaltyCalculationProcessStep2.createRoyaltiesCalculation(ag, system.today().addMonths(1), eRates));
            ag.Royalty_Type__c = '1 - Standard';
            ag2Up.add(ag);
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
        
        insert new List<Group_Income_Per_Month__c>{gipm1, gipm2};
        
        String query = GlobalHelperMethods.getQueryString(new Group_Income_Per_Month__c()) + ' WHERE (Royalty_Type__c = \'1 - Standard\' OR Royalty_Type__c = null) AND For_Royalty_Calculation__c = true';
        
        Test.StartTest();
        RoyaltyCalculationProcessStep2 b = new RoyaltyCalculationProcessStep2();
        b.rollback_key              = system.now().getTime();
        b.processName               = 'testprocess';
        b.filterIds                 = new Set<Id>{database.query(query)[0].Id};
        b.runJustThisBatchFromTest  = true;
        Database.executeBatch(b,1);
        Test.StopTest(); 
    }
    
    @isTest(seeAllData=false)
    static void RoyaltyCalculationProcessStep2BisTest() {
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        Map<String, Map<Date, Average_Exchange_Rate__c>> eRates = RoyaltyCalculationProcessStep1.getAverageExchangeRates(system.today().addMonths(-1));
        
        Account newAcc = ObjectCreator.getNewAccount();
        insert newAcc;
        
        Test.StartTest();
        
        Agreement__c newAg2 = ObjectCreator.getNewAgreement(newAcc.Id);
        insert newAg2;
        
        Agreement__c newAg = ObjectCreator.getNewAgreement(newAcc.Id);
        newAg.Direct_Franchisee_Agreement__c = newAg2.Id;
        insert newAg;
        
        List<Royalties_Calculation__c> rc2Ins = new List<Royalties_Calculation__c>();
        List<Agreement__c> ag2Up = new List<Agreement__c>();
        Set<Id> agids = new Set<Id>();
        
        Id recTypeId = Schema.SObjectType.Royalties_Calculation__c.getRecordTypeInfosByName().get('Planned').getRecordTypeId();
        
        for(Agreement__c ag : [SELECT Id, From_Franchisee__c, From_Franchisee__r.Currency__c, Direct_Franchisee__c, Direct_Franchisee__r.CurrencyIsoCode, From_Franchisee__r.CurrencyIsoCode, CurrencyIsoCode FROM Agreement__c WHERE Id !=: newAg.Id]){
            Royalties_Calculation__c rc = RoyaltyCalculationProcessStep2.createRoyaltiesCalculation(ag, system.today().addMonths(1), eRates);
            rc.RecordTypeId = recTypeId;
            rc.Needs_transfer_to_Direct__c = true;
            rc2Ins.add(rc);
            ag.Direct_Franchisee_Agreement__c = newAg.Id;
            ag.Royalty_Type__c = '1 - Standard';
            ag2Up.add(ag);
            agids.add(ag.Id);
        }
        insert rc2Ins;
        update ag2Up;
        
        List<Agreement_Parameter__c> agp2Ins = new List<Agreement_Parameter__c>();
        for(Id agId : agids){
            agp2Ins.addAll(ObjectCreator.getNewAgreementParametersByStudents(agId));
        }
        insert agp2Ins;
        
        Integer x;
        Double y;
        Decimal z;
        RoyaltyCalculationProcessStep2Bis.getNotNullValue(x);
        RoyaltyCalculationProcessStep2Bis.getNotNullValue(y);
        RoyaltyCalculationProcessStep2Bis.getNotNullValue(z);
                
        Map<Id, Royalties_Calculation__c> rcM = new Map<Id, Royalties_Calculation__c>( [SELECT Id FROM Royalties_Calculation__c WHERE (Royalty_Type__c = '1 - Standard' OR Royalty_Type__c = null) AND Allow_to_Delete__c = true ] );
        
        RoyaltyCalculationProcessStep2Bis b = new RoyaltyCalculationProcessStep2Bis();
        b.rollback_key              = system.now().getTime();
        b.processName               = 'testprocess';
        b.filterIds                 = rcM.keySet();
        b.runJustThisBatchFromTest  = true;
        Database.executeBatch(b);
        Test.StopTest(); 
    }
   
    @isTest(seeAllData=false)
    static void RoyaltyCalculationProcessStep3Test() {
        HD_TriggerSettings.disableAllTriggers = true;
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        Map<String, Map<Date, Average_Exchange_Rate__c>> eRates = RoyaltyCalculationProcessStep1.getAverageExchangeRates(system.today().addMonths(-1));
        
        Account newAcc = ObjectCreator.getNewAccount();
        insert newAcc;
        
        Test.StartTest();
        
        Agreement__c newAg = ObjectCreator.getNewAgreement(newAcc.Id);
        insert newAg;
        
        List<Royalties_Calculation__c> rc2Ins = new List<Royalties_Calculation__c>();
        List<Agreement__c> ag2Up = new List<Agreement__c>();
        Set<Id> agids = new Set<Id>();


        for(Agreement__c ag : [SELECT Id, From_Franchisee__c, From_Franchisee__r.Currency__c, Direct_Franchisee__c, Direct_Franchisee__r.CurrencyIsoCode, From_Franchisee__r.CurrencyIsoCode, CurrencyIsoCode FROM Agreement__c WHERE Id !=: newAg.Id]){
            Royalties_Calculation__c rc = RoyaltyCalculationProcessStep2.createRoyaltiesCalculation(ag, system.today().addMonths(1), eRates);
            rc.Needs_transfer_to_Direct__c = true;
            rc2Ins.add(rc);
            ag.Direct_Franchisee_Agreement__c = newAg.Id;
            ag.Royalty_Type__c = '1 - Standard';
            ag2Up.add(ag);
            agids.add(ag.Id);
        }
        insert rc2Ins;
        update ag2Up;
        
        List<Agreement_Parameter__c> agp2Ins = new List<Agreement_Parameter__c>();
        for(Id agId : agids){
            agp2Ins.addAll(ObjectCreator.getNewAgreementParametersByStudents(agId));
        }
        insert agp2Ins;
        
        RoyaltyCalculationProcessStep3 b = new RoyaltyCalculationProcessStep3();
        b.rollback_key              = system.now().getTime();
        b.processName               = 'testprocess';
        //b.filterIds               = new Set<Id>{r.Id};
        b.runJustThisBatchFromTest  = true;
        Database.executeBatch(b,1);
        Test.StopTest(); 
    }
    
    @isTest(seeAllData=false)
    static void RoyaltyCalculationProcessStep3_1Test() {
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        Map<String, Map<Date, Average_Exchange_Rate__c>> eRates = RoyaltyCalculationProcessStep1.getAverageExchangeRates(system.today().addMonths(-1));
        
        Account newAcc = ObjectCreator.getNewAccount();
        insert newAcc;

        Test.StartTest();
        
        Agreement__c newAg = ObjectCreator.getNewAgreement(newAcc.Id);
        insert newAg;

        
        List<Royalties_Calculation__c> rc2Ins = new List<Royalties_Calculation__c>();
        List<Agreement__c> ag2Up = new List<Agreement__c>();
        Set<Id> agids = new Set<Id>();
        for(Agreement__c ag : [SELECT Id, From_Franchisee__r.HD_Currency__c, Direct_Franchisee__r.Account_Type__c, From_Franchisee__c, From_Franchisee__r.Currency__c, From_Franchisee__r.CurrencyIsoCode, Direct_Franchisee__c, Direct_Franchisee__r.CurrencyIsoCode, CurrencyIsoCode FROM Agreement__c WHERE Id !=: newAg.Id]){
            Royalties_Calculation__c rc = RoyaltyCalculationProcessStep2.createRoyaltiesCalculation(ag, system.today().addMonths(1), eRates);
            rc.Needs_transfer_to_Direct__c = true;
            rc2Ins.add(rc);
            ag.Direct_Franchisee_Agreement__c = newAg.Id;
            ag.Royalty_Type__c = '1 - Standard';
            ag2Up.add(ag);
            agids.add(ag.Id);
        }
        insert rc2Ins;
        update ag2Up;
        
        List<Agreement_Parameter__c> agp2Ins = new List<Agreement_Parameter__c>();
        for(Id agId : agids){
            agp2Ins.addAll(ObjectCreator.getNewAgreementParametersByType(agId, 'FP'));
        }
        insert agp2Ins;
        
        RoyaltyCalculationProcessStep3 b = new RoyaltyCalculationProcessStep3();
        b.rollback_key              = system.now().getTime();
        b.processName               = 'testprocess';
        //b.filterIds               = new Set<Id>{r.Id};
        b.runJustThisBatchFromTest  = true;
        Database.executeBatch(b,1);
        Test.StopTest(); 
    }
    
    @isTest(seeAllData=false)
    static void RoyaltyCalculationProcessStep4Test() {
        HD_TriggerSettings.disableAllTriggers = true;
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        Map<String, Map<Date, Average_Exchange_Rate__c>> eRates = RoyaltyCalculationProcessStep1.getAverageExchangeRates(system.today().addMonths(-1));
        
        Account newAcc = ObjectCreator.getNewAccount();
        insert newAcc;
        
        Agreement__c newAg = ObjectCreator.getNewAgreement(newAcc.Id);
        insert newAg;
        
        List<Royalties_Calculation__c> rc2Ins = new List<Royalties_Calculation__c>();
        List<Agreement__c> ag2Up = new List<Agreement__c>();
        Set<Id> agids = new Set<Id>();
        for(Agreement__c ag : [SELECT Id, From_Franchisee__r.HD_Currency__c, Direct_Franchisee__r.Account_Type__c, From_Franchisee__c, From_Franchisee__r.Currency__c, From_Franchisee__r.CurrencyIsoCode, Direct_Franchisee__c, Direct_Franchisee__r.CurrencyIsoCode, CurrencyIsoCode FROM Agreement__c WHERE Id !=: newAg.Id]){
            Royalties_Calculation__c rc = RoyaltyCalculationProcessStep2.createRoyaltiesCalculation(ag, system.today().addMonths(1), eRates);
            rc.Needs_transfer_to_Direct__c = true;
            rc2Ins.add(rc);
            ag.Direct_Franchisee_Agreement__c = newAg.Id;
            ag.Royalty_Type__c = '1 - Standard';
            ag.From_Franchisee__c = ag.Direct_Franchisee__c;
            
            ag2Up.add(ag);
            agids.add(ag.Id);
        }
        insert rc2Ins;
        update ag2Up;
        
        List<Agreement_Parameter__c> agp2Ins = new List<Agreement_Parameter__c>();
        for(Id agId : agids){
            agp2Ins.addAll(ObjectCreator.getNewAgreementParametersByType(agId, 'FP'));
        }
        insert agp2Ins;
        
        Test.StartTest();
        RoyaltyCalculationProcessStep4 b = new RoyaltyCalculationProcessStep4();
        b.rollback_key              = system.now().getTime();
        b.processName               = 'testprocess';
        //b.filterIds               = new Set<Id>{r.Id};
        Database.executeBatch(b,1);
        Test.StopTest(); 
    }
    
    @isTest(seeAllData=false)
    static void RoyaltyCalculationProcessStep5Test() {
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        Map<String, Map<Date, Average_Exchange_Rate__c>> eRates = RoyaltyCalculationProcessStep1.getAverageExchangeRates(system.today().addMonths(-1));
        
        List<Royalties_Calculation__c> rc2Ins = new List<Royalties_Calculation__c>();
        List<Agreement__c> ag2Up = new List<Agreement__c>();
        for(Agreement__c ag : [SELECT Id, From_Franchisee__c, From_Franchisee__r.Currency__c, Direct_Franchisee__c, Direct_Franchisee__r.CurrencyIsoCode, From_Franchisee__r.CurrencyIsoCode, CurrencyIsoCode FROM Agreement__c]){
            rc2Ins.add(RoyaltyCalculationProcessStep2.createRoyaltiesCalculation(ag, system.today().addMonths(1), eRates));
            ag.Royalty_Type__c = '1 - Standard';
            ag2Up.add(ag);
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
        
        insert new List<Group_Income_Per_Month__c>{gipm1, gipm2};
        
        String query = GlobalHelperMethods.getQueryString(new Group_Income_Per_Month__c()) + ' WHERE (Royalty_Type__c = \'1 - Standard\' OR Royalty_Type__c = null) AND For_Royalty_Calculation__c = true';
        
        Test.StartTest();
        RoyaltyCalculationProcessStep5 b = new RoyaltyCalculationProcessStep5();
        b.rollback_key              = system.now().getTime();
        b.processName               = 'testprocess';
        b.filterIds                 = new Set<Id>{database.query(query)[0].Id};
        b.runJustThisBatchFromTest  = true;
        Database.executeBatch(b,1);
        Test.StopTest(); 
    }
    
    @isTest(seeAllData=false) 
    static void RoyaltyCalculationProcessStepScheduler_Test() {     
        Test.startTest();        
        String jobId = System.schedule('testBasicScheduledApex', '0 0 0 3 9 ? 2042', new RoyaltyCalculationProcessStepScheduler());
        Test.stopTest();        
    }
}