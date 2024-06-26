/******************************************************************************* 
Name              : Account_TriggerHandler
Description       : Handler the before/after trigger on Account
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan Sinclair  		05/11/2016          	
*******************************************************************************/
trigger Account_TriggerHandler on Account (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

	Account_TriggerHandler.executeTriggerHandler();
}