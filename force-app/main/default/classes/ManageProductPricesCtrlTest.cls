/**************************************************************************************** 
    Name              : ManageProductPricesCtrlTest
    Description       : Test method of related Controller ManageProductPricesCtrl
    Revision History  :-
    Created/Modified by         Created/Modified Date     Requested by      Related Task/Issue  
    ----------------------------------------------------------------------------------------
    1. G. Fernandez (Created)         29/03/2016            Yaara                [SW-18656]
    ----------------------------------------------------------------------------------------    
****************************************************************************************/
@isTest
private class ManageProductPricesCtrlTest {
    
    @isTest(seeAllData=false)
    static void manageProductPricesCtrl_test(){
        Price_List_Title__c priceListTitle = ObjectCreator.getNewPriceListTitle();
        Price_List_Title__c priceListTitle2 = ObjectCreator.getNewPriceListTitle();
        insert new List<Price_List_Title__c>{priceListTitle,priceListTitle2};

		HD_Product__c hdProduct = ObjectCreator.getNewHDProduct();
    	HD_Product__c hdProduct2 = ObjectCreator.getNewHDProduct();
    	hdProduct2.MF_Product__c = false;
    	hdProduct2.PN_Code__c = 'test2';
        insert new List<HD_Product__c>{hdProduct, hdProduct2};	

        Product_Price__c productPrice2 = ObjectCreator.getNewProductPrice(priceListTitle2.Id);
        productPrice2.Selling_Price__c = 11;
        productPrice2.HD_Product__c = hdProduct2.Id;
        insert productPrice2;  
		
        Set_Product__c setProduct = ObjectCreator.getNewSetProduct(hdProduct.Id);
        insert setProduct; 

        Product_Price__c productPrice = ObjectCreator.getNewProductPrice(priceListTitle.Id);
        productPrice.HD_Product_Price__c = productPrice2.Id;
        productPrice.HD_Product__c = hdProduct.Id;
        insert productPrice;        
        
        ApexPages.StandardController sc = new ApexPages.StandardController (priceListTitle);
        manageProductPricesCtrl controller = new manageProductPricesCtrl (sc);
        
        controller.setJSonSaveData(controller.jsonData.replace('"selected":false', '"selected":true'));
        controller.getJSonSaveData();
        controller.Save();
        
        manageProductPricesCtrl.dataWrapper dw = new manageProductPricesCtrl.dataWrapper( productPrice );
        Decimal q = dw.quantity;
        String s = controller.showError;
        
    }
    
}