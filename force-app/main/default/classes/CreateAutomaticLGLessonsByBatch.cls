/**************************************************************************************** 
	Name              : CreateAutomaticLGLessonsByBatch
	Description 	  : Create LG Leassons and its related objects regarding logic of issue SW-26135.
	Revision History  :-
	Created/Modified by   		Created/Modified Date     Requested by      Related Task/Issue  
	----------------------------------------------------------------------------------------
	1. Hernan (Created)			08/11/2016                Yaara		           [SW-26135]
	----------------------------------------------------------------------------------------	
****************************************************************************************/
global class CreateAutomaticLGLessonsByBatch implements Database.Batchable<sObject>, Database.Stateful{

	public class MyException extends Exception {}
	
	global String query = 'SELECT Id, Name, Create_LG_Lessons_By__c, LG_Start_Date__c, LG_End_Date__c, LG_Lessons__c, Franchisee__r.Create_LG_Lessons_By_Formula__c, Recommended_Lessons__c FROM LG__c WHERE Create_Automatic_LG_Lessons__c = True AND ID NOT IN: lgAlreadyProcessedIds AND Billing_Type__c = \'Price per Session\' AND (Number_of_Lessons__c = Null OR Number_of_Lessons__c = 0) AND Number_of_Session_a_Week__c > 0 AND LG_End_Date__c >: queryEndDate AND Group_Status__c IN: queryStatus LIMIT :queryLimitByLG';
	
	global String processName					{get; set;}
	global Set<Id> lgAlreadyProcessedIds		{get; set;}
	global Integer queryLimitByLG 				{get; set;}
	global Date queryEndDate	 				{get; set;}
	global Set<String> queryStatus 				{get; set;}
	
	global List<HD_Log__c> errorLogs			{get; set;}
	global Decimal rollback_key					{get; set;}	
	
	public static boolean testErroONStart = false;
	public static boolean testErroONExcecution = false;
	
	public CreateAutomaticLGLessonsByBatch(){
			
		processName = 'Batch - Create Automatic LG Lessons'; // IMPORTANT!!! For initial specific request use 'Batch - Create Automatic LG Lessons (Initial)' at the moment to call the batch
		queryLimitByLG = 15;
		queryEndDate = Date.newInstance(2017,1,1);
		queryStatus = new Set<String>{'Active','Completed'};
		lgAlreadyProcessedIds = new Set<Id>();	
		errorLogs = new List<HD_Log__c>();
	}
	
	global Iterable<sObject> start(Database.BatchableContext BC){
		
		List<LG_Lesson__c> allLessons2Create = new List<LG_Lesson__c>();
		List<HD_Log__c> errorLogs = new List<HD_Log__c>();
		
		List<LG__c> currentLGList;
		try{
    	
    		// Get all the LG to be processed by this batch instance
    		currentLGList = (List<LG__c>) database.query(query);
    		for(LG__c currentLG : currentLGList){
    			
    			lgAlreadyProcessedIds.add(currentLG.Id); // for excluding on the next iteration (in case the LG cannot be updated due to a VR)
    			
    			currentLG.Create_Automatic_LG_Lessons__c = false; // for avoiding to include again this LG on future calls
    				
    			List<LG_Lesson__c> lessons2Create;
	    		if(currentLG.Franchisee__r.Create_LG_Lessons_By_Formula__c <> 'Number of Lessons'){ 
	    			
	    			// By End Date		    	
		    		lessons2Create = LGHelperMethods.getAllLessonsDays(currentLG.Id, currentLG.LG_Start_Date__c);
		    		currentLG.Create_LG_Lessons_By__c = 'LG End Date';
	    		}else{ 
	    			
	    			// By Lesson Number
	    			currentLG.Create_LG_Lessons_By__c = 'Number of Lessons';
	    			if(currentLG.LG_Lessons__c == null){
	    				currentLG.LG_Lessons__c = currentLG.Recommended_Lessons__c;
	    			}
	    			
	    			lessons2Create = LGHelperMethods.getAllLessonsDaysByNumberOfLessons(currentLG.Id, currentLG.LG_Lessons__c, currentLG.LG_Start_Date__c);
	    			
	    			if(lessons2Create.size() > 0){
	    			
	    				// Get the last lesson date
	    				Datetime dt = lessons2Create[lessons2Create.size()-1].Lesson_Date_Hour__c;
		    			Date lastLessonDate = Date.newInstance(dt.year(), dt.month(), dt.day());
		    			
		    			currentLG.LG_End_Date__c = lastLessonDate;
	    				currentLG.LG_End_Paying_Date__c = lastLessonDate; 
	    			}
	    		}
	    		
	    		if(lessons2Create.size()>0){
	    			allLessons2Create.addAll(lessons2Create);
	    		}
		    }
		    
		    if(currentLGList.size()>0){
			    
			    update currentLGList;
		    	/* On this batch logic Yaara told me that will not send any notification...
		    	if(needsChanged_LGEndDate ){ // Create a feed to the current user...
					LGCreateLessons_Ctl.sendNotifications(new List<LG__c>{currentLGList}); 
				}
				*/
		    }		  
		    
		    if(testErroONStart){
		    	throw new MyException('Test Error Log on Test method');
		    }		      
	    }catch(Exception ex){
	    	
	    	for(LG__c currentLG : currentLGList){	
    			errorLogs.add(new HD_Log__c(Process_Key__c = rollback_key, LG__c = currentLG.Id, Process_Name__c = processName, Error_Description__c = ex.getMessage(), Status__c = 'Fail'));
	    	}
	    	allLessons2Create = new List<LG_Lesson__c>(); // Nothing will continue until fix the data problem. TODO CHECK IF WE SHOULD EXCLUDE LG 
    	}    	
		return allLessons2Create;
	}
	 
	global void execute(Database.BatchableContext BC, List<LG_Lesson__c> scope){
		
		Set<Id> relatedLGInScope = new Set<Id>();
		
		try{
			
			MonitorRecursionClass.SetProcessKey(rollback_key);
			
			// Check if we are on the first initial running (this will consider also special cases like: If the LG. Group_Status__c = Completed, create also Payments for LG Students 
			// with Status_in_LG__c = Drop-Out or Moved or Completed)
			if(processName == 'Batch - Create Automatic LG Lessons (Initial)'){
				MonitorRecursionClass.isRunningInitialCreateAutomaticLGLessonsByBatch = true; // IMPORTANT
			}
			
			for(LG_Lesson__c lss : scope){
				relatedLGInScope.add(lss.LG__c);
			}
			
			// Avoiding the possible duplicate lessons (just to prevent this scenario but may not happen)
			Map<Id, Set<Datetime>> existingLGdates = new Map<Id,Set<Datetime>>();
			for(LG_Lesson__c existingLG : [SELECT Id, Lesson_Date_Hour__c, LG__c FROM LG_Lesson__c WHERE LG__c IN: relatedLGInScope]){
				if(!existingLGdates.containsKey(existingLG.LG__c)){
					existingLGdates.put(existingLG.LG__c, new Set<Datetime>());
				}
				existingLGdates.get(existingLG.LG__c).add(existingLG.Lesson_Date_Hour__c);
			}
			
			List<LG_Lesson__c> lss2Process = new List<LG_Lesson__c>();
			for(LG_Lesson__c lss : scope){
				if(!existingLGdates.containsKey(lss.LG__c) || !existingLGdates.get(lss.LG__c).contains(lss.Lesson_Date_Hour__c)){
					lss2Process.add(lss);
				}
			}			
			
			// Inserting the LG lessons
			List<Database.SaveResult> slr = Database.insert(lss2Process,false);
            for(Integer i = 0; i < slr.size(); i++){
                
                Database.SaveResult sr = slr.get(i);
                if(!sr.isSuccess()){
                	if(!(sr.getErrors()[0] instanceof Database.DuplicateError)) { // if the dupcheck find duplicate records we will exclude it...
                	 	throw new MyException(sr.getErrors()[0].getMessage());
                	}	                  
                }
            } 		
            
            // Logic that will not run automatically, so we should include here...
            
            Map<Id, List<LG_Student__c>> studentMap = new Map<Id, List<LG_Student__c>>();
			Set<Id> contactIds = new Set<Id>();
			
			for(LG_Student__c student : [SELECT Id, LG__c, Student__c, Student_Course_Start_Date__c, Student_Course_End_Date__c FROM LG_Student__c WHERE ( (Status_in_LG__c = 'Registered' OR (LG__r.Group_Status__c = 'Completed' AND (Status_in_LG__c = 'Drop-Out' OR Status_in_LG__c = 'Moved' OR Status_in_LG__c = 'Completed')) ) AND Billing_Type__c = 'Price per Session') AND LG__c IN : relatedLGInScope]){
				
				if(!studentMap.containsKey(student.LG__c)){
					studentMap.put(student.LG__c, new List<LG_Student__c>());
				}					
				studentMap.get(student.LG__c).add(student);
				contactIds.add(student.Student__c);
			}
			
			if(!studentMap.isEmpty()){
				LG_Student_TriggerHandler.LG_Student_CreateGroupIncomePerMonth_Helper(studentMap, contactIds);
			}           
            
            if(testErroONExcecution){
		    	throw new MyException('Test Error Log on Test method');
		    }
		}catch(Exception ex){
			for(Id currentLGId : relatedLGInScope){	
				errorLogs.add(new HD_Log__c(Process_Key__c = rollback_key, LG__c = currentLGId, Process_Name__c = processName, Error_Description__c = ex.getMessage(), Status__c = 'Fail'));
			}
		} 
	}
	
	global void finish(Database.BatchableContext BC){
		
		if(!errorLogs.isEmpty()){
			HD_Log__c log = new HD_Log__c(Send_Result__c = true, Process_Key__c = rollback_key, Process_Name__c = processName, Status__c = 'Fail');
			insert log;
			for(HD_Log__c hl : errorLogs){
				hl.Parent_Log__c = log.Id;
			}
			insert errorLogs;
		}		
		
		// Calls another query to check if there is pending LG to be processed. 
		List<LG__c> currentLGList = (List<LG__c>) database.query(query);
		
		CreateAutomaticLGLessonsByBatch b = new CreateAutomaticLGLessonsByBatch();
		b.queryLimitByLG = queryLimitByLG;
		b.processName = processName;
		b.lgAlreadyProcessedIds = lgAlreadyProcessedIds;
		b.rollback_key = rollback_key;
		if(currentLGList.size()>0){
			database.executebatch(b);
		}		
	}
}