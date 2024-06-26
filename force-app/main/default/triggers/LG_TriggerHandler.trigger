/******************************************************************************* 
Name              : LG_TriggerHandler
Description       : Handler the before/after trigger on LG
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan Sinclair          03/11/2016              
*******************************************************************************/
trigger LG_TriggerHandler on LG__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

    LG_TriggerHandler.executeTriggerHandler();
    
}