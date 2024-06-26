/******************************************************************************* 
Name              : FR_Order_Product_TriggerHandler
Description       : 
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio	     			15/12/2016           
*******************************************************************************/

public without sharing class FR_Order_Product_TriggerHandler {
	public static void executeTriggerHandler(){
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		
		
		/*if (Trigger.isBefore && Trigger.isInsert) // Before Update
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
		
		
		 
		if (Trigger.isAfter && Trigger.isInsert) // After Insert
		{
			CheckForDuplicateOrderProduct();
		}
		
		else if (Trigger.isAfter && Trigger.isUpdate) // After Update
		{
		}
		/*else if (Trigger.isAfter && Trigger.isDelete) // After Delete
		{
			
		}
		else if (Trigger.isAfter && Trigger.isUnDelete) // After UnDelete
		{
			
		}
		
		*/		
	}
	
	/******************************************************************************* 
	Name              : CheckForDuplicateOrderProduct
	Description       : Handler the sharing record of Price List Title in the Agreement object
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Sergio	         	15/12/2016         		Yaara Nadir				  [SW-22740]
	*******************************************************************************/
	
	public static void CheckForDuplicateOrderProduct(){
		if( HD_TriggerSettings.IsTriggerActive('CheckForDuplicateOrderProduct') ){
			Map<Id, Map<String, Id>> prodCodeByOrderId = new Map<Id, Map<String, Id>>();
			Set<String> pnCodes = new Set<String>();
			
			for(Integer i=0; i < trigger.size; i++ ){
				FR_Order_Product__c op = (FR_Order_Product__c) trigger.new[i];
				
				if( !prodCodeByOrderId.containsKey( op.Order__c ) ){
					prodCodeByOrderId.put( op.Order__c, new Map<String, Id>() );
				}
				
				prodCodeByOrderId.get( op.Order__c ).put( op.PN_Code__c, op.Id );
				pnCodes.add( op.PN_Code__c );
				
				system.debug( 'op.Id:' + op.Id );
				system.debug( 'op.PN_Code__c:' + op.PN_Code__c );
			}
			system.debug( 'pnCodes: ' + pnCodes );
			if( !prodCodeByOrderId.isEmpty() ){
				
				for( FR_Order_Product__c op : [SELECT Id, Product_Price__c, Product_Price__r.PN_Code__c, PN_Code__c, Order__c FROM FR_Order_Product__c WHERE Id != :trigger.newMap.keySet() AND PN_Code__c IN :pnCodes AND Order__c IN :prodCodeByOrderId.keySet() ] ){
					Map<String, Id> prodIdByPNCode = prodCodeByOrderId.get( op.Order__c );
					system.debug('op.Id: ' + op.Id);
					system.debug('op.PN_Code__c: ' + op.PN_Code__c);
					system.debug('op.Product_Price__c: ' + op.Product_Price__c);
					system.debug('op.Product_Price__r.PN_Code__c: ' + op.Product_Price__r.PN_Code__c);
					if( prodIdByPNCode.containsKey( op.PN_Code__c ) && prodIdByPNCode.get( op.PN_Code__c ) != op.Id ){
						//Duplicate found. Another Order Product with the same PN Code was found already existing in the Order
						trigger.newMap.get( prodIdByPNCode.get( op.PN_Code__c ) ).addError( Label.HDC_Order_Duplicate );
					}
				}
				
			}
		}
	}
}