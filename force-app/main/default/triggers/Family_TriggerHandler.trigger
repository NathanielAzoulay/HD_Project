/******************************************************************************* 
Name              : Family_TriggerHandler
Description       : Handler the before/after trigger on Family__c
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez         	05/13/2016
*******************************************************************************/
trigger Family_TriggerHandler on Family__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

	Family_TriggerHandler.executeTriggerHandler();
	
}