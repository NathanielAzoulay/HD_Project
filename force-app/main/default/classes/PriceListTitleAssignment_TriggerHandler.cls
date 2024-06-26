/******************************************************************************* 
Name              : PriceListTitleAssignment_TriggerHandler
Description       : Handler the before/after trigger on Account
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez         	07/07/2016          	
*******************************************************************************/
public class PriceListTitleAssignment_TriggerHandler {

	public static void executeTriggerHandler(){
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		/*
		if (Trigger.isBefore && Trigger.isInsert) // Before Update
		{
			
		} 
		if (Trigger.isBefore && Trigger.isUpdate) // Before Insert
		{
		}
		
		*/
		if (Trigger.isBefore && Trigger.isDelete) // Before Delete
		{
			pltAssignmentRemoveSharingRules();
		}
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		
	
		if (Trigger.isAfter && Trigger.isInsert) // After Insert
		{
			pltAssignmentCreateSharingRules();
		}
		
		/*else if (Trigger.isAfter && Trigger.isUpdate) // After Update
		{
			accCreateSharingRules();
		}
		
		if (Trigger.isAfter && Trigger.isDelete) // After Delete
		{
			
		}
		/*
		else if (Trigger.isAfter && Trigger.isUnDelete) // After UnDelete
		{
			
		}
		*/				
	}
	
	/******************************************************************************* 
	Name              : pltAssignmentCreateSharingRules
	Description       : Handler the sharing record of Account object
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez         	07/07/2016          	Yaara				  [SW-20272]
	*******************************************************************************/
	
	public static void pltAssignmentCreateSharingRules(){
		if( HD_TriggerSettings.IsTriggerActive('pltAssignmentCreateSharingRules') ){
			
	        List<Id> pltIds = new List<Id>(); 
	        for(Integer i=0; i < trigger.size; i++ ){
	            pltIds.add(trigger.new[i].Id);
	        }	

			HD_SharingMethods.PltAssignment_CreateSharingRules(pltIds);
		}
	}

	/******************************************************************************* 
	Name              : pltAssignmentRemoveSharingRules
	Description       : Handler the sharing record of Account object
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez         	08/06/2017          	Yaara				  [SW-25238]
	*******************************************************************************/
	
	public static void pltAssignmentRemoveSharingRules(){
		if( HD_TriggerSettings.IsTriggerActive('pltAssignmentRemoveSharingRules') ){
			HD_SharingMethods.PltAssignment_RemoveSharingRules();
		}
	}
}