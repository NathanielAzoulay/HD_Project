@isTest
private class Price_List_Title_TriggerHandler_Test {

    @isTest(seeAllData=false)  
    static void createRelatedProductPrice_Test(){

        Price_List_Title__c priceListTitle = ObjectCreator.getNewPriceListTitle();
        priceListTitle.Start_Date__c = System.today().addDays(-10);
        insert priceListTitle;
        
        HD_Product__c hdProduct = ObjectCreator.getNewHDProduct();
        hdProduct.Price_by_Quantity__c = true;
        insert hdProduct;



        /*Product_Price__c productPrice = ObjectCreator.getNewProductPrice(priceListTitle.Id);
        productPrice.HD_Product__c = hdProduct.Id;
        productPrice.Unique_Product_Price_ID__c = 'test';
        insert productPrice;*/

        Product_Price__c productPrice = [SELECT Id, HD_Price_List_Title_ID__c, Price_List_Title__c, Active__c FROM Product_Price__c];
        System.debug(LoggingLevel.ERROR,'insert 1' + productPrice);

        Product_Price_by_Quantity__c ppq = new Product_Price_by_Quantity__c();
        ppq.Product_Price__c = productPrice.Id;
        ppq.Price__c = 1;
        ppq.Minimum_Quantity__c = 1;
        ppq.Maximum_Quantity__c = 99;
        insert ppq;

        Price_List_Title__c priceListTitleFranchisee = ObjectCreator.getNewPriceListTitleFranchisee(priceListTitle.Id);
        insert priceListTitleFranchisee;

        Product_Price__c productPrice2 = [SELECT Id, Price_List_Title__c FROM Product_Price__c WHERE HD_Product_Price__c =: productPrice.Id];
        System.assert( priceListTitleFranchisee.Id == productPrice2.Price_List_Title__c);

        productPrice2.Selling_Price__c = 10;
        update productPrice2;

        System.debug(LoggingLevel.ERROR,'insert 2 ' + [SELECT Id, HD_Price_List_Title_ID__c, Price_List_Title__c, Active__c, Selling_Price__c, HD_Product__c FROM Product_Price__c]);

        Price_List_Title__c priceListTitleFranchiseeClone = ObjectCreator.getNewPriceListTitleFranchisee(priceListTitle.Id);
        priceListTitleFranchiseeClone.Cloned_From__c = priceListTitleFranchisee.Id;
        insert priceListTitleFranchiseeClone;
// Added By Rashad , requested By Merav 08/01/2018 *******************************************************************************************************************************

		Price_List_Title__c priceListTitle1 = ObjectCreator.getNewPriceListTitle();
        priceListTitle1.Start_Date__c = System.today().addDays(+360);
        priceListTitle1.Cloned_From__c = priceListTitle.id;
        insert priceListTitle1;
// Added By Rashad , requested By Merav 08/01/2018 *******************************************************************************************************************************

    }
    
    @isTest(seeAllData=false) 
    static void CreatePriceListAssignment_Test(){
        Account acc1 = ObjectCreator.getNewAccount();
        insert acc1;
        
        Price_List_Title__c priceListTitle1 = ObjectCreator.getNewPriceListTitle();
        insert priceListTitle1;
        
        Price_List_Title_Assignment__c plta1 = new Price_List_Title_Assignment__c(Price_List_Title__c = priceListTitle1.Id, Franchise__c = acc1.Id);
        insert plta1;
        
        Price_List_Title__c priceListTitle2 = ObjectCreator.getNewPriceListTitle();
        Price_List_Title__c priceListTitle3 = ObjectCreator.getNewPriceListTitle();
        priceListTitle2.Replace_Price_List_Title__c = priceListTitle1.Id;
        insert new List<Price_List_Title__c>{priceListTitle2, priceListTitle3};
        
        priceListTitle3.Replace_Price_List_Title__c = priceListTitle1.Id;
        update priceListTitle3;
        
        system.assertEquals( 1, [SELECT Id FROM Price_List_Title_Assignment__c WHERE Price_List_Title__c = :priceListTitle2.Id ].Size() );
        system.assertEquals( 1, [SELECT Id FROM Price_List_Title_Assignment__c WHERE Price_List_Title__c = :priceListTitle3.Id ].Size() );
    }
}