/******************************************************************************* 
Name              : Account_TriggerHandler
Description       : Handler the before/after trigger on Account
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez 	 		07/07/2016          	
*******************************************************************************/

trigger Price_List_Title_Assignment_TriggerHandler on Price_List_Title_Assignment__c(after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	PriceListTitleAssignment_TriggerHandler.executeTriggerHandler();
}