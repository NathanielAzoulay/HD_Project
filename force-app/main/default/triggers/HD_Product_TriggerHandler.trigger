/******************************************************************************* 
Name              : HD_Product_TriggerHandler
Description       : Handler the before/after trigger on HD_Product__c
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez         	06/18/2017
*******************************************************************************/

trigger HD_Product_TriggerHandler on HD_Product__c(after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	HD_Product_TriggerHandler.executeTriggerHandler();
}