/******************************************************************************* 
Name              : Contact_TriggerHandler
Description       : Handler the before/after trigger on Contact
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez             05/27/2016
2. Rashad Saeed             22/1/2017
*******************************************************************************/
trigger Contact_TriggerHandler on Contact (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

    Contact_TriggerHandler.executeTriggerHandler();
    
    /* Added by Rashad Saeed  */
    if (trigger.isbefore && trigger.isupdate)
      RSContactHistory.Handler(trigger.newMap,trigger.oldmap);
    /* Added by Rashad Saeed  */
}