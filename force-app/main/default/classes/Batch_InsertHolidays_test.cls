/******************************************************************************* 
Name              : Batch_AgreementUpdateDates
Description       : change the due date on active Agreements once a year
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan	             01/23/2017          	Yaara Nadir               [SW-23290]
*******************************************************************************/
@isTest
private class Batch_InsertHolidays_test {

    @isTest(seeAllData=false)
	static void doInsertHolidayVacationFromBatch() {
		Account franchiseAcc = ObjectCreator.getNewAccount();
		insert franchiseAcc;

		Holiday_Vacation__c holiday = ObjectCreator.getNewHolidayVacation(Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('LC').getRecordTypeId());
		holiday.Country__c = 'Spain';
		Batch_InsertHolidays batch = new Batch_InsertHolidays();
	    batch.holidays2Insert = new List<Holiday_Vacation__c>{holiday};
        Database.executeBatch(batch,1);			
    }
}