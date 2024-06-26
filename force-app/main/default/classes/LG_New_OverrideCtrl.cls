/******************************************************************************* 
Name              : LG_New_OverrideCtrl
Description       : Controller to LG new override
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez             11/04/2016       	Yaara Nadir					SW-18845
*******************************************************************************/

public class LG_New_OverrideCtrl {
    public LG_New_OverrideCtrl(ApexPages.StandardController controller) {
    	
    }

    public PageReference doRedirect(){ 
    	String lgPrefix = LG__c.sobjecttype.getDescribe().getKeyPrefix();
		PageReference returnPage = new PageReference('/' + lgPrefix + '/e');	

	   	try{
	   		//String prefix = Schema.getGlobalDescribe().get('Agreement__c').getDescribe().getKeyPrefix();
	   		//hold the param name
			HD_Settings_List__c agreementParam = HD_Settings_List__c.getInstance('LG__c.Agreement__c');	   		

			User currentUser = [SELECT AccountId, UserType FROM User WHERE Id = :Userinfo.getUserid()];

			if(currentUser.UserType == 'PowerPartner'){
				returnPage = new PageReference('/HDC/' + lgPrefix + '/e');				
				List<Agreement__c> agreements = [SELECT Name FROM Agreement__c WHERE From_Franchisee__c = :currentUser.AccountId];
				if(agreements.size() == 1){
					returnPage.getParameters().put(agreementParam.Value__c, agreements[0].Name);
				}				
			}	

			// Put relavant parameter from the current page to the redirect page
			for(String param : ApexPages.currentPage().getParameters().keySet()){
		      	if(param <> 'sfdc.override' && param <> 'save_new'){
		      		returnPage.getParameters().put(param, ApexPages.currentPage().getParameters().get(param));
				}	       	
			}
	    
		}catch(Exception e){
			System.debug(e.getMessage());
		}

		// Set "nooverride" parameter to avoid recursion
	    returnPage.getParameters().put('nooverride', '1');
	    returnPage.setRedirect(true);

		return returnPage;
	}

}