@isTest(seeAllData = false)
public with sharing class MassEmailControllerNewTest{
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
        Account acc = new Account(Name = 'test account', BillingCountry = 'France');
        insert acc;
        Contact testContact = new Contact(AccountId = acc.Id, FirstName = 'TestContactF', LastName = 'TestContactL', Email = 'none@navinet.net');
        insert testContact;
        Lead testLead = new Lead(FirstName = 'TestContactF', LastName = 'TestContactL', Email = 'none@navinet.net',Company = 'test company');
        insert testLead;
        CampaignMember newMember = new CampaignMember(CampaignId = c.Id, ContactId = testContact.Id);
        insert newMember;
        CampaignMember newMember1 = new CampaignMember(CampaignId = c.Id, LeadId = testLead.Id);
        insert newMember1;
        List<Email_Template__c> lstEmailTemp = new List<Email_Template__c>();
        for(Integer i = 0;i<5;i++){
        Email_Template__c emtemp = new Email_Template__c();
        emtemp.Name = 'Test Temp'+i;
        emtemp.Subject__c = 'Testing Purpose';
        emtemp.Body__c = 'hello {!$System.Today}';
        emtemp.Html_Value__c = 'hello {!$System.Today}';
        emtemp.Is_Active__c = true;
        emtemp.Related_To_Base_Object__c = 'Campaign';
        lstEmailTemp.add(emtemp);
        }
        insert lstEmailTemp; 
        map<string,string> subMap = new map<string,string>();
        subMap.put(testContact.Id,newMember.Id);
        subMap.put(testLead.Id,newMember1.Id);
        ApexPages.currentPage().getParameters().put('mode', 'campaign');
        MassEmailControllerNew mecObj = new MassEmailControllerNew();
        String userName = mecObj.UserName;
        Integer i = mecObj.pageSize;
        map<string,string> folders = MassEmailControllerNew.emailFolders();
        list<MassEmailControllerNew.TemplateWrapper> emailTemplates = MassEmailControllerNew.emailTemplates('Campaign');
        MassEmailControllerNew.ContactResultWrapper contactWP = MassEmailControllerNew.contacts(c.Id,'Campaign',JSON.serialize(new list<string>()),true);
        list<MassEmailControllerNew.FieldWrapper> filterFields = MassEmailControllerNew.getFilterFields('Campaign');
        contactWP = MassEmailControllerNew.search(c.Id,'Campaign',JSON.serialize(filterFields),JSON.serialize(new list<string>()),true);
        string subject = '{!Contact.Name} {!Lead.Name}';
        string body = 'hello {!Contact.Name}  {!Campaign.LastModifiedBy.Street} {!Campaign.Name} {!CampaignMember.Name} {!Lead.Name} {!Account.Name} {!$Organization.Address} {!$System.Now}  {!$User.Email} {!$System.Today} {!$System.Day} {!$System.Month} {!$System.Year}';
        string result = MassEmailControllerNew.sendEmail(body,JSON.serialize(subMap),subject,c.Id,'Campaign','test');
        result = MassEmailControllerNew.preview(body,testContact.Id,newMember.Id,subject,'Campaign',c.Id);
        result = MassEmailControllerNew.preview(body,testLead.Id,newMember1.Id,subject,'Campaign',c.Id);
        testContact.Marketing_opt_out__c = true;
        update testContact;
        list<MassEmailControllerNew.ContactWrapper> contacts = MassEmailControllerNew.uncontacts(c.Id,'Campaign');
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
        /*
        LG_Student__c student = new LG_Student__c(Id = testEnv.studentId);
        student.Status_in_LG__c = 'Registered';
        student.Student_Course_Start_Date__c = system.today().addDays(-1);
        update student;
        */
        ApexPages.currentPage().getParameters().put('mode', 'lg');
        MassEmailControllerNew mecObj = new MassEmailControllerNew();
        list<MassEmailControllerNew.FieldWrapper> objects = MassEmailControllerNew.fetchMergeFields('Account');
        list<MassEmailControllerNew.FieldWrapper> fields = MassEmailControllerNew.fetchMergeFields('Contact');
        string mergefield = MassEmailControllerNew.getField('Contact','Email');
        MassEmailControllerNew.ContactResultWrapper contactWP  = MassEmailControllerNew.contacts(lg.Id,'Lg',JSON.serialize(new list<string>()),false);
        map<string,string> subMap = new map<string,string>();
        string conId = '';
        string recId = '';
        for(MassEmailControllerNew.ContactWrapper cw : contactWP.contacts){
            subMap.put(cw.Id,cw.recId);
            conId = cw.Id;
            recId = cw.recId;
        }
        
        list<MassEmailControllerNew.FieldWrapper> filterFields = MassEmailControllerNew.getFilterFields('Lg');
        contactWP = MassEmailControllerNew.search(lg.Id,'Lg',JSON.serialize(filterFields),JSON.serialize(new list<string>()),false);
        string subject = '{!Contact.Name}';
        string body = 'hello {!Lg__c.Name}  {!LG_Student__c.Name} {!$User.Account.CurrencyIsoCode} {!Contact.Name} {!Account.Name} {!$Organization.Address} {!$System.Now} {!$System.Today} {!$System.Day} {!$System.Month} {!$System.Year}  {!$User.Email}';
        Test.startTest();
        string result = MassEmailControllerNew.sendEmail(body,JSON.serialize(subMap),subject,lg.Id,'Lg','test2');
        result = MassEmailControllerNew.preview(body,conId,recId,subject,'Lg',lg.Id);
        list<MassEmailControllerNew.ContactWrapper> contacts = MassEmailControllerNew.uncontacts(lg.Id,'Lg');
         Test.stopTest();
    }
    
    static testmethod void unitTest03() {
        List<Email_Template__c> lstEmailTemp = new List<Email_Template__c>();
        for(Integer i = 0;i<5;i++){
        Email_Template__c emtemp = new Email_Template__c();
        emtemp.Name = 'Test Temp'+i;
        emtemp.Subject__c = 'Testing Purpose';
        emtemp.Body__c = 'hello {!$System.Today}';
        emtemp.Html_Value__c = 'hello {!$System.Today}';
        emtemp.Is_Active__c = true;
        emtemp.Related_To_Base_Object__c = 'Campaign';
        lstEmailTemp.add(emtemp);
        }
        insert lstEmailTemp;
        MassEmailConfiguration__c mec = new MassEmailConfiguration__c(Folders__c = 'test', Site_Url__c = 'https://dev1-hdcmassemails.cs86.force.com/');
        insert mec;
        Account acc = new Account(Name = 'test account', BillingCountry = 'France');
        insert acc;
        Contact testContact = new Contact(AccountId = acc.Id, FirstName = 'TestContactF', LastName = 'TestContactL', Email = 'none@navinet.net');
        insert testContact;
        map<string,string> subMap = new map<string,string>();
        subMap.put(testContact.Id,testContact.Id);
        ApexPages.currentPage().getParameters().put('mode', 'campaign');
        MassEmailControllerNew mecObj = new MassEmailControllerNew();
        list<MassEmailControllerNew.FieldWrapper> filterFields = MassEmailControllerNew.getFilterFields('Contact');
        string subject = '{!Contact.Name}';
        string body = 'hello {!Lg__c.Name}  {!LG_Student__c.Name} {!Contact.Name} {!Account.Name} hello {!Seminar__c.Name} {!Seminar_Teachers__c.Name} {!$User.Account.CurrencyIsoCode} {!Account.Name} {!$Organization.Address} {!$System.Now}  {!$User.Email} {!$System.Today} {!$System.Day} {!$System.Month} {!$System.Year}';
        string result = MassEmailControllerNew.sendEmail(body,JSON.serialize(subMap),subject,testContact.Id,'Contact','test');
        result = MassEmailControllerNew.preview(body,testContact.Id,testContact.Id,subject,'Contact',testContact.Id);
        list<MassEmailControllerNew.FieldWrapper> fields = MassEmailControllerNew.fetchMergeFields('Contact');
        for(MassEmailControllerNew.FieldWrapper fw : fields){
            if(fw.type == 'Date')
                MassEmailControllerNew.createFilterCondition(fw.name,'not equal to','2016/5/5',fw.type,'');
            else if(fw.type == 'DateTime')
                MassEmailControllerNew.createFilterCondition(fw.name,'equal to','2017/26/4',fw.type,'');
            else
                MassEmailControllerNew.createFilterCondition(fw.name,'not equal to','',fw.type,'');
        }
    }
    static testmethod void unitTest04() {
        List<Email_Template__c> lstEmailTemp = new List<Email_Template__c>();
        for(Integer i = 0;i<5;i++){
        Email_Template__c emtemp = new Email_Template__c();
        emtemp.Name = 'Test Temp'+i;
        emtemp.Subject__c = 'Testing Purpose';
        emtemp.Body__c = 'hello {!$System.Today}';
        emtemp.Html_Value__c = 'hello {!$System.Today}';
        emtemp.Is_Active__c = true;
        emtemp.Related_To_Base_Object__c = 'Campaign';
        lstEmailTemp.add(emtemp);
        }
        insert lstEmailTemp;
        MassEmailConfiguration__c mec = new MassEmailConfiguration__c(Folders__c = 'test', Site_Url__c = 'https://dev1-hdcmassemails.cs86.force.com/');
        insert mec;
        Account acc = new Account(Name = 'test account', BillingCountry = 'France');
        insert acc;
        Contact testContact = new Contact(AccountId = acc.Id, FirstName = 'TestContactF', LastName = 'TestContactL', Email = 'none@navinet.net');
        insert testContact;
        map<string,string> subMap = new map<string,string>();
        subMap.put(testContact.Id,testContact.Id);
        ApexPages.currentPage().getParameters().put('mode', 'Seminar');
        Test.startTest();
        MassEmailControllerNew mecObj = new MassEmailControllerNew();
        list<MassEmailControllerNew.FieldWrapper> filterFields = MassEmailControllerNew.getFilterFields('Contact');
        string subject = '{!Contact.Name}';
        string body = 'hello {!Seminar__c.Name}  {!Seminar_Teachers__c.Name} {!Contact.FirstName} {!Account.Name} {!$Organization.Address} {!$System.Now} {!$Organization.CreatedBy.AccountId}  {!$User.Email} {!$System.Today} {!$System.Day} {!$System.Month} {!$System.Year} ';
        string result = MassEmailControllerNew.sendEmail(body,JSON.serialize(subMap),subject,testContact.Id,'Contact','test');
        result = MassEmailControllerNew.preview(body,testContact.Id,testContact.Id,subject,'Contact',testContact.Id);
        list<MassEmailControllerNew.FieldWrapper> fields = MassEmailControllerNew.fetchMergeFields('Contact');
        for(MassEmailControllerNew.FieldWrapper fw : fields){
            if(fw.type == 'Date')
                MassEmailControllerNew.createFilterCondition(fw.name,'not equal to','2016/5/5',fw.type,'');
            else if(fw.type == 'DateTime')
                MassEmailControllerNew.createFilterCondition(fw.name,'not equal to','2016/5/5',fw.type,'');
            else
                MassEmailControllerNew.createFilterCondition(fw.name,'not equal to','',fw.type,'');
        }
        Test.stopTest();
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
        Test.startTest();
        Seminar_Teachers__c st = ObjectCreator.getNewSeminarTeacher(seminar.Id, testEnv.teacherContactId);
        st.Teacher__c = testEnv.teacherContactId;
        insert st;
        
        Account acc = new Account();
         acc.Name = 'test';
         acc.BillingCountry = 'France';
         insert acc;
        
        Contact c = new Contact();
         c.FirstName = 'test';
         c.LastName = 'test';
         c.Email = 'test@test.com';
         c.AccountId = acc.Id;
         insert c;  
        
        //semTeacher.Seminar_Start_Date__c = system.today().addDays(-1);
        //insert semTeacher;
        
        ApexPages.currentPage().getParameters().put('mode', 'Seminar');
        
        MassEmailControllerNew mecObj = new MassEmailControllerNew();
        list<MassEmailControllerNew.FieldWrapper> objects = MassEmailControllerNew.fetchMergeFields('');
        list<MassEmailControllerNew.FieldWrapper> fields = MassEmailControllerNew.fetchMergeFields('Contact');
        string mergefield = MassEmailControllerNew.getField('Contact','Email');
        MassEmailControllerNew.ContactResultWrapper contactWP  = MassEmailControllerNew.contacts(seminar.Id,'Seminar',JSON.serialize(new list<string>()),false);
        map<string,string> subMap = new map<string,string>();
        string conId = '';
        string recId = '';
        for(MassEmailControllerNew.ContactWrapper cw : contactWP.contacts){
            subMap.put(cw.Id,cw.recId);
            conId = cw.Id;
            recId = cw.recId;
        }
        list<MassEmailControllerNew.FieldWrapper> fieldsdate = MassEmailControllerNew.fetchMergeFields('Contact');
        for(MassEmailControllerNew.FieldWrapper fw : fieldsdate){
            if(fw.type == 'Date')
                MassEmailControllerNew.createFilterCondition(fw.name,'greater or equal','2017/3/3',fw.type,'');
            else if(fw.type == 'DateTime')
                MassEmailControllerNew.createFilterCondition(fw.name,'less than','2016/5/5',fw.type,'');
            else
                MassEmailControllerNew.createFilterCondition(fw.name,'equals','',fw.type,'');
        }
        
        list<MassEmailControllerNew.FieldWrapper> filterFields = MassEmailControllerNew.getFilterFields('Seminar');
        contactWP = MassEmailControllerNew.search(seminar.Id,'Seminar',JSON.serialize(filterFields),JSON.serialize(new list<string>()),false);
        
        string subject = '{!Contact.Name}';
        string body = 'hello {!Seminar__c.Name}  {!Seminar_Teachers__c.Name} {!Contact.FirstName} {!Account.Name} {!$Organization.Address} {!$System.Now}  {!Campaign.LastModifiedBy.Street}  {!$User.Email} {!$System.Today} {!$System.Day} {!$System.Month} {!$System.Year}';
        string result = MassEmailControllerNew.sendEmail(body,JSON.serialize(subMap),subject,seminar.Id,'Seminar','test');
        result = MassEmailControllerNew.preview(body,conId,recId,subject,'Seminar',seminar.Id);
        
        list<MassEmailControllerNew.ContactWrapper> contacts = MassEmailControllerNew.uncontacts(seminar.Id,'Seminar');
        Test.stopTest();
    }
}