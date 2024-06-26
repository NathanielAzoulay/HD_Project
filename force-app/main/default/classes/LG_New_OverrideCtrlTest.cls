/******************************************************************************* 
Name              : LG_New_OverrideCtrl
Description       : Controller to LG new override
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez             11/04/2016       	Yaara Nadir					SW-18845
*******************************************************************************/
@isTest
private class LG_New_OverrideCtrlTest {

    @isTest(seeAllData=false)
    static void LG_New_OverrideCtrl_test(){

        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

        Profile profile = [SELECT Id FROM Profile WHERE UserType = 'PowerPartner' LIMIT 1]; 

        User u = new User(Alias = 'test2004', Email='test2004@test.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = profile.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='test2004@test.com', ContactId = testEnv.teacherContactId);

        LG__c lg = new LG__c(Id = testEnv.lgId);
        ApexPages.StandardController sc = new ApexPages.StandardController( lg );
        ApexPages.currentPage().getParameters().put('retUrl',lg.id);

        System.runAs(u){
            LG_New_OverrideCtrl controller = new LG_New_OverrideCtrl(sc);
            controller.doRedirect();
        }

    }

    @isTest(seeAllData=false)
    static void PriceListTitleCloneOverrideCtrl_test(){
        Price_List_Title__c priceListTitle = ObjectCreator.getNewPriceListTitle();
        priceListTitle.RecordTypeId = Schema.SObjectType.Price_List_Title__c.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();
        insert priceListTitle;
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

        LG__c lg = new LG__c(Id = testEnv.lgId);
        ApexPages.StandardController sc = new ApexPages.StandardController( lg );
        
        System.debug(LoggingLevel.ERROR, '*** priceListTitle.id: ' + priceListTitle.id);
        
        ApexPages.currentPage().getParameters().put('retUrl','/'+priceListTitle.id);
        ApexPages.currentPage().getParameters().put('test','test');

        PriceListTitleCloneOverrideCtrl controller = new PriceListTitleCloneOverrideCtrl(sc);
        controller.doRedirect();

    }

}