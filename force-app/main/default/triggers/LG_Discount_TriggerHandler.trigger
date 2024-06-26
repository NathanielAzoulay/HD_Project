/******************************************************************************* 
Name              : LG_Discount_TriggerHandler
Description       : Handler the before/after trigger on LG Discount
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Nicolas                   03/07/2016              
*******************************************************************************/
trigger LG_Discount_TriggerHandler on LG_Discount__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	
	 LG_Discount_TriggerHandler.executeTriggerHandler();
}