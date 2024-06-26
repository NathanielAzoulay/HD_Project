/**************************************************************************************** 
	Name              : LGCreateLessonBatch
	Description 	  : Create LG Leassons and its related objects on asyn mode.
	Revision History  :-
	Created/Modified by   		Created/Modified Date     Requested by      Related Task/Issue  
	----------------------------------------------------------------------------------------
	1. Hernan (Created)			02/24/2016                Yaara		           [SW-18001]
	2. Hernan 					04/08/2016                Yaara		           [SW-18014]
	3. Hernan 					05/02/2017                Yaara		           [SW-24707]
	4. G. Fernandez				09/06/2017                Yaara		           [SW-26336]
	5. Avihai Shindelman		03/07/2018			Gidi Abramovitch		Task-000001699
	----------------------------------------------------------------------------------------	
****************************************************************************************/
global class LGCreateLessonBatch implements Database.Batchable<sObject>, Database.Stateful{
    
	global class MyException extends Exception {}
	
	global Date selectedDate					{get; set;}
	global String processName					{get; set;}
	global List<HD_Log__c> errorLogs			{get; set;}
	global Decimal rollback_key					{get; set;}	
	global List<LG_Lesson__c> records2process	{get; set;}
	global List<LG_Student__c> lgStudents 		{get; set;}
	global Boolean doInsert 					{get; set;}

	global Iterable<sObject> start(Database.BatchableContext BC){
		
		this.errorLogs = new List<HD_Log__c>();//Avihai added this.
		
		return records2process;
	}
	 
	global void execute(Database.BatchableContext BC, List<LG_Lesson__c> scope){
		
		try{
			
			// Avoiding the possible duplicate lessons
			Set<Datetime> existingLGdates = new Set<Datetime>();
			for(LG_Lesson__c existingLG : [SELECT Id, Lesson_Date_Hour__c,LG__r.Holiday_Course__c, Lesson_Status__c FROM LG_Lesson__c WHERE LG__c =: records2process[0].LG__c]){
				existingLGdates.add(existingLG.Lesson_Date_Hour__c);
			}
			
			List<LG_Lesson__c> lss2Process = new List<LG_Lesson__c>();
			for(LG_Lesson__c lss : scope){
				if(!existingLGdates.contains(lss.Lesson_Date_Hour__c)){
                    if (lss.LG__r.Holiday_Course__c == false && lss.Lesson_Status__c == 'Day Off')//Avihai added Holiday Course.
                    	lss.Lesson_Status__c = null;
					lss2Process.add(lss);
				}
			}
			
            Date lastDayOfMonth; // In case that the Batch was called with a selecteDate (from Create Button), we will need just create (maintenance) the LG Payment from that seleted date
			if(selectedDate <> null){
				Integer iYear = selectedDate.year();
				Integer iMonth = selectedDate.month();
				lastDayOfMonth  = Date.newInstance(iYear, iMonth, Date.daysInMonth(iYear, iMonth));
			}
            
			if(doInsert){
				List<Database.SaveResult> slr = Database.insert(lss2Process,false);
	            for(Integer i = 0; i < slr.size(); i++){
	                Database.SaveResult sr = slr.get(i);
	                if(!sr.isSuccess()){
	                	if(!(sr.getErrors()[0] instanceof Database.DuplicateError)) { // if the dupcheck find duplicate records we will exclude it...
                            throw new MyException(sr.getErrors()[0].getMessage());
	                	}	                  
	                }
	            }
				
			}			
			 
			
			
			MonitorRecursionClass.SetProcessKey(rollback_key);
			
			/*
				createStudentsAttAndLGPayments(lss2Process, lgStudents, selectedDate, lastDayOfMonth, rollback_key, true);
			*/			
		}catch(Exception ex){
			errorLogs.add(new HD_Log__c(Process_Key__c = rollback_key, LG__c = records2process[0].LG__c, Process_Name__c = processName, Error_Description__c = ex.getMessage(), Status__c = 'Fail'));
		}
	}
	
	public static boolean notNeed2CheckRangeDateOnNewLesson = false; // Just we will put in true when the leasson is created because the user extend the lessons
	public static boolean theLessonWasCreatedDueToChangeLGEndDate = false; // Just we will put in true when the leasson is created not manually and when the user change the LG End Date.
	public static void createStudentsAttAndLGPayments(List<LG_Lesson__c> lss2Process, List<LG_Student__c> lgStudents, Date selectedDate, Date lastDayOfMonth, Decimal rollback_key, Boolean withLGPaymentAction){
		
		List<LG_Student_Attendance__c> studentsAtt4NextProcess = new List<LG_Student_Attendance__c>();
		Map<Id, LG_Student__c> maplgStudents = new Map<Id, LG_Student__c>(); 
		Map<Id, LG_Payment__c> mapInitialLGPaymetBylgStudents = new Map<Id, LG_Payment__c>(); 
		Set<Id> lgls = new Set<Id>(); 
		for(LG_Lesson__c s : lss2Process){            
			if(lgStudents <> null && s.Lesson_Status__c != 'Day Off'){
				lgls.add(s.Id);
				for(LG_Student__c lgStudent : lgStudents){
					
					if(notNeed2CheckRangeDateOnNewLesson || (s.Lesson_Date_Hour__c <> null && lgStudent.Student_Course_Start_Date__c <= s.Lesson_Date_Hour__c.date() && lgStudent.Student_Course_End_Date__c >= s.Lesson_Date_Hour__c.date()) /* could be null this  s.Lesson_End_Hour__c.date() anyway is the same date*/ ){ // Check the conditon LG Student Course Start Date <=Lesson Date and LG Student Course End Date >= Lesson Date 
						maplgStudents.put(lgStudent.Id, lgStudent);
						studentsAtt4NextProcess.add(new LG_Student_Attendance__c(Rollback_Key__c = rollback_key, LG_Lesson__c = s.Id, Lesson_Type__c = lgStudent.Lesson_Type__c, LG_Student__c = lgStudent.Id, Attended__c = 'None'));
					}
					
					/* the trigger will take care
					if(selectedDate <> null){ // TODO: check if this action just need to check on the border when the seleted date was selected or if exist an supperpostition maintenace all the rest
						for(LG_Payment__c p : lgStudent.LG_Payments__r){
							if(p.Planned_Date__c == lastDayOfMonth){
								mapInitialLGPaymetBylgStudents.put(lgStudent.Id, p);
							}
						}
					}
					*/
				}	
			}
		}
		
		if(!studentsAtt4NextProcess.isEmpty()){
					
			system.debug('>>> studentsAtt4NextProcess: ' + studentsAtt4NextProcess);	
			Set<String> existentAttendance = new Set<String>();
			for (LG_Lesson__c lgl : [SELECT Id, (SELECT LG_Student__c FROM LG_Students_Attendance__r) FROM LG_Lesson__c WHERE Id IN :lgls]) {
				for (LG_Student_Attendance__c lsa : lgl.LG_Students_Attendance__r) {
					String key = String.valueOf(lgl.Id).substring(0, 15) + '_' + String.valueOf(lsa.LG_Student__c).substring(0, 15);
					existentAttendance.add(key);
				}
			}

			//SW-26336
			List<LG_Student_Attendance__c> att2ins = new List<LG_Student_Attendance__c>();
			for (LG_Student_Attendance__c lsa : studentsAtt4NextProcess) {
				String key = String.valueOf(lsa.LG_Lesson__c).substring(0, 15) + '_' + String.valueOf(lsa.LG_Student__c).substring(0, 15);
				if(!existentAttendance.contains(key)){
					att2ins.add(lsa);
				}
			}
			// The related payment will be created on method "createLGPaymentToStudent"
			if(!att2ins.isEmpty()){
				insert att2ins;
			}
			
			/* the trigger will take care
			if(withLGPaymentAction){
				List<LG_Payment__c> p2Del = new List<LG_Payment__c>();
				List<LG_Payment__c> p2Ins = new List<LG_Payment__c>();
				for(LG_Payment__c p : LGHelperMethods.getLGPaymentBySessions(maplgStudents.keySet(), null, rollback_key)){ 
					
					if(selectedDate == null || selectedDate < p.Planned_Date__c){
						p2Ins.add(p);
					}
					
					if(selectedDate <> null && mapInitialLGPaymetBylgStudents.containsKey(p.LG_Student__c) && p.Planned_Date__c == lastDayOfMonth){
						p2Del.add(mapInitialLGPaymetBylgStudents.get(p.LG_Student__c)); // Already exist, so will be replaced by new one  TODO: check if should be deleted or updated
					}
				}
				
				system.debug('>>> p2Ins: ' + p2Ins);
				
				if(!p2Del.isEmpty()){
					delete p2Del;
				}
				
				if(!p2Ins.isEmpty()){
					insert p2Ins;
				}
			}
			*/
		}
	}
	
	global void finish(Database.BatchableContext BC){
		
		if(this.errorLogs.isEmpty()){//Avihai added "this".
			insert(new HD_Log__c(Send_Result__c = true, Process_Key__c = rollback_key, LG__c = records2process[0].LG__c, Process_Name__c = processName, Status__c = 'Success'));
		}else{
			
			if(doInsert && rollback_key <> null && rollback_key <> 0){
				delete [SELECT Id FROM LG_Student_Attendance__c WHERE Rollback_Key__c =: rollback_key]; // deleting the LG Student Attendance due to the error on the transaction (auto rollback)
				delete [SELECT Id FROM LG_Lesson__c WHERE Rollback_Key__c =: rollback_key]; // deleting the LG Lessons (created on previus batch process) due to the error on the transaction (auto rollback)
				delete [SELECT Id FROM LG_Payment__c WHERE Rollback_Key__c =: rollback_key];
			}
			
			HD_Log__c log = new HD_Log__c(Send_Result__c = true, Process_Key__c = rollback_key, LG__c = records2process[0].LG__c, Process_Name__c = processName, Status__c = 'Fail');
			insert log;
			for(HD_Log__c hl : errorLogs){
				hl.Parent_Log__c = log.Id;
			}
			insert errorLogs;
			
			if(processName == 'Batch - Update LG Days & Hour'){
				LGDeleteLessonBatch.doLGDeleteLessonBatchRollback(rollback_key);
			}
		}
	}
}