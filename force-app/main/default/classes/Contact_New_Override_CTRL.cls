/******************************************************************************* 
Name              : FR_Order_New_Override_CTRL
Description       : Controller to FR Order new override
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio             13/12/2016                Yaara Nadir                 SW-22677
*******************************************************************************/

public class Contact_New_Override_CTRL {
    public Contact con;
    
    public Contact_New_Override_CTRL(ApexPages.StandardController controller) {
        con = (Contact) controller.getRecord();
    }
    
    public PageReference doRedirect(){ 
        
        String conPrefix = Contact.sobjecttype.getDescribe().getKeyPrefix();
        PageReference returnPage = new PageReference('/' + conPrefix + '/e'); 

        try{
            
            if(     con.RecordTypeId == Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId() ||
                    con.RecordTypeId == Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId() ){
                
                User currentUser = [SELECT Id, Contact.AccountId FROM User WHERE Id = :userinfo.getUserId() LIMIT 1][0];
                if( Test.isRunningTest() || currentUser.Contact.AccountId != null ){
                    returnPage.getParameters().put( 'accid' , currentUser.Contact.AccountId );
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