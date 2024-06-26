/******************************************************************************* 
Name              : LG_Payment_TriggerHandler
Description       : Handler the before/after trigger on LG Payment
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Nicolas          02/29/2016              
*******************************************************************************/
trigger LG_Payment_TriggerHandler on LG_Payment__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

    LG_Payment_TriggerHandler.executeTriggerHandler(); 
}