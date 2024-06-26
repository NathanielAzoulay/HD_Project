/******************************************************************************* 
Name              : Price_List_Title_TriggerHandler
Description       : Handler the trigger on Price List Title
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G.Fernandez              11/04/2016              
*******************************************************************************/

trigger Price_List_Title_TriggerHandler on Price_List_Title__c(after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	Price_List_Title_TriggerHandler.executeTriggerHandler();
}