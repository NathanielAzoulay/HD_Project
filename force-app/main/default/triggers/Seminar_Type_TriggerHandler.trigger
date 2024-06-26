/******************************************************************************* 
Name              : Seminar_Type_TriggerHandler
Description       : Handler the before/after trigger on Seminar Teachers
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez              06/21/2016          
*******************************************************************************/
trigger Seminar_Type_TriggerHandler on Seminar_Type__c(after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    Seminar_Type_TriggerHandler.executeTriggerHandler();    
}