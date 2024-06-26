/******************************************************************************* 
Name              : LG_Agreement_TriggerHandler
Description       : 
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G.Fernandez     			07/04/2016           
*******************************************************************************/

trigger LG_Agreement_TriggerHandler on Agreement__c(after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	LG_Agreement_TriggerHandler.executeTriggerHandler();
}