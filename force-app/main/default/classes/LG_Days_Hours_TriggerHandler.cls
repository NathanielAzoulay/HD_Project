/******************************************************************************* 
Name              : LG_Days_Hours_TriggerHandler
Description       : Handler the before/after trigger on LG Days Hours
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio         	    11/03/2016       	
*******************************************************************************/
public with sharing class LG_Days_Hours_TriggerHandler {
    public static void executeTriggerHandler(){
    	
		//  ---------------------------- AFTER EVENTS -----------------------------
		
		
		if (Trigger.isBefore && Trigger.isInsert) // Before Update
		{
			MaxLessonsForADayOnBefore();
		}
		
		else if (Trigger.isBefore && Trigger.isUpdate) // Before Insert
		{
			MaxLessonsForADayOnBefore();
		}
		/*
		else if (Trigger.isBefore && Trigger.isDelete) // Before Delete
		{
		}
		*/
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		
		
		
		if (Trigger.isAfter && Trigger.isInsert) // After Insert
		{
            lgDHCreateSharingRules();	
		}
		
		if (Trigger.isAfter && Trigger.isUpdate) // After Update
		{
            lgDHCreateSharingRules();
            changeTeacherLessons();
		}
        /*
		else if (Trigger.isAfter && Trigger.isDelete) // After Delete
		{
			
		}
		else if (Trigger.isAfter && Trigger.isUnDelete) // After UnDelete
		{
			
		}
		
		*/	
    }
    
    /******************************************************************************* 
	Name              : MaxLessonsForADayOnBefore
	Description       : Validates that there aren't more Lessons in a given day based on Max Lessons per Day
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Sergio         			11/03/2016          	Ella  Bernachik			[SW-17617]
	*******************************************************************************/
    public static void MaxLessonsForADayOnBefore(){
        if( HD_TriggerSettings.IsTriggerActive('MaxLessonsForADayOnBefore') ){

        	//Will contain the Id of LG followed by Days and the number of Lessons
        	//LG.Id -> Day -> N° Lessons
        	Map<Id, Map<String, Integer>> lg_lessonsPerDay = new Map<Id, Map<String, Integer>>();
        	
        	//Helps determine to whom the error should go
        	Map<Id, Map<String, Set<Integer>>> lg_lgDHPerDay = new Map<Id, Map<String, Set<Integer>>>();
        	Set<Id> lgDHIds = new Set<Id>();
        	
        	for( Integer i=0; i < trigger.size; i++ ){
        		LG_Days_Hours__c lgDH_n = (LG_Days_Hours__c) trigger.new[i];
        		
        		Boolean condition = trigger.isInsert;
        		condition |= trigger.isUpdate && lgDH_n.Day__c != trigger.old[i].get('Day__c');
        		
        		if( condition ){
        			if( trigger.isUpdate ){
        				lgDHIds.add( lgDH_n.Id );
        			}
        			
        			Id lgId = lgDH_n.LG__c;
        			String day = lgDH_n.Day__c;
        			
        			if( lg_lessonsPerDay.containsKey( lgId ) == false ){
        				lg_lessonsPerDay.put( lgId, new Map<String, Integer>() );
        				lg_lgDHPerDay.put( lgId, new Map<String, Set<Integer>>() );
        			}
        			
        			Integer nDays = 0;
        			
        			if( lg_lessonsPerDay.get( lgId ).containsKey( day ) == true ){
        				nDays = lg_lessonsPerDay.get( lgId ).get(day);
        			}else{
        				lg_lgDHPerDay.get( lgId ).put( day, new Set<Integer>() );
        			}
        			
        			lg_lessonsPerDay.get( lgId ).put(day, nDays + 1 );
        			
        			//For knowing to whom throw the error if a given day has more lessons.
        			lg_lgDHPerDay.get( lgId ).get( day ).add( i );
        		}
        	}
        	
        	if( lg_lessonsPerDay.isEmpty() == false ){
        		
        		
        		
        		for( LG__c lg : [SELECT Id, Max_Lessons_per_Day__c, (SELECT Id, Day__c FROM LG_Days_Hours__r WHERE Id NOT IN :lgDHIds ) FROM LG__c WHERE Id IN :lg_lessonsPerDay.keySet() ] ){
        			
        			if( lg.LG_Days_Hours__r.isEmpty() == false ){
        				//There already exist some LG Days Hours. We add them to the Map
    					for( LG_Days_Hours__c lgDH : lg.LG_Days_Hours__r ){
    						Integer nDays = 0;
    						if( lg_lessonsPerDay.get( lg.Id ).containsKey( lgDH.Day__c ) == true ){
    							nDays = lg_lessonsPerDay.get( lg.Id ).get(lgDH.Day__c);
    						}
    						lg_lessonsPerDay.get( lg.Id ).put(lgDH.Day__c, nDays + 1 );
    					}
        			}
        			
        			for( String day : lg_lessonsPerDay.get(lg.Id).keySet() ){
        				if( lg.Max_Lessons_per_Day__c < lg_lessonsPerDay.get(lg.Id).get(day) ){
        					//Error: Exceeded number of Lessons per Day
        					for( Integer i : lg_lgDHPerDay.get(lg.Id).get(day) ){
        						trigger.new[i].addError( Label.LG_Days_Hours_Number_of_Days );
        					}
        				}
        			}
        		}
        		
        	}

        }
    }


    /******************************************************************************* 
    Name              : changeTeacherLessons
    Description       : Updates teachers on future lessons remaining after the change date
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez          16/03/2016              Yaara Nadir             [SW-18015]
    *******************************************************************************/
    public static void changeTeacherLessons(){
        if( HD_TriggerSettings.IsTriggerActive('changeTeacherLessons') ){
        
            Map<Id,LG_Days_Hours__c> lgsNewTeachers = new Map<Id,LG_Days_Hours__c>();

            //check changes in teacher and collect the ids of LGs with new teachers
            for( Integer i=0; i < trigger.size; i++ ){
                LG_Days_Hours__c lgDH_new = (LG_Days_Hours__c) trigger.new[i];
                LG_Days_Hours__c lgDH_old = (LG_Days_Hours__c) trigger.old[i];

                if(lgDH_new.Teacher__c != lgDH_old.Teacher__c){
                    lgsNewTeachers.put(lgDH_new.Id, lgDH_new);
                }
            }

            if(!lgsNewTeachers.isEmpty()){
                List<LG_Lesson__c> lgLessons2Up = new List<LG_Lesson__c>();
                //look for related future lessons from now
                for(LG_Lesson__c lesson2up : [SELECT Id, LG_Days_Hours__c FROM LG_Lesson__c WHERE LG_Days_Hours__c IN :lgsNewTeachers.keySet() AND Lesson_Date_Hour__c > :System.now()]){
                    lesson2up.Lesson_Teacher__c = lgsNewTeachers.get(lesson2up.LG_Days_Hours__c).Teacher__c;
                    lgLessons2Up.add(lesson2up);                  
                }

                System.debug('lgLessons2Up --> ' + lgLessons2Up);

                if(!lgLessons2Up.isEmpty()){
                    Update lgLessons2Up;
                }
            }

        }
    }

    /******************************************************************************* 
    Name              : lgDHCreateSharingRules
    Description       : Handler the sharing record of LG_Days_Hours__c object
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             05/11/2016              Yaara                 [SW-19269]
    *******************************************************************************/
    
    public static void lgDHCreateSharingRules(){
        if( HD_TriggerSettings.IsTriggerActive('lgDHCreateSharingRules') ){
            
            Set<Id> dHids = new Set<Id>();            
            Set<Id> updatedDHids = new Set<Id>(); 
            //collect lgDh new or with teacher changed 
            for(Integer i=0; i < trigger.size; i++ ){
                if(Trigger.isInsert){
                    dHids.add(trigger.new[i].Id);
                }else if(((LG_Days_Hours__c)trigger.new[i]).Teacher__c != ((LG_Days_Hours__c)trigger.old[i]).Teacher__c){                    
                    dHids.add(trigger.new[i].Id);
                    updatedDHids.add(trigger.new[i].Id);
                }                                   
            }

            Set<LG_Days_Hours__c> lgDHids = new Set<LG_Days_Hours__c>();
            //get more field on lgDH and check conditions
            if(!dHids.isEmpty()){
                for(LG_Days_Hours__c lgDH : [SELECT Teacher__c, LG__c, LG__r.Teacher__c FROM LG_Days_Hours__c WHERE Id IN :dHids]){
                    if(lgDH.Teacher__c != lgDH.LG__r.Teacher__c || updatedDHids.contains(lgDH.Id)){
                        lgDHids.add(lgDH);
                    }
                }                
            }

            if(!lgDHids.isEmpty()){
                HD_SharingMethods.lgDHCreateSharingRules(lgDHids);
            }
        }
    }
}