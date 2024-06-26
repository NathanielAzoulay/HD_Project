/******************************************************************************* 
Name              : HelperClassWithoutSharing
Description       : Store functions without permissions
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez         02/08/2016
*******************************************************************************/

public without sharing class HelperClassWithoutSharing {

	public static Boolean isTransferOwnershipRunning = false;

	/* Retrieve all the User on the Franchisee Hierarchy that it's being used on many triggers/methods around the Sharing Rules*/
	public static Map<String,Map<Id, Set<id>>> getFranchiseeHierarchyUsers(Set<Id> franchiseeIds, Boolean includeDirectUsers, Boolean inclueDirectManagers, Boolean includeNCHierarchy){

		Map<Id, Set<id>> franchiseeHierarchyUsers = new Map<Id, Set<Id>>();
		Map<Id, Set<id>> ncHierarchyUsers = new Map<Id, Set<Id>>();
		Map<Id, Set<id>> accUsers = new Map<Id, Set<Id>>();

		Map<String, HD_Settings_List__c> cs = HD_Settings_List__c.getAll();
		Id accHelenDoronHQId;
		if(cs.containsKey('Helen Doron HQ')){
			 accHelenDoronHQId = cs.get('Helen Doron HQ').value__c; // Get the Id of the account 'Helen Doron HQ'
		}		

		Map<String,Map<Id, Set<id>>> retHierarchyUsers = new Map<String,Map<Id, Set<id>>>();
		for(Account acc : [SELECT Id, Partner_Account_Manager__c, Partner_Account_User__c, Partner_Account_NC__c,
				ParentId, Parent.ParentId, Parent.Parent.ParentId, Parent.Parent.Parent.ParentId, Parent.Parent.Parent.Parent.ParentId, 
				Parent.Partner_Account_User__c, Parent.Parent.Partner_Account_User__c, Parent.Parent.Parent.Partner_Account_User__c, Parent.Parent.Parent.Parent.Partner_Account_User__c, 
				Parent.Partner_Account_Manager__c, Parent.Parent.Partner_Account_Manager__c, Parent.Parent.Parent.Partner_Account_Manager__c, Parent.Parent.Parent.Parent.Partner_Account_Manager__c,
				Parent.Partner_Account_NC__c, Parent.Parent.Partner_Account_NC__c, Parent.Parent.Parent.Partner_Account_NC__c, Parent.Parent.Parent.Parent.Partner_Account_NC__c
				FROM Account WHERE Id IN: franchiseeIds]){
			
			franchiseeHierarchyUsers.put(acc.Id, new Set<Id>());
			ncHierarchyUsers.put(acc.Id, new Set<Id>());
			accUsers.put(acc.Id, new Set<Id>());
		
			if(acc.Partner_Account_User__c <> null){
				franchiseeHierarchyUsers.get(acc.Id).add(acc.Partner_Account_User__c);
				accUsers.get(acc.Id).add(acc.Partner_Account_User__c);
			}
			
			if(acc.Partner_Account_Manager__c <> null){
				franchiseeHierarchyUsers.get(acc.Id).add(acc.Partner_Account_Manager__c);
				accUsers.get(acc.Id).add(acc.Partner_Account_Manager__c);
			}

			if(includeNCHierarchy && acc.Partner_Account_NC__c <> null){
				ncHierarchyUsers.get(acc.Id).add(acc.Partner_Account_NC__c);
				accUsers.get(acc.Id).add(acc.Partner_Account_NC__c);
			}
			
			Account directFranchisee = acc;

			if(directFranchisee.Id != accHelenDoronHQId){
				
				for(Integer i = 0; i<3 ; i++){ // navigate to the top level of the account Hierarchy or until reach "Helen Doron HQ"
					
					directFranchisee = directFranchisee.Parent;
					if(directFranchisee == null || directFranchisee.Id == accHelenDoronHQId){
						break;
					}
					
					if(includeDirectUsers && directFranchisee.Partner_Account_User__c <> null){
						franchiseeHierarchyUsers.get(acc.Id).add(directFranchisee.Partner_Account_User__c);
					}
					
					if(inclueDirectManagers && directFranchisee.Partner_Account_Manager__c <> null){
						franchiseeHierarchyUsers.get(acc.Id).add(directFranchisee.Partner_Account_Manager__c);
					}

					if(includeNCHierarchy && directFranchisee.Partner_Account_NC__c <> null){
						ncHierarchyUsers.get(acc.Id).add(directFranchisee.Partner_Account_NC__c);
					}
				}
			}
		}		

		retHierarchyUsers.put('franchisee',franchiseeHierarchyUsers);		
		retHierarchyUsers.put('nc',ncHierarchyUsers);
		retHierarchyUsers.put('account',accUsers);

		return retHierarchyUsers;
	}

 /* Retrieve all the User down the Franchisee Hierarchy */
    public static Map<Id, Set<id>> getSubFranchiseeUsers(Set<Id> franchiseeIds){

    	//clear null from set
    	Set<Id> onlyFranchiseeIds = new Set<Id>();
    	for (Id fId : franchiseeIds) {
    		if (fId!=null) {
    			onlyFranchiseeIds.add(fId);
    		}
    	}

        Map<Id, Set<id>> subFranchiseUsers = new Map<Id, Set<Id>>();
        for(Account acc : [SELECT Id, Partner_Account_User__c, ParentId, Parent.ParentId, Parent.Parent.ParentId, Parent.Parent.Parent.ParentId, Parent.Parent.Parent.Parent.ParentId
                FROM Account WHERE ParentId IN: onlyFranchiseeIds OR Parent.ParentId IN: onlyFranchiseeIds
                 OR Parent.Parent.ParentId IN: onlyFranchiseeIds OR Parent.Parent.Parent.ParentId IN: onlyFranchiseeIds
                  OR Parent.Parent.Parent.Parent.ParentId IN: onlyFranchiseeIds]){

            if(onlyFranchiseeIds.contains(acc.ParentId)){
                if( !subFranchiseUsers.containsKey(acc.ParentId) ){
                    subFranchiseUsers.put(acc.ParentId, new Set<Id>());
                }
                subFranchiseUsers.get(acc.ParentId).add(acc.Partner_Account_User__c);
            }
            if(onlyFranchiseeIds.contains(acc.Parent.ParentId)){
                if( !subFranchiseUsers.containsKey(acc.Parent.ParentId) ){
                    subFranchiseUsers.put(acc.Parent.ParentId, new Set<Id>());
                }
                subFranchiseUsers.get(acc.Parent.ParentId).add(acc.Partner_Account_User__c);
            }
            if(onlyFranchiseeIds.contains(acc.Parent.Parent.ParentId)){
                if( !subFranchiseUsers.containsKey(acc.Parent.Parent.ParentId) ){
                    subFranchiseUsers.put(acc.Parent.Parent.ParentId, new Set<Id>());
                }
                subFranchiseUsers.get(acc.Parent.Parent.ParentId).add(acc.Partner_Account_User__c);
            }
            if(onlyFranchiseeIds.contains(acc.Parent.Parent.Parent.ParentId)){
                if( !subFranchiseUsers.containsKey(acc.Parent.Parent.Parent.ParentId) ){
                    subFranchiseUsers.put(acc.Parent.Parent.Parent.ParentId, new Set<Id>());
                }
                subFranchiseUsers.get(acc.Parent.Parent.Parent.ParentId).add(acc.Partner_Account_User__c);
            }
            if(onlyFranchiseeIds.contains(acc.Parent.Parent.Parent.Parent.ParentId)){
                if( !subFranchiseUsers.containsKey(acc.Parent.Parent.Parent.Parent.ParentId) ){
                    subFranchiseUsers.put(acc.Parent.Parent.Parent.Parent.ParentId, new Set<Id>());
                }
                subFranchiseUsers.get(acc.Parent.Parent.Parent.Parent.ParentId).add(acc.Partner_Account_User__c);
            }
        }

        return subFranchiseUsers;
    }

    /* Retrieve all the Accounts down the Franchisee Hierarchy */
    public static Map<Id,Set<Id>> getHerarchyIdByType(Set<Id> franchiseeIds, Set<Id> accTypes){

        //clear null from set
        Set<Id> onlyFranchiseeIds = new Set<Id>();
        for (Id fId : franchiseeIds) {
            if (fId!=null) {
                onlyFranchiseeIds.add(fId);
            }
        }

        Map<Id, Set<id>> subFranchiseUsers = new Map<Id, Set<Id>>();
        for(Account acc : [SELECT Id, Partner_Account_User__c, ParentId, Parent.ParentId, Parent.Parent.ParentId, Parent.Parent.Parent.ParentId, Parent.Parent.Parent.Parent.ParentId
                FROM Account WHERE RecordTypeId IN :accTypes AND (ParentId IN: onlyFranchiseeIds OR Parent.ParentId IN: onlyFranchiseeIds
                 OR Parent.Parent.ParentId IN: onlyFranchiseeIds OR Parent.Parent.Parent.ParentId IN: onlyFranchiseeIds
                  OR Parent.Parent.Parent.Parent.ParentId IN: onlyFranchiseeIds)]){

            if(onlyFranchiseeIds.contains(acc.ParentId)){
                if( !subFranchiseUsers.containsKey(acc.ParentId) ){
                    subFranchiseUsers.put(acc.ParentId, new Set<Id>());
                }
                subFranchiseUsers.get(acc.ParentId).add(acc.Id);
            }
            if(onlyFranchiseeIds.contains(acc.Parent.ParentId)){
                if( !subFranchiseUsers.containsKey(acc.Parent.ParentId) ){
                    subFranchiseUsers.put(acc.Parent.ParentId, new Set<Id>());
                }
                subFranchiseUsers.get(acc.Parent.ParentId).add(acc.Id);
            }
            if(onlyFranchiseeIds.contains(acc.Parent.Parent.ParentId)){
                if( !subFranchiseUsers.containsKey(acc.Parent.Parent.ParentId) ){
                    subFranchiseUsers.put(acc.Parent.Parent.ParentId, new Set<Id>());
                }
                subFranchiseUsers.get(acc.Parent.Parent.ParentId).add(acc.Id);
            }
            if(onlyFranchiseeIds.contains(acc.Parent.Parent.Parent.ParentId)){
                if( !subFranchiseUsers.containsKey(acc.Parent.Parent.Parent.ParentId) ){
                    subFranchiseUsers.put(acc.Parent.Parent.Parent.ParentId, new Set<Id>());
                }
                subFranchiseUsers.get(acc.Parent.Parent.Parent.ParentId).add(acc.Id);
            }
            if(onlyFranchiseeIds.contains(acc.Parent.Parent.Parent.Parent.ParentId)){
                if( !subFranchiseUsers.containsKey(acc.Parent.Parent.Parent.Parent.ParentId) ){
                    subFranchiseUsers.put(acc.Parent.Parent.Parent.Parent.ParentId, new Set<Id>());
                }
                subFranchiseUsers.get(acc.Parent.Parent.Parent.Parent.ParentId).add(acc.Id);
            }
        }

        return subFranchiseUsers;
    }


	/* Retrieve all Account down the Hierarchy */
    public static Map<Id, List<Account>> getSubFranchisees(Set<Id> franchiseeIds, Integer hierarchyLvl){

    	//clear null from set
    	Set<Id> onlyFranchiseeIds = new Set<Id>();
    	for (Id fId : franchiseeIds) {
    		if (fId!=null) {
    			onlyFranchiseeIds.add(fId);
    		}
    	}

        Map<Id, List<Account>> subFranchiseUsers = new Map<Id, List<Account>>();
        for(Account acc : [SELECT Id, OwnerId, ParentId, Parent.ParentId, Parent.Parent.ParentId, Parent.Parent.Parent.ParentId, Parent.Parent.Parent.Parent.ParentId
                FROM Account WHERE Id IN: onlyFranchiseeIds
                 OR ParentId IN: onlyFranchiseeIds OR Parent.ParentId IN: onlyFranchiseeIds
                 OR Parent.Parent.ParentId IN: onlyFranchiseeIds OR Parent.Parent.Parent.ParentId IN: onlyFranchiseeIds
                  OR Parent.Parent.Parent.Parent.ParentId IN: onlyFranchiseeIds]){

            Account directFranchisee = acc;
            for(Integer i = 0; i<=hierarchyLvl ; i++){

                if(directFranchisee == null){
                    break;
                }

	            if(onlyFranchiseeIds.contains(directFranchisee.Id)){
	                if( !subFranchiseUsers.containsKey(directFranchisee.Id) ){
	                    subFranchiseUsers.put(directFranchisee.Id, new List<Account>());
	                }
	                subFranchiseUsers.get(directFranchisee.Id).add(acc);
	            }

                directFranchisee = directFranchisee.Parent;
            }
        }

        return subFranchiseUsers;
    }

    public static List<HD_Log__c> logIns = new List<HD_Log__c>();
    public static void logResults(Database.SaveResult[] saveResult, String objName){
        for(Integer i = 0; i < saveResult.size(); i++){
            Database.SaveResult sr = saveResult.get(i);
            
            if(!sr.isSuccess() || System.Test.isRunningTest()){
                String errorMsg = 'Test Error';
                if(!System.Test.isRunningTest()){
                    errorMsg = sr.getErrors()[0].getMessage();
                }
                logIns.add(new HD_Log__c(Process_Name__c = 'Batch_TransferOwnership_Resale', Error_Description__c = objName + ' : ' + errorMsg, Status__c = 'Fail'));
                System.debug(LoggingLevel.ERROR, '*** logResults : ' + sr.getErrors()[0].getMessage());
            }
        }
    }

    public static void logResults(Database.DeleteResult[] delResult, String objName){
        for(Integer i = 0; i < delResult.size(); i++){
            Database.DeleteResult sr = delResult.get(i);
            
            if(!sr.isSuccess() || System.Test.isRunningTest()){

                String errorMsg = 'Test Error';
                if(!System.Test.isRunningTest()){
                    errorMsg = sr.getErrors()[0].getMessage();
                }
                logIns.add(new HD_Log__c(Process_Name__c = 'Batch_TransferOwnership_Resale', Error_Description__c = objName + ' : ' + errorMsg, Status__c = 'Fail'));
                System.debug(LoggingLevel.ERROR, '*** logResults : ' + sr.getErrors()[0].getMessage());
            }
        }
    }

}