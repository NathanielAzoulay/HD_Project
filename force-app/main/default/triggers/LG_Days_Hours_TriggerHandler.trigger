/******************************************************************************* 
Name              : LG_Days_Hours_TriggerHandler
Description       : Handler the before/after trigger on LG Days Hour
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio                   11/03/2016              
*******************************************************************************/
trigger LG_Days_Hours_TriggerHandler on LG_Days_Hours__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    LG_Days_Hours_TriggerHandler.executeTriggerHandler();
}