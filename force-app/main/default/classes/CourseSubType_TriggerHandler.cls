/******************************************************************************* 
Name              : CourseSubType_TriggerHandler
Description       : Handler the before/after trigger on Campaign
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez         	05/13/2016
*******************************************************************************/
public class CourseSubType_TriggerHandler {

	public static void executeTriggerHandler(){
		
		//  ---------------------------- AFTER EVENTS -----------------------------
				
		//  ---------------------------- AFTER EVENTS -----------------------------
		if (Trigger.isAfter && Trigger.isInsert){
			courseSubTypeCreateSharingRules();
		}		
		else if (Trigger.isAfter && Trigger.isUpdate){
			courseSubTypeCreateSharingRules();
		}				
	}
	
	/******************************************************************************* 
	Name              : courseSubTypeCreateSharingRules
	Description       : Handler the sharing record of Course_Sub_Type__c object
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez         	05/13/2016         	Yaara Nadir				  [SW-19267]
	*******************************************************************************/
	
	public static void courseSubTypeCreateSharingRules(){
		if( HD_TriggerSettings.IsTriggerActive('courseSubTypeCreateSharingRules') ){
			
			List<Course_Sub_Type__c> courseSTs = new List<Course_Sub_Type__c>();
			for(Integer i=0; i < trigger.size; i++ ){
				Course_Sub_Type__c cst = (Course_Sub_Type__c)trigger.new[i];
				if(trigger.isInsert || ((Course_Sub_Type__c)trigger.old[i]).OwnerId <> cst.OwnerId){
					courseSTs.add(cst);
				}
			}

			if(!courseSTs.isEmpty()){
				HD_SharingMethods.CourseSubType_CreateSharingRules(courseSTs);				
			}
		}
	}
}