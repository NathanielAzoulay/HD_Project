/******************************************************************************* 
Name              : Batch_CreateUserFromContact2
Description       : Handler the contacts set to create user, updates after success user creation
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez             06/06/2016          Yaara Nadir               [SW-19584]
2. G. Fernandez             02/03/2017          Yaara Nadir               [SW-23867]
3. G. Fernandez             07/03/2017          Dafna Margalit            [SW-23968]
4. G. Fernandez             27/03/2017          Dafna Margalit            [SW-24204]
5. G. Fernandez             29/03/2017          Dafna Margalit            [SW-24028]

*******************************************************************************/

global without sharing class Batch_CreateUserFromContact2 implements Database.Batchable<sObject>, Database.Stateful {
    
    public String query; 
    
    global List<HD_Log__c> errorLogs = new List<HD_Log__c>();
    global Map<Id, Map<Id,Id>> originalOwners = new Map<Id, Map<Id,Id>>();
    global Boolean doFail {get; set;}

    global Map<String,Id> groups = new Map<String,Id>();
    global Map<String,Id> chatterGroups = new Map<String,Id>();    
    global Map<Id,Id> userContact = new Map<Id,Id>(); 
    global List<HD_Log__c> logIns = new List<HD_Log__c>();
    
    global Map<String,Id> profiles = new Map<String,Id>();

    global List<GroupMember> newMembers = new List<GroupMember>();
    global List<Id> permissionSetAssigns = new List<Id>();
    global List<Id> permissionTTAssigns = new List<Id>();
    
    global Map<Id, Contact> mapContacts2process {get; set;}
    global Map<Id, User> mapNewUser             {get; set;}
    global Map<Id, String> mapError             {get; set;}

    global Map<Id, List<String>> userSharingLogs{get; set;}

    global Iterable<sObject> start(Database.BatchableContext bc) { 
        doFail = false;
        userSharingLogs = new Map<Id, List<String>>();

        for(Group g : [SELECT Name FROM Group]){
            if(g.Name != null){
                groups.put(g.Name, g.Id);
            }
        }

        for(Profile profile : [SELECT Id, Name FROM Profile]){
            profiles.put(profile.Name, profile.Id);
        }

        for(CollaborationGroup g : [SELECT Name FROM CollaborationGroup]){
            chatterGroups.put(g.Name, g.Id);            
        }
   
        return mapContacts2process.values();
    }

    global void execute(Database.BatchableContext BC, List<Contact> scope) {
        
        // Get the requiered Record Type that we will need on the excecution.
        Id recTypeTeacherId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();
        Id recTypeFranchiseeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();
        Id recTypeStaffId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Staff').getRecordTypeId(); 
        Id recTypeStudentId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId(); 
        Id recTypeParentId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Parent').getRecordTypeId(); 
        Id recTypeLcSetLsfId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId();
        Id recTypeMfFpId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();  
        Id recTypeHVCountry = Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('Country').getRecordTypeId();
        
        Map<Id,Account> teacherFranchiseAccs = new Map<Id,Account>();
        Map<Id,Contact> contacts = new Map<Id,Contact>();
        //Map<Id,Contact> teacherUserPermission = new Map<Id,Contact>();
        
        Map<Id,List<Id>> accUsers = new Map<Id,List<Id>>();
        
        Set<Id> lcConAccRelations = new Set<Id>();
        Set<Id> teacherCon = new Set<Id>();
        
        List<Id> allCommunityPartnerGroup               = new List<Id>();
        List<Id> allMfGroup                             = new List<Id>();
        List<Id> allSubFranchiseeGroup                  = new List<Id>();
        List<Id> allTeachersGroup                       = new List<Id>();
        
        Map<String,List<Id>> allUserInSameCountryGroup  = new Map<String,List<Id>>();
        Map<String,List<Id>> eachFranchiseGroup         = new Map<String,List<Id>>(); 
        Map<String,List<Id>> eachMasterFranchiseGroup   = new Map<String,List<Id>>(); 

        Map<Id,List<Id>> sharesOnAccount = new Map<Id,List<Id>>();
        Map<String,Set<Id>> sharesOnCourseSubType = new Map<String,Set<Id>>();
        Map<String,Set<Id>> sharesCourseSubTypeOnFP = new Map<String,Set<Id>>();
        Map<String,Set<Id>> sharesOnHolidayVacation = new Map<String,Set<Id>>();
        Map<String,Set<Id>> sharesOnHolidayVacationByMF = new Map<String,Set<Id>>();
        Map<String,Set<Id>> sharesOnHolidayVacationByLC = new Map<String,Set<Id>>();
        Map<Id,List<Id>> sharesForStaff = new Map<Id,List<Id>>();
        Map<Id,List<Id>> sharesForManagerExecutive = new Map<Id,List<Id>>();
        Map<String,Set<Id>> programUserIds = new Map<String,Set<Id>>();

        Map<Id,List<User>> mfUsersByAccount = new Map<Id,List<User>>();
        Map<Id,List<User>> lcUsersByAccount = new Map<Id,List<User>>();
        Map<String,List<User>> lcUsersByMF = new Map<String,List<User>>();

        Map<String, HD_Settings_List__c> cs = HD_Settings_List__c.getAll();
        Id accHelenDoronHQId;
        Account accHelenDoronHQ;
        if(cs.containsKey('Helen Doron HQ')){
             accHelenDoronHQId = cs.get('Helen Doron HQ').value__c; // Get the Id of the account 'Helen Doron HQ'
             accHelenDoronHQ = [SELECT Id, Name FROM Account WHERE Id =: accHelenDoronHQId];
        }
        
        Savepoint sp = Database.setSavepoint();
        try{
            
            Map<Id,Id> contactUser = new Map<Id,Id>();
            
            for(Integer i = 0; i < scope.size();i++){
                
                Contact currentScopeCon = scope[i];
                
                /*this have the index error from the previous batch*/
                if(!mapError.isEmpty() && mapError.get(currentScopeCon.Id) != null){
                    currentScopeCon.User_Creation_Status__c = 'Error Creating User';
                    continue;
                }

                Account acc = currentScopeCon.Account;
                
                contactUser.put(currentScopeCon.Id, mapNewUser.get(currentScopeCon.Id).Id);
                contacts.put(currentScopeCon.Id, currentScopeCon);

                if(!accUsers.containsKey(currentScopeCon.AccountId)){
                    accUsers.put(currentScopeCon.AccountId, new List<Id>());
                }
                accUsers.get(currentScopeCon.AccountId).add(mapNewUser.get(currentScopeCon.Id).Id);
                
                userContact.put(mapNewUser.get(currentScopeCon.Id).Id, currentScopeCon.Id);

                if(currentScopeCon.RecordTypeId == recTypeStaffId || currentScopeCon.RecordTypeId == recTypeFranchiseeId || (currentScopeCon.RecordTypeId == recTypeTeacherId && currentScopeCon.SET__c == true)){
                    //1.2.1.1.1 If the Contact.Account.Owner is not Partner Community User
                    if(acc.Partner_Account_User__c == null){
                        acc.Partner_Account_User__c = mapNewUser.get(currentScopeCon.Id).Id;
                    }

                    acc.IsPartner = true;

                    teacherFranchiseAccs.put(acc.Id, acc);
                }
                
                currentScopeCon.User_Creation_Status__c = 'User Created';  
                currentScopeCon.Contact_Partner_User__c = mapNewUser.get(currentScopeCon.Id).Id;

                //1.2.2.1 All Community Partner Users – Enter all new community users to this Group. 
                allCommunityPartnerGroup.add(mapNewUser.get(currentScopeCon.Id).Id);

                //1.2.2.2 All users in the same Country 
                //1.2.2.2.1 If there is already group with the Contact.Mailing Country, enter the user to the existing group, else create new Group with the Country name and enter the user to the Group.
                if(currentScopeCon.MailingCountry != null){
                    if(!allUserInSameCountryGroup.containsKey(currentScopeCon.MailingCountry)){
                        allUserInSameCountryGroup.put(currentScopeCon.MailingCountry, new List<Id>());
                    }
                    allUserInSameCountryGroup.get(currentScopeCon.MailingCountry).add(mapNewUser.get(currentScopeCon.Id).Id);
                } 

                //1.2.2.3 All MF
                //1.2.2.3.1 If the user is with Role = Executive and user.Account.Record Type = MF/FP – Enter the user to this group
                if( mapNewUser.get(currentScopeCon.Id).PortalRole == 'Executive' && currentScopeCon.Account.RecordTypeId == recTypeMfFpId){
                    allMfGroup.add(mapNewUser.get(currentScopeCon.Id).Id);
                }
                
                //1.2.2.4 All Sub Franchisee 
                //1.2.2.4.1 If the user is with Role = Executive and user.Account.Record Type = LC/SET/LSF – Enter the user to this group
                if( mapNewUser.get(currentScopeCon.Id).PortalRole == 'Executive' && (currentScopeCon.Account.RecordTypeId == recTypeLcSetLsfId || currentScopeCon.Account.RecordTypeId == recTypeMfFpId) ){
                    allSubFranchiseeGroup.add(mapNewUser.get(currentScopeCon.Id).Id);
                }
                
                //All Teachers If the user with Role = Partner User – Enter the user to this group. Partner User = Worker          
                if( mapNewUser.get(currentScopeCon.Id).PortalRole == 'Worker' ){
                    allTeachersGroup.add(mapNewUser.get(currentScopeCon.Id).Id);
                }

                //dont do this, document update 07/07
                //1.2.3
                //1.2.2.5 Group for Each Franchisee  (for all users belong to the same franchisee)
                //1.2.2.5.1 If the user Role = Executive  - Create new Group with the Franchisee Name
                //1.2.2.5.2 If the user Role = Partner User  - Enter the user to the group with the user.Account Name            
                /*if( mapNewUser.get(currentScopeCon.Id).PortalRole == 'Executive' || mapNewUser.get(currentScopeCon.Id).PortalRole == 'Worker' ){
                    //TODO Franchisee Name != user.Account Name  ???
                    if(!eachFranchiseGroup.containsKey(currentScopeCon.Account.Name)){
                        eachFranchiseGroup.put(currentScopeCon.Account.Name, new List<Id>());
                    }
                    eachFranchiseGroup.get(currentScopeCon.Account.Name).add(mapNewUser.get(currentScopeCon.Id).Id);                
                }            

                //TODO users belong to franchisee and his sub Franchisee ??
                //1.2.2.6 Group for Each Master Franchisee (for all users belong to the same franchisee and his sub Franchisee)
                //1.2.2.6.1 If the user Role = Executive & Account.Record Type = MF/FP
                //1.2.2.6.2  Create new Group with the Franchisee Name            
                //1.2.2.6.3 If the user Role = Partner User or Executive but Account.Record Type = LC/SET/LSF
                //1.2.2.6.3.1 Enter the user to the group with the user.Account.Direct Franchisee Name
                if( mapNewUser.get(currentScopeCon.Id).PortalRole == 'Executive' && currentScopeCon.Account.RecordTypeId == recTypeMfFpId ){
                    if(!eachMasterFranchiseGroup.containsKey(currentScopeCon.Account.Name)){
                        eachMasterFranchiseGroup.put(currentScopeCon.Account.Name, new List<Id>());
                    }
                    eachMasterFranchiseGroup.get(currentScopeCon.Account.Name).add(mapNewUser.get(currentScopeCon.Id).Id);                
                }*/

                if( (mapNewUser.get(currentScopeCon.Id).PortalRole == 'Worker' || mapNewUser.get(currentScopeCon.Id).PortalRole == 'Executive') && currentScopeCon.Account.RecordTypeId == recTypeLcSetLsfId ){
                    if(!eachMasterFranchiseGroup.containsKey(currentScopeCon.Account.Direct_Franchisee__c)){
                        eachMasterFranchiseGroup.put(currentScopeCon.Account.Direct_Franchisee__c, new List<Id>());
                    }
                    eachMasterFranchiseGroup.get(currentScopeCon.Account.Direct_Franchisee__c).add(mapNewUser.get(currentScopeCon.Id).Id);                
                }

                /*Shares*/
                /*
                if the user account is MF - Then he should see MF Holidays where user.contact.account = mf
                if the user account is LC - Then he should see:
                LC Holidays where user.contact.account = the LC
                MF Holidays where user.contact.account.Direct Account = MF
                */
                if( mapNewUser.get(currentScopeCon.Id).PortalRole == 'Executive' || mapNewUser.get(currentScopeCon.Id).PortalRole == 'Manager' ){    
                    if(currentScopeCon.Account.ParentId != null){
                        if(!sharesOnAccount.containsKey(currentScopeCon.Account.ParentId)){
                            sharesOnAccount.put(currentScopeCon.Account.ParentId, new List<Id>());
                        }
                        sharesOnAccount.get(currentScopeCon.Account.ParentId).add(mapNewUser.get(currentScopeCon.Id).Id);
                    }
                }

                if(currentScopeCon.Account.RecordTypeId == recTypeMfFpId){
                    if(!sharesOnHolidayVacationByMF.containsKey(currentScopeCon.AccountId)){
                        sharesOnHolidayVacationByMF.put(currentScopeCon.AccountId,new Set<Id>());
                    }
                    sharesOnHolidayVacationByMF.get(currentScopeCon.AccountId).add(mapNewUser.get(currentScopeCon.Id).Id);
                }

                if( currentScopeCon.Account.RecordTypeId == recTypeLcSetLsfId){
                    if(currentScopeCon.Account.ParentId != null){
                        if(!sharesOnHolidayVacationByLC.containsKey(currentScopeCon.AccountId)){
                            sharesOnHolidayVacationByLC.put(currentScopeCon.AccountId,new Set<Id>());
                        }
                        sharesOnHolidayVacationByLC.get(currentScopeCon.AccountId).add(mapNewUser.get(currentScopeCon.Id).Id);
                    }

                    if(!sharesOnHolidayVacationByMF.containsKey(currentScopeCon.Account.ParentId)){
                        sharesOnHolidayVacationByMF.put(currentScopeCon.Account.ParentId,new Set<Id>());
                    }
                    sharesOnHolidayVacationByMF.get(currentScopeCon.Account.ParentId).add(mapNewUser.get(currentScopeCon.Id).Id);
                }

                /*Course Sub Type Shares*/
                //SW-24625 skype. treat HQ HELEN as null, not valid for sharing
                if(accHelenDoronHQ <> null && currentScopeCon.Direct_Franchisee__c!=accHelenDoronHQ.Name){
                    if(!sharesOnCourseSubType.containsKey(currentScopeCon.Direct_Franchisee__c)){
                        sharesOnCourseSubType.put(currentScopeCon.Direct_Franchisee__c,new Set<Id>());
                    }
                    sharesOnCourseSubType.get(currentScopeCon.Direct_Franchisee__c).add(mapNewUser.get(currentScopeCon.Id).Id);
                }

                /*share to LC users all the cst that his FP can read*/
                if( (mapNewUser.get(currentScopeCon.Id).PortalRole == 'Executive' || mapNewUser.get(currentScopeCon.Id).PortalRole == 'Manager') && currentScopeCon.Account.RecordTypeId == recTypeLcSetLsfId ){
                    if(!sharesCourseSubTypeOnFP.containsKey(currentScopeCon.Account.Parent.Partner_Account_User__c)){
                        sharesCourseSubTypeOnFP.put(currentScopeCon.Account.Parent.Partner_Account_User__c,new Set<Id>());
                    }
                    sharesCourseSubTypeOnFP.get(currentScopeCon.Account.Parent.Partner_Account_User__c).add(mapNewUser.get(currentScopeCon.Id).Id);
                }

                if(!sharesOnHolidayVacation.containsKey(currentScopeCon.Account.BillingCountry)){
                    sharesOnHolidayVacation.put(currentScopeCon.Account.BillingCountry,new Set<Id>());
                }
                sharesOnHolidayVacation.get(currentScopeCon.Account.BillingCountry).add(mapNewUser.get(currentScopeCon.Id).Id); 

                if(currentScopeCon.RecordTypeId == recTypeStaffId){
                    if(!sharesForStaff.containsKey(currentScopeCon.AccountId)){
                        sharesForStaff.put(currentScopeCon.AccountId, new List<Id>());
                    }
                    sharesForStaff.get(currentScopeCon.AccountId).add(mapNewUser.get(currentScopeCon.Id).Id);                         
                }

                if(mapNewUser.get(currentScopeCon.Id).PortalRole == 'Executive' || mapNewUser.get(currentScopeCon.Id).PortalRole == 'Manager'){
                    if(!sharesForManagerExecutive.containsKey(currentScopeCon.AccountId)){
                        sharesForManagerExecutive.put(currentScopeCon.AccountId, new List<Id>());
                    }
                    sharesForManagerExecutive.get(currentScopeCon.AccountId).add(mapNewUser.get(currentScopeCon.Id).Id);

                    //SW-23174 for lc user
                    lcConAccRelations.add(currentScopeCon.AccountId);
                }
    
                if((currentScopeCon.RecordTypeId == recTypeStaffId || currentScopeCon.RecordTypeId == recTypeFranchiseeId) && currentScopeCon.Account.RecordTypeId == recTypeLcSetLsfId && (currentScopeCon.Account.Account_Type__c == 'ILSF' || currentScopeCon.Account.Account_Type__c == 'ILCF') ){
                    permissionSetAssigns.add(mapNewUser.get(currentScopeCon.Id).Id);
                }

                //SW-24204
                //When creating new user to Contact with Record Type = Francisee: 
                if(currentScopeCon.RecordTypeId == recTypeFranchiseeId){
                    User u = mapNewUser.get(currentScopeCon.Id);
                    if(u.ProfileId == profiles.get('HDC MF User') || u.ProfileId == profiles.get('HDC MF Logistic')){
                        if(!mfUsersByAccount.containsKey(currentScopeCon.AccountId)){
                            mfUsersByAccount.put(currentScopeCon.AccountId,new List<User>());
                        }
                        mfUsersByAccount.get(currentScopeCon.AccountId).add(u);
                    }

                    if(u.ProfileId == profiles.get('HDC LC User') || u.ProfileId == profiles.get('HDC LC Logistic')){
                        if(!lcUsersByAccount.containsKey(currentScopeCon.AccountId)){
                            lcUsersByAccount.put(currentScopeCon.AccountId,new List<User>());
                        }
                        lcUsersByAccount.get(currentScopeCon.AccountId).add(u);

                        if(String.isNotBlank(u.MF_ID__c)) {
                            if(!lcUsersByMF.containsKey(u.MF_ID__c)){
                                lcUsersByMF.put(u.MF_ID__c,new List<User>());
                            }
                            lcUsersByMF.get(u.MF_ID__c).add(u);   
                        }
                    }
                }

                if(currentScopeCon.RecordTypeId == recTypeTeacherId && currentScopeCon.TT_Qualified__c == 'TT'){
                    permissionTTAssigns.add(mapNewUser.get(currentScopeCon.Id).Id);
                }

                if(currentScopeCon.RecordTypeId == recTypeTeacherId){
                    //teacherUserPermission.put(mapNewUser.get(currentScopeCon.Id).Id, currentScopeCon);

                    //SW-19584 QA UPDATE 01/01/2017
                    //moved to SW-23038
                    if(!String.isEmpty(currentScopeCon.Program_Type__c)){
                        String[] programs = currentScopeCon.Program_Type__c.split(';');
                        for(String program : programs){
                            if (!programUserIds.containsKey(program)) {
                                programUserIds.put(program,new Set<Id>()); 
                            }
                            programUserIds.get(program).add(mapNewUser.get(currentScopeCon.Id).Id);
                        }
                    }

                    //SW-23174 for teacher
                    teacherCon.add(currentScopeCon.Id);

                }
                
                /*if(!sharesOnHolidayVacationByCountryMF.containsKey(currentScopeCon.Account.ParentId)){
                    sharesOnHolidayVacationByCountryMF.put(currentScopeCon.Account.ParentId,new Set<Id>());
                }
                sharesOnHolidayVacationByCountryMF.get(currentScopeCon.Account.ParentId).add(mapNewUser.get(currentScopeCon.Id).Id);*/   
            }

            //update contacts user creation status 
            update scope;

            if(!contactUser.isEmpty()){
                
                // Disable the notification before creating the CollaborationGroupMembers since will send a notification to the user for each group.
	            NotificationNetWorkSetting.disableNotification(new Set<Id>(contactUser.values()));
                
                // update accounts to relate with his new user
                update teacherFranchiseAccs.values();                
                
                // get network Id using one user member for all the community
                Id networkId = [SELECT Id, Value__c FROM HD_Settings_List__c WHERE Name = 'HD Community ID' LIMIT 1][0].Value__c;

                // add members
                List<CollaborationGroupMember> newChatters = new List<CollaborationGroupMember>();
                for(Id userId : allCommunityPartnerGroup){
                
                    newMembers.add(new GroupMember(GroupId = groups.get('All Community Partner Users'), UserOrGroupId = userId));
                    if(chatterGroups.containsKey('All Community Partner Users')){
                        newChatters.add(new CollaborationGroupMember(CollaborationGroupId  = chatterGroups.get('All Community Partner Users'), MemberId  = userId));
                    }
                }

                for(Id userId : allMfGroup){

                    newMembers.add(new GroupMember(GroupId = groups.get('All MF'), UserOrGroupId = userId));
                    if(chatterGroups.containsKey('All MF')){
                        newChatters.add(new CollaborationGroupMember(CollaborationGroupId  = chatterGroups.get('All MF'), MemberId  = userId));
                    }
                }

                for(Id userId : allSubFranchiseeGroup){
               
                    newMembers.add(new GroupMember(GroupId = groups.get('All Sub Franchisee'), UserOrGroupId = userId));
                    if(chatterGroups.containsKey('All Sub Franchisee')){
                        newChatters.add(new CollaborationGroupMember(CollaborationGroupId  = chatterGroups.get('All Sub Franchisee'), MemberId  = userId));
                    }
                }

                for(Id userId : allTeachersGroup){
                    newMembers.add(new GroupMember(GroupId = groups.get('All Teachers'), UserOrGroupId = userId));
                }

                Set<String> groupsSuperSet = new Set<String>();
                groupsSuperSet.addAll(allUserInSameCountryGroup.keySet());                
                //dont do this, document update 07/07
                //groupsSuperSet.addAll(eachFranchiseGroup.keySet());
                //groupsSuperSet.addAll(eachMasterFranchiseGroup.keySet());


                Map<String,Group> newGroups = new Map<String,Group>();
                Map<String,CollaborationGroup> newChatterGroups = new Map<String,CollaborationGroup>();

                for(String groupName : groupsSuperSet){
                    //add groups that not exist till now
                    if( !groups.containsKey(groupName) ){
                        newGroups.put(groupName, new Group(Name = groupName, Type = 'Regular'));
                    }

                    System.debug(LoggingLevel.INFO, '*** chatterGroups: ' + chatterGroups);
                    System.debug(LoggingLevel.INFO, '*** groupName: ' + groupName);

                    //add chattergroups that not exist till now
                    if( !chatterGroups.containsKey(groupName)){
                        newChatterGroups.put(groupName, new CollaborationGroup(Name = groupName, CollaborationType = 'Public', NetworkId = networkId));
                    }
                }

                // create groups
                if(!newGroups.isEmpty()){
                    insert newGroups.values();
                }

                // create chatter groups
                if(!newChatterGroups.isEmpty()){
                    System.debug(LoggingLevel.INFO, '*** newChatterGroups: ' + newChatterGroups);
                    upsert newChatterGroups.values();
                }
                
                // We add the new groups / CollaborationGroups since the next iteration needs to consider this possible new groups
                for(Group g : newGroups.values()){
                    groups.put(g.Name, g.Id);
                }
                
                for(CollaborationGroup g : newChatterGroups.values()){
                    chatterGroups.put(g.Name, g.Id);
                }
              
                for(String groupName : allUserInSameCountryGroup.keySet()){
                    for(Id userId : allUserInSameCountryGroup.get(groupName)){
                        if(groups.containsKey(groupName) || newGroups.containsKey(groupName)){
                            
                            GroupMember member = new GroupMember();
                            if(groups.containsKey(groupName)){
                                member.GroupId = groups.get(groupName);                    
                            }else{
                                member.GroupId = newGroups.get(groupName).Id;
                            }
                            member.UserOrGroupId = userId;
                            newMembers.add(member);
                        }


                        if(chatterGroups.containsKey(groupName) || newChatterGroups.containsKey(groupName)){
                            
                            CollaborationGroupMember newChatter = new CollaborationGroupMember();
                            if(chatterGroups.containsKey(groupName)){
                                newChatter.CollaborationGroupId  = chatterGroups.get(groupName);
                            }else if(newChatterGroups.containsKey(groupName)){
                                newChatter.CollaborationGroupId = newChatterGroups.get(groupName).Id;
                            }
                            newChatter.MemberId  = userId;
                            newChatters.add(newChatter);
                        }
                    }  
                } 
                
                //dont do this, document update 07/07
                /*for(String groupName : eachFranchiseGroup.keySet()){
                    if(newGroups.containsKey(groupName) || groups.containsKey(groupName)){ 
                        Id groupId = newGroups.containsKey(groupName)?newGroups.get(groupName).Id:groups.get(groupName);             
                        for(Id userId : eachFranchiseGroup.get(groupName)){
                            GroupMember member = new GroupMember();
                            member.GroupId = groupId;
                            member.UserOrGroupId = userId;
                            newMembers.add(member);
                        }
                    }
                }

                for(String groupName : eachMasterFranchiseGroup.keySet()){
                    if(newGroups.containsKey(groupName) || groups.containsKey(groupName)){  
                        Id groupId = newGroups.containsKey(groupName)?newGroups.get(groupName).Id:groups.get(groupName); 
                        for(Id userId : eachMasterFranchiseGroup.get(groupName)){
                            GroupMember member = new GroupMember();
                            member.GroupId = groupId;
                            member.UserOrGroupId = userId;
                            newMembers.add(member);
                        }
                    }
                }*/        

                System.debug(LoggingLevel.INFO, '*** newChatters: ' + newChatters);
                //add users to groups
                if(!newChatters.isEmpty() && !Test.isRunningTest()) {            
                    database.insert(newChatters, false);
                }

                /**
                *Sharing 
                *******************************************
                */  

                //1.3.1.1.3 Read permission on its Direct Franchisee Account
                List<AccountShare> newSharesOnAccount = new List<AccountShare>();
                for(Id accId : sharesOnAccount.keySet()){
                    for (Id userId : sharesOnAccount.get(accId) ) {
                        newSharesOnAccount.add(new AccountShare(AccountId = accId, UserOrGroupId = userId, AccountAccessLevel = 'Read', OpportunityAccessLevel = 'None' )); 
                    }  
                }

                if(!newSharesOnAccount.isEmpty()){
                    Database.SaveResult[] saveResult = database.insert(newSharesOnAccount,false);
                    logResults(newSharesOnAccount, saveResult, 'Direct Franchisee Account');
                }

                //1.3.1.1.1 R/W permission on its own Account
                //1.3.1.1.2 R/W permission on its own Contact
                List<AccountShare> newSharesOnOwnAccount = new List<AccountShare>();
                List<ContactShare> newSharesOnOwnContact = new List<ContactShare>();
                for(Integer i = 0; i < scope.size();i++){
                    
                    Contact currentScopeCon = scope[i];
                    if(mapError.isEmpty() || mapError.get(currentScopeCon.Id) == null){
                        newSharesOnOwnAccount.add(new AccountShare(AccountId = currentScopeCon.AccountId, UserOrGroupId = mapNewUser.get(currentScopeCon.Id).Id, AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'None', ContactAccessLevel = 'Edit', CaseAccessLevel = 'Edit' ));
                        newSharesOnOwnContact.add(new ContactShare(ContactId = currentScopeCon.Id, UserOrGroupId = mapNewUser.get(currentScopeCon.Id).Id, ContactAccessLevel = 'Edit'));
                    }
                }
                if(!newSharesOnOwnAccount.isEmpty()){
                    Database.SaveResult[] saveResult = database.insert(newSharesOnOwnAccount,false);
                    logResults(newSharesOnOwnAccount, saveResult, 'Own Account');
                }
                
                if(!newSharesOnOwnContact.isEmpty()){
                    Database.SaveResult[] saveResult = database.insert(newSharesOnOwnContact,false);
                    logResults(newSharesOnOwnContact, saveResult, 'Own Contact');
                }

                //1.3.1.1.4 Read permission on the Agreement where Agreement.From Franchisee = the user.Account
                //1.3.1.1.8 Read permission on Price List Title from Agreement.Price List Title, where Agreement.From Franchisee = user.Account

                List<Agreement__Share> newSharesOnAgreement = new List<Agreement__Share>();
                Map<String,Set<Id>> sharesOnProgramType = new Map<String,Set<Id>>();

                for(Agreement__c agree : [SELECT From_Franchisee__c, Program_Type__c FROM Agreement__c WHERE From_Franchisee__c IN :accUsers.keySet()]){
                    for (Id userId : accUsers.get(agree.From_Franchisee__c) ) {
                        newSharesOnAgreement.add(new Agreement__Share(ParentId = agree.Id ,UserOrGroupId = userId, AccessLevel = 'Read' )); 
                        
                        if( !sharesOnProgramType.containsKey(agree.Program_Type__c) ){
                            sharesOnProgramType.put(agree.Program_Type__c, new Set<Id>());
                        }
                        sharesOnProgramType.get(agree.Program_Type__c).add(userId);                
                    }            
                }

                if(!newSharesOnAgreement.isEmpty()){
                    Database.SaveResult[] saveResult = database.insert(newSharesOnAgreement,false);
                    logResults(newSharesOnAgreement, saveResult, 'Agreement');
                }

                List<Price_List_Title__Share> newSharesOnPriceListTitle = new List<Price_List_Title__Share>();
                for(Price_List_Title_Assignment__c pltAssigment : [SELECT Price_List_Title__c, Franchise__c FROM Price_List_Title_Assignment__c WHERE Franchise__c IN :sharesForManagerExecutive.keySet()]){
                    for (Id userId : sharesForManagerExecutive.get(pltAssigment.Franchise__c) ) {
                        if( pltAssigment.Price_List_Title__c != null ){
                            newSharesOnPriceListTitle.add(new Price_List_Title__Share(ParentId = pltAssigment.Price_List_Title__c ,UserOrGroupId = userId, AccessLevel = 'Read' ));
                        }
                    }
                }

                if(!newSharesOnPriceListTitle.isEmpty()){
                    Database.SaveResult[] saveResult = database.insert(newSharesOnPriceListTitle,false);
                    logResults(newSharesOnPriceListTitle, saveResult, 'Price List Title from Agreement');
                }

                //1.3.1.1.5 Read permission on all Course Sub Type where Course Sub Type.Franchisee Name = user.Account.Direct Franchisee.
                List<Course_Sub_Type__Share> newSharesOnCourseSubType = new List<Course_Sub_Type__Share>();
                for(Course_Sub_Type__c courseST : [SELECT Id, Franchisee_Name__r.Name FROM Course_Sub_Type__c WHERE Franchisee_Name__r.Name IN :sharesOnCourseSubType.keySet()]){
                    for (Id userId : sharesOnCourseSubType.get(courseST.Franchisee_Name__r.Name) ) {
                        newSharesOnCourseSubType.add(new Course_Sub_Type__Share(ParentId = courseST.Id ,UserOrGroupId = userId, AccessLevel = 'Read' ));                    
                    }
                }
                //Copy read permissions from FP
                for(Course_Sub_Type__Share courseSTShare : [SELECT Id, ParentId, UserOrGroupId FROM Course_Sub_Type__Share WHERE UserOrGroupId IN :sharesCourseSubTypeOnFP.keySet()]){
                    for (Id userId : sharesCourseSubTypeOnFP.get(courseSTShare.UserOrGroupId) ) {
                        newSharesOnCourseSubType.add(new Course_Sub_Type__Share(ParentId = courseSTShare.ParentId ,UserOrGroupId = userId, AccessLevel = 'Read' ));                    
                    }
                }
                
                if(!newSharesOnCourseSubType.isEmpty()){
                    Database.SaveResult[] saveResult = database.insert(newSharesOnCourseSubType,false);
                    logResults(newSharesOnCourseSubType, saveResult, 'Course Sub Type');
                }
                //1.3.1.1.6 Read permission on all Holiday & Vacation where Holiday & Vacation.Country = user.Account.Billing Country
                //1.3.1.1.7 Read permission on all Holiday & Vacation where Holiday & Vacation.Country.MF = user.Account.Direct Franchisee
                //1.3.1.1.17 Read permission on all Holiday & Vacation where Holiday & Vacation.MF =  user.Account.Direct Franchisee
                List<Holiday_Vacation__Share> newSharesOnHolidayVacation = new List<Holiday_Vacation__Share>();
                for(Holiday_Vacation__c hv : [SELECT Id, Country__c, MF__c, LC__c, RecordTypeId FROM Holiday_Vacation__c
                    WHERE (Country__c IN :sharesOnHolidayVacation.keySet() AND RecordTypeId = :recTypeHVCountry)
                    OR LC__c IN :sharesOnHolidayVacationByLC.keySet()
                    OR MF__c IN :sharesOnHolidayVacationByMF.keySet()]){

                    if( hv.RecordTypeId == recTypeHVCountry && sharesOnHolidayVacation.containsKey(hv.Country__c) ){
                        for (Id userId : sharesOnHolidayVacation.get(hv.Country__c) ) {
                            newSharesOnHolidayVacation.add(new Holiday_Vacation__Share(ParentId = hv.Id, UserOrGroupId = userId, AccessLevel = 'Read' ));                    
                        }
                    }

                    if( hv.MF__c != null && sharesOnHolidayVacationByMF.containsKey(hv.MF__c)){
                        for (Id userId : sharesOnHolidayVacationByMF.get(hv.MF__c) ) {
                            newSharesOnHolidayVacation.add(new Holiday_Vacation__Share(ParentId = hv.Id, UserOrGroupId = userId, AccessLevel = 'Read' ));
                        }
                    }

                    /*if( sharesOnHolidayVacationByCountryMF.containsKey(hv.Country__r.MF__c)){
                        for (Id userId : sharesOnHolidayVacationByCountryMF.get(hv.Country__r.MF__c) ) {
                            newSharesOnHolidayVacation.add(new Holiday_Vacation__Share(ParentId = hv.Id, UserOrGroupId = userId, AccessLevel = 'Read' ));
                        }
                    }*/

                    if( hv.LC__c != null && sharesOnHolidayVacationByLC.containsKey(hv.LC__c)){
                        for (Id userId : sharesOnHolidayVacationByLC.get(hv.LC__c) ) {
                            newSharesOnHolidayVacation.add(new Holiday_Vacation__Share(ParentId = hv.Id, UserOrGroupId = userId, AccessLevel = 'Read' ));
                        }
                    }
                }

                if(!newSharesOnHolidayVacation.isEmpty()){        
                    Database.SaveResult[] saveResult = database.insert(newSharesOnHolidayVacation,false);
                    logResults(newSharesOnHolidayVacation, saveResult, 'Holiday & Vacation');
                }

                if(!sharesOnProgramType.isEmpty()){
                    String programsQuery = '';
                    for(String program : sharesOnProgramType.keySet()){
                        programsQuery += ',\''+program+'\'';            
                    }
                   
                    programsQuery = programsQuery.substring(1);

                    String baseCourseQ = 'SELECT Id, Program_Type__c FROM Base_Course__c WHERE Program_Type__c INCLUDES ('+programsQuery+')';

                    //1.3.1.1.9 Read Permission on Base Course where Base Course.Program Type is part of Agreement.Program Type, where Agreement.From Franchisee = user.Account
                    List<Base_Course__Share> newSharesOnBaseCourse = new List<Base_Course__Share>();
                    
                    for(Base_Course__c baseCourse : Database.query(baseCourseQ)){
                        String[] programs = baseCourse.Program_Type__c.split(';');  
                        for (String program : programs) {
                            if(sharesOnProgramType.containsKey(program)){
                                for (Id userId : sharesOnProgramType.get(program) ) {
                                    newSharesOnBaseCourse.add(new Base_Course__Share(ParentId = baseCourse.Id ,UserOrGroupId = userId, AccessLevel = 'Read' ));                    
                                }
                            }
                        }
                    }
                    if(!newSharesOnBaseCourse.isEmpty()){
                        Database.SaveResult[] saveResult = database.insert(newSharesOnBaseCourse,false);
                        logResults(newSharesOnBaseCourse, saveResult, 'Base Course');
                    }

                    //1.3.1.1.10 Read Permission on Seminar Type where Seminar Type.Program Type is part of Agreement.Program Type, where Agreement.From Franchisee = user.Account
                    
                    //SW-25908
                    /*String seminarTypeQ = 'SELECT Id, Program_Type__c FROM Seminar_Type__c WHERE Program_Type__c INCLUDES ('+programsQuery+')';
                    List<Seminar_Type__Share> newSharesOnSeminarType = new List<Seminar_Type__Share>();
                    for(Seminar_Type__c seminarType : Database.query(seminarTypeQ)){
                        String[] programs = seminarType.Program_Type__c.split(';');  
                        for (String program : programs) {
                            if(sharesOnProgramType.containsKey(program)){
                                for (Id userId : sharesOnProgramType.get(program) ) {
                                    newSharesOnSeminarType.add(new Seminar_Type__Share(ParentId = seminarType.Id ,UserOrGroupId = userId, AccessLevel = 'Read' ));                    
                                }
                            }
                        }
                    }
                    if(!newSharesOnSeminarType.isEmpty()){
                        Database.SaveResult[] saveResult = database.insert(newSharesOnSeminarType,false);
                        logResults(newSharesOnSeminarType, saveResult, 'Seminar Type');
                    }*/
                }

                //1.3.1.1.14 Read permission on Teacher Agreement where Teacher Agreement.Teacher = the user.Contact
                List<Teacher_Agreement__Share> newSharesOnteacherAgreement = new List<Teacher_Agreement__Share>();
                
                for(Teacher_Agreement__c teacerAgreement : [SELECT Id, Teacher__c FROM Teacher_Agreement__c WHERE Teacher__c IN :contactUser.keySet()]){
                    if(contacts.get(teacerAgreement.Teacher__c).RecordTypeId == recTypeTeacherId){
                        newSharesOnteacherAgreement.add(new Teacher_Agreement__Share(ParentId = teacerAgreement.Id ,UserOrGroupId = contactUser.get(teacerAgreement.Teacher__c), AccessLevel = 'Read' )); 
                    }
                }

                if(!newSharesOnteacherAgreement.isEmpty()){
                    Database.SaveResult[] saveResult = database.insert(newSharesOnteacherAgreement,false);
                    logResults(newSharesOnteacherAgreement, saveResult, 'Teacher Agreement');
                }

                /*
                Staff user should get permission on all the .. 
                R/W - LG - Related to its account (LG.Franchise = The Staff Contact.Franchisee) 
                R/W - Students, Parents - Related to its Account 
                Read - All Teachers related to its account 
                Read - Price List Titles - that have Price List Title assignment to his account
                */

                if(!sharesForStaff.isEmpty()){
                    List<LG__Share> newSharesOnLG = new List<LG__Share>();
                    List<ContactShare> newSharesOnContact = new List<ContactShare>();

                    for(LG__c lg : [SELECT Id, Franchisee__c FROM LG__c WHERE Franchisee__c IN :sharesForStaff.keySet()]){
                        for(Id uId : sharesForStaff.get(lg.Franchisee__c)){
                            newSharesOnLG.add(new LG__Share(ParentId = lg.Id, UserOrGroupId = uId, AccessLevel = 'Edit'));
                        }
                    }

                    for(Contact contact : [SELECT Id, AccountId, RecordTypeId FROM Contact WHERE AccountId IN :sharesForStaff.keySet() AND (RecordTypeId = :recTypeStudentId OR RecordTypeId = :recTypeParentId OR RecordTypeId = :recTypeTeacherId)]){
                        String access = 'Edit';
                        if(contact.RecordTypeId == recTypeTeacherId){
                            access = 'Read';
                        }
                        for(Id uId : sharesForStaff.get(contact.AccountId)){
                            newSharesOnContact.add(new ContactShare(ContactId = contact.Id, UserOrGroupId = uId, ContactAccessLevel = access));
                        }
                    }
                

                    if(!newSharesOnLG.isEmpty()){
                        Database.SaveResult[] saveResult = database.insert(newSharesOnLG,false);
                        logResults(newSharesOnLG, saveResult, 'LG');

                    }

                    if(!newSharesOnContact.isEmpty()){
                        Database.SaveResult[] saveResult = database.insert(newSharesOnContact,false);
                        logResults(newSharesOnContact, saveResult, 'Contact');
                    }
                }

                //SW-22698 duplicated in //1.3.1.1.14 Read permission on Teacher Agreement where Teacher Agreement.Teacher = the user.Contact
                /*if(!teacherUserPermission.isEmpty()){
                    List<UserShare> newSharesOnUser = new List<UserShare>();
                    for (Id uId : teacherUserPermission.keySet()) {
                        for (Teacher_Agreement__c ta : teacherUserPermission.get(uId).Teachers_Agreements__r) {
                            newSharesOnUser.add(new UserShare(UserId = ta.Teacher__r.Contact_Partner_User__c, UserOrGroupId = uId, UserAccessLevel = 'Read'));
                        }
                    }

                    if(!newSharesOnUser.isEmpty()){
                        insert newSharesOnUser;
                    }
                }*/

                //SW-19584 QA UPDATE 01/01/2017
                if(!programUserIds.isEmpty()){

                    String programsQuery = '';                    
                    for(String program : programUserIds.keySet()){
                        programsQuery += ',\''+program+'\'';            
                    }                    
                    programsQuery = programsQuery.substring(1);

                    Map<Id,Set<String>> stPrograms = new Map<Id,Set<String>>();
                    
                    //SW-25908
                    //List<Seminar_Type__Share> newSharesOnContactSeminarType = new List<Seminar_Type__Share>();
                    
                    String pquery = 'SELECT Id, Program_Type__c FROM Seminar_Type__c WHERE Program_Type__c INCLUDES ('+programsQuery+')';
                    for (Seminar_Type__c st : Database.query(pquery)) {
                        String[] programs = st.Program_Type__c.split(';');  
                        for (String program : programs) {
                            //SW-25908
                            /*if(programUserIds.containsKey(program)){
                                for(Id uId : programUserIds.get(program)){
                                    newSharesOnContactSeminarType.add(new Seminar_Type__Share(ParentId = st.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
                                }
                            }*/
                            //collect programs on each seminar type
                            if(!stPrograms.containsKey(st.Id)){
                                stPrograms.put(st.Id,new Set<String>());
                            }
                            stPrograms.get(st.Id).add(program);
                        }
                    }                    

                    //SW-25908
                    /*if (!newSharesOnContactSeminarType.isEmpty()) {
                        Database.SaveResult[] saveResult = database.insert(newSharesOnContactSeminarType,false);
                        logResults(newSharesOnContactSeminarType, saveResult, 'Contact Seminar Type');
                    }*/

                    //SW-23038
                    List<Seminar__Share> newSharesOnSeminar = new List<Seminar__Share>();
                    for (Seminar__c seminar : [SELECT Id, Status__c, Seminar_Type__c, (SELECT Teacher__c FROM Seminar_Teachers__r WHERE Teacher_Status_in_seminar__c = 'Registered') FROM Seminar__c WHERE Seminar_Type__c IN :stPrograms.keySet() AND Status__c IN ('Confirmed','Pending Evaluation','Evaluated') ]) {                        
                        for(String program:stPrograms.get(seminar.Seminar_Type__c)){
                            if(programUserIds.containsKey(program)){
                                for(Id uId : programUserIds.get(program)){
                                    
                                    if(seminar.Status__c == 'Confirmed'){
                                        newSharesOnSeminar.add(new Seminar__Share(ParentId = seminar.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
                                    }
                                    
                                    //SW-23968 Update 8/3/17  for #2 
                                    //sharing for teacher user in those seminars he is registered
                                    if(seminar.Status__c == 'Pending Evaluation' || seminar.Status__c == 'Evaluated'){
                                        for(Seminar_Teachers__c st : seminar.Seminar_Teachers__r){
                                            if(contactUser.containsKey(st.Teacher__c) && contactUser.get(st.Teacher__c) == uId){
                                                newSharesOnSeminar.add(new Seminar__Share(ParentId = seminar.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
                                            }                                                
                                        }
                                    }

                                }
                            }
                        }
                    }

                    if(!newSharesOnSeminar.isEmpty()){
                        Database.SaveResult[] saveResult = database.insert(newSharesOnSeminar,false);
                        logResults(newSharesOnSeminar, saveResult, 'Seminar');
                    }

                }

                //SW-24204
                if(!mfUsersByAccount.isEmpty() || !lcUsersByAccount.isEmpty()){
                    List<Seminar__Share> newSharesOnSeminar = new List<Seminar__Share>();

                    //Shares on TTC/Seminar
                    for (Seminar__c seminar : [SELECT Id, Status__c, Hosting_Franchisee__c FROM Seminar__c WHERE Status__c IN ('Confirmed') OR Hosting_Franchisee__c IN :mfUsersByAccount.keySet() OR Hosting_Franchisee__c IN :lcUsersByAccount.keySet() OR Hosting_Franchisee__c IN :lcUsersByMF.keySet()]) { 
                        //1.1 Read permission to all TTC/Seminar in status confirmed
                        for (Id accId : lcUsersByAccount.keySet()) {
                            for (User u : lcUsersByAccount.get(accId)) {
                                if(seminar.Status__c == 'Confirmed'){
                                    newSharesOnSeminar.add(new Seminar__Share(ParentId = seminar.Id, UserOrGroupId = u.Id, AccessLevel = 'Read'));
                                }
                            }
                        }

                        if(lcUsersByMF.containsKey(seminar.Hosting_Franchisee__c)){
                            for (User u : lcUsersByMF.get(seminar.Hosting_Franchisee__c)) {
                                //2.2 Read permission to all TTC/Seminar in status "Processing Application" where the TTC/Seminar.Hosting Francisee = User.MF ID
                                if(seminar.Status__c == 'Processing Application' && u.MF_ID__c == seminar.Hosting_Franchisee__c){
                                    newSharesOnSeminar.add(new Seminar__Share(ParentId = seminar.Id, UserOrGroupId = u.Id, AccessLevel = 'Read'));
                                }
                            }
                        }

                        for (Id accId : mfUsersByAccount.keySet()) {
                            for (User u : mfUsersByAccount.get(accId)) {
                                if(seminar.Status__c == 'Confirmed'){
                                    newSharesOnSeminar.add(new Seminar__Share(ParentId = seminar.Id, UserOrGroupId = u.Id, AccessLevel = 'Read'));
                                }
                            }
                        }

                        if(mfUsersByAccount.containsKey(seminar.Hosting_Franchisee__c)){
                            for (User u : mfUsersByAccount.get(seminar.Hosting_Franchisee__c)) {
                                //1.2 R/W to all TTC/Seminar where the TTC/Seminar.Hosting Francisee= User.Contact.Account
                                if(contacts.get(u.ContactId).AccountId == seminar.Hosting_Franchisee__c){
                                    newSharesOnSeminar.add(new Seminar__Share(ParentId = seminar.Id, UserOrGroupId = u.Id, AccessLevel = 'Edit'));
                                }
                            }
                        }
                    } 

                    if(!newSharesOnSeminar.isEmpty()){
                        Database.SaveResult[] saveResult = database.insert(newSharesOnSeminar,false);
                        logResults(newSharesOnSeminar, saveResult, 'Seminar');
                    } 

                    //Shares on Seminar Teacher
                    List<Seminar_Teachers__Share> newSharesOnST = new List<Seminar_Teachers__Share>();
                    for (Seminar_Teachers__c sTeacher : [SELECT Id, Seminar__r.Hosting_Franchisee__c, Teacher__r.AccountId, Seminar__r.Status__c, Teacher__r.Main_Franchise__c FROM Seminar_Teachers__c WHERE Seminar__r.Hosting_Franchisee__c IN :lcUsersByMF.keySet() OR Seminar__r.Hosting_Franchisee__c IN :mfUsersByAccount.keySet() OR Teacher__r.AccountId IN :mfUsersByAccount.keySet() OR Teacher__r.AccountId IN :lcUsersByMF.keySet()]) { 
                        
                        if(mfUsersByAccount.containsKey(sTeacher.Seminar__r.Hosting_Franchisee__c)){
                            for (User u : mfUsersByAccount.get(sTeacher.Seminar__r.Hosting_Franchisee__c)) {
                                //1.1 R/W Permissions to all Seminar Teacher where Seminar Teacher.TTC/Seminar. Hosting Franchisee= User.Contact.Account
                                if(sTeacher.Seminar__r.Hosting_Franchisee__c == contacts.get(u.ContactId).AccountId){
                                    newSharesOnST.add(new Seminar_Teachers__Share(ParentId = sTeacher.Id, UserOrGroupId = u.Id, AccessLevel = 'Edit'));
                                }
                            }
                        }

                        if(mfUsersByAccount.containsKey(sTeacher.Teacher__r.AccountId)){
                            for (User u : mfUsersByAccount.get(sTeacher.Teacher__r.AccountId)) {
                                //1.2  R/W permission to the Seminar Teacher where Seminar Teacher.Teacher.Account= User.contact.Account
                                if(sTeacher.Teacher__r.AccountId == contacts.get(u.ContactId).AccountId){
                                    newSharesOnST.add(new Seminar_Teachers__Share(ParentId = sTeacher.Id, UserOrGroupId = u.Id, AccessLevel = 'Edit'));
                                }
                            }
                        }

                        System.debug(LoggingLevel.ERROR, '***sTeacher.Seminar__r.Hosting_Franchisee__c : ' + sTeacher.Seminar__r.Hosting_Franchisee__c);
                        System.debug(LoggingLevel.ERROR, '***lcUsersByMF : ' + lcUsersByMF);

                        if(lcUsersByMF.containsKey(sTeacher.Seminar__r.Hosting_Franchisee__c)){
                            for (User u : lcUsersByMF.get(sTeacher.Seminar__r.Hosting_Franchisee__c)) {
                                //2.1 Read Permissions to the Seminar Teacher where TTC/Seminar. Hosting Franchisee = User.MF ID and TTC/Seminar. Status=Confirmed and Seminar Teacher.Teacher.Main Franchisee= User.Account
                                if(sTeacher.Seminar__r.Status__c == 'Confirmed' && sTeacher.Seminar__r.Hosting_Franchisee__c == u.MF_ID__c && sTeacher.Teacher__r.Main_Franchise__c == contacts.get(u.ContactId).AccountId){
                                    newSharesOnST.add(new Seminar_Teachers__Share(ParentId = sTeacher.Id, UserOrGroupId = u.Id, AccessLevel = 'Read'));
                                }
                            }
                        }

                        if(lcUsersByMF.containsKey(sTeacher.Teacher__r.AccountId)){
                            for (User u : lcUsersByMF.get(sTeacher.Teacher__r.AccountId)) {
                                //2.2 Read permission to all Seminar Teacher where Seminar Teacher.Teacher.Account= User.MF ID and TTC/Seminar. Status=Confirmed and Seminar Teacher.Teacher.Main Franchisee= User.Account
                                if(sTeacher.Seminar__r.Status__c == 'Confirmed' && sTeacher.Teacher__r.AccountId == u.MF_ID__c && sTeacher.Teacher__r.Main_Franchise__c == contacts.get(u.ContactId).AccountId){
                                    newSharesOnST.add(new Seminar_Teachers__Share(ParentId = sTeacher.Id, UserOrGroupId = u.Id, AccessLevel = 'Read'));
                                }
                            }
                        }
                    } 

                    if(!newSharesOnST.isEmpty()){
                        Database.SaveResult[] saveResult = database.insert(newSharesOnST,false);
                        logResults(newSharesOnST, saveResult, 'Seminar Teacher');
                    } 
                }

                //SW-23174
                if(!teacherCon.isEmpty()){
                    List<AccountShare> newSharesOnRelAccount = new List<AccountShare>();
                    
                    for(AccountContactRelation cRelation : [SELECT Id, ContactId, AccountId FROM AccountContactRelation WHERE ContactId IN :teacherCon]){
                        newSharesOnRelAccount.add(new AccountShare(AccountId = cRelation.AccountId, UserOrGroupId = contactUser.get(cRelation.ContactId), AccountAccessLevel = 'Read', OpportunityAccessLevel = 'None' ));           
                    }

                    if(!newSharesOnRelAccount.isEmpty()){
                        Database.SaveResult[] saveResult = database.insert(newSharesOnRelAccount,false);
                        logResults(newSharesOnRelAccount, saveResult, 'Seminar Teacher');
                    }

                    //SW-23968
                    List<Seminar_Teachers__Share> newSharesOnST = new List<Seminar_Teachers__Share>();
                    for(Seminar_Teachers__c st : [SELECT Id, Teacher__c FROM Seminar_Teachers__c WHERE Teacher__c IN :teacherCon AND Teacher_Status_in_seminar__c = 'Registered' AND Seminar__r.Status__c IN ('Confirmed','Pending Evaluation','Evaluated')]){
                        newSharesOnST.add(new Seminar_Teachers__Share(ParentId = st.Id, UserOrGroupId = contactUser.get(st.Teacher__c), AccessLevel = 'Read' ));           
                    }

                    if(!newSharesOnST.isEmpty()){
                        Database.SaveResult[] saveResult = database.insert(newSharesOnST,false);
                        logResults(newSharesOnST, saveResult, 'Seminar Teacher');
                    }
                }


                if(!lcConAccRelations.isEmpty()){

                    List<AccountShare> newSharesOnRelAccount = new List<AccountShare>();
                    Map<Id,Id> conAccIds = new Map<Id,Id>();
                    
                    for(AccountContactRelation cRelation : [SELECT Id, ContactId, AccountId FROM AccountContactRelation WHERE AccountId IN :lcConAccRelations]){
                        for (Id uId : accUsers.get(cRelation.AccountId) ) {
                            newSharesOnRelAccount.add(new AccountShare(AccountId = cRelation.AccountId, UserOrGroupId = uId, AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'None' ));           
                        }
                        conAccIds.put(cRelation.ContactId, cRelation.AccountId);
                    }

                    List<Teacher_Agreement__Share> newSharesTA = new List<Teacher_Agreement__Share>();
                    //mapping agreements by contacts
                    Map<Id,Set<Id>> teacherAgreements = new Map<Id,Set<Id>>();
                    for(Teacher_Agreement__c ta : [SELECT Teacher__c FROM Teacher_Agreement__c WHERE Teacher__c IN :conAccIds.keySet() AND Agreement_Status__c = 'Approved']){
                        Id accId = conAccIds.get(ta.Teacher__c);
                        for (Id uId : accUsers.get(accId) ) {
                            newSharesTA.add(new Teacher_Agreement__Share(ParentId = ta.Id, UserOrGroupId = uId, AccessLevel = 'Read'));
                        }
                    }

                    if(!newSharesOnRelAccount.isEmpty()){
                        Database.SaveResult[] newSharingData = database.insert(newSharesOnRelAccount, false); 
                        logResults(newSharesOnRelAccount, newSharingData, 'Account');
                    }

                    if(!newSharesTA.isEmpty()){
                        Database.SaveResult[] newSharingData = database.insert(newSharesTA, false); 
                        logResults(newSharesTA, newSharingData, 'Teacher_Agreement');
                    }
                }
                
                //Enable again the notification.
                NotificationNetworkSetting.enableNotification(new Set<Id>(contactUser.values()));
            }   

            if (System.Test.isRunningTest() && doFail) {
                throw new MyException();
            }         
        }catch(Exception ex){
            
            Database.rollback(sp);
            for(Contact c : (List<Contact>) scope){
                c.User_Creation_Status__c = 'Error Creating User Permission';
                GlobalHelperMethods.debugErrorMsg(ex);
                errorLogs.add(new HD_Log__c(Contact__c = c.Id, Process_Name__c = 'Batch_CreateUserFromContact2', Error_Description__c = GlobalHelperMethods.IncludeAllErrorMessage(ex), Status__c = 'Fail'));
            }
            database.update(scope,false);
        }      
        
        if (!originalOwners.isEmpty()) { // TODO: check if this will be a problem
            restoreContactOwners(scope, originalOwners);
        }
        
    }

    global void finish(Database.BatchableContext BC) {

        //sharing errors log
        if(!userSharingLogs.isEmpty()){
            List<Contact> upContacts = new List<Contact>();
            for (Id conId : userSharingLogs.keySet()) {
                Contact c = new Contact(Id = conId);
                String errorList = '';
                for (String ss : userSharingLogs.get(conId)) {
                    errorList += ', ' + ss;                    
                }
                c.User_Creation_Status__c = 'Error on create Permission';
                // + errorList.substring(2);
                upContacts.add(c);
            }

            //set contact error msg state
            if(!Test.isRunningTest()){
                update upContacts;
            }
        } 
        
        if(!errorLogs.isEmpty()){
            HD_Log__c log = new HD_Log__c(/*Send_Result__c = true, */ Process_Name__c = 'Batch_CreateUserFromContact2', Status__c = 'Fail');
            insert log;
            for(HD_Log__c hl : errorLogs){
                hl.Parent_Log__c = log.Id;
            }
            insert errorLogs;
        }

        /*
        if (!originalOwners.isEmpty()) { // TODO: check if this will be a problem
            restoreContactOwners(originalOwners);
        }
        */

        if(!newMembers.isEmpty()){
            Batch_CreateUserFromContact3 b = new Batch_CreateUserFromContact3();
            b.newMembers = newMembers;
            b.permissionSetAssigns = permissionSetAssigns;
            b.permissionTTAssigns = permissionTTAssigns;

            if(!Test.isRunningTest()){
                Database.executeBatch(b,1);
            }
        }
    }

    public void logResults(List<sObject> sharingList, Database.SaveResult[] saveResult, String objName){
        for(Integer i = 0; i < saveResult.size(); i++){
            Database.SaveResult sr = saveResult.get(i);
            if(!sr.isSuccess() || System.Test.isRunningTest()){
                Id userId = (Id) sharingList[i].get('UserOrGroupId');
                Id conId = userContact.get(userId);
                String errorMsg = 'Test Error';
                if(!System.Test.isRunningTest()){
                    errorMsg = sr.getErrors()[0].getMessage();
                }
                logIns.add(new HD_Log__c(Process_Name__c = 'Batch_CreateUserFromContact2', Error_Description__c = objName + ' : ' + errorMsg, Status__c = 'Fail', Contact__c = conId ));
                
                if (!userSharingLogs.containsKey(conId)) {
                    userSharingLogs.put( conId, new List<String>());
                }
                userSharingLogs.get( conId ).add(objName);
            }
        }
    }

    public static void restoreContactOwners(List<SObject> scope, Map<Id,Map<Id,Id>> originalOwners){
        
        Set<Id> accIds = new Set<Id>();
        for(Contact c : (List<Contact>)scope){
            accIds.add(c.AccountId);
        }
        
        //restore contacts owner          
        List<Contact> restoreContactOwners = new List<Contact>();
        for(Id accId : accIds){
            if(originalOwners.containsKey(accId)){
                for (Id conId : originalOwners.get(accId).keySet()) {
                    restoreContactOwners.add(new Contact(Id = conId, OwnerId = originalOwners.get(accId).get(conId)));
                }
            }
        }
        
        Contact_TriggerHandler.isUserCreationOnProcess = true;
        if(!restoreContactOwners.isEmpty()){
            update restoreContactOwners;
        }        
    }

    public class MyException extends Exception {}

}