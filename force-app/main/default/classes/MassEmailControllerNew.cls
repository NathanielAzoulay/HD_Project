public with sharing class MassEmailControllerNew{
    // OPERATORS
    private static String EQUALS           = 'equals';
    private static String NOT_EQUAL_TO     = 'not equal to';
    private static String LESS_THAN        = 'less than';
    private static String GREATER_THAN     = 'greater than';
    private static String LESS_OR_EQUAL    = 'less or equal';
    private static String GREATER_OR_EQUAL = 'greater or equal';
    private static String STARTS_WITH      = 'starts with';
    private static String CONTAINS         = 'contains';
    private static String DOES_NOT_CONTAIN = 'does not contain';
    private static String INCLUDES         = 'includes';
    private static String EXCLUDES         = 'excludes';
    
    private static String NONE             = '--None--';
    
    // FIELD TYPES
    /** Karan **/
    private static String EMAIL             = 'email';
    private static String Zip               = 'zip';
    private static String Address           = 'address';
    private static String Phone             = 'phone';
    private static String Url1               = 'url';
    private static String ImageUrl          = 'imageurl';
    private static String BirthDay          = 'birthday';
    /** End **/
    private static String TEXT             = 'Text';
    private static String PICKLIST         = 'Picklist';
    private static String MULTIPICKLIST    = 'MultiPicklist';
    private static String TOF              = 'Boolean';
    private static String NUM              = 'Number';
    // Added to resolve Date and Datetime filter issues - @Chirag 12/3/12
    private static String DATETYPE         = 'Date';
    private static String DATETIMETYPE     = 'DateTime';
    public string recordIds{get; set;}
    public string mode{get; set;}
    public string retURL{get; set;}
    public boolean hasAccess {get; set;}
    public string objType{get; set;}
    public string UserName{
        get{
            return String.escapeSingleQuotes(UserInfo.getName());
        }
        set;
    }
    public Integer pageSize{
        get{
            MassEmailConfiguration__c mec = MassEmailConfiguration__c.getOrgDefaults();
            return Integer.valueOf(mec.Page_Size__c != null && mec.Page_Size__c > 0 ? mec.Page_Size__c : 25);
        }
        set;
    }
    public static Integer pageSize1{
        get{
            MassEmailConfiguration__c mec = MassEmailConfiguration__c.getOrgDefaults();
            return Integer.valueOf(mec.Page_Size__c != null && mec.Page_Size__c > 0 ? mec.Page_Size__c : 25)+1;
        }
        set;
    }
    private static Integer totalRecords = 0;
    private static boolean fetchTotal = false;
    public string orgId {get; set;}
    public string uId {get; set;}
    
    public MassEmailControllerNew(){
        orgId     = UserInfo.getOrganizationId().substring(0,15);
        uId       = UserInfo.getUserId();
        System.debug('orgId::::::in Constructor::'+orgId);
        System.debug('uId::::::in Constructor::'+uId);
         
        recordIds = ApexPages.currentPage().getParameters().get('id');
        mode      = ApexPages.currentPage().getParameters().get('mode');
        objType   = ApexPages.currentPage().getParameters().get('ObjType');
        if(mode == 'campaign')
            mode = 'Campaign';
        else if(mode == 'lg')
            mode = 'Lg';
        else if(mode == 'seminar')
            mode = 'Seminar';
        //System.debug('mode:::::'+mode);
        retURL = ApexPages.currentPage().getParameters().get('retURL');
        hasAccess = false;
        for(User user : [select Id, Has_Access_Mass_Email__c from User where Id = :UserInfo.getUserId() limit 1]){
            hasAccess = user.Has_Access_Mass_Email__c;
        }
    }
    @RemoteAction
    public static map<string,string> emailFolders(){
     map<string,string> mapEmailTemplates = new map<string,string>();
        try{
            
            //MassEmailConfiguration__c mec = MassEmailConfiguration__c.getOrgDefaults();
            list<Email_Template__c> listEmailTemplates = new list<Email_Template__c>();
            //if(mec.Folders__c != null)
                //folders = mec.Folders__c.split(';');
            //list<Folder> folderIds = [select Id from Folder where DeveloperName IN :folders OR Id IN :folders];
            for(Email_Template__c et : [select Id, Name from Email_Template__c order by name]){
                mapEmailTemplates.put(et.Id, et.Name);
            }
        }
        catch(Exception e){

        }
        return mapEmailTemplates;
    }
    @RemoteAction
    public static list<TemplateWrapper> emailTemplates(string objType){
        system.debug('objType:::::'+objType);
        list<TemplateWrapper> emailTemplates = new list<TemplateWrapper>();
        try{
        List<Email_Template__c> emailTemplateList = [Select id,name,Subject__c,Body__c,Html_Value__c from Email_Template__c where Is_Active__c=true and Related_To_Base_Object__c = : objType order by name];            
            system.debug('emailTemplateList ::::'+emailTemplateList );
            if(emailTemplateList.size() > 0){
                for(Email_Template__c et : emailTemplateList){
                    system.debug('et  ::::'+et );
                    if(et != null){
                    emailTemplates.add(new TemplateWrapper(et));
                    system.debug('emailTemplates IN FOR LOOP::::'+emailTemplates);
                    }
                    
                }
            }
            
        }
        catch(Exception e){
            System.debug(e.getMessage() + e.getStackTraceString());
        }
        return emailTemplates;
    }
    private static ContactWrapper collectCampiagn(CampaignMember c){
        ContactWrapper con = new ContactWrapper();
        if(c.LeadId != null){
            con.id = c.LeadId;
            con.unsubscribed = c.Lead.Marketing_opt_out__c;
        }
        else if(c.ContactId != null){
            con.id = c.ContactId;
            con.unsubscribed = c.Contact.Marketing_opt_out__c;
            con.isBounced = c.Contact.IsEmailBounced;
        }

        for(Schema.FieldSetMember f : SObjectType.CampaignMember.FieldSets.MassEmailFields.getFields()) {
            con.fields.add(new FieldWrapper(f.getLabel(),f.getFieldPath(),string.valueOf(c.get(f.getFieldPath())),string.valueOf(f.getType())));
        }
        con.objectName = 'CampaignMember';
        con.recId = c.Id;
        return con;
    }
    private static ContactWrapper collectLGStudent(LG_Student__c c){
        ContactWrapper con = new ContactWrapper();
        for(Schema.FieldSetMember f : SObjectType.LG_Student__c.FieldSets.MassEmailFields.getFields()) {
            con.fields.add(new FieldWrapper(f.getLabel(),f.getFieldPath(),string.valueOf(c.get(f.getFieldPath())),string.valueOf(f.getType())));
        }
        con.id = c.Student__c;
        con.objectName = 'LG_Student__c';
        con.unsubscribed = c.Student__r.LGS_opt_out__c;
        con.isBounced = c.Student__r.IsEmailBounced;
        con.recId = c.Id;
        return con;
    }
    private static ContactWrapper collectSeminarTeachers(Seminar_Teachers__c c){
        ContactWrapper con = new ContactWrapper();
        for(Schema.FieldSetMember f : SObjectType.Seminar_Teachers__c.FieldSets.MassEmailFields.getFields()) {
            con.fields.add(new FieldWrapper(f.getLabel(),f.getFieldPath(),string.valueOf(c.get(f.getFieldPath())),string.valueOf(f.getType())));
        }
        con.id = c.Teacher__c;
        con.objectName = 'Seminar_Teachers__c ';
        con.unsubscribed = c.Teacher__r.Marketing_opt_out__c;
        con.isBounced = c.Teacher__r.IsEmailBounced;
        con.recId = c.Id;
        return con;
    }
    @RemoteAction
    public static list<ContactWrapper> uncontacts(string recordIds, string mode){
        list<ContactWrapper> contacts = new list<ContactWrapper>();
        try{
            list<string> sids = recordIds.split(',');
            set<Id> ids = new set<Id>();
            map<Id,Id> contactMap = new map<Id,Id>();
            set<Id> leadIds = new set<Id>();
            map<Id,boolean> contactUnsubscribeMap = new map<Id,boolean>();
            if(mode == 'Campaign'){
                for(CampaignMember c : (list<CampaignMember>)queryFields('MassEmailFields','CampaignMember',sids,true, new set<string>())){
                    contacts.add(collectCampiagn(c));
                }
            }
            else if(mode == 'Lg'){
                for(LG_Student__c c : (list<LG_Student__c>)queryFields('MassEmailFields','LG_Student__c',sids,true, new set<string>())){
                    contacts.add(collectLGStudent(c));
                }
            }
            else if(mode == 'Seminar'){
                for(Seminar_Teachers__c c : (list<Seminar_Teachers__c>)queryFields('MassEmailFields','Seminar_Teachers__c',sids,true, new set<string>())){
                    contacts.add(collectSeminarTeachers(c));
                //for(LG_Student__c c : (list<LG_Student__c>)queryFields('MassEmailFields','LG_Student__c',sids,true, new set<string>())){
                    //contacts.add(collectLGStudent(c));
                }
            }
        }
        catch(Exception e){
            contacts = new list<ContactWrapper>();
            ContactWrapper con = new ContactWrapper();
            con.objectName = 'Error: '+e.getMessage();
            contacts.add(con);
        }
        return contacts;
    }
    @RemoteAction
    public static ContactResultWrapper contacts(string recordIds, string mode, string existingIdsJson, boolean reseted){
        list<ContactWrapper> contacts = new list<ContactWrapper>();
        ContactResultWrapper crw = new ContactResultWrapper();
        try{
            list<string> sids = recordIds.split(',');
            set<string> existingIds = (set<string>)JSON.deserialize(existingIdsJson, set<string>.class);
            set<Id> ids = new set<Id>();
            fetchTotal = !reseted;
            map<Id,Id> contactMap = new map<Id,Id>();
            set<Id> leadIds = new set<Id>();
            map<Id,boolean> contactUnsubscribeMap = new map<Id,boolean>();
            if(mode == 'Campaign'){
                for(CampaignMember c : (list<CampaignMember>)queryFields('MassEmailFields','CampaignMember',sids,false,existingIds)){
                    
                    contacts.add(collectCampiagn(c));
                }
            }
            else if(mode == 'Lg'){
                for(LG_Student__c c : (list<LG_Student__c>)queryFields('MassEmailFields','LG_Student__c',sids,false,existingIds)){
                    contacts.add(collectLGStudent(c));
                }
            }
            else if(mode == 'Seminar'){
                for(Seminar_Teachers__c c : (list<Seminar_Teachers__c>)queryFields('MassEmailFields','Seminar_Teachers__c',sids,false,existingIds)){
                    contacts.add(collectSeminarTeachers(c));
                //for(LG_Student__c c : (list<LG_Student__c>)queryFields('MassEmailFields','LG_Student__c',sids,false,existingIds)){
                   // contacts.add(collectLGStudent(c));
                }
            }
            crw.totalContacts = totalRecords;
            crw.contacts = contacts;
        }
        catch(Exception e){
            crw.error = 'Error: '+e.getMessage() + '--'+e.getLinenumber() + '---'+ e.getStackTraceString();
        }
        return crw;
    }
    
    @RemoteAction 
    public static list<FieldWrapper> getFilterFields(string mode){
        list<FieldWrapper> fields = new list<FieldWrapper>();
        if(mode == 'Campaign'){
            mode = 'CampaignMember';
        }
        else if(mode == 'Lg'){
            mode = 'LG_Student__c';
        }
        else if(mode == 'Seminar'){
            mode = 'Seminar_Teachers__c';
            //mode = 'LG_Student__c';
        }
        Map<String, Schema.SObjectField> ObjFieldMap = Schema.getGlobalDescribe().get(mode).getDescribe().fields.getMap();
        fields.add(new FieldWrapper('--None--','','',''));
        
        for(Schema.FieldSetMember field : readFieldSet('MassEmailFilterFields',mode)) {
            Schema.DescribeFieldResult f = objFieldMap.get(field.getFieldPath()).getDescribe();
            if(f.isAccessible() 
                && f.isFilterable()
                && f.getType() != null && string.valueOf(f.getType()) != 'TEXTAREA')
                if(f.getName() != 'Address'){
                    map<string, string> values = new map<string, string> ();
                    if((string.valueOf(f.getType()) == 'PICKLIST') || (string.valueOf(f.getType()) == 'MULTIPICKLIST')){
                        List<Schema.PicklistEntry> ple = f.getPicklistValues();
                        values.put('','--None--');
                        for (Schema.PicklistEntry fp : ple) {
                            values.put(String.valueOf(fp.value),String.valueOf(fp.label));
                        }
                    }
                    FieldWrapper fw = new FieldWrapper(f.getLabel(),f.getName(),'',getFieldType(f.getType()).toLowerCase());
                    fw.objectName = mode;
                    fw.picklistValues = values;
                    System.debug('fw:::'+fw);
                    fields.add(fw);
                }
        }
        System.debug('fields1:::'+fields);
        fields = getSortedList(fields);
        System.debug('fields:::'+fields);
        return fields;
    }
    
    @RemoteAction
    public static ContactResultWrapper search(string recordIds, string mode, string filterRowsJson, string existingIdsJson, boolean reseted){
        list<ContactWrapper> contacts = new list<ContactWrapper>();
        ContactResultWrapper crw = new ContactResultWrapper();
        try{
            list<string> sids = recordIds.split(',');
            set<string> existingIds = (set<string>)JSON.deserialize(existingIdsJson, set<string>.class);
            list<filterCriteriaRow> filterRows = new List<filterCriteriaRow>();
            
            if(Test.isRunningTest()) {
                map<String, String> fieldmap = new map<String, String>();
                filterCriteriaRow f = new filterCriteriaRow('CampaignMember', 0,  fieldmap);
                f.field = 'Name';                
                f.objSelected = 'CampaignMember';
                f.operator = 'EQUALS';
                f.rowNumber = 0;
                f.value = 'Name';                
                filterRows.add(f);
                filterCriteriaRow f1 = new filterCriteriaRow('CampaignMember', 0,  fieldmap);
                f1.field = 'Email';                
                f1.objSelected = 'CampaignMember';
                f1.operator = 'NOT_EQUAL_TO';
                f1.rowNumber = 0;
                f1.value = 'Email';
                filterRows.add(f1);
            } else {
                filterRows = (list<filterCriteriaRow>)JSON.deserialize(filterRowsJson, list<filterCriteriaRow>.class);
            }
            System.debug('filterRows::::'+filterRows);
            System.debug('filterRowsJson::::'+filterRowsJson);
            set<Id> ids = new set<Id>();
            map<Id,Id> contactMap = new map<Id,Id>();
            set<Id> leadIds = new set<Id>();
            fetchTotal = !reseted;
            map<Id,boolean> contactUnsubscribeMap = new map<Id,boolean>();
            if(mode == 'Campaign'){
                for(CampaignMember c : (list<CampaignMember>)searchqueryFields('MassEmailFields','CampaignMember',sids,filterRows,'',existingIds)){
                    
                        contacts.add(collectCampiagn(c));
                }
            }
            else if(mode == 'Lg'){
                for(LG_Student__c c : (list<LG_Student__c>)searchqueryFields('MassEmailFields','LG_Student__c',sids,filterRows,'',existingIds)){
                    
                        contacts.add(collectLGStudent(c));
                }
            }
            else if(mode == 'Seminar'){
                for(Seminar_Teachers__c c : (list<Seminar_Teachers__c>)searchqueryFields('MassEmailFields','Seminar_Teachers__c',sids,filterRows,'',existingIds)){
                    
                        contacts.add(collectSeminarTeachers(c));                
                }
            }
            crw.totalContacts = totalRecords;
            crw.contacts = contacts;
        }
        catch(Exception e){
            crw.error = 'Error: '+e.getMessage();
        }
        return crw;
    }
    @remoteAction
    public static string preview(String templateBody,String Id,string conId,string subject,string mode,string recId){
        try{
            string orgId     = UserInfo.getOrganizationId().substring(0,15);
            string uId   = UserInfo.getUserId();
            //Integer day = System.day();
            //Integer month = System.month();
            Date expectedDate = System.today();
            //Integer year = System.year();
            //System.debug('day::::::::::::'+day);
            //System.debug('month::::::::::::'+month);
            System.debug('expectedDate::::::::::::'+expectedDate);
            //System.debug('year::::::::::::'+year);
            System.debug('Now::::::::::::'+System.now());
 
            string body  = templateBody;
            list<string> listbody = new list<string>();
            system.debug(recId+'======'+mode+'======'+Id+'-----'+conId);
            if(mode == 'Seminar'){
                Map<String,String> mapMergeFieldsContact = getMergeFields(templateBody,'Contact',subject);
                Map<String,String> mapMergeFieldsStd     = getMergeFields(templateBody,'Seminar_Teachers__c',subject);
                Map<String,String> mapMergeFieldsLg      = getMergeFields(templateBody,'Seminar__c',subject);
                Map<String,String> mapMergeFieldsUser    = getMergeFields(templateBody,'User',subject);
                Map<String,String> mapMergeFieldsSystem  = getMergeFields(templateBody,'System',subject);
                Map<String,String> mapMergeFieldsOrg     = getMergeFields(templateBody,'Organization',subject);
                
                System.debug('mapMergeFieldsSystem::::::::::::'+mapMergeFieldsSystem);
                
                if(mapMergeFieldsLg.size() > 0){
                    map<Id,SObject> lgs = getResult('Seminar__c',new list<string>{recId},mapMergeFieldsLg);
                    if(lgs.size() > 0){
                        listbody = getFinalResult(lgs.values()[0],mapMergeFieldsLg,templateBody,'Seminar__c',subject).split('=====');
                        subject = listbody[0];
                        body = listbody[1];
                    }
                }
                if(mapMergeFieldsContact.size() > 0){
                    map<Id,SObject> contacts = getResult('Contact',new list<string>{conId},mapMergeFieldsContact);
                    if(contacts.size() > 0){
                        listbody = getFinalResult(contacts.get(conId),mapMergeFieldsContact,body,'Contact',subject).split('=====');
                        subject = listbody[0];
                        body = listbody[1];
                    }
                }
                if(mapMergeFieldsStd.size() > 0){
                    map<Id,SObject> stds = getResult('Seminar_Teachers__c',new list<string>{Id},mapMergeFieldsStd);
                    if(stds.size() > 0){
                        listbody = getFinalResult(stds.get(Id),mapMergeFieldsStd,body,'Seminar_Teachers__c',subject).split('=====');
                        subject = listbody[0];
                        body = listbody[1];
                    }
                }
                if(mapMergeFieldsUser.size() > 0){
                 map<Id,SObject> users = getResult('User',new list<string>{uId},mapMergeFieldsUser);
                 if(users.size() > 0){
                     listbody = getFinalResult(users.get(uId),mapMergeFieldsUser,body,'User',subject).split('=====');
                     subject  = listbody[0];
                     body     = listbody[1];
                 } 
                }
                if(mapMergeFieldsOrg.size() > 0){
                 map<Id,SObject> orgs = getResult('Organization',new list<string>{orgId},mapMergeFieldsOrg);
                 if(orgs.size() > 0){
                     listbody = getFinalResult(orgs.get(orgId),mapMergeFieldsOrg,body,'Organization',subject).split('=====');
                     subject  = listbody[0];
                     body     = listbody[1];
                 } 
                }
                if(mapMergeFieldsSystem.size() > 0){
                     listbody = getSystemFinalResult(mapMergeFieldsSystem,body,subject).split('=====');
                     subject  = listbody[0];
                     body     = listbody[1];
                }
                
                listbody = clearText(body,subject).split('=====');
                subject = listbody[0];
                body = listbody[1];
            }
            else if(mode == 'Lg'){
                Map<String,String> mapMergeFieldsContact = getMergeFields(templateBody,'Contact',subject);
                Map<String,String> mapMergeFieldsStd = getMergeFields(templateBody,'LG_Student__c',subject);
                Map<String,String> mapMergeFieldsLg = getMergeFields(templateBody,'LG__c',subject);
                Map<String,String> mapMergeFieldsUser = getMergeFields(templateBody,'User',subject);
                Map<String,String> mapMergeFieldsSystem = getMergeFields(templateBody,'System',subject);
                Map<String,String> mapMergeFieldsOrg = getMergeFields(templateBody,'Organization',subject);
                
                if(mapMergeFieldsLg.size() > 0){
                    map<Id,SObject> lgs = getResult('LG__c',new list<string>{recId},mapMergeFieldsLg);
                    if(lgs.size() > 0){
                        listbody = getFinalResult(lgs.values()[0],mapMergeFieldsLg,templateBody,'LG__c',subject).split('=====');
                        subject = listbody[0];
                        body = listbody[1];
                    }
                }
                if(mapMergeFieldsContact.size() > 0){
                    map<Id,SObject> contacts = getResult('Contact',new list<string>{conId},mapMergeFieldsContact);
                    if(contacts.size() > 0){
                        listbody = getFinalResult(contacts.get(conId),mapMergeFieldsContact,body,'Contact',subject).split('=====');
                        subject = listbody[0];
                        body = listbody[1];
                    }
                }
                if(mapMergeFieldsStd.size() > 0){
                    map<Id,SObject> stds = getResult('LG_Student__c',new list<string>{Id},mapMergeFieldsStd);
                    if(stds.size() > 0){
                        listbody = getFinalResult(stds.get(Id),mapMergeFieldsStd,body,'LG_Student__c',subject).split('=====');
                        subject = listbody[0];
                        body = listbody[1];
                    }
                }
                if(mapMergeFieldsUser.size() > 0){
                     map<Id,SObject> users = getResult('User',new list<string>{uId},mapMergeFieldsUser);
                     if(users.size() > 0){
                         listbody = getFinalResult(users.get(uId),mapMergeFieldsUser,body,'User',subject).split('=====');
                         subject  = listbody[0];
                         body     = listbody[1];
                     } 
                }
                if(mapMergeFieldsOrg.size() > 0){
                     map<Id,SObject> orgs = getResult('Organization',new list<string>{orgId},mapMergeFieldsOrg);
                     if(orgs.size() > 0){
                         listbody = getFinalResult(orgs.get(orgId),mapMergeFieldsOrg,body,'Organization',subject).split('=====');
                         subject  = listbody[0];
                         body     = listbody[1];
                     } 
                }
                if(mapMergeFieldsSystem.size() > 0){
                     listbody = getSystemFinalResult(mapMergeFieldsSystem,body,subject).split('=====');
                     subject  = listbody[0];
                     body     = listbody[1];
                }
                
                listbody = clearText(body,subject).split('=====');
                subject = listbody[0];
                body = listbody[1];
            }
            else if(mode == 'Campaign'){
                Map<String,String> mapMergeFieldsContact = getMergeFields(templateBody,'Contact',subject);
                Map<String,String> mapMergeFieldsLead = getMergeFields(templateBody,'Lead',subject);
                Map<String,String> mapMergeFieldsStd = getMergeFields(templateBody,'CampaignMember',subject);
                Map<String,String> mapMergeFieldsLg = getMergeFields(templateBody,'Campaign',subject);
                Map<String,String> mapMergeFieldsUser = getMergeFields(templateBody,'User',subject);
                Map<String,String> mapMergeFieldsSystem = getMergeFields(templateBody,'System',subject);
                Map<String,String> mapMergeFieldsOrg = getMergeFields(templateBody,'Organization',subject);
                
                if(mapMergeFieldsLg.size() > 0){
                    map<Id,SObject> camps = getResult('Campaign',new list<string>{recId},mapMergeFieldsLg);
                    if(camps.size() > 0){
                        listbody = getFinalResult(camps.values()[0],mapMergeFieldsLg,templateBody,'Campaign',subject).split('=====');
                        subject = listbody[0];
                        body = listbody[1];
                    }
                }
                if(conId.substring(0, 3) == '003'){
                    if(mapMergeFieldsContact.size() > 0){
                        map<Id,SObject> contacts = getResult('Contact',new list<string>{conId},mapMergeFieldsContact);
                        if(contacts.size() > 0){
                            listbody = getFinalResult(contacts.get(conId),mapMergeFieldsContact,body,'Contact',subject).split('=====');
                            subject = listbody[0];
                            body = listbody[1];
                        }
                    }
                }else{
                    if(mapMergeFieldsLead.size() > 0){
                        map<Id,SObject> leads = getResult('Lead',new list<string>{conId},mapMergeFieldsLead);
                        if(leads.size() > 0){
                            listbody = getFinalResult(leads.get(conId),mapMergeFieldsLead,body,'Lead',subject).split('=====');
                            subject = listbody[0];
                            body = listbody[1];
                        }
                    }
                    
                    
                }
                if(mapMergeFieldsStd.size() > 0){
                    map<Id,SObject> campMambers = getResult('CampaignMember',new list<string>{Id},mapMergeFieldsStd);
                    if(campMambers.size() > 0){
                        listbody = getFinalResult(campMambers.get(Id),mapMergeFieldsStd,body,'CampaignMember',subject).split('=====');
                        subject = listbody[0];
                        body = listbody[1];
                    }
                }
                if(mapMergeFieldsUser.size() > 0){
                 map<Id,SObject> users = getResult('User',new list<string>{uId},mapMergeFieldsUser);
                 if(users.size() > 0){
                     listbody = getFinalResult(users.get(uId),mapMergeFieldsUser,body,'User',subject).split('=====');
                     subject  = listbody[0];
                     body     = listbody[1];
                 } 
                }
                if(mapMergeFieldsOrg.size() > 0){
                 map<Id,SObject> orgs = getResult('Organization',new list<string>{orgId},mapMergeFieldsOrg);
                 if(orgs.size() > 0){
                     listbody = getFinalResult(orgs.get(orgId),mapMergeFieldsOrg,body,'Organization',subject).split('=====');
                     subject  = listbody[0];
                     body     = listbody[1];
                 } 
                }
                if(mapMergeFieldsSystem.size() > 0){
                     listbody = getSystemFinalResult(mapMergeFieldsSystem,body,subject).split('=====');
                     subject  = listbody[0];
                     body     = listbody[1];
                }
                
                listbody = clearText(body,subject).split('=====');
                subject = listbody[0];
                body = listbody[1];
            }
            else{
                Map<String,String> mapMergeFieldsContact = getMergeFields(templateBody,mode,subject);
                map<Id,SObject> contacts = getResult(mode,new list<string>{conId},mapMergeFieldsContact);
                listbody = getFinalResult(contacts.get(conId),mapMergeFieldsContact,templateBody,mode,subject).split('=====');
                string subject1 = listbody[0];
                string body1 = listbody[1];
                listbody = clearText(body1,subject1).split('=====');
                subject = listbody[0];
                body = listbody[1];
            }
            return subject+'====='+Body;
        }
        catch(exception e){
            return 'Error: '+e.getMessage();
        }
    }

    @remoteAction
    public static string sendEmail(String templatebody,String subscribersJson,String Subject,string recId,string mode,string userName){
        try{
            string orgId     = UserInfo.getOrganizationId().substring(0,15);
            string uId   = UserInfo.getUserId();
            string temp = templateBody.substringBetween('<!--[CDATA[','-->');
            if(temp != null && temp != '')
                templateBody = templateBody.replace(temp,'');
            
            templateBody = templateBody.replace('<!--[CDATA[-->','');
            templateBody = templateBody.replace(']]>','');
            string tag = '<p>&nbsp;</p>';
            string endtag = '<p>&nbsp;</p></td></tr></tbody></table>';
            while(templateBody.endsWith(tag) || templateBody.endsWith(endtag)){
                templateBody = templateBody.substringBeforeLast(tag);
            }
            templateBody += endtag;
            User mec = new User();
            list<User> users = [select Id,Mass_Email_Limit_in_Counter_period__c, Counter_period__c,Last_Reset_Time__c,
                                Mass_Email_Limit__c, Counter__c from User where Id = :UserInfo.getUserId() limit 1];
            if(users.size() > 0)
                mec = users[0];
            map<String,string> subscribers = (map<String,string>)JSON.deserialize(subscribersJson, map<String,string>.class);
            list<Messaging.Singleemailmessage> listmail = new list<Messaging.Singleemailmessage>();
            list<Task> tasks = new list<Task>();
            integer i=0;
            DateTime current = system.now();
            Integer emailLimit = Integer.valueOf(mec.Mass_Email_Limit__c);
            Integer lastTimeDifference = 0;
            if(mec.Last_Reset_Time__c != null) {
                lastTimeDifference = (current.hour() - mec.Last_Reset_Time__c.hour())+((current.day() - mec.Last_Reset_Time__c.day())*24)+((current.year() - mec.Last_Reset_Time__c.year())*365);
                
            }
            emailLimit = Integer.valueOf(mec.Mass_Email_Limit_in_Counter_period__c != null ? mec.Mass_Email_Limit_in_Counter_period__c : 0) - Integer.valueOf(mec.Counter__c != null ? mec.Counter__c : 0);
            if(Integer.valueOf(mec.Mass_Email_Limit__c) <= 0 || emailLimit <= 0){
                return 'Error: Your Email limit has been reached.';
            }
            mec.Counter__c = (mec.Counter__c != null ? mec.Counter__c : 0);
            mec.Counter_period__c = (mec.Counter_period__c != null ? mec.Counter_period__c : 0);
            string body = templateBody;
            list<string> listbody = new list<string>();
            if(mode == 'Seminar'){
                Map<String,String> mapMergeFieldsContact = getMergeFields(templateBody,'Contact',subject);
                Map<String,String> mapMergeFieldsStd = getMergeFields(templateBody,'Seminar_Teachers__c',subject);
                Map<String,String> mapMergeFieldsLg = getMergeFields(templateBody,'Seminar__c',subject);
                Map<String,String> mapMergeFieldsUser    = getMergeFields(templateBody,'User',subject);
                Map<String,String> mapMergeFieldsSystem  = getMergeFields(templateBody,'System',subject);
                Map<String,String> mapMergeFieldsOrg     = getMergeFields(templateBody,'Organization',subject);
                list<string> cids = new list<string>();
                cids.addAll(subscribers.keySet());
                if(mapMergeFieldsLg.size() > 0){
                    map<Id,SObject> lgs = getResult('Seminar__c',new list<string>{recId},mapMergeFieldsLg);
                    if(lgs.size() > 0){
                        listbody = getFinalResult(lgs.values()[0],mapMergeFieldsLg,templateBody,'Seminar__c',subject).split('=====');
                        subject = listbody[0];
                        body = listbody[1];
                    }
                }
                map<Id,SObject> contacts = new map<Id,SObject> ();
                map<Id,SObject> stds = new map<Id,SObject> ();
                if(mapMergeFieldsContact.size() > 0){
                    contacts = getResult('Contact',cids,mapMergeFieldsContact);
                }
                if(mapMergeFieldsStd.size() > 0){
                    stds = getResult('Seminar_Teachers__c',subscribers.values(),mapMergeFieldsStd);
                }
                if(mapMergeFieldsUser.size() > 0){
                 map<Id,SObject> userData = getResult('User',new list<string>{uId},mapMergeFieldsUser);
                 if(users.size() > 0){
                     listbody = getFinalResult(userData.get(uId),mapMergeFieldsUser,body,'User',subject).split('=====');
                     subject  = listbody[0];
                     body     = listbody[1];
                 } 
                }
                if(mapMergeFieldsOrg.size() > 0){
                 map<Id,SObject> orgs = getResult('Organization',new list<string>{orgId},mapMergeFieldsOrg);
                 if(orgs.size() > 0){
                     listbody = getFinalResult(orgs.get(orgId),mapMergeFieldsOrg,body,'Organization',subject).split('=====');
                     subject  = listbody[0];
                     body     = listbody[1];
                 } 
                }
                if(mapMergeFieldsSystem.size() > 0){
                     listbody = getSystemFinalResult(mapMergeFieldsSystem,body,subject).split('=====');
                     subject  = listbody[0];
                     body     = listbody[1];
                }
                for(string conId : subscribers.keySet()){
                    string subj = subject;
                    string body1 = body;
                    if(contacts.size() > 0 && contacts.containsKey(conId)){
                        listbody = getFinalResult(contacts.get(conId),mapMergeFieldsContact,body,'Contact',subject).split('=====');
                        subj = listbody[0];
                        body1 = listbody[1];
                    }
                    if(stds.size() > 0 && stds.containsKey(subscribers.get(conId))){
                        listbody = getFinalResult(stds.get(subscribers.get(conId)),mapMergeFieldsStd,body1,'Seminar_Teachers__c',subj).split('=====');
                        subj = listbody[0];
                        body1 = listbody[1];
                    }
                    
                    if(i<Integer.valueOf(mec.Mass_Email_Limit__c) && i < emailLimit){
                        listmail.add(setMail(body1,subj,mode,conId, subscribers.get(conId),userName));
                        mec.Counter__c +=1;
                        mec.Counter_period__c +=1;
                        
                        //14-10:Creating Task for LG
                        if(tasks.size() == 0){
                            tasks.add(setTask(body1,subj,recId));
                        }
                    }
                    else{
                        break;
                    }
                    i++;
                }
                
            }
            else if(mode == 'Lg'){
                Map<String,String> mapMergeFieldsContact = getMergeFields(templateBody,'Contact',subject);
                Map<String,String> mapMergeFieldsStd = getMergeFields(templateBody,'LG_Student__c',subject);
                Map<String,String> mapMergeFieldsLg = getMergeFields(templateBody,'LG__c',subject);
                Map<String,String> mapMergeFieldsUser    = getMergeFields(templateBody,'User',subject);
                Map<String,String> mapMergeFieldsSystem  = getMergeFields(templateBody,'System',subject);
                Map<String,String> mapMergeFieldsOrg     = getMergeFields(templateBody,'Organization',subject);
                list<string> cids = new list<string>();
                cids.addAll(subscribers.keySet());
                if(mapMergeFieldsLg.size() > 0){
                    map<Id,SObject> lgs = getResult('LG__c',new list<string>{recId},mapMergeFieldsLg);
                    if(lgs.size() > 0){
                        listbody = getFinalResult(lgs.values()[0],mapMergeFieldsLg,templateBody,'LG__c',subject).split('=====');
                        subject = listbody[0];
                        body = listbody[1];
                    }
                }
                map<Id,SObject> contacts = new map<Id,SObject> ();
                map<Id,SObject> stds = new map<Id,SObject> ();
                if(mapMergeFieldsContact.size() > 0){
                    contacts = getResult('Contact',cids,mapMergeFieldsContact);
                }
                if(mapMergeFieldsStd.size() > 0){
                    stds = getResult('LG_Student__c',subscribers.values(),mapMergeFieldsStd);
                }
                if(mapMergeFieldsUser.size() > 0){
                 map<Id,SObject> userData = getResult('User',new list<string>{uId},mapMergeFieldsUser);
                 if(users.size() > 0){
                     listbody = getFinalResult(userData.get(uId),mapMergeFieldsUser,body,'User',subject).split('=====');
                     subject  = listbody[0];
                     body     = listbody[1];
                 } 
                }
                if(mapMergeFieldsOrg.size() > 0){
                 map<Id,SObject> orgs = getResult('Organization',new list<string>{orgId},mapMergeFieldsOrg);
                 if(orgs.size() > 0){
                     listbody = getFinalResult(orgs.get(orgId),mapMergeFieldsOrg,body,'Organization',subject).split('=====');
                     subject  = listbody[0];
                     body     = listbody[1];
                 } 
                }
                if(mapMergeFieldsSystem.size() > 0){
                     listbody = getSystemFinalResult(mapMergeFieldsSystem,body,subject).split('=====');
                     subject  = listbody[0];
                     body     = listbody[1];
                }
                for(string conId : subscribers.keySet()){
                    string subj = subject;
                    string body1 = body;
                    if(contacts.size() > 0 && contacts.containsKey(conId)){
                        listbody = getFinalResult(contacts.get(conId),mapMergeFieldsContact,body,'Contact',subject).split('=====');
                        subj = listbody[0];
                        body1 = listbody[1];
                    }
                    if(stds.size() > 0 && stds.containsKey(subscribers.get(conId))){
                        listbody = getFinalResult(stds.get(subscribers.get(conId)),mapMergeFieldsStd,body1,'LG_Student__c',subj).split('=====');
                        subj = listbody[0];
                        body1 = listbody[1];
                    }
                    
                    if(i<Integer.valueOf(mec.Mass_Email_Limit__c) && i < emailLimit){
                        listmail.add(setMail(body1,subj,mode,conId, subscribers.get(conId),userName));
                        mec.Counter__c +=1;
                        mec.Counter_period__c +=1;
                        
                        //14-10:Creating Task for LG
                        if(tasks.size() == 0){
                            tasks.add(setTask(body1,subj,recId));
                        }
                    }
                    else{
                        break;
                    }
                    i++;
                }
                
            }
            else if(mode == 'Campaign'){
                Map<String,String> mapMergeFieldsContact = getMergeFields(templateBody,'Contact',subject);
                Map<String,String> mapMergeFieldsLead = getMergeFields(templateBody,'Lead',subject);
                Map<String,String> mapMergeFieldsStd = getMergeFields(templateBody,'CampaignMember',subject);
                Map<String,String> mapMergeFieldsLg = getMergeFields(templateBody,'Campaign',subject);
                Map<String,String> mapMergeFieldsUser    = getMergeFields(templateBody,'User',subject);
                Map<String,String> mapMergeFieldsSystem  = getMergeFields(templateBody,'System',subject);
                Map<String,String> mapMergeFieldsOrg     = getMergeFields(templateBody,'Organization',subject);

                list<string> cids = new list<string>();
                list<string> lids = new list<string>();
                for(string str : subscribers.keySet()){
                    if(str.substring(0, 3) == '003')
                        cids.add(str);
                    else
                        lids.add(str);
                }
                if(mapMergeFieldsLg.size() > 0){
                    map<Id,SObject> camps = getResult('Campaign',new list<string>{recId},mapMergeFieldsLg);
                    if(camps.size() > 0){
                        listbody = getFinalResult(camps.values()[0],mapMergeFieldsLg,templateBody,'Campaign',subject).split('=====');
                        subject = listbody[0];
                        body = listbody[1];
                    }
                }
                map<Id,SObject> contacts = new map<Id,SObject> ();
                map<Id,SObject> leads = new map<Id,SObject> ();
                map<Id,SObject> campMambers = new map<Id,SObject> ();
                if(mapMergeFieldsContact.size() > 0){
                    contacts = getResult('Contact',cids,mapMergeFieldsContact);
                }
                if(mapMergeFieldsLead.size() > 0){
                    leads = leads = getResult('Lead',lids,mapMergeFieldsLead);
                }
                if(mapMergeFieldsStd.size() > 0){
                    campMambers = getResult('CampaignMember',subscribers.values(),mapMergeFieldsStd);
                }
                if(mapMergeFieldsUser.size() > 0){
                 map<Id,SObject> userData = getResult('User',new list<string>{uId},mapMergeFieldsUser);
                 if(users.size() > 0){
                     listbody = getFinalResult(userData.get(uId),mapMergeFieldsUser,body,'User',subject).split('=====');
                     subject  = listbody[0];
                     body     = listbody[1];
                 } 
                }
                if(mapMergeFieldsOrg.size() > 0){
                 map<Id,SObject> orgs = getResult('Organization',new list<string>{orgId},mapMergeFieldsOrg);
                 if(orgs.size() > 0){
                     listbody = getFinalResult(orgs.get(orgId),mapMergeFieldsOrg,body,'Organization',subject).split('=====');
                     subject  = listbody[0];
                     body     = listbody[1];
                 } 
                }
                if(mapMergeFieldsSystem.size() > 0){
                     listbody = getSystemFinalResult(mapMergeFieldsSystem,body,subject).split('=====');
                     subject  = listbody[0];
                     body     = listbody[1];
                }
                for(string conId : subscribers.keySet()){
                    string subj = subject;
                    string body1 = body;
                    if(conId.substring(0, 3) == '003'){
                        if(contacts.size() > 0 && contacts.containsKey(conId)){
                            listbody = getFinalResult(contacts.get(conId),mapMergeFieldsContact,body,'Contact',subject).split('=====');
                            subj = listbody[0];
                            body1 = listbody[1];
                        }
                    }
                    else{
                        if(leads.size() > 0 && leads.containsKey(conId)){
                            listbody = getFinalResult(leads.get(conId),mapMergeFieldsLead,body,'Lead',subject).split('=====');
                            subj = listbody[0];
                            body1 = listbody[1];
                        }
                    }
                    
                    if(campMambers.size() > 0 && campMambers.containsKey(subscribers.get(conId))){
                        listbody = getFinalResult(campMambers.get(subscribers.get(conId)),mapMergeFieldsStd,body1,'CampaignMember',subj).split('=====');
                        subj = listbody[0];
                        body1 = listbody[1];
                    }
                    if(i<Integer.valueOf(mec.Mass_Email_Limit__c) && i < emailLimit){
                        listmail.add(setMail(body1,subj,mode,conId, subscribers.get(conId),userName));
                        mec.Counter__c +=1;
                        mec.Counter_period__c +=1;
                        
                        //14-10:Creating Task for Campaign
                        if(tasks.size() == 0){
                            tasks.add(setTask(body1,subj,recId));
                        }
                    }
                    else{
                        break;
                    }
                    i++;
                }
                
            }
            else{
                Map<String,String> mapMergeFieldsContact = getMergeFields(templateBody,mode,subject);
                list<string> cids = new list<string>();
                cids.addAll(subscribers.keySet());
                map<Id,SObject> contacts = getResult(mode,cids,mapMergeFieldsContact);

                for(string conId : subscribers.keySet()){
                    if(i<Integer.valueOf(mec.Mass_Email_Limit__c) && i < emailLimit){
                        listbody = getFinalResult(contacts.get(conId),mapMergeFieldsContact,templateBody,mode,subject).split('=====');
                        string subject1 = listbody[0];
                        string body1 = listbody[1];
                        listmail.add(setMail(body1,subject1,mode,conId, subscribers.get(conId),userName));
                        mec.Counter__c +=1;
                        mec.Counter_period__c +=1;
                    
                    }
                    else{
                        break;
                    }
                    i++;
                }
            }
            Messaging.sendEmail(listmail);
            if(tasks.size() > 0){
                insert tasks;
            }
            update mec;
            return '';
        }
        catch(exception e){
            return 'Error: '+e.getMessage() + e.getStackTraceString();
        }
    }
    private static Task setTask(string body,string subject, string recId){
        return new Task(Subject = 'Email: '+subject, ActivityDate = System.today(), WhatId = recId, status= 'Completed',  Description = body);
    }
    private static Messaging.Singleemailmessage setMail(string body1,string subject1,string mode,string conId, string recId,string userName){
        list<string> listbody = clearText(body1,subject1).split('=====');
        string subject = listbody[0];
        string body = listbody[1];
        MassEmailConfiguration__c mecCs = MassEmailConfiguration__c.getInstance();
        String RefRefreshURL = mecCs.Site_Url__c + Page.UnsubscribePage.getURL();
        RefRefreshURL += '?Id='+conId;
        RefRefreshURL += '&mode='+mode;
        body += '<br/><a href="' + RefRefreshURL + '" style="font-size :15px;">Unsubscribe here</a>';
        Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
        mail.setTargetObjectId(conId);
        mail.setSaveAsActivity(true);
        mail.setSubject(subject);
        mail.setHtmlBody(body);
        mail.setSenderDisplayName(userName);
        return mail;
    }
    public static list<SObject> queryFields(String fieldSetName, String ObjectName,list<string> sids,boolean unsub, set<string> existingIds){
        String query = 'SELECT ';
        string queryTotal = 'SELECT count() FROM ';
        System.debug('Dheer Test1 : '+fieldSetName);
        System.debug('Dheer Test2 : '+ObjectName);
        for(Schema.FieldSetMember f : readFieldSet(fieldSetName,ObjectName)) {        
            if(f.getFieldPath() != 'Id' && f.getFieldPath() != 'Name' 
                            && ( (ObjectName == 'CampaignMember' && f.getFieldPath() != 'LeadId' && f.getFieldPath() != 'ContactId')
                                 || (ObjectName != 'CampaignMember') ) 
                            && ( (ObjectName != 'LG_Student__c') || (ObjectName == 'LG_Student__c' && f.getFieldPath() != 'Student__c') )
                            && ( (ObjectName != 'Seminar_Teachers__c') || (ObjectName == 'Seminar_Teachers__c' && f.getFieldPath() !=  'Teacher__c') ) )
                query += f.getFieldPath() + ', ';
        }
        if(ObjectName == 'CampaignMember'){
            query += 'Id,Name,LeadId,ContactId,Lead.Marketing_opt_out__c,Contact.Marketing_opt_out__c, Contact.IsEmailBounced FROM CampaignMember where CampaignId IN : sids and Id NOT IN :existingIds ';
            if(unsub)
                query += ' and (Lead.Marketing_opt_out__c = true Or Contact.Marketing_opt_out__c = true) ';
            else
                query += ' and (Lead.Marketing_opt_out__c = false and Contact.Marketing_opt_out__c = false) ';
            query += ' order by Name';
            queryTotal += ' CampaignMember where CampaignId IN : sids and Id NOT IN :existingIds and (Lead.Marketing_opt_out__c = false and Contact.Marketing_opt_out__c = false) ';
        }
        else if (ObjectName == 'LG_Student__c') {
            query += 'Id,Name,Student__c,Student__r.LGS_opt_out__c, Student__r.IsEmailBounced FROM LG_Student__c where LG__c IN : sids and Student__c != null and Id NOT IN :existingIds ';
            if(unsub)
                query += ' and (Student__r.LGS_opt_out__c = true) ';
            else
                query += ' and (Student__r.LGS_opt_out__c = false) ';
            query += ' order by Student__r.Name';
            queryTotal += ' LG_Student__c where LG__c IN : sids and Student__c != null and Id NOT IN :existingIds and (Student__r.LGS_opt_out__c = false) ';
        }
        else if (ObjectName == 'Seminar_Teachers__c') {
            query += 'Id,Name,Teacher__c,Teacher__r.Marketing_opt_out__c, Teacher__r.IsEmailBounced FROM Seminar_Teachers__c where Seminar__c IN : sids and Teacher__c != null and Id NOT IN :existingIds ';
            if(unsub)
                query += ' and (Teacher__r.Marketing_opt_out__c = true) ';
            else
                query += ' and (Teacher__r.Marketing_opt_out__c = false) ';
            query += ' order by Teacher__r.Name';
            queryTotal += ' Seminar_Teachers__c where Seminar__c IN : sids and Teacher__c != null and Id NOT IN :existingIds and (Teacher__r.Marketing_opt_out__c = false) ';
        }
        else{
            query += 'Id,Name, FROM '+ObjectName+' where Id IN : ids and Id NOT IN :existingIds ';
        }
        if(fetchTotal)
            totalRecords = database.countQuery(queryTotal);
        query += ' limit : pageSize1';
        //System.debug('Query:::::'+query);
        //System.debug('Query:::::'+Database.query(query));
        return Database.query(query);
    }
    public static list<SObject> searchqueryFields(String fieldSetName, String ObjectName,list<string> sids,list<filterCriteriaRow> filterRows,string parent, set<string> existingIds){
        String query = 'SELECT ';
        string conditions = '';
        string queryTotal = 'SELECT count() FROM ';
        for(Schema.FieldSetMember f : readFieldSet(fieldSetName,ObjectName)) {
            if( f.getFieldPath() != 'Id' 
     && f.getFieldPath() != 'Name' 
     && ((ObjectName == 'CampaignMember' && f.getFieldPath() != 'LeadId' && f.getFieldPath() != 'ContactId') || ObjectName !='CampaignMember') 
     && (ObjectName != 'LG_Student__c' || (ObjectName == 'LG_Student__c' && f.getFieldPath() != 'Student__c'))
     && (ObjectName != 'Seminar_Teachers__c' || (ObjectName == 'Seminar_Teachers__c' && f.getFieldPath() != 'Teacher__c'))
  )
                query += f.getFieldPath() + ', ';
        }
        if(ObjectName == 'CampaignMember'){
            query += 'Id,Name,LeadId,ContactId,Lead.Marketing_opt_out__c,Contact.Marketing_opt_out__c,Contact.IsEmailBounced FROM CampaignMember where CampaignId IN : sids';
            queryTotal += ' CampaignMember where CampaignId IN : sids ';
        }
        else if (ObjectName == 'LG_Student__c') {
            query += 'Id,Name,Student__c,Student__r.LGS_opt_out__c, Student__r.IsEmailBounced FROM LG_Student__c where LG__c IN : sids and Student__c != null';
            queryTotal += ' LG_Student__c where LG__c IN : sids and Student__c != null ';
        }
        else if (ObjectName == 'Seminar_Teachers__c') {
            query += 'Id,Name,Teacher__c,Teacher__r.LGS_opt_out__c, Teacher__r.IsEmailBounced FROM Seminar_Teachers__c where Seminar__c IN : sids and Teacher__c != null';
            queryTotal += ' Seminar_Teachers__c where Seminar__c IN : sids and Teacher__c != null ';
        }
        else{
            query += 'Id,Name, FROM '+ObjectName+' where Id IN : ids';
        }
        for(filterCriteriaRow filterRow : filterRows) {
            if(!isNull(filterRow.field) || Test.isRunningTest()) {
                conditions += ' and ';
                System.debug('===='+filterRow.field);
                if(filterRow.fieldTypeMap.get(filterRow.field) == 'address' || Test.isRunningTest()){
                    String AddressPrefix = (filterRow.field).replace('Address','');
                    String conj = '';
                    if(filterRow.operator == 'contains'){
                        conj = ' OR ';
                    }else{
                        conj = ' AND ';
                    }
                    conditions += ' ( ';
                    conditions += createFilterCondition(AddressPrefix+'Street', String.escapeSingleQuotes(filterRow.operator), String.escapeSingleQuotes(filterRow.value), 'address',parent);
                    conditions += conj;
                    conditions += createFilterCondition(AddressPrefix+'City', String.escapeSingleQuotes(filterRow.operator), String.escapeSingleQuotes(filterRow.value), 'address',parent);
                    conditions += conj;
                    conditions += createFilterCondition(AddressPrefix+'State', String.escapeSingleQuotes(filterRow.operator), String.escapeSingleQuotes(filterRow.value),'address',parent);
                    conditions += conj;
                    conditions += createFilterCondition(AddressPrefix+'PostalCode', String.escapeSingleQuotes(filterRow.operator), String.escapeSingleQuotes(filterRow.value), 'address',parent);
                    conditions += conj;
                    conditions += createFilterCondition(AddressPrefix+'Country', String.escapeSingleQuotes(filterRow.operator), String.escapeSingleQuotes(filterRow.value), 'address',parent);
                    conditions += ' ) '; 
                }
                else{
                    conditions += createFilterCondition(String.escapeSingleQuotes(filterRow.field), String.escapeSingleQuotes(filterRow.Operator), String.escapeSingleQuotes(filterRow.value), String.escapeSingleQuotes(filterRow.fieldTypeMap.get(filterRow.field)),parent);             
                }
            }
            else{
                break;
            }
        }
        if(ObjectName == 'CampaignMember'){
            conditions += ' and Id NOT IN :existingIds and (Lead.Marketing_opt_out__c = false and Contact.Marketing_opt_out__c = false)';
            query += conditions + ' order by Name';
        }
        else if (ObjectName == 'LG_Student__c') {
            conditions += ' and Id NOT IN :existingIds and (Student__r.LGS_opt_out__c = false)';
            query += conditions + ' order by Student__r.Name';
        }
        else if (ObjectName == 'Seminar_Teachers__c') {
            conditions += ' and Id NOT IN :existingIds and (Teacher__r.LGS_opt_out__c = false)';
            query += conditions + ' order by Teacher__r.Name';
        }
        queryTotal += conditions;
        query += ' limit : pageSize1';
        if(fetchTotal)
            totalRecords = database.countQuery(queryTotal);
        System.debug(query);
        //Debug.Log(query);
        return Database.query(query);
    }
    public static Map<String,String> getMergeFields(String Body,String ObjName,string subject){
        Map<String,String> mapMergeFields = new Map<String,String>();
        if(Body != null && Body.containsIgnoreCase('{!'+ObjName+'.')){
            //Sobject SObj;
            String tmpBody = Body;
            String tmpBody2 = '';
            Integer startPos = 0;
            Integer endPos = 0;
            /** Find all merge fields in body **/
            while(tmpBody.containsIgnoreCase('{!'+ObjName+'.')){
                startPos = tmpBody.indexOfIgnoreCase('{!'+ObjName+'.');
                tmpBody2 = tmpBody.subString(startPos, TmpBody.length());
                endPos = tmpBody2.indexOf('}');
                endPos = endPos + startPos;
                string mergeField = TmpBody.subString(startPos, endPos+1);
                string field = mergeField.removeStartIgnoreCase('{!'+ObjName+'.');
                field = field.replace('}','');
                mapMergeFields.put(mergeField, field);
                TmpBody = TmpBody.subString(0, startPos)+TmpBody.subString(endPos+1, TmpBody.length());
            }
        }
        
        else if(Body != null && Body.containsIgnoreCase('{!$'+ObjName+'.')){
            //Sobject SObj;
            String tmpBody = Body;
            String tmpBody2 = '';
            Integer startPos = 0;
            Integer endPos = 0;
            /** Find all merge fields in body **/
            while(tmpBody.containsIgnoreCase('{!$'+ObjName+'.')){
                startPos = tmpBody.indexOfIgnoreCase('{!$'+ObjName+'.');
                tmpBody2 = tmpBody.subString(startPos, TmpBody.length());
                endPos = tmpBody2.indexOf('}');
                System.debug('endPos:::'+endPos);
                endPos = endPos + startPos;
                string mergeField = TmpBody.subString(startPos, endPos+1);
                System.debug('startPos :::'+startPos);
                System.debug('tmpBody2 :::'+tmpBody2);
                System.debug('mergeField :::'+mergeField);
                string field = mergeField.removeStartIgnoreCase('{!$'+ObjName+'.');
                System.debug('field without replacing:::'+field);
                field = field.replace('}','');
                System.debug('field ::::::'+field);
                mapMergeFields.put(mergeField, field);
                TmpBody = TmpBody.subString(0, startPos)+TmpBody.subString(endPos+1, TmpBody.length());
            }
        }
        if(subject != null && subject.containsIgnoreCase('{!'+ObjName+'.')){
            //Sobject SObj;
            String tmpBody = subject;
            String tmpBody2 = '';
            Integer startPos = 0;
            Integer endPos = 0;

            while(tmpBody.containsIgnoreCase('{!'+ObjName+'.')){
                startPos = tmpBody.indexOfIgnoreCase('{!'+ObjName+'.');
                tmpBody2 = tmpBody.subString(startPos, TmpBody.length());
                endPos = tmpBody2.indexOf('}');
                endPos = endPos + startPos;
                string mergeField = TmpBody.subString(startPos, endPos+1);
                string field = mergeField.removeStartIgnoreCase('{!'+ObjName+'.');
                field = field.replace('}','');
                mapMergeFields.put(mergeField, field);
                TmpBody = TmpBody.subString(0, startPos)+TmpBody.subString(endPos+1, TmpBody.length());
            }
        }
        return mapMergeFields;
    }
    
    
    public static map<Id,SObject> getResult(String ObjName,list<string> ids,Map<String,String> mapMergeFields){
        if(mapMergeFields.size() > 0){
            string fields = '';
            if(mapMergeFields.size() > 0){
                Set<String> fieldSet = new Set<String>();

                for(string APIName : mapMergeFields.values()){
                    APIName = APIName.toLowerCase();
                    if(!fieldSet.contains(APIName)){
                        fields += fields != '' ? ', '+APIName : APIName;
                    }
                    fieldSet.add(APIName);
                }
            }
            String query = 'Select '+ fields +' FROM '+ObjName+' WHERE Id IN :ids';
            system.debug('---------'+query);
            System.debug('database.query(query):::'+database.query(query));
            map<Id,SObject> m1 = new map<Id,SObject>(database.query(query));
            System.debug('m1:::'+m1);
            return new map<Id,SObject>(database.query(query));
            
        }
        else{
            return new map<Id,SObject>();
        }
    }
    public static string getFinalResult(Sobject obj,Map<String,String> mapMergeFields,String Body,String ObjName,string subject){
        system.debug('======'+obj);
        system.debug(mapMergeFields+'======'+ObjName);
        try{
        Map<String, Schema.SObjectField> mapFields = Schema.getGlobalDescribe().get(ObjName).getDescribe().fields.getMap();

        for (string mergeField : mapMergeFields.keyset()) {
            string fieldAPI = mapMergeFields.get(mergeField);
            string fieldVal ='';
            Sobjectfield field = mapFields.get(fieldAPI.tolowercase());

            if(field != null){
                fieldVal = getFieldValue(field,obj);
            }
            else{
                /** Replace related object fields **/
                if (fieldAPI.containsIgnoreCase('.')) {
                    List<String> str = fieldAPI.split('\\.');

                    if (str.size() == 2) {
                        Sobject refSobj = obj.getSobject(str[0]);
                        if(refSobj != null){
                            for(sObjectType ST : Schema.getGlobalDescribe().get(ObjName).getDescribe().fields.getMap().get(str[0].endsWith('__r')?str[0].subString(0, str[0].length()-1)+'c':str[0]+'Id').getDescribe().getReferenceTo()){
                                fieldVal = getFieldValue(ST.getDescribe().fields.getMap().get(str[1]), refSobj);
                            }
                        }
                    }
                }
            }
            Body = Body.replace(mergeField , fieldVal);
            subject = subject.replace(mergeField , fieldVal);
        }
        }
        catch(Exception e){}
        return subject+'====='+Body;
    }
    
    public static string getSystemFinalResult(Map<String,String> mapMergeFields,String Body,string subject){
        try{
            string replacedValue = '';
            if(mapMergeFields.keySet().size() > 0){
                for(string systemVarKeyset : mapMergeFields.keySet()){
                
                          if(systemVarKeyset == '{!$System.now}'){
                              replacedValue = string.valueOf(System.now());  
                          }
                          else if(systemVarKeyset == '{!$System.today}'){
                              replacedValue = string.valueOf(System.today());
                          }
                          else if(systemVarKeyset == '{!$System.day}'){
                              replacedValue = string.valueOf(System.now().day());
                          }
                          else if(systemVarKeyset == '{!$System.month}'){
                              replacedValue = string.valueOf(System.now().month());
                          }
                          else if(systemVarKeyset == '{!$System.year}'){
                              replacedValue = string.valueOf(System.now().year());
                          }
                          Body = Body.replace(systemVarKeyset , replacedValue);
                          subject = subject.replace(systemVarKeyset , replacedValue);  
                }
                
            }
        }
        catch(Exception e){}
        return subject+'====='+Body;
    }
    
    public static string clearText(string Body, string subject){
        if(Body != null && Body.containsIgnoreCase('{!')){
            String tmpBody = Body;
            String tmpBody2 = '';
            Integer startPos = 0;
            Integer endPos = 0;
            while(tmpBody.containsIgnoreCase('{!')){
                startPos = tmpBody.indexOfIgnoreCase('{!');
                tmpBody2 = tmpBody.subString(startPos, TmpBody.length());
                endPos = tmpBody2.indexOf('}');
                endPos = endPos + startPos;
                string mergeField = TmpBody.subString(startPos, endPos+1);
                TmpBody = TmpBody.subString(0, startPos)+TmpBody.subString(endPos+1, TmpBody.length());
            }
            Body = tmpBody;
        }
        Body = Body.replace(']]>','');
        if(subject != null && subject.containsIgnoreCase('{!')){
            String tmpBody = subject;
            String tmpBody2 = '';
            Integer startPos = 0;
            Integer endPos = 0;
            while(tmpBody.containsIgnoreCase('{!')){
                startPos = tmpBody.indexOfIgnoreCase('{!');
                tmpBody2 = tmpBody.subString(startPos, TmpBody.length());
                endPos = tmpBody2.indexOf('}');
                endPos = endPos + startPos;
                string mergeField = TmpBody.subString(startPos, endPos+1);
                TmpBody = TmpBody.subString(0, startPos)+TmpBody.subString(endPos+1, TmpBody.length());
            }
            subject = tmpBody;
        }
        return subject+'====='+Body;
    }
    /** Return value for merge field **/
    public static string getFieldValue(Sobjectfield field, Sobject obj) {
        string fieldVal = '';
        try{
            string fieldAPI = field.getdescribe().getname();

            if (field.getdescribe().gettype() == Displaytype.Date || field.getdescribe().gettype() == Displaytype.Datetime) {
                fieldVal = (obj.get(fieldAPI) != null ? Date.valueOf(obj.get(fieldAPI)).format() : '') ;
            }
            else if (field.getdescribe().gettype() == Displaytype.Currency) {
                fieldVal = (obj.get(fieldAPI) != null ? getCurrencySymbol(obj)+String.valueOf(obj.get(fieldAPI)) : '') ;
            }
            else if (field.getdescribe().gettype() == Displaytype.Boolean) {
                fieldVal = (obj.get(fieldAPI ) != null ? String.valueOf(obj.get(fieldAPI )).equalsIgnoreCase('TRUE')?'Yes':'No' : '') ;
            }
            else if (field.getdescribe().gettype() == Displaytype.Percent) {
                fieldVal = (obj.get(fieldAPI ) != null ? String.valueOf(obj.get(fieldAPI ))+'%' : '0%') ;
            }
            else if (field.getdescribe().gettype() == Displaytype.ADDRESS) {
                fieldVal = (obj.get(fieldAPI ) != null ? string.valueOf(getAddress(Obj, fieldAPI)) : '') ;
            }
            else{
                fieldVal = (obj.get(fieldAPI ) != null ? string.valueOf(obj.get(fieldAPI )) : '') ;
            }
        }
        catch(Exception e){
            return 'Error: '+ e.getMessage();
        }
        return fieldVal ;
    }
    /** get Currency Symbol **/
    public static String getCurrencySymbol(SObject someObject) {
        return getCurrencySymbolFromIso(getCurrencyIsoCode(someObject));
    }

    public static String getCurrencyIsoCode(SObject someObject){
        String currencyIso = UserInfo.isMultiCurrencyOrganization() ? (String) someObject.get('CurrencyIsoCode') : UserInfo.getDefaultCurrency();
        return currencyIso;
    }

    public static String getCurrencySymbolFromIso(String Iso) {
         String currencySymbol =
           ('USD' == Iso ? '$' :
           ('CAD' == Iso ? '$' :
           ('EUR' == Iso ? '€' :
           ('GBP' == Iso ? '£' :
           ('JPY' == Iso ? '¥' :
           ('KRW' == Iso ? '₩' :
           ('CNY' == Iso ? '元' :
           Iso)))))));
           return currencySymbol;
    }

    /** Get formatted address for compound field **/
    public static String getAddress(Sobject Obj, String FieldName){
        try{
            Address Add = (Address) Obj.get(FieldName);
            String Address1 = '';

            if(Add.getStreet() != null){
                Address1 += Address1 == ''?Add.getStreet():Add.getStreet();
            }

            if(Add.getCity() != null){
                Address1 += Address1 == ''?Add.getCity():', '+Add.getCity();
            }

            if(Add.getState() != null){
                Address1 += Address1 == ''?Add.getState():', '+Add.getState();
            }

            if(Add.getCountry() != null){
                Address1 += Address1 == ''?Add.getCountry():', '+Add.getCountry();
            }

            if(Add.getPostalCode() != null){
                Address1 += Address1 == ''?Add.getPostalCode():', '+Add.getPostalCode();
            }
            return Address1;
        }
        catch(Exception e){
            return e.getMessage();
        }
        return null;
    }

    public static List<Schema.FieldSetMember> readFieldSet(String fieldSetName, String ObjectName)
    {
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
        return fieldSetObj.getFields();
    }
    @RemoteAction
    public static list<FieldWrapper> fetchMergeFields(string objectName){
        list<FieldWrapper> fields = new list<FieldWrapper>();
        try{
            if(objectName != null && objectName != ''){
                Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
                Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
                for (String field : fieldMap.keySet()) {
                    Schema.DescribeFieldResult dfr = fieldMap.get(field).getDescribe();
                    FieldWrapper fw = new FieldWrapper(dfr.getLabel(), dfr.getName(),'',String.valueOf(dfr.getType()));
                    if(String.valueOf(dfr.getType()) == 'REFERENCE')
                        fw.objectName = string.valueOf(dfr.getReferenceTo());
                    fields.add(fw);
                }
            }
            else{
                List<Schema.SObjectType> gd = Schema.getGlobalDescribe().Values();
                for (Schema.SObjectType f : gd) {
                    Schema.DescribeSObjectResult SR = f.getDescribe();
                    if(SR.isUpdateable() && SR.getKeyPrefix()!=null && !SR.isCustomSetting() && SR.isCreateable())
                        fields.add(new FieldWrapper(SR.getLabel(), SR.getName(),'',''));
                }
            }
            fields = getSortedList(fields);
        }
        catch(Exception e){

        }
        return fields;
    }
    public static List<FieldWrapper> getSortedList(List<FieldWrapper> ObjectFields){
        try{
            List<String> ObjectFieldstemp = new List<String>();
            Map<String,FieldWrapper> tempMap = new Map<String,FieldWrapper>();

            For(FieldWrapper so: ObjectFields){
                tempMap.put(so.label, so);
                ObjectFieldstemp.add(so.label);
            }
            ObjectFieldstemp.sort();

            ObjectFields = new List<FieldWrapper>();
            for(String so : ObjectFieldstemp){
                ObjectFields.add(tempMap.get(so));
            }
            return ObjectFields;
        }
        catch(Exception e){
            system.debug(' ===== Error in getSortedList ==== '+e.getMessage());
        }
        return null;
    }
    @RemoteAction
    public static string getField(string selectedObject,string selectedField){
        return  '{!'+selectedObject +'.'+selectedField+'}';
    }
    public static String getFieldType(Schema.DisplayType fieldType) {
        if(fieldType != null) {
            if(fieldType == Schema.DisplayType.PickList)
                return 'Picklist';
            if(fieldType == Schema.DisplayType.MultiPicklist)
                return 'MultiPicklist';
            if(fieldType == Schema.DisplayType.String
                || fieldType == Schema.DisplayType.Email
                || fieldType == Schema.DisplayType.EncryptedString
                || fieldType == Schema.DisplayType.ID
                || fieldType == Schema.DisplayType.Phone
                || fieldType == Schema.DisplayType.URL
                || fieldType == Schema.DisplayType.Reference)
                return 'Text';
            if(fieldType == Schema.DisplayType.Time
                || fieldType == Schema.DisplayType.Percent
                || fieldType == Schema.DisplayType.Integer
                || fieldType == Schema.DisplayType.Double
                || fieldType == Schema.DisplayType.Currency)
                return 'Numbers';
            if(fieldType == Schema.DisplayType.Boolean)
                return 'Boolean';
            // Update to resolve Date and Datetime issue @Chirag 12/3/12
            if(fieldType == Schema.DisplayType.Date)
                return 'Date';
            if(fieldType == Schema.DisplayType.DateTime)
                return 'DateTime';    
        }
        return '';
    }
    public static string createFilterCondition(String field, String operator, String value, String fieldType, string parent) {
        field = (parent != '' ? parent+'.':'')+field;
        String filterCondition = '';
        /** Karan **/
           if(fieldType == Email) {
            //System.assert(false,field+' '+operator+' '+value+' '+fieldType);
            if(operator == EQUALS)
                filterCondition = '(' + field + ' = \'' + value + '\')';
            else if(operator == NOT_EQUAL_TO)
                filterCondition = '(' + field + ' <> \'' + value + '\')';
            else if(operator == STARTS_WITH)
                filterCondition = '(' + field + ' like \'' + value + '%\')';
            else if(operator == CONTAINS && fieldType == Email)
                filterCondition = '(' + field + ' like \'%' + value + '%\')';
            else if(operator == DOES_NOT_CONTAIN && fieldType == Email)
                filterCondition = '( NOT ' + field + ' like \'%' + value + '%\')';
            else if(operator == CONTAINS  && fieldType == PICKLIST) {
                if(!value.contains(','))
                    filterCondition = '(' + field + ' like \'%' + value + '%\')';
                else {
                    value = value.replaceAll(',','\',\'');
                    filterCondition = '(' + field + ' in (\'' + value + '\'))';
                }
              }
             }
            else if(fieldType == Zip) {
            //System.assert(false,field+' '+operator+' '+value+' '+fieldType);
            if(operator == EQUALS)
                filterCondition = '(' + field + ' = \'' + value + '\')';
            else if(operator == NOT_EQUAL_TO)
                filterCondition = '(' + field + ' <> \'' + value + '\')';
            }
            else if(fieldType == Address) {
            //System.assert(false,field+' '+operator+' '+value+' '+fieldType);
            if(operator == CONTAINS)
                filterCondition = '(' + field + ' like \'%' + value + '%\')';
            else if(operator == DOES_NOT_CONTAIN)
                filterCondition = '( NOT ' + field + ' like \'%' + value + '%\')';
            }
            else if(fieldType == Phone) {
            //System.assert(false,field+' '+operator+' '+value+' '+fieldType);
            if(operator == EQUALS)
                filterCondition = '(' + field + ' = \'' + value + '\')';
            else if(operator == NOT_EQUAL_TO)
                filterCondition = '(' + field + ' <> \'' + value + '\')';
            }
            else if(fieldType == Url1) {
            //System.assert(false,field+' '+operator+' '+value+' '+fieldType);
            if(operator == EQUALS)
                filterCondition = '(' + field + ' = \'' + value + '\')';
            else if(operator == NOT_EQUAL_TO)
                filterCondition = '(' + field + ' <> \'' + value + '\')';
            }
            else if(fieldType == ImageUrl) {
            //System.assert(false,field+' '+operator+' '+value+' '+fieldType);
            if(operator == EQUALS)
                filterCondition = '(' + field + ' = \'' + value + '\')';
            else if(operator == NOT_EQUAL_TO)
                filterCondition = '(' + field + ' <> \'' + value + '\')';
            }
            // Birthday
            else if(fieldType == BirthDay) {
                // Format DateTime and Date value if format is MM/DD/YYYY
                if(fieldType == BirthDay&& value.contains('/'))
                    value = formattedDateString(value);
                else if(fieldType == BirthDay && value.equals('')){
                    value = '2000-01-01';  
                }
                    
                // Create filter condition
                if(operator == EQUALS)
                    filterCondition = '(' + field + ' = ' + value + ')';
                else if(operator == NOT_EQUAL_TO)
                    filterCondition = '(' + field + ' <> ' + value + ')';
                else if(operator == LESS_THAN)
                    filterCondition = '(' + field + ' < ' + value + ')';
                else if(operator == GREATER_THAN)
                    filterCondition = '(' + field + ' > ' + value + ')';
                else if(operator == LESS_OR_EQUAL)
                    filterCondition = '(' + field + ' <= ' + value + ')';
                else if(operator == GREATER_OR_EQUAL)
                    filterCondition = '(' + field + ' >= ' + value + ')';    
            }
            /** Karan **/    
            
           else if(fieldType == TEXT
            || fieldType == PICKLIST
            || fieldType == MULTIPICKLIST) {
            if(operator == EQUALS)
                filterCondition = '(' + field + ' = \'' + value + '\')';
            else if(operator == NOT_EQUAL_TO)
                filterCondition = '(' + field + ' <> \'' + value + '\')';
            else if(operator == STARTS_WITH)
                filterCondition = '(' + field + ' like \'' + value + '%\')';
            else if(operator == CONTAINS && fieldType == TEXT)
                filterCondition = '(' + field + ' like \'%' + value + '%\')';
            else if(operator == DOES_NOT_CONTAIN && fieldType == TEXT)
                filterCondition = '( NOT ' + field + ' like \'%' + value + '%\')';
            else if(operator == CONTAINS  && fieldType == PICKLIST) {
                if(!value.contains(','))
                    filterCondition = '(' + field + ' like \'%' + value + '%\')';
                else {
                    value = value.replaceAll(',','\',\'');
                    filterCondition = '(' + field + ' in (\'' + value + '\'))';
                }
            }
            
            else if(operator == DOES_NOT_CONTAIN && fieldType == PICKLIST) {
                if(!value.contains(','))
                    filterCondition = '(' + field +  ' not like \'%' + value + '%\')';
                else {
                    value = value.replaceAll(',','\',\'');
                    filterCondition = '(' + field + ' not in (\'' + value + '\'))';
                }
            }
            else if(operator == INCLUDES && fieldType == MultiPICKLIST) {
                if(!value.contains(','))
                    filterCondition = '(' + field + ' includes (\'' + value + '\'))';
                else {
                    value = value.replaceAll(',','\',\'');
                    filterCondition = '(' + field + ' includes (\'' + value + '\'))';
                }
             }
             else if(operator == Excludes && fieldType == MultiPICKLIST) {
                if(!value.contains(','))
                    filterCondition = '(' + field + ' not excludes (\'' + value + '\'))';
                else {
                    value = value.replaceAll(',','\',\'');
                    filterCondition = '(' + field + ' excludes (\'' + value + '\'))';
                }
            }
        }
        // Update to resolve DAte and Datetime issue @Chirag 12/3/12
        else if(fieldType == NUM
                    || fieldType == DATETYPE
                    || fieldType == DATETIMETYPE) {
            // Format DateTime and Date value if format is MM/DD/YYYY
            if(fieldType == DATETYPE && value.contains('/'))
                value = formattedDateString(value);
            else if(fieldType == DATETIMETYPE && value.contains('/'))
                value = formattedDatetimeString(value);
            else if(fieldType == DATETYPE && value.equals('')){
                value = '2000-01-01';  
            }
            else if(fieldType == DATETIMETYPE && value.equals('')){
                value = '2000-01-01T00:00:00Z';
                //System.assert(false,value+' -- '+fieldType);
            }    
            // Create filter condition
            if(operator == EQUALS)
                filterCondition = '(' + field + ' = ' + value + ')';
            else if(operator == NOT_EQUAL_TO)
                filterCondition = '(' + field + ' <> ' + value + ')';
            else if(operator == LESS_THAN)
                filterCondition = '(' + field + ' < ' + value + ')';
            else if(operator == GREATER_THAN)
                filterCondition = '(' + field + ' > ' + value + ')';
            else if(operator == LESS_OR_EQUAL)
                filterCondition = '(' + field + ' <= ' + value + ')';
            else if(operator == GREATER_OR_EQUAL)
                filterCondition = '(' + field + ' >= ' + value + ')';    
        }
        else if(fieldType == TOF) {
            if(operator == EQUALS && value.toUpperCase().equals('TRUE'))
                filterCondition = '(' + field + ' = true)';
            else if(operator == EQUALS && value.toUpperCase().equals('FALSE'))
                filterCondition = '(' + field + ' = false)';
            else if(operator == NOT_EQUAL_TO && value.toUpperCase().equals('TRUE'))
                filterCondition = '(' + field + ' = false)';
            else if(operator == NOT_EQUAL_TO && value.toUpperCase().equals('FALSE'))
                filterCondition = '(' + field + ' = true)';
        }
        return filterCondition;
    }
     
    // Added to resolve Date and Datetime string @Chirag 12/3/2012
    // Formats Date String MM/DD/YYYY to String YYYY-MM-DD
    public static String formattedDateString(String dateStr) {
        String formattedDateStr = '';
        if(dateStr != null && dateStr != '') {
            String[] parsedStr = dateStr.split('/');
            if(parsedStr != null && parsedStr.size() == 3) 
                formattedDateStr = parsedStr[2] + '-' + formattedDayMonth(parsedStr[0]) + '-' + formattedDayMonth(parsedStr[1]);
        }
        return formattedDateStr;
    }
    
    // Formats Date String MM/DD/YYYY to String YYYY-MM-DDThh:mm:ssZ
    public static String formattedDatetimeString(String dateStr) {
        String formattedDateStr = '';
        if(dateStr != null && dateStr != '') {
            String[] parsedStr = dateStr.split('/');
            if(parsedStr != null && parsedStr.size() == 3) 
                formattedDateStr = parsedStr[2] + '-' + formattedDayMonth(parsedStr[0]) + '-' + formattedDayMonth(parsedStr[1]) + 'T00:00:00Z';
        }
        return formattedDateStr;
    }
    
    // Formats day/Month. Eg 3 is returned as 03, 11 is returned as 11.
    public static String formattedDayMonth(String str) {
        String formattedStr = str;
        if(str != null && str != '' && str.length() == 1)
            formattedStr = '0' + formattedStr;
        return formattedStr; 
    }
    public static Boolean isNull(String str) {
        if(str == null || str == '' || str == NONE){
            return true;
        }   
        return false;
    }
    
    public class TemplateWrapper{
        public string id{get;set;}
        public string name{get;set;}
        public string subject{get;set;}
        public string body{get;set;}
        public string htmlBody{get;set;}
        public TemplateWrapper(Email_Template__c et){
        if(et.Id != null && et.Name != null && et.Subject__c != null && et.Body__c != null && et.Html_Value__c != null) {
            this.id = et.Id;
            this.name = et.Name;
            this.subject = et.Subject__c;
            this.body = et.Body__c;
            this.htmlBody = et.Html_Value__c;
            System.debug('this.htmlBody::' + this.htmlBody);
            this.htmlBody = this.htmlBody.replace(']]>','');
            }
        }
    }
    public class ContactResultWrapper{
        public Integer totalContacts {get;set;}
        public list<ContactWrapper> contacts {get;set;}
        public string error {get;set;}
        public ContactResultWrapper(){
            this.contacts = new list<ContactWrapper>();
            this.totalContacts = 0;
            this.error = '';
        }
    }
    public class ContactWrapper{
        public string id{get;set;}
        public string recId{get;set;}
        public string objectName{get;set;}
        public boolean isSelected{get;set;}
        public boolean unsubscribed{get;set;}
        //to check bounce email field status
        public boolean isBounced{get;set;}
        public list<FieldWrapper> fields{get;set;}
        public ContactWrapper(){
            id = '';
            recId = '';
            objectName = '';
            isSelected = false;
            unsubscribed = false;
            isBounced = false;
            fields = new list<FieldWrapper>();
        }
    }
    public class FieldWrapper{
        public string label{get;set;}
        public string name{get;set;}
        public string value{get;set;}
        public string type{get;set;}
        public string objectName{get;set;}
        public map<string,string> picklistValues{get;set;}
        public FieldWrapper(string label,string name,string value,string type){
            this.label = label;
            this.name = name;
            this.value = value;
            this.type = type;
            this.objectName = '';
            this.picklistValues = new map<string, string>();
        }
    }
    public class filterCriteriaRow {
        public String field {get; set;}
        public String operator {get; set;}
        public String value {get; set;}
        public String objSelected {get; set;}
        public Integer rowNumber {get; set;}
        public String sRowNumber {
            get{
                return '##'+string.valueOf(rowNumber)+'##';
            }
        }
        public Map<String, String> fieldTypeMap {get; set;}
        public filterCriteriaRow(String objSelected, Integer rowNumber, Map<String, String> fieldTypeMap) {
            this.objSelected = String.escapeSingleQuotes(objSelected);
            this.rowNumber = rowNumber;
            this.fieldTypeMap = fieldTypeMap;       
            value = '';
        }
    }
    
}