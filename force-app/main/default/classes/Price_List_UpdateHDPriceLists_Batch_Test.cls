@isTest
private class Price_List_UpdateHDPriceLists_Batch_Test {
    
    @isTest(SeeAllData=false)
    static void Price_List_UpdateHDPriceLists_Batch_Test() {
        Product_Price_Import__c ppImport = new Product_Price_Import__c();
        ppImport.Price_List_Title_Name__c = 'Test 1507';
        ppImport.Product_Name__c = 'Test 1507';
        ppImport.Selling_Price__c = 10.0;
        ppImport.Recommended_Price_for_Student__c = 11.0;
        ppImport.PN_Code__c = 'TEST';

        Product_Price_Import__c ppImport2 = new Product_Price_Import__c();
        ppImport2.Price_List_Title_Name__c = 'Test 1506';
        ppImport2.Product_Name__c = 'Test 1506';
        ppImport2.Selling_Price__c = 11.0;
        ppImport2.Recommended_Price_for_Student__c = 11.0;
        ppImport2.PN_Code__c = 'TEST2';

        insert new List<Product_Price_Import__c>{ppImport,ppImport2};

        HD_Product__c hdProduct = ObjectCreator.getNewHDProduct();
        hdProduct.PN_Code__c = 'TEST';
        insert hdProduct;

        Price_List_Title__c priceListTitle = ObjectCreator.getNewPriceListTitle();
        priceListTitle.Name = ppImport.Price_List_Title_Name__c.toLowerCase();

        Price_List_Title__c priceListTitle2 = ObjectCreator.getNewPriceListTitle();
        priceListTitle2.Name = ppImport2.Price_List_Title_Name__c.toLowerCase();
        insert new List<Price_List_Title__c>{priceListTitle,priceListTitle2};

        Product_Price__c productPrice = ObjectCreator.getNewProductPrice(priceListTitle.Id);
        productPrice.Selling_Price__c = 4;
        productPrice.HD_Product__c = hdProduct.Id;

        Product_Price__c productPrice2 = ObjectCreator.getNewProductPrice(priceListTitle2.Id);
        productPrice2.Selling_Price__c = 5;
        productPrice2.HD_Product__c = hdProduct.Id;

        insert new List<Product_Price__c>{productPrice,productPrice2};
        
        Test.startTest();
            Price_List_UpdateHDPriceLists_Batch b = new Price_List_UpdateHDPriceLists_Batch();
            b.restrict2Ids.add(ppImport.Id); 
            b.restrict2Ids.add(ppImport2.Id); 
            Database.executeBatch(b,10);
        Test.stopTest();
    }
}