/******************************************************************************* 
Name              : Campaign_TriggerHandler
Description       : Handler the before/after trigger on Opportunity
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez  		05/11/2016          	
*******************************************************************************/
trigger Campaign_TriggerHandler on Campaign (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

	Campaign_TriggerHandler.executeTriggerHandler();
	
}