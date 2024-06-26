@isTest(seeAllData = false)
public with sharing class MassEmailControllerTest{
    static testmethod void unitTest01() {
        
        MassEmailConfiguration__c mec = new MassEmailConfiguration__c(Folders__c = 'test', Site_Url__c = 'https://dev1-hdcmassemails.cs86.force.com/');
        insert mec;
        User user = new User();
        list<User> users = [select Id,Mass_Email_Limit_in_Counter_period__c, Counter_period__c,Last_Reset_Time__c,
                            Mass_Email_Limit__c, Counter__c from User where Id = :UserInfo.getUserId() limit 1];
        if(users.size() > 0)
            user = users[0];

        user.Mass_Email_Limit_in_Counter_period__c = 20;
        user.Counter__c = 1;
        user.Counter_period__c = 10;
        user.Mass_Email_Limit__c = 20;
        update user;
        Campaign c = new Campaign(Name='Test');
        insert c;
        Account acc = new Account(Name = 'test account', Account_Status__c = 'Active', BillingCountry = 'France');
        insert acc;
        Contact testContact = new Contact(AccountId = acc.Id, FirstName = 'TestContactF', LastName = 'TestContactL', Email = 'none@navinet.net');
        insert testContact;
        Lead testLead = new Lead(FirstName = 'TestContactF', LastName = 'TestContactL', Email = 'none@navinet.net',Company = 'test company');
        insert testLead;
        CampaignMember newMember = new CampaignMember(CampaignId = c.Id, ContactId = testContact.Id);
        insert newMember;
        CampaignMember newMember1 = new CampaignMember(CampaignId = c.Id, LeadId = testLead.Id);
        insert newMember1;
        map<string,string> subMap = new map<string,string>();
        subMap.put(testContact.Id,newMember.Id);
        subMap.put(testLead.Id,newMember1.Id);
        ApexPages.currentPage().getParameters().put('mode', 'campaign');
        MassEmailController mecObj = new MassEmailController();
        String userName = mecObj.UserName;
        Integer i = mecObj.pageSize;
        map<string,string> folders = MassEmailController.emailFolders();
        list<MassEmailController.TemplateWrapper> emailTemplates = MassEmailController.emailTemplates('');
        MassEmailController.ContactResultWrapper contactWP = MassEmailController.contacts(c.Id,'Campaign',JSON.serialize(new list<string>()),true);
        list<MassEmailController.FieldWrapper> filterFields = MassEmailController.getFilterFields('Campaign');
        contactWP = MassEmailController.search(c.Id,'Campaign',JSON.serialize(filterFields),JSON.serialize(new list<string>()),true);
        string subject = '{!Contact.Name} {!Lead.Name}';
        string body = 'hello {!Contact.Name}  {!Campaign.Name} {!CampaignMember.Name} {!Lead.Name} {!Account.Name}';
        string result = MassEmailController.sendEmail(body,JSON.serialize(subMap),subject,c.Id,'Campaign','test');
        result = MassEmailController.preview(body,testContact.Id,newMember.Id,subject,'Campaign',c.Id);
        result = MassEmailController.preview(body,testLead.Id,newMember1.Id,subject,'Campaign',c.Id);
        testContact.Marketing_opt_out__c = true;
        update testContact;
        list<MassEmailController.ContactWrapper> contacts = MassEmailController.uncontacts(c.Id,'Campaign');
    }
    static testmethod void unitTest02() {
        MassEmailConfiguration__c mec = new MassEmailConfiguration__c(Folders__c = 'test', Site_Url__c = 'https://dev1-hdcmassemails.cs86.force.com/');
        insert mec;
        User user = new User();
        list<User> users = [select Id,Mass_Email_Limit_in_Counter_period__c, Counter_period__c,Last_Reset_Time__c,
                            Mass_Email_Limit__c, Counter__c from User where Id = :UserInfo.getUserId() limit 1];
        if(users.size() > 0)
            user = users[0];

        user.Mass_Email_Limit_in_Counter_period__c = 20;
        user.Counter__c = 1;
        user.Counter_period__c = 10;
        user.Mass_Email_Limit__c = 20;
        update user;
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

        LG__c lg = new LG__c(Id = testEnv.lgId);
        lg.Group_Status__c = 'Planned';
        lg.LG_Start_Date__c = System.today();
        lg.LG_End_Date__c = System.today().addDays(30);
        update lg;
        LG_Student__c student = new LG_Student__c(Id = testEnv.studentId);
        student.Status_in_LG__c = 'Registered';
        student.Student_Course_Start_Date__c = system.today().addDays(-1);
        update student;
        ApexPages.currentPage().getParameters().put('mode', 'lg');
        MassEmailController mecObj = new MassEmailController();
        list<MassEmailController.FieldWrapper> objects = MassEmailController.fetchMergeFields('');
        list<MassEmailController.FieldWrapper> fields = MassEmailController.fetchMergeFields('Contact');
        string mergefield = MassEmailController.getField('Contact','Email');
        MassEmailController.ContactResultWrapper contactWP  = MassEmailController.contacts(lg.Id,'Lg',JSON.serialize(new list<string>()),false);
        map<string,string> subMap = new map<string,string>();
        string conId = '';
        string recId = '';
        for(MassEmailController.ContactWrapper cw : contactWP.contacts){
            subMap.put(cw.Id,cw.recId);
            conId = cw.Id;
            recId = cw.recId;
        }
        test.startTest();
        list<MassEmailController.FieldWrapper> filterFields = MassEmailController.getFilterFields('Lg');
        contactWP = MassEmailController.search(lg.Id,'Lg',JSON.serialize(filterFields),JSON.serialize(new list<string>()),false);
        string subject = '{!Contact.Name}';
        string body = 'hello {!Lg__c.Name}  {!LG_Student__c.Name} {!Contact.Name} {!Account.Name}';
        string result = MassEmailController.sendEmail(body,JSON.serialize(subMap),subject,lg.Id,'Lg','test');
        result = MassEmailController.preview(body,conId,recId,subject,'Lg',lg.Id);
        list<MassEmailController.ContactWrapper> contacts = MassEmailController.uncontacts(lg.Id,'Lg');
        test.stopTest();
    }
    static testmethod void unitTest03() {
        MassEmailConfiguration__c mec = new MassEmailConfiguration__c(Folders__c = 'test', Site_Url__c = 'https://dev1-hdcmassemails.cs86.force.com/');
        insert mec;
        Account acc = new Account(Name = 'test account', Account_Status__c = 'Active', BillingCountry = 'France');
        insert acc;
        Contact testContact = new Contact(AccountId = acc.Id, FirstName = 'TestContactF', LastName = 'TestContactL', Email = 'none@navinet.net');
        insert testContact;
        map<string,string> subMap = new map<string,string>();
        subMap.put(testContact.Id,testContact.Id);
        ApexPages.currentPage().getParameters().put('mode', 'campaign');
        MassEmailController mecObj = new MassEmailController();
        list<MassEmailController.FieldWrapper> filterFields = MassEmailController.getFilterFields('Contact');
        string subject = '{!Contact.Name}';
        string body = 'hello {!Lg__c.Name}  {!LG_Student__c.Name} {!Contact.Name} {!Account.Name}';
        string result = MassEmailController.sendEmail(body,JSON.serialize(subMap),subject,testContact.Id,'Contact','test');
        result = MassEmailController.preview(body,testContact.Id,testContact.Id,subject,'Contact',testContact.Id);
        list<MassEmailController.FieldWrapper> fields = MassEmailController.fetchMergeFields('Contact');
        for(MassEmailController.FieldWrapper fw : fields){
            if(fw.type == 'Date')
                MassEmailController.createFilterCondition(fw.name,'not equal to','2016/5/5',fw.type,'');
            else if(fw.type == 'DateTime')
                MassEmailController.createFilterCondition(fw.name,'not equal to','2016/5/5',fw.type,'');
            else
                MassEmailController.createFilterCondition(fw.name,'not equal to','',fw.type,'');
        }
    }
    static testmethod void unitTest04() {
        MassEmailConfiguration__c mec = new MassEmailConfiguration__c(Folders__c = 'test', Site_Url__c = 'https://dev1-hdcmassemails.cs86.force.com/');
        insert mec;
        Account acc = new Account(Name = 'test account', Account_Status__c = 'Active', BillingCountry = 'France');
        insert acc;
        Contact testContact = new Contact(AccountId = acc.Id, FirstName = 'TestContactF', LastName = 'TestContactL', Email = 'none@navinet.net');
        insert testContact;
        map<string,string> subMap = new map<string,string>();
        subMap.put(testContact.Id,testContact.Id);
        ApexPages.currentPage().getParameters().put('mode', 'Seminar');
        MassEmailController mecObj = new MassEmailController();
        list<MassEmailController.FieldWrapper> filterFields = MassEmailController.getFilterFields('Contact');
        string subject = '{!Contact.Name}';
        string body = 'hello {!Seminar__c.Name}  {!Seminar_Teachers__c.Name} {!Contact.Name} {!Account.Name}';
        string result = MassEmailController.sendEmail(body,JSON.serialize(subMap),subject,testContact.Id,'Contact','test');
        result = MassEmailController.preview(body,testContact.Id,testContact.Id,subject,'Contact',testContact.Id);
        list<MassEmailController.FieldWrapper> fields = MassEmailController.fetchMergeFields('Contact');
        for(MassEmailController.FieldWrapper fw : fields){
            if(fw.type == 'Date')
                MassEmailController.createFilterCondition(fw.name,'not equal to','2016/5/5',fw.type,'');
            else if(fw.type == 'DateTime')
                MassEmailController.createFilterCondition(fw.name,'not equal to','2016/5/5',fw.type,'');
            else
                MassEmailController.createFilterCondition(fw.name,'not equal to','',fw.type,'');
        }
    }
    static testmethod void unitTest05() {
        MassEmailConfiguration__c mec = new MassEmailConfiguration__c(Folders__c = 'test', Site_Url__c = 'https://dev1-hdcmassemails.cs86.force.com/');
        insert mec;
        User user = new User();
        list<User> users = [select Id,Mass_Email_Limit_in_Counter_period__c, Counter_period__c,Last_Reset_Time__c,
                            Mass_Email_Limit__c, Counter__c from User where Id = :UserInfo.getUserId() limit 1];
        if(users.size() > 0)
            user = users[0];

        user.Mass_Email_Limit_in_Counter_period__c = 20;
        user.Counter__c = 1;
        user.Counter_period__c = 10;
        user.Mass_Email_Limit__c = 20;
        update user;
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        
    
        Seminar_Type__c seminarType = ObjectCreator.getNewSeminarType();
        insert seminarType;
    
        Seminar__c seminar = ObjectCreator.getNewSeminar();
        seminar.Seminar_Type__c = seminarType.Id;
        seminar.Hosting_Franchisee__c = testEnv.accId;
        insert seminar;

        Seminar_Teachers__c st = ObjectCreator.getNewSeminarTeacher(seminar.Id, testEnv.teacherContactId);
        st.Teacher__c = testEnv.teacherContactId;
        insert st;  
        
        //semTeacher.Seminar_Start_Date__c = system.today().addDays(-1);
        //insert semTeacher;
        ApexPages.currentPage().getParameters().put('mode', 'Seminar');
        MassEmailController mecObj = new MassEmailController();
        list<MassEmailController.FieldWrapper> objects = MassEmailController.fetchMergeFields('');
        list<MassEmailController.FieldWrapper> fields = MassEmailController.fetchMergeFields('Contact');
        string mergefield = MassEmailController.getField('Contact','Email');
        MassEmailController.ContactResultWrapper contactWP  = MassEmailController.contacts(seminar.Id,'Seminar',JSON.serialize(new list<string>()),false);
        map<string,string> subMap = new map<string,string>();
        string conId = '';
        string recId = '';
        for(MassEmailController.ContactWrapper cw : contactWP.contacts){
            subMap.put(cw.Id,cw.recId);
            conId = cw.Id;
            recId = cw.recId;
        }
        try{
	        try{
	        	list<MassEmailController.FieldWrapper> filterFields = MassEmailController.getFilterFields('Seminar');
	        	contactWP = MassEmailController.search(seminar.Id,'Seminar',JSON.serialize(filterFields),JSON.serialize(new list<string>()),false);
	        }catch(exception ex){}
	        string subject = '{!Contact.Name}';
	        string body = 'hello {!Seminar__c.Name}  {!Seminar_Teachers__c.Name} {!Contact.Name} {!Account.Name}';
	        string result = MassEmailController.sendEmail(body,JSON.serialize(subMap),subject,seminar.Id,'Seminar','test');
	        result = MassEmailController.preview(body,conId,recId,subject,'Seminar',seminar.Id);
	        list<MassEmailController.ContactWrapper> contacts = MassEmailController.uncontacts(seminar.Id,'Seminar');
	    }catch(exception ex){}
    }
}