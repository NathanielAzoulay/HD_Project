/******************************************************************************* 
Name              : MonitorRecursionClass
Description       : Store variables reused on triggers called multiple times
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez         02/08/2016          Ella  Bernachik           [SW-17616]
2. G. Fernandez         03/07/2016          Ella  Bernachik           [SW-18074]
3. Nicolas         		03/14/2016          Ella  Bernachik           [SW-18074]
*******************************************************************************/

public with sharing class MonitorRecursionClass {
	
    public static Boolean isRunningInitialCreateAutomaticLGLessonsByBatch = false;
    
    public static Set<Id> contentFileToChatterGroup_Ids = new Set<Id>();
    
    public static Decimal processKey;
    public static Decimal getProcessKey() {return ProcessKey;}
    public static void setProcessKey(Decimal pKey) {ProcessKey = pKey;}
    public static Boolean isLeadConverting;
    
	static Map<Id, LG__c> lgCache = new Map<Id,LG__c>();
	public static Map<Id, LG__c> getLgFromCache(Set<Id> lgIds){
		
		Boolean hasNew = false;

		//check if already exist in cache
		for(Id lgId : lgIds){
			if(!lgCache.containsKey(lgId)){
				hasNew = true;
				break;
			}				
		}
		 //if not exist add them
		if(hasNew){
			for(LG__c lg :[SELECT Name, LG_Code__c, LG_Start_Date__c, LG_End_Date__c, LG_Start_Paying_Date__c, LG_End_Paying_Date__c, Billing_Type__c, Group_Status__c, LG_Type__c, Price_Charge__c, Declared_Number_of_Students__c, Price_Type__c FROM LG__c WHERE Id IN :lgIds]){
				if(!lgCache.containsKey(lg.Id)){
					lgCache.put(lg.Id, lg);
				}
			}
		}

		return lgCache;

	}
	
	
	static Map<Id, LG_Student__c> lgStudentCache = new Map<Id,LG_Student__c>();
	public static Map<Id, LG_Student__c> getLgStudentFromCache(Set<Id> lgStudentIds){
		
		Boolean hasNew = false;

		//check if already exist in cache
		for(Id lgSId : lgStudentIds){
			if(!lgStudentCache.containsKey(lgSId)){
				hasNew = true;
				break;
			}				
		}
		 //if not exist add them
		if(hasNew){
			for(LG_Student__c lgS :[SELECT Id, Name FROM LG_Student__c WHERE Id IN :lgStudentIds]){
				if(!lgStudentCache.containsKey(lgS.Id)){
					lgStudentCache.put(lgS.Id, lgS);
				}
			}
		}

		return lgStudentCache;

	}

	static Map<String,Map<Id, Set<id>>> franchiseeHierarchyUsersCache = new Map<String,Map<Id, Set<id>>>();
	static Map<String,Boolean> hierarchyRequest = new Map<String,Boolean>();
	public static Map<String,Map<Id, Set<id>>> getfranchiseeHierarchyUsersCache(Set<Id> accIds, Boolean includeDirectUsers, Boolean inclueDirectManagers, Boolean includeNCHierarchy){
		
		Map<String,Map<Id, Set<id>>> hierarchyUsers = franchiseeHierarchyUsersCache;

		Boolean cond = includeDirectUsers != hierarchyRequest.get('includeDirectUsers');
		cond = cond || inclueDirectManagers != hierarchyRequest.get('inclueDirectManagers');
		cond = cond || includeNCHierarchy != hierarchyRequest.get('includeNCHierarchy');

		//check if already exist in cache
		if (cond || !franchiseeHierarchyUsersCache.get('franchisee').keySet().containsAll(accIds)) {
			hierarchyUsers = HelperClassWithoutSharing.getFranchiseeHierarchyUsers(accIds, includeDirectUsers, inclueDirectManagers, includeNCHierarchy);
		}

		return hierarchyUsers;

	}

	static Map<Id, Set<id>> franchiseeNCHierarchyUsersCache = new Map<Id, Set<id>>();

	//same from above but only for NC
	public static Map<Id, Set<id>> getfranchiseeNCHierarchyUsers(Set<Id> accIds){
		
		Map<String, HD_Settings_List__c> cs = HD_Settings_List__c.getAll();
		Id accHelenDoronHQId;
		if(cs.containsKey('Helen Doron HQ')){
			 accHelenDoronHQId = cs.get('Helen Doron HQ').value__c; // Get the Id of the account 'Helen Doron HQ'
		}
		
		Map<Id, Set<id>> franchiseeNCHierarchyUsers = franchiseeNCHierarchyUsersCache;
		
		if (!franchiseeNCHierarchyUsersCache.keySet().containsAll(accIds)) {
			for(Account acc : [SELECT Id, Partner_Account_NC__c,
					ParentId, Parent.ParentId, Parent.Parent.ParentId, Parent.Parent.Parent.ParentId,
					Parent.Parent.Parent.Parent.ParentId, Parent.Partner_Account_NC__c, Parent.Parent.Partner_Account_NC__c,
					Parent.Parent.Parent.Partner_Account_NC__c, Parent.Parent.Parent.Parent.Partner_Account_NC__c
					FROM Account WHERE Id IN: accIds]){
			
				franchiseeNCHierarchyUsers.put(acc.Id, new Set<Id>());
				
				if(acc.Partner_Account_NC__c <> null){
					franchiseeNCHierarchyUsers.get(acc.Id).add(acc.Partner_Account_NC__c);
				}
				
				Account directFranchisee = acc;
				for(Integer i = 0; i<3 ; i++){ // navigate to the top level of the account Hierarchy or until reach "Helen Doron HQ"
					directFranchisee = directFranchisee.Parent;

					if(directFranchisee == null || directFranchisee.Id == accHelenDoronHQId){
						break;
					}
					
					if(directFranchisee.Partner_Account_NC__c <> null){
						franchiseeNCHierarchyUsers.get(acc.Id).add(directFranchisee.Partner_Account_NC__c);
					}				
				}	
			}
			franchiseeNCHierarchyUsersCache = franchiseeNCHierarchyUsers;
		}
		return franchiseeNCHierarchyUsers;
	}
	
	/*
		Method used for retrieving available Price List for the current User, With Sharing rules
	*/
	public static List<Price_List_Title__c> AvailablePriceListsForUser(){
		return [SELECT Id, Name FROM Price_List_Title__c WHERE Active_Formula__c = true ];
	}
}