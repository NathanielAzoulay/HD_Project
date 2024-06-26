/******************************************************************************* 
Name              : Opportunity_TriggerHandler
Description       : Handler the before/after trigger on Opportunity
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan Sinclair  		05/11/2016          	
*******************************************************************************/
trigger Opportunity_TriggerHandler on Opportunity (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

	Opportunity_TriggerHandler.executeTriggerHandler();
}