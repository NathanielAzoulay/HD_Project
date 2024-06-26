@isTest
private class AdditionalHolidays_TriggerHandler_Test {
    
    @isTest(seeAllData=false)
	static void duplicateHolidayVacation() {
		Account franchiseAcc = ObjectCreator.getNewAccount();
		insert franchiseAcc;
		franchiseAcc.RecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();
        update franchiseAcc;
        
        Holiday_Vacation__c holiday = ObjectCreator.getNewHolidayVacation(Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('LC').getRecordTypeId());
		holiday.Country__c = 'Spain';
		insert holiday;

		System.assertEquals(1, [SELECT Id FROM Holiday_Vacation__c WHERE Country__c = 'Spain'].size());

		Franchisee_Additional_Holidays__c additionalHoliday = ObjectCreator.getNewAdditionalHoliday(franchiseAcc.Id);
		insert additionalHoliday;
		
		System.assertEquals(1, [SELECT Id FROM Holiday_Vacation__c WHERE Country__c = 'Spain'].size());
		System.assertEquals(1, [SELECT Id FROM Holiday_Vacation__c WHERE Country__c = null].size());
		
        holiday = [SELECT Id FROM Holiday_Vacation__c WHERE Country__c = null AND Franchisee_Additional_Holiday__c = :additionalHoliday.Id LIMIT 1][0];
        holiday.Country__c = 'Spain';
        update holiday;
        
		Franchisee_Additional_Holidays__c additionalHoliday2 = ObjectCreator.getNewAdditionalHoliday(franchiseAcc.Id);
		insert additionalHoliday2;

		System.assertEquals(2, [SELECT Id FROM Holiday_Vacation__c WHERE Country__c = 'Spain'].size());
		System.assertEquals(0, [SELECT Id FROM Holiday_Vacation__c WHERE Country__c = null].size());
        //Fix Task-000001930 no more RecordType = LC . Changed on 2017 -> 'LC/SET/LSF'
        //franchiseAcc.RecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('LC').getRecordTypeId();
        franchiseAcc.RecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId();
        update franchiseAcc;
        
		Franchisee_Additional_Holidays__c additionalHoliday3 = ObjectCreator.getNewAdditionalHoliday(franchiseAcc.Id);
		insert additionalHoliday3;

    }

    @isTest(seeAllData=false)
	static void deleteHolidayVacation() {
        Account franchiseAcc = ObjectCreator.getNewAccount();
		insert franchiseAcc;

        Holiday_Vacation__c holiday = ObjectCreator.getNewHolidayVacation(Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('LC').getRecordTypeId());
		holiday.Country__c = 'Spain';
		insert holiday;

		System.assert(1 == [SELECT Id FROM Holiday_Vacation__c WHERE Country__c = 'Spain'].size());

		Franchisee_Additional_Holidays__c additionalHoliday = ObjectCreator.getNewAdditionalHoliday(franchiseAcc.Id);
		insert additionalHoliday;

		System.assert(1 == [SELECT Id FROM Holiday_Vacation__c WHERE Country__c = null].size());

		delete additionalHoliday;

		System.assert(0 == [SELECT Id FROM Holiday_Vacation__c WHERE Country__c = null].size());
    }
}