@isTest
private class LGZeroPaymentsControllerTest {

    @isTest(seeAllData=false)
    static void myUnitTest() {
        
		ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

        HD_Settings_List__c sl1 = new HD_Settings_List__c(Name = 'Zero_Monthly_Payment_Profiles', Value__c = String.valueOf(Userinfo.getProfileId()));
		insert sl1;

		LG__c myTestLG = new LG__c(id = testEnv.lgId, LG_Start_Date__c = system.today(), LG_End_Date__c = system.today().addYears(1));
		update myTestLG;

        ApexPages.StandardSetController sc = new ApexPages.StandardSetController( database.getQueryLocator( [SELECT Id FROM LG__c WHERE Id = :myTestLG.Id LIMIT 1] ) );
        ApexPages.currentPage().getParameters().put('retUrl', testEnv.lgid);
        
        LGZeroPaymentsController controller = new LGZeroPaymentsController(sc);
        
        sc.SetSelected( [SELECT Id FROM LG__c WHERE Id = :myTestLG.Id LIMIT 1] );
        controller = new LGZeroPaymentsController(sc);
        controller.doCreateLGSpecialPriceToLGs();
        controller.allMonths[system.today().month()-1].isSelected = true;
        controller.doCreateLGSpecialPriceToLGs();
        controller.dummySpecialPrice.Year__c = null;
        controller.doCreateLGSpecialPriceToLGs();
        
        sl1.Value__c = ',';
        update sl1;
        controller = new LGZeroPaymentsController(sc);
    }
}