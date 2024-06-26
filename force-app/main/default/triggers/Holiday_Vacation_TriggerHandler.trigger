/******************************************************************************* 
Name              : Holiday_Vacation_TriggerHandler
Description       : Handler the before/after trigger on Holiday & Vacation
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G.Fernandez                   18/03/2016              
*******************************************************************************/

trigger Holiday_Vacation_TriggerHandler on Holiday_Vacation__c(after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    Holiday_Vacation_TriggerHandler.executeTriggerHandler();
}