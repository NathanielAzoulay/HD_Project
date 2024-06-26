@isTest (seealldata=false) 
public class FR_Order_Product_TriggerHandler_Test {
	@isTest (seealldata=false) 
    static void CheckForDuplicateOrderProduct_Test(){
        Account acc2 = ObjectCreator.getNewAccount();
        insert acc2;

		Contact teacherContact2 = ObjectCreator.getNewContact(acc2.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact2;

		//User u2 = ObjectCreator.getNewUser(teacherContact2.Id);
    	//insert u2;

    	HD_Product__c hdProduct = ObjectCreator.getNewHDProduct();
    	HD_Product__c hdProduct2 = ObjectCreator.getNewHDProduct();
    	hdProduct.MF_Product__c = false;
    	hdProduct.PN_Code__c = 'test1';
    	hdProduct2.MF_Product__c = false;
    	hdProduct2.PN_Code__c = 'test2';
        insert new List<HD_Product__c>{hdProduct, hdProduct2};

        Set_Product__c setProduct = ObjectCreator.getNewSetProduct(hdProduct.Id);
        insert setProduct; 

    	Price_List_Title__c priceListTitle = ObjectCreator.getNewPriceListTitle();
    	priceListTitle.RecordTypeId = Schema.SObjectType.Price_List_Title__c.getRecordTypeInfosByName().get('HD').getRecordTypeId();
    	priceListTitle.Start_Date__c = system.today().addDays(-1);
        insert priceListTitle;
		
		Product_Price__c hdProductPrice = ObjectCreator.getNewProductPrice(priceListTitle.Id);
		hdProductPrice.CurrencyIsoCode = 'USD';
		hdProductPrice.HD_Product__c = hdProduct.Id;
		Product_Price__c hdProductPrice2 = ObjectCreator.getNewProductPrice(priceListTitle.Id);
		hdProductPrice2.CurrencyIsoCode = 'USD';
		hdProductPrice2.HD_Product__c = hdProduct2.Id;
		insert new List<Product_Price__c>{hdProductPrice, hdProductPrice2};
		/*
        Product_Price__c productPrice = ObjectCreator.getNewProductPrice(priceListTitle.Id);
        productPrice.HD_Product__c = hdProduct.Id;
        productPrice.HD_Product_Price__c = hdProductPrice.Id;
        productPrice.CurrencyIsoCode = 'USD';
        Product_Price__c productPrice2 = ObjectCreator.getNewProductPrice(priceListTitle.Id);
        productPrice2.HD_Product__c = hdProduct2.Id;
        productPrice2.HD_Product_Price__c = hdProductPrice2.Id;
        productPrice2.CurrencyIsoCode = 'USD';
        insert new List<Product_Price__c>{productPrice};
        insert new List<Product_Price__c>{productPrice2};
		*/
        FR_Order__c order = ObjectCreator.getNewOrder(priceListTitle.Id, Schema.SObjectType.FR_Order__c.getRecordTypeInfosByName().get('Sub Franchisee after Submit').getRecordTypeId());
        order.Status__c = 'Draft';
        insert order; 
		
		FR_Order_Product__c orderProd1 = ObjectCreator.getNewOrderProduct(order.Id, hdproductPrice.Id, Schema.SObjectType.FR_Order_Product__c.getRecordTypeInfosByName().get('Sub Franchisee after Submit').getRecordTypeId() ); 
		insert orderProd1;
        
        FR_Order_Product__c orderProd2 = ObjectCreator.getNewOrderProduct(order.Id, hdproductPrice.Id, Schema.SObjectType.FR_Order_Product__c.getRecordTypeInfosByName().get('Sub Franchisee after Submit').getRecordTypeId() ); 
        try{
			insert orderProd2;
        }catch(Exception e){}
    }
}