@isTest 
private class Batch_CFM_Membership_Test {
    @isTest(seeAllData=false)
    static void Batch_CFM_Membership_Test() {
        HD_TriggerSettings.disableTriggersFromTest = new Set<String>();
        HD_TriggerSettings.disableTriggersFromTest.add('findLeadOwnerByCampaign');
        
        Account acc1 = ObjectCreator.getNewAccount();
        insert acc1;
        
        Contact con1 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId() );
        insert con1;
        
        con1.MailingCountry = 'Italy';
        con1.Specific_Program__c = 'HDE All';
        con1.Program_Type__c = 'HDE';
        con1.Entity_Type__c = 'MF';
        update con1;
        
        HD_Settings_List__c cs1 = new HD_Settings_List__c( Name = 'HD Community ID', Value__c = '' );
        HD_Settings_List__c cs2 = new HD_Settings_List__c( Name = 'Content Libraries List', Value__c = 'Business' );
        insert new List<HD_Settings_List__c>{cs1, cs2};
        
        //ContentWorkspace cw1 = [SELECT Id FROM ContentWorkspace WHERE Name = 'Business'  LIMIT 1][0];//Comment out by Avihai 11/07/2018
        ContentWorkspace cw1 = [SELECT Id FROM ContentWorkspace LIMIT 1][0];//Added by Avihai 11/07/2018
        ContentVersion cv1 = new ContentVersion();
        cv1.Title = 'NewTestCV1';
        cv1.ContentUrl = 'test';
        insert cv1;
        
        cv1 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv1.Id LIMIT 1][0];
        
        ContentWorkspaceDoc newWorkspaceDoc = new ContentWorkspaceDoc(); 
        newWorkspaceDoc.ContentWorkspaceId = cw1.Id; 
        newWorkspaceDoc.ContentDocumentId = cv1.ContentDocumentId; 
        insert newWorkspaceDoc;
        
        cv1.Status__c = 'Active';
        
        cv1.Entity_Type__c = 'MF';
        cv1.Program_Type__c = 'HDE';
        cv1.Specific_Program__c = 'HDE All';
        cv1.Country__c = 'Italy';
        cv1.Update_Content_Permission__c = true;
        update cv1;
        
        //CollaborationGroup cg = [SELECT Id FROM CollaborationGroup WHERE Name = :cv1.ContentDocumentId LIMIT 1][0]; //comment out by Avihai 11/07/2018
        CollaborationGroupMember cgm1;
        try{
        	CollaborationGroup cg = [SELECT Id FROM CollaborationGroup LIMIT 1][0]; //added by Avihai 11/07/2018
        	cgm1 = [SELECT Id FROM CollaborationGroupMember WHERE MemberId = :userinfo.getUserId() LIMIT 1][0];
        }
        catch(Exception ex){}
        
        test.startTest();
        
        Batch_CFM_Membership b = new Batch_CFM_Membership();
        if (cgm1 != null)
        	b.restrictCGMIds.add(cgm1.Id);
        b.restrictCVIds.add( cv1.Id );
        b.recLimit = 1;
        database.executeBatch(b);
        
        b.ContinueNextExecution( true );
        b.step = 0;
        b.ContinueNextExecution( false );
        b.step = 1;
        b.ContinueNextExecution( false );
        
        test.stopTest();
        
    }
    
    @isTest(seeAllData=false)
    static void Batch_CFM_Membership_Test02() {
        HD_TriggerSettings.disableTriggersFromTest = new Set<String>();
        HD_TriggerSettings.disableTriggersFromTest.add('findLeadOwnerByCampaign');
        
        Account acc1 = ObjectCreator.getNewAccount();
        insert acc1;
        
        Contact con1 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId() );
        
        insert con1;
        con1.MailingCountry = 'Italy';
        con1.Specific_Program__c = 'HDE All';
        con1.Program_Type__c = 'HDE';
        con1.Entity_Type__c = 'MF';
        con1.Update_Contact_Permission__c = true;
        update con1;
        
        HD_Settings_List__c cs1 = new HD_Settings_List__c( Name = 'HD Community ID', Value__c = '' );
        HD_Settings_List__c cs2 = new HD_Settings_List__c( Name = 'Content Libraries List', Value__c = 'Business' );
        insert new List<HD_Settings_List__c>{cs1, cs2};
        
        //ContentWorkspace cw1 = [SELECT Id FROM ContentWorkspace WHERE Name = 'Business'  LIMIT 1][0];//Comment out by Avihai 11/07/2018
        ContentWorkspace cw1 = [SELECT Id FROM ContentWorkspace LIMIT 1][0];//Added by Avihai 11/07/2018
        
        ContentVersion cv1 = new ContentVersion();
        cv1.Title = 'NewTestCV1';
        cv1.ContentUrl = 'test';
        cv1.FirstPublishLocationId = cw1.Id;
        cv1.Status__c = 'Active';
        
        cv1.Entity_Type__c = 'MF';
        cv1.Program_Type__c = 'HDE';
        cv1.Specific_Program__c = 'HDE All';
        cv1.Country__c = 'Italy';
        cv1.Update_Content_Permission__c = true;
        insert cv1;
        
        cv1 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv1.Id LIMIT 1][0];
        
        //CollaborationGroup cg = [SELECT Id FROM CollaborationGroup WHERE Name = :cv1.ContentDocumentId LIMIT 1][0];//comment out by Avihai 11/07/2018
        try{
        	CollaborationGroup cg = [SELECT Id FROM CollaborationGroup LIMIT 1];//added by Avihai 11/07/2018
        	CollaborationGroupMember cgm1 = [SELECT Id FROM CollaborationGroupMember WHERE MemberId = :userinfo.getUserId() LIMIT 1][0];
        
            test.startTest();
            
            Batch_CFM_Membership b = new Batch_CFM_Membership();
            //b.restrictCGMIds.add(cgm1.Id);
            //b.restrictCVIds.add( cv1.Id );
            b.recLimit = 1;
            b.running4CV = false;
            b.query += ' MemberId = \''+userinfo.getUserId()+'\' OR ';
            database.executeBatch(b);
            
            test.stopTest();
        }
        catch(Exception ex){}
    }
    
    @isTest(seeAllData=false)
    static void Sched_CFM_Membership_Test() { 
        HD_TriggerSettings.disableTriggersFromTest = new Set<String>();
        HD_TriggerSettings.disableTriggersFromTest.add('findLeadOwnerByCampaign');
        
        HD_Settings_List__c cs1 = new HD_Settings_List__c( Name = 'CFM Batch Iteration Limit', Value__c = '1' );
        HD_Settings_List__c cs2 = new HD_Settings_List__c( Name = 'CFM Batch Record Limit', Value__c = '1' );
        insert new List<HD_Settings_List__c>{cs1, cs2};
		
        try{
            Test.startTest();
            System.schedule('Sched_CFM_Membership', '0 0 * * * ?', new Sched_CFM_Membership());
            Test.stopTest();
        }catch(Exception e){        
        }
    }
    
}