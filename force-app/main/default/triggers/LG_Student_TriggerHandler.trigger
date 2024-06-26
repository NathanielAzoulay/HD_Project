/******************************************************************************* 
Name              : LG_Student_TriggerHandler
Description       : Handler the before/after trigger on LG Student
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan           02/25/2016              
*******************************************************************************/
trigger LG_Student_TriggerHandler on LG_Student__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

    LG_Student_TriggerHandler.executeTriggerHandler();
}