/******************************************************************************* 
Name              : FR_Order_Product_TriggerHandler
Description       : 
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio	     			15/12/2016           
*******************************************************************************/

trigger FR_Order_Product_TriggerHandler on FR_Order_Product__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	FR_Order_Product_TriggerHandler.executeTriggerHandler();
}