/******************************************************************************* 
Name              : Batch_CreateUserFromContact
Description       : Handler the contacts set to create user
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez             06/03/2016          Yaara Nadir               [SW-19584]
2. G. Fernandez             03/01/2016          Yaara Nadir               [SW-23027]
3. G. Fernandez             14/02/2017          Yaara Nadir               [SW-23649]
4. G. Fernandez             02/03/2017          Yaara Nadir               [SW-23868]
5. G. Fernandez             27/03/2017          Dafna Margalit            [SW-24204]
6. G. Fernandez             26/04/2017          Yaara Nadir               [SW-24665]

*******************************************************************************/

global without sharing class Batch_CreateUserFromContact implements Database.Batchable<sObject>, Database.Stateful{
    
    public String query = 'SELECT SET__c, Status__c, Email, FirstName, LastName, RecordTypeId, Direct_Franchisee__c, Account.Name, Account.Direct_Franchisee__c, TT_Qualified__c, Program_Type__c,'+
        ' Account.Account_Type__c, Account.Parent.Account_Type__c, Account.Parent.Parent.Account_Type__c, Account.Parent.Parent.Parent.Account_Type__c,' +
        ' Account.IsPartner, Account.ParentId, Account.RecordTypeId,'+

        ' Account.Partner_Account_User__r.TimeZoneSidKey,Account.Partner_Account_User__r.LocaleSidKey,Account.Partner_Account_User__r.CurrencyIsoCode,Account.Partner_Account_User__r.DefaultCurrencyIsoCode,' +
        ' Account.Parent.Partner_Account_User__r.TimeZoneSidKey,Account.Parent.Partner_Account_User__r.LocaleSidKey,Account.Parent.Partner_Account_User__r.CurrencyIsoCode,Account.Parent.Partner_Account_User__r.DefaultCurrencyIsoCode,' +
        ' Account.Parent.Parent.Partner_Account_User__r.TimeZoneSidKey,Account.Parent.Parent.Partner_Account_User__r.LocaleSidKey,Account.Parent.Parent.Partner_Account_User__r.CurrencyIsoCode,Account.Parent.Parent.Partner_Account_User__r.DefaultCurrencyIsoCode,' +
        ' Account.Parent.Parent.Parent.Partner_Account_User__r.TimeZoneSidKey,Account.Parent.Parent.Parent.Partner_Account_User__r.LocaleSidKey,Account.Parent.Parent.Parent.Partner_Account_User__r.CurrencyIsoCode, Account.Parent.Parent.Parent.Partner_Account_User__r.DefaultCurrencyIsoCode,' +
        
        ' (Select Id, Teacher__r.Contact_Partner_User__c FROM Teachers_Agreements__r),'+ 
        ' Account.Parent.OwnerId, Account.CurrencyIsoCode, User_Creation_Status__c, MailingCountry, Account.BillingCountry, Account.Permitted_Users_per_Account__c,'+
        ' Account.Owner.UserType FROM Contact ';

    static Id recTypeTeacherId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();
    static Id recTypeStaffId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Staff').getRecordTypeId();    
    static Id recTypeFranchiseeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();
    
    static Id recTypeLcSetLsfId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId();
    static Id recTypeMfFpId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();
    
    global Map<String,Id> profiles = new Map<String,Id>();
    global Map<Id,String> profileNames = new Map<Id,String>();

    global Map<Id, Contact> mapContacts2process = new  Map<Id, Contact>(); 
    global Map<Id, User> mapNewUser             = new  Map<Id, User>();
    global Map<Id, String> mapError             = new  Map<Id, String>();
        
    global List<HD_Log__c> errorLogs = new List<HD_Log__c>();
    
    // Only used when execute the batch from the button
    global Boolean isAdditionalUser = false;
    global Id contactId;
   
    global Map<Id,Account> teacherFranchiseAccs = new Map<Id,Account>();
    global Map<Id,Map<Id,Id>> originalOwners = new Map<Id,Map<Id,Id>>();
    global Boolean instancebulkCreationRunning = false;
    
    static Boolean bulkCreationRunning = false;

    global Batch_CreateUserFromContact() {
        
        // For Bulk Running
        instancebulkCreationRunning = true;

        query += ' WHERE User_Creation_Status__c = \'User pending creation - Step 2\'';     
    }
    
    global Batch_CreateUserFromContact(Id convertContactId) {
        
        // For Button Running
        instancebulkCreationRunning = false;
        
        contactId = convertContactId;
 
        Id accId = [SELECT Id, AccountId FROM Contact WHERE Id = :convertContactId].AccountId;
        isAdditionalUser = [SELECT Id FROM User WHERE AccountId = :accId AND IsActive = true].size() > 0;

        query += ' WHERE User_Creation_Status__c = \'Create User\' AND Id = :contactId';
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        for(Profile profile : [SELECT Id, Name FROM Profile]){
            profiles.put(profile.Name, profile.Id);
            profileNames.put(profile.Id,profile.Name);
        } 

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Sobject> scope) {                                    
        
        bulkCreationRunning = instancebulkCreationRunning;
        
        Savepoint sp = Database.setSavepoint();
        try{
            
            List<Id> adminAccs = new List<Id>();
            Set<Id> regularTeacher = new Set<Id>();

            Map<Id, Map<Id,Contact>> contactsByAccId = new Map<Id, Map<Id,Contact>>();
            Map<Id, Contact> scopeContacst2Process = new Map<Id, Contact>();
            
            //one user creation at the time
            //validating and choosing the new user kind
            for(Contact con :(List<Contact>) scope){
                
                scopeContacst2Process.put(con.Id, con);
                
                if(!contactsByAccId.containsKey(con.AccountId)){
                    contactsByAccId.put(con.AccountId, new Map<Id, Contact>());
                }                
                contactsByAccId.get(con.AccountId).put(con.Id, con);
                                
                if( (con.SET__c == true && con.RecordTypeId == recTypeTeacherId ) || con.RecordTypeId == recTypeStaffId || con.RecordTypeId == recTypeFranchiseeId ){
                    
                    //1.2.1.1.1 If the Contact.Account.Owner is not Partner Community User
                    //Contact.Account.isPartner == false
                    if(teacherFranchiseAccs.containsKey(con.Account.Id)) {
                        continue;
                    }

                    //1.2.1.2 Otherwise - If the login user have Admin profile
                    if(UserInfo.getProfileId() == profiles.get('System Administrator')){
                        adminAccs.add(con.AccountId);
                        continue;
                    }else if(isAdditionalUser){
                        //1.2.1.5 Otherwise - If the user don't have Admin profile
                        errorLogs.add(new HD_Log__c(Process_Name__c = 'Batch_CreateUserFromContact', Error_Description__c = 'The franchisee already have one user - for additional user pls contact your AM', Status__c = 'Fail', Contact__c = con.Id));
                        continue;
                    }  

                    //SW-23868
                    //Check if the Contact.Status = Active
                    //If not - display error message using custom label
                    if(con.Status__c != 'Active'){
                        // The franchisee already have one user - for additional user pls contact your AM
                        errorLogs.add(new HD_Log__c(Process_Name__c = 'Batch_CreateUserFromContact', Error_Description__c = Label.Create_User_Not_Active, Status__c = 'Fail', Contact__c = con.Id));
                        continue;
                    }      
                }

                if(con.SET__c == false && con.RecordTypeId == recTypeTeacherId ){
                    if(con.Status__c == 'Active' || con.Status__c == 'Pending Agreement'){
                        Account acc = con.Account;
                        regularTeacher.add(acc.Id);
                        continue;
                    }else{
                        //1.2.1.8.2 If Contact Status <> "Active" or "Pending Agreement" , give Error Message: You can create user only to Active Teachers.
                        errorLogs.add(new HD_Log__c(Process_Name__c = 'Batch_CreateUserFromContact', Error_Description__c = 'You can create user only to Active Teachers.', Status__c = 'Fail', Contact__c = con.Id));
                        continue;                        
                    } 
                }

            }
            
            Set<Id> contactIds4Query = scopeContacst2Process.keySet();
            String query = GlobalHelperMethods.getQueryString(new User()) + ' WHERE ContactId IN: contactIds4Query AND IsActive = true'; 

            // Check existent users for the contact and use it, could have been left for a previous failed run
            Set<Id> existingContactUsers = new Set<Id>();
            for(User user : (List<User>)database.query(query)){ //[SELECT ContactId, AccountId, UserRoleId, IsActive FROM User ]){
                existingContactUsers.add(user.ContactId);                
                
                // Used on the next batch (we will apply the sharing logic to the existing user records  anyway)...
                mapNewUser.put(user.ContactId, user);
                mapError.put(user.ContactId, null);
                mapContacts2process.put(user.ContactId, contactsByAccId.get(user.AccountId).get(user.ContactId));
            }

            Map<Id, User> user2CreateByContact = new Map<Id, User>();
            //1.2.1.1.1.3 Create Partner Community user with Role = Executive to the Contact 
            if(!teacherFranchiseAccs.isEmpty()){
                for ( Account acc : teacherFranchiseAccs.values() ) {   
                    if(contactsByAccId.get(acc.Id) <> null){ 
                        for(Contact c : contactsByAccId.get(acc.Id).values()){
                            if(!existingContactUsers.contains(c.Id)){
                               
                                User newUser = getUserFromContact(c);
                                newUser.PortalRole = 'Executive';
                                if(acc.RecordTypeId == recTypeMfFpId){
                                    newUser.ProfileId = profiles.get('HDC MF User');
                                }else if(acc.RecordTypeId == recTypeLcSetLsfId){
                                    newUser.ProfileId = profiles.get('HDC LC User');
                                }       
                                user2CreateByContact.put(c.Id, newUser);
                                mapContacts2process.put(c.Id, c);
                            }
                        }
                    }
                }
            }
            
            if(!adminAccs.isEmpty()){
                
                Map<Id,List<User>> relatedUsers = new Map<Id,List<User>>();
                for(User u : [SELECT Id, AccountId FROM User WHERE AccountId IN :adminAccs AND IsActive = true  AND (Contact.RecordTypeId = :recTypeStaffId OR Contact.RecordTypeId = :recTypeFranchiseeId)]){
                    if(!relatedUsers.containsKey(u.AccountId)){
                        relatedUsers.put(u.AccountId, new List<User>());                        
                    }
                    relatedUsers.get(u.AccountId).add(u);
                }
                
                //1.2.1.5 If the user don't have Admin profile
                if(!relatedUsers.isEmpty() && UserInfo.getProfileId() != profiles.get('System Administrator')){
                    errorLogs.add(new HD_Log__c(Process_Name__c = 'Batch_CreateUserFromContact', Error_Description__c = 'The franchisee already have one user - for additional user please contact your AM', Status__c = 'Fail'));
                }else{

                    //1.2.1.2 If the login user have Admin profile
                    //1.2.1.4 If the number of existing and active users = Permitted users to Account
                    for(Id accId : adminAccs){
                        for(Contact c : contactsByAccId.get(accId).values()){
                            
                            if(!existingContactUsers.contains(c.Id)){
                            
                                Account acc = c.Account;
                                if(relatedUsers.containsKey(accId) && relatedUsers.get(accId).size() >= acc.Permitted_Users_per_Account__c){
                                    errorLogs.add(new HD_Log__c(Process_Name__c = 'Batch_CreateUserFromContact', Error_Description__c = 'The Franchisee got to the limit of permitted users, please update the "Permitted users to Account, on the Contact.Franchisee layout"', Status__c = 'Fail', Contact__c = c.Id));
                                }else if(!existingContactUsers.contains(c.Id) && (!relatedUsers.containsKey(accId) || (relatedUsers.containsKey(accId) && relatedUsers.get(accId).size() < acc.Permitted_Users_per_Account__c))){
                                    
                                    User newUser = getUserFromContact(c);
        
                                    if(acc.RecordTypeId == recTypeMfFpId){
                                        newUser.ProfileId = profiles.get('HDC MF Logistic');
                                    }else if(acc.RecordTypeId == recTypeLcSetLsfId){
                                        newUser.ProfileId = profiles.get('HDC LC Logistic');
                                    }
                                    newUser.PortalRole = 'Manager';
                                    user2CreateByContact.put(c.Id, newUser);
                                    mapContacts2process.put(c.Id, c);
                                    
                                    if(relatedUsers.containsKey(accId)){
                                        relatedUsers.get(accId).add(newUser); // We are considering the user that we will create...for checking the limit
                                    }
                                }
                            }
                        }
                    }
                }
            }


            //1.2.1.8.1 Create Partner Community user with Role = Partner User & Profile = HDC Teacher User to the Contact
            for(Id accId : regularTeacher){
                
                for(Contact c : contactsByAccId.get(accId).values()){
                    
                    if (!existingContactUsers.contains(c.Id)) {
                        Account acc = c.Account;
                        User newUser = getUserFromContact(c);
                    
                        newUser.ProfileId = profiles.get('HDC Teacher');
                        newUser.PortalRole = 'Worker';
                    
                        user2CreateByContact.put(c.Id, newUser);
                        mapContacts2process.put(c.Id, c);
                    }     
                }           
            }
            
            for(Id conId : scopeContacst2Process.keySet()){
                
                if(!user2CreateByContact.containsKey(conId)){
                    // Not user for creating...
                    if(!existingContactUsers.contains(conId)){ // Just considering as an error when the contact not has user created
                        
                        mapError.put(conId, 'There is nothing to create.');
                        if(!containsContact(errorLogs, conId)){ // For avoiding adding another error log into the transaction
                            errorLogs.add(new HD_Log__c(Contact__c = conId, Process_Name__c = 'Batch_CreateUserFromContact', Error_Description__c = 'There is nothing to create.', Status__c = 'Fail'));
                        }
                        
                        if(!mapContacts2process.containsKey(conId)){
                            mapContacts2process.put(conId, scopeContacst2Process.get(conId));
                        }
                    }                   
                }else{
                
                    Contact contact2process = scopeContacst2Process.get(conId);
                    User user2Create = user2CreateByContact.get(conId);
                                        
                    //new requeriment 31-08-2016
                    //Need to update new customize field on user name: MF ID 
                    Account mfAcc = getMF(contact2process);
                    if(mfAcc != null){
        
                        user2Create.MF_ID__c = mfAcc.Id;
                        //SW-23649
                        //Need to take its Timezone and Local according to its MF details
                        //SW-24665 Need the same logic when the new user.Contsct.Account is with Account Type = FP
                        Boolean typeCond = contact2process.RecordTypeId == recTypeTeacherId || contact2process.Account.RecordTypeId == recTypeLcSetLsfId || contact2process.Account.Account_Type__c=='FP';
                        if(typeCond){
                            //Account mfAcc = [SELECT Partner_Account_User__r.TimeZoneSidKey, Partner_Account_User__r.LocaleSidKey FROM Account WHERE Id = :mf.Id];
                            user2Create.TimeZoneSidKey = mfAcc.Partner_Account_User__r.TimeZoneSidKey;
                            user2Create.LocaleSidKey = mfAcc.Partner_Account_User__r.LocaleSidKey;
                            user2Create.CurrencyIsoCode = mfAcc.Partner_Account_User__r.CurrencyIsoCode;
                            user2Create.DefaultCurrencyIsoCode = mfAcc.Partner_Account_User__r.DefaultCurrencyIsoCode;
                        }
                    }
        
                    //SW-22698
                    if(contact2process.RecordTypeId == recTypeTeacherId && contact2process.TT_Qualified__c == 'TT'){
                        user2Create.TT_Qualified__c = 'TT';
                    }
        
                    //SW-23027
                    String pName = profileNames.get(user2Create.ProfileId);
                    
                    HDC_Mass_Email__c emailSettings =  HDC_Mass_Email__c.getValues(pName);
                    if(emailSettings != null){
                        user2Create.Mass_Email_Limit__c = emailSettings.Mass_Email_Limit__c;
                        user2Create.Mass_Email_Limit_in_Counter_period__c = emailSettings.Mass_Email_Limit_in_Counter_period__c;
                        user2Create.Has_Access_Mass_Email__c = emailSettings.Has_Access_Mass_Email__c;
                    }
                }
            }
            
            Set<Id> userMemeberIds = new Set<Id>();
            List<User> users2Create = user2CreateByContact.values();
            
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.EmailHeader.triggerUserEmail = true;
            dmo.optAllOrNone = false;
            if(bulkCreationRunning){  
                dmo.EmailHeader.triggerUserEmail = false;
            }
                        
            Integer i = 0;
            for(Database.SaveResult sr : Database.insert(users2Create, dmo)){
                system.debug( LoggingLevel.INFO, 'users2Create[i]: ' + users2Create[i] );
                //1.2.1.1.1.4 Update the Contact.Account field: Partner Account User with the Id of the new user
                if(!sr.isSuccess()){
                    system.debug( LoggingLevel.ERROR, 'sr.getErrors()[0].getMessage(): ' + sr.getErrors()[0].getMessage() );
                    system.debug( LoggingLevel.ERROR, 'users2Create[i]: ' + users2Create[i] );
                    mapNewUser.put(users2Create[i].ContactId, null);
                    errorLogs.add(new HD_Log__c(Contact__c = users2Create[i].ContactId, Process_Name__c = 'Batch_CreateUserFromContact', Error_Description__c = sr.getErrors()[0].getMessage(), Status__c = 'Fail'));
                    mapError.put(users2Create[i].ContactId, sr.getErrors()[0].getMessage());
                }else{
                    userMemeberIds.add(users2Create[i].Id);
                    mapNewUser.put(users2Create[i].ContactId, users2Create[i]);
                    mapError.put(users2Create[i].ContactId, null);
                }
                i++;
            }

            // Community network Id  
            Id hdCommId = ContentVersion_Methods.hdCommunityId;            
            List<NetworkMember> nm2Up = new List<NetworkMember>();
            
            for(NetworkMember nm : [SELECT Id FROM NetworkMember WHERE MemberId IN :userMemeberIds AND NetworkId =: hdCommId]){
                //SW-25080
                nm.PreferencesDisableAllFeedsEmail = false;
                /*if(bulkCreationRunning){ // Enabling again the notification on the new users... 
                nm.PreferencesDisableAllFeedsEmail = true;
                }*/
                nm2Up.add(nm);
            }
            if(!nm2Up.isEmpty()){
                database.update(nm2Up,false);
            }
            
            // Was already logged
        }catch(Exception ex){
            System.debug(System.LoggingLevel.ERROR,' Error ' + ex.getMessage() + ' trace ' + ex.getStackTraceString());
            Database.rollback(sp);
            for(Contact c : (List<Contact>) scope){
                c.User_Creation_Status__c = 'Error Creating User';
                errorLogs.add(new HD_Log__c(Contact__c = c.Id, Process_Name__c = 'Batch_CreateUserFromContact', Error_Description__c = GlobalHelperMethods.IncludeAllErrorMessage(ex), Status__c = 'Fail'));
            }
            database.update(scope,false);
        }        
    }

    global void finish(Database.BatchableContext BC) {

        if(!errorLogs.isEmpty()){
            HD_Log__c log = new HD_Log__c(/*Send_Result__c = true, */ Process_Name__c = 'Batch_CreateUserFromContact', Status__c = 'Fail');
            insert log;
            for(HD_Log__c hl : errorLogs){
                hl.Parent_Log__c = log.Id;
            }
            insert errorLogs;
        }

        System.debug(LoggingLevel.INFO, '*** mapNewUser: ' + mapNewUser);

        Batch_CreateUserFromContact2 b = new Batch_CreateUserFromContact2();
        b.mapContacts2process = mapContacts2process;
        b.mapNewUser = mapNewUser;
        b.mapError = mapError;
        b.originalOwners = originalOwners;
        Database.executeBatch(b,1);
    }
    
    public static Boolean containsContact(List<HD_Log__c> errorLogs, Id conId){
        Boolean containsContactLog = false;
        for(HD_Log__c eLog : errorLogs){
            if(eLog.Contact__c == conId){
                containsContactLog = true;
                break;
            }
        }
        return containsContactLog;
    }

    public static User getNickname(String fname, String lname){
        User dummyUser  = new User();

        String username     = fname+lname;
        username = username.replaceAll( '\\s+', '');
        if (username.length() > 40) {
           username = username.substring(0, 39); 
        }
        System.debug(LoggingLevel.INFO, '*** username: ' + username);
        dummyUser.CommunityNickname = username;
        if (username.length() > 8) {
           username = username.substring(0, 7); 
        }
        dummyUser.Alias       = username;               
        System.debug(LoggingLevel.INFO, '*** username: ' + username);

        return dummyUser;
    }

    public static User getUserFromContact(Contact con){
        User newUser        = new User();
        newUser.ContactId   = con.Id;               
        newUser.Username    = con.Email;
        if(newUser.Username == 'hernan@service-wise.com'){
            newUser.Username = 'test'+system.now().getTime()+'@test.com';
        }
        newUser.FirstName   = con.FirstName;
        newUser.LastName    = con.LastName;
        newUser.Email       = con.Email;
        newUser.UserPermissionsMarketingUser = true;

        User dummyUser = getNickname(con.FirstName, con.LastName);
        newUser.CommunityNickname = dummyUser.CommunityNickname;
        newUser.Alias       = dummyUser.Alias;
        newUser.TimeZoneSidKey      = UserInfo.getTimeZone().getID();//'America/Los_Angeles';
        newUser.LocaleSidKey        = UserInfo.getLocale();//'en_US';
        newUser.EmailEncodingKey    = 'UTF-8';
        newUser.LanguageLocaleKey   = 'en_US';
        newUser.CurrencyIsoCode     = con.Account.CurrencyIsoCode;
        newUser.DefaultCurrencyIsoCode     = con.Account.CurrencyIsoCode;
        newUser.IsActive            = true;

        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.EmailHeader.triggerUserEmail = true;
        if(bulkCreationRunning){  
            dmo.EmailHeader.triggerUserEmail = false;
        }

        newUser.setOptions(dmo);
        return newUser;
    }

    /*Called from button to set the contact for convertion*/    
    webservice static String setConvertStatus(Id convertContactId) {
        
        RemoteResponse retVal = new RemoteResponse('Success', Label.Create_User_Message);

        try{
            Contact con = new Contact(Id = convertContactId);
            con.User_Creation_Status__c = 'Create User';
            con.Update_Contact_Permission__c = true;
            update con;

            con = [SELECT SET__c, Account.IsPartner, RecordTypeId, Account.RecordTypeId, Account.Parent.OwnerId, Account.Owner.UserType FROM Contact WHERE Id = :convertContactId];

            Boolean isPartner = con.Account.IsPartner;//con.Account.Owner.UserType == 'PowerPartner';
            
            List<Account> partnerAccLists = new List<Account>();
            Map<Id,Account> partnerAccMap = new Map<Id,Account>();
            Account partnerAcc = con.Account;
            Map<Id,Map<Id,Id>> originalOwners = new Map<Id,Map<Id,Id>>();
            List<Contact> changeOwnerOnContact = new List<Contact>();
            
            if(!isPartner && ( (con.SET__c == true && con.RecordTypeId == recTypeTeacherId ) || con.RecordTypeId == recTypeStaffId || con.RecordTypeId == recTypeFranchiseeId)){
                //1.2.1.1.1 If the Contact.Account.Owner is not Partner Community User
                Id ownerIdAux = partnerAcc.OwnerId;
                if(partnerAcc.Owner.UserType == 'PowerPartner'){
                    partnerAcc.OwnerId = partnerAcc.Parent.OwnerId;
                }   

                partnerAccLists.add(partnerAcc);
                partnerAccMap.put(partnerAcc.Id, partnerAcc);
                System.debug(LoggingLevel.INFO, '*** : partnerAccMap' + partnerAccMap);

                if (partnerAcc.OwnerId != ownerIdAux) {                    
                    update partnerAccLists;
                } 

                //also changing partner user owners on contact, to convert the account
                //and using a map to back again to the original owner after the process
                for (Contact partnerContact : [SELECT Id, OwnerId, AccountId FROM Contact WHERE AccountId = :partnerAcc.Id AND Owner.UserType = 'PowerPartner']) {
                    
                    if(!originalOwners.containsKey(partnerContact.AccountId)){
                        originalOwners.put(partnerContact.AccountId, new Map<Id,Id>());
                    }
                    originalOwners.get(partnerContact.AccountId).put(partnerContact.Id, partnerContact.OwnerId); 
                    
                    partnerContact.OwnerId = partnerAcc.Parent.OwnerId;
                    changeOwnerOnContact.add(partnerContact);
                }           
            }            

            Batch_CreateUserFromContact b = new Batch_CreateUserFromContact(convertContactId);
            
            if(!changeOwnerOnContact.isEmpty()){
                Contact_TriggerHandler.isUserCreationOnProcess = true;
                update changeOwnerOnContact;
                b.originalOwners = originalOwners;
            }

            if (!partnerAccMap.isEmpty()) {
                b.teacherFranchiseAccs = partnerAccMap;
            }

            Database.executeBatch(b,10);

        }catch(Exception e){
            System.debug('Error: ' + e.getMessage() + ' Trace: ' + e.getStackTraceString());
            retVal = new RemoteResponse('Fail','An error occurred during request.');
        }

        return JSON.serialize(retVal);
    }

    @AuraEnabled
    /*Called from button before the convertion, validation things*/
    webservice static String validateConvertRequest(Id convertContactId) { 
        Map<String,Id> profiles = new Map<String,Id>();

        for(Profile profile : [SELECT Id, Name FROM Profile]){
            profiles.put(profile.Name, profile.Id);
        } 

        RemoteResponse retVal = new RemoteResponse('Success',null);
        try{
            if ([SELECT Id FROM User WHERE ContactId = :convertContactId AND IsActive = true].size() != 0) {
                return JSON.serialize(new RemoteResponse('Fail','The contact already have one user - for additional user please contact your AM'));    
            }

            Contact convertContact = [SELECT FirstName, LastName, Account.Owner.UserType, AccountId, SET__c, Account.IsPartner, Account.Permitted_Users_per_Account__c, RecordTypeId, Status__c FROM Contact WHERE Id = :convertContactId];
            
            Boolean isPartner = convertContact.Account.IsPartner;//convertContact.Account.Owner.UserType == 'PowerPartner';
            Boolean isStaff = ((convertContact.SET__c == true && convertContact.RecordTypeId == recTypeTeacherId ) || convertContact.RecordTypeId == recTypeStaffId || convertContact.RecordTypeId == recTypeFranchiseeId );
            Boolean isAdditionalUser = [SELECT Id FROM User WHERE AccountId = :convertContact.AccountId AND IsActive = true].size() > 0;
            
            if(isPartner && isStaff && isAdditionalUser && UserInfo.getProfileId() != profiles.get('System Administrator')){                
                //1.2.1.5 Otherwise - If the user don't have Admin profile
                return JSON.serialize(new RemoteResponse('Fail','The franchisee already have one user - for additional user please contact your AM'));
            }
            
            User[] accUsers = [SELECT Id, AccountId FROM User WHERE AccountId = :convertContact.AccountId AND IsActive = true AND (Contact.RecordTypeId = :recTypeStaffId OR Contact.RecordTypeId = :recTypeFranchiseeId)];

            //1.2.1.4 If the number of existing and active users = Permitted users to Account
            if(isPartner && isStaff && UserInfo.getProfileId() == profiles.get('System Administrator') && (accUsers.size() >= convertContact.Account.Permitted_Users_per_Account__c || convertContact.Account.Permitted_Users_per_Account__c == null ) ){
                return JSON.serialize(new RemoteResponse('Fail','The Franchisee got to the limit of permitted users, pls update the "Permitted users to Account, on the Contact.Franchisee layout"'));
            }

            //SW-23868
            //Check if the Contact.Status = Active
            //If not - display error message using custom label
            if(isStaff && convertContact.Status__c != 'Active'){
                return JSON.serialize(new RemoteResponse('Fail',Label.Create_User_Not_Active)); 
            }

            if(convertContact.SET__c == false && convertContact.RecordTypeId == recTypeTeacherId ){
                if(convertContact.Status__c != 'Active' && convertContact.Status__c != 'Pending Agreement'){
                    //1.2.1.8.2 If Contact Status <> "Active" or "Pending Agreement" , give Error Message: You can create user only to Active or Pending Agreement Teachers.
                    return JSON.serialize(new RemoteResponse('Fail','You can create user only to Active Teachers.')); 
                }
            }

            String nickname = getNickname(convertContact.FirstName,convertContact.LastName).CommunityNickname;
            //Validate nicknames
            if([SELECT Id FROM User WHERE CommunityNickname = :nickname].size() > 0){
               throw new MyException(Label.Contact_Duplicate_Users);
            }

            return setConvertStatus(convertContactId);
                      
        }catch(MyException e){
            System.debug('Error: ' + e.getMessage() + ' Trace: ' + e.getStackTraceString());
            retVal = new RemoteResponse('Fail', e.getMessage());
        }catch(Exception e){
            System.debug('Error: ' + e.getMessage() + ' Trace: ' + e.getStackTraceString());
            retVal = new RemoteResponse('Fail','An error occurred during request.');
        } 

        return JSON.serialize(retVal);
    }


    //return the id of the mf in the herarchy
    public static Account getMF(Contact con){

        Account mf;

        if(con.Account.Account_Type__c == 'MF' && (con.RecordTypeId == recTypeFranchiseeId || con.RecordTypeId == recTypeStaffId)){
            mf = con.Account;
        }

        if(con.RecordTypeId == recTypeTeacherId && con.SET__c == false){
            mf = con.Account;
        }

        Boolean cond = con.Account.Account_Type__c == 'FP' && (con.RecordTypeId == recTypeFranchiseeId || con.RecordTypeId == recTypeStaffId);
        cond = cond || con.Account.RecordTypeId == recTypeLcSetLsfId && (con.RecordTypeId == recTypeFranchiseeId || con.RecordTypeId == recTypeStaffId);
        cond = cond || con.RecordTypeId == recTypeTeacherId && con.SET__c == true;

        if(cond){
            Account directFranchisee = con.Account.Parent;
            for(Integer i = 0; i<3 ; i++){ // navigate to the top level of the account Hierarchy looking for MF
                if(directFranchisee == null){
                    break;
                }
                if(directFranchisee.Account_Type__c == 'MF'){
                    mf = directFranchisee;
                    break;
                }
                directFranchisee = directFranchisee.Parent;
            }
        }

        return mf;
    }

    class RemoteResponse{
        String error;
        String status;
        public RemoteResponse(String p_status, String p_error){
            error = p_error; 
            status = p_status;
        }
    }

    public class MyException extends Exception {}
}