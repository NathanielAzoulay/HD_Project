/******************************************************************************* 
Name              : Franchisee_VAT_TriggerHandler
Description       : Handler the before/after trigger on Holiday & Vacation
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G.Fernandez             21/03/2016              
*******************************************************************************/

trigger Franchisee_VAT_TriggerHandler on Franchisee_VAT__c(after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	Franchisee_VAT_TriggerHandler.executeTriggerHandler();
}