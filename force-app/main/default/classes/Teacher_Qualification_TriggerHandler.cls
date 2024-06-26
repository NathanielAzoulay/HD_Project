/******************************************************************************* 
Name              : Teacher_Qualification_TriggerHandler
Description       : Handler the Trigger on Teacher_Qualification__c
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez  		14/04/2016          	
*******************************************************************************/

public class Teacher_Qualification_TriggerHandler {
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
			Teacher_Qualification_checkTeacherQualifications();
		}
		
		else if (Trigger.isAfter && Trigger.isUpdate) // After Update
		{
			Teacher_Qualification_checkTeacherQualifications();
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
	Description       : Check for LG teachers qualifications and update the flag in LG.Teacher_is_not_Qualified_for_Base_Course__c
						
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez	         13/04/2016          	 Yaara          		 [SW-18850]
	1. G. Fernandez	         12/01/2017          	 Yaara          		 [SW-23221]
	*******************************************************************************/

	public static void Teacher_Qualification_checkTeacherQualifications(){
		if( HD_TriggerSettings.IsTriggerActive('Teacher_Qualification_checkTeacherQualifications') ){
			Set<Id> teacherQIds = new Set<Id>();
			for(Integer i = 0; i < trigger.size; i++ ){
				Teacher_Qualification__c newTeacherQ = (Teacher_Qualification__c) trigger.new[i];

				Boolean cond = trigger.isInsert; 
				cond |= trigger.isUpdate && newTeacherQ.Run_Logic_QT__c != ((Teacher_Qualification__c) trigger.old[i]).Run_Logic_QT__c && newTeacherQ.Run_Logic_QT__c == true;
				if(cond){
					teacherQIds.add(newTeacherQ.Id);
				}
			}

			if(!teacherQIds.isEmpty()){

				Map<Id, List<Teacher_Qualification__c>> teacherQMap = new Map<Id, List<Teacher_Qualification__c>>();
				for(Teacher_Qualification__c teacherQ : [SELECT Id, Teacher__c, Base_Course__r.Name FROM Teacher_Qualification__c WHERE Teacher__c != null AND Id IN :teacherQIds]){
					if(!teacherQMap.containsKey(teacherQ.Teacher__c)){

						teacherQMap.put(teacherQ.Teacher__c, new List<Teacher_Qualification__c>());
					}
					teacherQMap.get(teacherQ.Teacher__c).add(teacherQ);				
				}

				if(!teacherQMap.isEmpty()){
					List<LG__c> lgs2up = new List<LG__c>();
					for(LG__c lg : [SELECT Id, Base_Course__c, Teacher__c FROM LG__c WHERE Teacher__c IN :teacherQMap.keySet() AND Teacher_is_not_Qualified_for_Base_Course__c = true]){
						//check each qualification to see if he is qualified
						for(Teacher_Qualification__c teacherQ : teacherQMap.get(lg.Teacher__c)){
							if(lg.Base_Course__c == teacherQ.Base_Course__r.Name){
								lg.Teacher_is_not_Qualified_for_Base_Course__c = false;


								lgs2up.add(lg);
							}					
						}	
			
					}

				  	if(!lgs2up.isEmpty()){
				  		update lgs2up;
				  	}
				}
			}
		}
	}
}