/******************************************************************************* 
Name              : BC_Assessment_TriggerHandler
Description       : 
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G.Fernandez     			12/07/2016           
*******************************************************************************/

public with sharing class BC_Assessment_TriggerHandler {
	
	public static void executeTriggerHandler(){
	
		//  ---------------------------- BEFORE EVENTS -----------------------------
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		if (Trigger.isAfter && Trigger.isInsert){
			createLGStudentAssessments();	
		}
		
		if (Trigger.isAfter && Trigger.isUpdate){
			createLGStudentAssessments();
		}
    }  

    /******************************************************************************* 
	Name              : createLGStudentAssessments
	Description       : 
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G.Fernandez            12/07/2016		      Yaara Nadir        	SW-20366
	*******************************************************************************/
	public static void createLGStudentAssessments(){

    	if( HD_TriggerSettings.IsTriggerActive('createLGStudentAssessments') ){
			
			//3.2.1.2 Raise When: (New BC Assessment created with Active = True or existing BC Assessment.Active change to True) and Base Course.Status = Active.
	    	//MAP<BaseCourseId,SET BCAssessId>
	    	Map<String,Set<Id>> bcAssessMap = new Map<String,Set<Id>>();
	    	Set<Id> bcAssessIds = new Set<Id>();
	    	for( Integer i=0; i < trigger.size; i++ ){

	    		BC_Assessment__c bcAssess = (BC_Assessment__c) trigger.new[i];

	    		Boolean cond = trigger.isInsert && bcAssess.Active__c == true;
	    		cond |= trigger.isUpdate && bcAssess.Active__c == true && bcAssess.Active__c != ((BC_Assessment__c) trigger.old[i]).Active__c;
	    		
	    		if(cond){
	    			String id15 = String.valueOf(bcAssess.Base_Course__c).substring(0, 15);
	    			if (!bcAssessMap.containsKey(id15)) {	    				
	    				bcAssessMap.put(id15, new Set<Id>());
	    			}
	    			bcAssessMap.get(id15).add(bcAssess.Id);
	    			bcAssessIds.add(bcAssess.Id);
	    		}
    		}

    		if (!bcAssessMap.isEmpty() && !System.Test.isRunningTest()) {
				
    			Batch_CreateLGStudentAssessments b = new Batch_CreateLGStudentAssessments();
    			b.bcAssessMap = bcAssessMap;
    			Database.executeBatch(b);

    		}

    	}
	} 
}