/**************************************************************************************** 
    Name              : SearchProductsToOrder_Crl
    Description       : Controller of the VF page that allows to create Products under Orders
    Revision History  :-
    Created/Modified by         Created/Modified Date     Requested by      Related Task/Issue  
    ----------------------------------------------------------------------------------------
    1. Sergio (Created)             01/03/2016                Yaara                [SW-18147]
    ----------------------------------------------------------------------------------------    
****************************************************************************************/
public class SearchProductsToOrder_Crl {
    
    public class dataWrapper{
        
        public Product_Price__c productPrice {get;set;}
        public List<Set_Product__c> setProducts {get;set;}
        public Decimal quantity {get;set;}
        public Boolean selected {get;set;}
        public List<Product_Price_by_Quantity__c> priceQuantity {get;set;}
        public List<Product_Price_by_Quantity__c> hdPriceQuantity {get;set;}
        public Double customSellingPrice {get;set;}
        
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
    
    private FR_Order__c theOrder;
    
    public SearchProductsToOrder_Crl(ApexPages.StandardController controller) {
        theOrder = (FR_Order__c) controller.getRecord();
        getData();
    }
    
    transient public string jsonData {get;set;}
    transient public string prodFields {get;set;}
    transient public string orderRelList {get;set;}
    private String getData(){
        jsonData = '';
        
        try{
            String query = '';
            
            List<fieldWrapper> fwList = new List<fieldWrapper>();
            
            for(Schema.FieldSetMember f : Schema.SObjectType.Product_Price__c.FieldSets.Search_Products_for_Order.getFields()) {
                query += ', ' + f.getFieldPath() + ' ';
                //fwList.add( new fieldWrapper( f.getFieldPath(), f.getLabel() ) );
            }
            
            for(Schema.FieldSetMember f : Schema.SObjectType.FR_Order_Product__c.FieldSets.Search_Products_for_Order.getFields()) {
                fwList.add( new fieldWrapper( f.getFieldPath(), f.getLabel() ) );
            }
            
            Set<String> reqFields = new Set<String>{ 'Name', 'PN_Code__c', 'Base_Course__c', 'Product_Type__c', 'HD_Product__c', 'HD_Product__r.Product_Category__c', 'Product_Image__c', 'Selling_Price__c', 'HD_Currency__c','Price_by_Quantity__c' , 'Max_Quantity_Price__c', 'HD_Product_Price__c'};
            
            for( String f : reqFields ){
                if( query.toLowerCase().contains( ', ' + f.toLowerCase() + ' ' )  == false){
                    query += ', ' + f + ' ';
                }
            }
            
            query = 'SELECT ' + query.substring(1) + ' FROM Product_Price__c WHERE (Selling_Price__c > 0 OR HD_Product__r.Price_can_be_0__c = true OR (Price_by_Quantity__c = true AND Max_Quantity_Price__c > 0)) AND Price_List_Title__c = \'' + theOrder.Price_List_Title__c + '\'';
            
            
            List<dataWrapper> dwList = new List<dataWrapper>();
            Map<Id, List<dataWrapper>> products = new Map<Id, List<dataWrapper>>();
            
            Set<Id> ppIds = new Set<Id>();            
            Set<Id> ppHIds = new Set<Id>();  
            for( Product_Price__c pp : (List<Product_Price__c>) Database.query(query) ){
                dataWrapper dw = new dataWrapper(pp);
                dwList.add(dw);
                
                if( products.containsKey( pp.HD_Product__c ) == false ){
                    products.put( pp.HD_Product__c, new List<dataWrapper>() );
                }

                if(pp.Price_by_Quantity__c == true && pp.Max_Quantity_Price__c > 0){
                   ppHIds.add(pp.HD_Product_Price__c); 
                   ppIds.add(pp.Id); 
                }

                products.get( pp.HD_Product__c).add(dw);
            }
            
            
            if( products.isEmpty() == false ){
                for( Set_Product__c setProd : [SELECT Id, Set_Product__c, Set_Product__r.Name, Priority_Sub_Product_Name__c, Sub_Product_Name__c, Priority_Sub_Product_Type__c, Quantity_in_Set__c, Sub_Product_PN_Code__c FROM Set_Product__c WHERE Set_Product__c IN :products.keySet() ] ){
                    for( dataWrapper dw : products.get( setProd.Set_Product__c ) ){
                        dw.setProducts.add( setProd );
                    }
                }
            }

             List<FR_Order_Product__c> opRelList = [SELECT Id, Quantity__c,Product__c, Product_Price__r.HD_Product__c FROM FR_Order_Product__c WHERE Order__c = :theOrder.Id ];
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
            
            jsonData = JSON.serialize( dwList );
            
            prodFields = JSON.serialize( fwList );
            
            if(opRelList.size() > 0){
                orderRelList = JSON.serialize( opRelList );
                }
            else{    
                    orderRelList= JSON.serialize('');
                }
                
            
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
    
    public PageReference Save(){
        
        try{
            system.debug('jsonSaveData: ' + jsonSaveData);
            List<dataWrapper> dwList = (List<dataWrapper>) JSON.deserialize( jsonSaveData, List<dataWrapper>.class );
            
            system.debug( 'dwList:' + dwList );
            
            Map<Id, FR_Order_Product__c> op2Ins = new Map<Id, FR_Order_Product__c>();
            
            for( dataWrapper dw : dwList ){
                //if( dw.selected ){
                    FR_Order_Product__c op = new FR_Order_Product__c();
                    op.Order__c = theOrder.Id;
                    op.Product_Price__c = dw.productPrice.Id;
                    op.Quantity__c = dw.quantity;
                    op.Price_Quantity__c = dw.customSellingPrice;
                    
                    op2Ins.put( dw.productPrice.Id, op );
                //}
            }
            
            List<FR_Order_Product__c> op2Upd = new List<FR_Order_Product__c>();
            
            for( FR_Order_Product__c op : [SELECT Id, Quantity__c, Product_Price__c FROM FR_Order_Product__c WHERE Order__c = :theOrder.Id ] ){
                if( op2Ins.containsKey( op.Product_Price__c ) ){
                    op.Quantity__c = op2Ins.get(op.Product_Price__c).Quantity__c;
                    op.Price_Quantity__c = op2Ins.get(op.Product_Price__c).Price_Quantity__c;
                    
                    op2Upd.add( op );
                    
                    op2Ins.remove( op.Product_Price__c );
                }
            }
            
            if( op2Ins.isEmpty() == false ){
                insert op2Ins.values();
            }
            
            if( op2Upd.isEmpty() == false ){
                update op2Upd;
            }
            
            List<FR_Order_Product__c> opRelList = [SELECT Id, Quantity__c,Product__c, Product_Price__r.HD_Product__c FROM FR_Order_Product__c WHERE Order__c = :theOrder.Id ];
                  
            if(opRelList.size() > 0){
                orderRelList = JSON.serialize( opRelList );
            }
            else{    
                    orderRelList= JSON.serialize('');
            }
                
            //return new PageReference('/' + theOrder.Id);
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
        
    }
    
}