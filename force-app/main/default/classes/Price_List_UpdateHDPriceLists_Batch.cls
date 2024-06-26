global class Price_List_UpdateHDPriceLists_Batch implements Database.Batchable<sObject>{
	public List<Id> restrict2Ids = new List<Id>();
    public String query = 'SELECT Id, PN_Code__c, Price_List_Title_Name__c, Product_Name__c, Recommended_Price_for_Student__c, Selling_Price__c FROM Product_Price_Import__c ';
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        if( restrict2Ids.isEmpty() == false ){
            query += ' WHERE Id IN :restrict2Ids';
        }        
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Sobject> scope) {
    	Map<String, Map<String, Product_Price_Import__c>> pnCodeByPLT = new Map<String, Map<String, Product_Price_Import__c>>();
    	Map<String, Map<String, Product_Price_Import__c>> pnCodeByPLT_NotFound = new Map<String, Map<String, Product_Price_Import__c>>();
    	Set<String> pnCodes = new Set<String>();
    	
    	for( Product_Price_Import__c ppi : (List<Product_Price_Import__c>) scope ){
    		String priceListTitleName = ppi.Price_List_Title_Name__c.toLowerCase();
    		
    		if( pnCodeByPLT.containsKey( priceListTitleName ) == false ){
    			pnCodeByPLT.put( priceListTitleName, new Map<String, Product_Price_Import__c>() );
    			pnCodeByPLT_NotFound.put( priceListTitleName, new Map<String, Product_Price_Import__c>() );
    		}
    		
    		pnCodeByPLT.get( priceListTitleName ).put( ppi.PN_Code__c, ppi );
    		pnCodeByPLT_NotFound.get( priceListTitleName ).put( ppi.PN_Code__c, ppi );
    		
    		pnCodes.add( ppi.PN_Code__c );
    	}
    	
    	List<Product_Price__c> pp2Upd = new List<Product_Price__c>();
    	
    	for( Product_Price__c pp : [SELECT Id, Price_List_Title__r.Name, PN_Code__c, Selling_Price__c, Recommended_Price_for_Student__c FROM Product_Price__c WHERE PN_Code__c IN : pnCodes AND Price_List_Title__r.Name IN :pnCodeByPLT.keySet() ] ){
    		String priceListTitleName = pp.Price_List_Title__r.Name.toLowerCase();
    		
    		if( pnCodeByPLT.get( priceListTitleName ).containsKey( pp.PN_Code__c ) == false ){
    			//This Product Price was not in the Product Price Import
    			continue;
    		}
    		
    		Product_Price_Import__c ppi = pnCodeByPLT.get( priceListTitleName ).get( pp.PN_Code__c );
    		Boolean updatePP = false;
    		
    		if( pp.Selling_Price__c != ppi.Selling_Price__c ){
    			pp.Old_Price__c = pp.Selling_Price__c;
    			pp.Selling_Price__c = ppi.Selling_Price__c;
    			pp.Price_Modify_Date__c = system.today();
    			
    			updatePP = true;
    		}
    		
    		if( pp.Recommended_Price_for_Student__c != ppi.Recommended_Price_for_Student__c ){
    			pp.Recommended_Price_for_Student__c = ppi.Recommended_Price_for_Student__c;
    			
    			updatePP = true;
    		}
    		
    		if( updatePP ){
    			pp2Upd.add( pp );
    		}

            System.debug(LoggingLevel.ERROR, '*** : ' + pnCodeByPLT_NotFound);
            System.debug(LoggingLevel.ERROR, '*** priceListTitleName: ' + priceListTitleName);
    		
    		if( pnCodeByPLT_NotFound.containsKey( priceListTitleName ) ){
    			pnCodeByPLT_NotFound.get( priceListTitleName ).remove( pp.PN_Code__c );
    			
    			if( pnCodeByPLT_NotFound.get( priceListTitleName ).isEmpty() ){
	    			pnCodeByPLT_NotFound.remove( priceListTitleName );
	    		}
    		}
    	}
    	
    	if( pp2Upd.isEmpty() == false ){
    		update pp2Upd;
    	}
    	
    	
    	//Check if there were any Product Price Imports that were NOT Processed
    	if( pnCodeByPLT_NotFound.isEmpty() == false ){
    		
    		Set<String> pnCodes2Find = new Set<String>();
    		Set<String> pnCodesNotFound = new Set<String>();
    		Map<String, Product_Price_Import__c> ppiByPNCode = new Map<String, Product_Price_Import__c>();
    		
    		for( String priceListTitleName : pnCodeByPLT_NotFound.keySet() ){
    			for( String pn_Code : pnCodeByPLT_NotFound.get(priceListTitleName).keySet() ){
    				pnCodes2Find.add( pn_Code );
    				pnCodesNotFound.add( pn_Code );
    				
    				//Theoretically, only 1 PPI should exist per Price List Title Name and PN Code combination.
    				//Also theoretically, the HD Product fields shouldn't be differences between several PPI that aim at the same HD Product
    				ppiByPNCode.put( pn_Code, pnCodeByPLT_NotFound.get(priceListTitleName).get(pn_Code) );
    			}
    		}
    		
    		Map<String, HD_Product__c> hdProdByPNCode = new Map<String, HD_Product__c>();
    		
    		for(HD_Product__c hdProd : [SELECT Id, PN_Code__c FROM HD_Product__c WHERE PN_Code__c IN :pnCodes2Find ]){
    			hdProdByPNCode.put(hdProd.PN_Code__c, hdProd);
    			pnCodesNotFound.remove(hdProd.PN_Code__c);
    		}
    		
    		if( pnCodesNotFound.isEmpty() == false ){
    			//Some HD Products were not found, which would mean that they do not exist, so we create them
    			Map<String, HD_Product__c> hdProds2Ins = new Map<String, HD_Product__c>();
    			
    			for( String pnCode : pnCodesNotFound ){
    				if( ppiByPNCode.containsKey( pnCode ) ){
    					HD_Product__c hdProd = new HD_Product__c( Name = ppiByPNCode.get(pnCode).Product_Name__c, PN_Code__c = pnCode );
    					hdProds2Ins.put( pnCode, hdProd);
    				}
    			}
    			
    			insert hdProds2Ins.values();
    			
    			//We add them to the map of HD Products by PN Code
    			for( HD_Product__c hdProd : hdProds2Ins.values() ){
    				hdProdByPNCode.put( hdProd.PN_Code__c, hdProd );
    			}
    		}
    		
    		List< Product_Price__c > productPrice2Ins = new List<Product_Price__c>();
    		
    		for( Price_List_Title__c plt : [SELECT Id, Name FROM Price_List_Title__c WHERE Name IN :pnCodeByPLT_NotFound.keySet()] ){
    			
    			for( String pn_Code : pnCodeByPLT_NotFound.get(plt.Name).keySet() ){
    				
    				Product_Price_Import__c ppi = ppiByPNCode.get( pn_Code );
    				
    				Product_Price__c pp = new Product_Price__c( );
    				pp.Price_List_Title__c = plt.Id;
    				pp.Selling_Price__c = ppi.Selling_Price__c;
    				pp.HD_Product__c = hdProdByPNCode.get( pn_Code ).Id;
    				pp.Recommended_Price_for_Student__c = ppi.Recommended_Price_for_Student__c ;
    				pp.Price_Modify_Date__c = system.today();
    				
    				//TODO: Activate Product Price by updating HD Product and Price List Title to Active
    				
    				productPrice2Ins.add(pp);
    			}
    		}
    		
    		if( productPrice2Ins.isEmpty() == false ){
    			insert productPrice2Ins;
    		}
    	}    	
    	
    }
    
    global void finish(Database.BatchableContext BC) {

    }
}