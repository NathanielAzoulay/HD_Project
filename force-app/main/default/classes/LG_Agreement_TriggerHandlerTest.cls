@isTest
private class LG_Agreement_TriggerHandlerTest {
    
    @isTest(seeAllData=false) 
    static void CreateAgreementParameters_Test(){
        Id recTypeMfFpId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();
        Id recTypeFranchiseeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();

	    Account acc = ObjectCreator.getNewAccount();
        acc.Account_Type__c= 'MF';
        acc.RecordTypeId = recTypeMfFpId;
        acc.Permitted_Users_per_Account__c = 99; 
        acc.BillingCountry = 'Spain';

        insert acc;

        Agreement_Meta_Data__c agmd = new Agreement_Meta_Data__c();
        agmd.Royalty_Type__c = '1 - Standard';
        agmd.From_Franchise_Type__c = 'MF';
		agmd.Royalty_Percent__c = 3;
		agmd.Student_Count_Revenue__c = 99;
		agmd.Source_Account_Type__c= 'MF';
		agmd.To_Franchise_Type__c = 'MF';
		agmd.Program_Type__c = 'HDE';
        insert agmd;

        for(Agreement_Meta_Data__c agmdd : [SELECT Id, Royalty_Type__c, From_Franchise_Type__c, Program_Type__c, Country__c FROM Agreement_Meta_Data__c]){
        	System.debug(LoggingLevel.ERROR, '*** agmdd: ' + agmdd);
        }
		
    	Agreement__c agree 	= ObjectCreator.getNewAgreement(acc.Id);             
    	agree.From_Franchisee__c = acc.Id;
		agree.Agreement_Status__c = 'Active';
		agree.Due_Date_Q1__c = Date.newInstance(System.today().addYears(-1).year(), 2, 1);
		agree.Due_Date_Q2__c = System.today().addYears(-1);
		agree.Due_Date_Q3__c = System.today().addYears(-1);
		agree.Due_Date_Q4__c = System.today().addYears(-1);
		agree.Royalty_Type__c = '1 - Standard';
        agree.Agreement_type__c = 'MF';
		agree.Program_Type__c = 'HDE';
	    insert agree;

	    Agreement_Parameter__c newParameter = new Agreement_Parameter__c(Agreement__c = agree.Id, Student_Count_Revenue__c = 100, Royalty_Percent__c = 10);  
	    insert newParameter;

	    agree.Direct_Franchisee__c = acc.Id;
	    try{
	    	update agree;
	    	System.assert([SELECT Id FROM Agreement_Parameter__c WHERE Agreement__c = :agree.Id].size() > 0);
	    }catch(Exception ex){}
	}


}