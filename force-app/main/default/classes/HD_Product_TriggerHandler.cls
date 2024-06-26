/******************************************************************************* 
Name              : HD_Product_TriggerHandler
Description       : Handler the before/after trigger on HD_Product__c
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez         	06/18/2017
*******************************************************************************/
public with sharing class HD_Product_TriggerHandler {
    
	public static void executeTriggerHandler(){
		
		//  ---------------------------- BEFORE EVENTS -----------------------------
		/*if( trigger.isBefore && trigger.isInsert ){
		}*/
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		if (Trigger.isAfter && Trigger.isInsert){
			NewProductPrice();
		}
		else if (Trigger.isAfter && Trigger.isUpdate){
			NewProductPrice();
		}
	}

	/******************************************************************************* 
	Name              : NewProductPrice
	Description       : Populates the Price List on Order if the User has access to only 1 Price List
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez         	06/18/2017         		Yaara Nadir				  [SW-25391]
	*******************************************************************************/
	
	public static void NewProductPrice(){
		if(HD_TriggerSettings.IsTriggerActive('NewProductPrice') ){

			Id hdType = Product_Price__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('HD').getRecordTypeId();
			Id mfType = Product_Price__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('MF').getRecordTypeId();

			Map<String,List<HD_Product__c>> programProducts = new Map<String,List<HD_Product__c>>();
			List<HD_Product__c> lHdProds = new List<HD_Product__c>();
			Set<Id> hdProdIds = new Set<Id>();
			for(Integer i=0; i < trigger.size; i++ ){
				HD_Product__c r = (HD_Product__c)trigger.new[i];
				Boolean cond = false;
				if(Trigger.isUpdate){
					HD_Product__c rOld = (HD_Product__c)trigger.old[i];
					cond = rOld.Product_Status__c != r.Product_Status__c && r.Product_Status__c == 'Active';
					cond = cond || rOld.Program_Type__c != r.Program_Type__c;
				}else if(r.Product_Status__c == 'Active'){
					cond = true;
				}

				if(cond){
					lHdProds.add(r);
					hdProdIds.add(r.Id);
				}
			}

			//group program types
			for(HD_Product__c hdprod : lHdProds){
                if(!String.isEmpty(hdprod.Program_Type__c)){
                    String[] programs = hdprod.Program_Type__c.split(';');
                    for(String program : programs){
                        if (!programProducts.containsKey(program)) {
                            programProducts.put(program,new List<HD_Product__c>()); 
                        }
                        programProducts.get(program).add(hdprod);
                    }
                }
            }
            //Step 1 - HD Product Price

			//get all hd price list title
			if(!programProducts.isEmpty()){
				Set<String> existentProductPrices = new Set<String>();
				Map<String,Product_Price__c> productPrices = new Map<String,Product_Price__c>();
				Set<Id> pltIds = new Set<Id>();
				List<Price_List_Title__c> pltitles = [SELECT Id, Program_Type__c, (SELECT HD_Product__c FROM Product_Price_Lists__r WHERE HD_Product__c IN :hdProdIds) FROM Price_List_Title__c WHERE Program_Type__c IN :programProducts.keySet() AND RecordType.Name = 'HD' AND (Active__c = TRUE OR End_Date__c >= TODAY OR End_Date__c = Null)];
				for(Price_List_Title__c plt : pltitles){
					if(!plt.Product_Price_Lists__r.isEmpty()){
						for(Product_Price__c prodPrice : plt.Product_Price_Lists__r){
							String key = plt.Id + '_' + prodPrice.HD_Product__c;
							if(!productPrices.containsKey(key)){
								productPrices.put(key,prodPrice);
							}
						}
					}

					for(HD_Product__c hdProd : programProducts.get(plt.Program_Type__c)){
						//linking hd products to price list title by relating product prices
						Product_Price__c newProduct = new Product_Price__c();
						newProduct.Price_List_Title__c = plt.Id;
						newProduct.Selling_Price__c = 0;
						newProduct.HD_Product__c = hdProd.Id;
						newProduct.Price_Modify_Date__c = System.now();
						newProduct.RecordTypeId = hdType;
						newProduct.Created_by_Trigger__c = true;
						String key = plt.Id + '_' + hdProd.Id;
						
						if(!productPrices.containsKey(key)){
							productPrices.put(key,newProduct);
						}

						pltIds.add(plt.Id);
					}
				}

				if(!productPrices.isEmpty()){
					Database.insert(productPrices.values(),false);

					List<Product_Price__c> childProductPrices = new List<Product_Price__c>();
					//Step 2 - Franchisee Product Price
					for(Price_List_Title__c plt : [SELECT Id, HD_Price_List_Title__c , (SELECT HD_Product__c FROM Product_Price_Lists__r WHERE HD_Product__c IN :hdProdIds) FROM Price_List_Title__c WHERE HD_Price_List_Title__c IN :pltIds AND Active_Formula__c = TRUE AND DBAmp_Stop_Migration__c != NULL AND RecordType.Name = 'Franchisee']){
						Set<String> existentPP = new Set<String>();

						if(!plt.Product_Price_Lists__r.isEmpty()){
							for(Product_Price__c prodPrice : plt.Product_Price_Lists__r){
								existentPP.add(plt.Id + '_' + prodPrice.HD_Product__c);
							}
						}

						for(String key : productPrices.keySet()){
							Product_Price__c prodPrice = productPrices.get(key);
							if(key == plt.HD_Price_List_Title__c + '_' + prodPrice.HD_Product__c && !existentPP.contains(key)){
								//For each of the HD Product Price created in step 1- need to create related MF Product Price  (Product_Price__c  with record type = MF)
								Product_Price__c newProduct = new Product_Price__c();
								newProduct.Price_List_Title__c = plt.Id;
								newProduct.Selling_Price__c = 0;
								newProduct.HD_Product__c = prodPrice.HD_Product__c;
								newProduct.HD_Product_Price__c = prodPrice.Id;
								newProduct.Price_Modify_Date__c = System.now();
								newProduct.RecordTypeId = mfType;
								newProduct.Created_by_Trigger__c = true;

								childProductPrices.add(newProduct);
							}
						}
					}

					if(!childProductPrices.isEmpty()){
						Database.insert(childProductPrices,false);
					}

				}


			}
		}
	}

}