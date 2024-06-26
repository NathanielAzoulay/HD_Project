@isTest
private class HD_SharingMethods_Test {

     
    @isTest(seeAllData=false)
    static void Document_CreateSharingRules_Test() {
        Account acc1 = ObjectCreator.getNewAccount();
        insert acc1;
        
        Document__c doc1 = new Document__c();
        doc1.Application__c = acc1.Id;
        insert doc1;
        
        test.startTest();
        
        HD_SharingMethods.Document_CreateSharingRules( new Set<Id>{doc1.Id} );
        
        test.stopTest();
    }
    
    @isTest(seeAllData=false)
    static void PltAssignment_CreateSharingRules_Test() {

        ObjectCreator.initializeCustomSetting();


        Account acc2 = ObjectCreator.getNewAccount();
        insert acc2;

        Contact teacherContact2 = ObjectCreator.getNewContact(acc2.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact2;

        User u2 = ObjectCreator.getNewUser(teacherContact2.Id);
        insert u2;

        Contact contact3 = ObjectCreator.getNewContact(acc2.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert contact3;

        User u3 = ObjectCreator.getNewUser(contact3.Id);
        insert u3;

        Contact contact1 = ObjectCreator.getNewContact(acc2.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert contact1;

        User u1 = ObjectCreator.getNewUser(contact1.Id);
        insert u1;

        Account partnerAcc = ObjectCreator.getNewAccount();
        partnerAcc.Partner_Account_User__c = u1.Id;
        partnerAcc.Partner_Account_Manager__c = u2.Id;
        partnerAcc.Partner_Account_NC__c = u3.Id;
        insert partnerAcc;

        Price_List_Title__c priceListTitle = ObjectCreator.getNewPriceListTitle();
        priceListTitle.RecordTypeId = Schema.SObjectType.Price_List_Title__c.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();
        insert priceListTitle;

        Price_List_Title_Assignment__c priceListTitleAssignment = new Price_List_Title_Assignment__c();
        priceListTitleAssignment.Franchise__c = partnerAcc.Id;
        priceListTitleAssignment.Price_List_Title__c = priceListTitle.Id;
        insert priceListTitleAssignment;

        System.assert([SELECT Id FROM Price_List_Title__Share WHERE ParentId = :priceListTitle.Id AND UserOrGroupId = :u2.id].size() == 1);
        System.assert([SELECT Id FROM Price_List_Title__Share WHERE ParentId = :priceListTitle.Id AND UserOrGroupId = :u3.id].size() == 1);
        System.assert([SELECT Id FROM Price_List_Title__Share WHERE ParentId = :priceListTitle.Id AND UserOrGroupId = :u1.id].size() == 1);

    }

    @isTest(seeAllData=false)
    static void CampaignCreateSharingRules_Test() {
        HD_TriggerSettings.disableAllTriggers = true;
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        ObjectCreator.EnableSharingMethods();
        
        Account partnerAcc = ObjectCreator.getNewAccount();
        insert partnerAcc;

        Contact partnerteacherContact   = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert partnerteacherContact;

        User u = ObjectCreator.getNewUser(partnerteacherContact.Id);
        insert u;

        Contact contact3 = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert contact3;

        User u3 = ObjectCreator.getNewUser(contact3.Id);
        insert u3;

        Account teacherAcc = new Account(Id = testEnv.accId);
        teacherAcc.Partner_Account_User__c = u.Id;
        teacherAcc.Partner_Account_NC__c = u3.Id;
        update teacherAcc;

        User u2 = ObjectCreator.getNewUser(testEnv.teacherContactId);
        insert u2;

        Campaign camp = ObjectCreator.getNewCampaign();
        HD_TriggerSettings.disableAllTriggers = false;
        System.runAs(u2){
            
            insert camp;
        }       

        System.assert([SELECT Id FROM CampaignShare WHERE CampaignId = :camp.Id AND UserOrGroupId = :u.id].size() == 1);
        System.assert([SELECT Id FROM CampaignShare WHERE CampaignId = :camp.Id AND UserOrGroupId = :u3.id].size() == 1);

    }

    @isTest(seeAllData=false)
    static void lgStudent_CreateSharingRules_Test() {
        HD_TriggerSettings.disableAllTriggers = true;
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        ObjectCreator.EnableSharingMethods();
        //System.assert([SELECT Id FROM AccountShare WHERE AccountId = :testEnv.accId AND AccountAccessLevel = 'Read'].size() == 1);

        LG__c lg        = new LG__c(Id = testEnv.lgId);
        lg.Teacher__c   = testEnv.teacherContactId;
        update lg;

        Account partnerAcc = ObjectCreator.getNewAccount();
        insert partnerAcc;

        Contact studentContact  = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId());              
        insert studentContact;

        User u = ObjectCreator.getNewUser(testEnv.teacherContactId);
        insert u;

        Contact contact2    = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert contact2;

        User u2 = ObjectCreator.getNewUser(contact2.Id);
        insert u2;

        Contact partnerteacherContactNC = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert partnerteacherContactNC;

        test.startTest();
        HD_TriggerSettings.disableAllTriggers = false;
        
        User uNC = ObjectCreator.getNewUser(partnerteacherContactNC.Id);
        insert uNC;
        
        partnerAcc.Partner_Account_NC__c = uNC.Id;
        partnerAcc.Partner_Account_User__c = u2.Id;
        update partnerAcc;
    
        System.assertNotEquals(null, studentContact.Id);
        
        LG_Student__c student   = ObjectCreator.getNewLGStudent(studentContact.Id, testEnv.lgId);
        student.Student_End_Paying_Date__c = system.today();
        student.Student_Course_End_Date__c = System.today().addDays(5);
        insert student;

        System.assert([SELECT Id FROM ContactShare WHERE ContactId = :studentContact.Id AND UserOrGroupId = :u.id].size() == 1);
        System.assert([SELECT Id FROM ContactShare WHERE ContactId = :studentContact.Id AND UserOrGroupId = :u2.id].size() == 1);
        System.assert([SELECT Id FROM ContactShare WHERE ContactId = :studentContact.Id AND UserOrGroupId = :uNC.id].size() == 1);
    
        test.stopTest();
    }

    @isTest(seeAllData=false)
    static void lgDHCreateSharingRules_Test() {

        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        ObjectCreator.EnableSharingMethods();
        //System.assert([SELECT Id FROM LG__Share WHERE ParentId = :testEnv.lgId].size() == 0);

        User u = ObjectCreator.getNewUser(testEnv.teacherContactId);
        insert u;

        LG_Days_Hours__c lgdh   = new LG_Days_Hours__c(Id = testEnv.lgDHId);
        lgdh.Teacher__c         = testEnv.teacherContactId;
        update lgdh;        

        //System.assert([SELECT Id FROM LG__Share WHERE ParentId = :testEnv.lgId AND UserOrGroupId = :u.id].size() > 0);
        //System.assert([SELECT Id FROM AccountShare WHERE AccountId = :testEnv.accId AND UserOrGroupId = :u.id].size() > 0);

    }

    @isTest(seeAllData=false)
    static void FamilyCreateSharingRules_Test() {
        HD_TriggerSettings.disableAllTriggers = true;
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        ObjectCreator.EnableSharingMethods();
        
        Account partnerAcc = ObjectCreator.getNewAccount();
        insert partnerAcc;

        Contact partnerteacherContact   = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert partnerteacherContact;

        User u = ObjectCreator.getNewUser(partnerteacherContact.Id);
        insert u;

        Contact contact3 = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert contact3;

        User u3 = ObjectCreator.getNewUser(contact3.Id);
        insert u3;

        Account teacherAcc = new Account(Id = testEnv.accId);
        teacherAcc.Partner_Account_User__c = u.Id;
        teacherAcc.Partner_Account_NC__c = u3.Id;
        update teacherAcc;

        User u2 = ObjectCreator.getNewUser(testEnv.teacherContactId);
        insert u2;

        Family__c family = new Family__c(Name = 'test ' + String.valueOf(Math.random()) );
        HD_TriggerSettings.disableAllTriggers = false;
        System.runAs(u2){
            
            insert family;
        }       

        System.assert([SELECT Id FROM Family__Share WHERE ParentId = :family.Id AND UserOrGroupId = :u.id].size() == 1);
        System.assert([SELECT Id FROM Family__Share WHERE ParentId = :family.Id AND UserOrGroupId = :u3.id].size() > 0);

    }

    @isTest(seeAllData=false)
    static void CourseSubType_CreateSharingRules_Test() {
        HD_TriggerSettings.disableAllTriggers = true;
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        ObjectCreator.EnableSharingMethods();
        
        Account partnerAcc = ObjectCreator.getNewAccount();
        insert partnerAcc;

        Contact partnerteacherContact   = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert partnerteacherContact;

        User u = ObjectCreator.getNewUser(partnerteacherContact.Id);
        insert u;

        User u2 = ObjectCreator.getNewUser(testEnv.teacherContactId);
        insert u2;

        Contact contact3 = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert contact3;

        User u3 = ObjectCreator.getNewUser(contact3.Id);
        insert u3;

        Contact partnerteacherContactNC = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        partnerteacherContactNC.SET__c = false;
        insert partnerteacherContactNC;
        
        test.startTest();
        HD_TriggerSettings.disableAllTriggers = false;
        User uNC = ObjectCreator.getNewUser(partnerteacherContactNC.Id);
        insert uNC;

        Account teacherAcc = new Account(Id = testEnv.accId);
        teacherAcc.Partner_Account_User__c = u2.Id;
        teacherAcc.ParentId = partnerAcc.Id;
        update teacherAcc;

        partnerAcc.Partner_Account_User__c = u3.Id;
        partnerAcc.Partner_Account_NC__c = uNC.Id;
        update partnerAcc;      

        Course_Sub_Type__c curseSubType = ObjectCreator.getNewCourseSubType(testEnv.accId, testEnv.baseCurseId);
        curseSubType.OwnerId = u.Id;
                
        insert curseSubType;

        System.debug('u1 ' + u.id);
        System.debug([SELECT Id, UserOrGroupId FROM Course_Sub_Type__Share WHERE ParentId = :curseSubType.Id]);
        System.debug('u2 ' + u2.id);
//XXX       System.assert([SELECT Id FROM Course_Sub_Type__Share WHERE ParentId = :curseSubType.Id AND UserOrGroupId = :u2.id].size() == 1);
//XXX       System.assert([SELECT Id FROM Course_Sub_Type__Share WHERE ParentId = :curseSubType.Id AND UserOrGroupId = :u3.id].size() == 1);
//XXX       System.assert([SELECT Id FROM Course_Sub_Type__Share WHERE ParentId = :curseSubType.Id AND UserOrGroupId = :uNC.id].size() == 1);

        test.stopTest();
    }

    @isTest(seeAllData=false)
    static void HolidayVacation_CreateSharingRules_Test() {
        HD_TriggerSettings.disableAllTriggers = true;
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        ObjectCreator.EnableSharingMethods();
        
        Account teacherAcc = ObjectCreator.getNewAccount();
        insert teacherAcc;

        Contact teacherContact = ObjectCreator.getNewContact(teacherAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        teacherContact.MailingCountry = 'Spain';
        insert teacherContact;

        teacherContact.MailingCountry = 'Spain';
        update teacherContact;

        User u0 = ObjectCreator.getNewUser(teacherContact.Id);
        insert u0;

        Account partnerAcc2 = ObjectCreator.getNewAccount();
        insert partnerAcc2;

        Contact partnerteacherContact2 = ObjectCreator.getNewContact(partnerAcc2.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert partnerteacherContact2;

        User u2 = ObjectCreator.getNewUser(partnerteacherContact2.Id);
        insert u2;
        
        test.startTest();
        HD_TriggerSettings.disableAllTriggers = false;
        
        Account partnerAcc3 = ObjectCreator.getNewAccount();
        insert partnerAcc3;

        Contact partnerteacherContact3 = ObjectCreator.getNewContact(partnerAcc3.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert partnerteacherContact3;

        User u3 = ObjectCreator.getNewUser(partnerteacherContact3.Id);
        insert u3;

        Holiday_Vacation__c holiday = ObjectCreator.getNewHolidayVacation(Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('Country').getRecordTypeId());
        holiday.Country__c = 'Spain';

        Holiday_Vacation__c holiday2 = ObjectCreator.getNewHolidayVacation(Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('LC').getRecordTypeId());
        holiday2.LC__c = partnerAcc2.Id;

        Holiday_Vacation__c holiday3 = ObjectCreator.getNewHolidayVacation(Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('MF').getRecordTypeId());
        holiday3.MF__c = partnerAcc3.Id;    

        insert new List<Holiday_Vacation__c>{holiday,holiday2,holiday3};                

        System.assert([SELECT Id FROM Holiday_Vacation__Share WHERE ParentId = :holiday.Id AND UserOrGroupId = :u0.id].size() == 1);
        System.assert([SELECT Id FROM Holiday_Vacation__Share WHERE ParentId = :holiday2.Id AND UserOrGroupId = :u2.id].size() == 1);
        System.assert([SELECT Id FROM Holiday_Vacation__Share WHERE ParentId = :holiday3.Id AND UserOrGroupId = :u3.id].size() == 1);
        
        test.stopTest();
    }

    @isTest(seeAllData=false)
    static void HolidayVacation_CreateSharingRules2_Test() {
        HD_TriggerSettings.disableAllTriggers = true;
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        ObjectCreator.EnableSharingMethods();

        Account teacherAcc = ObjectCreator.getNewAccount();
        insert teacherAcc;

        Contact teacherContact = ObjectCreator.getNewContact(teacherAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact;

        User u0 = ObjectCreator.getNewUser(teacherContact.Id);
        insert u0;

        Account partnerAcc2 = ObjectCreator.getNewAccount();
        partnerAcc2.ParentId = teacherAcc.Id;
        insert partnerAcc2;

        Account partnerAcc3 = ObjectCreator.getNewAccount();
        partnerAcc3.ParentId = partnerAcc2.Id;
        insert partnerAcc3;

        
        test.startTest();
        HD_TriggerSettings.disableAllTriggers = false;
        
        Contact partnerteacherContact2 = ObjectCreator.getNewContact(partnerAcc3.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert partnerteacherContact2;

        User u2 = ObjectCreator.getNewUser(partnerteacherContact2.Id);
        insert u2;

        Holiday_Vacation__c holiday2 = ObjectCreator.getNewHolidayVacation(Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('LC').getRecordTypeId());
        holiday2.LC__c = partnerAcc2.Id;

        Holiday_Vacation__c holiday3 = ObjectCreator.getNewHolidayVacation(Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('MF').getRecordTypeId());
        holiday3.MF__c = teacherAcc.Id;    

        List<Holiday_Vacation__c> holidays = new List<Holiday_Vacation__c>();
        holidays.add(holiday2);
        holidays.add(holiday3);
        insert holidays;

        System.assert([SELECT Id FROM Holiday_Vacation__Share WHERE ParentId = :holiday2.Id AND UserOrGroupId = :u2.id].size() == 1);
        System.assert([SELECT Id FROM Holiday_Vacation__Share WHERE ParentId = :holiday3.Id AND UserOrGroupId = :u0.id].size() == 1);
        
        test.stopTest();
    }


    @isTest(seeAllData=false)
    static void Account_CreateSharingRules_Test() {

        ObjectCreator.initializeCustomSetting();

        Account acc2 = ObjectCreator.getNewAccount();
        insert acc2;

        Contact teacherContact1 = ObjectCreator.getNewContact(acc2.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact1;

        User u1 = ObjectCreator.getNewUser(teacherContact1.Id);
        insert u1;

        Contact teacherContact2 = ObjectCreator.getNewContact(acc2.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact2;

        User u2 = ObjectCreator.getNewUser(teacherContact2.Id);
        insert u2;

        Account partnerAcc = ObjectCreator.getNewAccount();
        insert partnerAcc;

        Contact contact3 = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert contact3;

        User u3 = ObjectCreator.getNewUser(contact3.Id);
        insert u3;

        Account acc1 = ObjectCreator.getNewAccount();
        acc1.Partner_Account_Manager__c = u1.Id;
        acc1.Partner_Account_User__c = u2.Id;
        acc1.Partner_Account_NC__c = u3.Id;

        insert acc1;        
        
        System.assert([SELECT Id FROM AccountShare WHERE AccountId = :acc1.Id AND UserOrGroupId = :u1.id].size() == 1);
        System.assert([SELECT Id FROM AccountShare WHERE AccountId = :acc1.Id AND UserOrGroupId = :u2.id].size() == 1);
        System.assert([SELECT Id FROM AccountShare WHERE AccountId = :acc1.Id AND UserOrGroupId = :u3.id].size() == 1);

    }   

    @isTest(seeAllData=false)
    static void Opportunity_CreateSharingRules_Test() {

        ObjectCreator.initializeCustomSetting();

        Account acc = ObjectCreator.getNewAccount();
        insert acc;

        Contact teacherContact = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact;

        User u = ObjectCreator.getNewUser(teacherContact.Id);
        insert u;

        Contact contact2 = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert contact2;

        User u2 = ObjectCreator.getNewUser(contact2.Id);
        insert u2;

        Account acc2 = ObjectCreator.getNewAccount();
        acc2.Partner_Account_User__c = u.Id;
        acc2.Partner_Account_NC__c = u2.Id;
        insert acc2;

        Opportunity opp = new Opportunity();
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId();
        opp.AccountId = acc2.Id;
        opp.Name = 'test opp';
        opp.StageName = 'Prospecting';
        opp.CloseDate = System.today();
        opp.CurrencyIsoCode = UserInfo.getDefaultCurrency();
        
        insert opp;        
        
        //System.assert([SELECT Id FROM OpportunityShare WHERE OpportunityId = :opp.Id AND UserOrGroupId = :u.id].size() > 0);
        //System.assert([SELECT Id FROM OpportunityShare WHERE OpportunityId = :opp.Id AND UserOrGroupId = :u2.id].size() > 0);

    }

    @isTest(seeAllData=false)
    static void LG_CreateSharingRules_Test() {

        ObjectCreator.initializeCustomSetting();

        Account acc2 = ObjectCreator.getNewAccount();
        insert acc2;

        Contact teacherContact2 = ObjectCreator.getNewContact(acc2.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact2;

        User u2 = ObjectCreator.getNewUser(teacherContact2.Id);
        insert u2;

        Contact contact3 = ObjectCreator.getNewContact(acc2.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert contact3;

        User u3 = ObjectCreator.getNewUser(contact3.Id);
        insert u3;

        Account lc = ObjectCreator.getNewAccount();
        lc.Partner_Account_User__c = u2.Id;
        lc.Partner_Account_NC__c = u3.Id;
        insert lc;

        Contact teacherContact  = ObjectCreator.getNewContact(lc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact;

        User u = ObjectCreator.getNewUser(teacherContact.Id);
        insert u;

        Account acc = ObjectCreator.getNewAccount();        
        insert acc;

        Agreement__c agree  = ObjectCreator.getNewAgreement(acc.Id);             
        insert agree;

        Base_Course__c baseCurse = ObjectCreator.getNewBaseCourse();                
        insert baseCurse;

        Course_Sub_Type__c curseSubType = ObjectCreator.getNewCourseSubType(acc.Id, baseCurse.Id);              
        insert curseSubType;

        LG__c lg            = ObjectCreator.getNewLG(acc.Id, curseSubType.Id, agree.Id);
        lg.Franchisee__c    = lc.Id;    
        lg.Teacher__c       = teacherContact.Id;
        insert lg;        
        
        System.assert([SELECT Id FROM LG__Share WHERE ParentId = :lg.Id AND UserOrGroupId = :u.id].size() == 1);
        System.assert([SELECT Id FROM LG__Share WHERE ParentId = :lg.Id AND UserOrGroupId = :u2.id].size() == 1);
        System.assert([SELECT Id FROM LG__Share WHERE ParentId = :lg.Id AND UserOrGroupId = :u3.id].size() == 1);

    }


    @isTest(seeAllData=false)
    static void SeminarDeleteManualSharing_Test() {
        HD_TriggerSettings.disableAllTriggers = true;
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        ObjectCreator.EnableSharingMethods();
        
        Account partnerAcc = ObjectCreator.getNewAccount();
        insert partnerAcc;
        
        Contact partnerteacherContactNC = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());
        partnerteacherContactNC.TT_Qualified__c = 'TT';
        insert partnerteacherContactNC;
        
        User uNC = ObjectCreator.getNewUser(partnerteacherContactNC.Id);
        uNC.ContactId = partnerteacherContactNC.Id;
        insert uNC;
        
        Contact ttcontact = ObjectCreator.getNewContact(testEnv.accId, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());
        ttcontact.TT_Qualified__c = 'TT';              
        insert ttcontact;

        User ttu = ObjectCreator.getNewUser(ttcontact.Id);
        insert ttu;

        partnerAcc.Partner_Account_NC__c = uNC.Id;
        partnerAcc.Partner_Account_User__c = uNC.Id;
        update partnerAcc;
        
        partnerteacherContactNC.Contact_Partner_User__c = uNC.Id;
        update partnerteacherContactNC;
        
        Seminar_Type__c stype = ObjectCreator.getNewSeminarType();
        insert stype;
        
        //HD_TriggerSettings.disableAllTriggers = false;
        Seminar__c seminar = new Seminar__c();      
        seminar.Hosting_Franchisee__c = partnerAcc.Id; 
        seminar.Teacher_Trainer__c = ttcontact.Id;
        seminar.TT_Status__c = 'Approved by TT';
        seminar.Status__c = 'Processing Application';
        seminar.Seminar_Type__c = stype.Id;
        insert seminar;

        System.assert([SELECT Id FROM Seminar__c WHERE Id = :seminar.Id and RecordtypeId != null].size() > 0);
        
        insert new Seminar__Share( AccessLevel = 'Edit', RowCause = 'Manual', ParentId = seminar.Id, UserOrGroupId = uNC.id );
        
        List<Seminar__Share> ls = [SELECT Id FROM Seminar__Share WHERE ParentId = :seminar.Id AND UserOrGroupId = :uNC.id AND RowCause = 'Manual' ];
        System.assert(ls.size() > 0);

        System.debug(LoggingLevel.ERROR, '*** : ' + ls);


        seminar.Status__c = 'Confirmed';
        
        update seminar;
        
        Seminar_Teachers__c st = ObjectCreator.getNewSeminarTeacher(seminar.Id, partnerteacherContactNC.Id);
        st.Teacher__c = partnerteacherContactNC.Id;
        st.Seminar__c = seminar.Id;
        st.Teacher_Status_in_seminar__c = 'Registered';
        insert st;
        
        System.debug(LoggingLevel.ERROR, '*** q1: ' + [SELECT Id, RowCause, UserOrGroupId FROM Seminar__Share WHERE ParentId = :seminar.Id AND UserOrGroupId = :uNC.id]);
        seminar.Status__c = 'Cancelled';
        update seminar;
        System.debug(LoggingLevel.ERROR, '*** q2: ' + [SELECT Id, RowCause, UserOrGroupId FROM Seminar__Share WHERE ParentId = :seminar.Id AND UserOrGroupId = :uNC.id]);
        
        test.startTest();
        Batch_SeminarDeleteManualSharing b = new Batch_SeminarDeleteManualSharing();
        b.seminarCancelled = new List<Seminar__c>{seminar};
            b.notDeleteTrainer = new Map<Id, Id>{ seminar.Id => partnerteacherContactNC.Id };
        Database.executeBatch(b);

        test.stopTest();

        //System.assert([SELECT Id FROM Seminar__Share WHERE ParentId = :seminar.Id AND UserOrGroupId = :uNC.id].size() == 0);
    }


    @isTest(seeAllData=false)
    static void Seminar_HostFranchiseeCreateSharingRules_Test() {
        HD_TriggerSettings.disableAllTriggers = true;
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        ObjectCreator.EnableSharingMethods();
        
        Account partnerAcc = ObjectCreator.getNewAccount();
        insert partnerAcc;

        Contact partnerteacherContactNC = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert partnerteacherContactNC;

        User uNC = ObjectCreator.getNewUser(partnerteacherContactNC.Id);
        insert uNC;

        partnerAcc.Partner_Account_NC__c = uNC.Id;
        update partnerAcc;
        HD_TriggerSettings.disableAllTriggers = false;
        Seminar__c seminar = new Seminar__c();      
        seminar.Hosting_Franchisee__c = partnerAcc.Id;      
        insert seminar;

        System.assert([SELECT Id FROM Seminar__Share WHERE ParentId = :seminar.Id AND UserOrGroupId = :uNC.id].size() > 0);

    }

    @isTest(seeAllData=false)
    static void Seminar_TeacherTrainersCreateSharingRules_Test() {
        HD_TriggerSettings.disableAllTriggers = true;
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        ObjectCreator.EnableSharingMethods();
        
        Account partnerAcc = ObjectCreator.getNewAccount();
        insert partnerAcc;

        Contact partnerteacherContact   = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert partnerteacherContact;

        User u = ObjectCreator.getNewUser(partnerteacherContact.Id);
        insert u;
        
        partnerAcc.Partner_Account_NC__c = u.Id;
        update partnerAcc;

        Contact seminarContact = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId()); 
        seminarContact.TT_Qualified__c = 'TT';             
        insert seminarContact;

        User u3 = ObjectCreator.getNewUser(seminarContact.Id);
        insert u3;
        
        test.startTest();
        HD_TriggerSettings.disableAllTriggers = false;
        Seminar_Type__c seminarType = new Seminar_Type__c(Name = 'test ' + String.valueOf(Math.random()) );
        seminarType.Active__c = true;
        seminarType.Program_Type__c = 'HDE';

        insert seminarType;

        Seminar__c seminar = new Seminar__c();      
        seminar.Seminar_Type__c = seminarType.Id;

        System.debug(LoggingLevel.ERROR, '*** u3: ' + u3);
        System.debug(LoggingLevel.ERROR, '*** u: ' + u);        
                
        insert seminar;
        seminar.Teacher_Trainer__c = seminarContact.Id;
        update seminar;
        

        System.debug(LoggingLevel.ERROR, '*** : ' + [SELECT Id FROM Seminar__Share]);

        //System.assert([SELECT Id FROM Seminar__Share WHERE ParentId = :seminar.Id AND UserOrGroupId = :u3.id].size() > 0);
        //System.assert([SELECT Id FROM Seminar__Share WHERE ParentId = :seminar.Id AND UserOrGroupId = :u.id].size() > 0);
        
        test.stopTest();
    }

    @isTest(seeAllData=false)
    static void Lead_CreateSharingRules_Test() {
        HD_TriggerSettings.disableAllTriggers = true;
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        ObjectCreator.EnableSharingMethods();
        
        Account partnerAcc = ObjectCreator.getNewAccount();
        insert partnerAcc;

        Contact partnerteacherContact   = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert partnerteacherContact;

        User u = ObjectCreator.getNewUser(partnerteacherContact.Id);
        insert u;

        Account teacherAcc = new Account(Id = testEnv.accId);
        teacherAcc.Partner_Account_User__c = u.Id;
        update teacherAcc;

        User u2 = ObjectCreator.getNewUser(testEnv.teacherContactId);
        insert u2;

        Lead l = new Lead(FirstName = 'ignoretestone', LastName = 'ignoretesttwo', Company = 'testCompany');
        HD_TriggerSettings.disableAllTriggers = false;
        System.runAs(u2){           
            insert l;
        }


        System.assert([SELECT Id FROM LeadShare WHERE LeadId = :l.Id AND UserOrGroupId = :u.id].size() > 0);

    }

    @isTest(seeAllData=false)
    static void teacherAgreement_CreateSharingRules_Test() {
        HD_TriggerSettings.disableAllTriggers = true;
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        ObjectCreator.EnableSharingMethods();
        
        Account partnerAcc = ObjectCreator.getNewAccount();
        insert partnerAcc;

        Contact partnerteacherContact   = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert partnerteacherContact;

        User u = ObjectCreator.getNewUser(partnerteacherContact.Id);
        insert u;

        Account teacherAcc = new Account(Id = testEnv.accId);
        teacherAcc.Partner_Account_User__c = u.Id;
        update teacherAcc;

        User u2 = ObjectCreator.getNewUser(testEnv.teacherContactId);
        insert u2;
        
        HD_TriggerSettings.disableAllTriggers = false;
        
        Teacher_Agreement__c tAgree = new Teacher_Agreement__c();
        tAgree.Teacher__c = partnerteacherContact.Id;
        
        insert tAgree;

        System.assert([SELECT Id FROM Teacher_Agreement__Share WHERE ParentId = :tAgree.Id AND UserOrGroupId = :u.id].size() > 0);

    }

    @isTest(seeAllData=false)
    static void Agreement_CreateSharingRules_Test() {

        ObjectCreator.initializeCustomSetting();

        Account acc2 = ObjectCreator.getNewAccount();
        insert acc2;

        Contact teacherContact2 = ObjectCreator.getNewContact(acc2.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact2;

        User u2 = ObjectCreator.getNewUser(teacherContact2.Id);
        insert u2;

        Contact contact3 = ObjectCreator.getNewContact(acc2.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert contact3;

        User u3 = ObjectCreator.getNewUser(contact3.Id);
        insert u3;

        Account lc = ObjectCreator.getNewAccount();
        lc.Partner_Account_User__c = u2.Id;
        lc.Partner_Account_NC__c = u3.Id;
        insert lc;

        Contact teacherContact  = ObjectCreator.getNewContact(lc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact;

        User u = ObjectCreator.getNewUser(teacherContact.Id);
        insert u;

        Account acc = ObjectCreator.getNewAccount();        
        insert acc;

        acc2.Partner_Account_User__c = u.Id;
        update acc2;

        Agreement__c agree  = ObjectCreator.getNewAgreement(acc.Id);
        agree.From_Franchisee__c = lc.Id;
        agree.Direct_Franchisee__c = acc2.Id;          
        insert agree;        
        
        System.assert([SELECT Id FROM Agreement__Share WHERE ParentId = :agree.Id AND UserOrGroupId = :u.id].size() == 1);
        System.assert([SELECT Id FROM Agreement__Share WHERE ParentId = :agree.Id AND UserOrGroupId = :u2.id].size() == 1);
        System.assert([SELECT Id FROM Agreement__Share WHERE ParentId = :agree.Id AND UserOrGroupId = :u3.id].size() == 1);

    }

    @isTest(seeAllData=false)
    static void BaseCourse_CreateSharingRules_Test() {

        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        ObjectCreator.EnableSharingMethods();
        
        Agreement__c agree = new Agreement__c(Id = testEnv.agreeId);
        agree.Program_Type__c = 'HDE';
        update agree;

        User u2 = ObjectCreator.getNewUser(testEnv.teacherContactId);
        insert u2;    

        Base_Course__c baseCourse = new Base_Course__c(Name = 'test ' + String.valueOf(Math.random()) );
        baseCourse.Status__c = 'Active';
        baseCourse.Program_Type__c = 'HDE';

        insert baseCourse;              

        System.assert([SELECT Id FROM Base_Course__Share WHERE ParentId = :baseCourse.Id AND UserOrGroupId = :u2.id].size() == 1);

    }

    @isTest(seeAllData=false)
    static void baseCourseRemoveSharingRules_Test() {
        HD_TriggerSettings.disableAllTriggers = true;
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        ObjectCreator.EnableSharingMethods();
        
        Agreement__c agree = new Agreement__c(Id = testEnv.agreeId);
        agree.Program_Type__c = 'HDE';
        update agree;

        User u2 = ObjectCreator.getNewUser(testEnv.teacherContactId);
        insert u2;    
        HD_TriggerSettings.disableAllTriggers = false;
        Base_Course__c baseCourse = new Base_Course__c(Name = 'test ' + String.valueOf(Math.random()) );
        baseCourse.Status__c = 'Active';
        baseCourse.Program_Type__c = 'HDE';
        
        insert baseCourse;

        System.assert([SELECT Id FROM Base_Course__Share WHERE ParentId = :baseCourse.Id AND UserOrGroupId = :u2.id].size() == 1);
        
        baseCourse.Status__c = 'Non Active';
        update baseCourse;
        
        System.assert([SELECT Id FROM Base_Course__Share WHERE ParentId = :baseCourse.Id AND UserOrGroupId = :u2.id].size() == 0);

    }


    @isTest(seeAllData=false)
    static void Batch_RecentSharingRulesOnContact0_Test() {
        HD_TriggerSettings.disableAllTriggers = true;
        Map<String,Id> profiles = new Map<String,Id>();

        for(Profile profile : [SELECT Id, Name FROM Profile]){
            profiles.put(profile.Name, profile.Id);
        }

        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        ObjectCreator.EnableSharingMethods();
        
        
        Account partnerAcc = ObjectCreator.getNewAccount();
        insert partnerAcc;

        Contact partnerteacherContact   = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert partnerteacherContact;

        User u = ObjectCreator.getNewUser(partnerteacherContact.Id);
        u.ProfileId = profiles.get('HDC MF User');
        insert u;

        Account teacherAcc = new Account(Id = testEnv.accId);
        teacherAcc.Partner_Account_User__c = u.Id;
        update teacherAcc;
        
        User u2 = ObjectCreator.getNewUser(testEnv.teacherContactId);
        u2.ProfileId = profiles.get('HDC LC User');
        insert u2;

        Teacher_Agreement__c tAgree = new Teacher_Agreement__c();
        tAgree.Teacher__c = partnerteacherContact.Id;

        insert tAgree;
        
        insert new ContactShare(ContactId = partnerteacherContact.Id, UserOrGroupId = u2.Id, ContactAccessLevel = 'Read');


        Test.startTest();
            HD_TriggerSettings.disableAllTriggers = false;
            Batch_RecentSharingRulesOnContact b = new Batch_RecentSharingRulesOnContact();
            Database.executeBatch(b);

        Test.stopTest();

        System.debug(LoggingLevel.ERROR, [SELECT Id FROM ContactShare WHERE ContactId = :partnerteacherContact.Id AND UserOrGroupId = :u2.id]);             

        System.assert([SELECT Id FROM ContactShare WHERE ContactId = :partnerteacherContact.Id AND UserOrGroupId = :u2.id].size() == 1);
        System.assert([SELECT Id FROM Teacher_Agreement__Share WHERE ParentId = :tAgree.Id AND UserOrGroupId = :u2.id].size() == 1);
        
    }

    
    @isTest(seeAllData=false)
    static void Batch_RecentSharingRulesOnContact_Test() {

        //ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

        Account partnerAcc = ObjectCreator.getNewAccount();
        insert partnerAcc;

        Contact partnerteacherContact   = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert partnerteacherContact;

        User u = ObjectCreator.getNewUser(partnerteacherContact.Id);
        insert u;

        Account teacherAcc = ObjectCreator.getNewAccount();//new Account(Id = testEnv.accId);
        teacherAcc.Partner_Account_User__c = u.Id;
        insert teacherAcc;

        Contact teacherContact  = ObjectCreator.getNewContact(teacherAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact;

        User u2 = ObjectCreator.getNewUser(teacherContact.Id);
        insert u2;

        Contact contact;        
        
        System.runAs(u2){
            Account acc = ObjectCreator.getNewAccount();
            insert acc;

            contact = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
            insert contact;
        }

        System.assert([SELECT Id FROM ContactShare WHERE ContactId = :contact.Id AND UserOrGroupId = :u.id].size() > 0);

        Account partnerAcc2 = ObjectCreator.getNewAccount();
        insert partnerAcc2;

        Test.startTest();

            Holiday_Vacation__c holiday2 = ObjectCreator.getNewHolidayVacation(Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('LC').getRecordTypeId());
            holiday2.LC__c = partnerAcc2.Id;
            holiday2.Teacher__c = contact.Id;
            insert holiday2;

            Contact partnerteacherContact2  = ObjectCreator.getNewContact(partnerAcc2.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
            insert partnerteacherContact2;

            User u3 = ObjectCreator.getNewUser(partnerteacherContact2.Id);
            insert u3;

            Contact partnerteacherContactNC = ObjectCreator.getNewContact(partnerAcc2.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
            insert partnerteacherContactNC;

            User uNC = ObjectCreator.getNewUser(partnerteacherContactNC.Id);
            insert uNC;

            partnerAcc2.Partner_Account_User__c = u3.Id;
            partnerAcc2.Partner_Account_NC__c = uNC.Id;
            update partnerAcc2;

            Batch_RecentSharingRulesOnContact b = new Batch_RecentSharingRulesOnContact();
            Database.executeBatch(b);

        Test.stopTest();

        System.debug(LoggingLevel.ERROR, '*** : ' + [SELECT Id FROM ContactShare WHERE ContactId = :contact.Id AND UserOrGroupId = :u3.id]);                

        System.assert([SELECT Id FROM ContactShare WHERE ContactId = :contact.Id AND UserOrGroupId = :u3.id].size() == 1);
        System.assert([SELECT Id FROM ContactShare WHERE ContactId = :contact.Id AND UserOrGroupId = :uNC.id].size() == 1);
        
    }

    @isTest(seeAllData=false)
    static void Contact_CreateRelationshipSharingRules_Test() {
        HD_TriggerSettings.disableAllTriggers = true;
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        ObjectCreator.EnableSharingMethods();
        
        Account partnerAcc = ObjectCreator.getNewAccount();
        insert partnerAcc;

        Contact partnerteacherContact   = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert partnerteacherContact;

        User u2 = ObjectCreator.getNewUser(testEnv.teacherContactId);
        insert u2;

        Contact contact   = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert contact;

        User u3 = ObjectCreator.getNewUser(contact.Id);
        insert u3;

        Account teacherAcc = new Account(Id = testEnv.accId);
        teacherAcc.Partner_Account_User__c = u2.Id;
        update teacherAcc;
        
        HD_TriggerSettings.disableAllTriggers = false;
        
        insert new AccountContactRelation(ContactId = partnerteacherContact.Id, AccountId = teacherAcc.Id);

        System.assert([SELECT Id FROM ContactShare WHERE ContactId = :partnerteacherContact.Id AND UserOrGroupId = :u3.id].size() == 0);

        partnerteacherContact.OwnerId = u3.Id;
        update partnerteacherContact;    

        System.debug(LoggingLevel.ERROR, [SELECT Id FROM ContactShare WHERE ContactId = :partnerteacherContact.Id AND UserOrGroupId = :u2.id]);             
        System.assert([SELECT Id FROM ContactShare WHERE ContactId = :partnerteacherContact.Id AND UserOrGroupId = :u3.id].size() == 1);
        
    }

    @isTest(seeAllData=false)
    static void HDC_Order_CreateSharingRules_Test() {
        HD_TriggerSettings.disableAllTriggers = true;
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        ObjectCreator.EnableSharingMethods();
        
        Account partnerAcc = ObjectCreator.getNewAccount();
        insert partnerAcc;

        Contact partnerteacherContact   = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert partnerteacherContact;

        User u = ObjectCreator.getNewUser(partnerteacherContact.Id);
        insert u;

        partnerAcc.Partner_Account_User__c = u.Id;
        update partnerAcc;
        HD_TriggerSettings.disableAllTriggers = false;
        System.runAs(u){

            HD_Product__c hdProduct = ObjectCreator.getNewHDProduct();
            insert hdProduct;

            Set_Product__c setProduct = ObjectCreator.getNewSetProduct(hdProduct.Id);
            insert setProduct; 

            Price_List_Title__c priceListTitle = ObjectCreator.getNewPriceListTitle();
            priceListTitle.RecordTypeId = Schema.SObjectType.Price_List_Title__c.getRecordTypeInfosByName().get('HD').getRecordTypeId();
            priceListTitle.Start_Date__c = system.today().addDays(-1);
            insert priceListTitle;

            Product_Price__c productPrice = ObjectCreator.getNewProductPrice(priceListTitle.Id);
            productPrice.HD_Product__c = hdProduct.Id;
            insert productPrice;  

            FR_Order__c frOrder = ObjectCreator.getNewOrder(priceListTitle.Id, Schema.SObjectType.FR_Order__c.getRecordTypeInfosByName().get('MF Order after Submit').getRecordTypeId());
            insert frOrder;
        }
    }

    @isTest(seeAllData=false)
    static void Contact_CreateTeacherSharingRules_Test() {
        HD_TriggerSettings.disableAllTriggers = true;
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        ObjectCreator.EnableSharingMethods();
        
        Account partnerAcc = ObjectCreator.getNewAccount();
        partnerAcc.Partner_Account_User__c = userinfo.getUserId();
        insert partnerAcc;

        Contact partnerteacherContact = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());
        partnerteacherContact.TT_Qualified__c = 'TT';              
        insert partnerteacherContact;

        Contact ttcontact = ObjectCreator.getNewContact(testEnv.accId, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());
        ttcontact.TT_Qualified__c = 'TT';              
        insert ttcontact;

        User uTT = ObjectCreator.getNewUser(partnerteacherContact.Id);
        insert uTT;

        test.startTest();
            HD_TriggerSettings.disableAllTriggers = false;

            Account partnerAcc2 = ObjectCreator.getNewAccount();
            partnerAcc2.Partner_Account_User__c = uTT.Id;
            insert partnerAcc2;

            Contact ttcontact2 = ObjectCreator.getNewContact(partnerAcc2.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());
            ttcontact2.TT_Qualified__c = 'TT';              
            insert ttcontact2;

            User uTT2 = ObjectCreator.getNewUser(ttcontact2.Id);
            insert uTT2;

            Seminar_Type__c stype = ObjectCreator.getNewSeminarType();
            insert stype;


            Seminar__c seminar = new Seminar__c();      
            seminar.Hosting_Franchisee__c = partnerAcc.Id; 
            seminar.Teacher_Trainer__c = ttcontact.Id;
            seminar.TT_Status__c = 'Approved by TT';
            seminar.Status__c = 'Processing Application';
            seminar.Seminar_Type__c = stype.Id;
            insert seminar;

            Seminar_Teachers__c st = ObjectCreator.getNewSeminarTeacher(seminar.Id, partnerteacherContact.Id);
            st.Teacher_Status_in_seminar__c = 'Registered';
            insert st;


            partnerteacherContact.AccountId = partnerAcc2.Id;
            update partnerteacherContact;

        test.stopTest();

    }

    @isTest(seeAllData=false)
    static void Batch_RecentRelationshipOnContact_Test() {
        HD_TriggerSettings.disableAllTriggers = true;

        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        ObjectCreator.EnableSharingMethods();
        
        Account partnerAcc = ObjectCreator.getNewAccount();
        partnerAcc.Partner_Account_User__c = userinfo.getUserId();
        insert partnerAcc;

        Contact partnerteacherContact   = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert partnerteacherContact;

        User u2 = ObjectCreator.getNewUser(testEnv.teacherContactId);
        insert u2;

        Contact ttcontact = ObjectCreator.getNewContact(testEnv.accId, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());
        ttcontact.TT_Qualified__c = 'TT';              
        insert ttcontact;

        Test.startTest();
            HD_TriggerSettings.disableAllTriggers = false;
            
            Seminar_Type__c stype = ObjectCreator.getNewSeminarType();
            insert stype;

            Seminar__c seminar = new Seminar__c();      
            seminar.Hosting_Franchisee__c = partnerAcc.Id; 
            seminar.Teacher_Trainer__c = ttcontact.Id;
            seminar.TT_Status__c = 'Approved by TT';
            seminar.Status__c = 'Processing Application';
            seminar.Seminar_Type__c = stype.Id;
            insert seminar;

            Seminar_Teachers__c st = ObjectCreator.getNewSeminarTeacher(seminar.Id, partnerteacherContact.Id);
            st.Teacher_Status_in_seminar__c = 'Registered';
            insert st;

            Teacher_Agreement__c tAgree = new Teacher_Agreement__c();
            tAgree.Teacher__c = partnerteacherContact.Id;
            insert tAgree;

            Account teacherAcc = new Account(Id = testEnv.accId);
            teacherAcc.Partner_Account_User__c = u2.Id;
            update teacherAcc;
            
            insert new AccountContactRelation(ContactId = partnerteacherContact.Id, AccountId = teacherAcc.Id);

            Batch_RecentRelationshipOnContact b = new Batch_RecentRelationshipOnContact();
            Database.executeBatch(b);

        Test.stopTest();

        System.debug(LoggingLevel.ERROR, [SELECT Id FROM ContactShare WHERE ContactId = :partnerteacherContact.Id AND UserOrGroupId = :u2.id]);             
        System.assert([SELECT Id FROM ContactShare WHERE ContactId = :partnerteacherContact.Id AND UserOrGroupId = :u2.id].size() == 1);
        
    }

    @isTest(seeAllData=false)
    static void SeminarType_CreateSharingRules_Test() {
        HD_TriggerSettings.disableAllTriggers = true;
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        ObjectCreator.EnableSharingMethods();
        
        Account partnerAcc = ObjectCreator.getNewAccount();
        insert partnerAcc;

        Contact partnerteacherContact   = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert partnerteacherContact;

        User u = ObjectCreator.getNewUser(partnerteacherContact.Id);
        insert u;

        test.startTest();
            HD_TriggerSettings.disableAllTriggers = false;
            Contact seminarContact  = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());
            seminarContact.TT_Qualified__c= 'TT';           
            seminarContact.Program_Type__c= 'HDE';  
            insert seminarContact;

            User u3 = ObjectCreator.getNewUser(seminarContact.Id);
            insert u3;

            seminarContact.Contact_Partner_User__c = u3.Id;      
            update seminarContact;

            Account teacherAcc = new Account(Id = testEnv.accId);
            teacherAcc.Partner_Account_User__c = u3.Id;
            update teacherAcc;    

            Agreement__c agree = new Agreement__c(Id = testEnv.agreeId);
            agree.Program_Type__c = 'HDE';
            agree.From_Franchisee__c = partnerAcc.Id;
            update agree;
            
            Seminar_Type__c seminarType = new Seminar_Type__c(Name = 'test ' + String.valueOf(Math.random()) );
            seminarType.Active__c = false;
            seminarType.Program_Type__c = 'HDE';
            insert seminarType;  

            seminarType.Active__c = true;
            update seminarType;         

        test.stopTest();
    }

    @isTest(seeAllData=false)
    static void PriceListTitleSharingRules_Test() {
        HD_TriggerSettings.disableAllTriggers = true;
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        ObjectCreator.EnableSharingMethods();
        
        Account partnerAcc = ObjectCreator.getNewAccount();
        insert partnerAcc;

        Contact partnerteacherContact   = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert partnerteacherContact;
        HD_TriggerSettings.disableAllTriggers = false;
        User u = ObjectCreator.getNewUser(partnerteacherContact.Id);
        insert u;
        
        partnerAcc.Partner_Account_User__c = u.Id;
        update partnerAcc;
        
        test.startTest();
        //System.runAs(u){
            Account acc1 = ObjectCreator.getNewAccount();
            insert acc1;
            
            Account acc2 = ObjectCreator.getNewAccount();
            acc2.Partner_Account_User__c = u.Id;
            acc2.ParentId = acc1.Id;
            insert acc2;
    
            Price_List_Title__c priceListTitle = ObjectCreator.getNewPriceListTitle();
            priceListTitle.RecordTypeId = Schema.SObjectType.Price_List_Title__c.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();
            insert priceListTitle;

            Agreement__c agree  = ObjectCreator.getNewAgreement(acc2.Id);             
            agree.Program_Type__c = 'HDE';
            agree.Price_List_Title__c = priceListTitle.Id;
            agree.From_Franchisee__c = partnerAcc.Id;                
            insert agree;

        //}
        test.stopTest();
    }

    @isTest(seeAllData=false)
    static void Seminar_TypesCreateSharingRules_Test() {
        HD_TriggerSettings.disableAllTriggers = true;
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        ObjectCreator.EnableSharingMethods();
        
        Account partnerAcc = ObjectCreator.getNewAccount();
        insert partnerAcc;

        Contact partnerteacherContact   = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert partnerteacherContact;

        User u = ObjectCreator.getNewUser(partnerteacherContact.Id);
        insert u;

        Contact partnerteacherContactNC = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert partnerteacherContactNC;

        User uNC = ObjectCreator.getNewUser(partnerteacherContactNC.Id);
        insert uNC;

        test.startTest();        
            HD_TriggerSettings.disableAllTriggers = false;
            partnerAcc.Partner_Account_NC__c = uNC.Id;
            update partnerAcc;

            Contact seminarContact  = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());
            seminarContact.TT_Qualified__c= 'TT';           
            insert seminarContact;

            User u3 = ObjectCreator.getNewUser(seminarContact.Id);
            insert u3;

            Account teacherAcc = new Account(Id = testEnv.accId);
            teacherAcc.Partner_Account_User__c = u3.Id;
            update teacherAcc;    

            Agreement__c agree = new Agreement__c(Id = testEnv.agreeId);
            agree.Program_Type__c = 'HDE';
            update agree;


            User u2 = ObjectCreator.getNewUser(testEnv.teacherContactId);
            insert u2;
            
            Seminar_Type__c seminarType = new Seminar_Type__c(Name = 'test ' + String.valueOf(Math.random()) );
            seminarType.Active__c = true;
            seminarType.Program_Type__c = 'HDE';

            System.runAs(uNC){           
                insert seminarType;
            }

            Seminar__c seminar = new Seminar__c();      
            seminar.Seminar_Type__c = seminarType.Id;
            
            seminarContact.ownerId = u2.Id;
            update seminarContact;

            seminar.Teacher_Trainer__c = seminarContact.Id;
            insert seminar;            

            seminar.Status__c = 'Confirmed';
            seminar.TT_Status__c = 'Approved by TT';
            seminar.TTC_Seminar_Name__c = 'Test';
            seminar.Start_Date__c = system.today();
            seminar.End_Date__c = system.today().addDays(1);
            seminar.Venue_City__c = 'Test';
            seminar.OwnerId = u2.Id;
            try{
            update seminar;
            }catch(exception e){}

            System.debug(LoggingLevel.ERROR, '*** : ' + [SELECT Id FROM Seminar__Share]);

        //System.assert([SELECT Id FROM Seminar__Share WHERE ParentId = :seminar.Id AND UserOrGroupId = :u3.id].size() > 0);
        //System.assert([SELECT Id FROM Seminar__Share WHERE ParentId = :seminar.Id AND UserOrGroupId = :uNC.id].size() > 0);
        
        test.stopTest();
    }

    @isTest(seeAllData=false)
    static void Account_HandleNcChange_Test2() {

        ObjectCreator.initializeCustomSetting();
        Id mcTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();
        Id lcsetlsfTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId();

        Account acc1 = ObjectCreator.getNewAccount();
        insert acc1;

        Contact teacherContact1 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact1;

        User u1 = ObjectCreator.getNewUser(teacherContact1.Id);
        insert u1;

        Contact teacherContact2 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact2;

        User u2 = ObjectCreator.getNewUser(teacherContact2.Id);
        insert u2;

        Contact teacherContact3 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact3;

        User u3 = ObjectCreator.getNewUser(teacherContact3.Id);
        insert u3;

        Test.startTest();

            Account acc2 = ObjectCreator.getNewAccount();
            acc2.RecordTypeId = mcTypeId;
            acc2.Partner_Account_NC__c = u1.Id;
            acc2.Partner_Account_User__c = u3.Id;
            insert acc2;

            Account lcAcc = ObjectCreator.getNewAccount();
            lcAcc.RecordTypeId = lcsetlsfTypeId;
            lcAcc.ParentId = acc2.Id;
            insert lcAcc;

            Contact lcAccContact = ObjectCreator.getNewContact(lcAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
            insert lcAccContact;

            User lcu = ObjectCreator.getNewUser(lcAccContact.Id);
            insert lcu;

            lcAcc.Partner_Account_User__c = lcu.Id;
            update lcAcc;
        
            Lead lcl = new Lead(FirstName = 'ignoretesttree', LastName = 'ignoretestfour', Company = 'testCompany');

            Opportunity lcopp = new Opportunity();
            lcopp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId();
            lcopp.AccountId = lcAcc.Id;
            lcopp.Name = 'test opp two';
            lcopp.StageName = 'Prospecting';
            lcopp.CloseDate = System.today();
            lcopp.CurrencyIsoCode = UserInfo.getDefaultCurrency();

            System.runAs(lcu){           
                insert lcl;
                insert lcopp;
            }

            Opportunity opp = new Opportunity();
            opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId();
            opp.AccountId = acc2.Id;
            opp.Name = 'test opp';
            opp.StageName = 'Prospecting';
            opp.CloseDate = System.today();
            opp.CurrencyIsoCode = UserInfo.getDefaultCurrency();
            
            System.runAs(u3){           
                insert opp; 
            }

            acc2.Partner_Account_NC__c =  u2.Id;
            update acc2;
        
        Test.stopTest();

    }

    @isTest(seeAllData=false)
    static void Account_HandleManagerChange_Test3() {

        ObjectCreator.initializeCustomSetting();
        Id mcTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();
        Id lcsetlsfTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId();

        Account acc1 = ObjectCreator.getNewAccount();
        insert acc1;

        Contact teacherContact1 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        teacherContact1.TT_Qualified__c = 'TT';             
        insert teacherContact1;

        User u1 = ObjectCreator.getNewUser(teacherContact1.Id);
        insert u1;

        Contact teacherContact2 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact2;

        User u2 = ObjectCreator.getNewUser(teacherContact2.Id);
        insert u2;

        Contact teacherContact3 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact3;

        User u3 = ObjectCreator.getNewUser(teacherContact3.Id);
        insert u3;

        Test.startTest();

            Account acc2 = ObjectCreator.getNewAccount();
            acc2.RecordTypeId = mcTypeId;
            acc2.Partner_Account_Manager__c = u1.Id;
            acc2.Partner_Account_User__c = u3.Id;
            insert acc2;

            Holiday_Vacation__c holiday = ObjectCreator.getNewHolidayVacation(Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('Country').getRecordTypeId());
            holiday.Country__c = 'Angola';

            Price_List_Title__c priceListTitle = ObjectCreator.getNewPriceListTitle();
            priceListTitle.RecordTypeId = Schema.SObjectType.Price_List_Title__c.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();

            Agreement__c agree  = ObjectCreator.getNewAgreement(acc2.Id);             
            agree.Program_Type__c = 'HDE';              
            insert agree;

            System.runAs(u3){ 
                insert holiday; 
                insert priceListTitle;         
            }

            Seminar_Type__c seminarType = new Seminar_Type__c(Name = 'test ' + String.valueOf(Math.random()) );
            seminarType.Active__c = true;
            seminarType.Program_Type__c = 'HDE';
            insert seminarType;

            Seminar__c seminar = new Seminar__c();      
            seminar.Hosting_Franchisee__c = acc1.Id; 
            seminar.Teacher_Trainer__c = teacherContact1.Id;
            seminar.TT_Status__c = 'Approved by TT';
            seminar.Status__c = 'Confirmed';
            insert seminar;

            Base_Course__c baseCurse = ObjectCreator.getNewBaseCourse();                
            seminarType.Program_Type__c = 'HDE';
            insert baseCurse;

            Course_Sub_Type__c curseSubType = ObjectCreator.getNewCourseSubType(acc2.Id, baseCurse.Id);              
            insert curseSubType;
            
            acc2.Partner_Account_Manager__c =  u2.Id;
            update acc2;
        
        Test.stopTest();
    }

    @isTest(seeAllData=false)
    static void Account_HandleManagerChange_Test2() {

        ObjectCreator.initializeCustomSetting();
        Id mcTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();
        Id lcsetlsfTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId();

        Account acc1 = ObjectCreator.getNewAccount();
        insert acc1;

        Contact teacherContact1 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact1;

        User u1 = ObjectCreator.getNewUser(teacherContact1.Id);
        insert u1;

        Contact teacherContact2 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact2;

        User u2 = ObjectCreator.getNewUser(teacherContact2.Id);
        insert u2;

        Contact teacherContact3 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact3;

        User u3 = ObjectCreator.getNewUser(teacherContact3.Id);
        insert u3;

        Test.startTest();

            Account acc2 = ObjectCreator.getNewAccount();
            acc2.RecordTypeId = mcTypeId;
            acc2.Partner_Account_Manager__c = u1.Id;
            acc2.Partner_Account_User__c = u3.Id;
            acc2.BillingCountry = 'Spain';
            acc2.Account_Type__c = 'MF';
            insert acc2;

            Account lcAcc = ObjectCreator.getNewAccount();
            lcAcc.RecordTypeId = lcsetlsfTypeId;
            lcAcc.ParentId = acc2.Id;
            insert lcAcc;

            Contact lcAccContact = ObjectCreator.getNewContact(lcAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
            insert lcAccContact;

            User lcu = ObjectCreator.getNewUser(lcAccContact.Id);
            insert lcu;

            lcAcc.Partner_Account_User__c = lcu.Id;
            update lcAcc;
        
            Lead lcl = new Lead(FirstName = 'ignoretesttree', LastName = 'ignoretestfour', Company = 'testCompany');

            Opportunity lcopp = new Opportunity();
            lcopp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId();
            lcopp.AccountId = lcAcc.Id;
            lcopp.Name = 'test opp two';
            lcopp.StageName = 'Prospecting';
            lcopp.CloseDate = System.today();
            lcopp.CurrencyIsoCode = UserInfo.getDefaultCurrency();

            Holiday_Vacation__c holidayChild = ObjectCreator.getNewHolidayVacation(Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('Country').getRecordTypeId());
            holidayChild.Country__c = 'Spain';

            System.runAs(lcu){           
                insert lcl;
                insert lcopp;
                insert holidayChild;
            }

            Holiday_Vacation__c holiday = ObjectCreator.getNewHolidayVacation(Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('Country').getRecordTypeId());
            holiday.Country__c = 'Spain';

            System.runAs(u3){           
                insert holiday;
            }
            
            acc2.Partner_Account_Manager__c =  u2.Id;
            update acc2;
        
        Test.stopTest();
    }

    @isTest(seeAllData=false)
    static void Account_HandleManagerChange_Test4() {

        ObjectCreator.initializeCustomSetting();
        Id mcTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();
        Id lcsetlsfTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId();

        Account acc1 = ObjectCreator.getNewAccount();
        insert acc1;

        Contact teacherContact1 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact1;

        User u1 = ObjectCreator.getNewUser(teacherContact1.Id);
        insert u1;

        Contact teacherContact2 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact2;

        User u2 = ObjectCreator.getNewUser(teacherContact2.Id);
        insert u2;

        Contact teacherContact3 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact3;

        User u3 = ObjectCreator.getNewUser(teacherContact3.Id);
        insert u3;

        Test.startTest();

            Account acc2 = ObjectCreator.getNewAccount();
            acc2.RecordTypeId = mcTypeId;
            acc2.Partner_Account_User__c = u3.Id;
            acc2.BillingCountry = 'Spain';
            acc2.Account_Type__c = 'MF';
            insert acc2;

            Account lcAcc = ObjectCreator.getNewAccount();
            lcAcc.RecordTypeId = lcsetlsfTypeId;
            lcAcc.ParentId = acc2.Id;
            insert lcAcc;

            Contact lcAccContact = ObjectCreator.getNewContact(lcAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
            insert lcAccContact;

            User lcu = ObjectCreator.getNewUser(lcAccContact.Id);
            insert lcu;

            lcAcc.Partner_Account_User__c = lcu.Id;
            lcAcc.Partner_Account_Manager__c = u1.Id;
            update lcAcc;
        
            Holiday_Vacation__c holiday = ObjectCreator.getNewHolidayVacation(Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('Country').getRecordTypeId());
            holiday.Country__c = 'Spain';

            System.runAs(lcu){           
                insert holiday;
            }

            Holiday_Vacation__c holidayMF = ObjectCreator.getNewHolidayVacation(Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('Country').getRecordTypeId());
            holidayMF.Country__c = 'Spain';

            System.runAs(u3){           
                insert holidayMF;
            }
            
            lcAcc.Partner_Account_Manager__c =  u2.Id;
            update lcAcc;
        
        Test.stopTest();
    }

    
    @isTest(seeAllData=false)
    static void AccContactRelation_CreateSharingRules_Test() {
        ObjectCreator.DisableSharingMethods();
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

        Account partnerAcc = ObjectCreator.getNewAccount();
        insert partnerAcc;

        Contact partnerteacherContact   = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert partnerteacherContact;

        User u2 = ObjectCreator.getNewUser(testEnv.teacherContactId);
        insert u2;

        test.startTest();

        Contact ttcontact = ObjectCreator.getNewContact(testEnv.accId, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());
        ttcontact.TT_Qualified__c = 'TT';              
        insert ttcontact;
        
        Teacher_Agreement__c tAgree = new Teacher_Agreement__c();
        tAgree.Teacher__c = partnerteacherContact.Id;
        tAgree.Agreement_Status__c = 'Approved';
        insert tAgree;

        Account teacherAcc = new Account(Id = testEnv.accId);
        teacherAcc.Partner_Account_User__c = u2.Id;
        update teacherAcc;
        
        ObjectCreator.EnableSharingMethods();
        
        insert new AccountContactRelation(ContactId = partnerteacherContact.Id, AccountId = teacherAcc.Id);
        
        System.debug(LoggingLevel.ERROR, [SELECT Id FROM ContactShare WHERE ContactId = :partnerteacherContact.Id AND UserOrGroupId = :u2.id]);             
        System.assert([SELECT Id FROM ContactShare WHERE ContactId = :partnerteacherContact.Id AND UserOrGroupId = :u2.id].size() == 1);
        
        test.stopTest();
        
    }

    @isTest(seeAllData=false)
    static void Account_HandleManagerChange_Test() {

        ObjectCreator.initializeCustomSetting();
        ObjectCreator.DisableSharingMethods();
        HD_TriggerSettings.disableTriggersFromTest.remove('HandleNcOrManagerChange');

        Id mcTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();
        Id lcsetlsfTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId();

        Account acc1 = ObjectCreator.getNewAccount();
        insert acc1;

        Contact teacherContact1 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact1;

        User u1 = ObjectCreator.getNewUser(teacherContact1.Id);
        insert u1;

        Contact teacherContact2 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact2;

        User u2 = ObjectCreator.getNewUser(teacherContact2.Id);
        insert u2;

        Contact teacherContact3 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact3;

        User u3 = ObjectCreator.getNewUser(teacherContact3.Id);
        insert u3;

        Account acc2 = ObjectCreator.getNewAccount();
        acc2.RecordTypeId = mcTypeId;
        acc2.Partner_Account_Manager__c = u1.Id;
        acc2.Partner_Account_User__c = u3.Id;
        acc2.BillingCountry = 'Spain';
        acc2.Account_Type__c = 'MF';
        insert acc2;

        Account childAcc = ObjectCreator.getNewAccount();
        childAcc.ParentId = acc2.Id;
        insert childAcc;

        Agreement__c agree  = ObjectCreator.getNewAgreement(acc2.Id);             
        insert agree;

        Agreement__c childAgree  = ObjectCreator.getNewAgreement(childAcc.Id);             
        insert childAgree;

        Test.startTest();

        Contact accContact = ObjectCreator.getNewContact(acc2.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert accContact;


            ObjectCreator.DisableSharingMethods();
            HD_TriggerSettings.disableTriggersFromTest.remove('HandleNcOrManagerChange');

            Contact childContact = ObjectCreator.getNewContact(childAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
            insert childContact;

            insert new AccountContactRelation(ContactId = teacherContact2.Id, AccountId = acc2.Id);

            Base_Course__c baseCurse = ObjectCreator.getNewBaseCourse();                
            insert baseCurse;
            
            Course_Sub_Type__c curseSubType = ObjectCreator.getNewCourseSubType(acc2.Id, baseCurse.Id);              
            insert curseSubType;

            LG__c lg            = ObjectCreator.getNewLG(acc1.Id, curseSubType.Id, agree.Id);
            lg.Franchisee__c    = acc2.Id;    
            lg.Teacher__c       = accContact.Id;
            insert lg; 

        
            LG__c childlg            = ObjectCreator.getNewLG(acc2.Id, curseSubType.Id, childAgree.Id);
            childlg.Franchisee__c    = childAcc.Id;    
            childlg.Teacher__c       = childContact.Id;
            insert childlg; 

            Price_List_Title__c priceListTitle = ObjectCreator.getNewPriceListTitle();
            priceListTitle.RecordTypeId = Schema.SObjectType.Price_List_Title__c.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();
            insert priceListTitle;

            Price_List_Title_Assignment__c priceListTitleAssignment = new Price_List_Title_Assignment__c();
            priceListTitleAssignment.Franchise__c = acc2.Id;
            priceListTitleAssignment.Price_List_Title__c = priceListTitle.Id;
            insert priceListTitleAssignment;

            insert new Price_List_Title__Share(ParentId = priceListTitle.Id, AccessLevel = 'Edit', UserOrGroupId = u1.Id );

            FR_Order__c frOrder;
            System.runAs(u1){

                frOrder = ObjectCreator.getNewOrder(priceListTitle.Id, Schema.SObjectType.FR_Order__c.getRecordTypeInfosByName().get('MF Order after Submit').getRecordTypeId());
                insert frOrder;

            }
            
            frOrder.Ordered_From__c = acc2.Id;
            update frOrder;

            Lead l = new Lead(FirstName = 'ignoretestone', LastName = 'ignoretesttwo', Company = 'testCompany');
            
            Opportunity opp = new Opportunity();
            opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId();
            opp.AccountId = acc2.Id;
            opp.Name = 'test opp';
            opp.StageName = 'Prospecting';
            opp.CloseDate = System.today();
            opp.CurrencyIsoCode = UserInfo.getDefaultCurrency();

            System.runAs(u3){           
                insert l;
                insert opp; 
            }
            
            acc2.Partner_Account_Manager__c =  u2.Id;
            update acc2;

            Map<Id,Id> accManagerIds = new Map<Id,Id>();
            accManagerIds.put(acc2.Id,u2.Id);

            List<LG__Share> lg2sh = new List<LG__Share>();
            lg2sh.add(new LG__Share(ParentId = lg.Id, UserOrGroupId = u2.Id, AccessLevel = 'Edit'));

            Batch_InsertShareRecords b = new Batch_InsertShareRecords();
            b.newSharingRecords = lg2sh;
            b.objType = 'LG__Share';
            Database.executeBatch(b,100);

            Map<Id,Id> accChilds = new Map<Id,Id>();
            accChilds.put(childAcc.Id, acc2.Id);

            Batch_CreateManagerContactSharing ba = new Batch_CreateManagerContactSharing();
            ba.accManagerIds = accManagerIds;
            ba.accChilds = accChilds;
            Database.executeBatch(ba,1);
        
        Test.stopTest();
    }

    @isTest(seeAllData=false)
    static void SeminarTeachersSharingRules(){
        HD_TriggerSettings.disableAllTriggers = true;
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        ObjectCreator.EnableSharingMethods();
        
        Contact ttcontact = ObjectCreator.getNewContact(testEnv.accId, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());
        ttcontact.TT_Qualified__c = 'TT';            
        insert ttcontact;

        User u = ObjectCreator.getNewUser(testEnv.teacherContactId);
        insert u;
        System.debug(System.LoggingLevel.ERROR, 'u');
        System.debug(System.LoggingLevel.ERROR, [SELECT Name FROM User WHERE Id = :u.Id]);

        User u2 = ObjectCreator.getNewUser(testEnv.staffContactId);
        insert u2;
        System.debug(System.LoggingLevel.ERROR, 'u2');
        System.debug(System.LoggingLevel.ERROR, [SELECT Name FROM User WHERE Id = :u2.Id]);

        User u3 = ObjectCreator.getNewUser(ttcontact.Id);
        u3.ProfileId = [SELECT Id FROM Profile WHERE Name = 'HDC LC User' LIMIT 1].Id;
        u3.MF_ID__c = testEnv.lcId;
        insert u3;
        System.debug(System.LoggingLevel.ERROR, 'u3');
        System.debug(System.LoggingLevel.ERROR, [SELECT Name FROM User WHERE Id = :u3.Id]);

        Account acc = new Account(Id = testEnv.accId);
        acc.Account_Type__c = 'LSF';
        acc.Partner_Account_User__c = u2.Id;
        update acc;
        
        test.startTest();
            HD_TriggerSettings.disableAllTriggers = false;
            Seminar_Type__c seminarType = ObjectCreator.getNewSeminarType();
            insert seminarType;
            
            //insert new Seminar_Type__Share(ParentId = seminarType.Id, UserOrGroupId = u3.Id, AccessLevel = 'Read');
            
            Seminar__c seminar = ObjectCreator.getNewSeminar();
            seminar.Seminar_Type__c = seminarType.Id;
            seminar.Hosting_Franchisee__c = testEnv.lcId;
            seminar.OwnerId = u.Id;

            seminar.Teacher_Trainer__c = ttcontact.Id;
            seminar.Status__c = 'Processing Application';
            insert seminar;

            Seminar_Teachers__c st = ObjectCreator.getNewSeminarTeacher(seminar.Id, testEnv.teacherContactId);
            st.Teacher__c = testEnv.teacherContactId;
            insert st;

            seminar.TT_Status__c = 'Approved by TT';
            update seminar;

            st.OwnerId = UserInfo.getUserId();
            update st;

            seminar.Status__c = 'Confirmed';
            update seminar;

            st.OwnerId = u.Id;
            update st;

        test.stopTest();

        System.debug([SELECT Name, Seminar_Number__c FROM Seminar_Teachers__c WHERE Id = :st.Id]);
    }

    @isTest(seeAllData=false)
    static void Seminar_TeacherTrainersDeleteSharingRules_Test() {

        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        HD_TriggerSettings.disableTriggersFromTest.remove('seminarCreateSharingRules');
        
        Account partnerAcc = ObjectCreator.getNewAccount();
        insert partnerAcc;

        Contact partnerteacherContact   = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert partnerteacherContact;

        User u = ObjectCreator.getNewUser(partnerteacherContact.Id);
        insert u;
        
        partnerAcc.Partner_Account_NC__c = u.Id;
        update partnerAcc;

        Test.startTest();

        Contact seminarContact = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId()); 
        seminarContact.TT_Qualified__c = 'TT';             
        insert seminarContact;

        Contact seminarContact2 = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId()); 
        seminarContact2.TT_Qualified__c = 'TT';             
        insert seminarContact2;

            HD_TriggerSettings.disableAllTriggers = false;
            User u3 = ObjectCreator.getNewUser(seminarContact.Id);
            insert u3;

            User u4 = ObjectCreator.getNewUser(seminarContact2.Id);
            insert u4;

            partnerAcc.Partner_Account_User__c = u4.Id;
            update partnerAcc;

            Seminar_Type__c seminarType = new Seminar_Type__c(Name = 'test ' + String.valueOf(Math.random()) );
            seminarType.Active__c = true;
            seminarType.Program_Type__c = 'HDE';

            insert seminarType;

            Seminar__c seminar = new Seminar__c();      
            seminar.Seminar_Type__c = seminarType.Id;
            seminar.Teacher_Trainer__c = seminarContact.Id;
            seminar.Hosting_Franchisee__c = partnerAcc.Id;
            insert seminar;

            Seminar__Share sShare = new Seminar__Share(ParentId = seminar.Id, UserOrGroupId = u3.Id, AccessLevel = 'Edit');
            insert sShare;
            //System.assert([SELECT Id FROM Seminar__Share WHERE ParentId = :seminar.Id AND UserOrGroupId = :u3.id].size() == 1);

            seminar.Teacher_Trainer__c = seminarContact2.Id;
            seminar.TT_Status__c = 'Rejected by TT';
            seminar.Status__c = 'Processing Application';
            update seminar;

            //System.assert([SELECT Id FROM Seminar__Share WHERE ParentId = :seminar.Id AND UserOrGroupId = :u3.id].size() == 0);
            System.assert([SELECT Id, AccessLevel FROM Seminar__Share WHERE Id = :sShare.Id].AccessLevel == 'Read');

        Test.stopTest();

    }


    @isTest(seeAllData=false)
    static void Account_HandleNcChange_Test() {
        
        ObjectCreator.initializeCustomSetting();
        Id mcTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();
        ObjectCreator.DisableSharingMethods();
        HD_TriggerSettings.disableTriggersFromTest.remove( 'HandleNcOrManagerChange' );

        Account acc1 = ObjectCreator.getNewAccount();
        insert acc1;

        Contact teacherContact1 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact1;

        User u1 = ObjectCreator.getNewUser(teacherContact1.Id);
        insert u1;

        Contact teacherContact2 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact2;

        User u2 = ObjectCreator.getNewUser(teacherContact2.Id);
        insert u2;

        Contact teacherContact3 = ObjectCreator.getNewContact(acc1.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert teacherContact3;

        User u3 = ObjectCreator.getNewUser(teacherContact3.Id);
        insert u3;

            Account acc2 = ObjectCreator.getNewAccount();
            acc2.RecordTypeId = mcTypeId;
            acc2.Partner_Account_NC__c = u1.Id;
            acc2.Partner_Account_User__c = u3.Id;
            insert acc2;

            Account childAcc = ObjectCreator.getNewAccount();
            childAcc.ParentId = acc2.Id;
            insert childAcc;
            
            HD_TriggerSettings.disableAllTriggers = false;
            Agreement__c agree  = ObjectCreator.getNewAgreement(acc2.Id);             
            insert agree;

            Agreement__c childAgree  = ObjectCreator.getNewAgreement(childAcc.Id);             
            insert childAgree;

            Contact accContact = ObjectCreator.getNewContact(acc2.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
            insert accContact;

            Contact childContact = ObjectCreator.getNewContact(childAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
            insert childContact;

        Test.startTest();

            Base_Course__c baseCurse = ObjectCreator.getNewBaseCourse();                
            insert baseCurse;

            Course_Sub_Type__c curseSubType = ObjectCreator.getNewCourseSubType(acc2.Id, baseCurse.Id);              
            insert curseSubType;

            LG__c lg            = ObjectCreator.getNewLG(acc1.Id, curseSubType.Id, agree.Id);
            lg.Franchisee__c    = acc2.Id;    
            lg.Teacher__c       = accContact.Id;
            insert lg; 

            LG__c childlg            = ObjectCreator.getNewLG(acc2.Id, curseSubType.Id, childAgree.Id);
            childlg.Franchisee__c    = childAcc.Id;    
            childlg.Teacher__c       = childContact.Id;
            insert childlg;  

            Seminar_Type__c seminarType = new Seminar_Type__c(Name = 'test ' + String.valueOf(Math.random()) );
            seminarType.Active__c = true;
            seminarType.Program_Type__c = 'HDE';
            insert seminarType;

            Seminar__c seminar = new Seminar__c();      
            seminar.Seminar_Type__c = seminarType.Id;
            insert seminar;


            Price_List_Title__c priceListTitle = ObjectCreator.getNewPriceListTitle();
            priceListTitle.RecordTypeId = Schema.SObjectType.Price_List_Title__c.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();
            insert priceListTitle;

            Price_List_Title_Assignment__c priceListTitleAssignment = new Price_List_Title_Assignment__c();
            priceListTitleAssignment.Franchise__c = acc2.Id;
            priceListTitleAssignment.Price_List_Title__c = priceListTitle.Id;
            insert priceListTitleAssignment;

            insert new Price_List_Title__Share(ParentId = priceListTitle.Id, AccessLevel = 'Edit', UserOrGroupId = u1.Id );

            FR_Order__c frOrder;
            System.runAs(u1){

                frOrder = ObjectCreator.getNewOrder(priceListTitle.Id, Schema.SObjectType.FR_Order__c.getRecordTypeInfosByName().get('MF Order after Submit').getRecordTypeId());
                insert frOrder;

            }
            
            frOrder.Ordered_From__c = acc2.Id;
            update frOrder;

            Lead l = new Lead(FirstName = 'ignoretestone', LastName = 'ignoretesttwo', Company = 'testCompany');
            System.runAs(u3){           
                insert l;
            }
            
            System.debug(LoggingLevel.ERROR, '*** acc2.Partner_Account_NC__c: ' + acc2.Partner_Account_NC__c);

            acc2.Partner_Account_NC__c =  u2.Id;
            update acc2;
        
        Test.stopTest();
    }

}