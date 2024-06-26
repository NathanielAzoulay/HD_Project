@isTest
private class Batch_CreateUserFromContact_Test {

    
    @isTest(seeAllData=false)
    static void Batch_CreateUserFromContactBulk_Test() {
        
        insert new HD_Settings_List__c(Name = 'HD Community ID', Value__c = '0DBD0000000TO1V');
        
        Id recTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();
        
        Account acc = ObjectCreator.getNewAccount();
        acc.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        acc.Partner_Account_User__c = userinfo.getUserId();
        insert acc;

        Contact con  = ObjectCreator.getNewContact(acc.Id, recTypeId);
        con.SET__c = false;
        con.Status__c = 'Active';
        con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
        insert con;

        User thisUser = [ SELECT Id FROM User WHERE Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            con.User_Creation_Status__c = 'User pending creation - Step 1';
            update con;
        }

        insert new HDC_Mass_Email__c(Name = 'HDC Teacher', Has_Access_Mass_Email__c = false, Mass_Email_Limit__c = 10, Mass_Email_Limit_in_Counter_period__c = 10, Profile_Name__c = 'HDC Teacher');
        
        Test.startTest();

            Batch_CreateUserFromContactBulk b = new Batch_CreateUserFromContactBulk();
            Database.executeBatch(b,10);

        Test.stopTest();

        for(HD_log__c log : [SELECT Error_Description__c FROM HD_Log__c]){
            system.debug(system.LoggingLevel.ERROR, log);
        }

        //System.assertEquals('User pending creation - Step 2', [SELECT User_Creation_Status__c FROM Contact WHERE Id = :con.Id].User_Creation_Status__c);    
        //System.assert([SELECT Id FROM USER WHERE ContactId = :con.Id AND isActive=true].size() == 1);
    }
    
    @isTest(seeAllData=false)
    static void Batch_CreateUserFromContactBulkb_Test() {
        
        insert new HD_Settings_List__c(Name = 'HD Community ID', Value__c = '0DBD0000000TO1V');
        
        Id recTypeFranchiseeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();

        Account acc = ObjectCreator.getNewAccount();
        // add email to account
        acc.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';
        insert acc;

        Contact con  = ObjectCreator.getNewContact(acc.Id, recTypeFranchiseeId);
        con.SET__c = false;
        con.Status__c = 'Active';
        con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
        insert con;

        User u = ObjectCreator.getNewUser(con.Id);
        insert u;

        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            con.User_Creation_Status__c = 'User pending creation - Step 1';
            con.LastName = 'ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ';
            update con;
        }
        
        Test.startTest();

            Batch_CreateUserFromContactBulk b = new Batch_CreateUserFromContactBulk();
            Database.executeBatch(b,10);

        Test.stopTest();

        System.debug([SELECT Id FROM USER WHERE ContactId = :con.Id AND isActive=true]);
        System.assert([SELECT Id FROM USER WHERE ContactId = :con.Id AND isActive=true].size() == 1);
    }


    @isTest(seeAllData=false)
    static void Batch_CreateUserFromContactBulkc_Test() {
        
        insert new HD_Settings_List__c(Name = 'HD Community ID', Value__c = '0DBD0000000TO1V');
        
        Id recTypeLcSetLsfId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId();
        Id recTypeFranchiseeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();

        Account accParent = ObjectCreator.getNewAccount();
        accParent.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        accParent.Account_Type__c = 'MF';
        insert accParent;

        Account acc = ObjectCreator.getNewAccount();
        acc.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';
        acc.RecordTypeId = recTypeLcSetLsfId;
        acc.Permitted_Users_per_Account__c = 99; 
        acc.ParentId = accParent.Id;
        insert acc;
        
        Contact con  = ObjectCreator.getNewContact(acc.Id, recTypeFranchiseeId);
        con.FirstName = 'verylongnameverylongnameverylongname';
        con.LastName = 'verylongnameverylongnameverylongname';
        con.SET__c = false;
        con.Status__c = 'Active';
        con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
        insert con;

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs ( thisUser ) {
            acc.IsPartner = true;
            update acc;
        }

        System.runAs ( thisUser ) {
            con.User_Creation_Status__c = 'User pending creation - Step 1';
            update con;
        }
        
        Test.startTest();

            Batch_CreateUserFromContactBulk b = new Batch_CreateUserFromContactBulk();
            b.failFromTestMethod = true;
            Database.executeBatch(b,10);

        Test.stopTest();
    }


    @isTest(seeAllData=false)
    static void Batch_CreateUserFromContactBulkd_Test() {
        
        insert new HD_Settings_List__c(Name = 'HD Community ID', Value__c = '0DBD0000000TO1V');
        
        Id recTypeFranchiseeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();

        Account acc = ObjectCreator.getNewAccount();
        acc.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        acc.Account_Type__c= 'MF';
        acc.Permitted_Users_per_Account__c = 99;        
        insert acc;
        
        Contact con  = ObjectCreator.getNewContact(acc.Id, recTypeFranchiseeId);
        con.SET__c = false;
        con.Status__c = 'Active';
        con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
        insert con;

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs ( thisUser ) {
            acc.IsPartner = true;
            update acc;
        }

        System.runAs ( thisUser ) {
            con.User_Creation_Status__c = 'User pending creation - Step 1';
            update con;
        }
        
        Test.startTest();

            Batch_CreateUserFromContactBulk b = new Batch_CreateUserFromContactBulk();
            Database.executeBatch(b,10);

        Test.stopTest();
    }

    
    @isTest(seeAllData=false)
    static void Batch_CreateUserFromContactBulke_Test() {
        
        insert new HD_Settings_List__c(Name = 'HD Community ID', Value__c = '0DBD0000000TO1V');
        
        Id recTypeMfFpId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();
        Id recTypeFranchiseeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();

        Account acc = ObjectCreator.getNewAccount();
        acc.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        acc.Account_Type__c= 'MF';
        acc.RecordTypeId = recTypeMfFpId;
        acc.Permitted_Users_per_Account__c = 99;        
        insert acc;
        
        Contact con  = ObjectCreator.getNewContact(acc.Id, recTypeFranchiseeId);
        con.SET__c = false;
        con.Status__c = 'Active';
        con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
        insert con;

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs ( thisUser ) {
            acc.IsPartner = true;
            update acc;
        }

        System.runAs ( thisUser ) {
            con.User_Creation_Status__c = 'User pending creation - Step 1';
            update con;
        }
        
        Test.startTest();

            Batch_CreateUserFromContactBulk b = new Batch_CreateUserFromContactBulk();
            b.partnerAccMap.put(acc.Id,acc);
            Database.executeBatch(b,10);

        Test.stopTest();
    }
    
    @isTest(seeAllData=false)
    static void setConvertStatusForBulk_Test() {
        Id recTypeLCSLSF = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId(); 
        Id recTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Staff').getRecordTypeId(); 
        
        Account acc1 = ObjectCreator.getNewAccount();
        acc1.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        insert acc1;

        Contact con1  = ObjectCreator.getNewContact(acc1.Id, recTypeId);
        insert con1;

        User us = ObjectCreator.getNewUser(con1.Id);
        us.ProfileId = [SELECT Id FROM Profile WHERE UserType = 'PowerPartner' LIMIT 1].Id;
        insert us;

        Contact con;
        Account acc2;
        System.runAs(us){
            acc2 = ObjectCreator.getNewAccount();
            acc2.Account_Type__c= 'MF';
            acc2.RecordTypeId = recTypeLCSLSF;
            acc2.Permitted_Users_per_Account__c = 99;
            acc2.ParentId = acc1.Id; 
            acc2.Partner_Account_User__c = null;     
            acc2.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';
  
            insert acc2;

            con  = ObjectCreator.getNewContact(acc2.Id, recTypeId);
            con.SET__c = false;
            con.Status__c = 'Active';
            con.User_Creation_Status__c = 'User pending creation - Step 1';
            con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
            insert con;
        }

        Test.startTest();

            Batch_CreateUserFromContactBulk b = new Batch_CreateUserFromContactBulk();
            b.partnerAccMap.put(acc2.Id,acc2);
            b.partnerAccMap.put(acc1.Id,acc1);
            Database.executeBatch(b,10);

        Test.stopTest();
        
        
    }

    
    
    ////////////////////////

    @isTest(seeAllData=false)
    static void Batch_CreateUserFromContacta0_Test() {

        Id recTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();

        Account acc = ObjectCreator.getNewAccount();
        acc.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        insert acc;

        Contact con  = ObjectCreator.getNewContact(acc.Id, recTypeId);
        con.SET__c = false;
        con.Teacher__c = true;
        con.Status__c = 'Active';      
        insert con;

        System.assert([SELECT Teacher__c FROM Contact WHERE Id =: con.Id].size() == 1);

        User thisUser = [ SELECT Id FROM User WHERE Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            con.User_Creation_Status__c = 'Create User';
            con.Status__c = 'Not Active';
            update con;
        }
        
        Test.startTest();
            Batch_CreateUserFromContact b = new Batch_CreateUserFromContact(con.Id);            
            b.errorLogs.add(new HD_Log__c(Process_Name__c = 'Batch_CreateUserFromContact', Error_Description__c = 'Test', Status__c = 'Fail'));  
            Database.executeBatch(b,10);

        Test.stopTest();
    }

        @isTest(seeAllData=false)
    static void Batch_CreateUserFromContacta_Test() {

        Id recTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();
        
        Account acc = ObjectCreator.getNewAccount();
        acc.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        acc.Partner_Account_User__c = userinfo.getUserId();
        insert acc;

        Contact con  = ObjectCreator.getNewContact(acc.Id, recTypeId);
        con.SET__c = false;
        con.Status__c = 'Active';
        con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
        insert con;

        User thisUser = [ SELECT Id FROM User WHERE Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            con.User_Creation_Status__c = 'Create User';
            update con;
        }

        insert new HDC_Mass_Email__c(Name = 'HDC Teacher', Has_Access_Mass_Email__c = false, Mass_Email_Limit__c = 10, Mass_Email_Limit_in_Counter_period__c = 10, Profile_Name__c = 'HDC Teacher');
        
        Test.startTest();

            Batch_CreateUserFromContact b = new Batch_CreateUserFromContact(con.Id);
            Database.executeBatch(b,10);

        Test.stopTest();

        System.debug([SELECT Id FROM USER WHERE ContactId = :con.Id AND isActive=true]);
        System.assert([SELECT Id FROM USER WHERE ContactId = :con.Id AND isActive=true].size() == 1);
    }


    @isTest(seeAllData=false)
    static void Batch_CreateUserFromContactb_Test() {

        Id recTypeFranchiseeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();

        Account acc = ObjectCreator.getNewAccount();
        acc.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        insert acc;

        Contact con  = ObjectCreator.getNewContact(acc.Id, recTypeFranchiseeId);
        con.SET__c = false;
        con.Status__c = 'Active';
        con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
        insert con;

        User u = ObjectCreator.getNewUser(con.Id);
        insert u;

        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            con.User_Creation_Status__c = 'Create User';
            con.LastName = 'ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ';
            update con;
        }
        
        Test.startTest();

            Batch_CreateUserFromContact b = new Batch_CreateUserFromContact(con.Id);
            Database.executeBatch(b,10);

        Test.stopTest();

        System.debug([SELECT Id FROM USER WHERE ContactId = :con.Id AND isActive=true]);
        System.assert([SELECT Id FROM USER WHERE ContactId = :con.Id AND isActive=true].size() == 1);
    }


    @isTest(seeAllData=false)
    static void Batch_CreateUserFromContactc_Test() {
        Id recTypeLcSetLsfId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId();
        Id recTypeFranchiseeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();

        Account accParent = ObjectCreator.getNewAccount();
        accParent.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        accParent.Account_Type__c = 'MF';
        insert accParent;

        Account acc = ObjectCreator.getNewAccount();
        acc.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        acc.RecordTypeId = recTypeLcSetLsfId;
        acc.Permitted_Users_per_Account__c = 99; 
        acc.ParentId = accParent.Id;
        insert acc;
        
        Contact con  = ObjectCreator.getNewContact(acc.Id, recTypeFranchiseeId);
        con.FirstName = 'verylongnameverylongnameverylongname';
        con.LastName = 'verylongnameverylongnameverylongname';
        con.SET__c = false;
        con.Status__c = 'Active';
        con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
        insert con;

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs ( thisUser ) {
            acc.IsPartner = true;
            update acc;
        }

        System.runAs ( thisUser ) {
            con.User_Creation_Status__c = 'Create User';
            update con;
        }
        
        Test.startTest();

            Batch_CreateUserFromContact b = new Batch_CreateUserFromContact(con.Id);
            Database.executeBatch(b,10);

        Test.stopTest();
    }


    @isTest(seeAllData=false)
    static void Batch_CreateUserFromContactd_Test() {
        Id recTypeFranchiseeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();

        Account acc = ObjectCreator.getNewAccount();
        acc.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        acc.Account_Type__c= 'MF';
        acc.Permitted_Users_per_Account__c = 99;        
        insert acc;
        
        Contact con  = ObjectCreator.getNewContact(acc.Id, recTypeFranchiseeId);
        con.SET__c = false;
        con.Status__c = 'Active';
        con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
        insert con;

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs ( thisUser ) {
            acc.IsPartner = true;
            update acc;
        }

        System.runAs ( thisUser ) {
            con.User_Creation_Status__c = 'Create User';
            update con;
        }
        
        Test.startTest();

            Batch_CreateUserFromContact b = new Batch_CreateUserFromContact(con.Id);
            Database.executeBatch(b,10);

        Test.stopTest();
    }

    
    @isTest(seeAllData=false)
    static void Batch_CreateUserFromContacte_Test() {
        Id recTypeMfFpId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();
        Id recTypeFranchiseeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();

        Account acc = ObjectCreator.getNewAccount();
        acc.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        acc.Account_Type__c= 'MF';
        acc.RecordTypeId = recTypeMfFpId;
        acc.Permitted_Users_per_Account__c = 99;        
        insert acc;
        
        Contact con  = ObjectCreator.getNewContact(acc.Id, recTypeFranchiseeId);
        con.SET__c = false;
        con.Status__c = 'Active';
        con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
        insert con;

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs ( thisUser ) {
            acc.IsPartner = true;
            update acc;
        }

        System.runAs ( thisUser ) {
            con.User_Creation_Status__c = 'Create User';
            update con;
        }
        
        Test.startTest();

            Batch_CreateUserFromContact b = new Batch_CreateUserFromContact(con.Id);
            b.teacherFranchiseAccs.put(acc.Id,acc);
            Database.executeBatch(b,10);

        Test.stopTest();
    } 


    class RemoteResponse{
        String error;
        String status;
        public RemoteResponse(String p_status, String p_error){
            error = p_error; 
            status = p_status;
        }
        public RemoteResponse(){

        }
    }

    @isTest(seeAllData=true)
    static void validateConvertRequest_Test() {
        Id recTypeLCSLSF = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId(); 
        Id recTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Staff').getRecordTypeId(); 
        Id recTypeTeacherId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();
        
        Account acc1 = ObjectCreator.getNewAccount();
        // add email to account
        acc1.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';
        insert acc1;

        Contact con1  = ObjectCreator.getNewContact(acc1.Id, recTypeId);

        insert con1;

        Account acc2 = ObjectCreator.getNewAccount();
        acc2.Account_Type__c= 'MF';
        acc2.RecordTypeId = recTypeLCSLSF;
        acc2.Permitted_Users_per_Account__c = 99;
        acc2.ParentId = acc1.Id; 
        acc2.Partner_Account_User__c = null;   
        acc2.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';    
        insert acc2;

        Contact con  = ObjectCreator.getNewContact(acc2.Id, recTypeId);
        con.SET__c = false;
        con.Status__c = 'Active';
        con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
        insert con;

        User us1 = ObjectCreator.getNewUser(con1.Id);
        us1.CommunityNickname = Batch_CreateUserFromContact.getNickname(con.FirstName, con.LastName).CommunityNickname;
        insert us1;

        Batch_CreateUserFromContact.validateConvertRequest(con.Id);
        
    }

    @isTest(seeAllData=false)
    static void validateConvertRequest2_Test() {
        Id recTypeLCSLSF = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId(); 
        Id recTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Staff').getRecordTypeId(); 
        Id recTypeTeacherId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();
        
        Account acc1 = ObjectCreator.getNewAccount();
        acc1.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        insert acc1;

        Account acc2 = ObjectCreator.getNewAccount();
        acc2.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        acc2.Account_Type__c= 'MF';
        acc2.RecordTypeId = recTypeLCSLSF;
        acc2.Permitted_Users_per_Account__c = 99;
        acc2.ParentId = acc1.Id; 
        acc2.Partner_Account_User__c = null;       
        insert acc2;

        Contact con  = ObjectCreator.getNewContact(acc2.Id, recTypeId);
        con.SET__c = false;
        con.Status__c = 'Active';
        con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
        insert con;

        String retVal = Batch_CreateUserFromContact.validateConvertRequest(con.Id);
        RemoteResponse response = (RemoteResponse) JSON.deserialize(retVal, RemoteResponse.class);
        System.assertEquals('Success', response.status);

        con.RecordTypeId = recTypeTeacherId;
        con.Status__c = 'Potential';
        update con;
        
        Batch_CreateUserFromContact.validateConvertRequest(con.Id);

        User us = ObjectCreator.getNewUser(con.Id);
        us.ProfileId = [SELECT Id FROM Profile WHERE UserType = 'PowerPartner' LIMIT 1].Id;
        us.IsActive = true;
        insert us;

        Batch_CreateUserFromContact.validateConvertRequest(con.Id);
        
    }


    @isTest(seeAllData=false)
    static void setConvertStatus_Test() {
        Id recTypeLCSLSF = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId(); 
        Id recTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Staff').getRecordTypeId(); 
        
        Account acc1 = ObjectCreator.getNewAccount();
        acc1.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        insert acc1;

        Contact con1  = ObjectCreator.getNewContact(acc1.Id, recTypeId);
        insert con1;

        User us = ObjectCreator.getNewUser(con1.Id);
        us.ProfileId = [SELECT Id FROM Profile WHERE UserType = 'PowerPartner' LIMIT 1].Id;
        insert us;

        Contact con;
        System.runAs(us){
            Account acc2 = ObjectCreator.getNewAccount();
            acc2.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

            acc2.Account_Type__c= 'MF';
            acc2.RecordTypeId = recTypeLCSLSF;
            acc2.Permitted_Users_per_Account__c = 99;
            acc2.ParentId = acc1.Id; 
            acc2.Partner_Account_User__c = null;       
            insert acc2;

            con  = ObjectCreator.getNewContact(acc2.Id, recTypeId);
            con.SET__c = false;
            con.Status__c = 'Active';
            con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
            insert con;
        }

        String retVal = Batch_CreateUserFromContact.setConvertStatus(con.Id);
        RemoteResponse response = (RemoteResponse) JSON.deserialize(retVal, RemoteResponse.class);
        
        System.debug(LoggingLevel.ERROR, '*** retVal: ' + retVal);
        System.assertEquals('Success', response.status);
    }

    @isTest(seeAllData=false)
    static void setConvertStatus2_Test() {
        //Id recTypeFranchiseeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();
        Id recTypeStaffId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Staff').getRecordTypeId();
        Id recTypeLCSLSF = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId(); 
        
        Account acc1 = ObjectCreator.getNewAccount();
        acc1.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        insert acc1;

        Account acc2 = ObjectCreator.getNewAccount();
        acc2.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        acc2.Account_Type__c= 'MF';
        acc2.RecordTypeId = recTypeLCSLSF;
        acc2.Permitted_Users_per_Account__c = 99;
        acc2.ParentId = acc1.Id; 
        acc2.Partner_Account_User__c = null;       
        insert acc2;

        System.debug(LoggingLevel.ERROR, '*** : ' + acc2.ParentId);
        
        Contact con  = ObjectCreator.getNewContact(acc2.Id, recTypeStaffId);
        con.SET__c = false;
        con.Status__c = 'Active';
        con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
        insert con;

        String retVal = Batch_CreateUserFromContact.setConvertStatus(con.Id);
        RemoteResponse response = (RemoteResponse) JSON.deserialize(retVal, RemoteResponse.class);
        
        System.debug(LoggingLevel.ERROR, '*** retVal: ' + retVal);
        System.assertEquals('Success', response.status);
    }

    @isTest(seeAllData=false)
    static void GetMFID_Test() {
        Id recTypeTeacherId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();
        Id recTypeFranchiseeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();

        Account pAcc = ObjectCreator.getNewAccount();
        pAcc.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        pAcc.Account_Type__c = 'MF';

        Account acc = ObjectCreator.getNewAccount();
        acc.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        acc.Account_Type__c = 'MF';
        acc.Parent = pAcc;
     
        Contact con = new Contact(FirstName = 'FirstNameTest140217 ', LastName = 'LastNameTest140217', RecordTypeId = recTypeFranchiseeId);       
        con.Account = pAcc;
        con.SET__c = false;
        Batch_CreateUserFromContact.getMF(con);


        con.RecordTypeId = recTypeTeacherId;
        con.SET__c = true;
        Batch_CreateUserFromContact.getMF(con);

        con.Account = acc;
        Batch_CreateUserFromContact.getMF(con);

        pAcc.Account_Type__c = 'ILCF';
        acc.Parent = pAcc;
        con.Account = acc;
        Batch_CreateUserFromContact.getMF(con);

    }



    /*
    *
    *
    */



    @isTest(seeAllData=false)
    static void Batch_CreateUserFromContact2_Test() {

        //Prod
        String communityId = '0DBD0000000TO1V';
        //Dev
        if( '00De0000001O0rTEAS' == Userinfo.getOrganizationId() ){
            communityId = '0DBe00000008OiN';
        }

        HD_Settings_List__c cs1 = new HD_Settings_List__c(Name = 'HD Community ID', Value__c = communityId);
        insert cs1;

        Id recTypeMfFpId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();  
        Id recTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();

        Account acc1 = ObjectCreator.getNewAccount();
        acc1.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        insert acc1;

        Account acc2 = ObjectCreator.getNewAccount();
        acc2.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        acc2.Account_Type__c= 'MF';
        acc2.RecordTypeId = recTypeMfFpId;
        acc2.Permitted_Users_per_Account__c = 99;
        acc2.ParentId = acc1.Id;        
        insert acc2;

        System.debug(LoggingLevel.ERROR, '*** : ' + acc2.ParentId);
        
        Contact con  = ObjectCreator.getNewContact(acc2.Id, recTypeId);
        con.Program_Type__c='HDE';
        con.SET__c = false;
        con.Status__c = 'Active';
        con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
        insert con;

        Seminar_Type__c seminarType = new Seminar_Type__c(Name = 'test ' + String.valueOf(Math.random()) );
        seminarType.Active__c = true;
        seminarType.Program_Type__c = 'HDE';

        insert seminarType;

        User u;

        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];

        System.runAs ( thisUser ) {
            
            con.Email='trsconvert@t.hd';
            u = Batch_CreateUserFromContact.getUserFromContact(con);
            u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'HDC Teacher' LIMIT 1].Id;
            u.PortalRole = 'Executive';

            System.debug(LoggingLevel.ERROR, '*** u: ' + u);
            insert u;
        }

        Base_Course__c baseCourse = new Base_Course__c(Name = 'test ' + String.valueOf(Math.random()) );
        baseCourse.Status__c = 'Active';
        baseCourse.Program_Type__c = 'HDE';

        insert baseCourse;   

        Agreement__c agree  = ObjectCreator.getNewAgreement(acc2.Id); 
        agree.Program_Type__c = 'HDE';            
        insert agree;

        Teacher_Agreement__c tAgree = new Teacher_Agreement__c();
        tAgree.Teacher__c = con.Id;

        insert tAgree;
        
        Test.startTest();

            Batch_CreateUserFromContact2 b = new Batch_CreateUserFromContact2();
            b.mapContacts2process = new Map<Id, Contact>();
            b.mapContacts2process.put(con.Id, con);
            b.mapNewUser = new Map<Id,User>();
            b.mapNewUser.put(con.Id, u);
            b.mapError = new Map<Id, String>();
            Database.executeBatch(b,10);

        Test.stopTest();

        //System.assert([SELECT Id FROM Contact WHERE Id = :con.Id AND User_Creation_Status__c='User Created'].size() == 1);
        System.assert([SELECT Id FROM Teacher_Agreement__Share WHERE ParentId = :tAgree.Id AND UserOrGroupId = :u.id].size() > 0);  
        System.debug(LoggingLevel.ERROR,[SELECT Id, AccessLevel FROM Teacher_Agreement__Share WHERE ParentId = :tAgree.Id AND UserOrGroupId = :u.id]);
        
    }

    @isTest(seeAllData=false)
    static void Batch_CreateUserFromContact20_Test() {

        Id recTypeFranchiseeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();
        Id recTypeStaffId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Staff').getRecordTypeId();
        
        Account acc = ObjectCreator.getNewAccount();
        acc.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        insert acc;
        
        Contact con  = ObjectCreator.getNewContact(acc.Id, recTypeFranchiseeId);
        con.SET__c = false;
        con.Status__c = 'Active';
        con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
        insert con;

        User u = new User();
        
        Test.startTest();

            Batch_CreateUserFromContact2 b = new Batch_CreateUserFromContact2();
            b.mapContacts2process = new Map<Id, Contact>();
            b.mapContacts2process.put(con.Id, con);
            b.mapNewUser = new Map<Id,User>();
            b.mapNewUser.put(con.Id, u);
            b.mapError = new Map<Id, String>();
            b.mapError.put(con.Id, 'Test');

            b.errorLogs = new List<HD_Log__c>{new HD_Log__c(Process_Name__c = 'Batch_CreateUserFromContact2', Error_Description__c = 'Test', Status__c = 'Fail')};
            Database.executeBatch(b,10);

        Test.stopTest();

    }


    @isTest(seeAllData=false)
    static void Batch_CreateUserFromContact2b_Test() {
        //Prod
        String communityId = '0DBD0000000TO1V';
        //Dev
        if( '00De0000001O0rTEAS' == Userinfo.getOrganizationId() ){
            communityId = '0DBe00000008OiN';
        }

        HD_Settings_List__c cs1 = new HD_Settings_List__c(Name = 'HD Community ID', Value__c = communityId);
        insert cs1;

        Id recTypeLCSLSF = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId(); 
        Id recTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Staff').getRecordTypeId();

        Account acc1 = ObjectCreator.getNewAccount();
        acc1.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        insert acc1;

        Account acc2 = ObjectCreator.getNewAccount();
        acc2.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        acc2.Account_Type__c= 'MF';
        acc2.RecordTypeId = recTypeLCSLSF;
        acc2.Permitted_Users_per_Account__c = 99;
        acc2.ParentId = acc1.Id; 
        acc2.Partner_Account_User__c = null;       
        insert acc2;

        System.debug(LoggingLevel.ERROR, '*** : ' + acc2.ParentId);
        
        Contact con  = ObjectCreator.getNewContact(acc2.Id, recTypeId);
        con.SET__c = false;
        con.Status__c = 'Active';
        con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
        insert con;

        User u;
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            con.Account = acc2;
            con.Email='trsconvert@t.hd';
            u = Batch_CreateUserFromContact.getUserFromContact(con);
            u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'HDC Teacher' LIMIT 1].Id;
            u.PortalRole = 'Executive';
            
            System.debug(LoggingLevel.ERROR, '*** u: ' + u);
            insert u;
        }        

        Test.startTest();

            Batch_CreateUserFromContact2 b = new Batch_CreateUserFromContact2();
            b.mapContacts2process = new Map<Id, Contact>();
            b.mapContacts2process.put(con.Id, con);
            b.mapNewUser = new Map<Id,User>();
            b.mapNewUser.put(con.Id, u);
            b.mapError = new Map<Id, String>();
            Database.executeBatch(b,10);

        Test.stopTest();

        //System.assert([SELECT Id FROM Contact WHERE Id = :con.Id AND User_Creation_Status__c='User Created'].size() > 0);

    }


    @isTest(seeAllData=false)
    static void Batch_CreateUserFromContact2c_Test() {

            //Prod
        String communityId = '0DBD0000000TO1V';
        //Dev
        if( '00De0000001O0rTEAS' == Userinfo.getOrganizationId() ){
            communityId = '0DBe00000008OiN';
        }

        HD_Settings_List__c cs1 = new HD_Settings_List__c(Name = 'HD Community ID', Value__c = communityId);
        insert cs1;
        
        Id recTypeLCSLSF = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId(); 
        Id recTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Staff').getRecordTypeId(); 
        
        Account acc1 = ObjectCreator.getNewAccount();
        acc1.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        insert acc1;

        Account acc2 = ObjectCreator.getNewAccount();
        acc2.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        acc2.Account_Type__c= 'MF';
        acc2.RecordTypeId = recTypeLCSLSF;
        acc2.Permitted_Users_per_Account__c = 99;
        acc2.ParentId = acc1.Id; 
        acc2.Partner_Account_User__c = null;       
        insert acc2;

        System.debug(LoggingLevel.ERROR, '*** : ' + acc2.ParentId);
        
        Contact con  = ObjectCreator.getNewContact(acc2.Id, recTypeId);
        con.SET__c = false;
        con.Status__c = 'Active';
        con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com';
        con.MailingCountry = 'Argentina';
        insert con;

        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            List<User> us2up = new List<User>();
            for(User usr : [SELECT Id FROM User WHERE ContactId =:con.Id AND (IsActive = true OR IsPortalEnabled = true)]){
                usr.IsActive = false;
                usr.IsPortalEnabled = false; 
                us2up.add(usr);
                System.debug(LoggingLevel.ERROR, '*** : ' + us2up);
            }
            update us2up;
        }

        User u;
        System.runAs ( thisUser ) {
            con.Account = acc2;
            con.RecordTypeId = recTypeId;
            con.Email='trsconvert@t.hd';
            u = Batch_CreateUserFromContact.getUserFromContact(con);
            u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'HDC Teacher' LIMIT 1].Id;
            u.PortalRole = 'Worker';
            
            System.debug(LoggingLevel.ERROR, '*** u: ' + u);
            insert u;
        }        

        Test.startTest();

            Batch_CreateUserFromContact2 b = new Batch_CreateUserFromContact2();
            b.mapContacts2process = new Map<Id, Contact>();
            b.mapContacts2process.put(con.Id, con);
            b.mapNewUser = new Map<Id,User>();
            b.mapNewUser.put(con.Id, u);
            b.mapError = new Map<Id, String>();
            Database.executeBatch(b,10);

        Test.stopTest();

        //System.assert([SELECT Id FROM Contact WHERE Id = :con.Id AND User_Creation_Status__c='User Created'].size() == 1);

    }

    @isTest(seeAllData=false)
    static void Batch_CreateUserFromContact2d_Test() {

        //Prod
        String communityId = '0DBD0000000TO1V';
        //Dev
        if( '00De0000001O0rTEAS' == Userinfo.getOrganizationId() ){
            communityId = '0DBe00000008OiN';
        }

        HD_Settings_List__c cs1 = new HD_Settings_List__c(Name = 'HD Community ID', Value__c = communityId);
        insert cs1;
        
        Id recTypeMfFpId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId(); 
        Id recTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Staff').getRecordTypeId(); 
        
        Account acc1 = ObjectCreator.getNewAccount();
        acc1.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        insert acc1;

        Account acc2 = ObjectCreator.getNewAccount();
        acc2.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        acc2.Account_Type__c= 'MF';
        acc2.RecordTypeId = recTypeMfFpId;
        acc2.Permitted_Users_per_Account__c = 99;
        acc2.ParentId = acc1.Id; 
        acc2.Partner_Account_User__c = null;       
        insert acc2;

        System.debug(LoggingLevel.ERROR, '*** : ' + acc2.ParentId);
        
        Contact con  = ObjectCreator.getNewContact(acc2.Id, recTypeId);
        con.SET__c = false;
        con.Status__c = 'Active';
        con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com';
        con.MailingCountry = 'Argentina';
        insert con;

        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            List<User> us2up = new List<User>();
            for(User usr : [SELECT Id FROM User WHERE ContactId =:con.Id AND (IsActive = true OR IsPortalEnabled = true)]){
                usr.IsActive = false;
                usr.IsPortalEnabled = false; 
                us2up.add(usr);
                System.debug(LoggingLevel.ERROR, '*** : ' + us2up);
            }
            update us2up;
        }

        User u;
        System.runAs ( thisUser ) {
            con.Account = acc2;
            con.RecordTypeId = recTypeId;
            con.Email='trsconvert@t.hd';
            u = Batch_CreateUserFromContact.getUserFromContact(con);
            u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'HDC Teacher' LIMIT 1].Id;
            u.PortalRole = 'Worker';
            
            System.debug(LoggingLevel.ERROR, '*** u: ' + u);
            insert u;
        }        

        Test.startTest();

            Batch_CreateUserFromContact2 b = new Batch_CreateUserFromContact2();
            b.mapContacts2process = new Map<Id, Contact>();
            b.mapContacts2process.put(con.Id, con);
            b.mapNewUser = new Map<Id,User>();
            b.mapNewUser.put(con.Id, u);
            b.mapError = new Map<Id, String>();
            Database.executeBatch(b,10);

        Test.stopTest();

        //System.assert([SELECT Id FROM Contact WHERE Id = :con.Id AND User_Creation_Status__c='User Created'].size() == 1);

    }

        //SW-23968
    @isTest(seeAllData=false)
    static void Batch_CreateUserFromContact2e_Test() {

        //Prod
        String communityId = '0DBD0000000TO1V';
        //Dev
        if( '00De0000001O0rTEAS' == Userinfo.getOrganizationId() ){
            communityId = '0DBe00000008OiN';
        }

        HD_Settings_List__c cs1 = new HD_Settings_List__c(Name = 'HD Community ID', Value__c = communityId);
        insert cs1;

        Id recTypeLCSLSF = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId(); 
        Id recTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();

        Account acc1 = ObjectCreator.getNewAccount();
        acc1.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        acc1.Partner_Account_User__c = UserInfo.getUserId();
        insert acc1;

        Account acc2 = ObjectCreator.getNewAccount();
        acc2.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        acc2.Account_Type__c= 'MF';
        acc2.RecordTypeId = recTypeLCSLSF;
        acc2.Permitted_Users_per_Account__c = 99;
        acc2.ParentId = acc1.Id; 
        acc2.Partner_Account_User__c = null;       
        insert acc2;

        Seminar_Type__c stype = ObjectCreator.getNewSeminarType();
        stype.Program_Type__c = 'HDE'; 
        insert stype;
        
        Contact con  = ObjectCreator.getNewContact(acc2.Id, recTypeId);
        con.SET__c = false;
        con.Status__c = 'Active';
        con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
        con.Program_Type__c = 'HDE';
        insert con;

        Contact teacherContact1 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        teacherContact1.TT_Qualified__c = 'TT';             
        insert teacherContact1;

        User u;
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            con.Account = acc2;
            con.Email='trsconvert@t.hd';
            u = Batch_CreateUserFromContact.getUserFromContact(con);
            u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'HDC Teacher' LIMIT 1].Id;
            u.PortalRole = 'Executive';
            
            System.debug(LoggingLevel.ERROR, '*** u: ' + u);
            insert u;
        }        

        Test.startTest();

            Seminar__c seminar = new Seminar__c();      
            seminar.Status__c = 'Pending Evaluation';
            seminar.Seminar_Type__c = stype.Id;
            seminar.Hosting_Franchisee__c = acc1.Id;
            seminar.TTC_Seminar_Name__c = 'seminarName';
            insert seminar;

            Seminar__c seminar2 = new Seminar__c();      
            seminar2.Teacher_Trainer__c = teacherContact1.Id;
            seminar2.TT_Status__c = 'Approved by TT';
            seminar2.Status__c = 'Confirmed';
            seminar2.Seminar_Type__c = stype.Id;
            seminar2.TTC_Seminar_Name__c = 'seminarName';

            insert seminar2;

            Seminar_Teachers__c st = ObjectCreator.getNewSeminarTeacher(seminar.Id, con.Id);
            st.Teacher_Status_in_seminar__c = 'Registered';
            insert st;

            Batch_CreateUserFromContact2 b = new Batch_CreateUserFromContact2();
            b.mapContacts2process = new Map<Id, Contact>();
            b.mapContacts2process.put(con.Id, con);
            b.mapNewUser = new Map<Id,User>();
            b.mapNewUser.put(con.Id, u);
            b.mapError = new Map<Id, String>();
            Database.executeBatch(b,10);

        Test.stopTest();

        //System.assert([SELECT Id FROM Contact WHERE Id = :con.Id AND User_Creation_Status__c='User Created'].size() > 0);

    }



    @isTest(seeAllData=false)
    static void restoreContactOwners_Test(){
        Id recTypeStaffId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Staff').getRecordTypeId();
        Id recTypeLCSLSF = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId(); 
        
        Account acc1 = ObjectCreator.getNewAccount();
        acc1.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        insert acc1;

        Account acc2 = ObjectCreator.getNewAccount();
        acc2.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        acc2.Account_Type__c= 'MF';
        acc2.RecordTypeId = recTypeLCSLSF;
        acc2.Permitted_Users_per_Account__c = 99;
        acc2.ParentId = acc1.Id; 
        acc2.Partner_Account_User__c = null;       
        insert acc2;

        System.debug(LoggingLevel.ERROR, '*** : ' + acc2.ParentId);
        
        Contact con  = ObjectCreator.getNewContact(acc2.Id, recTypeStaffId);
        con.SET__c = false;
        con.Status__c = 'Active';
        con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
        insert con;

        Map<Id, Contact> mapContacts2process = new Map<Id, Contact>();
        mapContacts2process.put(con.Id, con);

        Map<Id, Map<Id,Id>> originalOwners = new Map<Id, Map<Id,Id>>();
        originalOwners.put(con.AccountId, new Map<Id,Id>());
        originalOwners.get(con.AccountId).put(con.Id, UserInfo.getUserId());

        Batch_CreateUserFromContact2.restoreContactOwners((List<SObject>) mapContacts2process.values(), originalOwners);
    }

    @isTest(seeAllData=false)
    static void Batch_CreateUserFromContact3_Test() {

        Id recTypeLCSLSF = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId(); 
        Id recTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Staff').getRecordTypeId(); 
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        
        Account acc1 = ObjectCreator.getNewAccount();
        acc1.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        System.runAs ( thisUser ) {
            insert acc1;
        }

        Account acc2 = ObjectCreator.getNewAccount();
        acc2.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        acc2.Account_Type__c= 'MF';
        acc2.RecordTypeId = recTypeLCSLSF;
        acc2.Permitted_Users_per_Account__c = 99;
        acc2.ParentId = acc1.Id; 
        acc2.Partner_Account_User__c = null; 

        System.runAs ( thisUser ) {
            insert acc2;
        }

        System.debug(LoggingLevel.ERROR, '*** : ' + acc2.ParentId);
        
        Contact con  = ObjectCreator.getNewContact(acc2.Id, recTypeId);
        con.SET__c = false;
        con.Status__c = 'Active';
        con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
        
        System.runAs ( thisUser ) {
            insert con;
        }
        
        User u = ObjectCreator.getNewUser(con.Id);
        
        System.runAs ( thisUser ) {
            insert u;  
        }

        /***/

        Group g = new Group();
        g.Name = 'All Teachers';
        insert g;

        GroupMember member = new GroupMember();
        member.GroupId = g.Id;
        member.UserOrGroupId = u.Id;

        Test.startTest();
        
            Batch_CreateUserFromContact3 b3 = new Batch_CreateUserFromContact3();
            b3.newMembers = new List<GroupMember>{member};
            b3.permissionSetAssigns.add(u.Id);
            b3.permissionTTAssigns.add(u.Id);
            Database.executeBatch(b3,10);

        Test.stopTest();
        

        //System.assert([SELECT Id FROM GroupMember WHERE UserOrGroupId = :u.Id AND GroupId = :g.Id].size() == 1);
    }

    //SW-24204 //HDC MF User
    @isTest(seeAllData=false)
    static void Batch_CreateUserFromContact2f_Test() {

        //Prod
        String communityId = '0DBD0000000TO1V';
        //Dev
        if( '00De0000001O0rTEAS' == Userinfo.getOrganizationId() ){
            communityId = '0DBe00000008OiN';
        }

        HD_Settings_List__c cs1 = new HD_Settings_List__c(Name = 'HD Community ID', Value__c = communityId);
        insert cs1;

        Id recTypeLCSLSF = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId(); 
        Id recTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();

        Account acc1 = ObjectCreator.getNewAccount();
        acc1.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        acc1.Partner_Account_User__c = UserInfo.getUserId();
        insert acc1;

        Account acc2 = ObjectCreator.getNewAccount();
        acc2.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        acc2.Account_Type__c= 'MF';
        acc2.RecordTypeId = recTypeLCSLSF;
        acc2.Permitted_Users_per_Account__c = 99;
        acc2.ParentId = acc1.Id; 
        acc2.Partner_Account_User__c = null;       
        insert acc2;

        Seminar_Type__c stype = ObjectCreator.getNewSeminarType();
        stype.Program_Type__c = 'HDE'; 
        insert stype;
        
        Contact con  = ObjectCreator.getNewContact(acc2.Id, recTypeId);
        con.SET__c = false;
        con.Status__c = 'Active';
        con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
        con.Program_Type__c = 'HDE';
        insert con;

        Contact teacherContact1 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        teacherContact1.TT_Qualified__c = 'TT';             
        insert teacherContact1;

        User u;
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            con.Account = acc2;
            con.Email='trsconvert@t.hd';
            u = Batch_CreateUserFromContact.getUserFromContact(con);
            u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'HDC MF User' LIMIT 1].Id;
            u.PortalRole = 'Executive';
            
            System.debug(LoggingLevel.ERROR, '*** u: ' + u);
            insert u;
        }        

        Test.startTest();

            Seminar__c seminar = new Seminar__c();      
            seminar.TTC_Seminar_Name__c = 'Seminar name';
            seminar.Status__c = 'Pending Evaluation';
            seminar.Seminar_Type__c = stype.Id;
            seminar.Hosting_Franchisee__c = acc2.Id;
            insert seminar;

            Seminar__c seminar2 = new Seminar__c();   
            seminar2.TTC_Seminar_Name__c = 'Seminar name';
   
            seminar2.Teacher_Trainer__c = teacherContact1.Id;
            seminar2.TT_Status__c = 'Approved by TT';
            seminar2.Status__c = 'Confirmed';
            seminar2.Seminar_Type__c = stype.Id;
            seminar2.Hosting_Franchisee__c = acc2.Id;
            insert seminar2;

            Seminar_Teachers__c st = ObjectCreator.getNewSeminarTeacher(seminar.Id, con.Id);
            st.Teacher_Status_in_seminar__c = 'Registered';
            insert st;

            Batch_CreateUserFromContact2 b = new Batch_CreateUserFromContact2();
            b.mapContacts2process = new Map<Id, Contact>();
            b.mapContacts2process.put(con.Id, con);
            b.mapNewUser = new Map<Id,User>();
            b.mapNewUser.put(con.Id, u);
            b.mapError = new Map<Id, String>();

            Database.executeBatch(b,10);

        Test.stopTest();

        //System.assert([SELECT Id FROM Contact WHERE Id = :con.Id AND User_Creation_Status__c='User Created'].size() > 0);

    }

    //SW-24204 //HDC LC User
    @isTest(seeAllData=false)
    static void Batch_CreateUserFromContact2g_Test() {

        //Prod
        String communityId = '0DBD0000000TO1V';
        //Dev
        if( '00De0000001O0rTEAS' == Userinfo.getOrganizationId() ){
            communityId = '0DBe00000008OiN';
        }

        HD_Settings_List__c cs1 = new HD_Settings_List__c(Name = 'HD Community ID', Value__c = communityId);
        insert cs1;

        Id recTypeLCSLSF = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId(); 
        Id recTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();

        Account acc1 = ObjectCreator.getNewAccount();
        acc1.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        acc1.Partner_Account_User__c = UserInfo.getUserId();
        insert acc1;

        Account acc2 = ObjectCreator.getNewAccount();
        acc2.Email__c = 'test_' + String.valueOf(Math.random()) + '@test.com';

        acc2.Account_Type__c= 'MF';
        acc2.RecordTypeId = recTypeLCSLSF;
        acc2.Permitted_Users_per_Account__c = 99;
        acc2.ParentId = acc1.Id; 
        acc2.Partner_Account_User__c = null;       
        insert acc2;

        Seminar_Type__c stype = ObjectCreator.getNewSeminarType();
        stype.Program_Type__c = 'HDE'; 
        insert stype;
        
        Contact con  = ObjectCreator.getNewContact(acc2.Id, recTypeId);
        con.SET__c = false;
        con.Status__c = 'Active';
        con.Email = 'test_' + String.valueOf(Math.random()) + '@test.com'; 
        con.Program_Type__c = 'HDE';
        con.Main_Franchise__c = acc2.Id;
        insert con;

        Contact teacherContact1 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        teacherContact1.TT_Qualified__c = 'TT';             
        insert teacherContact1;

        User u;
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            con.Account = acc2;
            con.Email='trsconvert@t.hd';
            u = Batch_CreateUserFromContact.getUserFromContact(con);
            u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'HDC LC User' LIMIT 1].Id;
            u.PortalRole = 'Executive';
            u.MF_ID__c = acc2.Id;

            System.debug(LoggingLevel.ERROR, '*** u: ' + u);
            insert u;
        }        

        Test.startTest();

            Seminar__c seminar = new Seminar__c();      
            seminar.Teacher_Trainer__c = teacherContact1.Id;
            seminar.TT_Status__c = 'Approved by TT';
            seminar.Status__c = 'Processing Application';
            seminar.Seminar_Type__c = stype.Id;
            seminar.Hosting_Franchisee__c = acc2.Id;
            seminar.TTC_Seminar_Name__c = 'Seminar name';

            insert seminar;

            Seminar__c seminar2 = new Seminar__c();      
            seminar2.Teacher_Trainer__c = teacherContact1.Id;
            seminar2.TT_Status__c = 'Approved by TT';
            seminar2.Status__c = 'Confirmed';
            seminar2.Seminar_Type__c = stype.Id;
            seminar2.Hosting_Franchisee__c = acc2.Id;
            seminar2.TTC_Seminar_Name__c = 'Seminar name';

            insert seminar2;


            Seminar_Teachers__c st = ObjectCreator.getNewSeminarTeacher(seminar.Id, con.Id);
            st.Teacher_Status_in_seminar__c = 'Registered';
            insert st;

            Batch_CreateUserFromContact2 b = new Batch_CreateUserFromContact2();
            b.mapContacts2process = new Map<Id, Contact>();
            b.mapContacts2process.put(con.Id, con);
            b.mapNewUser = new Map<Id,User>();
            b.mapNewUser.put(con.Id, u);
            b.mapError = new Map<Id, String>();

            Database.executeBatch(b,10);

        Test.stopTest();

        //System.assert([SELECT Id FROM Contact WHERE Id = :con.Id AND User_Creation_Status__c='User Created'].size() > 0);

    }

    
    
}