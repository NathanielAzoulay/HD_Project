@isTest 
private class Batch_CFM_Contacts_Test {
    @isTest(seeAllData=false)
    static void Batch_CFM_Contacts_Test() {
    	//Testing creation of Membership
    	//Prod
        String communityId = '0DBD0000000TO1V';
        //Dev
        if( '00De0000001O0rTEAS' == Userinfo.getOrganizationId() ){
            communityId = '0DBe00000008OiN';
        }
        
        HD_TriggerSettings.disableTriggersFromTest = new Set<String>();
        HD_TriggerSettings.disableTriggersFromTest.add('findLeadOwnerByCampaign');
        
        Id partnerCommunityProfile = [SELECT Id FROM Profile WHERE Name='Partner Community User'].Id;
        
        Account acc1 = ObjectCreator.getNewAccount();
        insert acc1;
        
        Contact con1 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId() );
        Contact con2 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId() );
        insert new List<Contact>{con1, con2};
        
        con1.MailingCountry = 'Italy';
        con1.Specific_Program__c = 'HDE All';
        con1.Program_Type__c = 'HDE';
        con1.Entity_Type__c = 'MF';
        
        con2.MailingCountry = 'Italy';
        con2.Specific_Program__c = 'HDE All';
        con2.Program_Type__c = 'HDE';
        con2.Entity_Type__c = 'MF';
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
        
        //ContentWorkspace cw1 = [SELECT Id FROM ContentWorkspace WHERE Name = 'Business' LIMIT 1][0];
        ContentWorkspace cw1 = [SELECT Id FROM ContentWorkspace LIMIT 1][0];
        //Avihai 10/07/2018 add condition if cw1 is not null
        if (cw1 != null){
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
            cv2.HDC_File__c = false;
                
            insert new List<ContentVersion>{cv1, cv2};
            
            test.startTest();
            
            Batch_CFM_Contacts b = new Batch_CFM_Contacts();
            b.restrictConIds.add(con1.Id);
            b.restrictConIds.add(con2.Id);
            b.restrictCVIds.add( cv1.Id );
            b.restrictCVIds.add( cv2.Id );
            b.errorRecords.add(null);
            b.procRecords.add(null);
            b.recLimit = 10;
            //database.executeBatch(b);
            Batch_CFM_Contacts.RunBatch(b, 1000);
            
            //Covering the Error capturing method
            Savepoint sp = Database.setSavepoint();
            Map<Id, HD_Log__c> hdLogs2Ins = new Map<Id, HD_Log__c>();
            b.cvMap.put(cv1.Id, cv1);
            b.cvMap.put(cv2.Id, cv2);
            try{
                Integer i=1/0;
            }catch( Exception e){
                b.CatchException( e, sp, hdLogs2Ins );
            }
            test.stopTest();
        }
    }
    
    @isTest(seeAllData=false)
    static void Batch_CFM_Contacts_Test02() {
    	//Testing Partner User logic
    	
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
        
        con2.MailingCountry = 'Italy';
        con2.Specific_Program__c = 'HDE All';
        con2.Program_Type__c = 'HDE';
        con2.Entity_Type__c = 'MF';
        update new List<Contact>{con1, con2};
        
        User user = new User(alias = 'CFMUser', email='CFMUserTest@noemail.com',
                emailencodingkey='UTF-8', lastname='CFMUserTest', languagelocalekey='en_US',
                localesidkey='en_US', profileid = partnerCommunityProfile, country='United States',IsActive =true,
                ContactId = con1.Id,
                timezonesidkey='America/Los_Angeles', username='CFMUserTest@noemail.com');
		
        insert user;
        
        HD_Settings_List__c cs1 = new HD_Settings_List__c( Name = 'HD Community ID', Value__c = communityId );
        HD_Settings_List__c cs2 = new HD_Settings_List__c( Name = 'Content Libraries List', Value__c = 'Business' );//11/07/2018 Avihai remove comma after Business,(comma)
        HD_Settings_List__c cs3 = new HD_Settings_List__c( Name = 'HDC User Guide', Value__c = 'Business,Pedagogic,Seminars/Workshops' );//11/07/2018 Avihai added after Business,(comma) : Pedagogic,Seminars/Workshops
        insert new List<HD_Settings_List__c>{cs1, cs2, cs3};//Add cs3
        //Commetn out Avihai
        //ContentWorkspace cw1 = [SELECT Id FROM ContentWorkspace WHERE Name = 'Business'  LIMIT 1][0];
        ContentWorkspace cw1 = [SELECT Id FROM ContentWorkspace LIMIT 1][0];
        //Avihai 10/07/2018 add condition if cw1 is not null
        if (cw1 != null){
            
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
            
            ContentVersion cv2 = new ContentVersion();
            cv2.Title = 'Test000000002';
            cv2.ContentUrl = 'test';
            //cv2.ContentDocumentId = cw1.Id;//Comment out by Avihai
            //cv2.FirstPublishLocationId = cw1.Id;
            cv2.NetworkId = communityId;
            cv2.Content_Old_Id__c = 'Test000000002';
            cv2.Entity_Type__c = 'MF';
            cv2.Program_Type__c = 'HDE';
            cv2.Specific_Program__c = 'HDE All';
            cv2.Country__c = 'Italy';
            cv2.Status__c = 'Active';
            
            //system.runAs(user){
                insert new List<ContentVersion>{cv1, cv2};
            //}
            
            cv2 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv2.Id LIMIT 1][0];
            Batch_CreateUserFromContact2 bUfC2 = new Batch_CreateUserFromContact2();
            Test.startTest();
			//Added by Avihai 11/07/2018 
            bUfC2.mapContacts2process = new Map<Id, Contact>();
            bUfC2.mapContacts2process.put(con1.Id, con1);
            bUfC2.mapNewUser = new Map<Id,User>();
            bUfC2.mapNewUser.put(con1.Id, user);
            bUfC2.mapError = new Map<Id, String>();
            Database.executeBatch(bUfC2,1);

       		Test.stopTest();
            
            if (!Test.isRunningTest()){
                //CollaborationGroup cg2 = [SELECT Id FROM CollaborationGroup WHERE Name = :cv2.ContentDocumentId LIMIT 1][0];//Comment out by Avihai
                CollaborationGroup cg2 = [SELECT Id FROM CollaborationGroup LIMIT 1][0];
                if (cg2 != null){
                    CollaborationGroupMember cgm = new CollaborationGroupMember();
                    cgm.CollaborationGroupId = cg2.Id;
                    cgm.MemberId = user.Id;
                    insert cgm;
                    
                    test.startTest();
                    
                    Batch_CFM_Contacts b = new Batch_CFM_Contacts();
                    b.restrictConIds.add(con1.Id);
                    b.restrictConIds.add(con2.Id);
                    b.restrictCVIds.add( cv1.Id );
                    b.restrictCVIds.add( cv2.Id );
                    b.errorRecords.add(null);
                    b.procRecords.add(null);
                    b.recLimit = 10;
                    //database.executeBatch(b);
                    Batch_CFM_Contacts.RunBatch(b, 1000);
                    
                    test.stopTest();
                }
            }            
        }
    }
    
    @isTest(seeAllData=false)
    static void Batch_CFM_Contacts_Test03() {
    	//Testing Recursivity of Batch
    	
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
        
        con2.MailingCountry = 'Italy';
        con2.Specific_Program__c = 'HDE All';
        con2.Program_Type__c = 'HDE';
        con2.Entity_Type__c = 'MF';
        update new List<Contact>{con1, con2};
        
        User user = new User(alias = 'CFMUser', email='CFMUserTest@noemail.com',
                emailencodingkey='UTF-8', lastname='CFMUserTest', languagelocalekey='en_US',
                localesidkey='en_US', profileid = partnerCommunityProfile, country='United States',IsActive =true,
                ContactId = con1.Id,
                timezonesidkey='America/Los_Angeles', username='CFMUserTest@noemail.com');
		
        insert user;
        
        HD_Settings_List__c cs1 = new HD_Settings_List__c( Name = 'HD Community ID', Value__c = communityId );
        HD_Settings_List__c cs2 = new HD_Settings_List__c( Name = 'Content Libraries List', Value__c = 'Business,' );
        insert new List<HD_Settings_List__c>{cs1, cs2};
        
        //ContentWorkspace cw1 = [SELECT Id FROM ContentWorkspace WHERE Name = 'Business'  LIMIT 1][0];
        ContentWorkspace cw1 = [SELECT Id FROM ContentWorkspace LIMIT 1][0];
        //Avihai 10/07/2018 add condition if cw1 is not null
        if (cw1 != null){
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
            
            //system.runAs(user){
                insert new List<ContentVersion>{cv1, cv2};
            //}
            
                    			//Added by Avihai 15/07/2018 
           	Group g = new Group();
            g.Name = 'All Teachers';
            insert g;

            GroupMember member = new GroupMember();
            member.GroupId = g.Id;
            member.UserOrGroupId = user.Id;
                    
            cv2 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv2.Id LIMIT 1][0];
            
            Batch_CreateUserFromContact3 bUfC3 = new Batch_CreateUserFromContact3();
            Test.startTest();
			//Added by Avihai 11/07/2018            	

            Batch_CreateUserFromContact3 b3 = new Batch_CreateUserFromContact3();
            b3.newMembers = new List<GroupMember>{member};
            b3.permissionSetAssigns.add(user.Id);
            b3.permissionTTAssigns.add(user.Id);
            Database.executeBatch(b3,1);
       		Test.stopTest();
            
            if (!Test.isRunningTest()){
                CollaborationGroup cg2 = [SELECT Id FROM CollaborationGroup WHERE Name = :cv2.ContentDocumentId LIMIT 1][0];
                
                CollaborationGroupMember cgm = new CollaborationGroupMember();
                cgm.CollaborationGroupId = cg2.Id;
                cgm.MemberId = user.Id;
                insert cgm;
                
                test.startTest();
                
                Batch_CFM_Contacts b = new Batch_CFM_Contacts();
                b.restrictConIds.add(con1.Id);
                b.restrictConIds.add(con2.Id);
                b.restrictCVIds.add( cv1.Id );
                b.restrictCVIds.add( cv2.Id );
                b.errorRecords.add(null);
                b.procRecords.add(null);
                b.recLimit = 1;
                //database.executeBatch(b);
                Batch_CFM_Contacts.RunBatch(b, 1000);
                
                test.stopTest();
            }
        }
    }
    
    @isTest(seeAllData=false)
    static void Sched_CFM_Contacts_Test() {
        System.schedule('Sched_RecentSharingRulesOnContact 123', '0 0 * * * ?', new Sched_CFM_Contacts());
    }
}