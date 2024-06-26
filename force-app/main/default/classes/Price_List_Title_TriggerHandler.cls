/******************************************************************************* 
Name              : Price_List_Title_TriggerHandler
Description       : Handler the trigger on Price List Title
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G.Fernandez                   11/04/2016              
*******************************************************************************/

public class Price_List_Title_TriggerHandler {
   public static void executeTriggerHandler(){
        
        //  ---------------------------- BEFORE EVENTS -----------------------------
        
        /*
        if (Trigger.isBefore && Trigger.isInsert) // Before Update
        {
            
        }
        
        else if (Trigger.isBefore && Trigger.isUpdate) // Before Insert
        {
            
        }
        
        else if (Trigger.isBefore && Trigger.isDelete) // Before Delete
        {
        }
        */
        
        //  ---------------------------- AFTER EVENTS -----------------------------
        
        //
        if (Trigger.isAfter && Trigger.isInsert) // After Insert
        {
            createRelatedProductPrice();
            CreatePriceListAssignment();  
        }
        
        if (Trigger.isAfter && Trigger.isUpdate) // After Update
        {
            CreatePriceListAssignment();
        }
        /*      
        else if (Trigger.isAfter && Trigger.isDelete) // After Delete
        {
            
        }
        else if (Trigger.isAfter && Trigger.isUnDelete) // After UnDelete
        {
            
        }
        
        */  
    } 

    /******************************************************************************* 
    Name              : createRelatedProductPrice
    Description       : Handler the trigger on Price List Title
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G.Fernandez             11/04/2016             Yaara Nadir               SW-18898
    2. G.Fernandez             19/06/2017             Yaara Nadir               SW-25392
    3. G.Fernandez             22/08/2017             Yaara Nadir               SW-25942
    *******************************************************************************/  

    public static void createRelatedProductPrice(){
        if( HD_TriggerSettings.IsTriggerActive('createRelatedProductPrice') ){

            Id franchiseType = Schema.SObjectType.Price_List_Title__c.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();
            // Added By Rashad , requested By Merav 08/01/2018
            
            Id HDPLtype = Schema.SObjectType.Price_List_Title__c.getRecordTypeInfosByName().get('HD').getRecordTypeId();
            Map <Id,Id> HDPLTSource_NewIds = new Map <Id,Id> ();
            
            // Added By Rashad , requested By Merav 08/01/2018
            Id mfPPType = Schema.SObjectType.Product_Price__c.getRecordTypeInfosByName().get('MF').getRecordTypeId();
            //map HD_Price_List_Title__c,newpricelist
            Map<Id,Price_List_Title__c> hdPriceListIds = new Map<Id,Price_List_Title__c>();
            Map<Id,Product_Price__c> hdProductPriceMap = new Map<Id,Product_Price__c>();
            Set<Id> priceListIds = new Set<Id>();
            Map<Id,Price_List_Title__c> sourcePriceListIds = new Map<Id,Price_List_Title__c>();

            for(Price_List_Title__c priceListTitle : (List<Price_List_Title__c>) trigger.new){
                Boolean cond = Trigger.isInsert && priceListTitle.RecordTypeId == franchiseType && priceListTitle.HD_Price_List_Title__c != null ;
// Start Added By Rashad , requested By Merav 08/01/2018 *******************************************************************************************************************************
                
                Boolean HDcond = Trigger.isInsert && priceListTitle.RecordTypeId == HDPLtype && priceListTitle.Cloned_From__c != null ;
                
// End Added By Rashad , requested By Merav 08/01/2018 *******************************************************************************************************************************

                if(cond){
                    hdPriceListIds.put(priceListTitle.HD_Price_List_Title__c, priceListTitle);
                    priceListIds.add(priceListTitle.Id);
                    if (priceListTitle.Cloned_From__c != null) {
                        sourcePriceListIds.put(priceListTitle.Cloned_From__c, null);
                    }               
                }
// Start Added By Rashad , requested By Merav 08/01/2018 *******************************************************************************************************************************
                if (HDcond){
                    HDPLTSource_NewIds.Put (priceListTitle.Cloned_From__c,priceListTitle.Id);
                }
            }
            
            if (!HDPLTSource_NewIds.isEmpty()){
                List <Product_Price__c> PPHdToInsertList = new  List <Product_Price__c> ();
                List <Product_Price_by_Quantity__c> QQHdToInsertList = new  List <Product_Price_by_Quantity__c> ();
                Set <Id> PLTS = new Set <Id>();
                plts.addAll(HDPLTSource_NewIds.KeySet());
                String ProductPriceQuery ='select (select Maximum_Quantity__c,Minimum_Quantity__c,Price__c,Product_Price__c ,CurrencyIsoCode,id from Product_Price_by_Quantity__r ORDER BY Minimum_Quantity__c ASC) ,Id,Price_List_Title__c,HD_Product__c,Old_Price__c,Selling_Price__c,Recommended_Price_for_Student__c,Created_by_Trigger__c from Product_Price__c where Price_List_Title__c in:plts And Active__c=true';
                Map <ID,SObject > PPToClone = new Map <ID,SObject >(Database.query(ProductPriceQuery));
                for (SObject PP : PPToClone.Values()) 
                {
                    Product_Price__c temp = (Product_Price__c)PP.Clone();
                    for (Product_Price_by_Quantity__c qq : temp.Product_Price_by_Quantity__r)
                    {
                        Product_Price_by_Quantity__c qTemp = qq.Clone();
                        //qtemp.Product_Price__c =   HDPLTSource_NewIds.get (temp.Price_List_Title__c);
                        QQHdToInsertList.add(qtemp);
                    }
                    temp.Price_List_Title__c = HDPLTSource_NewIds.get (temp.Price_List_Title__c);
                    PPHdToInsertList.add(temp);
                    
                }
                Database.SaveResult[] PPList=DataBase.insert(PPHdToInsertList,False);
                List <HD_Log__c> HDLOGLIST = new List <HD_Log__c> ();

                for (Database.SaveResult PPE : PPList) {
                    IF (!ppe.isSuccess())
                        for(Database.Error err : PPE.getErrors()) {
                            
                             HDLOGLIST.add(new HD_Log__c( Error_Description__c = err.getMessage(),Process_Name__c ='Clone PP',Status__c = 'Fail'));     
                        }
                }
                insert HDLOGLIST;
                //Insert PPHdToInsertList;
                HDPLTSource_NewIds.clear();
                
                for (Product_Price__c p : PPHdToInsertList)
                {
                   HDPLTSource_NewIds.put (p.getCloneSourceId(),P.id);
                }
                for (Product_Price_by_Quantity__c q : QQHdToInsertList)
                {
                    q.Product_Price__c=HDPLTSource_NewIds.get(q.Product_Price__c);
                    q.Deactivate_VR__c = true;
                    System.debug('@@@@@@@@@@ '+ q.Minimum_Quantity__c+'@@@@@@@@ Product Price '+q.Product_Price__c);
                }
                 Database.SaveResult[] QQList=DataBase.insert(QQHdToInsertList,False);
                //insert  QQHdToInsertList; 
            }
// End Added By Rashad , requested By Merav 08/01/2018 *******************************************************************************************************************************
            if(!hdPriceListIds.isEmpty()){
                User currUser = [SELECT Contact.Account.CurrencyIsoCode FROM User WHERE Id = :UserInfo.getUserId()];

                /*1.1.1.3.1 For each Product_Price__c in HD Price List Title, Need to create related Product_Price__c connected to the Product_Price__c as HD_Product_Price__c */
                Map<Id,Product_Price__c> productPrice2In = new Map<Id,Product_Price__c>();
                Map<Id,Price_List_Title__c> pltMap = new Map<Id,Price_List_Title__c>();

                List<Product_Price__c> productPriceList = [SELECT Id, Unique_Product_Price_ID__c, PN_Code__c, Price_List_Title__c, HD_Product__c, HD_Product__r.PN_Code__c, HD_Product_Price__c, Recommended_Price_for_Student__c, Selling_Price__c, Price_List_Title__r.Price_List_TitleOld_Id__c, (SELECT Maximum_Quantity__c, Minimum_Quantity__c, Price__c FROM Product_Price_by_Quantity__r ORDER BY Minimum_Quantity__c ASC) FROM Product_Price__c WHERE (Price_List_Title__c IN :hdPriceListIds.keySet() OR Price_List_Title__c IN :sourcePriceListIds.keySet())];
                Map<Id,Map<String,Product_Price__c>> plSourcesProdPrices = new Map<Id,Map<String,Product_Price__c>>();
                Map<Id,Map<String,Product_Price__c>> plSourcesProdPricesPN = new Map<Id,Map<String,Product_Price__c>>();
                for(Product_Price__c productPrice : productPriceList){  

                    if(sourcePriceListIds.containsKey(productPrice.Price_List_Title__c)){
                        sourcePriceListIds.put(productPrice.Price_List_Title__c, productPrice.Price_List_Title__r);

                        if(!plSourcesProdPrices.containsKey(productPrice.Price_List_Title__c)){
                            plSourcesProdPrices.put(productPrice.Price_List_Title__c ,new Map<String,Product_Price__c>());
                            plSourcesProdPricesPN.put(productPrice.Price_List_Title__c ,new Map<String,Product_Price__c>());
                        }
                        if(!plSourcesProdPrices.get(productPrice.Price_List_Title__c).containsKey(productPrice.Unique_Product_Price_ID__c)){
                            plSourcesProdPrices.get(productPrice.Price_List_Title__c).put(productPrice.Unique_Product_Price_ID__c,productPrice);
                            plSourcesProdPricesPN.get(productPrice.Price_List_Title__c).put(productPrice.PN_Code__c,productPrice);
                        }
                    }
                }

                Set<String> checkUnique = new Set<String>();
                
                for(Product_Price__c productPrice : productPriceList){  

                    if(hdPriceListIds.containsKey(productPrice.Price_List_Title__c)){

                        Price_List_Title__c pltFromTrigger = hdPriceListIds.get(productPrice.Price_List_Title__c);

                        Product_Price__c newProductPrice = new Product_Price__c();
                        newProductPrice.HD_Product__c = productPrice.HD_Product__c;
                        newProductPrice.Price_List_Title__c = pltFromTrigger.Id;
                        newProductPrice.Price_Modify_Date__c = System.now();
                        newProductPrice.Selling_Price__c = null;
                        newProductPrice.HD_Product_Price__c = productPrice.Id;
                        //newProductPrice.Unique_Product_Price_ID__c = productPrice.PN_Code__c + '-' + newProductPrice.Price_List_Title__c;
                        
                        if(pltFromTrigger.RecordTypeId == franchiseType){
                            newProductPrice.RecordTypeId = mfPPType;
                        }
                        
                        if(pltFromTrigger.Cloned_From__c == null){                  
                            //newProductPrice
                            newProductPrice.CurrencyIsoCode = UserInfo.getDefaultCurrency();
                            if(productPrice.Recommended_Price_for_Student__c != null && pltFromTrigger.Exchange_Rate_from_HD_Currency__c != null){
                                newProductPrice.Recommended_Price_for_Student__c = productPrice.Recommended_Price_for_Student__c * pltFromTrigger.Exchange_Rate_from_HD_Currency__c;
                            }
                        }else{  
                            //clone newProductPrice
                            Id origId = pltFromTrigger.Cloned_From__c;
                            if(plSourcesProdPrices.containsKey(origId)){
                                /*
                                    //SearchOldProductPrice
                                    Find the Product_Price__c from the old (Cloned) Price List Title where
                                    Unique_Product_Price_ID__c = 
                                    If Price_List_TitleOld_Id__c is not null
                                    Concatenate (Price_List_Title__c. Price_List_TitleOld_Id__c,”-“, PN_Code__c)
                                    If Price_List_TitleOld_Id__c is null
                                    Concatenate (Price_List_Title__c. Id,”-“, PN_Code__c)
                                */

                                String findCode = '';
                                if(sourcePriceListIds.get(origId) != null && sourcePriceListIds.get(origId).Price_List_TitleOld_Id__c != null){
                                    findCode = sourcePriceListIds.get(origId).Price_List_TitleOld_Id__c + '-' + productPrice.PN_Code__c;
                                }else{
                                    findCode = String.valueOf(origId).substring(0,15) + '-' + productPrice.PN_Code__c;
                                }

                                /*
                                    If Found Product_Price__c
                                    The Selling Price will be equal to Product_Price__c. Selling_Price__c
                                    If not found: Selling Price = Null
                                */
                                Map<String,Product_Price__c> sourceProdPrices = plSourcesProdPrices.get(origId);
                                if(sourceProdPrices.containsKey(findCode)){
                                    newProductPrice.Selling_Price__c = sourceProdPrices.get(findCode).Selling_Price__c;
                                    newProductPrice.Recommended_Price_for_Student__c = sourceProdPrices.get(findCode).Recommended_Price_for_Student__c;                 
                                }

                            }

                            //price products on cloned record
                            if(currUser.ContactId != null && currUser.Contact.AccountId != null){
                                newProductPrice.CurrencyIsoCode = currUser.Contact.Account.CurrencyIsoCode;
                            }
                            newProductPrice.Price_Modify_Date__c = System.now();
                        }

                        String uniqueCode = '';
                        if(pltFromTrigger.Price_List_TitleOld_Id__c != null){
                            uniqueCode = pltFromTrigger.Price_List_TitleOld_Id__c + '-' + productPrice.PN_Code__c;
                        }else{
                            uniqueCode = pltFromTrigger.Id + '-' + productPrice.PN_Code__c;
                        }

                        if(!checkUnique.contains(uniqueCode)){
                            checkUnique.add(uniqueCode);
                            hdProductPriceMap.put(productPrice.Id,productPrice);
                            productPrice2In.put(productPrice.Id,newProductPrice);
                            if(!pltMap.containsKey(newProductPrice.Price_List_Title__c)){
                                pltMap.put(newProductPrice.Price_List_Title__c,pltFromTrigger);
                            }
                        }
                    }
                }

                if(!productPrice2In.isEmpty()){
                    Database.SaveResult[] srl = Database.insert(productPrice2In.values());

                    //SW-25942 copy all the Product Price by Quantity records that is related to the Product price
                    Map<Id,Product_Price__c> newPPIds = new Map<Id,Product_Price__c>();
                    for(Integer i = 0; i < srl.size(); i++){
                        Database.SaveResult sr = srl.get(i);

                        if(sr.isSuccess() || System.Test.isRunningTest()){
                            Product_Price__c oldPP = hdProductPriceMap.values()[i];
                            newPPIds.put(sr.getId(),oldPP);
                        }
                    }

                    List<Product_Price_by_Quantity__c> ppq2ins = new List<Product_Price_by_Quantity__c>();
                    if(!newPPIds.isEmpty()){
                        for (Product_Price__c newPP : [SELECT Price_List_Title__r.CurrencyIsoCode, Price_List_Title__r.Cloned_From__c, PN_Code__c FROM Product_Price__c WHERE Id IN :newPPIds.keySet() ]) {
                            //checking each PP copied to the new plt triggered to get PPQ
                            //if was cloned, get PPQ from PLT
                            if (newPP.Price_List_Title__r.Cloned_From__c != null) {
                                if (plSourcesProdPricesPN.containsKey(newPP.Price_List_Title__r.Cloned_From__c)) {

                                    Map<String,Product_Price__c> oldProdPrices = plSourcesProdPricesPN.get(newPP.Price_List_Title__r.Cloned_From__c);

                                    if(oldProdPrices != null && oldProdPrices.containsKey(newPP.PN_Code__c)){
                                        for (Product_Price_by_Quantity__c ppQ : oldProdPrices.get(newPP.PN_Code__c).Product_Price_by_Quantity__r) {
                                            Product_Price_by_Quantity__c newProductPriceQuantity = ppQ.clone();
                                            newProductPriceQuantity.Product_Price__c = newPP.Id;
                                            newProductPriceQuantity.CurrencyIsoCode = newPP.Price_List_Title__r.CurrencyIsoCode;
                                            ppq2ins.add(newProductPriceQuantity);
                                        }
                                    }
                                }
                            }else{
                            //if plt is new, get PPQ from HDPLT and edit to 0
                                for (Product_Price_by_Quantity__c ppQ : newPPIds.get(newPP.Id).Product_Price_by_Quantity__r) {
                                    Product_Price_by_Quantity__c newProductPriceQuantity = ppQ.clone();
                                    newProductPriceQuantity.Product_Price__c = newPP.Id;
                                    newProductPriceQuantity.CurrencyIsoCode = newPP.Price_List_Title__r.CurrencyIsoCode;
                                    //New- Clone all the related Product Price by Quantity with Price=0 
                                    newProductPriceQuantity.Price__c = 0;
                                    ppq2ins.add(newProductPriceQuantity);
                                }
                            }

                            
                        }

                        if (!ppq2ins.isEmpty()) {
                            insert ppq2ins;  
                        }
                    }
                }
            }

        }
    }
    
    /******************************************************************************* 
    Name              : CreatePriceListAssignment
    Description       : On Replace Price List Title not being null, clones the Price List Assignment from the Replace Price List Title
                        to the new/updated record
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. Sergio             07/05/2016                Yaara Nadir             SW-20273
    *******************************************************************************/  

    public static void CreatePriceListAssignment (){
        
        if( HD_TriggerSettings.IsTriggerActive('CreatePriceListAssignment') ){
            
            Map<Id, Set<Integer>> repPLT = new Map<Id, Set<Integer>>();
            
            for(Integer i=0; i < trigger.size; i++){
                Price_List_Title__c newPLT = (Price_List_Title__c) trigger.new[i];
                Boolean condition = newPLT.Replace_Price_List_Title__c != null;
                
                if( trigger.isUpdate ){
                    condition &= ((Price_List_Title__c) trigger.oldMap.get(newPLT.Id)).Replace_Price_List_Title__c != newPLT.Replace_Price_List_Title__c;
                }
                
                if( condition ){
                    if( !repPLT.containsKey( newPLT.Replace_Price_List_Title__c ) ){
                        repPLT.put( newPLT.Replace_Price_List_Title__c, new Set<Integer>() );
                    }
                    repPLT.get( newPLT.Replace_Price_List_Title__c ).add(i);
                }
            }
            
            if( !repPLT.isEmpty() ){
                List<Price_List_Title_Assignment__c> plta2Ins = new List<Price_List_Title_Assignment__c>();
                Set<String> checkUnique = new Set<String>();
                
                for( Price_List_Title_Assignment__c plta : [SELECT Id, Price_List_Title__c, Franchise__c, Franchise__r.Account_No_in_Infoman__c FROM Price_List_Title_Assignment__c WHERE Price_List_Title__c IN :repPLT.keySet() ] ){
                    for( Integer i : repPLT.get( plta.Price_List_Title__c ) ){
                        /*
                        IF( ISBLANK(Price_List_Title__r.Price_List_TitleOld_Id__c), Price_List_Title__c, 
                        Price_List_Title__r.Price_List_TitleOld_Id__c) 
                        & "-" & 
                        IF ( ISBLANK(Franchise__r.Account_No_in_Infoman__c), Franchise__c, 
                        TEXT(Franchise__r.Account_No_in_Infoman__c))
                        */
                        Price_List_Title_Assignment__c newPLTA = plta.clone( false, true );
                        newPLTA.Price_List_Title__c = trigger.new[i].Id;
                        String uniqueCode = '';
                        Price_List_Title__c newPLT = (Price_List_Title__c) trigger.new[i];
                        if(newPLT.Price_List_TitleOld_Id__c != null){
                            uniqueCode = newPLT.Price_List_TitleOld_Id__c + '-';
                        }else{
                            uniqueCode = newPLT.Id + '-';
                        }

                        if(plta.Franchise__r.Account_No_in_Infoman__c != null){
                            uniqueCode += plta.Franchise__r.Account_No_in_Infoman__c;
                        }else{
                            uniqueCode += plta.Franchise__c;
                        }

                        if(!checkUnique.contains(uniqueCode)){
                            checkUnique.add(uniqueCode);
                            plta2Ins.add( newPLTA );
                        }

                    }
                }
                
                if( !plta2Ins.isEmpty() ){
                    insert plta2Ins;
                }
            }
        }
        
    }
}