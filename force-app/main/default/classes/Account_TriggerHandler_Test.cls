/******************************************************************************* 
Name              : deactivateAccountUsers
Description       : Disable users when account is not active
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez        		05/30/2016          	Yaara			  	[SW-19583]
*******************************************************************************/

@isTest
private class Account_TriggerHandler_Test {
    static testMethod void deactivateAccountUsers() {

    	ObjectCreator.initializeCustomSetting();
        
        Account acc = ObjectCreator.getNewAccount();
    	acc.Account_Status__c = 'Active';
    	acc.Account_No_in_Infoman__c = 666;
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();
	    insert acc;

	    Contact con	= ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
	    insert con;

		User us = ObjectCreator.getNewUser(con.Id);
		us.ProfileId = [SELECT Id FROM Profile WHERE UserType = 'PowerPartner' LIMIT 1].Id;
    	insert us;

        Contact con2 = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert con2;

        User us2 = ObjectCreator.getNewUser(con2.Id);
        us.ProfileId = [SELECT Id FROM Profile WHERE UserType = 'PowerPartner' LIMIT 1].Id;
        insert us2;

    	System.assert( [SELECT IsPartner FROM Account WHERE Id = :acc.Id].IsPartner == true );
		System.debug('before deactivateAccountUsers ' + [SELECT IsPartner FROM Account WHERE Id = :acc.Id]);

        User thisUser = [ SELECT Id FROM User WHERE Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
        Test.startTest();        
        	acc.Account_Status__c = 'Candidate';
            acc.Partner_Account_Manager__c = thisUser.Id;
            acc.Partner_Account_NC__c = thisUser.Id;
        	update acc;
        	
        	Account_TriggerHandler.DeactivateUsers( new List<Id>{ acc.Id } );
            
            for( User usWithAcc : [SELECT Id, AccountId FROM User WHERE IsActive = true AND AccountId != null LIMIT 1] ){
            	Account_TriggerHandler.DeactivateUsersFuture( new List<Id>{ usWithAcc.AccountId } );
            }
        Test.stopTest();
        }

		System.debug('after deactivateAccountUsers ' + [SELECT IsPartner, Account_Status__c FROM Account WHERE Id = :acc.Id]);
    
        System.assert( [SELECT IsActive FROM User WHERE IsActive = false AND (Id = :us.Id OR Id = :us2.Id )].size() == 2);
    	/*System.assert( [SELECT IsPartner FROM Account WHERE Id = :acc.Id].IsPartner == false );
    	*/

    }
}