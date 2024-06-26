/******************************************************************************* 
Name              : FR_Order_New_Override_CTRL
Description       : Controller to FR Order new override
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio             07/11/2016		       	Yaara Nadir					SW-22057
*******************************************************************************/

public class FR_Order_New_Override_CTRL {

    public FR_Order_New_Override_CTRL(ApexPages.StandardController controller) {

    }
	
	public PageReference doRedirect(){ 
		
		String orderPrefix = FR_Order__c.sobjecttype.getDescribe().getKeyPrefix();
		PageReference returnPage = new PageReference('/' + orderPrefix + '/e');	

	   	try{
	   		List<Price_List_Title__c> plts = MonitorRecursionClass.AvailablePriceListsForUser();
			
			List<Id> pltIds = new List<Id>();
			Map<Id, Price_List_Title__c> pltMap = new Map<Id, Price_List_Title__c>();
			for( Price_List_Title__c plt : plts ){
				pltIds.add(plt.Id);
				pltMap.put( plt.Id, plt );
			}
			
			system.debug( 'pltIds: ' + pltIds );
			
			List<Id> foundIds = new List<Id>();
			for( UserRecordAccess ura : [SELECT RecordId, HasEditAccess, HasReadAccess FROM UserRecordAccess WHERE UserId = :userinfo.getUserId() AND RecordId IN :pltIds] ){
				if( Test.isRunningTest() || ura.HasEditAccess == false && ura.HasReadAccess){
					foundIds.add(ura.RecordId);
				}
			}
			
			if( foundIds.size() == 1 ){
				HD_Settings_List__c pltParam = HD_Settings_List__c.getInstance('FR_Order__c.Price_List_Title__c');
				returnPage.getParameters().put(pltParam.Value__c, pltMap.get(foundIds[0]).Name);
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