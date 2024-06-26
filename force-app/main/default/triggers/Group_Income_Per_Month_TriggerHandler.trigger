/******************************************************************************* 
Name              : Group_Income_Per_Month_TriggerHandler
Description       : Handler the before/after trigger on Group_Income_Per_Month
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio Caputo            08/03/2016              
*******************************************************************************/
trigger Group_Income_Per_Month_TriggerHandler on Group_Income_Per_Month__c (after delete, before insert, before update) {
    Group_Income_Per_Month_TriggerHandler.executeTriggerHandler();
    /*
    if (Trigger.IsBefore && !Trigger.IsDelete){
        for (Group_Income_Per_Month__c GIPM : Trigger.new)
        {
            Integer numberOfDaysInStartMonth = Date.daysInMonth(GIPM.Royalty_Start_Date__c.year(), GIPM.Royalty_Start_Date__c.month());
            Integer numberOfDaysInEndMonth = Date.daysInMonth(GIPM.Royalty_End_Date__c.year(), GIPM.Royalty_End_Date__c.month());
        }
    }
    */
}