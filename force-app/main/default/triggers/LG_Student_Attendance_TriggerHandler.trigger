/******************************************************************************* 
Name              : LG_Student_Attendance_TriggerHandler
Description       : Handler the before/after trigger on LG Student Attendance
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan                   03/01/2016              
*******************************************************************************/
trigger LG_Student_Attendance_TriggerHandler on LG_Student_Attendance__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

    LG_Student_Attendance_TriggerHandler.executeTriggerHandler();
}