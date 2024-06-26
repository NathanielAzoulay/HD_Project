/******************************************************************************* 
Name              : Seminar_Teachers_TriggerHandler
Description       : Handler the before/after trigger on Seminar Teachers
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan         			02/25/2016          	
*******************************************************************************/
public class Seminar_Teachers_TriggerHandler {
	
	public static void executeTriggerHandler(){
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		
		if (Trigger.isBefore && Trigger.isInsert) 
		{
			populateSeminarTeachersFielsOnBefore();
		}
		else if (Trigger.isBefore && Trigger.isUpdate) 
		{
			populateSeminarTeachersFielsOnBefore();
		}
		/*
		else if (Trigger.isBefore && Trigger.isDelete) // Before Delete
		{
		}
		*/
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		
		/*
		//else 
		*/
		if (Trigger.isAfter && Trigger.isUpdate) // After Update
		{
			SeminarTeachersSharingRules();
		}
		
		else if (Trigger.isAfter && Trigger.isInsert) // After Insert
		{			
			SeminarTeachersSharingRules();
		}
		/*else if (Trigger.isAfter && Trigger.isDelete) // After Delete
		{
			
		}
		else if (Trigger.isAfter && Trigger.isUnDelete) // After UnDelete
		{
			
		}
		*/		
	}

	/******************************************************************************* 
	Name              : SeminarTeachersSharingRules
	Description       : 
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez         19/12/2016              Ella  Bernachik         [SW-22725]
    2. G. Fernandez         02/03/2017              Dafna Margalit      	[SW-23909]
	*******************************************************************************/
	public static void SeminarTeachersSharingRules(){
		if( HD_TriggerSettings.IsTriggerActive('SeminarTeachersSharingRules') ){
		
			List<Seminar_Teachers__c> seminarsShareByHosting = new List<Seminar_Teachers__c>();
			List<Seminar_Teachers__c> seminarsShareByTeacher = new List<Seminar_Teachers__c>();
			List<Seminar_Teachers__c> shareByTeacher = new List<Seminar_Teachers__c>();
			for( Integer i=0; i < trigger.size; i++ ){
				Seminar_Teachers__c r = (Seminar_Teachers__c)trigger.new[i];

				Boolean cond = trigger.isUpdate && r.OwnerId != ((Seminar_Teachers__c) trigger.old[i]).OwnerId;
				cond |= trigger.isInsert;
				if(cond){
					seminarsShareByHosting.add(r);
				}

				cond = trigger.isUpdate && r.OwnerId != ((Seminar_Teachers__c)trigger.old[i]).OwnerId;
				cond |= trigger.isUpdate && r.Teacher_Status_in_seminar__c != ((Seminar_Teachers__c)trigger.old[i]).Teacher_Status_in_seminar__c;
				cond |= trigger.isInsert;
				cond &=	r.Teacher_Status_in_seminar__c == 'Registered';
				if(cond){
					seminarsShareByTeacher.add(r);
				}

				cond = trigger.isUpdate && r.OwnerId != ((Seminar_Teachers__c)trigger.old[i]).OwnerId;
				cond |= trigger.isInsert;
				if(cond){
					shareByTeacher.add(r);
				}
			}

			if(!seminarsShareByHosting.isEmpty()){
				HD_SharingMethods.SeminarTeachersSharingRules(seminarsShareByHosting);
			}
			if(!seminarsShareByTeacher.isEmpty()){
				HD_SharingMethods.SeminarTeachersSharingRules2(seminarsShareByTeacher);
			}	
			if(!shareByTeacher.isEmpty()){
				HD_SharingMethods.SeminarTeachersSharingRules4(shareByTeacher);
				HD_SharingMethods.SeminarTeachersSharingRules3(shareByTeacher);
			}
		}	
	}
	
	
	/******************************************************************************* 
	Name              : SeminarTeacher_PopulateBefore
	Description       : Populate fields before duplicatecheck
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez         10/02/2016          Ella  Bernachik           [SW-17367]
	*******************************************************************************/
	public static void populateSeminarTeachersFielsOnBefore(){
		if( HD_TriggerSettings.IsTriggerActive('populateSeminarTeachersFielsOnBefore') ){
		
			Map<Id,List<Integer>> seminarIds = new Map<Id,List<Integer>>();
			for( Integer i=0; i < trigger.size; i++ ){
				Seminar_Teachers__c r = (Seminar_Teachers__c)trigger.new[i];
				if(!seminarIds.containsKey(r.Seminar__c))
					seminarIds.put(r.Seminar__c, new List<Integer>());
		
				seminarIds.get(r.Seminar__c).add(i);
			}
		
			for(Seminar__c seminar : [SELECT Id, Name FROM Seminar__c WHERE Id IN :seminarIds.keySet()]){
				for(Integer seminarTeacherIndex : seminarIds.get(seminar.Id)){
					Seminar_Teachers__c r = (Seminar_Teachers__c)trigger.new[seminarTeacherIndex];
					r.Seminar_Number__c = seminar.Name;
				}		
			}	

		}	
	}

}