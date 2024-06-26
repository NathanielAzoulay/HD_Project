/******************************************************************************* 
Name              : LG_Student_Attendance_TriggerHandler
Description       : Handler the before/after trigger on LG Student Attendance
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan         			03/01/2016          	
*******************************************************************************/
public class LG_Student_Attendance_TriggerHandler {
	
	public static void executeTriggerHandler(){
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		
		/*
		if (Trigger.isBefore && Trigger.isInsert) // Before Update
		{
			
		}
		else if (Trigger.isBefore && Trigger.isUpdate) // Before Insert
		{
			
		}
		
		else if (Trigger.isBefore && Trigger.isDelete) // Before Delete
		{
		}
		*/
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		
		/*
		//else 
		if (Trigger.isAfter && Trigger.isUpdate) // After Update
		{
		}
		
		else if (Trigger.isAfter && Trigger.isInsert) // After Insert
		{
		}
		else 
		*/
		
		if (Trigger.isAfter && Trigger.isDelete){ // After Delete
		
			updateRelatedPayments();
		}
		/*
		else if (Trigger.isAfter && Trigger.isUnDelete) // After UnDelete
		{
			
		}
		
		*/		
	}
	
	/******************************************************************************* 
	Description       : Populate fields before duplicatecheck
						1) Need to recalculate the LG Payment.Planned Price - without the deleted LG Student Attendance (When LG Student Attendance is deleted & LG Student Attendance.LP Payment is not null)
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Hernan Sinclair       10/21/2016            	  Yaara          		 [SW-21843]
	*******************************************************************************/
	public static void updateRelatedPayments(){
		
		Set<Id> relatedLessonIds = new Set<Id>();
		for(Integer i=0; i < trigger.size; i++ ){
			
			LG_Student_Attendance__c r = (LG_Student_Attendance__c)trigger.old[i];
			
			if(r.LG_Payment__c <> null){
				relatedLessonIds.add(r.LG_Lesson__c);
			}
		}
		
		Map<Id, LG_Lesson__c> lgLesson2RecalculateLGPayments = new Map<Id, LG_Lesson__c>();
		for(Id lsId : relatedLessonIds){
			lgLesson2RecalculateLGPayments.put(lsId, new LG_Lesson__c(Id = lsId));
		}
		
		if(!lgLesson2RecalculateLGPayments.isEmpty()){
			LG_Lesson_TriggerHandler.lgLessonsThatNeedReCalculationLGPayments.addAll(lgLesson2RecalculateLGPayments.keySet());
			update lgLesson2RecalculateLGPayments.values(); // execute reCalculateLGPaymentsToLGLesson
		}
	}
}