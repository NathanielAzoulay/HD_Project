@isTest
public class DeduplicateContactTest {

    @isTest
    static void testUniteContactNo() {

        RecordType franchiseRecordType = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Contact' AND Name = 'Franchisee' LIMIT 1];
        
        Account acc = new Account(
            Name = 'test',
            BillingCountry = 'France'
        );
        insert acc;

        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@test.com',
            Phone = '1234567890',
            MobilePhone = '9876543210',
            RecordTypeId = franchiseRecordType.Id,
            AccountId = acc.Id
        );
        insert testContact;
        ApexPages.CurrentPage().getParameters().put('id',testContact.Id);
        DeduplicateContact dedupContact = new DeduplicateContact(new ApexPages.StandardController(testContact));

        dedupContact.selectedButtonValue = 'YES';
        dedupContact.selectedContactId = null;
        Test.startTest();
        dedupContact.uniteContact();
        Test.stopTest();
        System.assertEquals('No changes have been performed', dedupContact.updatedStatusMsg);
    }

    @isTest
    static void testUniteContactYes() {

        Account acc = new Account(
            Name = 'test',
            BillingCountry = 'France'
        );
        insert acc;

        RecordType franchiseRecordType = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Contact' AND Name = 'Franchisee' LIMIT 1];
        Contact contact1 = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe1@test.com',
            Phone = '1234567890',
            MobilePhone = '9876543210',
            RecordTypeId = franchiseRecordType.Id, 
            AccountId = acc.Id
        );
        insert contact1;

        Contact contact2 = new Contact(
            FirstName = 'Jane',
            LastName = 'Doe',
            Email = 'john.doe1@test.com',
            Phone = '1111111111',
            MobilePhone = '9999999999',
            RecordTypeId = franchiseRecordType.Id,
            AccountId = acc.Id
        );
        insert contact2;
        ApexPages.CurrentPage().getParameters().put('id',contact1.Id);
        DeduplicateContact dedupContact = new DeduplicateContact(new ApexPages.StandardController(contact1));

        dedupContact.selectedButtonValue = 'YES';
        dedupContact.selectedContactId = contact2.Id;

        Test.startTest();
        dedupContact.uniteContact();
        Test.stopTest();

        System.assertEquals('Your changes have been saved successfully', dedupContact.updatedStatusMsg);
    }
}