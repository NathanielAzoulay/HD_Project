/******************************************************************************* 
Name              : Holiday_Vacation_TriggerHandler
Description       :
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G.Fernandez              25/04/2016         	Yaara Nadir 			SW-19138
*******************************************************************************/

trigger AdditionalHolidays_TriggerHandler on Franchisee_Additional_Holidays__c(after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	AdditionalHolidays_TriggerHandler.executeTriggerHandler(); 
}