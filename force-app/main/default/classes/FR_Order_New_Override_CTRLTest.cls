@isTest
private class FR_Order_New_Override_CTRLTest {

    @isTest(seeAllData=false)
    static void myUnitTest() {
        
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
    	
        insert new HD_Settings_List__c(Name = 'FR_Order__c.Price_List_Title__c', Value__c = 'test');
        
    	ApexPages.currentPage().getParameters().put('test', 'test');
    	ApexPages.StandardController sc = new ApexPages.StandardController(frOrder);
        FR_Order_New_Override_CTRL controller = new FR_Order_New_Override_CTRL(sc);
        controller.doRedirect();	
    }
}