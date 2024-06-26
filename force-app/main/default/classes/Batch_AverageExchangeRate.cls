/******************************************************************************* 
Name              : Batch_AverageExchangeRate
Description       : 
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio	             07/04/2016  	        Yaara Nadir               [SW-19970]
*******************************************************************************/

global class Batch_AverageExchangeRate implements Database.Batchable<AggregateResult> {
	
    public Date dtStart = system.today().addMonths(-1).toStartOfMonth();
    public Date dtEnd = system.today().toStartOfMonth();
	public String query = 'SELECT AVG(ConversionRate) a , IsoCode FROM DatedConversionRate WHERE (StartDate >= :dtStart OR NextStartDate >= :dtStart) AND StartDate < :dtEnd GROUP BY IsoCode';
	
	public List<String> toCurrencies = new List<String>{'USD', 'EUR'};
	
	global Iterable<AggregateResult> start(Database.BatchableContext bc) {
        return new AggregateResultIterable( query, dtStart, dtEnd );
    }
	
    global void execute(Database.BatchableContext BC, list<Sobject> scope) {
    	//Lets check if there already exists a record for this month, if so, we should overwrite it
		Map<String, Map<String, Average_Exchange_Rate__c>> AER_Map = new Map<String, Map<String, Average_Exchange_Rate__c>>();
		
		for( Average_Exchange_Rate__c aer : [SELECT Id, CurrencyIsoCode, To_Currency__c FROM Average_Exchange_Rate__c WHERE To_Currency__c IN :toCurrencies AND Exchange_Rate_Start_Date__c = :system.today().addMonths(-1).toStartOfMonth()] ){
			if( !AER_Map.containsKey( aer.To_Currency__c ) ){
				AER_Map.put( aer.To_Currency__c, new Map<String, Average_Exchange_Rate__c>() );
			}
			AER_Map.get( aer.To_Currency__c ).put( aer.CurrencyIsoCode, aer );
		}
		
		Map<String, Decimal> conversionRates = new Map<String, Decimal>();
		
		for( DatedConversionRate dcr : [SELECT Id, ConversionRate, IsoCode FROM DatedConversionRate WHERE IsoCode IN :toCurrencies ORDER BY CreatedDate desc LIMIT 1] ){
			conversionRates.put(dcr.IsoCode, dcr.ConversionRate);
		}
		
		List<Average_Exchange_Rate__c> aer2Ins = new List<Average_Exchange_Rate__c>();
		
		for( AggregateResult ag : (List<AggregateResult>) scope ){
			String isoCode = String.valueOf( ag.get('IsoCode') );
			Decimal avgCR = (Decimal) ag.get('a');
			
			for( String toCurrency : toCurrencies ){
				
				Average_Exchange_Rate__c aer = new Average_Exchange_Rate__c();
				
				if( AER_Map.containsKey( toCurrency ) && AER_Map.get( toCurrency ).containsKey( isoCode ) ){
					aer = new Average_Exchange_Rate__c( Id = AER_Map.get( toCurrency ).get( isoCode ).Id );
				}
				
				aer.CurrencyIsoCode = isoCode;
				aer.To_Currency__c = toCurrency;
				aer.Exchange_Rate_Start_Date__c = system.today().addMonths(-1).toStartOfMonth();
				aer.Average_Rate__c = avgCR;
				
				if( conversionRates.containsKey(toCurrency) ){
					aer.Average_Rate__c = avgCR / conversionRates.get(toCurrency);
				}
				
				if(aer.CurrencyIsoCode == aer.To_Currency__c){
					aer.Average_Rate__c = 1.0000;
				}
				
				aer2Ins.add( aer );
			}
		}
		
		if( !aer2Ins.isEmpty() ){
			upsert aer2Ins;
		}
    }
    
    global void finish(Database.BatchableContext BC) {
    	
    }
    
    global class AggregateResultIterator implements Iterator<AggregateResult> {
		AggregateResult [] results {get;set;}
		// tracks which result item is returned
		Integer index {get; set;} 
		
		global AggregateResultIterator(String query, Date dtStart, Date dtEnd) {
			index = 0;
			results = Database.query(query);
		}
		
		global boolean hasNext(){
			return results != null && !results.isEmpty() && index < results.size();
		}
		
		global AggregateResult next(){
			return results[index++];
		}
	}
	
	global class AggregateResultIterable implements Iterable<AggregateResult> {
		private String query;
        private Date dtStart;
		private Date dtEnd;
		
		global Iterator<AggregateResult> Iterator(){
			return new AggregateResultIterator(query, dtStart, dtEnd);
		}
		
		global AggregateResultIterable(String query, Date dtStart, Date dtEnd){
			this.query = query;
			this.dtStart = dtStart;
            this.dtEnd = dtEnd;
		}
	}
}