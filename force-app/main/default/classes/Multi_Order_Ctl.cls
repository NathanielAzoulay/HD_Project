/******************************************************************************* 
Name              : Multi_Order_Ctl 
Description       : 
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio                 22/04/2016              Yaara Nadir            [SW-18875]
2. Sergio                 15/12/2016              Yaara Nadir            [SW-22740]
3. G. Fernandez           26/07/2017              Yaara Nadir            [SW-25394]
*******************************************************************************/

public with sharing class Multi_Order_Ctl {
    public class MyException extends Exception {}
    
    public String showError {get; set;}
    public String showException {get; set;}
    public Boolean showForm {get; set;}
    public Boolean showDone {get; set;}
    
    public FR_Order__c dummyOrder {get;set;}
    
    private Set<String> orderIds {get;set;}
    private String newMultiOrder {get;set;}
    
    public String recordTypeName {get;set;}
    String selectedPriceList = '';
    String defaultPriceList = '';
    String selectedMultiOrder = '';
    
    public Boolean isMF {get{return recordTypeName == 'MF';}}
    public Boolean isFP {get{return recordTypeName == 'FP';}}
    
    public Multi_Order_Ctl(ApexPages.StandardController controller) {
        try{
            User us = [SELECT Id, Contact.AccountId, Contact.Account.Account_Type__c FROM User WHERE Id = :userinfo.getUserId() LIMIT 1][0];
            
            showForm = false;
            
            orderIds = new Set<String>();
            String idsParam = Apexpages.currentPage().getParameters().get('ids');
            
            orderIds.addAll( idsParam.split(',') );
            
            //Mode determines the logic.
            //Values : "MF", "FP"
            recordTypeName = us.Contact.Account.Account_Type__c;
            
            if( recordTypeName == null ){
                recordTypeName = 'MF';
            }
            
            Id hdPriceList;
            
            for( FR_Order__c ord : [SELECT Id, RecordType.Name, OwnerId, Status__c, HD_Price_List_Title_ID__c, Multi_Order__c, (SELECT Id FROM FR_Order_Products__r WHERE MF_Product__c = true ) FROM FR_Order__c WHERE Id IN :orderIds] ){
                if( ord.Status__c == null || ord.Status__c != null && !( ord.Status__c.equalsIgnoreCase('Sent to MF') || ord.Status__c.equalsIgnoreCase('Sent to FP') ) ){
                    showError = Label.Multi_Order_MF;
                    if( isFP ){
                        showError = Label.Multi_Order_FP;
                    }
                    showForm = false;
                    break;
                }
                
                if( hdPriceList == null ){
                    hdPriceList = ord.HD_Price_List_Title_ID__c;
                    defaultPriceList =ord.HD_Price_List_Title_ID__c;
                }

                // SW-25394 1.1.1.2 (Delete this check)
                /*else if( hdPriceList != ord.HD_Price_List_Title_ID__c ){
                    showError = Label.Multi_Order_HD_Price_List_Title;
                    showForm = false;
                    break;
                }
                */
                if( hdPriceList != ord.HD_Price_List_Title_ID__c ){
                    defaultPriceList = '';
                }

                if( ord.Multi_Order__c != null ){
                    showError = Label.HDC_Order_Please_choose_Order;
                    showForm = false;
                    break;
                }
                
                if( recordTypeName == 'MF' ){
                    if( !ord.FR_Order_Products__r.isEmpty() ){
                        showError = Label.HDC_Order_Consolidate_without_MF_Products;
                        showForm = true;
                        break;
                    }
                }
            }
            
            //We setup this dummy Order with the following values as to use the lookup with the Filter on it.
            dummyOrder = new FR_Order__c();
            dummyOrder.Ordered_By_Franchisee__c = us.Contact.AccountId;
            dummyOrder.Price_List_Title__c = hdPriceList;
            
            if( String.isBlank(showError) ){
                Set<Id> pltIds = FindPriceList( recordTypeName, orderIds );
                for( FR_Order__c ord : [SELECT Id FROM FR_Order__c WHERE OwnerId = :userinfo.getUserId() AND Status__c = 'Draft' AND Price_List_Title__c = :pltIds LIMIT 1 ] ){
                    showForm = true;
                    break;
                }
                
                if( pltIds.Size() > 1 ){
                    showForm = true;
                }
            }
            
        }catch(Exception e){
            showException = e.getMessage() + ' - ' + e.getStackTraceString();
            showForm = false;
            showError = '';
        }

    }
    
    public void DoAction(){
        if( showForm == false && String.isBlank(showException) && String.isBlank(showError) ){
            //Auto create new MultiOrder
            newMultiOrder = 'true';
            
            doContinue();
        }
    }
    
    public void setNewMultiOrder( String value ){
        newMultiOrder= value;
    }
    
    public String getNewMultiOrder( ){
        return newMultiOrder;
    }
    
    public PageReference doContinue(){
        Savepoint sp = Database.setSavepoint();
        showError = null;
        showException = null;
        Price_List_Title__c priceList;

        try{
            
            if( orderIds == null || newMultiOrder == null ){
                return null;
            }
            
            Map<Id, FR_Order__c > orders = new Map<Id, FR_Order__c >();
            
            for( FR_Order__c ord : [SELECT Id, HD_Price_List_Title_ID__c, Price_List_Title__c FROM FR_Order__c WHERE Id IN :orderIds ] ){
                orders.put(ord.Id, ord);
            }
            
            FR_Order__c multiOrd = new FR_Order__c();
            
            Map<String, FR_Order_Product__c> multiOrderExistingProds = new Map<String, FR_Order_Product__c>();
            
            if( newMultiOrder.equalsIgnoreCase('false') ){
                //Add to existing Multi Order
                
                multiOrd = [SELECT Id, Status__c, Price_List_Title__c, ( SELECT Id, PN_Code__c, Quantity__c FROM FR_Order_Products__r ) FROM FR_Order__c WHERE Id = :selectedMultiOrder ][0];
                
                selectedPriceList = multiOrd.Price_List_Title__c;
                
                for( FR_Order_Product__c op : multiOrd.FR_Order_Products__r ){
                    multiOrderExistingProds.put( op.PN_Code__c, op );
                }
                if( String.isNotBlank(multiOrd.Status__c) && !multiOrd.Status__c.equalsIgnoreCase('Draft') ){
                    throw new MyException( Label.Multi_Order_Not_Draft );
                }


                for(Price_List_Title__c plt : [SELECT Price_List_TitleOld_Id__c FROM Price_List_Title__c WHERE Id = :multiOrd.Price_List_Title__c LIMIT 1]){
                    priceList = plt;
                }
            }else{
                //Create new Multi Order
                
                multiOrd.RecordTypeId = FR_Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get( 'MF/FP' ).getRecordTypeId();
                multiOrd.Ordered_By_Franchisee__c = dummyOrder.Ordered_By_Franchisee__c;
                multiOrd.Order_By__c = Userinfo.getUserId();
                multiOrd.OwnerId = userInfo.getUserId();
                multiOrd.Status__c = 'Draft';

                //multiOrd.Price_List_Title__c = orders.values()[0].HD_Price_List_Title_ID__c;
                if( String.isBlank(selectedPriceList) ){
                    for(Id splId : FindPriceList(recordTypeName, orderIds) ){
                        selectedPriceList = splId;
                    }
                }
                
                multiOrd.Price_List_Title__c = selectedPriceList;

                //SW-26192
                if( isMF && ((!String.isBlank(defaultPriceList) && orderIds.size() > 1) || String.isBlank(selectedPriceList)) ){
                    multiOrd.Price_List_Title__c = defaultPriceList;
                }

                for(Price_List_Title__c plt : [SELECT Price_List_TitleOld_Id__c FROM Price_List_Title__c WHERE Id = :multiOrd.Price_List_Title__c LIMIT 1]){
                    priceList = plt;
                }

                /*
                if( multiOrd.Price_List_Title__c == null ){
                    multiOrd.Price_List_Title__c = orders.values()[0].Price_List_Title__c;
                }
                */
                if( isMF ){
                    for( Account acc : [SELECT Id FROM Account WHERE Name = 'Helen Doron HQ' LIMIT 1] ){
                        multiOrd.Ordered_From__c = acc.Id;
                    }
                }
                
                if( isFP ){
                    for( User user : [SELECT Id, Contact.AccountId, Contact.Account.ParentId FROM User WHERE Id = :Userinfo.getUserId() LIMIT 1] ){
                        multiOrd.Ordered_From__c = user.Contact.Account.ParentId;
                        if( multiOrd.Ordered_From__c == null ){
                            multiOrd.Ordered_From__c = user.Contact.AccountId;
                        }
                    }
                }
                
                system.debug( LoggingLevel.ERROR ,'multiOrd: ' + multiOrd );
                
                insert multiOrd;
            }
            
            //Create Product Price
            //Map<Id, Product_Price__c> pp2Ins = new Map<Id, Product_Price__c>();
            //Map<Id, FR_Order_Product__c> ordProd2Ins = new Map<Id, FR_Order_Product__c>();
            Map<String, FR_Order_Product__c> ordProd2Ins = new Map<String, FR_Order_Product__c>();
            
            Map<String, FR_Order_Product__c> orderProdByHDProd = new Map<String, FR_Order_Product__c>();
            
            for( FR_Order_Product__c orderProd : [SELECT Id, PN_Code__c, MF_Product__c, Quantity__c, Product_Price__r.Price_List_Title__r.Price_List_TitleOld_Id__c, Product_Price__r.Selling_Price__c, Product_Price__r.HD_Product__c, HD_Product_Price_Id__c, Product_Price__r.HD_Product_Price__c FROM FR_Order_Product__c WHERE Order__c IN :orders.keySet() ] ){
                if( isMF && orderProd.MF_Product__c == true ){
                    //Ignore this Producto
                    continue;
                }
                
                /*
                SW-22740
                Changed logic from checking Product Price Id matching to checking for Product Code
                and changing the new Order Product's Product Price Id to the one from the Order
                
                if( ordProd2Ins.containsKey(orderProd.HD_Product_Price_Id__c) == false ){
                    
                    FR_Order_Product__c newOrderProd = new FR_Order_Product__c();
                    newOrderProd.Order__c = multiOrd.Id;
                    if( isMF ){
                        newOrderProd.Product_Price__c = orderProd.HD_Product_Price_Id__c;
                    }
                    newOrderProd.Quantity__c = 0;
                    
                    ordProd2Ins.put(orderProd.HD_Product_Price_Id__c, newOrderProd);
                    //quantities.put( orderProd.HD_Product_Price_Id__c, 0 );
                    
                    orderProdByHDProd.put( orderProd.Product_Price__r.HD_Product__c, newOrderProd );
                }
                */

                String findCode = '';
                if(priceList.Price_List_TitleOld_Id__c != null){
                	findCode = priceList.Price_List_TitleOld_Id__c + '-' + orderProd.PN_Code__c; // Price_List_TitleOld_Id__c this field it's never and ID (it's a number).
                }else{
                    findCode = String.valueOf(priceList.Id).substring(0, 15) + '-' + orderProd.PN_Code__c;
                }

                //add existent quantity in the order product on consolidation order
                if( !multiOrderExistingProds.isEmpty() && multiOrderExistingProds.containsKey( orderProd.PN_Code__c ) && !ordProd2Ins.containsKey( orderProd.PN_Code__c ) ){
                    ordProd2Ins.put( orderProd.PN_Code__c, multiOrderExistingProds.get( orderProd.PN_Code__c ) );
                    orderProdByHDProd.put(findCode, multiOrderExistingProds.get( orderProd.PN_Code__c ) );
                }

                //create new producto order                
                if( ordProd2Ins.containsKey( orderProd.PN_Code__c ) == false ){
                    FR_Order_Product__c newOrderProd = new FR_Order_Product__c();
                    newOrderProd.Order__c = multiOrd.Id;
                    
                    newOrderProd.Quantity__c = 0;
                    
                    ordProd2Ins.put(orderProd.PN_Code__c, newOrderProd);

                    orderProdByHDProd.put(findCode, newOrderProd );
                }
                
                //add quantity for each product in the consolidated orders
                ordProd2Ins.get(orderProd.PN_Code__c).Quantity__c = ordProd2Ins.get(orderProd.PN_Code__c).Quantity__c + orderProd.Quantity__c;
            }

            List<FR_Order_Product__c> lOrder2Ins = new List<FR_Order_Product__c>();

            System.debug(LoggingLevel.ERROR, '*** orderProdByHDProd: ' + orderProdByHDProd.keySet());
            //SW-25394
            for( Product_Price__c pp : [SELECT Id, Unique_Product_Price_ID__c, HD_Product__c, PN_Code__c FROM Product_Price__c WHERE Unique_Product_Price_ID__c IN :orderProdByHDProd.keySet()] ){
                    FR_Order_Product__c fOrder = orderProdByHDProd.get(pp.Unique_Product_Price_ID__c);
                    if (ordProd2Ins.containsKey( pp.PN_Code__c )) {
                        fOrder.Quantity__c = ordProd2Ins.get(pp.PN_Code__c).Quantity__c;
                    }
                    fOrder.Product_Price__c = pp.Id;


                    lOrder2Ins.add(fOrder);
            }

            //SW-22740
            /*for( Product_Price__c pp : [SELECT Id, HD_Product__c FROM Product_Price__c WHERE Price_List_Title__c = :selectedPriceList AND HD_Product__c IN :orderProdByHDProd.keySet() ] ){
            }*/
            
            /*
            SW-22740
            if( isFP ){
                system.debug('selectedPriceList: ' + selectedPriceList);
                //Set the Product Price for FP logic
                for( Product_Price__c pp : [SELECT Id, HD_Product__c FROM Product_Price__c WHERE Price_List_Title__c = :selectedPriceList AND HD_Product__c IN :orderProdByHDProd.keySet() ] ){
                    orderProdByHDProd.get(pp.HD_Product__c).Product_Price__c = pp.Id;
                }
            }
            */
            
            System.debug(LoggingLevel.ERROR, '*** lOrder2Ins: ' + lOrder2Ins);
            System.debug(LoggingLevel.ERROR, '*** newMultiOrder: ' + newMultiOrder);

            if( !lOrder2Ins.isEmpty() ){
            	for(FR_Order_Product__c p : lOrder2Ins){
            		system.debug(p);
            	}
                upsert lOrder2Ins;
            }else if( !newMultiOrder.equalsIgnoreCase('false') ){
                //If they are creating a new Multi Order and no Products can be added, show an error.
                throw new MyException( Label.HDC_Order_No_Products_Available );
            }
            
            
            //Create Order Product
            List<FR_Order__c> ord2Upd = new List<FR_Order__c>();
            
            for( Id ordId : orders.keySet() ){
                FR_Order__c ord = orders.get(ordId);
                ord.Multi_Order__c = multiOrd.Id;
                ord2Upd.add(ord);
            }
            
            update ord2Upd;
            
            selectedMultiOrder = multiOrd.Id;
            
            showDone = true;
            showForm = false;
        }catch(MyException e){
            Database.rollback(sp);
            showError = e.getMessage();
            
            GlobalHelperMethods.debugErrorMsg(e);
        }catch(Exception e){
            Database.rollback(sp);
            showException = e.getMessage();
            showForm = false;
            showError = '';
            
            GlobalHelperMethods.debugErrorMsg(e);
        }
        
        return null;
    }
    
    /*
        Multi Order Picklist
    */
    
    public List<SelectOption> getMultiOrders(){
        List<SelectOption> options = new List<SelectOption>();
        
        if( isMF ){

            for( FR_Order__c ord : [SELECT Id, Name FROM FR_Order__c WHERE Status__c = 'Draft' AND Ordered_By_Franchisee__c = :dummyOrder.Ordered_By_Franchisee__c AND Price_List_Title__c = :dummyOrder.Price_List_Title__c ] ){
                options.add(new SelectOption( ord.Id, ord.Name));
            }
        }else if( isFP ){
            Set<Id> priceListIds = Multi_Order_Ctl.FindPriceList( recordTypeName, orderIds );
            
            for( FR_Order__c ord : [SELECT Id, Name FROM FR_Order__c WHERE Status__c = 'Draft' AND Ordered_By_Franchisee__c = :dummyOrder.Ordered_By_Franchisee__c AND Price_List_Title__c IN :priceListIds ] ){
                options.add(new SelectOption( ord.Id, ord.Name));
            }
        }
        
        return options;
    }
    
    public String getSelectedMultiOrder(){
        return selectedMultiOrder;
    }
    
    public void setSelectedMultiOrder(String multiOrderId){
        selectedMultiOrder = multiOrderId;
    }

    public String getDefaultPriceList(){
        return defaultPriceList;
    }
    
    public void setDefaultPriceList(String dPriceList){
        defaultPriceList = dPriceList;
    }
    
    /*
        Price List Picklist
    */
    public List<SelectOption> getPriceLists(){
        List<SelectOption> options = new List<SelectOption>();
        
        Set<Id> priceListIds = Multi_Order_Ctl.FindPriceList( recordTypeName, orderIds );
        
        for( Price_List_Title__c plt : [SELECT Id, Name FROM Price_List_Title__c WHERE Id IN :priceListIds ] ){
            options.add(new SelectOption( plt.Id, plt.Name));
        }

        return options;
    }

    /*
        HD Price List Picklist step 2
    */
    public List<SelectOption> getHDPriceLists(){
        List<SelectOption> options = new List<SelectOption>();
        
        for( Price_List_Title__c plt : [SELECT Id, Name FROM Price_List_Title__c WHERE Active_Formula__c = TRUE AND RecordType.Name = 'HD'] ){
            options.add(new SelectOption( String.valueOf(plt.Id).substring(0, 15), plt.Name));
        }

        return options;
    }
    
    public String getSelectedPriceList() {
        return selectedPriceList;
    }
        
    public void setSelectedPriceList( String priceListId ) {
        this.selectedPriceList = priceListId;
    }
    
    /*
        Get Price List Logic
    */
    
    public static Set<Id> FindPriceList( String multiOrderType, Set<String> orderIds ){
        Multi_Order_Ctl.withSharing ws = new Multi_Order_Ctl.withSharing();
        return ws.FindPriceListWithSharing(multiOrderType, orderIds);
    }
    
    public with sharing class withSharing{
        
        public Set<Id> FindPriceListWithSharing( String multiOrderType, Set<String> orderIds ){
            //Finds the Price List Title to be assigned to the New Multi Order that gets created.
            Set<Id> priceListTitleIds = new Set<Id>();
            Map<Id, FR_Order__c> orders = new Map<Id, FR_Order__c>();
            
            for( FR_Order__c ord : [SELECT Id, HD_Price_List_Title_ID__c, Price_List_Title__c FROM FR_Order__c WHERE Id IN :orderIds ] ){
                orders.put(ord.Id, ord);
            }
            
            if( multiOrderType == 'MF' ){
                //Logic for Multi Order for MR record types
                //According to design, only 1 Price List Title is returned
                Id priceListTitleId = orders.values()[0].HD_Price_List_Title_ID__c;
                
                if( priceListTitleId == null ){
                    priceListTitleId = orders.values()[0].Price_List_Title__c;
                }
                
                priceListTitleIds.add( priceListTitleId );
            }
            
            if( multiOrderType == 'FP' ){
                //Logic for Multi Order for FP record types
                //According to design, there could be more than 1 Price List Titles returned.
                //If so, a popup is shown, and the User selects which to use.
                Set<Id> pltIds = new Set<Id>();
                for( FR_Order__c ord : orders.values() ){
                    pltIds.add( ord.HD_Price_List_Title_ID__c );
                }
                
                Boolean inactivePLT = false;
                
                for( Price_List_Title__c plt : [SELECT Id, Active_Formula__c FROM Price_List_Title__c WHERE HD_Price_List_Title__c IN :pltIds ] ){
                    inactivePLT |= !plt.Active_Formula__c;
                    
                    if( plt.Active_Formula__c ){
                        priceListTitleIds.add( plt.Id );
                    }
                }
                
                if( inactivePLT && priceListTitleIds.isEmpty() ){
                    throw new MyException( Label.HDC_Order_Price_List_Title_is_not_Active );
                }
            }

            
            return priceListTitleIds;
        }
    }
}