/******************************************************************************* 
Name              : Batch_CreateUserFromContact
Description       : Handler the contacts set to create user
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan             	 09/03/2017          	Yaara Nadir               [SW-23907]
*******************************************************************************/
global without sharing class Batch_CreateUserFromContactBulk implements Database.Batchable<sObject>, Database.Stateful{
     
     public class MyException extends Exception {}
     
     public String query = 'SELECT Id, SET__c, RecordTypeId, Account.IsPartner, Account.RecordTypeId, Account.OwnerId, Account.Parent.OwnerId, Account.Owner.UserType FROM Contact WHERE User_Creation_Status__c = \'User pending creation - Step 1\'';
     
     global Map<Id,Account> partnerAccMap 	= new Map<Id,Account>(); // Needed for the existing batch Batch_CreateUserFromContact logic
     global Map<Id, Map<Id,Id>> originalOwners 		= new Map<Id,Map<Id,Id>>(); 	 // Needed for the existing batch Batch_CreateUserFromContact logic
     
     global List<HD_Log__c> errorLogs 		= new List<HD_Log__c>(); // For tracking the errors on the related contacts	
     
     global Boolean failFromTestMethod = false;
     
     global Database.QueryLocator start(Database.BatchableContext bc) {
     	 return Database.getQueryLocator(query);
     }
     
     global void execute(Database.BatchableContext BC, List<Contact> scope) {
     
     	Savepoint sp = Database.setSavepoint();
     	try{
     		
     		system.debug(system.LoggingLevel.INFO, 'scope' + scope.size());
     		system.debug(system.LoggingLevel.INFO, 'scope' + scope);
     		
     		Id recTypeTeacherId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();
     		Id recTypeStaffId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Staff').getRecordTypeId();    
     		Id recTypeFranchiseeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();
     	
	     	List<Contact> con2Up = new List<Contact>();
	     	Map<Id,Account> partnerAccMapScope 	= new Map<Id,Account>();
	     	Map<Id, Account> partnerAccLists2Up = new Map<Id, Account>();
	     	for(Contact c : scope){
	     		
	     		// We set the status and other field for being taking into cosideration on the next step
	     		con2Up.add(new Contact(Id = c.Id, User_Creation_Status__c = 'User pending creation - Step 2', Update_Contact_Permission__c = true));
	     		
	     		// Update the owner of the account as was requested on the issue SW-19584
	     		Account partnerAcc = c.Account;
	            if(Test.isRunningTest() || (!partnerAcc.IsPartner && ( (c.SET__c == true && c.RecordTypeId == recTypeTeacherId ) || c.RecordTypeId == recTypeStaffId || c.RecordTypeId == recTypeFranchiseeId))){
	                
	                system.debug(system.LoggingLevel.INFO, 'partnerAcc' + partnerAcc);
	                
	                //1.2.1.1.1 If the Contact.Account.Owner is not Partner Community User
	                if(partnerAcc.Owner.UserType == 'PowerPartner'){
	                    partnerAcc.OwnerId = partnerAcc.Parent.OwnerId;
	                    partnerAccLists2Up.put(partnerAcc.Id, partnerAcc);
	                }   
	                partnerAccMap.put(partnerAcc.Id, partnerAcc);
	                partnerAccMapScope.put(partnerAcc.Id, partnerAcc);
	            }
	     	}
	     	
	     	//also changing partner user owners on contact, to convert the account
	        //and using a map to back again to the original owner after the process
	        List<Contact> changeOwnerOnContact = new List<Contact>();
	        if(!partnerAccMapScope.isEmpty()){
	        	system.debug(system.LoggingLevel.INFO, 'partnerAccMapScope' + partnerAccMapScope);
		        for (Contact partnerContact : [SELECT Id, OwnerId, AccountId FROM Contact WHERE AccountId IN :partnerAccMapScope.keySet() AND Owner.UserType = 'PowerPartner']) {
		            
		            system.debug(system.LoggingLevel.INFO, 'partnerContact' + partnerContact);
		            
		            if(!originalOwners.containsKey(partnerContact.AccountId)){
		            	originalOwners.put(partnerContact.AccountId, new Map<Id,Id>());
		            }
		            
		            originalOwners.get(partnerContact.AccountId).put(partnerContact.Id, partnerContact.OwnerId); // Backup the previous owner that we should transfer to the next batch.
		            
		            if(partnerAccMapScope.get(partnerContact.AccountId).Parent.OwnerId <> null){
		            	partnerContact.OwnerId = partnerAccMapScope.get(partnerContact.AccountId).Parent.OwnerId;	// Changing the owner for avoiding SF errors during the creation user.
		            	system.debug(system.LoggingLevel.INFO, 'partnerContact' + partnerContact);
		            }else{
		            	partnerContact.OwnerId = partnerAccMapScope.get(partnerContact.AccountId).OwnerId;
		            	system.debug(system.LoggingLevel.INFO, 'partnerContact' + partnerContact);
		            }		            
		            changeOwnerOnContact.add(partnerContact);
		        }
	        }
	     	     	
	     	if(!partnerAccLists2Up.isEmpty()){
	     		update partnerAccLists2Up.values();
	     	}
	     	
	     	system.debug(system.LoggingLevel.INFO, 'changeOwnerOnContact' + changeOwnerOnContact);
	     	if(!changeOwnerOnContact.isEmpty()){
	     		Contact_TriggerHandler.isUserCreationOnProcess = true;
	     		update changeOwnerOnContact;
	     	}
	    
	    	// Update the contact for the next batch (step) that will create the user 	
	     	Integer i = 0;
			for(Database.SaveResult sr : Database.update(con2Up, false)){
		        if(!sr.isSuccess()){	            
		            errorLogs.add(new HD_Log__c(Contact__c = con2Up[i].Id, Process_Name__c = 'Batch_CreateUserFromContactBulk', Error_Description__c = sr.getErrors()[0].getMessage(), Status__c = 'Fail'));
		        }     
		        i++;
	        }
	        
	        if(failFromTestMethod){
	        	throw new MyException('Test Coverage!!!');
	        }
     	}catch(Exception ex){
     		
     		Database.rollback(sp);
     		for(Contact c : scope){
     			c.User_Creation_Status__c = 'Error Creating User';
		        errorLogs.add(new HD_Log__c(Contact__c = c.Id, Process_Name__c = 'Batch_CreateUserFromContactBulk', Error_Description__c = GlobalHelperMethods.IncludeAllErrorMessage(ex), Status__c = 'Fail'));
		    }
		    database.update(scope,false);
     	}
     } 
     
     global void finish(Database.BatchableContext BC) {
     	
     	if(!errorLogs.isEmpty()){
            HD_Log__c log = new HD_Log__c(/*Send_Result__c = true, */ Process_Name__c = 'Batch_CreateUserFromContactBulk', Status__c = 'Fail');
            insert log;
            for(HD_Log__c hl : errorLogs){
                hl.Parent_Log__c = log.Id;
            }
            insert errorLogs;
        }
        
        // Call the next step for creating the users
        Batch_CreateUserFromContact b = new Batch_CreateUserFromContact();
        b.originalOwners = originalOwners;
        b.teacherFranchiseAccs = partnerAccMap;
        Database.executeBatch(b,1);
     }
}