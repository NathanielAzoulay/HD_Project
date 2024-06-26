@isTest(seeAllData = false)
public with sharing class SubscribeControllerTest{

    /*static testmethod void unitTestLeadfromBoth() {
        Campaign c = new Campaign(Name='Test');
        insert c;
        Lead testLead = new Lead(FirstName = 'TestContactF', LastName = 'TestContactL', Email = 'none@navinet.net',Company = 'test company');
        insert testLead;
        CampaignMember newMember1 = new CampaignMember(CampaignId = c.Id, LeadId = testLead.Id);
        insert newMember1;
        //for unsubscribe contact from all LGs and marketing
        ApexPages.currentPage().getParameters().put('Id', testLead.Id);
        UnsubscribeController mecObj = new UnsubscribeController();
        mecObj.unsubscribeMarketing = true;
        mecObj.unsubscribeLG = true;
        mecObj.submit();
        list<Lead> leads = [select Marketing_opt_out__c from Lead where Id =: testLead.Id];
        system.assertEquals(true, leads[0].Marketing_opt_out__c);
        mecObj = new UnsubscribeController();
    }
    static testmethod void unitTestLeadfromMarketing() {
        Campaign c = new Campaign(Name='Test');
        insert c;
        Lead testLead = new Lead(FirstName = 'TestContactF', LastName = 'TestContactL', Email = 'none@navinet.net',Company = 'test company');
        insert testLead;
        CampaignMember newMember1 = new CampaignMember(CampaignId = c.Id, LeadId = testLead.Id);
        insert newMember1;
        //for unsubscribe lead from all Marketing
        ApexPages.currentPage().getParameters().put('Id', testLead.Id);
        UnsubscribeController mecObj = new UnsubscribeController();
        mecObj.unsubscribeMarketing = true;
        mecObj.submit();
        list<Lead> leads = [select Marketing_opt_out__c from Lead where Id =: testLead.Id];
        system.assertEquals(true, leads[0].Marketing_opt_out__c);
    }*/
    
    static testmethod void unitTestContactfromBoth() {
        
        Campaign c = new Campaign(Name='Test');
        insert c;
        Account acc = new Account(Name = 'test account', BillingCountry = 'France');
        insert acc;
        Contact testContact = new Contact(AccountId = acc.Id, FirstName = 'TestContactF', LastName = 'TestContactL', Email = 'none@navinet.net');
        insert testContact;
        
        CampaignMember newMember = new CampaignMember(CampaignId = c.Id, ContactId = testContact.Id);
        insert newMember;
        
        //for unsubscribe contact from all LGs and Marketing
        ApexPages.currentPage().getParameters().put('Id', testContact.Id);
        SubscribeController mecObj = new SubscribeController();
        mecObj.subscribeLG = true;
        mecObj.subscribeMarketing = true;        
        mecObj.submit();
        
        list<Contact> contacts = [select Marketing_opt_out__c, LGS_opt_out__c from Contact where Id =: testContact.Id];
        //system.assertEquals(true, contacts[0].Marketing_opt_out__c);
        //system.assertEquals(true, contacts[0].LGS_opt_out__c);
        mecObj = new SubscribeController();
    }
    static testmethod void unitTestContactfromMarketing() {
        
        Campaign c = new Campaign(Name='Test');
        insert c;
        Account acc = new Account(Name = 'test account', BillingCountry = 'France');
        insert acc;
        Contact testContact = new Contact(AccountId = acc.Id, FirstName = 'TestContactF', LastName = 'TestContactL', Email = 'none@navinet.net');
        insert testContact;
        
        CampaignMember newMember = new CampaignMember(CampaignId = c.Id, ContactId = testContact.Id);
        insert newMember;
        
        //for unsubscribe contact from all Marketing
        ApexPages.currentPage().getParameters().put('Id', testContact.Id);
        SubscribeController mecObj = new SubscribeController();
        mecObj.subscribeMarketing = true;
        
        mecObj.submit();
        list<Contact> contacts = [select Marketing_opt_out__c, LGS_opt_out__c from Contact where Id =: testContact.Id];
        //system.assertEquals(true, contacts[0].Marketing_opt_out__c);
        //system.assertEquals(false, contacts[0].LGS_opt_out__c);
    }
    static testmethod void unitTestContactfromLG() {
        
        Campaign c = new Campaign(Name='Test');
        insert c;
        Account acc = new Account(Name = 'test account', BillingCountry = 'France');
        insert acc;
        Contact testContact = new Contact(AccountId = acc.Id, FirstName = 'TestContactF', LastName = 'TestContactL', Email = 'none@navinet.net');
        insert testContact;
        
        CampaignMember newMember = new CampaignMember(CampaignId = c.Id, ContactId = testContact.Id);
        insert newMember;
        
        //for unsubscribe contact from all LGs
        ApexPages.currentPage().getParameters().put('Id', testContact.Id);
        SubscribeController mecObj = new SubscribeController();
        mecObj.subscribeLG = true;
        mecObj.submit();
        list<Contact> contacts = [select Marketing_opt_out__c, LGS_opt_out__c from Contact where Id =: testContact.Id];
        //system.assertEquals(true, contacts[0].Marketing_opt_out__c);
        //system.assertEquals(true, contacts[0].LGS_opt_out__c);
        //to cover for No record selected to unsubscribe.
        ApexPages.currentPage().getParameters().put('Id', newMember.Id);
        mecObj = new SubscribeController();
    }
}