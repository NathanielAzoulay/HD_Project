/******************************************************************************* 
Name              : TeacherAgreement_TriggerHandler
Description       : Handler the before/after trigger on Teacher_Qualification__c
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez				14/04/2016              
*******************************************************************************/

trigger TeacherAgreement_TriggerHandler on Teacher_Agreement__c(after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    TeacherAgreement_TriggerHandler.executeTriggerHandler();
}