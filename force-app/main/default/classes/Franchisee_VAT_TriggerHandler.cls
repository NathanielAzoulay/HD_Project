/******************************************************************************* 
Name              : Franchisee_VAT_TriggerHandler
Description       : Handler the before/after trigger on Holiday & Vacation
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G.Fernandez                   18/03/2016              
*******************************************************************************/

public class Franchisee_VAT_TriggerHandler {
	public static void executeTriggerHandler(){
    	
		//  ---------------------------- BEFORE EVENTS -----------------------------
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		
		if (Trigger.isAfter && Trigger.isInsert){
			updateOtherVatsOnSameFranchise();
			updatePaymentOnVatChange();
		}
		if (Trigger.isAfter && Trigger.isUpdate){
		    updatePaymentOnVatChange();
		}	
    }  

    /******************************************************************************* 
	Name              : updatePaymentOnVatChange
	Description       : 
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G.Fernandez            21/03/2016		      Yaara Nadir        	SW-18017
	*******************************************************************************/

    public static void updatePaymentOnVatChange(){
    	
    	if( HD_TriggerSettings.IsTriggerActive('updatePaymentOnVatChange') ){
	    	
	    	Set<Id> franchiseeAccIds = new Set<Id>();
	    	for(Integer i=0; i < trigger.size; i++ ){	    		
				
				Franchisee_VAT__c franchiseeVat = (Franchisee_VAT__c) trigger.new[i];
	    		Boolean cond = trigger.isInsert;
				if(trigger.isUpdate){
				
					Franchisee_VAT__c odlFranchiseeVat = (Franchisee_VAT__c) trigger.old[i];
					cond = franchiseeVat.Franchisee__c != odlFranchiseeVat.Franchisee__c;					
					cond |= franchiseeVat.VAT__c != odlFranchiseeVat.VAT__c;
					cond |= franchiseeVat.VAT_From_Date__c != odlFranchiseeVat.VAT_From_Date__c;
					cond |= franchiseeVat.VAT_End_Date__c != odlFranchiseeVat.VAT_End_Date__c;
				}

				if(cond){
					franchiseeAccIds.add(franchiseeVat.Franchisee__c);
				}

			}
			
			if(!franchiseeAccIds.isEmpty()){
				Batch_applyVAT2LGPayments b = new Batch_applyVAT2LGPayments();
				b.franchiseeAccIds = franchiseeAccIds;
				Database.executeBatch(b);
			}
    	}
    }

    /******************************************************************************* 
	Name              : updateOtherVatsOnSameFranchise
	Description       : 
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G.Fernandez            27/04/2016		      Yaara Nadir        	SW-19200
	*******************************************************************************/

    public static void updateOtherVatsOnSameFranchise(){

    	if( HD_TriggerSettings.IsTriggerActive('updateOtherVatsOnSameFranchise') ){
	    	
	    	//Get all the franchisee Account involved
	    	Map<Id,List<Franchisee_VAT__c>> franchiseeAccIds = new Map<Id,List<Franchisee_VAT__c>>();
	    	for(Integer i=0; i < trigger.size; i++ ){	    		
				
				Franchisee_VAT__c franchiseeVat = (Franchisee_VAT__c) trigger.new[i];
				if(!franchiseeAccIds.containsKey(franchiseeVat.Franchisee__c)){
	    			franchiseeAccIds.put(franchiseeVat.Franchisee__c, new List<Franchisee_VAT__c>());
				}
	    		franchiseeAccIds.get(franchiseeVat.Franchisee__c).add(franchiseeVat);
			}	

			if(!franchiseeAccIds.isEmpty()){
				List<Franchisee_VAT__c> vats2up = new List<Franchisee_VAT__c>();
				//Looking for VAT on same Franchisee with end date = null
				for(Franchisee_VAT__c vat : [SELECT Id, Franchisee__c, VAT_From_Date__c FROM Franchisee_VAT__c WHERE Franchisee__c IN :franchiseeAccIds.keySet() AND VAT_End_Date__c = null]){
					for(Franchisee_VAT__c newVat : franchiseeAccIds.get(vat.Franchisee__c)){
						//comparing vat dates and populate the end with the start date of the next one
						if(vat.VAT_From_Date__c < newVat.VAT_From_Date__c && vat.Id != newVat.Id){
							vat.VAT_End_Date__c = newVat.VAT_From_Date__c.addDays(-1);
							vats2up.add(vat);
							break;
						}
					}				
				}

				if(!vats2up.isEmpty()){
					update vats2up;
				}
			}
    	}
    }
}