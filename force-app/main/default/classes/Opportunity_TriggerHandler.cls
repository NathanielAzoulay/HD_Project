/******************************************************************************* 
Name              : Opportunity_TriggerHandler
Description       : Handler the before/after trigger on Opportunity
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan Sinclair  		05/11/2016          	
*******************************************************************************/
public class Opportunity_TriggerHandler {

	public static void executeTriggerHandler(){
		
		//  ---------------------------- AFTER EVENTS -----------------------------
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
		
	
		if (Trigger.isAfter && Trigger.isInsert) // After Insert
		{
			oppCreateSharingRules();
		}
		
		else if (Trigger.isAfter && Trigger.isUpdate) // After Update
		{
			oppCreateSharingRules();
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
	Name              : oppCreateSharingRules
	Description       : Handler the sharing record of Opportunity object
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Hernan Sinclair         	05/11/2016          	Yaara				  [SW-19265]
	*******************************************************************************/
	
	public static void oppCreateSharingRules(){
		if( HD_TriggerSettings.IsTriggerActive('oppCreateSharingRules') ){
			
			List<Opportunity> opps = new List<Opportunity>();
			for(Integer i=0; i < trigger.size; i++ ){
				Opportunity r = (Opportunity)trigger.new[i];
				if(trigger.isInsert || ((Opportunity)trigger.old[i]).OwnerId <> r.OwnerId){
					opps.add(r);
				}
			}
			
			if(!opps.isEmpty()){
				HD_SharingMethods.Opportunity_CreateSharingRules(opps);
			}
		}
	}
}