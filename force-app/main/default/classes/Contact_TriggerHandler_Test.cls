@isTest(seeAllData=false)
private class Contact_TriggerHandler_Test {
	// data setup method
    @testSetup static void setupData() {
        HD_TriggerSettings.disableAllTriggers = true;
        
        ObjectCreator.initializeCustomSetting();
        ObjectCreator.TestEnviroment oc = new ObjectCreator.TestEnviroment();
    }
    
    static testMethod void ContactUpdateMFID() {
		HD_TriggerSettings.disableAllTriggers = true;
        
        Id recTypeMfFpId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();  
        Id recTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();
        Id recTypeStaffId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Staff').getRecordTypeId();

        Account acc1 = ObjectCreator.getNewAccount();
        acc1.Account_Type__c = 'MF';
        acc1.RecordTypeId = recTypeMfFpId;
        acc1.Permitted_Users_per_Account__c = 99;
        //insert acc1;

        Account acc2 = ObjectCreator.getNewAccount();
        acc2.Account_Type__c = 'MF';
        acc2.RecordTypeId = recTypeMfFpId;
        acc2.Permitted_Users_per_Account__c = 99;
        acc2.ParentId = acc1.Id;
        //insert acc2;

        Account acc = ObjectCreator.getNewAccount();
        acc.Account_Type__c = 'FP';
        acc.RecordTypeId = recTypeMfFpId;
        acc.Permitted_Users_per_Account__c = 99;
        acc.ParentId = acc1.Id;       
        insert new List<Account>{acc, acc1, acc2};

        test.startTest();

        System.debug(LoggingLevel.ERROR, '*** : ' + acc2.ParentId);
        
        Contact con  = ObjectCreator.getNewContact(acc2.Id, recTypeStaffId);
        con.SET__c = false;
        con.Status__c = 'Active';
        con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
        //insert con;

        Contact con2 = ObjectCreator.getNewContact(acc.Id, recTypeStaffId);
        con2.SET__c = true;
        con2.Status__c = 'Active';
        con2.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
        insert new List<Contact>{con, con2};

        User us = ObjectCreator.getNewUser(con.Id);
        us.ProfileId = [SELECT Id FROM Profile WHERE UserType = 'PowerPartner' LIMIT 1].Id;
        us.MF_ID__c = acc2.Id;
        insert us;

        User us2 = ObjectCreator.getNewUser(con2.Id);
        us2.ProfileId = [SELECT Id FROM Profile WHERE UserType = 'PowerPartner' LIMIT 1].Id;
        insert us2;

        System.debug(LoggingLevel.ERROR, '***acc.Id : ' + acc.Id);
        System.debug(LoggingLevel.ERROR, '***acc1.Id : ' + acc1.Id);
        System.debug(LoggingLevel.ERROR, '***acc2.Id : ' + acc2.Id);
        System.debug(LoggingLevel.ERROR, '***MF_ID__c : ' + us.MF_ID__c);
		
        HD_TriggerSettings.disableAllTriggers = false;
        
        User current = new User(Id = UserInfo.getUserId());
        System.runAs(current){
            con.AccountId = acc.Id;
            update con;         
        }
		test.stopTest();
        System.debug(LoggingLevel.ERROR, '***MF_ID__c2 : ' + [SELECT Id, MF_ID__c FROM User WHERE Id = :us.Id LIMIT 1].MF_ID__c);
        //System.assert(acc.Id == us.MF_ID__c);

        //acc
    }

    static testMethod void ContactUpdateMFID2() {
        HD_TriggerSettings.disableAllTriggers = true;
        ObjectCreator.initializeCustomSetting();
        
        Id recTypeMfFpId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();  
        Id recTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();
        Id recTypeStaffId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Staff').getRecordTypeId();

        Account acc1 = ObjectCreator.getNewAccount();
        acc1.Account_Type__c = 'MF';
        acc1.RecordTypeId = recTypeMfFpId;
        acc1.Permitted_Users_per_Account__c = 99;
        //insert acc1;

        Account acc2 = ObjectCreator.getNewAccount();
        acc2.Account_Type__c = 'MF';
        acc2.RecordTypeId = recTypeMfFpId;
        acc2.Permitted_Users_per_Account__c = 99;
        acc2.ParentId = acc1.Id;        
        //insert acc2;
        
        test.startTest();

        Account acc = ObjectCreator.getNewAccount();
        acc.Account_Type__c = 'FP';
        acc.RecordTypeId = recTypeMfFpId;
        acc.Permitted_Users_per_Account__c = 99;
        acc.ParentId = acc1.Id;       
        insert new List<Account>{acc, acc2, acc1};

        System.debug(LoggingLevel.ERROR, '*** : ' + acc2.ParentId);

        Contact con2 = ObjectCreator.getNewContact(acc.Id, recTypeStaffId);
        con2.SET__c = true;
        con2.Status__c = 'Active';
        con2.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
        //insert con2;
        
        Contact con  = ObjectCreator.getNewContact(acc2.Id, recTypeId);
        con.SET__c = false;
        con.Status__c = 'Active';
        con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
        //con.Contact_Partner_User__c = us2.Id;
        insert new List<Contact>{con, con2};
        
        Id profileId = [SELECT Id FROM Profile WHERE UserType = 'PowerPartner' LIMIT 1].Id;
        User us2 = ObjectCreator.getNewUser(con2.Id);
        us2.ProfileId = profileId;
        //insert us2;
        
        User us = ObjectCreator.getNewUser(con.Id);
        us.ProfileId = profileId;
        us.MF_ID__c = acc2.Id;
        insert new List<User>{us, us2};
        
        con.Contact_Partner_User__c = us2.Id;
        update con;
        
        HD_TriggerSettings.disableAllTriggers = false;
        
        User current = new User(Id = UserInfo.getUserId());
        System.runAs(current){
            con.AccountId = acc.Id;
            con.TT_Qualified__c = 'TT';
            con.Status__c = 'Registered to TTC';
            update con;         
        }
        test.stopTest();
        Id setId = [SELECT Id FROM PermissionSet WHERE Name = 'TT_Additional_Permissions' LIMIT 1].Id;
        //System.assert([SELECT Id FROM PermissionSetAssignment WHERE PermissionSetId = :setId AND AssigneeId = :us.Id LIMIT 1].size() > 0);

        //acc
    }
    
    @isTest(seeAllData=false) 
    public static void DeactivateTeacherUser_Test01() {
        User us = [SELECT Id, ContactId FROM User WHERE IsActive = true AND ContactId != null LIMIT 1][0];
        
        Contact con1 = [SELECT Id FROM Contact LIMIT 1][0];
        con1.Status__c = 'Not Active';
        update con1;
        
        AsyncDeactivateUser asyncJob1 = new AsyncDeactivateUser();
        asyncJob1.ContactIds.add( us.ContactId );
        System.enqueueJob(asyncJob1);
        
        AsyncUpdateUsers asyncJob2 = new AsyncUpdateUsers();
        asyncJob2.conIds.put(us.ContactId, us.ContactId);
        System.enqueueJob(asyncJob2);

        
        AsyncPermissionSetAssigns asyncJob3 = new AsyncPermissionSetAssigns();
        asyncJob3.users2TT.add( [SELECT Id FROM User WHERE Id != :us.Id AND IsActive = true AND ContactId != null LIMIT 1][0].Id );
        test.startTest();
        try{
        System.enqueueJob(asyncJob3);
        }catch(Exception e){}

        test.stopTest();
    }

}