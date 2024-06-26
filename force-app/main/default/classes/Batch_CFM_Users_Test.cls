@isTest 
private class Batch_CFM_Users_Test {
    @isTest(seeAllData=false)
    static void Batch_CFM_Users_Test() {
        //Prod
        String communityId = '0DBD0000000TO1V';
        //Dev
        if( '00De0000001O0rTEAS' == Userinfo.getOrganizationId() ){
            //communityId = '0DBe00000008OiN';
        }
        
        HD_TriggerSettings.disableTriggersFromTest = new Set<String>();
        HD_TriggerSettings.disableTriggersFromTest.add('findLeadOwnerByCampaign');
        
        Id partnerCommunityProfile = [SELECT Id FROM Profile WHERE Name='HDC MF Logistic'].Id;
        
        Account acc1 = ObjectCreator.getNewAccount();
        insert acc1;
        
        Contact con1 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId() );
        Contact con2 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId() );
        insert new List<Contact>{con1, con2};
        
        con1.MailingCountry = 'Italy';
        con1.Specific_Program__c = 'HDE All';
        con1.Program_Type__c = 'HDE';
        con1.Entity_Type__c = 'MF';
        con1.Update_Contact_Permission__c = true;
        
        con2.MailingCountry = 'Italy';
        con2.Specific_Program__c = 'HDE All';
        con2.Program_Type__c = 'HDE';
        con2.Entity_Type__c = 'MF';
        con2.Update_Contact_Permission__c = true;
        
        update new List<Contact>{con1, con2};
        
        User user = new User(alias = 'CFMUser', email='CFMUserTest@noemail.com',
                emailencodingkey='UTF-8', lastname='CFMUserTest', languagelocalekey='en_US',
                localesidkey='en_US', profileid = partnerCommunityProfile, country='United States',IsActive =true,
                ContactId = con1.Id,
                timezonesidkey='America/Los_Angeles', username='CFMUserTest@noemail.com');
		
        insert user;
        
        HD_Settings_List__c cs1 = new HD_Settings_List__c( Name = 'HD Community ID', Value__c = communityId );
        HD_Settings_List__c cs2 = new HD_Settings_List__c( Name = 'Content Libraries List', Value__c = 'Business' );
        insert new List<HD_Settings_List__c>{cs1, cs2};
        
        //ContentWorkspace cw1 = [SELECT Id FROM ContentWorkspace WHERE Name = 'Business'  LIMIT 1][0];
        ContentWorkspace cw1 = [SELECT Id FROM ContentWorkspace LIMIT 1][0];
        ContentVersion cv1 = new ContentVersion();
        cv1.Title = 'Test000000001';
        cv1.ContentUrl = 'test';
        cv1.FirstPublishLocationId = cw1.Id;
        cv1.NetworkId = communityId;
        cv1.Content_Old_Id__c = 'Test000000001';
        cv1.Entity_Type__c = 'MF';
        cv1.Program_Type__c = 'HDE';
        cv1.Specific_Program__c = 'HDE All';
        cv1.Country__c = 'Italy';
        cv1.Status__c = 'Active';
        cv1.Update_Content_Permission__c = true;
        
        ContentVersion cv2 = new ContentVersion();
        cv2.Title = 'Test000000002';
        cv2.ContentUrl = 'test';
        cv2.FirstPublishLocationId = cw1.Id;
        cv2.NetworkId = communityId;
        cv2.Content_Old_Id__c = 'Test000000002';
        cv2.Entity_Type__c = '';
        cv2.Program_Type__c = '';
        cv2.Specific_Program__c = '';
        cv2.Country__c = '';
        cv2.Status__c = 'Active';
        cv2.Update_Content_Permission__c = true;
        
        //system.runAs(user) {
        	
        insert new List<ContentVersion>{cv1, cv2};
        
        //}
        List<NetworkMember> nmL = new List<NetworkMember>();
        for( NetworkMember nm : [SELECT Id FROM NetworkMember WHERE MemberId = :Userinfo.getUserId() ]){
        	nm.PreferencesDisableAllFeedsEmail = false;
        	nmL.add(nm);
        }
        update nmL;
        
        test.startTest();
        
        Batch_CFM_Users b = new Batch_CFM_Users();
        b.restrictConIds.add(con1.Id);
        b.restrictConIds.add(con2.Id);
        b.restrictCVIds.add( cv1.Id );
        b.restrictCVIds.add( cv2.Id );
        b.recLimit = 1;
        //database.executeBatch(b);
        Batch_CFM_Users.RunBatch(b, 1000);
        
        test.stopTest();
    }
    
    @isTest(seeAllData=false)
    static void Batch_CFM_Users_Test02() {
        //Prod
        String communityId = '0DBD0000000TO1V';
        //Dev
        if( '00De0000001O0rTEAS' == Userinfo.getOrganizationId() ){
            communityId = '0DBe00000008OiN';
        }
        
        HD_TriggerSettings.disableTriggersFromTest = new Set<String>();
        HD_TriggerSettings.disableTriggersFromTest.add('findLeadOwnerByCampaign');
        
        Id partnerCommunityProfile = [SELECT Id FROM Profile WHERE Name='HDC MF Logistic'].Id;
        
        Account acc1 = ObjectCreator.getNewAccount();
        insert acc1;
        
        Contact con1 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId() );
        Contact con2 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId() );
        insert new List<Contact>{con1, con2};
        
        con1.MailingCountry = 'Italy';
        con1.Specific_Program__c = 'HDE All';
        con1.Program_Type__c = 'HDE';
        con1.Entity_Type__c = 'MF';
        con1.Update_Contact_Permission__c = true;
        
        con2.MailingCountry = 'Italy';
        con2.Specific_Program__c = 'HDE All';
        con2.Program_Type__c = 'HDE';
        con2.Entity_Type__c = 'MF';
        con2.Update_Contact_Permission__c = true;
        
        update new List<Contact>{con1, con2};
        
        User user = new User(alias = 'CFMUser', email='CFMUserTest@noemail.com',
                emailencodingkey='UTF-8', lastname='CFMUserTest', languagelocalekey='en_US',
                localesidkey='en_US', profileid = partnerCommunityProfile, country='United States',IsActive =true,
                ContactId = con1.Id,
                timezonesidkey='America/Los_Angeles', username='CFMUserTest@noemail.com');
		
        insert user;
        
        HD_Settings_List__c cs1 = new HD_Settings_List__c( Name = 'HD Community ID', Value__c = communityId );
        //HD_Settings_List__c cs2 = new HD_Settings_List__c( Name = 'Content Libraries List', Value__c = 'Business,' );
        HD_Settings_List__c cs2 = new HD_Settings_List__c( Name = 'Content Libraries List', Value__c = 'Business' );
        insert new List<HD_Settings_List__c>{cs1, cs2};
        
        //ContentWorkspace cw1 = [SELECT Id FROM ContentWorkspace WHERE Name = 'Business'  LIMIT 1][0];//Comment out by Avihai 16/07/2018
        ContentWorkspace cw1 = [SELECT Id FROM ContentWorkspace LIMIT 1][0];

        ContentVersion cv1 = new ContentVersion();
        cv1.Title = 'Test000000001';
        cv1.ContentUrl = 'test';
        //cv1.FirstPublishLocationId = cw1.Id;
        cv1.NetworkId = communityId;
        cv1.Content_Old_Id__c = 'Test000000001';
        cv1.Entity_Type__c = 'MF';
        cv1.Program_Type__c = 'HDE';
        cv1.Specific_Program__c = 'HDE All';
        cv1.Country__c = 'Italy';
        cv1.Status__c = 'Active';
        cv1.Update_Content_Permission__c = true;
        
        ContentVersion cv2 = new ContentVersion();
        cv2.Title = 'Test000000002';
        cv2.ContentUrl = 'test';
        //cv2.FirstPublishLocationId = cw1.Id;
        cv2.NetworkId = communityId;
        cv2.Content_Old_Id__c = 'Test000000002';
        cv2.Entity_Type__c = 'MF';
        cv2.Program_Type__c = 'HDE';
        cv2.Specific_Program__c = 'HDE All';
        cv2.Country__c = 'Italy';
        cv2.Status__c = 'Active';
        cv2.Update_Content_Permission__c = true;
        //system.runAs(user){
        	insert new List<ContentVersion>{cv1, cv2};
        //}
        cv2 = [SELECT Id, ContentDocumentId, Description FROM ContentVersion WHERE Id = :cv2.Id LIMIT 1][0];
        // cg2 = [SELECT Id FROM CollaborationGroup WHERE Name = :cv2.ContentDocumentId LIMIT 1][0];
        //Added by Avihai 16/07/2018 WHERE Name = :cv2.Description
        CollaborationGroup cg2 = new CollaborationGroup();
        cg2.Description = 'test';
        cg2.Name = 'Business';
        cg2.CollaborationType = 'Public';
        insert cg2;
 		
        test.startTest();
        /*
        CollaborationGroupMember cgm = new CollaborationGroupMember();
        cgm.CollaborationGroupId = cg2.Id;
	    cgm.MemberId = user.Id;
        insert cgm;
       */
        
        Batch_CFM_Users b = new Batch_CFM_Users();
        b.restrictConIds.add(con1.Id);
        b.restrictConIds.add(con2.Id);
        b.restrictCVIds.add( cv1.Id );
        b.restrictCVIds.add( cv2.Id );
        b.recLimit = 10;
        //database.executeBatch(b);
        Batch_CFM_Users.RunBatch(b, 1000);
        
        //Covering the Error capturing method
        Savepoint sp = Database.setSavepoint();
        List<HD_Log__c> hdLogs2Ins = new List<HD_Log__c>();
        b.conMap.put(con1.Id, con1);
        b.conMap.put(con2.Id, con2);
        try{
        	Integer i=1/0;
        }catch( Exception e){
        	b.CatchException( e, sp, hdLogs2Ins );
        }
        test.stopTest();
    }
    
    @isTest(seeAllData=false)
    static void Sched_CFM_Users_Test() {
        Test.startTest();
        System.schedule('Sched_CFM_Users 12345', '0 0 * * * ?', new Sched_CFM_Users());
        Test.stopTest();
    }
}