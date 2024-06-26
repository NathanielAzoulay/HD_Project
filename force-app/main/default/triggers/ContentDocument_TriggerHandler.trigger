/******************************************************************************* 
Name              : ContentDocument_TriggerHandler
Description       : Handler the before/after trigger on Content Document
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio Caputo	  		09/11/2016          	
*******************************************************************************/
trigger ContentDocument_TriggerHandler on ContentDocument (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	ContentDocument_TriggerHandler.executeTriggerHandler();
}