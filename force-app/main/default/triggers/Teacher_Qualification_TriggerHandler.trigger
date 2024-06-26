/******************************************************************************* 
Name              : Teacher_Qualification_TriggerHandler
Description       : Handler the before/after trigger on Teacher_Qualification__c
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez				14/04/2016              
*******************************************************************************/

trigger Teacher_Qualification_TriggerHandler on Teacher_Qualification__c(after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    Teacher_Qualification_TriggerHandler.executeTriggerHandler();
}