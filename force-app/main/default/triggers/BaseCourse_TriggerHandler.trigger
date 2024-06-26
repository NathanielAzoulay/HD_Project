/******************************************************************************* 
Name              : BaseCourse_TriggerHandler
Description       : Handler the before/after trigger on Base Course
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez         	05/27/2016
*******************************************************************************/

trigger BaseCourse_TriggerHandler on Base_Course__c(after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    BaseCourse_TriggerHandler.executeTriggerHandler();
}