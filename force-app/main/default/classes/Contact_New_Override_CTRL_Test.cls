@isTest
private class Contact_New_Override_CTRL_Test {

    @isTest(seeAllData=false)
    static void doRedirect_Test() {
        
        HD_Product__c hdProduct = ObjectCreator.getNewHDProduct();
        insert hdProduct;

        Set_Product__c setProduct = ObjectCreator.getNewSetProduct(hdProduct.Id);
        insert setProduct; 

    	Price_List_Title__c priceListTitle = ObjectCreator.getNewPriceListTitle();
    	priceListTitle.RecordTypeId = Schema.SObjectType.Price_List_Title__c.getRecordTypeInfosByName().get('HD').getRecordTypeId();
    	priceListTitle.Start_Date__c = system.today().addDays(-1);
        insert priceListTitle;

        Product_Price__c productPrice = ObjectCreator.getNewProductPrice(priceListTitle.Id);
        productPrice.HD_Product__c = hdProduct.Id;
        insert productPrice;  

        FR_Order__c frOrder = ObjectCreator.getNewOrder(priceListTitle.Id, Schema.SObjectType.FR_Order__c.getRecordTypeInfosByName().get('MF Order after Submit').getRecordTypeId());
        insert frOrder; 

        Account acc = ObjectCreator.getNewAccount();
	    insert acc;
        
        Contact con	= ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId());              
	    insert con;
        
        Contact con1 = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId() );
        insert new List<Contact>{con1};
        
        Id partnerCommunityProfile = [SELECT Id FROM Profile WHERE Name='Partner Community User'].Id;
        
        User user = new User(alias = 'CFMUser', email='CFMUserTest@noemail.com',
                emailencodingkey='UTF-8', lastname='CFMUserTest', languagelocalekey='en_US',
                localesidkey='en_US', profileid = partnerCommunityProfile, country='United States',IsActive =true,
                ContactId = con1.Id,
                timezonesidkey='America/Los_Angeles', username='CFMUserTest@noemail.com');
		
        insert user;
        
    	System.runAs(user){
	    	ApexPages.currentPage().getParameters().put('test', 'test');
	    	ApexPages.StandardController sc = new ApexPages.StandardController(con);
	        Contact_New_Override_CTRL controller = new Contact_New_Override_CTRL(sc);
	        controller.doRedirect();
	    }

    }
}