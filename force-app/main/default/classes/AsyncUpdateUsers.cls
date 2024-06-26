/******************************************************************************* 
Name              : AsyncUpdateUsers
Description       : Avoid mixed dml from batch with user update
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez         	25/07/2016									SW-25070
*******************************************************************************/

public class AsyncUpdateUsers implements Queueable {
	public Map<Id,Id> conIds = new Map<Id,Id>();
    public Set<Id> giveTTPermissions = new Set<Id>();

    public void execute(QueueableContext context) {
		List<User> users2up = new List<User>();
		for (User u : [SELECT Id, ContactId FROM User WHERE ContactId IN :conIds.keySet() OR ContactId IN :giveTTPermissions]){
		    if(conIds.containsKey(u.ContactId)){
		    	u.MF_ID__c = conIds.get(u.ContactId);
		    }
		    if(giveTTPermissions.contains(u.ContactId)){
				u.TT_Qualified__c = 'TT';
		    }
        	users2up.add(u);
        }

        if (!users2up.isEmpty()) {
			update users2up;
        }
    }
}