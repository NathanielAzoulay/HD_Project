/******************************************************************************* 
Name              : HD_SharingMethods
Description       : Handler the sharing methods on HD environment, scheduled in Sched_SharingRulesOnLastSubFranchisee
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan Sinclair          05/11/2016              
*******************************************************************************/
public without sharing class HD_SharingMethods {
    
    public static void Document_CreateSharingRules( Set<Id> docIds ){
        Map<String, List<Document__c>> docByApp = new Map<String, List<Document__c>>();
        Map<String, String> objNameByPrefix = new Map<String, String>();
        Map<String, String> objShareByObjName = new Map<String, String>();
        
        Map<String, Schema.SObjectType> gd =  Schema.getGlobalDescribe(); 
        
        for( Document__c doc : [SELECT Id, Application__c FROM Document__c WHERE Id IN :docIds ] ){
            if( String.isNotBlank(doc.Application__c) ){
                String appId = doc.Application__c.substring(0,15);
                if( !docByApp.containsKey( appId ) ){
                    docByApp.put( appId, new List<Document__c>() );
                }
                docByApp.get( appId ).add( doc );
                
                if( !objNameByPrefix.containsKey( appId.substring(0,3) ) ){
                    String objName = GlobalHelperMethods.findObjectNameFromRecordIdPrefix( appId.substring(0,3) ).toLowerCase();
                    
                    objNameByPrefix.put( appId.substring(0,3), objName );
                    
                    if( gd.containsKey( objName + 'Share' ) ){
                        objShareByObjName.put( objName, objName + 'Share' );
                    }else if( objName.contains('__c') && gd.containsKey( objName.replace('__c','__Share') ) ){
                        objShareByObjName.put( objName, objName.replace('__c','__Share') );
                    }
                }
            }
        }
        
        system.debug(objShareByObjName);
        
        if( !objNameByPrefix.isEmpty() ){
            List<sObject> shares2Ins = new List<sObject>();
            Set<String> appIds = docByApp.keySet();
            
            for( String prefix : objNameByPrefix.keySet() ){
                String objName = objNameByPrefix.get( prefix );
                
                if( objShareByObjName.containsKey( objName ) ){
                    String objShare = objShareByObjName.get( objName );
                    
                    Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get(objShare).getDescribe().fields.getMap();
                    
                    String query = '';
                    String parentField = 'parentid';
                    String accessField = '';
                    String rowCauseField = '';
                    String userField = '';
                    
                    for(String fName : fieldsMap.keySet()){
                        query += ', ' + fName + ' ';
                        
                        if( fName.toLowerCase() == objName.toLowerCase() + 'id' ){
                            parentField = fName;
                        }
                        if( fName.toLowerCase().contains('access') ){
                            accessField = fName;
                        }
                        if( fName.toLowerCase().contains('cause') ){
                            rowCauseField = fName;
                        }
                        if( fName.toLowerCase().contains('user') ){
                            userField = fName;
                        }
                    }
                    system.debug('objShare: ' + objShare);
                    query = 'SELECT ' + query.subString(1) + ' FROM ' + objShare + ' WHERE IsDeleted = false AND ' + parentField + ' IN :appIds ';
                    system.debug('query: ' + query );
                    for( sObject sObj : database.query( query ) ){
                        String appId = String.valueOf(sObj.get(parentField)).subString(0,15) ;
                        for( Document__c doc : docByApp.get( appId ) ){
                            Document__Share docShare = new Document__Share();
                            docShare.UserOrGroupId = (Id) sObj.get( userField );
                            docShare.AccessLevel = String.valueOf(sObj.get( accessField ));
                            if(docShare.AccessLevel == 'All'){
                                docShare.AccessLevel = 'Edit'; // Since we cannot create with all value.
                            }
                            // SHOULDN'T BE POPULATED SINCE WILL FAIL WIHT Automatic SHARING - docShare.RowCause = String.valueOf(sObj.get(rowCauseField));
                            docShare.ParentId = doc.Id;
                            
                            shares2Ins.add(docShare);
                        }
                    }
                }
            }
            
            if( !shares2Ins.isEmpty() ){
                
                system.debug(system.LoggingLevel.INFO, 'shares2Ins: ' + shares2Ins );
                List<Database.SaveResult> slr = database.insert( shares2Ins, false );
                for(Integer i = 0; i < slr.size(); i++){
                    system.debug(system.LoggingLevel.INFO, 'slr[i]: ' + slr[i]);
                }
            }
        }
    }
    
    
    /******************************************************************************* 
    Name              : PltAssignment_CreateSharingRules
    Description       : Handler the sharing record of Price list title
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             07/07/2016              Yaara                 [SW-20272]
    *******************************************************************************/
    public static void PltAssignment_CreateSharingRules(List<Id> pltIds){

        List<Price_List_Title__Share> sh2Ins = new List<Price_List_Title__Share>();
        for(Price_List_Title_Assignment__c pltAssignment : [SELECT Price_List_Title__c, Franchise__r.Partner_Account_User__c, Franchise__r.Partner_Account_Manager__c, Franchise__r.Partner_Account_NC__c FROM Price_List_Title_Assignment__c WHERE Id IN :pltIds]){
            sh2Ins.add(new Price_List_Title__Share(ParentId = pltAssignment.Price_List_Title__c, UserOrGroupId = pltAssignment.Franchise__r.Partner_Account_User__c, AccessLevel = 'Read'));
            sh2Ins.add(new Price_List_Title__Share(ParentId = pltAssignment.Price_List_Title__c, UserOrGroupId = pltAssignment.Franchise__r.Partner_Account_Manager__c, AccessLevel = 'Read'));
            sh2Ins.add(new Price_List_Title__Share(ParentId = pltAssignment.Price_List_Title__c, UserOrGroupId = pltAssignment.Franchise__r.Partner_Account_NC__c, AccessLevel = 'Read'));
        }
        
        if(!sh2Ins.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(sh2Ins, false);
            system.debug('newSharingData: ' + newSharingData);
        }
    }

    /******************************************************************************* 
    Name              : PltAssignment_RemoveSharingRules
    Description       : Handling the sharing record of Price list title
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             07/07/2016              Yaara                 [SW-25238]
    *******************************************************************************/
    public static void PltAssignment_RemoveSharingRules(){

        Set<Id> pltIds = new Set<Id>();
        Map<Id,Set<Id>> pltMap = new Map<Id,Set<Id>>();
        Set<Id> uIds = new Set<Id>();

        for(Integer i=0; i < trigger.size; i++ ){
            pltIds.add(trigger.old[i].Id);
        }

        for(Price_List_Title_Assignment__c pltAssignment : [SELECT Price_List_Title__c, Franchise__r.Partner_Account_User__c, Franchise__r.Partner_Account_Manager__c, Franchise__r.Partner_Account_NC__c FROM Price_List_Title_Assignment__c WHERE Id IN :pltIds]){
            if(!pltMap.containsKey(pltAssignment.Price_List_Title__c)){
                pltMap.put(pltAssignment.Price_List_Title__c , new Set<Id>());
            }
            pltMap.get(pltAssignment.Price_List_Title__c).add(pltAssignment.Franchise__r.Partner_Account_User__c);
            pltMap.get(pltAssignment.Price_List_Title__c).add(pltAssignment.Franchise__r.Partner_Account_Manager__c);
            uIds.add(pltAssignment.Franchise__r.Partner_Account_User__c);
            uIds.add(pltAssignment.Franchise__r.Partner_Account_Manager__c);
        }

        List<Price_List_Title__Share> sh2remove = new List<Price_List_Title__Share>();
        for (Price_List_Title__Share pltShare : [SELECT ParentId, UserOrGroupId FROM Price_List_Title__Share WHERE ParentId IN :pltMap.keySet() AND UserOrGroupId IN :uIds]) {
            if(pltMap.get(pltShare.ParentId).contains(pltShare.UserOrGroupId)){
                sh2remove.add(pltShare);
            }
        }
        
        if(!sh2remove.isEmpty()){
            Database.delete(sh2remove, false);
        }
    }

    /******************************************************************************* 
    Name              : Opportunity_CreateSharingRules
    Description       : Handler the sharing record of LG cusmot object
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. Hernan Sinclair          05/11/2016              Yaara                 [SW-19265]
    *******************************************************************************/
    public static void Opportunity_CreateSharingRules(List<Opportunity> opps){
        
        Set<Id> accIds = new Set<Id>();
        for(Opportunity opp : opps){
            accIds.add(opp.AccountId);
        }

        //accid, parentid
        Map<Id,Id> dAccIds = new Map<Id,Id>();
        for (Account dAcc : [SELECT ParentId FROM Account WHERE Id = :accIds]) {
            dAccIds.put(dAcc.Id, dAcc.ParentId);
        }

        Set<Id> dAccIdset = new Set<Id>();
        dAccIdset.addAll(dAccIds.values());
        
        Map<String,Map<Id, Set<id>>> hierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(dAccIdset, true, true, true);
        Map<Id, Set<id>> franchiseeHierarchyUsers = hierarchyUsers.get('franchisee');
        Map<Id, Set<id>> ncHierarchyUsers = hierarchyUsers.get('nc');
        
        List<OpportunityShare> sh2Ins = new List<OpportunityShare>();
        for(Opportunity opp : opps){
            if(!franchiseeHierarchyUsers.isEmpty()){
                Id pId = dAccIds.get(opp.AccountId);
                for(Id uId : franchiseeHierarchyUsers.get(pId)){
                    sh2Ins.add(new OpportunityShare(OpportunityId = opp.Id, UserOrGroupId = uId, OpportunityAccessLevel = 'Edit'));
                }
            }

            if(!ncHierarchyUsers.isEmpty()){
                Id pId = dAccIds.get(opp.AccountId);
                for(Id uId : ncHierarchyUsers.get(pId)){
                    sh2Ins.add(new OpportunityShare(OpportunityId = opp.Id, UserOrGroupId = uId, OpportunityAccessLevel = 'Read'));
                }
            }
        }
        
        if(!sh2Ins.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(sh2Ins, false);
            system.debug('newSharingData: ' + newSharingData);
        }
    }

    /******************************************************************************* 
    Name              : Account_CreateSharingRules
    Description       : Handler the sharing record of LG cusmot object
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. Hernan Sinclair          05/11/2016              Yaara                 [SW-19262]
    *******************************************************************************/
    public static void Account_CreateSharingRules(Set<Id> accIds){
        
        Map<String,Map<Id, Set<id>>> hierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(accIds, true, true, true);
        Map<Id, Set<id>> franchiseeHierarchyUsers = hierarchyUsers.get('franchisee');
        Map<Id, Set<id>> ncHierarchyUsers = hierarchyUsers.get('nc');

        List<AccountShare> sh2Ins = new List<AccountShare>();
        for(Id accId : accIds){
            if(!franchiseeHierarchyUsers.isEmpty()){
                for(Id uId : franchiseeHierarchyUsers.get(accId)){
                    sh2Ins.add(new AccountShare(AccountId = accId, UserOrGroupId = uId, AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'None', ContactAccessLevel = 'Edit', CaseAccessLevel = 'Edit'));
                }
            }
            if(!ncHierarchyUsers.isEmpty()){
                for(Id uId : ncHierarchyUsers.get(accId)){
                    sh2Ins.add(new AccountShare(AccountId = accId, UserOrGroupId = uId, AccountAccessLevel = 'Read', OpportunityAccessLevel = 'Read' , ContactAccessLevel = 'Read', CaseAccessLevel = 'Read'));
                }
            }
        }
        
        if(!sh2Ins.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(sh2Ins, false);
            system.debug('newSharingData: ' + newSharingData);
        }
    }
    

    /******************************************************************************* 
    Name              : LG_CreateSharingRules
    Description       : Handler the sharing record of LG cusmot object
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. Hernan Sinclair          05/11/2016              Yaara                 [SW-19263]
    2. G. Fernandez             05/26/2016              Yaara                 [SW-19263]
    *******************************************************************************/
    
    public static void LG_CreateSharingRules(List<LG__c> lgs){      
         
        Map<Id, Set<Id>> teachersByLG       = new Map<Id, Set<Id>>(); // I used a set in case that in future we will need to manage more than one teacher (example fom the LG lessons). 
        List<LG__c> lgRecords               = new List<LG__c>();
        Set<Id> franchiseeIds               = new Set<Id>();
        Map<Id,Id> ownerIds                 = new Map<Id,Id>();
        
        
        for(LG__c lg : lgs){
            
            lgRecords.add(lg);
            
            // Get the related the teacher to look for his user
            teachersByLG.put(lg.Id, new Set<Id>());
            if(lg.Teacher__c != null){
                teachersByLG.get(lg.Id).add(lg.Teacher__c);
            }
            
            //Use for getting the related franchisee users on the hiearchy
            if(lg.Franchisee__c != null){
                franchiseeIds.add(lg.Franchisee__c);
            }

            //Use for getting the related franchisee users on the hiearchy
            ownerIds.put(lg.OwnerId,null);      
        }
        
        // Get the users related with the teachers
        Map<Id, User> userOfTeacher = new Map<Id, User>();

        Set<Id> allTeacherIds = new Set<Id>();
        for(Set<Id> t : teachersByLG.values()){ 
            allTeacherIds.addAll(t);
        }

        //get the account from lg owners, and users from contacts(teachers)
        for(User u : [SELECT Id, ContactId, AccountId FROM User WHERE ContactId IN : allTeacherIds OR Id IN :ownerIds.keySet()]){
            userOfTeacher.put(u.ContactId, u);
            franchiseeIds.add(u.AccountId);
            ownerIds.put(u.Id, u.AccountId);
        }
        
        // Get the franchisee Hierarchy Users
        Map<String,Map<Id, Set<id>>> hierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(franchiseeIds, true, true, true);
        Map<Id, Set<id>> franchiseeHierarchyUsers = hierarchyUsers.get('franchisee');
        Map<Id, Set<id>> ncHierarchyUsers = hierarchyUsers.get('nc');

        /*Map<Id, Set<id>> franchiseeHierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(franchiseeIds, true, true);
        Map<Id, Set<id>> ncHierarchyUsers = MonitorRecursionClass.getfranchiseeNCHierarchyUsers(franchiseeIds);*/
        
        List<LG__Share> lg2Insert = new List<LG__Share>();
        //sharing according to classroom            
        List<LC_Class_Room__Share> classShare2Ins = new List<LC_Class_Room__Share>();

        // Collect Users and LG to delete related shares
        Map<Id,Set<Id>> removeSharing = new Map<Id,Set<Id>>();
        Set<Id> lgRemoveSharing = new Set<Id>();

        for(LG__c lg : lgs){
            
            // Create sharing for LG Teachers
            Map<Id,List<LG__Share>> rwSharing = new Map<Id,List<LG__Share>>();          

            for(Id tId : teachersByLG.get(lg.Id)){
                if(userOfTeacher.containsKey(tId)){
                    if(lg.Teacher_Permission_on_LG__c != null && lg.Teacher_Permission_on_LG__c.startsWith('Update')){
                        if( !rwSharing.containsKey(userOfTeacher.get(tId).Id) ){
                            rwSharing.put( userOfTeacher.get(tId).Id, new List<LG__Share>() );
                        }
                        rwSharing.get(userOfTeacher.get(tId).Id).add(new LG__Share(ParentId = lg.Id, UserOrGroupId = userOfTeacher.get(tId).Id, AccessLevel = 'Edit'));
                        if(lg.Classroom__c != null){
                            classShare2Ins.add(new LC_Class_Room__Share(ParentId = lg.Classroom__c, UserOrGroupId = userOfTeacher.get(tId).Id, AccessLevel = 'Edit'));
                        }
                    }else if(lg.Teacher_Permission_on_LG__c != null && lg.Teacher_Permission_on_LG__c.startsWith('Read')){
                        if( !rwSharing.containsKey(userOfTeacher.get(tId).Id) ){
                            rwSharing.put( userOfTeacher.get(tId).Id, new List<LG__Share>() );
                        }
                        rwSharing.get(userOfTeacher.get(tId).Id).add(new LG__Share(ParentId = lg.Id, UserOrGroupId = userOfTeacher.get(tId).Id, AccessLevel = 'Read'));
                        if(lg.Classroom__c != null){
                            classShare2Ins.add(new LC_Class_Room__Share(ParentId = lg.Classroom__c, UserOrGroupId = userOfTeacher.get(tId).Id, AccessLevel = 'Read'));
                        }
                    }else if(lg.Teacher_Permission_on_LG__c == null || lg.Teacher_Permission_on_LG__c.startsWith('No Permission')){
                        if( !removeSharing.containsKey(userOfTeacher.get(tId).Id) ){
                            removeSharing.put( userOfTeacher.get(tId).Id, new Set<Id>() );
                        }
                        removeSharing.get(userOfTeacher.get(tId).Id).add(lg.Id);
                        lgRemoveSharing.add(lg.Id);
                    }
                }
            }
            
            // Creating sharing for LG User/Manager on Franchisee Hierarchy
            if( lg.Franchisee__c <> null && franchiseeHierarchyUsers.containsKey(lg.Franchisee__c) && franchiseeHierarchyUsers.get(lg.Franchisee__c) != null){  
                for(Id uId : franchiseeHierarchyUsers.get(lg.Franchisee__c)){

                    if( !rwSharing.containsKey(uId) ){
                        rwSharing.put( uId, new List<LG__Share>() );
                    }
                    rwSharing.get(uId).add(new LG__Share(ParentId = lg.Id, UserOrGroupId = uId, AccessLevel = 'Edit'));
                }
                if(!ncHierarchyUsers.isEmpty()){
                    for(Id uId : ncHierarchyUsers.get(lg.Franchisee__c)){
                        if( !rwSharing.containsKey(uId) ){
                            rwSharing.put( uId, new List<LG__Share>() );
                        }
                        rwSharing.get(uId).add(new LG__Share(ParentId = lg.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
                    }
                }
            }

            // Creating sharing for DirectFranchise Hierarchy
            if(ownerIds.containsKey(lg.OwnerId) && ownerIds.get(lg.OwnerId) != null){
                if(franchiseeHierarchyUsers.containsKey(ownerIds.get(lg.OwnerId))){             
                    for( Id uId : franchiseeHierarchyUsers.get( ownerIds.get(lg.OwnerId) ) ){
                        if( !rwSharing.containsKey(uId) ){
                            rwSharing.put( uId, new List<LG__Share>() );
                        }
                        rwSharing.get(uId).add(new LG__Share(ParentId = lg.Id, UserOrGroupId = uId, AccessLevel = 'Edit'));
                    }
                }
                if(!ncHierarchyUsers.isEmpty()){
                    for(Id uId : ncHierarchyUsers.get(ownerIds.get(lg.OwnerId))){
                        if( !rwSharing.containsKey(uId) ){
                            rwSharing.put( uId, new List<LG__Share>() );
                        }
                        rwSharing.get(uId).add(new LG__Share(ParentId = lg.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
                    }
                }
            }

            for( Id user4Sharing : rwSharing.keySet() ){                        
                for( LG__Share lgSh : rwSharing.get(user4Sharing) ){
                    lg2Insert.add(lgSh);
                }
            }
        }
        
        if(!lg2Insert.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(lg2Insert, false);
        }

        if(!classShare2Ins.isEmpty()){
            Database.SaveResult[] newClassroomSharingData = database.insert(classShare2Ins, false);
        }

        /* DELETING TEACHER SHARES FOR LGs WITH NO PERMISSION */
        if(!removeSharing.isEmpty()){
            List<LG__Share> deleteShares = new List<LG__Share>();   
            for(LG__Share share : [SELECT Id, ParentId, UserOrGroupId FROM LG__Share WHERE ParentId IN : lgRemoveSharing AND UserOrGroupId IN : removeSharing.keySet() AND RowCause = 'Manual']){
                if(removeSharing.containsKey(share.UserOrGroupId) && removeSharing.get(share.UserOrGroupId).contains(share.ParentId) ){
                    deleteShares.add(share);
                }
            }       
            Database.delete(deleteShares,false);
        }       
    }

    /******************************************************************************* 
    Name              : Campaign_CreateSharingRules
    Description       : Handler the sharing record of Campaign
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             05/11/2016              Yaara                 [SW-19261]
    *******************************************************************************/
    
    public static void Campaign_CreateSharingRules(Map<Id,Id> campaignAccIds){  

        Set<Id> accIds = new Set<Id>(campaignAccIds.values());  
                
        // Get the franchisee Hierarchy Users
        Map<String,Map<Id, Set<id>>> hierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(accIds, true, true, true);
        Map<Id, Set<id>> franchiseeHierarchyUsers = hierarchyUsers.get('franchisee');
        Map<Id, Set<id>> ncHierarchyUsers = hierarchyUsers.get('nc');               

        /*Map<Id, Set<id>> franchiseeHierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(accIds, true, true);
        Map<Id, Set<id>> ncHierarchyUsers = MonitorRecursionClass.getfranchiseeNCHierarchyUsers(accIds);*/
        
        List<CampaignShare> sh2Ins = new List<CampaignShare>();
        for(Id campaignId : campaignAccIds.keySet()){
            if (franchiseeHierarchyUsers.containsKey(campaignAccIds.get(campaignId))) {
                for( Id uId : franchiseeHierarchyUsers.get(campaignAccIds.get(campaignId)) ){
                    sh2Ins.add(new CampaignShare(CampaignId = campaignId, UserOrGroupId = uId, CampaignAccessLevel = 'Edit'));
                }
            }
            if(!ncHierarchyUsers.isEmpty()){
                for(Id uId : ncHierarchyUsers.get(campaignAccIds.get(campaignId))){
                    sh2Ins.add(new CampaignShare(CampaignId = campaignId, UserOrGroupId = uId, CampaignAccessLevel = 'Read'));
                }
            }
        }
        
        if(!sh2Ins.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(sh2Ins, false);
        }
    }

    /******************************************************************************* 
    Name              : Family_CreateSharingRules
    Description       : Handler the sharing record of Family__c
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             05/13/2016          Yaara Nadir               [SW-19264]
    *******************************************************************************/
    
    public static void Family_CreateSharingRules(List<Family__c> familys){  
        
        Set<Id> ownerIds = new Set<Id>();
        for(Family__c family : familys){
            ownerIds.add(family.OwnerId);           
        }

        Map<Id,Id> familyAccIds = new Map<Id,Id>();
        for(User u : [SELECT AccountId FROM User WHERE Id IN : ownerIds]){
            familyAccIds.put(u.Id, u.AccountId);
        }   

        Set<Id> familyAccSetId = new Set<Id>(familyAccIds.values());

        // Get the franchisee Hierarchy Users
        Map<String,Map<Id, Set<id>>> hierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(familyAccSetId, true, true, true);
        Map<Id, Set<id>> franchiseeHierarchyUsers = hierarchyUsers.get('franchisee');
        Map<Id, Set<id>> ncHierarchyUsers = hierarchyUsers.get('nc');
                
        /*Map<Id, Set<id>> franchiseeHierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(familyAccSetId, true, true);
        Map<Id, Set<id>> ncHierarchyUsers = MonitorRecursionClass.getfranchiseeNCHierarchyUsers(familyAccSetId);*/
        
        List<Family__Share> sh2Ins = new List<Family__Share>();
        for(Family__c family : familys){
            if(!franchiseeHierarchyUsers.isEmpty()){            
                for( Id uId : franchiseeHierarchyUsers.get(familyAccIds.get(family.OwnerId)) ){
                    sh2Ins.add(new Family__Share(ParentId = family.Id, UserOrGroupId = uId, AccessLevel = 'Edit'));
                }
            }
        
            if(!ncHierarchyUsers.isEmpty()){
                for(Id uId : ncHierarchyUsers.get(familyAccIds.get(family.OwnerId))){
                    sh2Ins.add(new Family__Share(ParentId = family.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
                }
            }
        }       

        if(!sh2Ins.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(sh2Ins, false);
        }
    }

    /******************************************************************************* 
    Name              : Contact_CreateSharingRules
    Description       : Handler the sharing record of Contact
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             05/13/2016          Yaara Nadir               [SW-19588]
    *******************************************************************************/
    
    public static void Contact_CreateSharingRules(List<Contact> contacts){  
        
        /*Set<Id> ownerIds = new Set<Id>();
        for(Contact con : contacts){
            ownerIds.add(con.OwnerId);          
        }

        Map<Id,Id> conAccIds = new Map<Id,Id>();
        for(User u : [SELECT AccountId FROM User WHERE Id IN : ownerIds]){
            conAccIds.put(u.Id, u.AccountId);
        }*/

        Map<Id,Id> conAccIds = new Map<Id,Id>();
        for(Contact c : contacts){
            conAccIds.put(c.Id, c.AccountId);
        }


        Set<Id> conAccSetId = new Set<Id>(conAccIds.values());  

        // Get the franchisee Hierarchy Users
        Map<String,Map<Id, Set<id>>> hierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(conAccSetId, true, true, true);
        Map<Id, Set<id>> franchiseeHierarchyUsers = hierarchyUsers.get('franchisee');
        Map<Id, Set<id>> ncHierarchyUsers = hierarchyUsers.get('nc');
                
        /*Map<Id, Set<id>> franchiseeHierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(conAccSetId, true, true);
        Map<Id, Set<id>> ncHierarchyUsers = MonitorRecursionClass.getfranchiseeNCHierarchyUsers(conAccSetId);*/

        List<ContactShare> sh2Ins = new List<ContactShare>();
        
        for(Contact con : contacts){
            Id conAccId = conAccIds.get(con.Id);
            if(!franchiseeHierarchyUsers.isEmpty() && conAccId != null){
                for( Id uId : franchiseeHierarchyUsers.get(conAccId)){
                    sh2Ins.add(new ContactShare(ContactId = con.Id, UserOrGroupId = uId, ContactAccessLevel = 'Edit'));
                }
            }
            if(!ncHierarchyUsers.isEmpty() && conAccId != null){
                for( Id uId : ncHierarchyUsers.get(conAccId)){
                    sh2Ins.add(new ContactShare(ContactId = con.Id, UserOrGroupId = uId, ContactAccessLevel = 'Read'));
                }
            }
        }

        
        if(!sh2Ins.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(sh2Ins, false);
            for(Integer i = 0; i < newSharingData.size(); i++){
                Database.SaveResult sr = newSharingData.get(i);
                if(!sr.isSuccess()){
                    System.debug(System.LoggingLevel.ERROR,' Error ' + sr.getErrors()[0].getMessage());
                }
            }
        }
    }

    /******************************************************************************* 
    Name              : Contact_CreateTeacherSharingRules
    Description       : Handler the sharing record of Contact
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             16/12/2016          Yaara Nadir               [SW-22752]
    *******************************************************************************/
    
    public static void Contact_CreateTeacherSharingRules(List<Contact> contacts){  
        
        Map<Id,Id> conAccIds = new Map<Id,Id>();
        for(Contact c : contacts){
            conAccIds.put(c.Id,c.AccountId);
        }

        Map<Id,Account> accs = new Map<Id,Account>();
        for(Account acc : [SELECT Id, Partner_Account_User__c, Partner_Account_Manager__c FROM Account WHERE Id IN :conAccIds.values()]){
            accs.put(acc.Id, acc);
        }


        List<Seminar__Share> ssh2Ins = new List<Seminar__Share>();
        List<Seminar_Teachers__Share> stsh2Ins = new List<Seminar_Teachers__Share>();
        for(Seminar_Teachers__c st :[SELECT Id, Teacher__c, Seminar__c FROM Seminar_Teachers__c WHERE Teacher__c IN :conAccIds.keySet() AND Teacher_Status_in_seminar__c = 'Registered']){
            Id accId = conAccIds.get(st.Teacher__c);
            Account acc = accs.get(accId);
            stsh2Ins.add(new Seminar_Teachers__Share(ParentId = st.Id, UserOrGroupId = acc.Partner_Account_User__c, AccessLevel = 'Read'));
            stsh2Ins.add(new Seminar_Teachers__Share(ParentId = st.Id, UserOrGroupId = acc.Partner_Account_Manager__c, AccessLevel = 'Read'));

            ssh2Ins.add(new Seminar__Share(ParentId = st.Seminar__c, UserOrGroupId = acc.Partner_Account_User__c, AccessLevel = 'Read'));
            ssh2Ins.add(new Seminar__Share(ParentId = st.Seminar__c, UserOrGroupId = acc.Partner_Account_Manager__c, AccessLevel = 'Read'));
        }

        if(!ssh2Ins.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(ssh2Ins, false);
        }

        if(!stsh2Ins.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(stsh2Ins, false);
        }
    }

    //same as batch Batch_RecentRelationshipOnContact but triggered on contact owner change
    public static void Contact_CreateRelationshipSharingRules(List<Id> contactIds){ 

        List<AccountContactRelation> accountRelations = [SELECT Id, ContactId, AccountId, LastModifiedById FROM AccountContactRelation WHERE ContactId IN :contactIds];

        Map<Id,Set<Id>> accIds = new Map<Id,Set<Id>>();
        for(AccountContactRelation cRelation : accountRelations){
            if (!accIds.containsKey(cRelation.AccountId)) {
                accIds.put(cRelation.AccountId,new Set<Id>());
            }
            accIds.get(cRelation.AccountId).add(cRelation.ContactId);
        }

        Map<String,Map<Id, Set<id>>> hierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(accIds.keySet(),true,true,false);
        Map<Id, Set<id>> franchiseeHierarchyUsers = hierarchyUsers.get('franchisee');
        

        List<ContactShare> newContactShares = new List<ContactShare>();

        if(!franchiseeHierarchyUsers.isEmpty()){
            for(AccountContactRelation cRelation : accountRelations){
                for(Id uId : franchiseeHierarchyUsers.get(cRelation.AccountId)){
                    newContactShares.add(new ContactShare(ContactId = cRelation.ContactId, UserOrGroupId = uId, ContactAccessLevel = 'Edit'));
                }
            }
        }

        if(!newContactShares.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(newContactShares, false);
            system.debug('newSharingData: ' + newSharingData);
        }
    }

    /******************************************************************************* 
    Name              : AccContactRelation_CreateSharingRules
    Description       : sames as Batch_SharingForAccountContactRelated but triggered on creation (since this feature on the object is new in sf)
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             03/05/2017          Yaara Nadir               [SW-24694]
    *******************************************************************************/
    public static void AccContactRelation_CreateSharingRules(List<AccountContactRelation> accountRelations){ 

        Id recTypeTeacherId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();

        Map<Id,Set<Id>> accIds = new Map<Id,Set<Id>>();
        Map<Id,Set<Id>> conAccIds = new Map<Id,Set<Id>>();

        for(AccountContactRelation cRelation : accountRelations){
            if (!accIds.containsKey(cRelation.AccountId)) {
                accIds.put(cRelation.AccountId,new Set<Id>());
            }
            accIds.get(cRelation.AccountId).add(cRelation.ContactId);

            if (!conAccIds.containsKey(cRelation.ContactId)) {
                conAccIds.put(cRelation.ContactId,new Set<Id>());
            }
            conAccIds.get(cRelation.ContactId).add(cRelation.AccountId);           
        }

        //getting contact users
        Map<Id,Id> conUsers = new Map<Id,Id>(); 
        for (Contact con : [SELECT Contact_Partner_User__c FROM Contact WHERE Id IN :conAccIds.keySet() AND RecordTypeId =:recTypeTeacherId]) {
            if(con.Contact_Partner_User__c != null){
                conUsers.put(con.Id ,con.Contact_Partner_User__c);
            }    
        }

        //getting account users
        Map<Id,Id> accUsers = new Map<Id,Id>(); 
        for (Account acc : [SELECT Partner_Account_User__c FROM Account WHERE Id IN :accIds.keySet()]) {
            if(acc.Partner_Account_User__c != null){
                accUsers.put(acc.Id ,acc.Partner_Account_User__c);
            }    
        }

        //mapping agreements by contacts
        Map<Id,Set<Id>> teacherAgreements = new Map<Id,Set<Id>>();
        for(Teacher_Agreement__c ta : [SELECT Teacher__c FROM Teacher_Agreement__c WHERE Teacher__c IN :conAccIds.keySet() AND Agreement_Status__c = 'Approved']){
            if(!teacherAgreements.containsKey(ta.Teacher__c)){
                teacherAgreements.put(ta.Teacher__c,new Set<Id>());
            }
            teacherAgreements.get(ta.Teacher__c).add(ta.Id);
        }

        List<AccountShare> newSharesOnAccount = new List<AccountShare>();
        List<ContactShare> newContactShares = new List<ContactShare>();
        List<Teacher_Agreement__Share> newSharesTA = new List<Teacher_Agreement__Share>();
        Set<String> newSharesTAkey = new Set<String>();

        for(AccountContactRelation cRelation : accountRelations){
            if(conUsers.containsKey(cRelation.ContactId)){
                newSharesOnAccount.add(new AccountShare(AccountId = cRelation.AccountId, UserOrGroupId = conUsers.get(cRelation.ContactId), AccountAccessLevel = 'Read', OpportunityAccessLevel = 'None' )); 
            }

            if(accUsers.containsKey(cRelation.AccountId)){
                Id uId = accUsers.get(cRelation.AccountId);
                newContactShares.add(new ContactShare(ContactId = cRelation.ContactId, UserOrGroupId = uId, ContactAccessLevel = 'Edit'));
            
                if(teacherAgreements.containsKey(cRelation.ContactId)){
                    for(Id taId : teacherAgreements.get(cRelation.ContactId)){
                        String key = taId +'_'+ uId;
                        if(!newSharesTAkey.contains(key)){
                            newSharesTAkey.add(key);
                            newSharesTA.add(new Teacher_Agreement__Share(ParentId = taId, UserOrGroupId = uId, AccessLevel = 'Read'));
                        }
                    }
                }
            }
        }

        if(!newSharesOnAccount.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(newSharesOnAccount, false);
        }

        if(!newContactShares.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(newContactShares, false);
        }

        if(!newSharesTA.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(newSharesTA, false);
        }

    }

    /******************************************************************************* 
    Name              : HDC_Order_CreateSharingRules
    Description       : Handler the sharing record of FR_Order__c
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             05/27/2016          Yaara Nadir               [SW-19590]
    *******************************************************************************/
    
    public static void HDC_Order_CreateSharingRules(List<FR_Order__c> orders){  
        
        Set<Id> ownerIds = new Set<Id>();
        for(FR_Order__c order : orders){
            ownerIds.add(order.OwnerId);            
        }

        Map<Id,Id> orderAccIds = new Map<Id,Id>();
        for(User u : [SELECT AccountId FROM User WHERE Id IN : ownerIds]){
            orderAccIds.put(u.Id, u.AccountId);
        }

        Set<Id> orderAccSetId = new Set<Id>(orderAccIds.values());  

        // Get the franchisee Hierarchy Users
        Map<String,Map<Id, Set<id>>> hierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(orderAccSetId, true, true, false);
        Map<Id, Set<id>> franchiseeHierarchyUsers = hierarchyUsers.get('franchisee');
                
        //Map<Id, Set<id>> franchiseeHierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(orderAccSetId, true, true);
        List<FR_Order__Share> sh2Ins = new List<FR_Order__Share>();
        
        if (!franchiseeHierarchyUsers.isEmpty()){
            for(FR_Order__c order : orders){
                for( Id uId : franchiseeHierarchyUsers.get(orderAccIds.get(order.OwnerId)) ){
                    sh2Ins.add(new FR_Order__Share(ParentId = order.Id, UserOrGroupId = uId, AccessLevel = 'Edit'));
                }
            }
        }

        if(!sh2Ins.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(sh2Ins, false);
        }
    }


    /******************************************************************************* 
    Name              : SeminarTeachersSharingRules
    Description       : 
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             16/12/2016              Ella               [SW-22725]
    *******************************************************************************/
    
    public static void SeminarTeachersSharingRules(List<Seminar_Teachers__c> seminarTeachers){  
        
        try{
            Map<Id,Set<Id>> semTeachers = new Map<Id,Set<Id>>();
            for(Seminar_Teachers__c semTeacher : seminarTeachers){
                if(semTeacher.Hosting_Franchisee__c != null){
                    if(!semTeachers.containsKey(semTeacher.Seminar__c)){
                        semTeachers.put(semTeacher.Seminar__c, new Set<Id>());
                    }
                    semTeachers.get(semTeacher.Seminar__c).add(semTeacher.Id);
                }
            }

            Map<Id,Id> teacherHFranchisee = new Map<Id,Id>();
            Set<Id> hostingFranchisee = new Set<Id>();
            for(Seminar__c sm : [SELECT Hosting_Franchisee__c FROM Seminar__c WHERE Id IN : semTeachers.keySet()]){
                for(Id teachers : semTeachers.get(sm.Id)){
                    teacherHFranchisee.put(teachers, sm.Hosting_Franchisee__c);
                }
                hostingFranchisee.add(sm.Hosting_Franchisee__c);
            }


            Map<Id,Id> semTeacherAccIds = new Map<Id,Id>();
            for(Account a : [SELECT Partner_Account_User__c FROM Account WHERE Id IN : hostingFranchisee]){
                semTeacherAccIds.put(a.Id,a.Partner_Account_User__c);
            }
                    
            //Map<Id, Set<id>> franchiseeHierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(semTeacherAccSetId, true, true);
            List<Seminar_Teachers__Share> sh2Ins = new List<Seminar_Teachers__Share>();
            
            for(Seminar_Teachers__c semTeacher : seminarTeachers){
                Id fId = teacherHFranchisee.get(semTeacher.Id);
                Id uId = semTeacherAccIds.get(fId);
                sh2Ins.add(new Seminar_Teachers__Share(ParentId = semTeacher.Id, UserOrGroupId = uId, AccessLevel = 'Edit'));
            }

            if(!sh2Ins.isEmpty()){
                Database.SaveResult[] newSharingData = database.insert(sh2Ins, false);
            }
        }catch(Exception e){
            System.debug(LoggingLevel.ERROR, '*** : ' + e.getMessage() + ' ' + e.getStackTraceString());
        }
    }

    /******************************************************************************* 
    Name              : SeminarTeachersSharingRules2
    Description       : 
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             16/12/2016              Ella               [SW-22725]
    *******************************************************************************/
    
    public static void SeminarTeachersSharingRules2(List<Seminar_Teachers__c> semTeachers){  
        
        Set<Id> sTeacherIds = new Set<Id>();
        for(Seminar_Teachers__c semTeacher : semTeachers){
           sTeacherIds.add(semTeacher.Id); 
        } 
        
        Map<Id,Id> semTeacherTeacher = new Map<Id,Id>();
        for(Seminar_Teachers__c semTeacher : [SELECT Id, Teacher__c FROM Seminar_Teachers__c WHERE Id IN :sTeacherIds AND Seminar__r.Status__c = 'Confirmed']){
           semTeacherTeacher.put(semTeacher.Teacher__c,null);   
        }       

        Map<Id,Id> semTeacherAccIds = new Map<Id,Id>();
        for( Contact c : [SELECT Contact_Partner_User__c FROM Contact WHERE Id IN :semTeacherTeacher.keySet()] ){
            semTeacherTeacher.put(c.Id, c.Contact_Partner_User__c); 
        }
                
        //Map<Id, Set<id>> franchiseeHierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(semTeacherAccSetId, true, true);
        List<Seminar_Teachers__Share> sh2Ins = new List<Seminar_Teachers__Share>();
        
        for(Seminar_Teachers__c semTeacher : semTeachers){
            Id uId = semTeacherTeacher.get(semTeacher.Teacher__c);
            if(uId != null && uId != semTeacher.OwnerId){
                sh2Ins.add(new Seminar_Teachers__Share(ParentId = semTeacher.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
            }
        }

        if(!sh2Ins.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(sh2Ins, false);
        }
    }

    /******************************************************************************* 
    Name              : SeminarTeachersSharingRules3
    Description       : 
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             21/12/2016              Ella               [SW-22725]
    *******************************************************************************/
    
    public static void SeminarTeachersSharingRules3(List<Seminar_Teachers__c> semTeachers){  
        
        Set<Id> sTeacherIds = new Set<Id>();
        for(Seminar_Teachers__c semTeacher : semTeachers){
           sTeacherIds.add(semTeacher.Id); 
        } 
        
        List<Seminar_Teachers__Share> sh2Ins = new List<Seminar_Teachers__Share>();
        for(Seminar_Teachers__c semTeacher : [SELECT Id, Seminar__r.Teacher_Trainer__r.Contact_Partner_User__c FROM Seminar_Teachers__c WHERE Id IN :sTeacherIds AND Seminar__r.TT_Status__c = 'Approved by TT']){
            sh2Ins.add(new Seminar_Teachers__Share(ParentId = semTeacher.Id, UserOrGroupId = semTeacher.Seminar__r.Teacher_Trainer__r.Contact_Partner_User__c, AccessLevel = 'Edit'));
        }

        if(!sh2Ins.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(sh2Ins, false);
        }
    }

    /******************************************************************************* 
    Name              : SeminarTeachersSharingRules4
    Description       : Give Read Permissions to the LC
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             02/03/2017              Dafna Margalit      [SW-23909]
    *******************************************************************************/
    
    public static void SeminarTeachersSharingRules4(List<Seminar_Teachers__c> semTeachers){  
        
        Set<Id> sTeacherIds = new Set<Id>();
        //map teacher , many seminar teachers mapped id , object
        Map<Id,Map<Id,Seminar_Teachers__c>> seminarTeachersMap = new Map<Id,Map<Id,Seminar_Teachers__c>>();
        for(Seminar_Teachers__c semTeacher : semTeachers){
            sTeacherIds.add(semTeacher.Id); 

            if(!seminarTeachersMap.containsKey(semTeacher.Teacher__c)){
                seminarTeachersMap.put(semTeacher.Teacher__c,new Map<Id,Seminar_Teachers__c>());
            }
            if(!seminarTeachersMap.get(semTeacher.Teacher__c).containsKey(semTeacher.Id)){
                seminarTeachersMap.get(semTeacher.Teacher__c).put(semTeacher.Id, semTeacher);
            }
        } 

        Set<Id> teacherIds = new Set<Id>();

        //checking if account related to the teacher match conditions
        List<Seminar_Teachers__Share> sh2Ins = new List<Seminar_Teachers__Share>();
        for(Seminar_Teachers__c semTeacher : [SELECT Id, Teacher__r.Account.Account_Type__c, Teacher__r.Account.Partner_Account_User__c, OwnerId, Seminar__r.Hosting_Franchisee__c, Seminar__r.Status__c FROM Seminar_Teachers__c WHERE Id IN :sTeacherIds]){
            //AND  TTC/Seminar. Status=Confirmed:
            if(semTeacher.Seminar__r.Status__c == 'Confirmed'){
                teacherIds.add(semTeacher.Teacher__c);
            }
            
            Boolean ownerIsNotAccPartner = semTeacher.Teacher__r.Account.Partner_Account_User__c != semTeacher.OwnerId;
            //Seminar Teacher. Teacher. Account not equal to TTC/Seminar. Hosting franchisee
            if(ownerIsNotAccPartner && semTeacher.Seminar__r.Hosting_Franchisee__c != semTeacher.Teacher__r.Account.Id){
                sh2Ins.add(new Seminar_Teachers__Share(ParentId = semTeacher.Id, UserOrGroupId = semTeacher.Teacher__r.Account.Partner_Account_User__c, AccessLevel = 'Edit')); // SW-25298
            }
        }


        
        //looking on accounts relationship object
        for(AccountContactRelation accTeacherRelation : [SELECT AccountId, Account.Partner_Account_User__c, ContactId FROM AccountContactRelation WHERE (Account.Account_Type__c = 'LSF' OR Account.Account_Type__c = 'LCF') AND ContactId IN :teacherIds]){
            
            if(teacherIds.contains(accTeacherRelation.ContactId)){
                for(Seminar_Teachers__c tSeminar : seminarTeachersMap.get(accTeacherRelation.ContactId).values()){
                    //If the Seminar Teacher owner is not the same as the teacher LC
                    //LC (Seminar Teacher. Teacher ->Related account with account type=LSF or LCF ->Partner Account User) 
                    if(tSeminar.OwnerId != accTeacherRelation.Account.Partner_Account_User__c){
                        sh2Ins.add(new Seminar_Teachers__Share(ParentId = tSeminar.Id, UserOrGroupId = accTeacherRelation.Account.Partner_Account_User__c, AccessLevel = 'Read'));
                    }            
                }
            }

        }

        if(!sh2Ins.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(sh2Ins, false);
        }
    }

    /******************************************************************************* 
    Name              : BaseCourse_CreateSharingRules
    Description       : Handler the sharing record of Base_Course__c
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             05/27/2016          Yaara Nadir               [SW-19589]
    *******************************************************************************/
    
    public static void BaseCourse_CreateSharingRules(List<Base_Course__c> bCourses){

        //user.Account  = Agreement.From Franchisee & Agreement.Program Type    
        
        //program type , account to give share
        Map<String,Set<Id>> programsAccs = new Map<String,Set<Id>>();
        for(Base_Course__c baseCourse : bCourses){
            String[] programs = baseCourse.Program_Type__c.split(';');
            for(String program : programs){             
                programsAccs.put(program, new Set<Id>());               
            }
        }

        Set<Id> agreeAccIds = new Set<Id>();
        for(Agreement__c agree : [SELECT From_Franchisee__c, Program_Type__c FROM Agreement__c WHERE Program_Type__c IN :programsAccs.keySet()]){
            programsAccs.get(agree.Program_Type__c).add(agree.From_Franchisee__c);
            agreeAccIds.add(agree.From_Franchisee__c);
        }

        //get the user of each franchise in program
        Map<Id,Set<Id>> userInProgram = new Map<Id,Set<Id>>();
        for(User u : [SELECT AccountId FROM User WHERE AccountId IN : agreeAccIds]){
            if(!userInProgram.containsKey(u.AccountId)){
                userInProgram.put(u.AccountId, new Set<Id>());
            }
            userInProgram.get(u.AccountId).add(u.Id);
        }   

        List<Base_Course__Share> sh2Ins = new List<Base_Course__Share>();           
        
        for(Base_Course__c baseCourse : bCourses){
            String[] programs = baseCourse.Program_Type__c.split(';');  
            for (String program : programs) {       
                //for each account with an agreement = program type
                for(Id accId : programsAccs.get(program)){
                    //for each user in account
                    if(userInProgram.containsKey(accId)){
                        for(Id uId : userInProgram.get(accId)){
                            sh2Ins.add(new Base_Course__Share(ParentId = baseCourse.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
                        }
                    }
                }
            }
        }

        if(!sh2Ins.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(sh2Ins, false);
        }
    }

/******************************************************************************* 
    Name              : CourseSubType_CreateSharingRules
    Description       : Handler the sharing record of Course_Sub_Type__c
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             05/13/2016          Yaara Nadir               [SW-19267]
    2. G. Fernandez             06/02/2016          Yaara Nadir               [SW-19267]
    3. G. Fernandez             07/06/2016          Yaara Nadir               [SW-19267]
    *******************************************************************************/
    
    public static void CourseSubType_CreateSharingRules(List<Course_Sub_Type__c> courseSt){ 
        
        Set<Id> ownerIds = new Set<Id>();
        for(Course_Sub_Type__c course : courseSt){
            ownerIds.add(course.OwnerId);           
        }

        //Map course type owners with his accounts
        Map<Id,Id> courseAccIds = new Map<Id,Id>();
        for(User u : [SELECT AccountId FROM User WHERE Id IN : ownerIds]){
            courseAccIds.put(u.Id, u.AccountId);
        }

        //Users to share
        Set<Id> courseAccIdset = new Set<Id>(courseAccIds.values());

        //get herarchy users 
        Map<Id,Set<Id>> subFranchiseUsers = HelperClassWithoutSharing.getSubFranchiseeUsers(courseAccIdset);

        // Get the franchisee Hierarchy Users
        Map<String,Map<Id, Set<id>>> hierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(courseAccIdset, true, true, true);
        Map<Id, Set<id>> franchiseeHierarchyUsers = hierarchyUsers.get('franchisee');
        Map<Id, Set<id>> ncHierarchyUsers = hierarchyUsers.get('nc');

        /*Map<Id, Set<id>> franchiseeHierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(courseAccIdset, true, true);
        Map<Id, Set<id>> ncHierarchyUsers = MonitorRecursionClass.getfranchiseeNCHierarchyUsers(courseAccIdset);*/
        
        List<Course_Sub_Type__Share> sh2Ins = new List<Course_Sub_Type__Share>();       
        for(Course_Sub_Type__c course : courseSt){
            if(courseAccIds.containsKey(course.OwnerId)){
                Id franchiseId = courseAccIds.get(course.OwnerId);
                if(!subFranchiseUsers.isEmpty()){
                    for( Id subFranchiseUserId : subFranchiseUsers.get(franchiseId) ){
                        sh2Ins.add(new Course_Sub_Type__Share(ParentId = course.Id, UserOrGroupId = subFranchiseUserId, AccessLevel = 'Read'));
                    }
                }
                if(!franchiseeHierarchyUsers.isEmpty()){
                    for( Id fUId : franchiseeHierarchyUsers.get(franchiseId) ){
                        sh2Ins.add(new Course_Sub_Type__Share(ParentId = course.Id, UserOrGroupId = fUId, AccessLevel = 'Edit'));
                    }
                }
                if(!ncHierarchyUsers.isEmpty()){
                    for( Id uNCId : ncHierarchyUsers.get(franchiseId) ){
                        sh2Ins.add(new Course_Sub_Type__Share(ParentId = course.Id, UserOrGroupId = uNCId, AccessLevel = 'Read'));
                    }
                }
            }
        }
        
        //test.startTest();
        
        if(!sh2Ins.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(sh2Ins, false);
        }
        
        //test.stopTest();
    }

    /******************************************************************************* 
    Name              : SeminarType_CreateSharingRules
    Description       : Handler the sharing record of Campaign
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             06/21/2016              Yaara                 [SW-20016]
    2. G. Fernandez             02/01/2017              Dafna Margalit        [SW-22980]
    *******************************************************************************/
    
    public static void SeminarType_CreateSharingRules(List<Seminar_Type__c> seminarTypeList){   

        //user.Account  = Agreement.From Franchisee & Agreement.Program Type
        Map<String,Set<Id>> programsAccs = new Map<String,Set<Id>>();
        String programsQuery = '';
        for(Seminar_Type__c st : seminarTypeList){
            String[] programs = st.Program_Type__c.split(';');
            for(String program : programs){
                if(!programsAccs.containsKey(program)){
                    programsAccs.put(program, new Set<Id>());
                    programsQuery += ',\''+program+'\'';            
                }             
            }
        }
        programsQuery = programsQuery.substring(1);

        Set<Id> agreeAccIds = new Set<Id>();
        for(Agreement__c agree : [SELECT From_Franchisee__c, Program_Type__c FROM Agreement__c WHERE Program_Type__c IN :programsAccs.keySet()]){
            programsAccs.get(agree.Program_Type__c).add(agree.From_Franchisee__c);
            agreeAccIds.add(agree.From_Franchisee__c);
        }

        String query = 'SELECT Contact_Partner_User__c, Program_Type__c FROM Contact WHERE Program_Type__c INCLUDES ('+programsQuery+')';

        Map<String,Set<Id>> programContactIds = new Map<String,Set<Id>>();
        for(Contact con : Database.query(query)){
            if (con.Contact_Partner_User__c!=null) {
                String[] programs = con.Program_Type__c.split(';');
                for(String program : programs){
                    if (!programContactIds.containsKey(program)) {
                        programContactIds.put(program,new Set<Id>()); 
                    }
                    programContactIds.get(program).add(con.Contact_Partner_User__c);
                }
            }
        }

        //get the user of each franchise in program
        Map<Id,Set<Id>> userInProgram = new Map<Id,Set<Id>>();
        for(User u : [SELECT AccountId FROM User WHERE AccountId IN : agreeAccIds]){
            if(!userInProgram.containsKey(u.AccountId)){
                userInProgram.put(u.AccountId, new Set<Id>());
            }
            userInProgram.get(u.AccountId).add(u.Id);
        }   

        List<Seminar_Type__Share> sh2Ins = new List<Seminar_Type__Share>();         
        
        for(Seminar_Type__c st : seminarTypeList){
            String[] programs = st.Program_Type__c.split(';');  
            for (String program : programs) {       
                //for each account with an agreement = program type
                for(Id accId : programsAccs.get(program)){
                    //for each user in account
                    if(userInProgram.containsKey(accId)){
                        for(Id uId : userInProgram.get(accId)){
                            sh2Ins.add(new Seminar_Type__Share(ParentId = st.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
                        }
                    }
                }

                //for each contact with program type
                if (programContactIds.containsKey(program)) {
                    for(Id uId : programContactIds.get(program)){
                        sh2Ins.add(new Seminar_Type__Share(ParentId = st.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
                    }
                }
            }
        }
        
        Database.SaveResult[] newSharingData;
        if(!sh2Ins.isEmpty()){
            newSharingData = database.insert(sh2Ins, false);
        }
    }

    /******************************************************************************* 
    Name              : lgStudent_CreateSharingRules
    Description       : Handler the sharing record of LG_Student
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             05/12/2016              Yaara                 [SW-19268]
    2. G. Fernandez             06/09/2016              Yaara                 [SW-19268]
    3. G. Fernandez             07/06/2016              Yaara                 [SW-19268]
    *******************************************************************************/

    public static void lgStudent_CreateSharingRules(Set<Id> lgStudentIds){
        
        Set<Id> teachersIds = new Set<Id>();
        Map<Id, Set<Id>> lgTeachers = new Map<Id, Set<Id>>();
        Set<Id> studentAccIds = new Set<Id>();
        //Get teacher from student lg
        List<LG_Student__c> lgStudents = [SELECT Student__c, LG__c, LG__r.Teacher__c, Student__r.AccountId, LG__r.Teacher_Permission_on_LG__c FROM LG_Student__c WHERE Id IN :lgStudentIds];
        for(LG_Student__c lgStudent :lgStudents){
            if(lgStudent.LG__r.Teacher__c != null && lgStudent.LG__r.Teacher_Permission_on_LG__c != null && (lgStudent.LG__r.Teacher_Permission_on_LG__c.startsWith('Update') || lgStudent.LG__r.Teacher_Permission_on_LG__c.startsWith('Read') )){
                if(!lgTeachers.containsKey(lgStudent.LG__c)){
                    lgTeachers.put(lgStudent.LG__c, new Set<Id>());
                }
                lgTeachers.get(lgStudent.LG__c).add(lgStudent.LG__r.Teacher__c);
                teachersIds.add(lgStudent.LG__r.Teacher__c);
                studentAccIds.add(lgStudent.Student__r.AccountId);
            }
        }
        //requeriments changed
        //Get teachers from lg's days n hours
        /*for(LG_Days_Hours__c dh : [SELECT Teacher__c, LG__c FROM LG_Days_Hours__c WHERE LG__c IN :lgTeachers.keySet()]){
            if(dh.Teacher__c != null){
                if(!lgTeachers.containsKey(dh.LG__c)){
                    lgTeachers.put(dh.LG__c, new Set<Id>());
                }
                lgTeachers.get(dh.LG__c).add(dh.Teacher__c);
                teachersIds.add(dh.Teacher__c);     
            }   
        }*/             

        //get teacher's users 
        Map<Id,User> teacherUsers = new Map<Id,User>();
        if(!teachersIds.isEmpty()){
            for(User user : [SELECT Id, ContactId FROM User WHERE ContactId IN :teachersIds]){          
                teacherUsers.put(user.ContactId, user);
            }
        }   

        // Get the franchisee Hierarchy Users
        Map<String,Map<Id, Set<id>>> hierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(studentAccIds, true, true, true);
        Map<Id, Set<id>> franchiseeHierarchyUsers = hierarchyUsers.get('franchisee');
        Map<Id, Set<id>> ncHierarchyUsers = hierarchyUsers.get('nc');
        
        //test.startTest();
        
        if(!teacherUsers.isEmpty()){
            //adding share to each teacher user for each student inserted 
            List<ContactShare> sh2Ins = new List<ContactShare>();       
            for(LG_Student__c lgStudent :lgStudents){
                if(lgTeachers.containsKey(lgStudent.LG__c)){
                    for(Id teacherId : lgTeachers.get(lgStudent.LG__c)){
                        if(teacherUsers.containsKey(teacherId)){
                            sh2Ins.add(new ContactShare(ContactId = lgStudent.Student__c, UserOrGroupId = teacherUsers.get(teacherId).Id, ContactAccessLevel = 'Read'));
                        }
                    }
                }
                if(!franchiseeHierarchyUsers.isEmpty() && franchiseeHierarchyUsers.containsKey(lgStudent.Student__r.AccountId)){
                    for( Id uId : franchiseeHierarchyUsers.get(lgStudent.Student__r.AccountId) ){
                        sh2Ins.add(new ContactShare(ContactId = lgStudent.Student__c, UserOrGroupId = uId, ContactAccessLevel = 'Read'));
                    }
                }
                if(!ncHierarchyUsers.isEmpty() && ncHierarchyUsers.containsKey(lgStudent.Student__r.AccountId)){
                    for( Id uId : ncHierarchyUsers.get(lgStudent.Student__r.AccountId) ){
                        sh2Ins.add(new ContactShare(ContactId = lgStudent.Student__c, UserOrGroupId = uId, ContactAccessLevel = 'Read'));
                    }
                }
            }

            if(!sh2Ins.isEmpty()){
                Database.SaveResult[] newSharingData = database.insert(sh2Ins, false);
            }
        }       
        //test.stopTest();
    }

    /******************************************************************************* 
    Name              : lgDHCreateSharingRules
    Description       : Handler the sharing record of LG_Student
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             05/12/2016              Yaara                 [SW-19269]
    *******************************************************************************/

    public static void lgDHCreateSharingRules(Set<LG_Days_Hours__c> lgDHs){
        
        Set<Id> teachersIds = new Set<Id>();
        Map<Id, Set<Id>> lgTeachers = new Map<Id, Set<Id>>();

        //Get teachers from lg days n hours
        for(LG_Days_Hours__c dh : lgDHs){
            if(!lgTeachers.containsKey(dh.LG__c)){
                lgTeachers.put(dh.LG__c, new Set<Id>());
            }
            lgTeachers.get(dh.LG__c).add(dh.Teacher__c);
            teachersIds.add(dh.Teacher__c); 
            if(dh.LG__r.Teacher__c != null){                
                lgTeachers.get(dh.LG__c).add(dh.LG__r.Teacher__c);
                teachersIds.add(dh.LG__r.Teacher__c);
            }       
        }               

        //get teacher's users 
        Map<Id,User> teacherUsers = new Map<Id,User>();
        if(!teachersIds.isEmpty()){
            for(User user : [SELECT Id, ContactId FROM User WHERE ContactId IN :teachersIds]){          
                teacherUsers.put(user.ContactId, user);
            }
        }   

        Map<Id,Set<Id>> lgStudents = new Map<Id,Set<Id>>();
        for(LG_Student__c lstudent: [SELECT LG__c, Student__r.AccountId FROM LG_Student__c WHERE LG__c IN :lgTeachers.keySet()]){
            if(!lgStudents.containsKey(lstudent.LG__c)){
                lgStudents.put(lstudent.LG__c, new Set<Id>());
            }
            lgStudents.get(lstudent.LG__c).add(lstudent.Student__r.AccountId);
        }   

        /*if(!teacherUsers.isEmpty()){
            //adding share for each lgDH inserted to each teacher user
            Map<String,LG__Share> lgSh2Ins = new Map<String,LG__Share>();   
            //Map<String,LG_Days_Hours__share> accSh2Ins = new Map<String,LG_Days_Hours__share>();      
            for(Id lgId : lgTeachers.keySet()){
                for(Id teacherId : lgTeachers.get(lgId)){
                    String key = String.valueOf(lgId) + String.valueOf(teacherUsers.get(teacherId).Id);
                    if(!lgSh2Ins.containsKey(key)){
                        lgSh2Ins.put(key, new LG__Share(ParentId = lgId, UserOrGroupId = teacherUsers.get(teacherId).Id, AccessLevel = 'Edit'));
                        for(Id studentAccId : lgStudents.get(lgId)){
                            key = String.valueOf(studentAccId) + String.valueOf(teacherUsers.get(teacherId).Id);
                            //accSh2Ins.put(key, new LG_Days_Hours__share(AccountId = studentAccId, UserOrGroupId = teacherUsers.get(teacherId).Id, AccountAccessLevel = 'Read', OpportunityAccessLevel = 'None'));
                        }
                    }
                }
            }

            if(!lgSh2Ins.isEmpty()){
                Database.SaveResult[] newSharingData1 = database.insert(lgSh2Ins.values(), false);
                //Database.SaveResult[] newSharingData2 = database.insert(accSh2Ins.values(), false);
            }
        }   */  
        
    }

    /******************************************************************************* 
    Name              : PriceListAgreement_CreateSharingRules
    Description       : Handler the sharing record of Campaign
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             06/16/2016          Yaara Nadir               [SW-19960]
    *******************************************************************************/
    
    public static void PriceListAgreement_CreateSharingRules(List<Agreement__c> agrees){  
        
        Map<Id,Set<Id>> accIds = new Map<Id,Set<Id>>();
        for(Agreement__c agree : agrees){
            if(!accIds.containsKey(agree.From_Franchisee__c)){
                accIds.put(agree.From_Franchisee__c, new Set<Id>());
            }
            accIds.get(agree.From_Franchisee__c).add(agree.Price_List_Title__c);
        }   

        // Get the franchisee Hierarchy Users
        Map<String,Map<Id, Set<id>>> hierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(accIds.keySet(), true, true, false);
        Map<Id, Set<id>> franchiseeHierarchyUsers = hierarchyUsers.get('franchisee');
                
        //Map<Id, Set<id>> franchiseeHierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(accIds.keySet(), true, true);

        List<Price_List_Title__Share> sh2Ins = new List<Price_List_Title__Share>();
        for(Id accId : accIds.keySet()){
            for(Id priceListId : accIds.get(accId)){
                for( Id uId : franchiseeHierarchyUsers.get(accId) ){
                    sh2Ins.add(new Price_List_Title__Share(ParentId = priceListId, UserOrGroupId = uId, AccessLevel = 'Read'));
                }
            }
        }
        
        if(!sh2Ins.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(sh2Ins, false);
        }
    }

    /******************************************************************************* 
    Name              : Agreement_CreateSharingRules
    Description       : Handler the sharing record Agreement
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             07/25/2016          Yaara Nadir               [SW-20540]
    2. G. Fernandez             08/22/2016          Yaara Nadir               [SW-20540]
    *******************************************************************************/
    
    public static void Agreement_CreateSharingRules(List<Agreement__c> agrees){ 
        
        Map<Id,Set<Id>> franchiseeIds = new Map<Id,Set<Id>>();
        Map<Id,Set<Id>> dfranchiseeIds = new Map<Id,Set<Id>>();
        Map<Id,Set<Id>> accIds = new Map<Id,Set<Id>>();
        Map<String,Set<Id>> accByProgramType = new Map<String,Set<Id>>();
        String programTypesToQuery = '';

        for(Agreement__c agree : agrees){
            
            if(!franchiseeIds.containsKey(agree.From_Franchisee__c)){
                franchiseeIds.put(agree.From_Franchisee__c, new Set<Id>());
            }
            franchiseeIds.get(agree.From_Franchisee__c).add(agree.Id);

            if(!dfranchiseeIds.containsKey(agree.Direct_Franchisee__c)){
                dfranchiseeIds.put(agree.Direct_Franchisee__c, new Set<Id>());
            }
            dfranchiseeIds.get(agree.Direct_Franchisee__c).add(agree.Id);

            if(!accByProgramType.containsKey(agree.Program_Type__c)){
                accByProgramType.put(agree.Program_Type__c, new Set<Id>());
                programTypesToQuery += ','+agree.Program_Type__c;
            }
            accByProgramType.get(agree.Program_Type__c).add(agree.From_Franchisee__c);          
        }

        Map<String,Map<Id, Set<id>>> dhierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(dfranchiseeIds.keySet(), true, true, true);
        Map<Id, Set<id>> dfranchiseeHierarchyUsers = dhierarchyUsers.get('franchisee');
        Map<Id, Set<id>> dncHierarchyUsers = dhierarchyUsers.get('nc');

        // Get the franchisee Hierarchy Users
        Map<String,Map<Id, Set<id>>> hierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(franchiseeIds.keySet(), false, false, true);
        Map<Id, Set<id>> franchiseeHierarchyUsers = hierarchyUsers.get('franchisee');
        Map<Id, Set<id>> ncHierarchyUsers = hierarchyUsers.get('nc');

        List<Agreement__Share> sh2Ins = new List<Agreement__Share>();
        for(Agreement__c agree : agrees){
            if(!dfranchiseeHierarchyUsers.isEmpty() && dfranchiseeHierarchyUsers.containsKey(agree.Direct_Franchisee__c)){
                for( Id uId : dfranchiseeHierarchyUsers.get(agree.Direct_Franchisee__c) ){
                    sh2Ins.add(new Agreement__Share(ParentId = agree.Id, UserOrGroupId = uId, AccessLevel = 'Edit'));                   
                }
            }
            if(!dncHierarchyUsers.isEmpty() && dncHierarchyUsers.containsKey(agree.Direct_Franchisee__c)){
                for( Id uId : dncHierarchyUsers.get(agree.Direct_Franchisee__c) ){
                    sh2Ins.add(new Agreement__Share(ParentId = agree.Id, UserOrGroupId = uId, AccessLevel = 'Read'));                   
                }
            }
            if(!franchiseeHierarchyUsers.isEmpty() && franchiseeHierarchyUsers.containsKey(agree.From_Franchisee__c)){
                for( Id uId : franchiseeHierarchyUsers.get(agree.From_Franchisee__c) ){
                    sh2Ins.add(new Agreement__Share(ParentId = agree.Id, UserOrGroupId = uId, AccessLevel = 'Read'));                   
                }
            }
            if(!ncHierarchyUsers.isEmpty() && ncHierarchyUsers.containsKey(agree.From_Franchisee__c)){
                for( Id uId : ncHierarchyUsers.get(agree.From_Franchisee__c) ){
                    sh2Ins.add(new Agreement__Share(ParentId = agree.Id, UserOrGroupId = uId, AccessLevel = 'Read'));                   
                }
            }
        }

        //group users under franchise to give share 
        Map<Id,Set<Id>> usersUnderFranchisee = new Map<Id,Set<Id>>();
        for(User u : [SELECT Id, AccountId FROM User WHERE AccountId IN :franchiseeIds.keySet() ]){
            if(!usersUnderFranchisee.containsKey(u.AccountId)){
                usersUnderFranchisee.put(u.AccountId,new Set<Id>());
            }
            usersUnderFranchisee.get(u.AccountId).add(u.Id);

            if(franchiseeHierarchyUsers.containsKey(u.AccountId)){
                for(Id uId : franchiseeHierarchyUsers.get(u.AccountId)){
                    usersUnderFranchisee.get(u.AccountId).add(uId);
                }
            }
        }

        List<Base_Course__Share> baseCourseShares2Ins = new List<Base_Course__Share>();
        List<Seminar_Type__Share> stShares2Ins = new List<Seminar_Type__Share>();

        if(!usersUnderFranchisee.isEmpty() && !String.isEmpty(programTypesToQuery)){
            programTypesToQuery = programTypesToQuery.substring(1);

            //Read permissions on Base Course with the same Program Type
            for(Base_Course__c bCourse : [SELECT Id, Name, Program_Type__c FROM Base_Course__c WHERE Status__c = 'Active' AND Program_Type__c INCLUDES (:programTypesToQuery)]){
                
                String[] programs = bCourse.Program_Type__c.split(';'); 
                for (String program : programs) {
                    //for each account with an agreement = program type
                    if(accByProgramType.containsKey(program)){
                        for(Id accId : accByProgramType.get(program)){
                            if(usersUnderFranchisee.containsKey(accId)){
                                for (Id uId : usersUnderFranchisee.get(accId)) {
                                    baseCourseShares2Ins.add(new Base_Course__Share(ParentId = bCourse.Id, UserOrGroupId = uId, AccessLevel = 'Read'));         
                                }
                            }   
                        }
                    }
                }
            }

            //TTC/Seminar Type with the same Program Type
            for(Seminar_Type__c st : [SELECT Id, Program_Type__c, Name FROM Seminar_Type__c WHERE Active__c = true AND Program_Type__c INCLUDES (:programTypesToQuery)]){
                String[] programs = st.Program_Type__c.split(';');  
                for (String program : programs) {       
                    //for each account with an agreement = program type
                    if(accByProgramType.containsKey(program)){
                        for(Id accId : accByProgramType.get(program)){
                            //for each user in account
                            if(usersUnderFranchisee.containsKey(accId)){
                                for (Id uId : usersUnderFranchisee.get(accId)) {
                                    stShares2Ins.add(new Seminar_Type__Share(ParentId = st.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
                                }
                            }
                        }
                    }
                }
            }   
        }

        if(!sh2Ins.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(sh2Ins, false);
        }

        if(!baseCourseShares2Ins.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(baseCourseShares2Ins, false);
        }

        if(!stShares2Ins.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(stShares2Ins, false);
        }
    }

    /******************************************************************************* 
    Name              : SeminarDeleteManualSharing
    Description       : Handler the sharing record of Seminar__c object
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             07/19/2016              Yaara               SW-20471
    2. G. Fernandez             12/15/2016              Ella                SW-22711
    *******************************************************************************/
    
    public static void SeminarDeleteManualSharing(List<Seminar__c> seminarCancelled){        

        if (!seminarCancelled.isEmpty()) {
            Map<Id,Set<Seminar__Share>> shares = new Map<Id,Set<Seminar__Share>>();

            Map<Id,Id> notDeleteTrainer = new Map<Id,Id>();
            Set<Id> seminarCancelledIds = new Set<Id>();
            for (Seminar__c seminar : seminarCancelled) {
                seminarCancelledIds.add(seminar.Id);
                notDeleteTrainer.put(seminar.Id, seminar.Teacher_Trainer__c);
            }
            
            //getting shares on canceled seminars
            for(Seminar__Share sShare : [SELECT Id, UserOrGroupId, ParentId FROM Seminar__Share WHERE ParentId IN :seminarCancelledIds AND RowCause = 'Manual']){
                if (!shares.containsKey(sShare.UserOrGroupId)) {
                    shares.put(sShare.UserOrGroupId, new Set<Seminar__Share>());                        
                }                   
                shares.get(sShare.UserOrGroupId).add(sShare);
            }

            //getting contact from users with share
            Map<Id,Id> contactUser = new Map<Id,Id>();
            for(User u : [SELECT ContactId FROM User WHERE Id IN :shares.keySet() OR ContactId IN :notDeleteTrainer.values()]){
                contactUser.put(u.ContactId, u.Id);
            }

            //avoid to delete seminar teachers
            for(Seminar_Teachers__c st : [SELECT Id, Teacher__r.Contact_Partner_User__c, Seminar__c, Seminar__r.Hosting_Franchisee__r.Partner_Account_User__c, Teacher_Status_in_seminar__c FROM Seminar_Teachers__c WHERE (Teacher_Status_in_seminar__c = 'Registered' AND Teacher__r.Contact_Partner_User__c IN :shares.keySet()) OR Seminar__r.Hosting_Franchisee__r.Partner_Account_User__c IN :shares.keySet()]){
                if(shares.containsKey(st.Seminar__r.Hosting_Franchisee__r.Partner_Account_User__c)){
                    Set<Seminar__Share> sSet = shares.get(st.Seminar__r.Hosting_Franchisee__r.Partner_Account_User__c);
                    Set<Seminar__Share> sSet2 = new Set<Seminar__Share>();
                    for (Seminar__Share sShare : sSet) {                    
                        if(sShare.ParentId != st.Seminar__c){
                            sSet2.add(sShare);
                        }                        
                    }
                    shares.put(st.Seminar__r.Hosting_Franchisee__r.Partner_Account_User__c, sSet2);
                }

                if(shares.containsKey(st.Teacher__r.Contact_Partner_User__c) && st.Teacher_Status_in_seminar__c == 'Registered'){
                    Set<Seminar__Share> sSet = shares.get(st.Teacher__r.Contact_Partner_User__c);
                    Set<Seminar__Share> sSet2 = new Set<Seminar__Share>();
                    for (Seminar__Share sShare : sSet) {                    
                        if(sShare.ParentId != st.Seminar__c){
                            sSet2.add(sShare);
                        }                        
                    }
                    shares.put(st.Teacher__r.Contact_Partner_User__c, sSet2);
                }

            }

            //avoid to delete teacher trainers
            for (Id sId : notDeleteTrainer.keySet()) {
                Id teacherTrainerId = notDeleteTrainer.get(sId);
                Id uId = contactUser.get(teacherTrainerId);
                //check teacher trainer shares
                if(shares.containsKey(uId)){
                    Set<Seminar__Share> sSet = shares.get(uId);
                    Set<Seminar__Share> sSet2 = new Set<Seminar__Share>();
                    for(Seminar__Share ss : sSet){
                        Boolean cond = notDeleteTrainer.containsKey(ss.ParentId);

                        if(cond){
                            Id tId = notDeleteTrainer.get(ss.ParentId);
                            cond = teacherTrainerId==tId;
                        }

                        //only delete shares were he isnt trainer
                        if(!cond){
                            sSet2.add(ss);
                        }
                    }
                    shares.put(uId, sSet2);
                }
            }

            List<Seminar__Share> shares2del = new List<Seminar__Share>();
            for (Id uId : shares.keySet()) {
                shares2del.addAll(shares.get(uId));
            }

            /*for(User u : [SELECT UserType FROM User WHERE UserType='PowerPartner' AND Id IN :shares.keySet()]){
                shares2del.addAll(shares.get(u.Id));
            }*/

            if(!shares2del.isEmpty()){
                Database.DeleteResult[] delSharingResult = Database.delete(shares2del, false);          
            }
        }
    }
    

    /******************************************************************************* 
    Name              : Seminar_HostFranchiseeCreateSharingRules
    Description       : Handler the sharing record of Seminar ttc
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             06/22/2016              Yaara               SW-20017
    *******************************************************************************/
    
    public static void Seminar_HostFranchiseeCreateSharingRules(Map<Id,Set<Seminar__c>> hostFranchisees){       

        List<Seminar__Share> sh2Ins = new List<Seminar__Share>();
        //1. If the owner is not the Hosting Franchisee.Partner Account User – Give R/W permission to that user.
        if (!hostFranchisees.isEmpty()) {
            Map<Id,Id> accUser = new Map<Id,Id>();  
            for (Account acc : [SELECT Partner_Account_User__c FROM Account WHERE Id IN :hostFranchisees.keySet()]) {
                accUser.put(acc.Id,acc.Partner_Account_User__c);
            }
            
            Map<Id, Set<id>> ncHierarchyUsers = MonitorRecursionClass.getfranchiseeNCHierarchyUsers(hostFranchisees.keySet());
            
            for(Id hFranchiseeId : hostFranchisees.keySet()){
                for(Seminar__c sem : hostFranchisees.get(hFranchiseeId)){
                    Id userId = accUser.get(sem.Hosting_Franchisee__c);
                    if (userId != sem.OwnerId) {
                        sh2Ins.add(new Seminar__Share(ParentId = sem.Id, UserOrGroupId = userId, AccessLevel = 'Edit'));
                        if(!ncHierarchyUsers.isEmpty()){
                            for(Id uId : ncHierarchyUsers.get(hFranchiseeId)){
                                sh2Ins.add(new Seminar__Share(ParentId = sem.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
                            }                       
                        }
                    }                   
                }
            }       
        
            if(!sh2Ins.isEmpty()){
                Database.SaveResult[] newSharingData = database.insert(sh2Ins, false);
            }
        }
    }

    /******************************************************************************* 
    Name              : Seminar_TypesCreateSharingRules
    Description       : Handler the sharing record of Seminar ttc
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             06/22/2016              Yaara               SW-20017
    2. G. Fernandez             05/21/2017              Yaara               SW-24965
    *******************************************************************************/
    
    public static void Seminar_TypesCreateSharingRules(Map<Id,Set<Seminar__c>> seminarTypes){   

        List<Seminar__Share> sh2Ins = new List<Seminar__Share>();
        Map<Id, Set<Id>> sh2check = new Map<Id, Set<Id>>();
        /*2. Status Confirmed: Give read permission on the TTC/Seminar to all Partner users  that have read permission to the TTC/Seminar.Seminar Type.
        Except (additional logic) : 
            (a) TTC/Seminar. Hosting Franchise. Partner Account User (already have R/W Permissions from #1) 
            (b) TTC/Seminar. Teacher Trainer (already gets R/W permissions from #3) 
        */
        if (!seminarTypes.isEmpty()) {
            Map<Id,Seminar_Type__Share> stsIds = new Map<Id,Seminar_Type__Share>();
            for (List<Seminar_Type__Share> liststs : [SELECT UserOrGroupId, ParentId FROM Seminar_Type__Share WHERE ParentId IN :seminarTypes.keySet() AND AccessLevel = 'Read']) {
                for (Seminar_Type__Share sts : liststs) {
                    stsIds.put(sts.UserOrGroupId, sts);
                }
            }

            Set<Id> hostIds = new Set<Id>();
            for (Id stId : seminarTypes.keySet()) {
                for (Seminar__c sem : seminarTypes.get(stId)) {
                    hostIds.add(sem.Hosting_Franchisee__c);
                }
            }

            Map<Id,Id> hostUserIds = new Map<Id,Id>();
            for(List<Account> lacc :[SELECT Partner_Account_User__c FROM Account WHERE Id IN :hostIds]){
                for(Account acc : lacc){
                    hostUserIds.put(acc.Id,acc.Partner_Account_User__c);
                }
            }

            Map<Id,Id> accIds = new Map<Id,Id>();
            Map<Id,Id> conUserIds = new Map<Id,Id>();
            for(List<User> lu :[SELECT AccountId, ContactId FROM User WHERE Id IN :stsIds.keySet() OR AccountId =:hostIds]){
                for(User u : lu){
                    accIds.put(u.Id,u.AccountId);
                    conUserIds.put(u.ContactId,u.Id);
                }
            }

            /*Set<Id> accIdset = new Set<Id>();
            accIdset.addAll(accIds.values());
            Map<Id, Set<id>> ncHierarchyUsers = MonitorRecursionClass.getfranchiseeNCHierarchyUsers(accIdset);*/

            for (Seminar_Type__Share sts : stsIds.values()) {
                for (Seminar__c sem : seminarTypes.get(sts.ParentId)) {

                    Id tId = null;
                    if (conUserIds.containsKey(sem.Teacher_Trainer__c)) {
                        tId = conUserIds.get(sem.Teacher_Trainer__c); 
                    }
                    Id hId = null;
                    if (hostUserIds.containsKey(sem.Hosting_Franchisee__c)) {
                        hId = hostUserIds.get(sem.Hosting_Franchisee__c);
                    }

                    if (!sh2check.containsKey(sem.Id)) {
                        sh2check.put(sem.Id, new Set<Id>()); 
                    }

                    if(tId != sts.UserOrGroupId && hId != sts.UserOrGroupId){
                        sh2Ins.add(new Seminar__Share(ParentId = sem.Id, UserOrGroupId = sts.UserOrGroupId, AccessLevel = 'Read'));
                        sh2check.get(sem.Id).add(sts.UserOrGroupId);
                    }
                    
                    /*Id accId = accIds.get(sts.UserOrGroupId);
                    if(!ncHierarchyUsers.isEmpty() && ncHierarchyUsers.containsKey(accId)){
                        for(Id uId : ncHierarchyUsers.get(accId)){
                            sh2Ins.add(new Seminar__Share(ParentId = sem.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
                            sh2check.get(sem.Id).add(sts.UserOrGroupId);
                        }                       
                    }*/
                }
            }
        }

        if(!sh2Ins.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(sh2Ins, false);
        }

        /*if(!sh2Ins.isEmpty()){
            List<Seminar__Share> ssh2Ins = new List<Seminar__Share>();
            Map<Id, Set<Id>> ssh2check = new Map<Id, Set<Id>>();

            //looking and mapping existent shares
            for(List<Seminar__Share> lss : [SELECT ParentId, UserOrGroupId FROM Seminar__Share WHERE ParentId IN :sh2check.keySet()]){
                for (Seminar__Share ss : lss) {
                    if (!ssh2check.containsKey(ss.ParentId)) {
                        ssh2check.put(ss.ParentId, new Set<Id>()); 
                    }
                    ssh2check.get(ss.ParentId).add(ss.UserOrGroupId);
                }
            }

            //filtering already existent shares
            for (Seminar__Share seminar2share : sh2Ins) { 
                //checking for each user  
                for (Id user2share : sh2check.get(seminar2share.ParentId)) {  
                    //if already have sharing 
                    if(!ssh2check.get(seminar2share.ParentId).contains(user2share)){
                        ssh2Ins.add(seminar2share);
                    }
                }
            }

            if(!ssh2Ins.isEmpty()){
                Database.SaveResult[] newSharingData = database.insert(ssh2Ins, false);
            }
        }*/
    }

    /******************************************************************************* 
    Name              : Seminar_TeacherTrainersCreateSharingRules
    Description       : Handler the sharing record of Seminar ttc
    Revision History  :- 
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             06/22/2016              Yaara               SW-20017
    2. G. Fernandez             06/22/2016              Yaara               SW-20017
    3. G. Fernandez             12/15/2016              Ella                SW-22711
    *******************************************************************************/
    
    public static void Seminar_TeacherTrainersCreateSharingRules(Map<Id,Set<Seminar__c>> seminarTeacherTrainers){

        List<Seminar__Share> sh2Ins = new List<Seminar__Share>();

        if (!seminarTeacherTrainers.isEmpty()) {
            Map<Id,Id> conUser = new Map<Id,Id>();
            for (Contact c : [SELECT Id, Contact_Partner_User__c FROM Contact WHERE Id IN :seminarTeacherTrainers.keySet()]) {
                conUser.put(c.Id, c.Contact_Partner_User__c);
            }

            for(Id seminarTeacherId : seminarTeacherTrainers.keySet()){
                for(Seminar__c sem : seminarTeacherTrainers.get(seminarTeacherId)){
                    Id userId = conUser.get(seminarTeacherId);
                    sh2Ins.add(new Seminar__Share(ParentId = sem.Id, UserOrGroupId = userId, AccessLevel = 'Edit'));
                }
            }
        }
        
        if(!sh2Ins.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(sh2Ins, false);
        }
    }

    /******************************************************************************* 
    Name              : Seminar_TeacherTrainersDeleteSharingRules
    Description       : delete old teacher sharing 
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             06/22/2016              Yaara               SW-20017
    2. G. Fernandez             22/12/2016              Yaara               SW-22711
    *******************************************************************************/
    
    public static void Seminar_TeacherTrainersDeleteSharingRules(Map<Id,Set<Seminar__c>> seminarTeacherTrainers){

        Set<Id> seminars = new Set<Id>();
        Map<Id,Set<Id>> teacherAndSeminars = new Map<Id,Set<Id>>();

        //get users from teacher contact
        Map<Id,Id> accIds = new Map<Id,Id>();
        Map<Id,Id> userCon = new Map<Id,Id>();  
        for (User u : [SELECT Id, ContactId, AccountId FROM User WHERE ContactId IN :seminarTeacherTrainers.keySet()]) {
            userCon.put(u.Id,u.ContactId);
        }

        //put all seminars together
        for (Id teacherId : seminarTeacherTrainers.keySet()) {
            if(!teacherAndSeminars.containsKey(teacherId)){
                teacherAndSeminars.put(teacherId, new Set<Id>());
            }
            for (Seminar__c seminar : seminarTeacherTrainers.get(teacherId)) {
                seminars.add(seminar.Id);
                teacherAndSeminars.get(teacherId).add(seminar.Id);
            }
        }

        //delete shares on seminar for teacher trainers
        List<Seminar__Share> shares2del = new List<Seminar__Share>();
        for (Seminar__Share sShare : [SELECT ParentId, UserOrGroupId FROM Seminar__Share WHERE UserOrGroupId IN :userCon.keySet() AND ParentId IN :seminars AND RowCause = 'Manual']) {
            Id contactId = userCon.get(sShare.UserOrGroupId);
            Set<Id> teachertrainerSeminars = teacherAndSeminars.get(contactId);
            if(teachertrainerSeminars.contains(sShare.ParentId)){
                sShare.AccessLevel = 'Read';
                shares2del.add(sShare);
            }
        }

        Map<Id,Set<Id>> teacherAndteachers = new Map<Id,Set<Id>>();
        Map<Id,Id> teachers = new Map<Id,Id>();
        for (Seminar_Teachers__c st : [SELECT Id, Seminar__r.Teacher_Trainer__c, Teacher__c FROM Seminar_Teachers__c WHERE Seminar__c IN :seminars]) {
            teachers.put(st.Id, st.Teacher__c);
            Id teacherId = st.Seminar__r.Teacher_Trainer__c;
            //grouping teachers by teacher trainers
            if(!teacherAndteachers.containsKey(teacherId)){
                teacherAndteachers.put(teacherId, new Set<Id>());
            }
            teacherAndteachers.get(teacherId).add(st.Teacher__c);
        }

        //delete shares on teachers for teacher trainers
        List<Seminar_Teachers__Share> tshares2del= new List<Seminar_Teachers__Share>();
        for (Seminar_Teachers__Share sShare : [SELECT ParentId, Parent.Teacher__c, UserOrGroupId, AccessLevel FROM Seminar_Teachers__Share WHERE ParentId IN :teachers.keySet() AND UserOrGroupId IN :userCon.keySet() AND RowCause = 'Manual']) {
            Id contactId = userCon.get(sShare.UserOrGroupId);
            Set<Id> teacherInSeminars = teacherAndteachers.get(contactId);
            if(teacherInSeminars.contains(sShare.Parent.Teacher__c)){
                tshares2del.add(sShare);
            }
        }

        //delete shares on teachers contacts for teacher trainers
        List<ContactShare> cshares2del= new List<ContactShare>();
        for (ContactShare sShare : [SELECT Id, ContactId, UserOrGroupId FROM ContactShare WHERE ContactId IN :teachers.values() AND UserOrGroupId IN :userCon.keySet() AND RowCause = 'Manual']) {
            Id contactId = userCon.get(sShare.UserOrGroupId);
            Set<Id> teacherInSeminars = teacherAndteachers.get(contactId);
            if(teacherInSeminars.contains(sShare.ContactId)){
                cshares2del.add(sShare);
            }
        }
    
        if(!shares2del.isEmpty()){
            database.update(shares2del, false);
        }

        if(!tshares2del.isEmpty()){
            database.delete(tshares2del, false);
        }

        if(!cshares2del.isEmpty()){
            database.delete(cshares2del, false);
        }
    }

    /******************************************************************************* 
    Name              : Lead_CreateSharingRules
    Description       : Handler the sharing record of Lead
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             06/22/2016              Yaara               SW-20031
    *******************************************************************************/
    
    public static void Lead_CreateSharingRules(List<Lead> leads){

        List<Id> ownerIds = new List<Id>();
        for (Lead l : leads) {
             ownerIds.add(l.OwnerId);
        }

        Set<Id> accIds = new Set<Id>();
        Map<Id,Id> accUsers = new Map<Id,Id>();
        for(User u : [SELECT AccountId FROM User WHERE Id IN :ownerIds]){
            accIds.add(u.AccountId);
            accUsers.put(u.Id, u.AccountId);
        }

        // Get the franchisee Hierarchy Users
        Map<String,Map<Id, Set<id>>> allhierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(accIds, true, true, true);
        Map<Id, Set<id>> hierarchyUsers = allhierarchyUsers.get('franchisee');
        Map<Id, Set<id>> ncHierarchyUsers = allhierarchyUsers.get('nc');

        /*Map<Id, Set<id>> hierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(accIds, true, true);
        Map<Id, Set<id>> ncHierarchyUsers = MonitorRecursionClass.getfranchiseeNCHierarchyUsers(accIds);*/
        
        List<LeadShare> sh2Ins = new List<LeadShare>();
        for(Lead l : leads){
            Id accId = accUsers.get(l.OwnerId);
            if(!hierarchyUsers.isEmpty()){
                for(Id uId : hierarchyUsers.get(accId)){
                    sh2Ins.add(new LeadShare(LeadId = l.Id, UserOrGroupId = uId, LeadAccessLevel = 'Edit'));                    
                }
            }
            if(!ncHierarchyUsers.isEmpty()){
            for(Id uId : ncHierarchyUsers.get(accId)){
                    sh2Ins.add(new LeadShare(LeadId = l.Id, UserOrGroupId = uId, LeadAccessLevel = 'Read'));                    
                }
            }
        }
        
        if(!sh2Ins.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(sh2Ins, false);
        }
    }

    /******************************************************************************* 
    Name              : teacherAgreement_CreateSharingRules
    Description       : Handler the sharing record of Teacher Agreement
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             06/22/2016              Yaara               SW-20017
    *******************************************************************************/
    
    public static void teacherAgreement_CreateSharingRules(List<Teacher_Agreement__c> tAgreements){

        List<Id> teachers = new List<Id>();
        for (Teacher_Agreement__c tAgreement : tAgreements) {
            teachers.add(tAgreement.Teacher__c);
        }

        Map<Id,Id> teacherUser = new Map<Id,Id>();  
        for (User u : [SELECT Id, ContactId FROM User WHERE ContactId IN :teachers]) {
            teacherUser.put(u.ContactId, u.Id);
        }

        List<Teacher_Agreement__Share> sh2Ins = new List<Teacher_Agreement__Share>();
        for(Teacher_Agreement__c tAgreement : tAgreements){
            sh2Ins.add(new Teacher_Agreement__Share(ParentId = tAgreement.Id, UserOrGroupId = teacherUser.get(tAgreement.Teacher__c), AccessLevel = 'Read'));                   
        }
        
        if(!sh2Ins.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(sh2Ins, false);
        }
    }

    /******************************************************************************* 
    Name              : HolidayVacation_CreateSharingRules
    Description       : Handler the sharing record of Holiday_Vacation__c
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             05/13/2016          Yaara Nadir               [SW-19266]
    *******************************************************************************/
    
    public static void HolidayVacation_CreateSharingRules(List<Holiday_Vacation__c> holidays){  

        Id countryType = Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('Country').getRecordTypeId();
        Id mfType = Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('MF').getRecordTypeId();
        Id lcType = Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('LC').getRecordTypeId();

        Id studentType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId();

        //map owner,holidays 
        Set<Id> ownerIds = new Set<Id>();
        Map<String,List<Holiday_Vacation__c>> holidayLCMap = new Map<String,List<Holiday_Vacation__c>>();
        Map<String,List<Holiday_Vacation__c>> holidayMFMap = new Map<String,List<Holiday_Vacation__c>>();
        Map<String,List<Holiday_Vacation__c>> holidayCountryMap = new Map<String,List<Holiday_Vacation__c>>();
        for(Holiday_Vacation__c holiday : holidays){
            //looking users for sharing according hierarchy
            ownerIds.add(holiday.OwnerId);

            //collecting filters to get users for sharing according to recordtype           
            if(holiday.RecordTypeId == lcType && holiday.LC__c != null){
                if(!holidayLCMap.containsKey(holiday.LC__c)){
                    holidayLCMap.put(holiday.LC__c, new List<Holiday_Vacation__c>());
                }
                holidayLCMap.get(holiday.LC__c).add(holiday);
            }else if(holiday.RecordTypeId == mfType && holiday.MF__c != null){
                if(!holidayMFMap.containsKey(holiday.MF__c)){
                    holidayMFMap.put(holiday.MF__c, new List<Holiday_Vacation__c>());
                }
                holidayMFMap.get(holiday.MF__c).add(holiday);
            }else if(holiday.RecordTypeId == countryType && holiday.Country__c != null){
                if(!holidayCountryMap.containsKey(holiday.Country__c)){
                    holidayCountryMap.put(holiday.Country__c, new List<Holiday_Vacation__c>());
                }                   
                holidayCountryMap.get(holiday.Country__c).add(holiday);
            }           
        }

        Map<Id,Set<Id>> relatedContactIds = new Map<Id,Set<Id>>();

        /* SW-24758 - Direct Franchisee*/
        for(Contact contact2share : [SELECT Id, AccountId, MailingCountry, Direct_Franchisee__c, Account.ParentId FROM Contact WHERE ( MailingCountry IN :holidayCountryMap.keySet() 
                                        //OR Direct_Franchisee__c IN :holidayMFMap.keySet() OR Direct_Franchisee__c IN :holidayLCMap.keySet()
                                        OR AccountId IN :holidayMFMap.keySet() OR AccountId IN :holidayLCMap.keySet()
                                        OR Account.ParentId IN :holidayMFMap.keySet() OR Account.ParentId IN :holidayLCMap.keySet() ) 
                                        AND RecordTypeId != :studentType] ){

            //grouping contact in countrysm LC, MF and country
            if(!holidayLCMap.isEmpty() && holidayLCMap.containsKey(contact2share.AccountId) ){
                for(Holiday_Vacation__c holiday : holidayLCMap.get(contact2share.AccountId)){
                    if(!relatedContactIds.containsKey(contact2share.Id)){
                        relatedContactIds.put(contact2share.Id, new Set<Id>());
                    }
                    relatedContactIds.get(contact2share.Id).add(holiday.Id);
                }
            }
            /*if(!holidayLCMap.isEmpty() && holidayLCMap.containsKey(contact2share.Direct_Franchisee__c)){
                for(Holiday_Vacation__c holiday : holidayLCMap.get(contact2share.Direct_Franchisee__c)){
                    if(!relatedContactIds.containsKey(contact2share.Id)){
                        relatedContactIds.put(contact2share.Id, new Set<Id>());
                    }
                    relatedContactIds.get(contact2share.Id).add(holiday.Id);
                }
            }*/
            if(!holidayLCMap.isEmpty() && holidayLCMap.containsKey(contact2share.Account.ParentId)){
                for(Holiday_Vacation__c holiday : holidayLCMap.get(contact2share.Account.ParentId)){
                    if(!relatedContactIds.containsKey(contact2share.Id)){
                        relatedContactIds.put(contact2share.Id, new Set<Id>());
                    }
                    relatedContactIds.get(contact2share.Id).add(holiday.Id);
                }
            }

            if(!holidayMFMap.isEmpty() && holidayMFMap.containsKey(contact2share.AccountId) ){
                for(Holiday_Vacation__c holiday : holidayMFMap.get(contact2share.AccountId)){
                    if(!relatedContactIds.containsKey(contact2share.Id)){
                        relatedContactIds.put(contact2share.Id, new Set<Id>());
                    }
                    relatedContactIds.get(contact2share.Id).add(holiday.Id);
                }
            }
            /*if(!holidayMFMap.isEmpty() && holidayMFMap.containsKey(contact2share.Direct_Franchisee__c) ){
                for(Holiday_Vacation__c holiday : holidayMFMap.get(contact2share.Direct_Franchisee__c)){
                    if(!relatedContactIds.containsKey(contact2share.Id)){
                        relatedContactIds.put(contact2share.Id, new Set<Id>());
                    }
                    relatedContactIds.get(contact2share.Id).add(holiday.Id);
                }
            }*/
            if(!holidayMFMap.isEmpty() && holidayMFMap.containsKey(contact2share.Account.ParentId) ){
                for(Holiday_Vacation__c holiday : holidayMFMap.get(contact2share.Account.ParentId)){
                    if(!relatedContactIds.containsKey(contact2share.Id)){
                        relatedContactIds.put(contact2share.Id, new Set<Id>());
                    }
                    relatedContactIds.get(contact2share.Id).add(holiday.Id);
                }
            }

            if(!holidayCountryMap.isEmpty() && holidayCountryMap.containsKey(contact2share.MailingCountry) ){
                for(Holiday_Vacation__c holiday : holidayCountryMap.get(contact2share.MailingCountry)){
                    if(!relatedContactIds.containsKey(contact2share.Id)){
                        relatedContactIds.put(contact2share.Id, new Set<Id>());
                    }
                    relatedContactIds.get(contact2share.Id).add(holiday.Id);
                }
            }
        }

        System.debug('relatedContactIds ' + relatedContactIds);


        Map<Id,Id> holidayAccIds = new Map<Id,Id>();
        Map<Id,Set<Id>> relatedUserIds = new Map<Id,Set<Id>>();
        Set<Id> relatedUserIdSet = new Set<Id>();
        //get teacher/owners users to give share
        for(User u : [SELECT AccountId, Contact.AccountId, ContactId FROM User WHERE Id IN : ownerIds OR ContactId IN : relatedContactIds.keySet()]){
            System.debug('u ' + u);
            if(ownerIds.contains(u.Id)){
                holidayAccIds.put(u.Id, u.Contact.AccountId);
            }else if(relatedContactIds.containsKey(u.ContactId)){
                for(Id holidayId : relatedContactIds.get(u.ContactId)){
                    if(!relatedUserIds.containsKey( holidayId) ){
                        relatedUserIds.put( holidayId , new Set<Id>());
                    }
                    relatedUserIds.get( holidayId ).add(u.Id);
                    relatedUserIdSet.add(u.Contact.AccountId);
                }
            }
        }

        //merge both sets of users for each holiday
        Set<Id> holidayAccSetId = new Set<Id>(holidayAccIds.values());  
        holidayAccSetId.addAll(relatedUserIdSet);

        System.debug('holidayAccSetId ' + holidayAccSetId);

        // Get the franchisee Hierarchy Users
        Map<String,Map<Id, Set<id>>> hierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(holidayAccSetId, true, true, false);
        Map<Id, Set<id>> franchiseeHierarchyUsers = hierarchyUsers.get('franchisee');
                    
        //Map<Id, Set<id>> franchiseeHierarchyUsers = MonitorRecursionClass.getfranchiseeHierarchyUsersCache(holidayAccSetId, true, true);

        List<Holiday_Vacation__Share> share2Ins = new List<Holiday_Vacation__Share>();
        
        if(!franchiseeHierarchyUsers.isEmpty() || !relatedUserIds.isEmpty()){
            for(Holiday_Vacation__c holiday : holidays){
                Id accId = holidayAccIds.get(holiday.OwnerId);
                if(franchiseeHierarchyUsers.containsKey(accId)){
                    for( Id uId : franchiseeHierarchyUsers.get(accId) ){
                        Holiday_Vacation__Share hvs = new Holiday_Vacation__Share(ParentId = holiday.Id, UserOrGroupId = uId, AccessLevel = 'Edit');
                        if(relatedUserIds.containsKey(holiday.Id)){
                            hvs.AccessLevel = 'Read';
                        }
                        share2Ins.add(hvs);
                    }
                }
                if(relatedUserIds.containsKey(holiday.Id)){
                    for( Id uId : relatedUserIds.get(holiday.Id) ){
                        share2Ins.add(new Holiday_Vacation__Share(ParentId = holiday.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
                    }
                }
            }
        }
        
        if(!share2Ins.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(share2Ins, false);
            system.debug('newSharingData: ' + newSharingData);
        }
    }


    /******************************************************************************* 
    Name              : Account_CreateNCSharingRules
    Description       : when nc changes on account, give share to the new nc user
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             16/01/2016              Yaara                 [SW-23253]
    *******************************************************************************/
    public static void Account_CreateNCSharingRules(Map<Id,Id> accNcIds){
        
        Id mcTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();
        Id lcsetlsfTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId();
        
        /*
        1.1.1 Accounts
        */
        List<AccountShare> acc2sh = new List<AccountShare>();
        for(Id accId : accNcIds.keySet()){
            Id uId = accNcIds.get(accId);
            //1.1.1.1 Read Permissions on the Account where Account. Partner Account NC is updated
            acc2sh.add(new AccountShare(AccountId = accId, UserOrGroupId = uId, AccountAccessLevel = 'Read', OpportunityAccessLevel = 'None', ContactAccessLevel = 'None', CaseAccessLevel = 'None'));
        }

        Map<Id,Id> accChilds = new Map<Id,Id>();
        Map<Id,Id> mapLCAccChilds = new Map<Id,Id>();
        //1.1.1.2 Read permission on all the children accounts of that account
        for (Account childAccount : [SELECT Id, ParentId, RecordTypeId, Partner_Account_User__c FROM Account WHERE ParentId IN :accNcIds.keySet()]) {
            Id uId = accNcIds.get(childAccount.ParentId);
            accChilds.put(childAccount.Id,childAccount.ParentId);
            acc2sh.add(new AccountShare(AccountId = childAccount.Id, UserOrGroupId = uId, AccountAccessLevel = 'Read', OpportunityAccessLevel = 'None', ContactAccessLevel = 'None', CaseAccessLevel = 'None'));
            
            if(childAccount.RecordTypeId == lcsetlsfTypeId){
                mapLCAccChilds.put(childAccount.Partner_Account_User__c, childAccount.Id);
            }
        }

        Map<Id,Id> accPartnerUsers = new Map<Id,Id>();
        for (Account acc : [SELECT Id, Partner_Account_User__c FROM Account WHERE Id IN :accNcIds.keySet()]) {
            accPartnerUsers.put(acc.Partner_Account_User__c,acc.Id);
        }
        
        if(!acc2sh.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(acc2sh, false);
            system.debug('newSharingData: ' + newSharingData);
        }

        /*
        1.1.2 Agreements 
        */
        
        List<Agreement__Share> agreements2sh = new List<Agreement__Share>();
        for(Agreement__c agree : [SELECT From_Franchisee__c, Program_Type__c FROM Agreement__c WHERE From_Franchisee__c IN :accNcIds.keySet() OR From_Franchisee__c IN :accChilds.keySet()]){
            //1.1.2.1 Read Permissions on the Agreements where Account. Partner Account NC is the From Franchise/
            if(accNcIds.containsKey(agree.From_Franchisee__c)){
                Id uId = accNcIds.get(agree.From_Franchisee__c);
                agreements2sh.add(new Agreement__Share(ParentId = agree.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
            }

            //1.1.2.2 Read permission on all the children agreements
            if(accChilds.containsKey(agree.From_Franchisee__c)){
                Id parentId = accChilds.get(agree.From_Franchisee__c);
                Id uId = accNcIds.get(parentId);
                agreements2sh.add(new Agreement__Share(ParentId = agree.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
            }                 
        }

        if(!agreements2sh.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(agreements2sh, false);
            system.debug('newSharingData: ' + newSharingData);
        }

        /*
        1.1.3 Contacts
        */

        List<ContactShare> contact2sh = new List<ContactShare>();
        for(Contact contact: [SELECT AccountId, Id FROM Contact WHERE AccountId IN :accNcIds.keySet() OR AccountId IN :accChilds.keySet()]){
            //1.1.3.1 Read Permissions on all the Contact related to the Account where Account. Partner Account NC is updated
            if(accNcIds.containsKey(contact.AccountId)){
                Id uId = accNcIds.get(contact.AccountId);
                contact2sh.add(new ContactShare(ContactId = contact.Id, UserOrGroupId = uId, ContactAccessLevel = 'Read'));
            }

            //1.1.3.2 Read permission on all the contact of the children accounts of that account
            if(accChilds.containsKey(contact.AccountId)){
                Id parentId = accChilds.get(contact.AccountId);
                Id uId = accNcIds.get(parentId);
                contact2sh.add(new ContactShare(ContactId = contact.Id, UserOrGroupId = uId, ContactAccessLevel = 'Read'));
            }                 
        }

        if(!contact2sh.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(contact2sh, false);
            system.debug('newSharingData: ' + newSharingData);
        }


        /*
        1.1.4 Base Course
        */

        List<Base_Course__Share> bc2sh = new List<Base_Course__Share>();
        for(Base_Course__c bCourse: [SELECT Id FROM Base_Course__c]){
            //1.1.4.1 Read Permissions on all Base Course
            for(Id accId : accNcIds.keySet()){
                Id uId = accNcIds.get(accId);
                bc2sh.add(new Base_Course__Share(ParentId = bCourse.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
            }
        }

        if(!bc2sh.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(bc2sh, false);
            system.debug('newSharingData: ' + newSharingData);
        }


        /*
        1.1.5 Course Sub Type
        */
        List<Course_Sub_Type__Share> cst2sh = new List<Course_Sub_Type__Share>();
        for(Course_Sub_Type__c cst: [SELECT Id, Franchisee_Name__c FROM Course_Sub_Type__c WHERE Franchisee_Name__c IN :accNcIds.keySet()]){
            //1.1.5.1 Read Permissions on all the Course Sub Types related to the Account where Account. Partner Account NC is updated
            if(accNcIds.containsKey(cst.Franchisee_Name__c)){
                Id uId = accNcIds.get(cst.Franchisee_Name__c);
                cst2sh.add(new Course_Sub_Type__Share(ParentId = cst.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
            }               
        }

        if(!cst2sh.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(cst2sh, false);
            system.debug('newSharingData: ' + newSharingData);
        }


        /*
        1.1.6 LGs
        */

        List<LG__Share> lg2sh = new List<LG__Share>();
        for(LG__c lg: [SELECT Id, Franchisee__c FROM LG__c WHERE Franchisee__c IN :accNcIds.keySet() OR Franchisee__c IN :accChilds.keySet()]){
            //1.1.6.1 Read Permissions on all the LGs related to the Account where Account. Partner Account NC is updated
            if(accNcIds.containsKey(lg.Franchisee__c)){
                Id uId = accNcIds.get(lg.Franchisee__c);
                lg2sh.add(new LG__Share(ParentId = lg.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
            }

            //1.1.6.2 Read permission on all the LGs of the children accounts of that account
            if(accChilds.containsKey(lg.Franchisee__c)){
                Id parentId = accChilds.get(lg.Franchisee__c);
                Id uId = accNcIds.get(parentId);
                lg2sh.add(new LG__Share(ParentId = lg.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
            }                 
        }

        if(!lg2sh.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(lg2sh, false);
            system.debug('newSharingData: ' + newSharingData);
        }

        /*
        1.1.7 Seminar Type
        */
        List<Seminar_Type__Share> st2sh = new List<Seminar_Type__Share>();
        for(Seminar_Type__c st: [SELECT Id FROM Seminar_Type__c]){
            //1.1.7.1 Read Permissions on all Seminar Type 
            for(Id accId : accNcIds.keySet()){
                Id uId = accNcIds.get(accId);
                st2sh.add(new Seminar_Type__Share(ParentId = st.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
            }
        }

        if(!st2sh.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(st2sh, false);
            system.debug('newSharingData: ' + newSharingData);
        }


        /*
        1.1.8 Seminars
        */
        List<Seminar__Share> sem2sh = new List<Seminar__Share>();
        for(Seminar__c seminar: [SELECT Id FROM Seminar__c]){
            //1.1.8.1 Read Permissions on all Seminars
            for(Id accId : accNcIds.keySet()){
                Id uId = accNcIds.get(accId);
                sem2sh.add(new Seminar__Share(ParentId = seminar.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
            }
        }

        if(!sem2sh.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(sem2sh, false);
            system.debug('newSharingData: ' + newSharingData);
        }

        /*
        1.1.9 Price List Title
        1.1.9.1 Read Permissions on all Price Lists related to its Accounts.
        */
        List<Price_List_Title__Share> priceList2sh = new List<Price_List_Title__Share>();
        for(Price_List_Title_Assignment__c pltAssignment : [SELECT Price_List_Title__c, Franchise__c FROM Price_List_Title_Assignment__c WHERE Franchise__c IN :accNcIds.keySet()]){
            if(accNcIds.containsKey(pltAssignment.Franchise__c)){
                Id uId = accNcIds.get(pltAssignment.Franchise__c);
                priceList2sh.add(new Price_List_Title__Share(ParentId = pltAssignment.Price_List_Title__c, UserOrGroupId = uId, AccessLevel = 'Read'));
            }
        }

        
        if(!priceList2sh.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(priceList2sh, false);
            system.debug('newSharingData: ' + newSharingData);
        }

        /*
        1.1.10 HDC Orders
        1.1.10.1 Read Permissions on HDC Orders related to its Accounts.
        */
        List<FR_Order__Share> order2sh = new List<FR_Order__Share>();
        for(FR_Order__c order : [SELECT Id, Ordered_From__c FROM FR_Order__c WHERE Ordered_From__c IN :accNcIds.keySet()]){
            if(accNcIds.containsKey(order.Ordered_From__c)){
                Id uId = accNcIds.get(order.Ordered_From__c);
                order2sh.add(new FR_Order__Share(ParentId = order.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
            }
        }
        
        if(!order2sh.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(order2sh, false);
            system.debug('newSharingData: ' + newSharingData);
        }

        /*
        1.1.12 Leads
        1.1.12.1 Read permission on all Leads owned by the Partner Account User
        */
        List<LeadShare> lead2sh = new List<LeadShare>();
        for(Lead l : [SELECT Id, OwnerId FROM Lead WHERE OwnerId IN :accPartnerUsers.keySet() OR OwnerId IN :mapLCAccChilds.keySet()]){
            if (accPartnerUsers.containsKey(l.OwnerId)) {
                Id accId = accPartnerUsers.get(l.OwnerId);
                if(accNcIds.containsKey(accId)){
                    Id uId = accNcIds.get(accId);
                    lead2sh.add(new LeadShare(LeadId = l.Id, UserOrGroupId = uId, LeadAccessLevel = 'Read'));
                }
            }

            /*
            1.1.12.2 Read Permission on all Leads owned by his LCs
            */
            if (mapLCAccChilds.containsKey(l.OwnerId)) {
                Id lcAccId = mapLCAccChilds.get(l.OwnerId);
                Id accId = accChilds.get(lcAccId);
                if(accNcIds.containsKey(accId)){
                    Id uId = accNcIds.get(accId);
                    lead2sh.add(new LeadShare(LeadId = l.Id, UserOrGroupId = uId, LeadAccessLevel = 'Read'));
                } 
            }
        }
        
        if(!lead2sh.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(lead2sh, false);
            system.debug('newSharingData: ' + newSharingData);
        }

        /*
        1.1.11 Opportunities
        1.1.11.1 Read permission on all opportunities owned by the Partner Account User
        */
        List<OpportunityShare> opp2sh = new List<OpportunityShare>();
        for(Opportunity opp : [SELECT Id, OwnerId FROM Opportunity WHERE OwnerId IN :accPartnerUsers.keySet() OR OwnerId IN :mapLCAccChilds.keySet()]){
            if (accPartnerUsers.containsKey(opp.OwnerId)) {
                Id accId = accPartnerUsers.get(opp.OwnerId);
                if(accNcIds.containsKey(accId)){
                    Id uId = accNcIds.get(accId);
                    opp2sh.add(new OpportunityShare(OpportunityId = opp.Id, UserOrGroupId = uId, OpportunityAccessLevel = 'Read'));
                }
            }

            /*
                1.1.11.2 Read Permission on all opportunities owned by his LCs
            */

            if (mapLCAccChilds.containsKey(opp.OwnerId)) {
                Id lcAccId = mapLCAccChilds.get(opp.OwnerId);
                Id accId = accChilds.get(lcAccId);
                if(accNcIds.containsKey(accId)){
                    Id uId = accNcIds.get(accId);
                    opp2sh.add(new OpportunityShare(OpportunityId = opp.Id, UserOrGroupId = uId, OpportunityAccessLevel = 'Read'));
                } 
            }
        }

        if(!opp2sh.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(opp2sh, false);
            system.debug('newSharingData: ' + newSharingData);
        }

    }


    /******************************************************************************* 
    Name              : Account_CreateManagerSharingRules
    Description       : when manager changes on account, give share to the new manager user
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             16/01/2016              Yaara                 [SW-23253]
    *******************************************************************************/
    public static void Account_CreateManagerSharingRules(Map<Id,Id> accManagerIds){
        
        Id mcTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();
        Id lcsetlsfTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId();
        /*
        1.2.1 Accounts
        */
        List<AccountShare> acc2sh = new List<AccountShare>();
        for(Id accId : accManagerIds.keySet()){
            Id uId = accManagerIds.get(accId);
            //1.2.1.1 R/W Permissions on the Account where Account. Partner Account Manager is updated
            acc2sh.add(new AccountShare(AccountId = accId, UserOrGroupId = uId, AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'None', ContactAccessLevel = 'None', CaseAccessLevel = 'None'));
        }

        Map<Id,Account> accs = new Map<Id,Account>();
        Map<Id,Id> accPartnerUsers = new Map<Id,Id>();
        Map<Id,Id> accChilds = new Map<Id,Id>();
        Map<Id,Id> mapAccChilds = new Map<Id,Id>();
        Map<Id,Id> mapLCAccChilds = new Map<Id,Id>();
        Map<Id,Id> mapMFAccChilds = new Map<Id,Id>();
        //1.2.1.2 R/W permission on all the children accounts of those accounts
        for (Account acc : [SELECT Id, Partner_Account_User__c, ParentId, Parent.Partner_Account_User__c, RecordTypeId, BillingCountry FROM Account WHERE ParentId IN :accManagerIds.keySet() OR Id IN :accManagerIds.keySet()]) {
            if(accManagerIds.containsKey(acc.Id)){
                accPartnerUsers.put(acc.Partner_Account_User__c,acc.Id);
                accs.put(acc.Id,acc);
            }else{
                Id uId = accManagerIds.get(acc.ParentId);
                accChilds.put(acc.Id,acc.ParentId);
                acc2sh.add(new AccountShare(AccountId = acc.Id, UserOrGroupId = uId, AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'None', ContactAccessLevel = 'None', CaseAccessLevel = 'None'));
                
                mapAccChilds.put(acc.Partner_Account_User__c, acc.Id);
                if(acc.RecordTypeId == lcsetlsfTypeId){
                    mapLCAccChilds.put(acc.Partner_Account_User__c, acc.Id);
                }
                if(acc.RecordTypeId == mcTypeId){
                    mapMFAccChilds.put(acc.Partner_Account_User__c, acc.Id);
                }
            }
        }

        if(!acc2sh.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(acc2sh, false);
            system.debug('newSharingData: ' + newSharingData);
        }

        /*
        1.2.2 Agreements 
        */
        
        List<Agreement__Share> agreements2sh = new List<Agreement__Share>();
        Map<String,Set<Id>> programAccs = new Map<String,Set<Id>>();
        for(Agreement__c agree : [SELECT From_Franchisee__c, Program_Type__c FROM Agreement__c WHERE From_Franchisee__c IN :accManagerIds.keySet() OR From_Franchisee__c IN :accChilds.keySet()]){
            //1.2.2.1 Read Permissions on the Agreements where Account. Partner Account Manager is the From Franchise.
            if(accManagerIds.containsKey(agree.From_Franchisee__c)){
                Id uId = accManagerIds.get(agree.From_Franchisee__c);
                agreements2sh.add(new Agreement__Share(ParentId = agree.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
            
                if(!programAccs.containsKey(agree.Program_Type__c)){
                    programAccs.put(agree.Program_Type__c, new Set<Id>());
                }
                programAccs.get(agree.Program_Type__c).add(agree.From_Franchisee__c);
            }

            //1.2.2.2 R/W permission on all the children agreements
            if(accChilds.containsKey(agree.From_Franchisee__c)){
                Id parentId = accChilds.get(agree.From_Franchisee__c);
                Id uId = accManagerIds.get(parentId);
                agreements2sh.add(new Agreement__Share(ParentId = agree.Id, UserOrGroupId = uId, AccessLevel = 'Edit'));
            }                
        }

        if(!agreements2sh.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(agreements2sh, false);
            system.debug('newSharingData: ' + newSharingData);
        }

        /*
        1.2.3 Contacts
        */

        /*SW-25148
        List<ContactShare> contact2sh = new List<ContactShare>();
        for(Contact contact: [SELECT AccountId, Id FROM Contact WHERE AccountId IN :accManagerIds.keySet() OR AccountId IN :accChilds.keySet()]){
            //1.2.3.1 R/W Permissions on all the Contact related to the Account where Account. Partner Account Manager is updated
            if(accManagerIds.containsKey(contact.AccountId)){
                Id uId = accManagerIds.get(contact.AccountId);
                contact2sh.add(new ContactShare(ContactId = contact.Id, UserOrGroupId = uId, ContactAccessLevel = 'Edit'));
            }

            //1.2.3.2 R/W permission on all the contact of the children accounts of that account
            if(accChilds.containsKey(contact.AccountId)){
                Id parentId = accChilds.get(contact.AccountId);
                Id uId = accManagerIds.get(parentId);
                contact2sh.add(new ContactShare(ContactId = contact.Id, UserOrGroupId = uId, ContactAccessLevel = 'Edit'));
            }                 
        }

        if(!contact2sh.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(contact2sh, false);
            system.debug('newSharingData: ' + newSharingData);
        }*/


        /*
        1.2.4 Account Contact Relationship
        */
        List<ContactShare> contact2RelSh = new List<ContactShare>();
        for(AccountContactRelation accContRelated: [SELECT AccountId, ContactId FROM AccountContactRelation WHERE AccountId IN :accManagerIds.keySet()]){
            //1.2.4.1 R/W Permissions on all the Contact related to the Account where Account Contact Relationship . -> Account.Partner Account Manager is updated
            if(accManagerIds.containsKey(accContRelated.AccountId)){
                Id uId = accManagerIds.get(accContRelated.AccountId);
                contact2RelSh.add(new ContactShare(ContactId = accContRelated.ContactId, UserOrGroupId = uId, ContactAccessLevel = 'Edit'));
            }                 
        }

        if(!contact2RelSh.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(contact2RelSh, false);
            system.debug('newSharingData: ' + newSharingData);
        }

        /*
        1.2.5 LGs
        */

        List<LG__Share> lg2sh = new List<LG__Share>();
        for(LG__c lg: [SELECT Id, Franchisee__c FROM LG__c WHERE Franchisee__c IN :accManagerIds.keySet() OR Franchisee__c IN :accChilds.keySet()]){
            //1.2.5.1 R/W Permissions on all the LGs related to the Account where Account. Partner Account Manager is updated
            if(accManagerIds.containsKey(lg.Franchisee__c)){
                Id uId = accManagerIds.get(lg.Franchisee__c);
                lg2sh.add(new LG__Share(ParentId = lg.Id, UserOrGroupId = uId, AccessLevel = 'Edit'));
            }

            //1.2.5.2 R/W permission on all the LGs of the children accounts of that account
            if(accChilds.containsKey(lg.Franchisee__c)){
                Id parentId = accChilds.get(lg.Franchisee__c);
                Id uId = accManagerIds.get(parentId);
                lg2sh.add(new LG__Share(ParentId = lg.Id, UserOrGroupId = uId, AccessLevel = 'Edit'));
            }                 
        }

        if(!lg2sh.isEmpty() && !Test.isRunningTest()){
            Batch_InsertShareRecords b = new Batch_InsertShareRecords();
            b.newSharingRecords = lg2sh;
            b.objType = 'LG__Share';
            Database.executeBatch(b,100);
            //Database.SaveResult[] newSharingData = database.insert(lg2sh, false);
            //system.debug('newSharingData: ' + newSharingData);
        }

        /*
        1.2.6 Price List Title
        1.2.6.1 Read Permissions on all Price Lists related to its Accounts on Price List Title Assignment where the Account is the Account. Partner Account Manager 
        */
        List<Price_List_Title__Share> priceList2sh = new List<Price_List_Title__Share>();
        for(Price_List_Title_Assignment__c pltAssignment : [SELECT Price_List_Title__c, Franchise__c FROM Price_List_Title_Assignment__c WHERE Franchise__c IN :accManagerIds.keySet()]){
            if(accManagerIds.containsKey(pltAssignment.Franchise__c)){
                Id uId = accManagerIds.get(pltAssignment.Franchise__c);
                priceList2sh.add(new Price_List_Title__Share(ParentId = pltAssignment.Price_List_Title__c, UserOrGroupId = uId, AccessLevel = 'Read'));
            }
        }

        /*
        1.2.6.2 To MF User: Permissions on all the Price List Title where the owner is the Partner Account User
        */
        for(Price_List_Title__c pricelistTitle : [SELECT OwnerId FROM Price_List_Title__c WHERE OwnerId IN :accPartnerUsers.keySet()]){
            if(accPartnerUsers.containsKey(pricelistTitle.OwnerId)){
                Id accId = accPartnerUsers.get(pricelistTitle.OwnerId);
                if(accManagerIds.containsKey(accId) && accs.get(accId).RecordTypeId == mcTypeId){
                    Id uId = accManagerIds.get(accId);
                    priceList2sh.add(new Price_List_Title__Share(ParentId = pricelistTitle.Id, UserOrGroupId = uId, AccessLevel = 'Edit'));
                }
            }
        }
        
        if(!priceList2sh.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(priceList2sh, false);
            system.debug('newSharingData: ' + newSharingData);
        }

        /*
        1.2.7 HDC Orders
        1.2.7.1 R/W Permissions on HDC Orders related to its Accounts.
        */
        List<FR_Order__Share> order2sh = new List<FR_Order__Share>();
        for(FR_Order__c order : [SELECT Id, Ordered_From__c FROM FR_Order__c WHERE Ordered_From__c IN :accManagerIds.keySet()]){
            if(accManagerIds.containsKey(order.Ordered_From__c)){
                Id uId = accManagerIds.get(order.Ordered_From__c);
                order2sh.add(new FR_Order__Share(ParentId = order.Id, UserOrGroupId = uId, AccessLevel = 'Edit'));
            }
        }
        
        if(!order2sh.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(order2sh, false);
            system.debug('newSharingData: ' + newSharingData);
        }

        /*
        1.2.10  Leads 
        1.2.10.1    Read permission on all Leads owned by the Partner Account User
        */
        List<LeadShare> lead2sh = new List<LeadShare>();
        for(Lead l : [SELECT Id, OwnerId FROM Lead WHERE OwnerId IN :accPartnerUsers.keySet() OR OwnerId IN :mapLCAccChilds.keySet()]){
            if (accPartnerUsers.containsKey(l.OwnerId)) {
                Id accId = accPartnerUsers.get(l.OwnerId);
                if(accManagerIds.containsKey(accId)){
                    Id uId = accManagerIds.get(accId);
                    lead2sh.add(new LeadShare(LeadId = l.Id, UserOrGroupId = uId, LeadAccessLevel = 'Edit'));
                }
            }

            /*
            1.2.10.2    Read Permission on all Leads owned by his LCs 
            */

            if (mapLCAccChilds.containsKey(l.OwnerId)) {
                Id lcAccId = mapLCAccChilds.get(l.OwnerId);
                Id accId = accChilds.get(lcAccId);
                Account acc = accs.get(accId);
                if(acc.RecordTypeId == mcTypeId){
                    if(accManagerIds.containsKey(accId)){
                        Id uId = accManagerIds.get(accId);
                        lead2sh.add(new LeadShare(LeadId = l.Id, UserOrGroupId = uId, LeadAccessLevel = 'Edit'));
                    }
                }
            }
        }

        if(!lead2sh.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(lead2sh, false);
            system.debug('newSharingData: ' + newSharingData);
        }

        /*
        Opportunities 
        1.2.9.1 R/W permission on all opportunities owned by the Partner Account User 
        */
        List<OpportunityShare> opp2sh = new List<OpportunityShare>();
        for(Opportunity opp : [SELECT Id, OwnerId FROM Opportunity WHERE OwnerId IN :accPartnerUsers.keySet() OR OwnerId IN :mapLCAccChilds.keySet()]){
            if (accPartnerUsers.containsKey(opp.OwnerId)) {
                Id accId = accPartnerUsers.get(opp.OwnerId);
                if(accManagerIds.containsKey(accId)){
                    Id uId = accManagerIds.get(accId);
                    opp2sh.add(new OpportunityShare(OpportunityId = opp.Id, UserOrGroupId = uId, OpportunityAccessLevel = 'Edit'));
                }
            }

            /*
                1.2.9.2 For MF Manager – R/W Permission on all opportunities owned by his LCs 
            */

            if (mapLCAccChilds.containsKey(opp.OwnerId)) {
                Id lcAccId = mapLCAccChilds.get(opp.OwnerId);
                Id accId = accChilds.get(lcAccId);
                if(accManagerIds.containsKey(accId)){
                    Id uId = accManagerIds.get(accId);
                    opp2sh.add(new OpportunityShare(OpportunityId = opp.Id, UserOrGroupId = uId, OpportunityAccessLevel = 'Edit'));
                } 
            }
        }


        if(!opp2sh.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(opp2sh, false);
            system.debug('newSharingData: ' + newSharingData);
        }

        /*
            1.2.8 Holidays & Vacations (new v1.2)
        */

        Map<String,Set<Id>> accCountry = new Map<String,Set<Id>>();
        Map<Id,Id> mfManagers = new Map<Id,Id>();
        Map<Id,Id> lcManagers = new Map<Id,Id>();
        Map<Id,Id> lcMFManagers = new Map<Id,Id>();
        for (Account acc : accs.values()) {
            if(acc.RecordTypeId == mcTypeId){
                if(!accCountry.containsKey(acc.BillingCountry)){
                    accCountry.put(acc.BillingCountry, new Set<Id>());
                }
                accCountry.get(acc.BillingCountry).add(acc.Id);
                mfManagers.put(acc.Partner_Account_User__c,acc.Id);
            }
            if(acc.RecordTypeId == lcsetlsfTypeId ){
                lcManagers.put(acc.Partner_Account_User__c,acc.Id);
                lcMFManagers.put(acc.Parent.Partner_Account_User__c,acc.Id);
            }           
        }

        Map<String,Holiday_Vacation__Share> hdv2sh = new Map<String,Holiday_Vacation__Share>();
        for(Holiday_Vacation__c hdv : [SELECT Id, Country__c, OwnerId FROM Holiday_Vacation__c WHERE Country__c IN :accCountry.keySet() OR OwnerId IN :mfManagers.keySet() OR OwnerId IN :mapAccChilds.keySet() OR OwnerId IN :lcManagers.keySet() OR OwnerId IN :lcMFManagers.keySet()]){
            /*
                1.2.8.1 Read permission on all Country Holidays where the Country = MF.Billing Country
            */
            if(accCountry.containsKey(hdv.Country__c)){
                for(Id accId : accCountry.get(hdv.Country__c)){
                    if(accManagerIds.containsKey(accId)){
                        Id uId = accManagerIds.get(accId);
                        String stringKey = String.valueOf(hdv.Id) + '_' + String.valueOf(uId);
                        hdv2sh.put(stringKey, new Holiday_Vacation__Share(ParentId = hdv.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
                    }
                }
            }

            /*
                1.2.8.2 For MF Manager - R/W Permissions on Holidays – created by the MF
            */
            if(mfManagers.containsKey(hdv.OwnerId)){
                Id accId = mfManagers.get(hdv.OwnerId);
                if(accManagerIds.containsKey(accId)){
                    Id uId = accManagerIds.get(accId);
                    String stringKey = String.valueOf(hdv.Id) + '_' + String.valueOf(uId);
                    hdv2sh.put(stringKey, new Holiday_Vacation__Share(ParentId = hdv.Id, UserOrGroupId = uId, AccessLevel = 'Edit'));
                }
            }

            /*
                 1.2.8.3 For MF Manager - R/W Permissions on all Holidays & Vacations created by its child accounts
            */
            if(mapAccChilds.containsKey(hdv.OwnerId)){
                Id accId = accChilds.get(mapAccChilds.get(hdv.OwnerId));
                if(accManagerIds.containsKey(accId)){
                    Id uId = accManagerIds.get(accId);
                    String stringKey = String.valueOf(hdv.Id) + '_' + String.valueOf(uId);
                    hdv2sh.put(stringKey, new Holiday_Vacation__Share(ParentId = hdv.Id, UserOrGroupId = uId, AccessLevel = 'Edit'));
                }
            }

            /*
                1.2.8.4 For LC Manager - Read Permissions on Holidays – created by the MF 
            */
            if(lcMFManagers.containsKey(hdv.OwnerId)){
                Id accId = lcMFManagers.get(hdv.OwnerId);
                if(accManagerIds.containsKey(accId)){
                    Id uId = accManagerIds.get(accId);
                    String stringKey = String.valueOf(hdv.Id) + '_' + String.valueOf(uId);
                    hdv2sh.put(stringKey, new Holiday_Vacation__Share(ParentId = hdv.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
                }
            }

            /*
                1.2.8.5 For LC Manager – R/W Permissions on Holidays – created by the LC
            */
            if(lcManagers.containsKey(hdv.OwnerId)){
                Id accId = lcManagers.get(hdv.OwnerId);
                if(accManagerIds.containsKey(accId)){
                    Id uId = accManagerIds.get(accId);
                    String stringKey = String.valueOf(hdv.Id) + '_' + String.valueOf(uId);
                    hdv2sh.put(stringKey, new Holiday_Vacation__Share(ParentId = hdv.Id, UserOrGroupId = uId, AccessLevel = 'Edit'));
                }
            }           
        }
        
        if(!hdv2sh.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(hdv2sh.values(), false);
            system.debug('newSharingData: ' + newSharingData);
        } 

        if (!programAccs.isEmpty()) {
            String programsQuery = '';
            for(String program : programAccs.keySet()){
                programsQuery += ',\''+program+'\'';            
            }

            programsQuery = programsQuery.substring(1);

            /*
            1.1.7 Seminar Type
            */
            List<Seminar_Type__Share> st2sh = new List<Seminar_Type__Share>();            
            for(Seminar_Type__c st: (List<Seminar_Type__c>) Database.query('SELECT Id, Program_Type__c FROM Seminar_Type__c WHERE Program_Type__c INCLUDES ('+programsQuery+')')){
                //QA TTC/Seminar Type Permissions - permissions to all Seminar Types according to Agreement
                String[] programs = st.Program_Type__c.split(';');  
                for (String program : programs) {
                    if(programAccs.containsKey(program)){
                        for (Id accId : programAccs.get(program)) {
                            if(accManagerIds.containsKey(accId)){
                                Id uId = accManagerIds.get(accId);
                                st2sh.add(new Seminar_Type__Share(ParentId = st.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
                            }   
                        }
                    }
                }
            }

            if(!st2sh.isEmpty()){
                Database.SaveResult[] newSharingData = database.insert(st2sh, false);
                system.debug('newSharingData: ' + newSharingData);
            }

            /*
            QA Base Course Permissions - permissions to Base Course (Need read permissions on all base course according to the agreement betw
            */
            List<Base_Course__Share> bc2sh = new List<Base_Course__Share>();
            for(Base_Course__c bc: (List<Base_Course__c>) Database.query('SELECT Id, Program_Type__c FROM Base_Course__c  WHERE Program_Type__c INCLUDES ('+programsQuery+')')){
                //1.1.5.1 Read Permissions on all the Course Sub Types related to the Account where Account. Partner Account NC is updated
                String[] programs = bc.Program_Type__c.split(';');  
                for (String program : programs) { 
                    if(programAccs.containsKey(program)){
                        for (Id accId : programAccs.get(program)) {
                            if(accManagerIds.containsKey(accId)){
                                Id uId = accManagerIds.get(accId);
                                bc2sh.add(new Base_Course__Share(ParentId = bc.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
                            }
                        }
                    }
                }               
            }

            if(!bc2sh.isEmpty()){
                Database.SaveResult[] newSharingData = database.insert(bc2sh, false);
                system.debug('newSharingData: ' + newSharingData);
            }
        }

       /*
        1.2.11.1 Read permission on all Confirmed Seminars
        */
        List<Seminar__Share> sem2sh = new List<Seminar__Share>();
        for(Seminar__c seminar: [SELECT Id FROM Seminar__c WHERE Status__c = 'Confirmed']){
            for(Id accId : accManagerIds.keySet()){
                Id uId = accManagerIds.get(accId);
                sem2sh.add(new Seminar__Share(ParentId = seminar.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
            }
        }

        if(!sem2sh.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(sem2sh, false);
            system.debug('newSharingData: ' + newSharingData);
        }

        /*
        1.1.5 Course Sub Type
        */
        List<Course_Sub_Type__Share> cst2sh = new List<Course_Sub_Type__Share>();
        for(Course_Sub_Type__c cst: [SELECT Id, Franchisee_Name__c FROM Course_Sub_Type__c WHERE Franchisee_Name__c IN :accManagerIds.keySet()]){
            //1.1.5.1 Read Permissions on all the Course Sub Types related to the Account where Account. Partner Account NC is updated
            if(accManagerIds.containsKey(cst.Franchisee_Name__c)){
                Id uId = accManagerIds.get(cst.Franchisee_Name__c);
                cst2sh.add(new Course_Sub_Type__Share(ParentId = cst.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
            }               
        }

        if(!cst2sh.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(cst2sh, false);
            system.debug('newSharingData: ' + newSharingData);
        }

        if(!Test.isRunningTest()){
            Batch_CreateManagerContactSharing b = new Batch_CreateManagerContactSharing();
            b.accManagerIds = accManagerIds;
            b.accChilds = accChilds;
            Database.executeBatch(b,1);
        }

    }
    
}