/******************************************************************************* 
Name              : PriceListTitleCloneOverrideCtrl
Description       : Controller to Price List Title clone override
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez             12/04/2016       	Yaara Nadir					SW-18898
*******************************************************************************/


public class PriceListTitleCloneOverrideCtrl {
    public PriceListTitleCloneOverrideCtrl(ApexPages.StandardController controller) {
    	
    }

    public PageReference doRedirect(){ 
    	System.debug(ApexPages.currentPage().getParameters());
    	PageReference returnPage = new PageReference(ApexPages.currentPage().getParameters().get('retURL') + '/e?clone=1');	
    	String sourcePriceListId = ApexPages.currentPage().getParameters().get('retURL').substring(1);
	   	try{

	   		User currentUser = [SELECT AccountId, UserType FROM User WHERE Id = :Userinfo.getUserid()];
	   		if(currentUser.UserType == 'PowerPartner'){	
				String checkRet = ApexPages.currentPage().getParameters().get('retURL');
				if(!checkRet.contains('/e?')){
					returnPage = new PageReference(checkRet.substring(0,20) + '/e?clone=1'  + checkRet.substring(20));
				}
				sourcePriceListId = ApexPages.currentPage().getParameters().get('retURL').substring(5,20);
			}
			Price_List_Title__c sourcePriceList = [SELECT Name FROM Price_List_Title__c WHERE Id = :sourcePriceListId];

	   		// Put relavant parameter from the current page to the redirect page
			for(String param : ApexPages.currentPage().getParameters().keySet()){
		      	if(param <> 'sfdc.override' && param <> 'clone'){
		      		returnPage.getParameters().put(param, ApexPages.currentPage().getParameters().get(param));
				}	       	
			}

			HD_Settings_List__c startDateParam = HD_Settings_List__c.getInstance('Price_List_Title__c.Start_Date__c');
			HD_Settings_List__c clonedFromParam = HD_Settings_List__c.getInstance('Price_List_Title__c.Cloned_From__c');
			
			returnPage.getParameters().put(startDateParam.Value__c, System.today().format());
			returnPage.getParameters().put(clonedFromParam.Value__c, sourcePriceList.Name);   		

		}catch(Exception e){
			System.debug(e.getMessage());
		}

		// Set "nooverride" parameter to avoid recursion
	    returnPage.getParameters().put('nooverride', '1');
	    returnPage.setRedirect(true);

		return returnPage;
	}

}