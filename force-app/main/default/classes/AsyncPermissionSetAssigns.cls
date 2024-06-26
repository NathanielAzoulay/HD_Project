/******************************************************************************* 
Name              : AsyncPermissionSetAssigns
Description       : Avoid mixed dml from batch with PermissionSet update
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez         	25/07/2016									SW-25070
*******************************************************************************/

public class AsyncPermissionSetAssigns implements Queueable {
    public List<Id> users2TT = new List<Id>();

    public void execute(QueueableContext context) {
		PermissionSet ttAdditionalPermissionsSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'TT_Additional_Permissions' LIMIT 1];
		List<PermissionSetAssignment> permissionSetAssigns2ins = new List<PermissionSetAssignment>();
		for (Id assignId : users2TT) {                
			permissionSetAssigns2ins.add(new PermissionSetAssignment(PermissionSetId = ttAdditionalPermissionsSet.Id, AssigneeId = assignId));
		}

		insert permissionSetAssigns2ins;
    }
}