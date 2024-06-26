/******************************************************************************* 
Name              : AsyncDeactivateUser
Description       : Avoid mixed dml from batch with user update
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez         	05/13/2016									SW-24105
*******************************************************************************/

public class AsyncDeactivateUser implements Queueable {
	public List<Id> contactIds = new List<Id>();

    public void execute(QueueableContext context) {
		List<User> users2up = new List<User>();
		for (User u : [SELECT Id FROM User WHERE ContactId IN :contactIds]) {
			u.IsActive = false;
			users2up.add(u);
		}  
		
		update users2up;
    }
}