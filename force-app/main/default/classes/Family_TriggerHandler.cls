/******************************************************************************* 
Name              : Family_TriggerHandler
Description       : Handler the before/after trigger on Family__c
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez         	05/13/2016
*******************************************************************************/
public class Family_TriggerHandler {

	public static void executeTriggerHandler(){
		
		//  ---------------------------- AFTER EVENTS -----------------------------
				
		//  ---------------------------- AFTER EVENTS -----------------------------
		if (Trigger.isAfter && Trigger.isInsert){
			familyCreateSharingRules();
		}		
		else if (Trigger.isAfter && Trigger.isUpdate){
			familyCreateSharingRules();
		}				
	}
	
	/******************************************************************************* 
	Name              : familyCreateSharingRules
	Description       : Handler the sharing record of Family__c object
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez         	05/13/2016         	Yaara Nadir				  [SW-19264]
	*******************************************************************************/
	
	public static void familyCreateSharingRules(){
		if( HD_TriggerSettings.IsTriggerActive('familyCreateSharingRules') ){
			
			List<Family__c> familys = new List<Family__c>();
			for(Integer i=0; i < trigger.size; i++ ){
				Family__c f = (Family__c)trigger.new[i];
				if(trigger.isInsert || ((Family__c)trigger.old[i]).OwnerId <> f.OwnerId){
					familys.add(f);
				}
			}

			if(!familys.isEmpty()){
				HD_SharingMethods.Family_CreateSharingRules(familys);				
			}
		}
	}
}