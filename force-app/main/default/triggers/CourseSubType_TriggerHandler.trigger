/******************************************************************************* 
Name              : CourseSubType_TriggerHandler
Description       : Handler the before/after trigger on Course_Sub_Type__c
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez         	05/13/2016
2. Rashad Saeed             20-30-2018   Implement the new permission module
*******************************************************************************/
trigger CourseSubType_TriggerHandler on Course_Sub_Type__c (after insert,after update,Before Delete) {

	//CourseSubType_TriggerHandler.executeTriggerHandler();
    If (trigger.IsAfter&& !trigger.isDelete){
        // Grant Access to  Franchisee Group.
     	RSSHARING.RSHelper.RecalcGroup(JSON.serialize(trigger.newMap),JSON.serialize(trigger.OldMap),'Franchisee_Name__c' ,'Franchisee__c');
    }
   
	
}