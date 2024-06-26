/******************************************************************************* 
Name              : HDCOrder_TriggerHandler
Description       : Handler the before/after trigger on FR_Order__c
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez         	05/13/2016
*******************************************************************************/
public class HDCOrder_TriggerHandler {

	public static void executeTriggerHandler(){
		
		//  ---------------------------- BEFORE EVENTS -----------------------------
		if( trigger.isBefore && trigger.isInsert ){
			Default_Price_List_Title();
		}
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		if (Trigger.isAfter && Trigger.isInsert){
			HDC_Order_CreateSharingRules();
		}
		else if (Trigger.isAfter && Trigger.isUpdate){
			HDC_Order_CreateSharingRules();
		}
	}
	
	/******************************************************************************* 
	Name              : Default_Price_List_Title
	Description       : Populates the Price List on Order if the User has access to only 1 Price List
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Sergio	         	02/11/2016         		Yaara Nadir				  [SW-22057]
	*******************************************************************************/
	
	public static void Default_Price_List_Title(){
		if(HD_TriggerSettings.IsTriggerActive('Default_Price_List_Title') ){
			List<Price_List_Title__c> plts = MonitorRecursionClass.AvailablePriceListsForUser();
			
			List<Id> pltIds = new List<Id>();
			for( Price_List_Title__c plt : plts ){
				pltIds.add(plt.Id);
			}
			
			system.debug( 'pltIds: ' + pltIds );
			
			List<Id> foundIds = new List<Id>();
			for( UserRecordAccess ura : [SELECT RecordId, HasEditAccess, HasReadAccess FROM UserRecordAccess WHERE UserId = :userinfo.getUserId() AND RecordId IN :pltIds] ){
				if( ura.HasEditAccess == false && ura.HasReadAccess){
					foundIds.add(ura.RecordId);
				}
			}
			
			if( foundIds.size() == 1 ){
				for( FR_Order__c ord : (List<FR_Order__c>) trigger.new ){
					if( ord.Price_List_Title__c == null ){
						ord.Price_List_Title__c = foundIds[0];
					}
				}
			}
		}
	}
	
	
	/******************************************************************************* 
	Name              : HDC_Order_CreateSharingRules
	Description       : Handler the sharing record of FR_Order__c object
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez         	05/27/2016         	Yaara Nadir				  [SW-19590]
	*******************************************************************************/
	
	public static void HDC_Order_CreateSharingRules(){
		if( HD_TriggerSettings.IsTriggerActive('HDC_Order_CreateSharingRules') ){
			
			List<FR_Order__c> orders = new List<FR_Order__c>();
			for(Integer i=0; i < trigger.size; i++ ){
				FR_Order__c order = (FR_Order__c)trigger.new[i];
				if(trigger.isInsert || ((FR_Order__c)trigger.old[i]).OwnerId <> order.OwnerId){
					orders.add(order);
				}
			}

			if(!orders.isEmpty()){
				HD_SharingMethods.HDC_Order_CreateSharingRules(orders);				
			}
		}
	}
}