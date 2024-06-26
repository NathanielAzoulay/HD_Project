/**************************************************************************************** 
    Name              : manageProductPricesCtrl
    Description       : Controller of the VF page that allows to search Products and update his price
    Revision History  :-
    Created/Modified by         Created/Modified Date     Requested by      Related Task/Issue  
    ----------------------------------------------------------------------------------------
    1. G. Fernandez (Created)         29/03/2016            Yaara                [SW-18656]
    2. G. Fernandez (Created)         16/05/2017            Yaara                [SW-24870]
    ----------------------------------------------------------------------------------------    
****************************************************************************************/
public class manageProductPricesCtrl {
    
    public class dataWrapper{
        
        public Product_Price__c productPrice {get;set;}
        public List<Set_Product__c> setProducts {get;set;}
        public Decimal quantity {get;set;}
        public Boolean selected {get;set;}
        public List<Product_Price_by_Quantity__c> priceQuantity {get;set;}
        public List<Product_Price_by_Quantity__c> hdPriceQuantity {get;set;}
        
        public dataWrapper( Product_Price__c pp ){
            productPrice = pp;
            //quantity = 0;
            selected = false;
            priceQuantity = new List<Product_Price_by_Quantity__c>();
            hdPriceQuantity = new List<Product_Price_by_Quantity__c>();
            setProducts = new List<Set_Product__c>();
        }
    }
    
    public class fieldWrapper{
        public String name {get;set;}
        public String label {get;set;}
        
        public fieldWrapper(String n, String l){
            name = n;
            label = l;
        }
    }
    
    private Price_List_Title__c thePriceListTitle;
    
    public manageProductPricesCtrl(ApexPages.StandardController controller) {
        thePriceListTitle = (Price_List_Title__c) controller.getRecord();
        getData();
    }
    
    transient public string jsonData {get;set;}
    transient public string prodFields {get;set;}
    transient public string priceByQuantity {get;set;}
    
    private String getData(){
        jsonData = '""';
        priceByQuantity = '""';
        prodFields = '""';
        
        try{
            String query = '';
            
            List<fieldWrapper> fwList = new List<fieldWrapper>();
            
            for(Schema.FieldSetMember f : Schema.SObjectType.Product_Price__c.FieldSets.Search_Products_for_Manage_Price.getFields()) {
                query += ', ' + f.getFieldPath() + ' ';
                fwList.add( new fieldWrapper( f.getFieldPath(), f.getLabel() ) );
            }
            
            Set<String> reqFields = new Set<String>{ 'Name', 'Purchase_Price_HD_Currency__c','PN_Code__c', 'Base_Course__c', 'Product_Type__c', 'HD_Product__c', 'HD_Product__r.Product_Category__c', 'Product_Image__c', 'HD_Currency__c', 'CurrencyIsoCode', 'Purchase_Price_Modify_Date__c', 'Purchase_Price__c','Price_Modify_Date__c','Recommended_Price_for_Student__c', 'Selling_Price__c','Price_by_Quantity__c' , 'HD_Product_Price__r.Max_Quantity_Price__c'};
            
            for( String f : reqFields ){
                if( query.toLowerCase().contains( ', ' + f.toLowerCase() + ' ' )  == false){
                    query += ', ' + f + ' ';
                }
            }

            query = 'SELECT ' + query.substring(1) + ' FROM Product_Price__c WHERE ' +
            ' ( Purchase_Price__c > 0 OR HD_Product__r.Price_can_be_0__c = TRUE OR Selling_Price__c > 0 OR (Price_by_Quantity__c = true AND HD_Product_Price__r.Max_Quantity_Price__c > 0))' +
            ' AND Price_List_Title__c = \'' + thePriceListTitle.Id + '\'';

            List<dataWrapper> dwList = new List<dataWrapper>();
            Map<Id, List<dataWrapper>> products = new Map<Id, List<dataWrapper>>();
            
            Set<Id> ppIds = new Set<Id>();            
            Set<Id> ppHIds = new Set<Id>();            
            for( Product_Price__c pp : (List<Product_Price__c>) Database.query(query) ){
                if(pp.Price_Modify_Date__c !=null){
                    pp.Price_Modify_Date__c = Datetime.valueOfGmt(pp.Price_Modify_Date__c.format('yyyy-MM-dd HH:mm:ss'));
                }
                dataWrapper dw = new dataWrapper(pp);
                dwList.add(dw);
                
                if( products.containsKey( pp.HD_Product__c ) == false ){
                    products.put( pp.HD_Product__c, new List<dataWrapper>() );
                }
                products.get( pp.HD_Product__c).add(dw);

                if(pp.Price_by_Quantity__c == true && pp.HD_Product_Price__r.Max_Quantity_Price__c > 0){
                   ppHIds.add(pp.HD_Product_Price__c); 
                   ppIds.add(pp.Id); 
                }
            }            
            
            if( products.isEmpty() == false ){
                for( Set_Product__c setProd : [SELECT Id, Set_Product__c, Set_Product__r.Name, Priority_Sub_Product_Name__c, Priority_Sub_Product_Type__c, Quantity_in_Set__c, Sub_Product_Name__c, Sub_Product_PN_Code__c FROM Set_Product__c WHERE Set_Product__c IN :products.keySet() ] ){
                    for( dataWrapper dw : products.get( setProd.Set_Product__c ) ){
                        dw.setProducts.add( setProd );
                    }
                }
            }

            //List<PriceQuantityWrapper> pqList = new List<PriceQuantityWrapper>();
            //get prices by quantity
            if(!ppIds.isEmpty() || !ppHIds.isEmpty() ){
                for (Product_Price_by_Quantity__c ppQ : [SELECT Product_Price__c, Price__c, Maximum_Quantity__c, Minimum_Quantity__c FROM Product_Price_by_Quantity__c WHERE Product_Price__c IN :ppIds OR Product_Price__c IN:ppHIds ORDER BY Minimum_Quantity__c ASC]) {
                    //pqList.add(new PriceQuantityWrapper(ppQ));
                    for( dataWrapper dw : dwList ){
                        if(dw.productPrice.HD_Product_Price__c == ppQ.Product_Price__c){
                            dw.hdPriceQuantity.add( ppQ );
                        }
                        if(dw.productPrice.Id == ppQ.Product_Price__c){
                            dw.priceQuantity.add( ppQ );
                        }
                    }
                }
            }

            //priceByQuantity = JSON.serialize( pqList );
            
            jsonData = JSON.serialize( dwList );
            
            prodFields = JSON.serialize( fwList );
            
        }catch( Exception e ){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return jsonData;
    } 

    private String jsonSaveData;
    public void setJSonSaveData(String s){
        jsonSaveData = s;
    }
    
    public String getJSonSaveData(){
        return jsonSaveData;
    }

    public String showError{get;set;}
    public String saveSuccess{get;set;}
    
    public PageReference Save(){
        PageReference retVal;
        saveSuccess = 'true';
        try{
            system.debug('jsonSaveData: ' + jsonSaveData);
            List<dataWrapper> dwList = (List<dataWrapper>) JSON.deserialize( jsonSaveData, List<dataWrapper>.class );
            
            system.debug( 'dwList:' + dwList );
            
            Map<Id, Product_Price__c> productPrice2Up = new Map<Id, Product_Price__c>();
            Map<Id, Product_Price_by_Quantity__c> priceQuantity2up = new Map<Id, Product_Price_by_Quantity__c>();
            
            for( dataWrapper dw : dwList ){
                Product_Price__c prodPrice = new Product_Price__c(Id = dw.productPrice.Id);
                prodPrice.Selling_Price__c = dw.productPrice.Selling_Price__c;
                    
                productPrice2Up.put( dw.productPrice.Id, prodPrice ); 
                for (Product_Price_by_Quantity__c pq : dw.priceQuantity) {
                    priceQuantity2up.put( pq.Id, pq ); 
                }

            }
            
            if( !productPrice2Up.isEmpty() ){
                update productPrice2Up.values();
            }
            if( !priceQuantity2up.isEmpty() ){
                update priceQuantity2up.values();
            }

        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            showError = e.getMessage();
        }
        
        return null;
        
    }  
    
}