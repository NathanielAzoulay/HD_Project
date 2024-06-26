/******************************************************************************* 
Name              : AccountContactRelation_TriggerHandler
Description       : Handler the before/after trigger on LG Lesson
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez			02/21/2017            	
*******************************************************************************/
public class AccountContactRelation_TriggerHandler {

	public static void executeTriggerHandler(){
		
		//  ---------------------------- BEFORE EVENTS -----------------------------
		
		/*if (Trigger.isBefore && Trigger.isInsert) // Before Insert
		{
		}
		
		else if (Trigger.isBefore && Trigger.isUpdate) // Before Update
		{
		}
		*/
		/*if (Trigger.isBefore && Trigger.isDelete) // Before Delete
		{
		}*/
		
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		
		
		if (Trigger.isAfter && Trigger.isInsert) // After Insert
		{
			CreateSharingRules();
		}		
		
		/*else if (Trigger.isAfter && Trigger.isUpdate) // After Update
		{
		}*/
		
		if (Trigger.isAfter && Trigger.isDelete) // After Delete
		{

			MainFranchiseDelete();	

		}
		/*
		else if (Trigger.isAfter && Trigger.isUnDelete) // After UnDelete
		{
			
		}
		*/
				
	}

	/******************************************************************************* 
	Description       : Update Main Franchise after relationship deleted
						1) Update LG Lesson before insert and when edited
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez			02/21/2017            Dafna Margalit             [SW-23632]
	2. G. Fernandez			02/21/2017            Dafna Margalit             [SW-24154]
	*******************************************************************************/
	public static void MainFranchiseDelete(){
		if( HD_TriggerSettings.IsTriggerActive('MainFranchiseDelete') ){
				
			//map franchise and contacts ids relations
			Map<Id,Set<Id>> franchiseIds = new Map<Id,Set<Id>>();
			//map contactid relations
			Map<Id,List<AccountContactRelation>> con2check = new Map<Id,List<AccountContactRelation>>();

			for(Integer i=0; i < trigger.size; i++ ){				
				AccountContactRelation r = (AccountContactRelation)trigger.old[i];
				if(!con2check.containsKey(r.ContactId)){
					con2check.put(r.ContactId, new List<AccountContactRelation>());
				}
				con2check.get(r.ContactId).add(r);

				if(!franchiseIds.containsKey(r.AccountId)){
					franchiseIds.put(r.AccountId, new Set<Id>());
				}
				franchiseIds.get(r.AccountId).add(r.ContactId);
			}

			//get franchisee relationships info in case
			Map<Id,List<AccountContactRelation>> otherRelations = new Map<Id,List<AccountContactRelation>>();
			for (AccountContactRelation acr : [SELECT ContactId, AccountId FROM AccountContactRelation WHERE ContactId IN :con2check.keySet() AND IsDirect = false]) {
				if(!otherRelations.containsKey(acr.ContactId)){
					otherRelations.put(acr.ContactId, new List<AccountContactRelation>());
				}
				otherRelations.get(acr.ContactId).add(acr);
			}


			if(!con2check.isEmpty()){
				List<Contact> cont2up = new List<Contact>();
				List<AccountContactRelation> acr2up = new List<AccountContactRelation>();
				// if the main franchise is populated with the account relationship that is deleted
				for (Contact con : [SELECT Id, Main_Franchise__c FROM Contact WHERE Main_Franchise__c IN :franchiseIds.keySet() AND Id IN :con2check.keySet()]) {
					Set<Id> conRel = franchiseIds.get(con.Main_Franchise__c);
					
					if(conRel.contains(con.Id)){
					 	con.Main_Franchise__c = null;

					 	//new main franchise = account relationship where IsDirect = false
					 	if(otherRelations.containsKey(con.Id)){
					 		AccountContactRelation acr = otherRelations.get(con.Id)[0];
					 		con.Main_Franchise__c = acr.AccountId;
					 		//SW-24154
					 		acr.Update_as_Main_Franchisee__c = true;
					 		acr2up.add(acr);  
					 	}
					 	cont2up.add(con);  
					}
				}

				if(!acr2up.isEmpty()){
					update acr2up;
				}

				if(!cont2up.isEmpty()){
					update cont2up;
				}
			}
		
		}
	}

	/******************************************************************************* 
    Name              : CreateSharingRules
    Description       : handles sharing for new relations
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             03/05/2017          Yaara Nadir               [SW-24694]
    *******************************************************************************/
    public static void CreateSharingRules(){
    	List<AccountContactRelation> accRelations = new List<AccountContactRelation>();
		for(Integer i=0; i < trigger.size; i++ ){				
			AccountContactRelation r = (AccountContactRelation) trigger.new[i];
			accRelations.add(r);
		}

		if(!accRelations.isEmpty()){
			HD_SharingMethods.AccContactRelation_CreateSharingRules(accRelations);
		}
	}


}