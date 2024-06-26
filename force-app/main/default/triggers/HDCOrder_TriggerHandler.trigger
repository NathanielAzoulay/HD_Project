/******************************************************************************* 
Name              : HDCOrder_TriggerHandler
Description       : Handler the before/after trigger on FR_Order__c
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez         	05/27/2016
*******************************************************************************/
trigger HDCOrder_TriggerHandler on FR_Order__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

	HDCOrder_TriggerHandler.executeTriggerHandler();
	
}