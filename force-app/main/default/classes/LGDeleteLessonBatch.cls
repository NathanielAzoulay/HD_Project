/**************************************************************************************** 
	Name              : LGDeleteLessonBatch
	Description 	  : Delete LG Leassons and its related objects on asyn mode.
	Revision History  :-
	Created/Modified by   		Created/Modified Date     Requested by      Related Task/Issue  
	----------------------------------------------------------------------------------------
	1. Hernan (Created)			25/02/2016                Yaara		           [SW-18002]
	2. Hernan 					04/08/2016                Yaara		           [SW-18014]
	3. Hernan 					03/13/2017                Yaara		           [SW-23793]
	----------------------------------------------------------------------------------------	
****************************************************************************************/
global class LGDeleteLessonBatch implements Database.Batchable<sObject>, Database.Stateful{
	
	global Date selectedDate					{get; set;}
	global Id lgId								{get; set;}
	global String processName					{get; set;}
	global List<HD_Log__c> errorLogs			{get; set;}
	global Decimal rollback_key					{get; set;}	
	global List<LG_Lesson__c> records2process	{get; set;}
	
	global Iterable<sObject> start(Database.BatchableContext BC){
	
		errorLogs = new List<HD_Log__c>();
		return records2process;
	}
	
	global void execute(Database.BatchableContext BC, List<LG_Lesson__c> scope){
		
		try{
			
			List<LG_Student_Attendance__c> studentsAtt2Del = new List<LG_Student_Attendance__c>();
    		for(LG_Lesson__c r : scope){
    			studentsAtt2Del.addAll(r.LG_Students_Attendance__r);
    		}
    		
    		Map<String, LG_Payment__c> p2Ins = LGHelperMethods.deleteLGStudentAttendanceAndItsLGPayments(studentsAtt2Del, true, rollback_key);
    		
    		delete scope;  
    		
    		if(!p2Ins.isEmpty()){ // Insert the LG Payment realculated with the remaind att
    			insert p2Ins.values();
    		}    		
    	}catch(Exception ex){
			errorLogs.add(new HD_Log__c(Process_Key__c = rollback_key, LG__c = lgId, Process_Name__c = processName, Error_Description__c = ex.getMessage(), Status__c = 'Fail'));
		}
	}
	
	global void finish(Database.BatchableContext BC){
		
		if(errorLogs.isEmpty()){
			if(processName != 'Batch - Update LG Days & Hour'){
				insert(new HD_Log__c(Send_Result__c = true, Process_Key__c = rollback_key, LG__c = lgId, Process_Name__c = processName, Status__c = 'Success'));
			}else{
				
				// Calling the Batch process that will Create the LG Leasson and its related records from the Selected Date
				LGCreateLessonBatch b = new LGCreateLessonBatch();
				LG__c lg = [SELECT Id, Create_LG_Lessons_By__c, LG_Lessons__c, LG_End_Date__c, Name FROM LG__c WHERE Id =: lgId];
				Date originalLGEndDate = lg.LG_End_Date__c;
				if(lg.Create_LG_Lessons_By__c != 'Number of Lessons'){
		    		b.records2process = LGHelperMethods.getAllLessonsDays(lgId, selectedDate);
				}else{
					b.records2process = LGHelperMethods.getAllLessonsDaysByNumberOfLessons(lg.Id, lg.LG_Lessons__c, selectedDate);
					
					// Get the last lesson date
	    			Date lastLessonDate = Date.valueOf(b.records2process[b.records2process.size()-1].Lesson_Date_Hour__c);
		    		if(originalLGEndDate <> lastLessonDate){
		    			LG__c lg2Up = new LG__c(Id = lg.Id, LG_End_Date__c = lastLessonDate);
		    			Database.SaveResult sr = database.update(lg2UP, false);
		    		}
				}
		    	b.doInsert = true;
		    	b.lgStudents = [SELECT Id, Student_Course_Start_Date__c, Student_Course_End_Date__c, Billing_Type__c, Lesson_Type__c, (Select Planned_Date__c, Planned_Price__c From LG_Payments__r) FROM LG_Student__c WHERE LG__c =: lgId AND (Status_in_LG__c = 'Registered' OR Status_in_LG__c = 'Signed for Demo')];
		    	b.processName = processName;
		    	b.selectedDate = selectedDate;
		    	if(!b.records2process.isEmpty()){
		    		b.rollback_key = rollback_key; 
		    		Database.executeBatch(b);
		    	}
			}
		}else{			
						
			HD_Log__c log = new HD_Log__c(Send_Result__c = true, Process_Key__c = rollback_key, LG__c = lgId, Process_Name__c = processName, Status__c = 'Fail');
			insert log;
			for(HD_Log__c hl : errorLogs){
				hl.Parent_Log__c = log.Id;
			}
			insert errorLogs;
		
			doLGDeleteLessonBatchRollback(rollback_key);
		}
	}
	
	public static void doLGDeleteLessonBatchRollback(Decimal rollback_key){
		
		// Rollback all record affected by the Batch Process.	
		delete [SELECT Id FROM LG_Payment__c WHERE Rollback_Key__c =: rollback_key];
		undelete [SELECT Id FROM LG_Lesson__c WHERE isDeleted = true AND Rollback_Key__c =: rollback_key ALL ROWS]; 
		undelete [SELECT Id FROM LG_Payment__c WHERE isDeleted = true AND Rollback_Key__c =: rollback_key ALL ROWS]; 
		undelete [SELECT Id FROM LG_Student_Attendance__c WHERE isDeleted = true AND Rollback_Key__c =: rollback_key ALL ROWS];
	}
}