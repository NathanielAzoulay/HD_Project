/******************************************************************************* 
Name              : LG_Lesson_TriggerHandler
Description       : Handler the before/after trigger on LG Lesson
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan Sinclair			03/17/2016          	
*******************************************************************************/
trigger LG_Lesson_TriggerHandler on LG_Lesson__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

	LG_Lesson_TriggerHandler.executeTriggerHandler();
	
}