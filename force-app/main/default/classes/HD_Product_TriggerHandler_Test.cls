@isTest
private class HD_Product_TriggerHandler_Test {

	@isTest ( seeAllData = false )
	static void NewProductPrice_Test(){

        Account acc = ObjectCreator.getNewAccount();
        acc.DBAmp_Stop_Migration_MF__c = 'Yes';
        acc.Account_Type__c = 'MF';
        insert acc;

        Contact teacherContact = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact;

        User u = ObjectCreator.getNewUser(teacherContact.Id);
        insert u;

        System.runAs(u){

	    	Price_List_Title__c priceListTitle = ObjectCreator.getNewPriceListTitle();
	    	priceListTitle.RecordTypeId = Schema.SObjectType.Price_List_Title__c.getRecordTypeInfosByName().get('HD').getRecordTypeId();
	    	priceListTitle.Start_Date__c = system.today().addDays(-10);
	        insert priceListTitle;

	    	Price_List_Title__c priceListTitleChild = ObjectCreator.getNewPriceListTitle();
	    	priceListTitleChild.RecordTypeId = Schema.SObjectType.Price_List_Title__c.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();
	    	priceListTitleChild.Start_Date__c = system.today().addDays(-5);
	    	priceListTitleChild.HD_Price_List_Title__c = priceListTitle.Id;
	        insert priceListTitleChild;

	        HD_Product__c hdProduct = ObjectCreator.getNewHDProduct();
	        insert hdProduct;

        	//System.assert([SELECT Id FROM Product_Price__c].size() == 1);
        }

    }

}