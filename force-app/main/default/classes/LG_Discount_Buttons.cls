/******************************************************************************* 
Name              : LG_Buttons
Description       : Contains general Methods for buttons on LG Discount object 
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan         			02/07/2017          	
*******************************************************************************/
global class LG_Discount_Buttons {

    /******************************************************************************* 
	Name              : approveDiscounts
	Description       : Method that will approve the Special Prices. 
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Hernan         			02/07/2017          	Dafna                 SW-23511
	*******************************************************************************/
	static webservice string approveDiscounts(String discountIds){
		
		String response = 'success';
		try{
			
			Set<Id> profileWithPermission2UserTheButtton = new Set<Id>();
			for(String profId : HD_Settings_List__c.getInstance('Approve_Zero_Monthly_Payment_Profiles').Value__c.split(',')){
				profileWithPermission2UserTheButtton.add(Id.valueOf(profId));
			}			
			
			if(profileWithPermission2UserTheButtton.contains(UserInfo.getProfileId())){
			
				List<LG_Discount__c> lgD2Up = new List<LG_Discount__c>();
				for(LG_Discount__c lgD : [SELECT Id, Requested_Price_per_Month__c, Requested_Price_per_Session__c FROM LG_Discount__c WHERE Id IN: discountIds.split(',')]){
					lgD.Discount_Status__c = 'Approved';
					if(lgD.Requested_Price_per_Month__c == 0){
						lgD.Approved_Price_per_Month__c = 0;
					}
					if(lgD.Requested_Price_per_Session__c == 0){
						lgD.Approved_Price_per_Session__c = 0;
					}					
					lgD2Up.add(lgD);
				}
				update lgD2Up;
			}else{
				response = Label.Don_t_have_permission_on_button;
			}			
		}catch(Exception e){
			response = 'An error has occurred: ' + GlobalHelperMethods.ImproveErrorMessage(e);
		}		
		return response; 
	}
	
	/******************************************************************************* 
	Name              : rejectDiscounts
	Description       : Method that will reject the Special Prices. 
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Hernan         			02/07/2017          	Dafna                 SW-23511
	*******************************************************************************/
	static webservice string rejectDiscounts(String discountIds){
		
		String response = 'success';
		try{
			
			Set<Id> profileWithPermission2UserTheButtton = new Set<Id>();
			for(String profId : HD_Settings_List__c.getInstance('Reject_Zero_Monthly_Payment_Profiles').Value__c.split(',')){
				profileWithPermission2UserTheButtton.add(Id.valueOf(profId));
			}
			
			if(profileWithPermission2UserTheButtton.contains(UserInfo.getProfileId())){
				List<LG_Discount__c> lgD2Up = new List<LG_Discount__c>();
				for(LG_Discount__c lgD : [SELECT Id FROM LG_Discount__c WHERE Id IN: discountIds.split(',')]){
					lgD.Discount_Status__c = 'Rejected';
					lgD2Up.add(lgD);
				}
				update lgD2Up;	
			}else{
				response = Label.Don_t_have_permission_on_button;
			}		
		}catch(Exception e){
			response = 'An error has occurred: ' + GlobalHelperMethods.ImproveErrorMessage(e);
		}		
		return response; 
	}
}