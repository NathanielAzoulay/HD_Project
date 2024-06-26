/******************************************************************************* 
Name              : Document_TriggerHandler
Description       : Handler the before/after trigger on Document__c
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio	         	01/12/2016
*******************************************************************************/
trigger Document_TriggerHandler on Document__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	Document_TriggerHandler.executeTriggerHandler();
}