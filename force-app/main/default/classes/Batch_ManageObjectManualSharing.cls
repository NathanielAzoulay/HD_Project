/*
 * @Date: 01/05/2018
 * @Avihai Shindelman
 @Description:
The method in this batchable class will receive those parameters: Parent Object , Child Object , Child Account Lookup name , Sharing Reason
Method execute will delete all manual sharing records for the parent object by Filters : Manual sharing row has to be related to partner user only and RowCause equals to 'Manual'.
After deletion, method will insert the records to the Child object Sharing.
Child rows: Child Account Lookup name = User.Contact.Account
 */ 
global class Batch_ManageObjectManualSharing implements Database.Batchable<sObject>  {

	static String emailAddress = 'MIS@helendorongroup.com';       
    set<id> parentsIds;
    //set <Id> testIds;
    public List<sObject> list_manual_sharing_to_delete;
    public Map<Id,Set<Id>> ManualSharingUsersToInsert;
    
    global final String query;
    global final String objParentSharingToDelete;
    global final String objChildSharingToInsert;
    global final String ParentLookupFieldAPIName;
    global final String AccountLookupFieldAPIName;
    global final String cause;
	public boolean isCustomObject;
    public string subStrObjectName;
    
    global Batch_ManageObjectManualSharing(String ParentObjAPIName, String objParentSharingToDelete, String objChildSharingToInsert, String ParentLookupFieldAPIName, String AccountLookupFieldAPIName){//, String cause){
        
        //Schema.SObjectType objectType = Schema.getGlobalDescribe().get(ParentObjAPIName);
		this.objParentSharingToDelete = objParentSharingToDelete;
        this.objChildSharingToInsert = objChildSharingToInsert;
        this.ParentLookupFieldAPIName = ParentLookupFieldAPIName;
        this.AccountLookupFieldAPIName = AccountLookupFieldAPIName;
        //define scope of the batch
        
        //Check if object is standard object or a custom object
        if (ParentObjAPIName.containsAny('_')){
        	//query = 'SELECT Id, ParentId, UserOrGroupId FROM ' +objParentSharingToDelete + ' WHERE RowCause = \'Manual\'';
            isCustomObject = true;
        }
        else//If child object is a standard object
        {
            subStrObjectName = objParentSharingToDelete.substringBefore('Share');
            //This query allows you to determine which users can view and edit objParentSharingToDelete records owned by other users
           // query = 'SELECT Id, UserOrGroupId FROM ' +objParentSharingToDelete + ' WHERE RowCause = \'' + cause + '';
            isCustomObject = false;
        }   
        //a10D000000EFdF3, a10D000000EFmn3, a10D000000EFnob, a10D000000EFkDy, a10D000000EFnel
		/*
		 testIds= new set <Id>();
        //testIds.add('a10D000000EFnoT');
         /*testIds.add('a10D000000EFmn3'); 
         testIds.add('a10D000000EFnob');
         testIds.add('a10D000000EFkDy');
         testIds.add('a10D000000EFnel');*/
        /*
        for (AggregateResult ar :[select ParentId from Course_Sub_Type__Share where RowCause = 'Manual' group by parentId])
        {
          //Id PID=(Id)Ar.get('ParentId');   
          testIds.add((Id)Ar.get('ParentId'));  
        }
          */  
        
        query ='select id from '+ParentObjAPIName ; // 
    }
     
	global Database.QueryLocator start(Database.BatchableContext BC) {
        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, list<sObject> scope) {
        parentsIds = new set<id>();
        Set<Id> userIds = new Set<Id>();
        //ManualSharingUsersToInsert  = new Map<Id,Set<Id>>();// parentid-> set Account Id'
        List<sObject> shareRecordsToInsert = new List<sObject>();
        list <Sobject> list_ss;
        String query2;
        String parAccId;
        for (sObject s : scope){
            parentsIds.add(s.id);
        }
        system.debug('parentsIds == ' +parentsIds);
        if (!parentsIds.isEmpty()){
            if (isCustomObject){//List of manual sharing records to delete
                query2 ='select parentId,UserOrGroupId,id from '+objParentSharingToDelete + ' where RowCause = \'Manual\' AND ParentId IN :parentsIds';
                parAccId = 'ParentId';
            }
            else{
                string fieldId = subStrObjectName+'Id';//AccountId, CaseId for example
                parAccId = fieldId;
                query2 ='select UserOrGroupId,id from '+objParentSharingToDelete + ' where RowCause = \'Manual\' AND '+ fieldId +' IN :parentsIds';
            }
            system.debug('query2 == ' +query2);
            if (query2 != null){//To save user ids of the manaul sharing BEFORE DELETE
                list_ss = Database.query(query2);
            }
            system.debug('list_ss == ' +list_ss);
            Map<Id,list<string>> UserParent = new Map<Id,list<string>>();
            
            for (sObject obj : list_ss){                
                List<string> list_userIds = UserParent.get((Id)obj.get(parAccId));
                if (list_userIds == null){
                    list_userIds = new List<string>();
                }
                userIds.add((Id)obj.get('UserOrGroupId'));
                list_userIds.add((string)obj.get('UserOrGroupId'));
                UserParent.put((Id)obj.get(parAccId),list_userIds);              
            }
            system.debug('UserParent == ' +UserParent);
            Map<Id,Id> userAccountIds = new Map<Id,Id>();
        	for (User u : [SELECT Id,AccountId FROM User WHERE Id IN : userIds]){
            	userAccountIds.put(u.Id,u.AccountId);                
        	}
            system.debug('userAccountIds == ' +userAccountIds);
            if (!userAccountIds.isEmpty()){
                for (Id parentObjId : UserParent.KeySet()){
                    for (String strUserId : UserParent.get(parentObjId)){
                        Sobject sObj = this.getNewSObject(objChildSharingToInsert);
                        sObj.put(ParentLookupFieldAPIName, parentObjId);                    
                        String account_id = userAccountIds.get(strUserId);
                        sObj.put(AccountLookupFieldAPIName, account_id);
                        // Prevent Null Accounts 
                        if (account_id<>null)
                        	shareRecordsToInsert.add(sObj);
                        system.debug('sObj == ' +sObj);
                    }
                }                
            }
        }
        // Rashad Saeed - Task-000001436 MFC QA Reject - Remove duplicates 
        Set<sobject> InsertSet = new Set<sobject>();
        InsertSet.addAll(shareRecordsToInsert);
        shareRecordsToInsert.clear();
        shareRecordsToInsert.addAll (InsertSet);

        try {
            system.debug('shareRecordsToInsert == ' +shareRecordsToInsert);
            insert shareRecordsToInsert;
           // Delete the existing sharing records.
           delete list_ss;
           // Insert the new sharing records and capture the save result.           
        
        } catch(DmlException e) {
           // Send an email to the Apex job's submitter on failure.
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {emailAddress}; 
            mail.setToAddresses(toAddresses); 
            mail.setSubject('Apex Sharing Recalculation Exception');
            mail.setPlainTextBody('The Apex sharing recalculation threw the following exception: ' +e.getMessage());
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
       
    }
    
    public SObject getNewSobject(String t) {
    
        /* Call global describe to get the map of string to token. */
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        
        /* Get the token for the sobject based on the type. */
        Schema.SObjectType st = gd.get(t);
        System.assert(st != null,'Type provided: "' + t + '" doesnt map to an sobject token in this org.');
        
        /* Instantiate the sobject from the token. */
        Sobject s = st.newSobject();
        
        return s;
    }

    global void finish(Database.BatchableContext BC) {

    }    
    
}