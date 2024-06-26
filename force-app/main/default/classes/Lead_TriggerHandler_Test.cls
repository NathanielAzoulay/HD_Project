@isTest
private class Lead_TriggerHandler_Test {
   
	@isTest ( seeAllData = false )
	static void convertTeacherLead_Test() {
		ObjectCreator.initializeCustomSetting();
		
        
        Account partnerAcc = ObjectCreator.getNewAccount();
        partnerAcc.BillingCountry = 'France';
        partnerAcc.Account_Type__c = 'MF';
        insert partnerAcc;

        Contact partnerteacherContact   = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId());              
        insert partnerteacherContact;

        User u = ObjectCreator.getNewUser(partnerteacherContact.Id);
        insert u;

        partnerAcc.Partner_Account_User__c = u.Id;
        update partnerAcc;
		
        System.runAs(u){
            Lead l2convert 	= new Lead(FirstName = 'Lead convert', LastName = 'ONETEST');
            l2convert.Company = 'Test Company Two';
            l2convert.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Teacher').getRecordTypeId(); 
            //l2convert.Status = 'Qualified';   
            l2convert.Lead_Type__c = 'Teacher';    
            l2convert.Account_Type__c = 'MF';   
            l2convert.Country__c = 'France';   
            insert l2convert;
            
            l2convert.Status = 'Qualified'; 
            l2convert.Country__c = 'France'; 
            update l2convert;
        }
    }
    
    @isTest(seeAllData=false)
	static void convertQualifiedLead_Test() {
		ObjectCreator.initializeCustomSetting();

        Account acc = ObjectCreator.getNewAccount();
        acc.Name = 'Test Company ONE';
        acc.BillingCountry = 'France';
        insert acc;

        Lead l2convert 	= new Lead(FirstName = 'Lead convert', LastName = 'ONETEST');
        l2convert.Company = 'Test Company ONE';
        l2convert.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Student').getRecordTypeId(); 
        l2convert.Status = 'Qualified';   
        l2convert.Lead_Type__c = 'Student';    
        l2convert.Account_Type__c = 'NC';   
        l2convert.Country__c = 'France';      
    	insert l2convert;

    	System.assert([SELECT Id FROM Contact WHERE AccountId = :acc.Id].size() == 1);

    	System.assert([SELECT Id FROM Opportunity LIMIT 1].size() == 0);
    }

    @isTest(seeAllData=false)
    static void lead_withCampaignLink_Test() {
        ObjectCreator.initializeCustomSetting();

        Account partnerAcc = ObjectCreator.getNewAccount();
        partnerAcc.BillingCountry = 'France';
        insert partnerAcc;

        Contact partnerteacherContact   = ObjectCreator.getNewContact(partnerAcc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert partnerteacherContact;

        User u = ObjectCreator.getNewUser(partnerteacherContact.Id);
        insert u;

        partnerAcc.Partner_Account_User__c = u.Id;
        update partnerAcc;

        Campaign camp = ObjectCreator.getNewCampaign();
        System.runAs(u){
            insert camp;
        }

        System.debug('Campaign owner ' + [SELECT OwnerId FROM Campaign WHERE Id = :camp.Id LIMIT 1]);        

        Lead newLead  = new Lead(FirstName = 'Lead Test', LastName = 'TWOTEST'); 
        newLead.Company = 'Test Company'; 
        newLead.Country__c = 'France';          
        insert newLead; 

        CampaignMember cm = new CampaignMember(CampaignId = camp.Id, LeadId = newLead.Id);
        insert cm;

        camp = [SELECT OwnerId FROM Campaign WHERE Id = :camp.Id LIMIT 1];
        newLead = [SELECT OwnerId FROM Lead WHERE Id = :newLead.Id LIMIT 1];

        System.assert(camp.OwnerId == newLead.OwnerId);
    }
}