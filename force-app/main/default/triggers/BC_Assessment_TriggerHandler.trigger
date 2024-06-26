/******************************************************************************* 
Name              : BC_Assessment_TriggerHandler
Description       : 
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G.Fernandez     			12/07/2016           
*******************************************************************************/

trigger BC_Assessment_TriggerHandler on BC_Assessment__c(after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	BC_Assessment_TriggerHandler.executeTriggerHandler();
}