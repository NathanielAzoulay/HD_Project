/******************************************************************************* 
Name              : ContentVersion_TriggerHandler
Description       : Handler the before/after trigger on ContentVersion
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio Caputo	  		12/08/2016          	
*******************************************************************************/
trigger ContentVersion_TriggerHandler on ContentVersion (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	ContentVersion_TriggerHandler.executeTriggerHandler();
}