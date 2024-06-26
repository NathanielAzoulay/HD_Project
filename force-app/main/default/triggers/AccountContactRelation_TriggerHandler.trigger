/******************************************************************************* 
Name              : AccountContactRelation_TriggerHandler
Description       : Handler the before/after trigger on AccountContactRelation
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez			02/21/2017          	
*******************************************************************************/
trigger AccountContactRelation_TriggerHandler on AccountContactRelation (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

	AccountContactRelation_TriggerHandler.executeTriggerHandler();
	
}