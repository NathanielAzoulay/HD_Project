/******************************************************************************* 
Name              : Document_TriggerHandler
Description       : 
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio	     			01/12/2016           
*******************************************************************************/

public class Document_TriggerHandler {
	public static void executeTriggerHandler(){
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		
		if (Trigger.isBefore && Trigger.isInsert){ // Before Update
		}else if (Trigger.isBefore && Trigger.isUpdate){ // Before Insert
		}
		/*
		else if (Trigger.isBefore && Trigger.isDelete) // Before Delete
		{
		}
		*/
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		
		if (Trigger.isAfter && Trigger.isInsert) // After Insert
		{		
			DocumentShareRuleCreation();
		}
		
		else if (Trigger.isAfter && Trigger.isUpdate) // After Update
		{
			DocumentShareRuleCreation();
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
	Name              : DocumentsOnLeadConvert
	Description       : Changes the Documents with the Lead Id to point to the new Contact created from the convertion
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Sergio	        	30/11/2016          	Yaara Nadir 		  [SW-22547]
	*******************************************************************************/
	
	public static void DocumentShareRuleCreation(){
		system.debug( 'DocumentShareRuleCreation' );
		if( HD_TriggerSettings.IsTriggerActive('DocumentShareRuleCreation') ){
			Set<Id> docIds = new Set<Id>();
			for( Document__c doc : (List<Document__c>) trigger.new){
				if( trigger.isInsert || ( trigger.isUpdate && doc.Application__c != trigger.oldMap.get( doc.Id ).get('Application__c')) ){
					docIds.add( doc.Id );
				}
			}
			
			if( !docIds.isEmpty() ){
				HD_SharingMethods.Document_CreateSharingRules(docIds);
			}
		}
	}
}