/******************************************************************************* 
Name              : Campaign_TriggerHandler
Description       : Handler the before/after trigger on Campaign
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez		  		05/11/2016          	
*******************************************************************************/
public class Campaign_TriggerHandler {

	public static void executeTriggerHandler(){
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		
	
		if (Trigger.isAfter && Trigger.isInsert) // After Insert
		{
			campaignCreateSharingRules();
		}
		
		else if (Trigger.isAfter && Trigger.isUpdate) // After Update
		{
			campaignCreateSharingRules();
		}				
	}

		/******************************************************************************* 
	Name              : campaignCreateSharingRules
	Description       : Handler the sharing record of Campaign object
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez         	05/11/2016          	Yaara				  [SW-19261]
	2. G. Fernandez         	09/06/2016          	Yaara				  [SW-19261]
	*******************************************************************************/
	
	public static void campaignCreateSharingRules(){
		if( HD_TriggerSettings.IsTriggerActive('campaignCreateSharingRules') ){
			
			Set<Id> campaignIds = new Set<Id>();
			for(Integer i=0; i < trigger.size; i++ ){
				Campaign r = (Campaign)trigger.new[i];
				if(trigger.isInsert || ((Campaign)trigger.old[i]).OwnerId <> r.OwnerId){
					campaignIds.add(r.Id);
				}
			}

			if(!campaignIds.isEmpty()){
				Map<Id,Id> campaignAccountsIds = new Map<Id,Id>();
				for(Campaign camp : [SELECT Id, Owner.AccountId FROM Campaign WHERE Id IN :campaignIds]){
					if(camp.Owner.AccountId != null){
						campaignAccountsIds.put(camp.Id, camp.Owner.AccountId);
					}
				}

				HD_SharingMethods.Campaign_CreateSharingRules(campaignAccountsIds);
			}
		}
	}
}