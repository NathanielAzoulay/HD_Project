/**************************************************************************************** 
    Name              : PriceListTitleAssignment_TriggerHdlrTest
    Description       : Test method of related Controller PriceListTitleAssignment_TriggerHandler
    Revision History  :-
    Created/Modified by         Created/Modified Date     Requested by      Related Task/Issue  
    ----------------------------------------------------------------------------------------
    1. Sergio
    ----------------------------------------------------------------------------------------    
****************************************************************************************/
@isTest(seeAllData=false)
public class PriceListTitleAssignment_TriggerHdlrTest {
    
    @TestSetup
    public static void setup(){
        ObjectCreator.initializeCustomSetting();
        
        Account acc1 = ObjectCreator.getNewAccount();
        acc1.Name += 'FirstAccount';
        Account acc2 = ObjectCreator.getNewAccount();
        acc1.Name += 'SecondAccount';
        insert new List<Account>{acc1, acc2};
    	
    	Price_List_Title__c priceListTitle1 = ObjectCreator.getNewPriceListTitle();
    	insert priceListTitle1;
    	
    	Price_List_Title_Assignment__c plta1 = new Price_List_Title_Assignment__c(Price_List_Title__c = priceListTitle1.Id, Franchise__c = acc1.Id);
    	insert plta1;
    }
    
	@isTest(seeAllData=false)
    public static void pltAssignmentRemoveSharingRules_Test01(){
        Price_List_Title_Assignment__c plta1 = [SELECT Id FROM Price_List_Title_Assignment__c LIMIT 1][0];
        delete plta1;
    }
    
    @isTest(seeAllData=false)
    public static void pltAssignmentCreateSharingRules_Test01(){
        Account acc2 = [SELECT Id FROM Account WHERE Name LIKE '%SecondAccount' LIMIT 1];
        
        Price_List_Title__c priceListTitle1 = ObjectCreator.getNewPriceListTitle();
    	insert priceListTitle1;
        
        Price_List_Title_Assignment__c plta1 = new Price_List_Title_Assignment__c(Price_List_Title__c = priceListTitle1.Id, Franchise__c = acc2.Id);
    	insert plta1;
    }
}