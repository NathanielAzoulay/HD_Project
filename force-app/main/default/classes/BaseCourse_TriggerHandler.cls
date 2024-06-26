/******************************************************************************* 
Name              : BaseCourse_TriggerHandler
Description       : Handler the before/after trigger on Base_Course__c
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez         	05/27/2016
*******************************************************************************/
public class BaseCourse_TriggerHandler {

	public static void executeTriggerHandler(){
		
		//  ---------------------------- BEFORE EVENTS -----------------------------
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		if (Trigger.isAfter && Trigger.isInsert){
			baseCourseCreateSharingRules();
		}
		
		else if (Trigger.isAfter && Trigger.isUpdate){
			baseCourseCreateSharingRules();
			baseCourseRemoveSharingRules();
		}				
	}
	
	/******************************************************************************* 
	Name              : baseCourseCreateSharingRules
	Description       : Handler the sharing record of Base_Course__c object
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez         	05/27/2016         	Yaara Nadir				  [SW-19589]
	*******************************************************************************/
	
	public static void baseCourseCreateSharingRules(){
		if( HD_TriggerSettings.IsTriggerActive('baseCourseCreateSharingRules') ){
			
			List<Base_Course__c> baseCourse = new List<Base_Course__c>();
			for(Integer i=0; i < trigger.size; i++ ){
				
				Base_Course__c bc = (Base_Course__c) trigger.new[i];
				Boolean active = bc.Status__c == 'Active';
				Boolean cond = Trigger.isInsert;
				cond |= Trigger.isUpdate && ( ((Base_Course__c) trigger.old[i]).Status__c <> bc.Status__c || ((Base_Course__c) trigger.old[i]).OwnerId <> bc.OwnerId );

				if( active && cond ){
					baseCourse.add(bc);
				}
			}

			if(!baseCourse.isEmpty()){
				HD_SharingMethods.BaseCourse_CreateSharingRules(baseCourse);				
			}
		}
	}

	/******************************************************************************* 
	Name              : baseCourseRemoveSharingRules
	Description       : Handler the sharing record of Base_Course__c object when changes status to != Active
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez         	04/08/2016         	Yaara Nadir				  [SW-19589]
	*******************************************************************************/
	
	public static void baseCourseRemoveSharingRules(){
		if( HD_TriggerSettings.IsTriggerActive('baseCourseRemoveSharingRules') ){
			
			Set<Id> baseCourseIds = new Set<Id>();
			for(Integer i=0; i < trigger.size; i++ ){
				
				Base_Course__c bc = (Base_Course__c) trigger.new[i];
				Base_Course__c bcOld = (Base_Course__c) trigger.old[i];
				Boolean active = bcOld.Status__c == 'Active';
				Boolean cond = Trigger.isUpdate && ( bcOld.Status__c <> bc.Status__c );

				if( active && cond ){
					baseCourseIds.add(bc.Id);
				}
			}

			if(!baseCourseIds.isEmpty()){
				Map<Id,List<Base_Course__Share>> shares = new Map<Id,List<Base_Course__Share>>();
				for(Base_Course__Share share : [SELECT Id, UserOrGroupId FROM Base_Course__Share WHERE ParentId IN :baseCourseIds AND RowCause != 'Owner' ]){
					if(!shares.containsKey(share.UserOrGroupId)){
						shares.put(share.UserOrGroupId, new List<Base_Course__Share>());
					}
					shares.get(share.UserOrGroupId).add(share);

				}
				
				List<Base_Course__Share> shares2del = new List<Base_Course__Share>();
				for(User u : [SELECT Id FROM User WHERE Id IN :shares.keySet() AND UserType = 'PowerPartner']){
					for(Base_Course__Share bShare : shares.get(u.Id)){
						shares2del.add(bShare);
					}
				}

				if(!shares2del.isEmpty()){
					delete shares2del;
				}
			}
		}
	}
}