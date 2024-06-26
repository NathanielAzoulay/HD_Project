/******************************************************************************* 
Name              : Batch_CreateUserFromContact3
Description       : Handler the contacts set to create user, updates after success user creation
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez             06/15/2016          Yaara Nadir               [SW-19584]
*******************************************************************************/

global class Batch_CreateUserFromContact3 implements Database.Batchable<sObject> {
    public String query;
    global List<GroupMember> newMembers{get; set;}
    global List<Id> permissionSetAssigns = new List<Id>();
    global List<Id> permissionTTAssigns = new List<Id>();    

    global Iterable<sObject> start(Database.BatchableContext bc) {
    	
        return newMembers;
    }

    global void execute(Database.BatchableContext BC, List<GroupMember> scope) {
        //add new group members //TODO mixed dml
        System.debug(System.LoggingLevel.INFO,' newChatters scope ' + scope);
        database.insert(scope, false);

        /*
        Permission set Insert
        */
        if(!permissionSetAssigns.isEmpty()){

            PermissionSet hdcAdviceILCFpermSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'HDC_Advice_of_Payment_for_ILCF' LIMIT 1];
            List<PermissionSetAssignment> permissionSetAssigns2ins = new List<PermissionSetAssignment>();
            for (Id assignId : permissionSetAssigns) {                
                permissionSetAssigns2ins.add(new PermissionSetAssignment(PermissionSetId = hdcAdviceILCFpermSet.Id, AssigneeId = assignId));
            }
            database.insert(permissionSetAssigns2ins, false);
        }

        if(!permissionTTAssigns.isEmpty()){
            PermissionSetAssigns(permissionTTAssigns);
        }
    }

    global void finish(Database.BatchableContext BC) {

    }

    public static void PermissionSetAssigns(List<Id> userIds){
        
        PermissionSet ttAdditionalPermissionsSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'TT_Additional_Permissions' LIMIT 1];
        List<PermissionSetAssignment> permissionSetAssigns2ins = new List<PermissionSetAssignment>();
        for (Id assignId : userIds) {                
            permissionSetAssigns2ins.add(new PermissionSetAssignment(PermissionSetId = ttAdditionalPermissionsSet.Id, AssigneeId = assignId));
        }
        database.insert(permissionSetAssigns2ins,false);
    }
}