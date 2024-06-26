@isTest
private class Multi_Order_Ctl_Test {
	@isTest(seeAllData=false)
    static void Multi_Order_Ctl_Test() {
        //HD_TriggerSettings.disableAllTriggers = true;

        ObjectCreator.DisableSharingMethods();
        HD_TriggerSettings.disableTriggersFromTest.remove('Default_Price_List_Title');
        HD_TriggerSettings.disableTriggersFromTest.remove('HDC_Order_CreateSharingRules');

        Account acc2 = ObjectCreator.getNewAccount();
        insert acc2;

		Contact teacherContact2 = ObjectCreator.getNewContact(acc2.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact2;

		User u2 = ObjectCreator.getNewUser(teacherContact2.Id);
    	insert u2;

    	HD_Product__c hdProduct = ObjectCreator.getNewHDProduct();
    	HD_Product__c hdProduct2 = ObjectCreator.getNewHDProduct();
    	hdProduct.MF_Product__c = false;
    	hdProduct.PN_Code__c = 'test1';
    	hdProduct2.MF_Product__c = false;
    	hdProduct2.PN_Code__c = 'test2';
        insert new List<HD_Product__c>{hdProduct, hdProduct2};

        Set_Product__c setProduct = ObjectCreator.getNewSetProduct(hdProduct.Id);
        insert setProduct; 
		
        Price_List_Title__c priceListTitleHD = ObjectCreator.getNewPriceListTitle();
    	priceListTitleHD.RecordTypeId = Schema.SObjectType.Price_List_Title__c.getRecordTypeInfosByName().get('HD').getRecordTypeId();
    	priceListTitleHD.Start_Date__c = system.today().addDays(-1);
        
    	Price_List_Title__c priceListTitle = ObjectCreator.getNewPriceListTitle();
    	priceListTitle.RecordTypeId = Schema.SObjectType.Price_List_Title__c.getRecordTypeInfosByName().get('HD').getRecordTypeId();
    	priceListTitle.Start_Date__c = system.today().addDays(-1);

        FR_Order__c order;
        System.runAs(u2){
            insert priceListTitleHD;
            
            priceListTitle.HD_Price_List_Title__c = priceListTitleHD.Id;
            insert priceListTitle;
            
            order = ObjectCreator.getNewOrder(priceListTitle.Id, Schema.SObjectType.FR_Order__c.getRecordTypeInfosByName().get('Sub Franchisee after Submit').getRecordTypeId());
            order.Status__c = 'Draft';
            
            insert order; 
        }
		
		Product_Price__c hdProductPrice = ObjectCreator.getNewProductPrice(priceListTitleHD.Id);
		hdProductPrice.CurrencyIsoCode = 'USD';
		hdProductPrice.HD_Product__c = hdProduct.Id;
        hdProductPrice.Unique_Product_Price_ID__c = String.valueOf(priceListTitleHD.Id).substring(0, 15) + '-' + hdProduct.PN_Code__c;
		Product_Price__c hdProductPrice2 = ObjectCreator.getNewProductPrice(priceListTitleHD.Id);
        hdProductPrice2.Unique_Product_Price_ID__c = String.valueOf(priceListTitleHD.Id).substring(0, 15) + '-' + hdProduct2.PN_Code__c;
		hdProductPrice2.CurrencyIsoCode = 'USD';
		hdProductPrice2.HD_Product__c = hdProduct2.Id;
		insert new List<Product_Price__c>{hdProductPrice, hdProductPrice2};
		
        Product_Price__c productPrice = ObjectCreator.getNewProductPrice(priceListTitle.Id);
        productPrice.HD_Product__c = hdProduct.Id;
        productPrice.HD_Product_Price__c = hdProductPrice.Id;
        productPrice.CurrencyIsoCode = 'USD';
        productPrice.Unique_Product_Price_ID__c = String.valueOf(priceListTitle.Id).substring(0, 15) + '-' + hdProduct.PN_Code__c;
        Product_Price__c productPrice2 = ObjectCreator.getNewProductPrice(priceListTitle.Id);
        productPrice2.HD_Product__c = hdProduct2.Id;
        productPrice2.HD_Product_Price__c = hdProductPrice2.Id;
        productPrice2.CurrencyIsoCode = 'USD';
        productPrice2.Unique_Product_Price_ID__c = String.valueOf(priceListTitle.Id).substring(0, 15) + '-' + hdProduct2.PN_Code__c;
        insert new List<Product_Price__c>{productPrice, productPrice2};

        for (Product_Price__c pp :[SELECT id, Unique_Product_Price_ID__c FROM Product_Price__c] ) {
            System.debug(LoggingLevel.ERROR, '*** : ' + pp);
        }
		
		FR_Order_Product__c orderProd1 = ObjectCreator.getNewOrderProduct(order.Id, productPrice.Id, Schema.SObjectType.FR_Order_Product__c.getRecordTypeInfosByName().get('Sub Franchisee after Submit').getRecordTypeId() ); 
		insert orderProd1;
        
    	Apexpages.currentPage().getParameters().put('ids', String.valueOf(order.Id));

    	ApexPages.StandardController sc = new ApexPages.StandardController(order);

		Multi_Order_Ctl ctrl = new Multi_Order_Ctl(sc);
        order.Status__c= 'Sent to MF';
        order.Ordered_From__c = acc2.Id;
        update order;

        test.startTest();

        ctrl = new Multi_Order_Ctl(sc);

        ctrl.showForm = false;
        ctrl.showError = '';
        System.runAs(u2){
    		ctrl.DoAction();
    	}
    	ctrl.setNewMultiOrder( 'xxxx' );
        System.runAs(u2){
        	ctrl.doContinue();  
        }  	
    	
        ctrl.setNewMultiOrder( 'false' );
    	
    	order = [SELECT Id, Multi_Order__c FROM FR_Order__c WHERE Id = :order.Id LIMIT 1][0];

    	order.Status__c = 'Draft';
        update order; 
    	
    	FR_Order_Product__c orderProd = ObjectCreator.getNewOrderProduct(order.Id, productPrice2.Id, Schema.SObjectType.FR_Order_Product__c.getRecordTypeInfosByName().get('Sub Franchisee after Submit').getRecordTypeId() );
		insert orderProd;
		
		order.Multi_Order__c = [SELECT Id FROM FR_Order__c WHERE Id != :order.Id LIMIT 1].Id;
        System.debug(LoggingLevel.ERROR, '*** Multi_Order__c: ' );
		System.debug(LoggingLevel.ERROR, '*** Multi_Order__c: ' + order.Multi_Order__c);

		ctrl.setSelectedMultiOrder( order.Multi_Order__c );
		ctrl.getSelectedMultiOrder();
		ctrl.getMultiOrders();
        System.runAs(u2){
		  ctrl.doContinue();
        }   
		
        update new FR_Order__c(Id= order.Multi_Order__c, Status__c = 'Not Draft');

    	ctrl.setSelectedMultiOrder( order.Multi_Order__c );
    	ctrl.doContinue();
    	ctrl.getNewMultiOrder();
    	
    	ctrl.getPriceLists();
    	ctrl.getSelectedPriceList();
    	ctrl.setSelectedPriceList('test');
    	
    	ctrl = new Multi_Order_Ctl(sc);
    	ctrl.recordTypeName = 'FP';
    	ctrl.setNewMultiOrder( 'true' );
    	ctrl.getMultiOrders();
        System.runAs(u2){
    	   ctrl.doContinue();
        }   
        
    	ctrl.getHDPriceLists();
        ctrl.getDefaultPriceList();
        ctrl.setDefaultPriceList(null);
        
    	Multi_Order_Ctl.FindPriceList('FP', new Set<String>{order.Id} );
        
        test.stopTest();
    }
}