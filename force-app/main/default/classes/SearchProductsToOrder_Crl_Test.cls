@isTest
private class SearchProductsToOrder_Crl_Test {

	/******************************************************************************* 
	Name              : SearchProductsToOrder_Crl_Test
	Description       : 
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G.Fernandez             21/04/2016           Hernan Sinclair
	*******************************************************************************/
	@isTest(seeAllData=false)
    static void SearchProductsToOrder_Crl_Test(){

    	HD_Product__c hdProduct = ObjectCreator.getNewHDProduct();
        insert hdProduct;

        Set_Product__c setProduct = ObjectCreator.getNewSetProduct(hdProduct.Id);
        insert setProduct; 

    	Price_List_Title__c priceListTitle = ObjectCreator.getNewPriceListTitle();
        insert priceListTitle;

        Product_Price__c productPrice = ObjectCreator.getNewProductPrice(priceListTitle.Id);
        productPrice.HD_Product__c = hdProduct.Id;
        insert productPrice; 

        Account acc2 = ObjectCreator.getNewAccount();
        insert acc2;

        Contact con = ObjectCreator.getNewContact(acc2.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId());              
        insert con;

        User u = ObjectCreator.getNewUser(con.Id);
        insert u;

        Test.startTest(); 

        FR_Order__c order = ObjectCreator.getNewOrder(priceListTitle.Id, Schema.SObjectType.FR_Order__c.getRecordTypeInfosByName().get('MF Order after Submit').getRecordTypeId());
        order.Status__c = 'Draft';
        order.CreatedById = u.Id;
        insert order; 

        FR_Order_Product__c orderProduct = ObjectCreator.getNewOrderProduct(order.Id, productPrice.Id, Schema.SObjectType.FR_Order_Product__c.getRecordTypeInfosByName().get('MF Order Product').getRecordTypeId());
        insert orderProduct; 
        
        ApexPages.StandardController sc = new ApexPages.StandardController (order);
        SearchProductsToOrder_Crl controller = new SearchProductsToOrder_Crl(sc);
        
        controller.setJSonSaveData(controller.jsonData.replace('"selected":false', '"selected":true'));
        controller.getJSonSaveData();
        controller.Save();

        Test.stopTest(); 

    }
}