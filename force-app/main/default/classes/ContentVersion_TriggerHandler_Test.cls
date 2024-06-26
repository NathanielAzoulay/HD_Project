/******************************************************************************* 
Name              : ContentVersion_TriggerHandler_Test
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio Caputo            12/08/2016
*******************************************************************************/

@isTest
private class ContentVersion_TriggerHandler_Test {
    @isTest
    static void checkForDuplicateContentVersion() {
        ContentVersion_TriggerHandler.executeTriggerHandler();
    }


    /*@isTest(seeAllData=false) 
    static void checkForDuplicateContentVersion() {
        //Prod
        String communityId = '0DBD0000000TO1V';
        //Dev
        if( '00De0000001O0rTEAS' == Userinfo.getOrganizationId() ){
            communityId = '0DBe00000008OiN';
        }
        test.startTest();
        HD_Settings_List__c cs1 = new HD_Settings_List__c(Name = 'HD Community ID', Value__c = communityId);
        insert cs1;
        
        ContentWorkspace testWorkspace = [SELECT Id FROM ContentWorkspace LIMIT 1];
        
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test';
        cv.ContentUrl = 'test';
        cv.FirstPublishLocationId = testWorkspace.Id;
        cv.Content_Old_Id__c = 'test01';
        cv.HDC_File__c = false;
        insert cv;
        
        ContentVersion cv2 = new ContentVersion();
        cv2.Title = 'Test';
        cv2.ContentUrl = 'test';
        cv2.FirstPublishLocationId = testWorkspace.Id;
        cv2.Content_Old_Id__c = 'test01';
        try{
            insert cv2;
        }catch(Exception e){
        }
        test.stopTest();
        
    }
    @isTest(seeAllData=false) 
    static void contentFileToChatterGroup() {
        test.startTest();
        //Prod
        String communityId = '0DBD0000000TO1V';
        //Dev
        if( '00De0000001O0rTEAS' == Userinfo.getOrganizationId() ){
            communityId = '0DBe00000008OiN';
        }
        
        HD_Settings_List__c cs1 = new HD_Settings_List__c(Name = 'HD Community ID', Value__c = communityId);
        insert cs1;
        
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test';
        cv.ContentUrl = 'test';
        cv.HDC_File__c = false;
        insert cv;
        test.stopTest();
        
    }
    @isTest(seeAllData=false) 
    static void UpdateContentPermission_Test() {

        HD_TriggerSettings.disableTriggersFromTest = new Set<String>{'contentFileToChatterGroup'};
        ContentWorkspace testWorkspace = [SELECT Id FROM ContentWorkspace LIMIT 1];
        
        insert new HD_Settings_List__c(Name = 'HD Community ID', Value__c = '');
        
        ContentVersion testContentInsert = new ContentVersion();
        Test.startTest();
            testContentInsert.ContentURL='<a target="_blank" href="http://test.url/">http://test.url/</a>';
            testContentInsert.Title ='TEST CONTENT';
            testContentInsert.FirstPublishLocationId = testWorkspace.Id;
            //testContentInsert.Update_Content_Permission__c = false;
            insert testContentInsert;
        Test.stopTest();

        System.debug(LoggingLevel.ERROR, '*** : ' + [SELECT Title, Update_Content_Permission__c FROM ContentVersion WHERE Id = :testContentInsert.Id]);

        ContentVersion testContent = [SELECT ContentDocumentId, Update_Content_Permission__c FROM ContentVersion WHERE Id = :testContentInsert.Id];
        System.assert(testContent.Update_Content_Permission__c == true);
    }
    @isTest(seeAllData=false) 
    static void UpdateContentPermission2_Test() {

        HD_TriggerSettings.disableTriggersFromTest = new Set<String>{'contentFileToChatterGroup'};      
        
        insert new HD_Settings_List__c(Name = 'HD Community ID', Value__c = '');
        
        ContentVersion testContentInsert = new ContentVersion();
        Test.startTest();
            testContentInsert.ContentURL='<a target="_blank" href="http://test.url/">http://test.url/</a>';
            testContentInsert.Title ='TEST CONTENT';
            //testContentInsert.Update_Content_Permission__c = false;
            insert testContentInsert;
        Test.stopTest();

        ContentVersion testContent = [SELECT ContentDocumentId, Update_Content_Permission__c FROM ContentVersion WHERE Id = :testContentInsert.Id];
        ContentWorkspace testWorkspace = [SELECT Id FROM ContentWorkspace LIMIT 1];

        ContentWorkspaceDoc newWorkspaceDoc = new ContentWorkspaceDoc();
        newWorkspaceDoc.ContentWorkspaceId = testWorkspace.Id;
        newWorkspaceDoc.ContentDocumentId = testContent.ContentDocumentId;
        insert newWorkspaceDoc;

        //testContent.Update_Content_Permission__c = false;
        testContent.Country__c = 'Spain';
        update testContent;

        System.assert([SELECT Update_Content_Permission__c FROM ContentVersion WHERE Id = :testContent.Id].Update_Content_Permission__c == true);
    
    }
    
    @isTest(seeAllData=false)
    static void ContentVersionMethods_CanSee(){
        test.startTest();
            //Prod
            String communityId = '0DBD0000000TO1V';
            //Dev
            if( '00De0000001O0rTEAS' == Userinfo.getOrganizationId() ){
                communityId = '0DBe00000008OiN';
            }
            
            HD_Settings_List__c cs1 = new HD_Settings_List__c(Name = 'HD Community ID', Value__c = communityId);
            insert cs1;
            
            //ContentWorkspace testWorkspace = [SELECT Id FROM ContentWorkspace WHERE Name = 'Business' LIMIT 1];
        	ContentWorkspace testWorkspace = [SELECT Id FROM ContentWorkspace LIMIT 1];
            if (testWorkspace != null){
                ContentVersion cv = new ContentVersion();
                cv.Title = 'Test000000001';
                cv.ContentUrl = 'test';
                cv.FirstPublishLocationId = testWorkspace.Id;
                cv.NetworkId = communityId;
                cv.Content_Old_Id__c = 'Test000000001';
                cv.Entity_Type__c = 'MF';
                cv.Program_Type__c = 'HDE';
                cv.Specific_Program__c = 'HDE All';
                cv.Country__c = 'Italy';
                cv.Status__c = 'Active';
                insert cv;
                
                Account acc1 = ObjectCreator.getNewAccount();
                insert acc1;
                
                Contact con1 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId() );
                
                insert con1;
                con1.MailingCountry = 'Italy';
                con1.Specific_Program__c = 'HDE All';
                con1.Program_Type__c = 'HDE';
                con1.Entity_Type__c = 'MF';
                update con1;
                
                ContentVersion_Methods.canSee(con1, cv);
                
            	test.stopTest();
            }
    }

    @isTest(seeAllData=false)
    static void ContentVersionMethods_deleteCollaborationGroups(){
    	//Prod
        String communityId = '0DBD0000000TO1V';
        //Dev
        if( '00De0000001O0rTEAS' == Userinfo.getOrganizationId() ){
            communityId = '0DBe00000008OiN';
        }
        
        HD_Settings_List__c cs1 = new HD_Settings_List__c(Name = 'HD Community ID', Value__c = communityId);
        HD_Settings_List__c cs2 = new HD_Settings_List__c(Name = 'Content Libraries List', Value__c = 'Business,Pedagogic');
        insert new List<HD_Settings_List__c>{cs1, cs2};
        
        //ContentWorkspace testWorkspace = [SELECT Id FROM ContentWorkspace WHERE Name = 'Business' LIMIT 1];
        ContentWorkspace testWorkspace = [SELECT Id,Name FROM ContentWorkspace LIMIT 1];
        if (testWorkspace != null){
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Test000000002';
            cv.ContentUrl = 'test';
            cv.FirstPublishLocationId = testWorkspace.Id;
            cv.NetworkId = communityId;
            cv.Content_Old_Id__c = 'Test000000002';
            cv.Entity_Type__c = 'MF';
            cv.Program_Type__c = 'HDE';
            cv.Specific_Program__c = 'HDE All';
            cv.Country__c = 'Italy';
            cv.Status__c = 'Active';
            insert cv;
            
            try{//Avihai added try & catch 15/07/2018
            	ContentVersion_Methods.createNewChatterGroup(new List<ContentVersion>{cv});
            }
            catch(Exception ex){}
            cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1][0];
            ContentDocument cd = [SELECT Id FROM ContentDocument WHERE Id = :cv.ContentDocumentId LIMIT 1][0];
            
            ContentVersion_Methods.deleteCollaborationGroups( new List<ContentDocument>{cd} );
        }
        
        // cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1][0];
        
    	// ContentDocumentLink cdl = new ContentDocumentLink();
        // cdl.ContentDocumentId = cv.ContentDocumentId;
        // cdl.LinkedEntityId = cg2InsByIndex.get(i).Id;
        // cdl.ShareType = 'V';
      
    }
    
    @isTest(seeAllData=false) 
    static void ContentVersionMethods_createNewChatterGroup(){
        //Prod
        String communityId = '0DBD0000000TO1V';
        //Dev
        if( '00De0000001O0rTEAS' == Userinfo.getOrganizationId() ){
            communityId = '0DBe00000008OiN';
        }
        
        HD_Settings_List__c cs1 = new HD_Settings_List__c(Name = 'HD Community ID', Value__c = communityId);
        HD_Settings_List__c cs2 = new HD_Settings_List__c(Name = 'Content Libraries List', Value__c = 'Business,Pedagogic');
        insert new List<HD_Settings_List__c>{cs1, cs2};
        
        //ContentWorkspace testWorkspace = [SELECT Id FROM ContentWorkspace WHERE Name = 'Business' LIMIT 1];
        ContentWorkspace testWorkspace = [SELECT Id,Name FROM ContentWorkspace LIMIT 1];
        if (testWorkspace != null){
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Test000000002';
            cv.ContentUrl = 'test';
            cv.FirstPublishLocationId = testWorkspace.Id;
            cv.NetworkId = communityId;
            cv.Content_Old_Id__c = 'Test000000002';
            cv.Entity_Type__c = 'MF';
            cv.Program_Type__c = 'HDE';
            cv.Specific_Program__c = 'HDE All';
            cv.Country__c = 'Italy';
            cv.Status__c = 'Active';
            
            ContentVersion cv4 = new ContentVersion();
            cv4.Title = 'Test000000004';
            cv4.ContentUrl = 'test';
            cv4.Content_Old_Id__c = 'Test000000004';
            cv4.NetworkId = communityId;
            cv4.Entity_Type__c = 'MF';
            cv4.Program_Type__c = 'HDE';
            cv4.Specific_Program__c = 'HDE All';
            cv4.Country__c = 'Italy';
            cv4.Status__c = 'Active';
            cv4.HDC_File__c = false;
            
            insert new List<ContentVersion>{cv, cv4};
            
            Account acc1 = ObjectCreator.getNewAccount();
            insert acc1;
            
            Contact con1 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId() );
            
            insert con1;
            con1.MailingCountry = 'Italy';
            con1.Specific_Program__c = 'HDE All';
            con1.Program_Type__c = 'HDE';
            con1.Entity_Type__c = 'MF';
            update con1;
            
            test.startTest();
                try{
                    ContentVersion_Methods.createNewChatterGroup(new List<ContentVersion>{cv, cv4});
                }catch(Exception e){
                }
                
                //ContentVersion_Methods.createNewChatterGroup(new List<ContentVersion>{cv});//Avihai comment out this line and insert try & catch instead 15/07/2018
                try{//Avihai added try & catch 15/07/2018
                    ContentVersion_Methods.createNewChatterGroup(new List<ContentVersion>{cv});
                }catch(Exception ex){
                    Boolean containsError = ex.getMessage().contains('ContentDocumentLink requires a filter by a single Id') ? true : false;
                    System.assertEquals(true, containsError);
                    //ContentDocumentLink requires a filter by a single Id
                }
                
                ContentVersion_Methods.CFM_Result cfmr = new ContentVersion_Methods.CFM_Result( null, false, '');
                
                ContentVersion cv2 = new ContentVersion();
                cv2.Title = 'Test000000003';
                cv2.ContentUrl = 'test';
                cv2.FirstPublishLocationId = testWorkspace.Id;
                cv2.NetworkId = communityId;//Remove comment out on 11/07/2018
                cv2.HDC_File__c = true;
                cv2.Content_Old_Id__c = 'Test000000003';
                cv2.Entity_Type__c = 'MF';
                cv2.Program_Type__c = 'HDE';
                cv2.Specific_Program__c = 'HDE All';
                cv2.Country__c = 'Italy';
                cv2.Status__c = 'Active';
                try{
                    insert cv2;
                }catch(Exception e){
                }
            test.stopTest();
        }
    }
    
    @isTest(seeAllData=false) 
    static void cloneContentVersionToCommunity() {
        test.startTest();
        //Prod
        String communityId = '0DBD0000000TO1V';
        //Dev
        if( '00De0000001O0rTEAS' == Userinfo.getOrganizationId() ){
            communityId = '0DBe00000008OiN';
        }
        
        HD_Settings_List__c cs1 = new HD_Settings_List__c(Name = 'HD Community ID', Value__c = communityId);
        insert cs1;
        
        //ContentWorkspace testWorkspace = [SELECT Id FROM ContentWorkspace WHERE Name = 'Business' LIMIT 1];
        ContentWorkspace testWorkspace = [SELECT Id FROM ContentWorkspace LIMIT 1];
        if (testWorkspace != null){
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Test';
            cv.ContentUrl = 'test';
            cv.FirstPublishLocationId = testWorkspace.Id;
            cv.Content_Old_Id__c = 'test01';
            cv.HDC_File__c = false;
            insert cv;
            
            cv.Clone_Date__c = system.today();
            try{
            update cv;
            }catch(Exception ex){
                // Duplication under the same community 
            }
            
            Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = : cv.id].ContentDocumentId;
            delete new ContentDocument(id= conDocId);
            
            test.stopTest();
        }        
    }
    
    @isTest(seeAllData=false) 
    static void deleteChatterGroupOnNotActive_Test() {
        //Prod
        String communityId = '0DBD0000000TO1V';
        //Dev
        if( '00De0000001O0rTEAS' == Userinfo.getOrganizationId() ){
            communityId = '0DBe00000008OiN';
        }
        
        HD_Settings_List__c cs1 = new HD_Settings_List__c(Name = 'HD Community ID', Value__c = communityId);
        insert cs1;
        
        //ContentWorkspace testWorkspace = [SELECT Id FROM ContentWorkspace WHERE Name = 'Business' LIMIT 1];
        ContentWorkspace testWorkspace = [SELECT Id FROM ContentWorkspace LIMIT 1];
        if (testWorkspace != null){
            ContentVersion cv = new ContentVersion();
            Test.startTest();
                cv.Title = 'Test';
                cv.ContentUrl = 'test';
                //cv.FirstPublishLocationId = testWorkspace.Id;
                cv.Content_Old_Id__c = 'test01';
                cv.HDC_File__c = false;
                cv.Status__c= 'Active';
                cv.NetworkId = ContentVersion_Methods.hdCommunityId;
                insert cv;
            Test.stopTest();
    
    
            cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
    
            ContentWorkspaceDoc newWorkspaceDoc = new ContentWorkspaceDoc(); 
    
            newWorkspaceDoc.ContentWorkspaceId = testWorkspace.Id; 
            newWorkspaceDoc.ContentDocumentId = cv.ContentDocumentId; 
    
            insert newWorkspaceDoc;
            
            cv.Status__c = 'Not Active';
            update cv;
        }                
    }*/

}