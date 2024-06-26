/******************************************************************************* 
Name              : CampaignMember_TriggerHandler
Description       : 
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G.Fernandez     			16/05/2016           
*******************************************************************************/

public class CampaignMember_TriggerHandler {

   public static void executeTriggerHandler(){
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		if (Trigger.isAfter && Trigger.isInsert){
			findLeadOwnerByCampaign();
		}		
	}
	

	/******************************************************************************* 
	Name              : findLeadOwnerByCampaign
	Description       : change the owner if the campaign is partner user
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez 	  		06/23/2016     			Yaara 				[SW-20028]
	2. G. Fernandez 	  		17/03/2017     			Yaara 				[SW-24127]
	*******************************************************************************/
	
	public static void findLeadOwnerByCampaign(){
		if( HD_TriggerSettings.IsTriggerActive('findLeadOwnerByCampaign') ){
			Set<Id> leads = new Set<Id>();
			
			for(Integer i=0; i < trigger.size; i++ ){
				CampaignMember cm = (CampaignMember) trigger.new[i];
				if(cm.LeadId != null){
					leads.add(cm.LeadId);
				}
			}

			if(!leads.isEmpty()){
				
				List<Lead> lead2up = new List<Lead>();
				for (CampaignMember cam: [SELECT Id, LeadId, Lead.OwnerId, Campaign.OwnerId, CampaignId, Campaign.Owner.Account.Partner_Account_User__c, Campaign.Owner.Account.RecordTypeId FROM CampaignMember WHERE LeadId IN :leads AND Campaign.Owner.Account.Account_Type__c != 'HQ'] ) {
				
					if(cam.Campaign.Owner.Account.Partner_Account_User__c == cam.Campaign.OwnerId && cam.Lead.OwnerId != cam.Campaign.OwnerId){						
						lead2up.add(new Lead(Id = cam.LeadId, OwnerId = cam.Campaign.OwnerId ));						
						//camp2up.add(new Campaign(Id = cam.CampaignId, OwnerId = leads.get(cam.LeadId).OwnerId ));						
					}
				}

				if(!lead2up.isEmpty()) {
					update lead2up;
				}				
			}
		}
	}
}