/******************************************************************************* 
Name              : TeacherAgreement_TriggerHandler
Description       : Handler the Trigger on Teacher_Agreement__c
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez  		06/22/2016          	
*******************************************************************************/

public class TeacherAgreement_TriggerHandler {
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
		
		
		if (Trigger.isAfter && Trigger.isInsert) // After Insert
		{
			teacherAgreement_CreateSharingRules();
		}
		
		else if (Trigger.isAfter && Trigger.isUpdate) // After Update
		{
			teacherAgreement_CreateSharingRules();			
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
	Name              : teacherAgreement_CreateSharingRules
	Description       : Handler the sharing record of Teacher_Agreement__c object
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez         	06/22/2016          	Yaara				  [SW-20019]
	*******************************************************************************/
	
	public static void teacherAgreement_CreateSharingRules(){
		if( HD_TriggerSettings.IsTriggerActive('teacherAgreement_CreateSharingRules') ){
			List<Teacher_Agreement__c> tAgreements = new List<Teacher_Agreement__c>();
			for(Integer i=0; i < trigger.size; i++ ){
				Teacher_Agreement__c t = (Teacher_Agreement__c)trigger.new[i];
				if(t.Teacher__c != null && (trigger.isInsert || (((Teacher_Agreement__c)trigger.old[i]).OwnerId <> t.OwnerId || ((Teacher_Agreement__c)trigger.old[i]).Teacher__c <> t.Teacher__c)) ){
					tAgreements.add(t);
				}
			}
			
			if(!tAgreements.isEmpty()){
				HD_SharingMethods.teacherAgreement_CreateSharingRules(tAgreements);
			}
		}
	}
}