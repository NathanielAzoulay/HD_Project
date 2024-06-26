/******************************************************************************* 
Name              : LG_TriggerHandler
Description       : Handler the before/after trigger on LG
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan Sinclair  		03/11/2016          	
*******************************************************************************/
public class LG_TriggerHandler {

	public static void executeTriggerHandler(){
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		if (Trigger.isBefore && Trigger.isUpdate){ // Before Insert
		 	// Cannot be called on before due to the recursive update during the delete...recreateLGPayment2LGBillingTypeChange();
		}
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		
		if (Trigger.isAfter && Trigger.isInsert){ // After Insert
		
			createLGPaymentToLG();
			LG_CreateGroupIncomePerMonth();
			LG_checkTeacherQualifications();
			
			lgCreateSharingRules();
		}else if (Trigger.isAfter && Trigger.isUpdate){ // After Update
			
			updateCompletedLGStudentWhenCompletedLGIsBeingActivatedAgain();
			deleteLGPaymentToLG(); // If the End_Paying_Date__c has changed for a more recent value, the we should delete some LG payments...
			maintenaceLGStudents();
			maintenanceLGPaymentsAndGIMRecordsOnDeclaredNroChanged(); // This method should be called before createLGPaymentToLG() and LG_CreateGroupIncomePerMonth(), so please, take into consideration you if you need to change the order of execution 
			recreateLGPayment2LGBillingTypeChange();
			updateRelatedRecordsOnChangeLGTeacher();
			maintenaceLGLesson();
			createLGPaymentToLG();
			maintenanceLGPaymentToLGStudents();
			LG_CreateGroupIncomePerMonth();
			LG_DeleteGroupIncomePerMonth();			
			LG_checkTeacherQualifications();
			
			reCallTheDiscountLogic();
			reCreateLGPaymentToLGStudent();
			
			lgCreateSharingRules();
		}				
	}
	
	
	/******************************************************************************* 
	Name              : reCallTheDiscountLogic
	Description       : Since the PB (that update the price on LG) it's fire after the LG Discount trigger discount running (when the discount it's approved). 
						We created this second process that will reRun the discount logic that didn't run it...  
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Hernan Sinclair         	06/04/2016          	Daftna				  [SW-24329]
	*******************************************************************************/
	public static void reCallTheDiscountLogic(){
		
		if(!LG_Discount_TriggerHandler.lgDiscountApproved.isEmpty()){
			
			Boolean callDisountLogic = false;
			for(Integer i=0; i < trigger.size; i++ ){
				
				LG__c r = (LG__c)trigger.new[i];
				LG__c rOld = (LG__c)trigger.old[i];
				if(r.Price_for_Payment__c <> rOld.Price_for_Payment__c){
					callDisountLogic = true;
				}
			}
			
			if(callDisountLogic){
				LG_Discount_TriggerHandler.updateLGPaymentWhenLGDiscountIsApproved(LG_Discount_TriggerHandler.lgDiscountApproved);
				LG_Discount_TriggerHandler.lgDiscountApproved.clear();
			}
		}		
	}
	
	/******************************************************************************* 
	Name              : updateCompletedLGStudentWhenCompletedLGIsBeingActivatedAgain
	Description       : When changing LG Status from Completed to Active, change the Status in LG for all Completed LG Students (LG Student.Status in LG = Completed) to "Register" 
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Hernan Sinclair         	11/07/2016          	Yaara				  [SW-22135]
	*******************************************************************************/
	public static void updateCompletedLGStudentWhenCompletedLGIsBeingActivatedAgain(){
		
		if( HD_TriggerSettings.IsTriggerActive('updateCompletedLGStudentWhenCompletedLGIsBeingActivatedAgain') ){
			
			Set<Id> lgIds = new Set<Id>();
			for(Integer i=0; i < trigger.size; i++ ){
				
				LG__c r = (LG__c)trigger.new[i];
				LG__c rOld = (LG__c)trigger.old[i];
				
				if(rOld.Group_Status__c == 'Completed' && r.Group_Status__c == 'Active'){
					lgIds.add(r.Id);
				}
			}	
			
			if(!lgIds.isEmpty()){
				List<LG_Student__c> lgS2Up = new List<LG_Student__c>();
				for(LG_Student__c ls : [SELECT Id FROM LG_Student__c WHERE LG__c IN: lgIds AND Status_in_LG__c = 'Completed']){
					ls.Status_in_LG__c = 'Registered';
					lgS2Up.add(ls);
				}
				
				if(!lgS2Up.isEmpty()){
					
					// We deactivate the following triggers, since only will be run it, by other LG methods, if the End Date ("LG End Date" or "LG End Paying Date" also are being changed).
					LG_Student_TriggerHandler.SKIP_createLGLessonsToStudent = true;
					LG_Student_TriggerHandler.SKIP_LG_Student_CreateGroupIncomePerMonth = true;
					LG_Student_TriggerHandler.SKIP_lgStudents2ReCreatedLGPaymentToLGStudents = true;
					update lgS2Up;
					LG_Student_TriggerHandler.SKIP_createLGLessonsToStudent = false;
					LG_Student_TriggerHandler.SKIP_LG_Student_CreateGroupIncomePerMonth = false;
					LG_Student_TriggerHandler.SKIP_lgStudents2ReCreatedLGPaymentToLGStudents = false;
				}
			}		
		}
	}
	
	/******************************************************************************* 
	Name              : LG_CreateSharingRules
	Description       : Handler the sharing record of LG cusmot object
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Hernan Sinclair         	05/11/2016          	Yaara				  [SW-19263]
	*******************************************************************************/
	
	public static void lgCreateSharingRules(){
		
		if( HD_TriggerSettings.IsTriggerActive('lgCreateSharingRules') ){
			
			List<LG__c> lgs = new List<LG__c>();
			for(Integer i=0; i < trigger.size; i++ ){
				LG__c lg = (LG__c)trigger.new[i];
				Boolean hasChange = trigger.isUpdate && ((LG__c)trigger.old[i]).OwnerId <> lg.OwnerId;
				hasChange |= trigger.isUpdate && ((LG__c)trigger.old[i]).Teacher__c <> lg.Teacher__c;
				hasChange |= trigger.isUpdate && ((LG__c)trigger.old[i]).Teacher_Permission_on_LG__c <> lg.Teacher_Permission_on_LG__c;
				hasChange |= trigger.isUpdate && ((LG__c)trigger.old[i]).Classroom__c <> lg.Classroom__c && lg.Classroom__c != null;
				if(trigger.isInsert || hasChange){
					lgs.add(lg);
				}
			}

			if(!lgs.isEmpty()){
				HD_SharingMethods.LG_CreateSharingRules(lgs);
			}
		}
	}
	
	/******************************************************************************* 
	Description       : Maintenace LG Students and its attendances
						* When new LG End Date > Previous LG End Date
							To all LG Student with
								1. Status in LG = Registered or Completed &
								2. Student Course End Date = pervious LG End Date
						  Update Student Course End Date to new LG End Date


						* When new LG End Date < Previous LG End Date
							To all LG Student with
								1. Status in LG = Registered &
								2. Student Course End Date = pervious LG End Date.
  			     		  Update Student Course End Date to new LG End Date(Work when Price Type = Per Student).						
   
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Hernan Sinclair         10/26/2016          	 Yaara          		 [SW-21976]
	2. Hernan Sinclair         03/29/2016          	 Dafna          		 [SW-24179]
	*******************************************************************************/
	public static void maintenaceLGStudents(){
		if( HD_TriggerSettings.IsTriggerActive('maintenaceLGStudents') ){
			
			Id recTypeLGDemoId = Schema.SObjectType.LG__c.getRecordTypeInfosByName().get('Demo Lesson').getRecordTypeId();
			
			Map<Id, Date> newDays = new Map<Id, Date>();
			Map<Id, Date> lessDays = new Map<Id, Date>(); 
			for(Integer i=0; i < trigger.size; i++ ){
				
				LG__c r = (LG__c)trigger.new[i];
				LG__c rOld = (LG__c)trigger.old[i];
				
				Boolean conditionLessDays = r.RecordTypeId != recTypeLGDemoId && rOld.LG_End_Date__c <> r.LG_End_Date__c && r.LG_End_Date__c > rOld.LG_End_Date__c;
				if(conditionLessDays){
					newDays.put(r.Id, r.LG_End_Date__c);
				}			
								
				Boolean conditionMoreDays = r.RecordTypeId != recTypeLGDemoId && rOld.LG_End_Date__c <> r.LG_End_Date__c && r.LG_End_Date__c < rOld.LG_End_Date__c;
				if(conditionMoreDays){
					lessDays.put(r.Id, r.LG_End_Date__c);
				}
			}
			
			List<LG_Student__c> lgStudent2Up = new List<LG_Student__c>();
			if(!newDays.isEmpty()){
				
				Map<Id, LG__c> rOlds = (Map<Id, LG__c>)trigger.oldMap;
				for(LG_Student__c ls : [SELECT Id, Student_Course_End_Date__c, LG__c FROM LG_Student__c WHERE LG__c IN: newDays.keySet() AND (Status_in_LG__c = 'Registered' OR Status_in_LG__c = 'Completed')]){
					
					if(ls.Student_Course_End_Date__c == rOlds.get(ls.LG__c).LG_End_Date__c){
						ls.Student_Course_End_Date__c = newDays.get(ls.LG__c);
						lgStudent2Up.add(ls);
					}
				}
			}			
			
			if(!lessDays.isEmpty()){
				
				Map<Id, LG__c> rOlds = (Map<Id, LG__c>)trigger.oldMap;
				for(LG_Student__c ls : [SELECT Id, Student_Course_End_Date__c, LG__c FROM LG_Student__c WHERE LG__c IN: lessDays.keySet() AND Status_in_LG__c = 'Registered']){
					
					if(ls.Student_Course_End_Date__c == rOlds.get(ls.LG__c).LG_End_Date__c){
						ls.Student_Course_End_Date__c = lessDays.get(ls.LG__c);
						lgStudent2Up.add(ls);
					}
				}
			}
			
			if(!lgStudent2Up.isEmpty()){
				update lgStudent2Up;
			}			
		}
	}
	
	/******************************************************************************* 
	Description       : Maintenace LG Lessons and its attendances
						1) If the LG.Group Status change to "Cancelled" and LG.Number of Lessons > 0 and there are LG Lesson with Lesson Date/Hour >= LG End Date
						   1.1) Run process that will delete all LG Lesson and its related LG Student Attendance - Related to the LG Where Lesson Status is Null and Lesson Date/Hour >= LG End Date
						   1.2) The process will also delete the related LG Payments
						2) If LG End date is changed, will create new LG Lessons and LG Student Attendance (same logic as describe above) from the LG End Date- pre value until the new LG End Date   
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Hernan Sinclair         04/12/2016          	 Yaara          		 [SW-18013]
	*******************************************************************************/
	private static Set<Id> lgAlreadyProcecced_LGLessonInsert = new Set<Id>(); 
	public static void maintenaceLGLesson(){
		if( HD_TriggerSettings.IsTriggerActive('maintenaceLGLesson') ){

			Id recTypeLGDemoId = Schema.SObjectType.LG__c.getRecordTypeInfosByName().get('Demo Lesson').getRecordTypeId();
	
			Map<Id, Date> lgIdsWhereDeleteLessons = new Map<Id, Date>();
			Map<Id, Date> lgIdsWhereInsertLessons = new Map<Id, Date>();
			
			Map<Id, Decimal> lgIdsWhereDeleteLessonsByLGLessons = new Map<Id, Decimal>();
			Map<Id, Decimal> lgIdsWhereInsertLessonsByLGLessons = new Map<Id, Decimal>();
			
			for(Integer i=0; i < trigger.size; i++ ){
				
				LG__c r = (LG__c)trigger.new[i];
				LG__c rOld = (LG__c)trigger.old[i];
				
				// Logic to Delete LG Lessons and its related object (LG payment & Attendaces)
				Boolean condition2delete = r.RecordTypeId != recTypeLGDemoId && r.Create_LG_Lessons_By__c != 'Number of Lessons' && r.Number_of_Lessons__c > 0 && rOld.LG_End_Date__c <> r.LG_End_Date__c && rOld.LG_End_Date__c > r.LG_End_Date__c;
				if(condition2delete){
					lgIdsWhereDeleteLessons.put(r.Id, r.LG_End_Date__c);
				}			
				condition2delete = r.RecordTypeId != recTypeLGDemoId && r.Number_of_Lessons__c > 0 &&  rOld.Group_Status__c <> r.Group_Status__c && r.Group_Status__c == 'Cancelled';
				if(condition2delete){
					lgIdsWhereDeleteLessons.put(r.Id, null);
				}
				condition2delete = r.RecordTypeId != recTypeLGDemoId && r.Create_LG_Lessons_By__c == 'Number of Lessons' && r.Number_of_Lessons__c > 0 && rOld.LG_Lessons__c > r.LG_Lessons__c;
				if(condition2delete){
					lgIdsWhereDeleteLessonsByLGLessons.put(r.Id, rOld.LG_Lessons__c - r.LG_Lessons__c);
				}
				
				system.debug('lgAlreadyProcecced_LGLessonInsert: ' + lgAlreadyProcecced_LGLessonInsert);
				
				// Logic for creating new LG Lesson from the new LG End Date
				Boolean condition2insert = r.RecordTypeId != recTypeLGDemoId && r.Create_LG_Lessons_By__c != 'Number of Lessons' && r.Number_of_Lessons__c > 0 && rOld.LG_End_Date__c <> r.LG_End_Date__c && rOld.LG_End_Date__c < r.LG_End_Date__c;
				if(condition2insert && !lgAlreadyProcecced_LGLessonInsert.contains(r.Id)){
					system.debug('r.Id: ' + r.Id);
					lgIdsWhereInsertLessons.put(r.Id, rOld.LG_End_Date__c/*.addDays(1)*/); // since teh LG End Date it's already consider
					lgAlreadyProcecced_LGLessonInsert.add(r.Id);
				}
				
				condition2insert = r.RecordTypeId != recTypeLGDemoId && r.Create_LG_Lessons_By__c == 'Number of Lessons' && r.Number_of_Lessons__c > 0 && rOld.LG_Lessons__c < r.LG_Lessons__c;
				if(condition2insert){
					lgIdsWhereInsertLessonsByLGLessons.put(r.Id, r.LG_Lessons__c);
					lgAlreadyProcecced_LGLessonInsert.add(r.Id);					
				}
			}
			
			Map<Id, LG__c> lg2UpdateEndDate = new Map<Id, LG__c>();
			
			// Deletes
			List<LG_Lesson__c> lessons2Del = new List<LG_Lesson__c>();
			List<LG_Student_Attendance__c> studentsAtt2Del = new List<LG_Student_Attendance__c>();
			
			// By LG End Date
			if(!lgIdsWhereDeleteLessons.isEmpty()){
				for(LG_Lesson__c ls : [SELECT Id, LG__c, Lesson_Date_Hour__c, (Select Id, LG_Payment__c, LG_Student__c, LG_Student__r.LG__r.CurrencyIsoCode From LG_Students_Attendance__r) FROM LG_Lesson__c WHERE LG__c IN: lgIdsWhereDeleteLessons.keySet() AND Lesson_Status__c = null]){
					if(lgIdsWhereDeleteLessons.get(ls.LG__c) == null || (ls.Lesson_Date_Hour__c <> null && ls.Lesson_Date_Hour__c.dateGMT() > lgIdsWhereDeleteLessons.get(ls.LG__c))){
						studentsAtt2Del.addAll(ls.LG_Students_Attendance__r);
						lessons2Del.add(ls);
						
						system.debug(system.LoggingLevel.INFO, 'ls: ' + ls);
						system.debug(system.LoggingLevel.INFO, 'ls.LG_Students_Attendance__r: ' + ls.LG_Students_Attendance__r);
					}	
				}
			}
			
			// By LG Lesson
			if(!lgIdsWhereDeleteLessonsByLGLessons.isEmpty()){
				for(LG_Lesson__c ls : [SELECT Id, LG__c, Lesson_Date_Hour__c, (Select Id, LG_Payment__c, LG_Student__c, LG_Student__r.LG__r.CurrencyIsoCode From LG_Students_Attendance__r) FROM LG_Lesson__c WHERE LG__c IN: lgIdsWhereDeleteLessonsByLGLessons.keySet() AND Lesson_Status__c = null ORDER BY Lesson_Date_Hour__c Desc]){
					if(lgIdsWhereDeleteLessonsByLGLessons.get(ls.LG__c) >= 0){ // We should delete the latest lg lesson not initiated yet and that count into the LG Lesson number (skiping day off)
						if(lgIdsWhereDeleteLessonsByLGLessons.get(ls.LG__c) > 0){
							studentsAtt2Del.addAll(ls.LG_Students_Attendance__r);
							lessons2Del.add(ls);
						}else{
							lg2UpdateEndDate.put(ls.LG__c, new LG__c(id=ls.LG__c, Name = String.valueOf(Trigger.newMap.get(ls.LG__c).get('Name')), LG_End_Date__c = Date.valueOf(ls.Lesson_Date_Hour__c)));	
						}
						lgIdsWhereDeleteLessonsByLGLessons.put(ls.LG__c, lgIdsWhereDeleteLessonsByLGLessons.get(ls.LG__c)-1);
					}
				}
			}
			
			if(!lessons2Del.isEmpty()){
				
				// delete the attendances (and get the remain LG Payments)
				Map<String, LG_Payment__c> p2Ins = LGHelperMethods.deleteLGStudentAttendanceAndItsLGPayments(studentsAtt2Del, true, null);
	    		
	    		system.debug(system.LoggingLevel.INFO, 'p2Ins: ' + p2Ins);
				
	    		// delete the leassons
	    		delete lessons2Del;      		
	    		if(!p2Ins.isEmpty()){
	    			// insert the remains LG Payment
	    			
	    			Set<String> existingPayments = new Set<String>();
	    			for(LG_Payment__c lgP : [SELECT Id, LG__c, LG_Student__c, Planned_Date__c FROM LG_Payment__c WHERE LG__c IN : lgIdsWhereDeleteLessons.keySet() OR LG__c IN : lgIdsWhereDeleteLessonsByLGLessons.keySet()]){
	    				existingPayments.add(lgP.LG__c + '_' + lgP.LG_Student__c + '_' + lgP.Planned_Date__c);	
	    			}
	    			
	    			List<LG_Payment__c> lgP2Ins = new List<LG_Payment__c>();
	    			for(LG_Payment__c lgP : p2Ins.values()){
	    				if(!existingPayments.contains(lgP.LG__c + '_' + lgP.LG_Student__c + '_' + lgP.Planned_Date__c)){ // To avoid duplication
	    					lgP2Ins.add(lgP);
	    				}
	    			}
	    			
	    			insert lgP2Ins;
	    			system.debug(system.LoggingLevel.INFO, 'lgP2Ins: ' + lgP2Ins);
	    		} 
			}
			
			
			// Inserts
			List<LG_Lesson__c> allLessons2InsertTemp = new List<LG_Lesson__c>();
			
			// By End Date
			system.debug(system.LoggingLevel.INFO, 'lgIdsWhereInsertLessons: ' + lgIdsWhereInsertLessons);
			if(!lgIdsWhereInsertLessons.isEmpty()){
				
				for(Id lgId : lgIdsWhereInsertLessons.keySet()){
					system.debug(system.LoggingLevel.INFO, 'allLessons2InsertTemp: ' + allLessons2InsertTemp);
					allLessons2InsertTemp.addAll(LGHelperMethods.getAllLessonsDays(lgId, lgIdsWhereInsertLessons.get(lgId)));	
					system.debug(system.LoggingLevel.INFO, 'allLessons2InsertTemp2: ' + allLessons2InsertTemp);
				}
			}
			
			// By LG Lesson 
			if(!lgIdsWhereInsertLessonsByLGLessons.isEmpty()){
				
				for(Id lgId : lgIdsWhereInsertLessonsByLGLessons.keySet()){
					List<LG_Lesson__c> lgLesson2Ins = LGHelperMethods.getAllLessonsDaysByNumberOfLessons(lgId, lgIdsWhereInsertLessonsByLGLessons.get(lgId), null);
					if(!lgLesson2Ins.isEmpty()){
						allLessons2InsertTemp.addAll(lgLesson2Ins);
						// If the new LG lessons are greater that the end date we should update the end date
						if(Date.valueOf(Trigger.newMap.get(lgId).get('LG_End_Date__c')) < Date.valueOf(lgLesson2Ins[lgLesson2Ins.size()-1].Lesson_Date_Hour__c)){
							lg2UpdateEndDate.put(lgId, new LG__c(id=lgId, LG_End_Date__c = Date.valueOf(lgLesson2Ins[lgLesson2Ins.size()-1].Lesson_Date_Hour__c)));
						}
					}		
				}
			}
				
			if(!lg2UpdateEndDate.isEmpty()){
				update lg2UpdateEndDate.values();
			}	
				
			if(!allLessons2InsertTemp.isEmpty()){
					
				Set<String> existingLGdates = new Set<String>();
				for(LG_Lesson__c existingLG : [SELECT Id, LG__c, Lesson_Date_Hour__c FROM LG_Lesson__c WHERE LG__c IN :lgIdsWhereInsertLessons.keySet() OR LG__c IN :lgIdsWhereInsertLessonsByLGLessons.keySet() ]){
					existingLGdates.add(existingLG.Lesson_Date_Hour__c + '_' + existingLG.LG__c);
					system.debug(system.LoggingLevel.INFO, 'xxxxxxxxxxxxx: ' + (existingLG.Lesson_Date_Hour__c + '_' + existingLG.LG__c));
				}					
				
				List<LG_Lesson__c> allLessons2Insert = new List<LG_Lesson__c>();
				for(LG_Lesson__c l : allLessons2InsertTemp){ // Remove the duplicate LG Lessons
					system.debug(system.LoggingLevel.INFO, 'l2Ins: ' + l); 
					if(!existingLGdates.contains(l.Lesson_Date_Hour__c + '_' + l.LG__c)){
						system.debug(system.LoggingLevel.INFO, 'l2Ins2: ' + l); 
						allLessons2Insert.add(l);
					}
				}
				
				// Active the ability to create new attendances automatically after create the new exteded lessons here...
				// from yaara comment: Create the attendance anyway, 
				// the reason for that is that sometimes they continue to more classes, if they didn't finish the classes in that year, 
				// so all the End Date of the student are not changing according to the new lg end date, but all the registered student 
				// (the students that didn't move or drop-out) are still continue with the class, so we need to create student attendance for them.
// for issue SW-21976 (QA: "Attendance after Student End Date")	
//				LGCreateLessonBatch.notNeed2CheckRangeDateOnNewLesson = true;
				LGCreateLessonBatch.theLessonWasCreatedDueToChangeLGEndDate = true;	
				system.debug(system.LoggingLevel.INFO, 'allLessons2Insert: ' + allLessons2Insert); 
				insert allLessons2Insert;
				LGCreateLessonBatch.theLessonWasCreatedDueToChangeLGEndDate = false;	
//				LGCreateLessonBatch.notNeed2CheckRangeDateOnNewLesson = false; 
			}

		}
	}
	
	/*******************************************************************************  
	Description       : Re Creates LG Payment to LG
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Hernan Sinclair         06/09/2016          	 Yaara          		 [SW-19459]
	2. Hernan Sinclair		   02/20/2017          	 Yaara                   [SW-23715]
	*******************************************************************************/
	public static void recreateLGPayment2LGBillingTypeChange(){
		
		if( HD_TriggerSettings.IsTriggerActive('recreateLGPayment2LGBillingTypeChange') ){
			
			// Getting the profiles that will skip the limitation about maximun 1 month.
			Set<Id> profileWithPermission2CreatePaymentWithoutMonthLimit = new Set<Id>();
			if(HD_Settings_List__c.getInstance('Generate Payment Profiles') <> null){
				for(String profId : HD_Settings_List__c.getInstance('Generate Payment Profiles').Value__c.split(',')){
					profileWithPermission2CreatePaymentWithoutMonthLimit.add(Id.valueOf(profId));
				}
			}			
			
			Set<Id> lgIds = new Set<Id>();
			for(Integer i=0; i < trigger.size; i++ ){
				
				LG__c r 	= (LG__c)trigger.new[i];
				LG__c rOld 	= (LG__c)trigger.old[i];
				
				if(r.LG_Type__c != 'Demo Lesson' && rOld.Billing_Type__c <> null && r.Billing_Type__c <> rOld.Billing_Type__c){
					
					String result;
					if(r.LG_Start_Paying_Date__c <> null && r.LG_Start_Paying_Date__c.addDays(30) < system.today() && !profileWithPermission2CreatePaymentWithoutMonthLimit.contains(Userinfo.getProfileId())){ // Just check the date
						result = Label.Generate_payments_to_LG_days_after_the_LG_Start_paying_Date;
					}
					if(!String.isBlank(result)){
						r.addError(result);
					}else{
						lgIds.add(r.Id);
					}
				}
			}
			
			if(!lgIds.IsEmpty()){
				LGHelperMethods.doRecreateLGPayment2LG(lgIds);
			}
		}
	}
	
	
	/*******************************************************************************  
	Description       : Delete LG Payment to LG Student when the LG End Paying Date has changed for less date  
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Hernan Sinclair         10/31/2016          	 Yaara          		 [SW-21977]
	2. Hernan Sinclair         03/29/2017          	 Dafna          		 [SW-24179]
	*******************************************************************************/
	public static void deleteLGPaymentToLG(){
		if( HD_TriggerSettings.IsTriggerActive('deleteLGPaymentToLG') ){

			Id recTypeLGDemoId = Schema.SObjectType.LG__c.getRecordTypeInfosByName().get('Demo Lesson').getRecordTypeId();

			Map<Id, Date> lgIdsAndNewEndDate = new Map<Id, Date>(); 
			for(Integer i=0; i < trigger.size; i++ ){
				
				LG__c r = (LG__c)trigger.new[i];
				LG__c rOld = (LG__c)trigger.old[i];
				
				
				Boolean condition =  r.RecordTypeId != recTypeLGDemoId && (r.Declared_Number_of_Students__c > 0 || r.Price_Type__c == 'Per Group');
				condition &= r.LG_Type__c == 'Standard' && r.Group_Status__c == 'Active';
				condition &= r.Billing_Type__c == 'Price per Month' && rOld.LG_End_Paying_Date__c > r.LG_End_Paying_Date__c;
				if(condition){
					lgIdsAndNewEndDate.put(r.Id, r.LG_End_Paying_Date__c);
				}
			}
			
			if(!lgIdsAndNewEndDate.isEmpty()){
				LGHelperMethods.doRemoveLGPaymentToLG(lgIdsAndNewEndDate); 
			}
		}
	}
	
	/*******************************************************************************  
	Description       : ReCreates LG Payment to LG Student
						When the First_Month_Price__c or Last_Month_Price__c has changed
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Hernan Sinclair         04/13/2017          	  Dafna          		 [SW-24275]
	*******************************************************************************/
	public static void reCreateLGPaymentToLGStudent(){
		if( HD_TriggerSettings.IsTriggerActive('reCreateLGPaymentToLGStudent') ){
			Set<Id> lgIds = new Set<Id>();
			Set<Id> lgIdsFirstOrLast = new Set<Id>();
			Set<Id> lgIdsPerMonth = new Set<Id>();
			Set<Id> lgIdsPerSession = new Set<Id>();
			Set<Id> lgIdsPerCourse = new Set<Id>();
			for(Integer i=0; i < trigger.size; i++ ){
				
				LG__c r = (LG__c)trigger.new[i];
				LG__c rOld = (LG__c)trigger.old[i];
				
				Boolean condition = r.Price_Type__c == 'Per Student' && (r.Declared_Number_of_Students__c == null || r.Declared_Number_of_Students__c == 0);
				Boolean conditionChangeMonthPrice = rOld.First_Month_Price__c <> r.First_Month_Price__c/*#3 SW-24275*/ || rOld.Last_Month_Price__c <> r.Last_Month_Price__c/*#3 SW-24275*/;
				Boolean conditionChangePricePerMonth = rOld.Price_per_Month__c <> r.Price_per_Month__c;
				Boolean conditionChangePricePerSession = rOld.Price_per_Session__c <> r.Price_per_Session__c;
				Boolean conditionChangePricePerCourse = rOld.Course_Price__c <> r.Course_Price__c || rOld.Number_of_Payments__c <> r.Number_of_Payments__c || rOld.Gap_between_Price_Payments__c <> r.Gap_between_Price_Payments__c;
				if(condition && (conditionChangeMonthPrice || conditionChangePricePerMonth || conditionChangePricePerSession || conditionChangePricePerCourse)){
					lgIds.add(r.Id);	
				}
				
				if(conditionChangeMonthPrice){
					lgIdsFirstOrLast.add(r.Id);
				}
				
				if(conditionChangePricePerMonth){
					lgIdsPerMonth.add(r.Id);	
				}
				
				if(conditionChangePricePerSession){
					lgIdsPerSession.add(r.Id);	
				}
				
				if(conditionChangePricePerCourse){
					lgIdsPerCourse.add(r.Id);	
				}
			}
			
			if(!lgIds.isEmpty()){
				
				Set<Id> lgStudentIds = new Set<Id>();
				for(LG_Student__c lgS : [SELECT Id, Billing_Type__c, LG__c, LG__r.Price_Type__c, Student_Start_Paying_Date__c FROM LG_Student__c WHERE LG__r.LG_Type__c != 'Demo Lesson' AND Status_in_LG__c = 'Registered' AND LG__c IN: lgIds]){
					
					if(lgIdsFirstOrLast.contains(lgS.LG__c)){
						lgStudentIds.add(lgS.Id);
					}
					
					if(lgIdsPerMonth.contains(lgS.LG__c) && lgS.Billing_Type__c == 'Price Per Month'){
						lgStudentIds.add(lgS.Id);
					}
					
					if(lgIdsPerCourse.contains(lgS.LG__c) && lgS.Billing_Type__c == 'Course Price'){
						lgStudentIds.add(lgS.Id);
					}
					
					if(lgIdsPerSession.contains(lgS.LG__c) && lgS.Billing_Type__c == 'Price per Session'){
						lgStudentIds.add(lgS.Id);
					}
				}
				LGHelperMethods.doRecreateLGPayment2LGStudent(lgStudentIds);
			}
		}
	}
	
	/*******************************************************************************  
	Description       : Creates LG Payment to LG
						When LG.Declared Number of Student is Not Null and LG Type = Standard and (LG.created with Group Status = "Active" or LG. Group Status Change to "Active") and
						(Billing Type  is not Price per Session  OR (Billing Type  is Price per Session and Number of Lessons is not null))
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Hernan Sinclair         03/11/2016          	 Yaara          		 [SW-18006]
	2. Hernan Sinclair         06/07/2016          	 Yaara          		 [SW-19459]		
	3. Hernan Sinclair         06/08/2016          	 Yaara          		 [SW-19454]
	4. Hernan Sinclair         02/16/2017          	 Yaara          		 [SW-23645]
	5. Hernan Sinclair         03/03/2017          	 Yaara          		 [SW-23814]
	6. Hernan Sinclair         04/07/2017          	 Dafna          		 [SW-24275]
	*******************************************************************************/
	public static List<LG__c> lgs2ReCreatedLGPaymentToLG = new List<LG__c>();
	public static Set<Id> lg2ReCalculateLGPayment = new Set<Id>();
	public static void createLGPaymentToLG(){
		if( HD_TriggerSettings.IsTriggerActive('createLGPaymentToLG') ){
			
			Map<Id, LG__c> lg2Process = new Map<Id, LG__c>(); 
			for(Integer i=0; i < trigger.size; i++ ){
				
				LG__c r = (LG__c)trigger.new[i];
				LG__c rOld;
				if(trigger.isUpdate){
					rOld = (LG__c)trigger.old[i];
				}
				
				Boolean condition = r.Declared_Number_of_Students__c > 0;
				condition |= (!condition && r.Price_Type__c == 'Per Group' /*SW-23645*/); 
				condition &= (r.LG_Type__c == 'Standard' && r.Group_Status__c == 'Active');
				condition &= (r.Billing_Type__c == 'Price per Session' || r.Price_Charge__c != null);
				condition &= (r.Billing_Type__c != 'Price per Session' || (r.Billing_Type__c == 'Price per Session' && r.Number_of_Lessons__c > 0 ));
				//condition &= (trigger.isInsert || (trigger.isUpdate && ( (r.Billing_Type__c == 'Course Price' && (/*2.1 SW-24275*/ rOld.Number_of_Payments__c <> r.Number_of_Payments__c || rOld.Gap_between_Price_Payments__c <> r.Gap_between_Price_Payments__c || rOld.Course_Price__c <> r.Course_Price__c)) || (r.Price_Type__c == 'Per Student' && r.Declared_Number_of_Students__c <> rOld.Declared_Number_of_Students__c /*SW-23814*/) || r.Group_Status__c <> rOld.Group_Status__c || r.Price_Charge__c <> rOld.Price_Charge__c || (rOld.Billing_Type__c == null && r.Billing_Type__c != null) || (r.Billing_Type__c == 'Price per Month' && (rOld.LG_End_Paying_Date__c <> r.LG_End_Paying_Date__c || rOld.Price_per_Month__c <> r.Price_per_Month__c/*4.2 SW-24275*/ || rOld.First_Month_Price__c <> r.First_Month_Price__c/*3 SW-24275*/|| rOld.Last_Month_Price__c <> r.Last_Month_Price__c/*3 SW-24275*/)  ) || (r.Billing_Type__c == 'Price per Session' && rOld.Price_per_Session__c <> r.Price_per_Session__c/*4.2 SW-24275*/))));
				if(trigger.isUpdate && condition){ 
					 condition  = r.Billing_Type__c == 'Course Price' && (/*2.1 SW-24275*/ rOld.Number_of_Payments__c <> r.Number_of_Payments__c || rOld.Gap_between_Price_Payments__c <> r.Gap_between_Price_Payments__c || rOld.Course_Price__c <> r.Course_Price__c); 
					 condition |= r.Billing_Type__c == 'Price per Month' && (rOld.LG_End_Paying_Date__c <> r.LG_End_Paying_Date__c || rOld.Price_per_Month__c <> r.Price_per_Month__c/*#4.2 SW-24275*/ || rOld.First_Month_Price__c <> r.First_Month_Price__c/*#3 SW-24275*/|| rOld.Last_Month_Price__c <> r.Last_Month_Price__c/*#3 SW-24275*/); 
					 condition |= r.Billing_Type__c == 'Price per Session' && rOld.Price_per_Session__c <> r.Price_per_Session__c/*#4.2 SW-24275*/;
					 condition |= r.Price_Type__c == 'Per Student' && r.Declared_Number_of_Students__c <> rOld.Declared_Number_of_Students__c /*SW-23814*/; 
					 condition |= r.Group_Status__c <> rOld.Group_Status__c || r.Price_Charge__c <> rOld.Price_Charge__c || rOld.Billing_Type__c == null && r.Billing_Type__c != null;
					 
					 if(lg2ReCalculateLGPayment.contains(r.Id)){ // Was already considerated...we should avoid recursion.
					 	lg2ReCalculateLGPayment.remove(r.Id);
					 }else if(condition){ // We will re create their LG Payments.
					 	lg2ReCalculateLGPayment.add(r.Id);
					 }	
				}else if(condition){ // On insert not need to re calculate
					lg2Process.put(r.Id, r);
				}
			}
			
			if(!lgs2ReCreatedLGPaymentToLG.isEmpty()){ // SW-19459
				for(LG__c lg : lgs2ReCreatedLGPaymentToLG){	
					lg2Process.put(lg.Id, lg);
				}	
				lgs2ReCreatedLGPaymentToLG.clear();
			}
			
			if(!lg2ReCalculateLGPayment.isEmpty()){ // From update we will call the re calculation...
				LGHelperMethods.doRecreateLGPayment2LG(lg2ReCalculateLGPayment);
			}
			
			Map<String, LG_Payment__c> existingLGPaymentToLG = new Map<String, LG_Payment__c>();
			List<LG_Payment__c> r2Insert = new List<LG_Payment__c>();
			if(!lg2Process.isEmpty()){
				
				for(LG_Payment__c p : [SELECT Id, LG__c, Planned_Date__c FROM LG_Payment__c WHERE LG__c IN : lg2Process.KeySet()]){
					existingLGPaymentToLG.put(p.LG__c+'_'+p.Planned_Date__c, p);
				}
			
				
			
				Set<Id> lgWithBillingSession = new Set<Id>();
				for(LG__c lg : lg2Process.values()){
					
					Date paymentDate = lg.LG_Start_Paying_Date__c;
					if(paymentDate == null){
						paymentDate = lg.LG_Start_Date__c;
					}					
				
					if(lg.Billing_Type__c == 'Course Price'){					
						
						if(lg.Number_of_Payments__c == null || lg.Number_of_Payments__c == 0){
							lg.Number_of_Payments__c = 1;
						}	
						
						Decimal gapBetweenPayments = 1;
						if(lg.Gap_between_Price_Payments__c <> null){
							gapBetweenPayments = lg.Gap_between_Price_Payments__c;
						}
						
						Double Price_for_Payment = lg.Price_for_Payment__c; // lg.Price_Charge__c /* No need to multiply by Declare number of Students (QA-SW-18006) * lg.Declared_Number_of_Students__c; 
						for(Integer i = 0; i < lg.Number_of_Payments__c; i++){
							r2Insert.add(new LG_Payment__c(LG__c = lg.Id, CurrencyIsoCode = lg.CurrencyIsoCode, Payment_Type__c = 'Standard', Payment_Method__c = lg.Payment_Method__c==null?'Credit Card':lg.Payment_Method__c, Planned_Date__c = paymentDate, Planned_Price__c = Price_for_Payment)); //s.Price_for_Payment__c/s.Number_of_Payments__c));	
							paymentDate = paymentDate.addMonths(Integer.valueOf(gapBetweenPayments));
						}
						
					}else if(lg.Billing_Type__c == 'Price per Month'){
						
						Double Price_for_Payment = lg.Price_for_Payment__c; // No need to multiply by Declare number of Students (QA-SW-18006) * lg.Declared_Number_of_Students__c ;
						if(lg.First_Month_Price__c <> null){ // Update First Payment is it's on the start middle of the month
							r2Insert.add(new LG_Payment__c(LG__c = lg.Id, CurrencyIsoCode = lg.CurrencyIsoCode, Payment_Type__c = 'Standard', Payment_Method__c = lg.Payment_Method__c==null?'Credit Card':lg.Payment_Method__c, Planned_Date__c = paymentDate, Planned_Price__c = lg.First_Month_Price__c));
							paymentDate = paymentDate.addMonths(1);	
						}						
						
						Date endPaymentDate = lg.LG_End_Paying_Date__c;
						if(endPaymentDate == null){
							endPaymentDate = lg.LG_End_Date__c;
						}
						
						while(paymentDate <= endPaymentDate){
							r2Insert.add(new LG_Payment__c(LG__c = lg.Id, CurrencyIsoCode = lg.CurrencyIsoCode, Payment_Type__c = 'Standard', Payment_Method__c = lg.Payment_Method__c==null?'Credit Card':lg.Payment_Method__c, Planned_Date__c = paymentDate, Planned_Price__c = Price_for_Payment));
							paymentDate = paymentDate.addMonths(1);
						}
						
						if(lg.Last_Month_Price__c <> null){ // Update First Payment is it's on the last middle of the month
							r2Insert[r2Insert.size()-1].Planned_Price__c = lg.Last_Month_Price__c;
						}					
					}else if(lg.Billing_Type__c == 'Price per Session'){
						
						lgWithBillingSession.add(lg.Id);
					}				
				}	
				
				if(!lgWithBillingSession.isEmpty()){
					r2Insert.addAll(LGHelperMethods.getLGPaymentByToLGSessions(lgWithBillingSession, null, null));
				}		
			}
			
			if(!r2Insert.isEmpty()){
				
				List<LG_Payment__c> lgPayment2Insert = new List<LG_Payment__c>();
				List<LG_Payment__c> lgPayment2Update = new List<LG_Payment__c>();
				for(LG_Payment__c p : r2Insert){
					if(!existingLGPaymentToLG.containsKey(p.LG__c+'_'+p.Planned_Date__c)){
						lgPayment2Insert.add(p);
						system.debug('p2Ins: ' + p);
					}else{
						p.Id = existingLGPaymentToLG.get(p.LG__c+'_'+p.Planned_Date__c).Id;
						lgPayment2Update.add(p);
						system.debug('p2Up: ' + p);
					}
				}
				
				if(!lgPayment2Insert.isEmpty()){
					insert lgPayment2Insert;  // This will fire the trigger that will calculate the related Vat and Discount for each payment created...
				}
				if(!lgPayment2Update.isEmpty()){
					update lgPayment2Update;
				}
			}	

		}		
	}	
	
	
	/*******************************************************************************  
	Description       : Creates/Update/Deete LG Payment to LG Student
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Hernan Sinclair         10/31/2016          	 Yaara          		 [SW-21977]
	*******************************************************************************/
	public static void maintenanceLGPaymentToLGStudents(){
		if( HD_TriggerSettings.IsTriggerActive('maintenanceLGPaymentToLGStudents') ){
			
			Id recTypeLGDemoId = Schema.SObjectType.LG__c.getRecordTypeInfosByName().get('Demo Lesson').getRecordTypeId();
			
			Map<Id, Date> lg2Process = new Map<Id,Date>(); 
			for(Integer i=0; i < trigger.size; i++ ){
				
				LG__c r = (LG__c)trigger.new[i];
				LG__c rOld = (LG__c)trigger.old[i];
				
				Boolean condition = r.RecordTypeId != recTypeLGDemoId && (r.Declared_Number_of_Students__c == null || r.Declared_Number_of_Students__c == 0);
				condition &= rOld.LG_End_Paying_Date__c <> r.LG_End_Paying_Date__c;
				if(condition){
					lg2Process.put(r.Id, rOld.LG_End_Paying_Date__c);
				}
			}
			
			if(!lg2Process.isEmpty()){  
				LGHelperMethods.doUpdateLGEndPayingDate(lg2Process);
			}
		}
	}
	
	/******************************************************************************* 
	Description       : Creates Group Income Per Month from the LG
						new LG with Group Status = Active or change Group Status = Active and
						Fixed Number of Students = True and
						Declared Number of Students <> Null/0
						
						Then we create Group Income Per Month for each month of the LG
						
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Sergio 		         03/18/2016          	 Yaara          		 [SW-18018]
	2. hernan 		         01/25/2017          	 Yaara          		 [SW-23388]
	3. Hernan Sinclair       03/03/2017          	 Yaara          		 [SW-23814]
	*******************************************************************************/
	public static Set<Id> lgsNotToRun = new Set<Id>();
	public static void LG_CreateGroupIncomePerMonth(){
		if( HD_TriggerSettings.IsTriggerActive('LG_CreateGroupIncomePerMonth') ){

			//try{
				
				List<Group_Income_Per_Month__c> gm2Ins = new List<Group_Income_Per_Month__c>();
				Id recordTypeId = Schema.SObjectType.Group_Income_Per_Month__c.getRecordTypeInfosByName().get('Calculated Student').getRecordTypeId();
				Set<Id> lg2Del = new Set<Id>();
				Set<Id> lgCheckGIPM = new Set<Id>();
				
				for( Integer i=0; i < trigger.size; i++ ){
					LG__c lg = (LG__c) trigger.new[i];
					
					Boolean gralCond = (lg.Price_Type__c == 'Per Group' && lg.Declared_Number_of_Students__c > 0 /*new condition SW-23645*/) || (lg.Price_Type__c == 'Per Student' && lg.Declared_Number_of_Students__c > 0 /*SW-23388*/);
					
					Boolean baseCondition = String.isNotBlank(lg.Group_Status__c) && lg.Group_Status__c.equalsIgnoreCase('Active') ;
					//condition &= lg.Fixed_Number_of_Students__c == true && lg.Declared_Number_of_Students__c > 0;
					baseCondition &= gralCond;
					
					//Dealing with recursivity
					baseCondition &= !lgsNotToRun.contains( lg.Id );
					
					Boolean endDateUpdate_cnd = baseCondition;
					endDateUpdate_cnd &= trigger.isUpdate && lg.LG_End_Date__c != trigger.old[i].get('LG_End_Date__c');
					endDateUpdate_cnd &= gralCond;
					
                    /*SW-23814*/
                    Boolean decNumStdCond = trigger.isUpdate && lg.Declared_Number_of_Students__c != null && lg.Declared_Number_of_Students__c > 0 && (trigger.old[i].get('Declared_Number_of_Students__c') == null || trigger.old[i].get('Declared_Number_of_Students__c') == 0);
                    decNumStdCond |= trigger.isUpdate && (lg.Declared_Number_of_Students__c == null || lg.Declared_Number_of_Students__c == 0) && ( trigger.old[i].get('Declared_Number_of_Students__c') != null && Integer.valueOf(trigger.old[i].get('Declared_Number_of_Students__c')) > 0 );
                    
					Boolean createCondition = baseCondition;
					createCondition &= trigger.isInsert || ( trigger.isUpdate && (lg.Group_Status__c != trigger.old[i].get('Group_Status__c') || ( decNumStdCond /*SW-23814*/ ) ) );
					
                    if( createCondition && !endDateUpdate_cnd ){
                        //If only Group_Status__c is changing to Active, but there is no change to Dates,
                        //then we need to make sure that the GIPM don't already exist before creating them
                        lgCheckGIPM.add( lg.Id );
                    }
                    
                    Boolean deleteCondition = createCondition && decNumStdCond;
                    deleteCondition |= endDateUpdate_cnd;
                    
                    if( deleteCondition ){
                        lg2Del.add( lg.Id );
                    }
                    
					if( endDateUpdate_cnd ){
						createCondition = true;
					}
					
					if( createCondition ){
						Group_Income_Per_Month__c gm;
						
						for(Date dt = lg.LG_Start_Date__c; dt < lg.LG_End_Date__c; dt = dt.addMonths(1) ){
							gm = new Group_Income_Per_Month__c();
							gm.RecordTypeId = recordTypeId;
							gm.Agreement__c = lg.Agreement__c;
							gm.LG__c = lg.Id;
							
							if( dt == lg.LG_Start_Date__c ){
								gm.Royalty_Start_Date__c = lg.LG_Start_Date__c;
								dt = lg.LG_Start_Date__c.toStartOfMonth(); // SW-25293
							}else{
								gm.Royalty_Start_Date__c = Date.newInstance( dt.year(), dt.month(), 1 );
								dt = gm.Royalty_Start_Date__c;
							}
							gm2Ins.add(gm);
							
							lgsNotToRun.add( lg.Id );
						}
						
						if( gm != null ){
							gm.Royalty_End_Date__c = lg.LG_End_Date__c;
						}
					}
				}
				
				if( lg2Del.isEmpty() == false ){
					delete [SELECT Id FROM Group_Income_Per_Month__c WHERE LG__c IN :lg2Del AND RecordTypeId = :recordTypeId];
				}
				
				if( gm2Ins.isEmpty() == false ){
                    if( !lgCheckGIPM.isEmpty() ){
                        for( Group_Income_Per_Month__c gm : [SELECT Id, LG__c FROM Group_Income_Per_Month__c WHERE LG__c IN :lgCheckGIPM AND RecordTypeId = :recordTypeId ] ){
                            lgCheckGIPM.remove( gm.LG__c );
                        }
                        
                        for( Integer i = 0; i < gm2Ins.size(); i++ ){
                            if( !lgCheckGIPM.contains(gm2Ins[i].LG__c ) ){
                                gm2Ins.remove(i);
                                i--;
                            }
                        }
                    }
                    
					insert gm2Ins;
				}
			/*}catch(Exception e){
				trigger.new[0].addError( e.getMessage() );
			}*/

		}
	}
	
	
	/******************************************************************************* 
	Description       : Delete Group Income Per Month from the LG
						LG.Group Status change to Cancelled and LG End Date is changed and there are Group Income Per Month related to LG
						
						Then we delete Group Income Per Month for each month after the new End Date
						
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Sergio 		         03/18/2016          	 Yaara          		 [SW-18018]
	*******************************************************************************/
	public static void LG_DeleteGroupIncomePerMonth(){
		if( HD_TriggerSettings.IsTriggerActive('LG_DeleteGroupIncomePerMonth') ){

			try{
				Map<Id, LG__c> lgMap = new Map<Id, LG__c>();
				
				for( Integer i=0; i < trigger.size; i++ ){
					LG__c lg = (LG__c) trigger.new[i];
					
					Boolean condition = String.isNotBlank(lg.Group_Status__c) && lg.Group_Status__c.equalsIgnoreCase('Cancelled') ;
					condition &= lg.LG_End_Date__c != trigger.old[i].get('LG_End_Date__c');
					
					if( condition ){
						lgMap.put( lg.Id, lg );
					}
				}
				
				if( lgMap.isEmpty() == false ){
					
					List<Group_Income_Per_Month__c> gm2Del = new List<Group_Income_Per_Month__c>();
					List<Group_Income_Per_Month__c> gm2Upd = new List<Group_Income_Per_Month__c>();
					
					for( Group_Income_Per_Month__c gm : [SELECT Id, LG__c, Royalty_Start_Date__c FROM Group_Income_Per_Month__c WHERE LG__c IN :lgMap.keySet() ] ){
						LG__c lg = lgMap.get(gm.LG__c);
						
						//Same month and year
						if( gm.Royalty_Start_Date__c.month() == lg.LG_End_Date__c.month() && gm.Royalty_Start_Date__c.year() == lg.LG_End_Date__c.year() ){
							gm.Royalty_End_Date__c = lg.LG_End_Date__c;
							gm2Upd.add(gm);
						}else if( gm.Royalty_Start_Date__c > lg.LG_End_Date__c ){
							gm2Del.add(gm);
						}
					}
					
					if( gm2Del.isEmpty() == false ){
						delete gm2Del;
					}
					
					if( gm2Upd.isEmpty() == false ){
						update gm2Upd;
					}
				}
			}catch(Exception e){
				trigger.new[0].addError(e.getMessage());
			}

		}
	}

	/******************************************************************************* 
	Description       : Check for LG teachers qualifications and update the flag in LG.Teacher_is_not_Qualified_for_Base_Course__c
						
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez	         13/04/2016          	 Yaara          		 [SW-18850]
	*******************************************************************************/

	public static void LG_checkTeacherQualifications(){
		if( HD_TriggerSettings.IsTriggerActive('LG_checkTeacherQualifications') ){
			
			Map<Id, LG__c> teacherlgMap = new Map<Id,LG__c>();
			Set<String> baseCourceNames = new Set<String>();
			for(Integer i = 0; i < trigger.size; i++ ){
				LG__c newLG = (LG__c) trigger.new[i];
				if(Trigger.isInsert && newLG.Teacher__c != null){
					
					teacherlgMap.put(newLG.Teacher__c, new LG__c(Id = newLG.Id, Teacher_is_not_Qualified_for_Base_Course__c = true));
					baseCourceNames.add(newLG.Base_Course__c);
				}else if(Trigger.isUpdate){
					LG__c oldLG = (LG__c) trigger.old[i];
					if(newLG.Teacher__c != null && oldLG.Teacher__c != newLG.Teacher__c){
						teacherlgMap.put(newLG.Teacher__c, new LG__c(Id = newLG.Id, Teacher_is_not_Qualified_for_Base_Course__c = true));
						baseCourceNames.add(newLG.Base_Course__c);
					}
				}
			}

			if(!teacherlgMap.isEmpty()){
				for(Teacher_Qualification__c teacherQ : [SELECT Id, Teacher__c FROM Teacher_Qualification__c WHERE Teacher__c IN :teacherlgMap.keySet() AND Base_Course__r.Name IN :baseCourceNames ]){
					teacherlgMap.get(teacherQ.Teacher__c).Teacher_is_not_Qualified_for_Base_Course__c = false;				
				}			

				update teacherlgMap.values();
			}

		}
	}
	
	/******************************************************************************* 
	Description       : When LG.Teacher is change
						1. If there is LG_Days_Hours__c, connected to this LG and LG_Days_Hours__c.Teacher = to the LG - Previouse Teacher
						Update LG_Days_Hours__c.Teacher to the new LG.Teacher.

						2. If there are LG_Lesson__c connected to the LG with Lesson_Teacher__c = Previouse LG.Teacher
						Change the Lesson_Teacher__c but obly to LG_Lesson__c with Lesson_Date_Hour__c >= Today()
 
						
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Hernan Sinclair        14/06/2016          	 Yaara          		 [SW-19881]
	*******************************************************************************/
	public static void updateRelatedRecordsOnChangeLGTeacher(){
		if( HD_TriggerSettings.IsTriggerActive('updateRelatedRecordsOnChangeLGTeacher') ){
			
			Map<Id, List<Id>> lgThatHasChangedItsTeacher = new Map<Id, List<Id>>();
			for(Integer i = 0; i < trigger.size; i++ ){
				LG__c newLG = (LG__c) trigger.new[i];
				LG__c oldLG = (LG__c) trigger.old[i];
				if(oldLG.Teacher__c <> newLG.Teacher__c){
					lgThatHasChangedItsTeacher.put(newLG.Id, new List<Id>{oldLG.Teacher__c,newLG.Teacher__c});
				}
			}

			if(!lgThatHasChangedItsTeacher.isEmpty()){
				List<LG_Lesson__c> lgL2Up = new List<LG_Lesson__c>();
				List<LG_Days_Hours__c> lgDH2Up = new List<LG_Days_Hours__c>();
				for(LG__c lg : [SELECT Id, (Select Id, Lesson_Teacher__c FROM LG_Lessons__r WHERE Lesson_Date_Hour__c >= TODAY), (Select Id, Teacher__c From LG_Days_Hours__r) FROM LG__c WHERE id IN: lgThatHasChangedItsTeacher.keySet()]){
					
					for(LG_Lesson__c lgL : lg.LG_Lessons__r){
						if(lgL.Lesson_Teacher__c != null && lgThatHasChangedItsTeacher.get(lg.Id)[0] == lgL.Lesson_Teacher__c){
							lgL.Lesson_Teacher__c = lgThatHasChangedItsTeacher.get(lg.Id)[1];
							lgL2Up.add(lgL);
						}
					}
					
					for(LG_Days_Hours__c lgHD : lg.LG_Days_Hours__r){
						if(lgHD.Teacher__c != null && lgThatHasChangedItsTeacher.get(lg.Id)[0] == lgHD.Teacher__c){
							lgHD.Teacher__c = lgThatHasChangedItsTeacher.get(lg.Id)[1];
							lgDH2Up.add(lgHD);
						}
					}						
				}
				
				if(!lgL2Up.isEmpty()){
					update lgL2Up;
				}
				
				if(!lgDH2Up.isEmpty()){
					update lgDH2Up;
				}
			}

		}
	}
	
	/******************************************************************************* 
	Description       : Maintenance the LG Payment / GIPM records when the LG "Declared_Number_of_Students__c" field is being changed
						from Null/0 to >0 or when from >0 to 0.
 
						
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Hernan Sinclair        03/03/2017          	 Yaara          		 [SW-23814]
	*******************************************************************************/
	public static void maintenanceLGPaymentsAndGIMRecordsOnDeclaredNroChanged(){
		
		if( HD_TriggerSettings.IsTriggerActive('updateRelatedRecordsOnChangeLGTeacher') ){
			
			Set<Id> lgThatHasChangedItsDeclaredNroToNullZero = new Set<Id>();
			Set<Id> lgThatHasChangedItsDeclaredNroFromNullZero = new Set<Id>();
			
			for(Integer i = 0; i < trigger.size; i++ ){
				
				LG__c newLG = (LG__c) trigger.new[i];
				LG__c oldLG = (LG__c) trigger.old[i];
				
				Boolean condition = oldLG.Declared_Number_of_Students__c <> newLG.Declared_Number_of_Students__c;
				Boolean conditionFromNullZero = condition && (oldLG.Declared_Number_of_Students__c == 0 || oldLG.Declared_Number_of_Students__c == null) && newLG.Declared_Number_of_Students__c > 0; 
				Boolean conditionToNullZero   = condition && !(oldLG.Declared_Number_of_Students__c == 0 || oldLG.Declared_Number_of_Students__c == null) && (newLG.Declared_Number_of_Students__c == 0 || newLG.Declared_Number_of_Students__c == null);
				
				if(conditionFromNullZero){
					lgThatHasChangedItsDeclaredNroFromNullZero.add(newLG.Id); // has changed to greater than 0
				}
				
				if(conditionToNullZero){
					lgThatHasChangedItsDeclaredNroToNullZero.add(newLG.Id); // has changed to 0
				}				
			}
			
			if(!lgThatHasChangedItsDeclaredNroFromNullZero.isEmpty() || !lgThatHasChangedItsDeclaredNroToNullZero.isEmpty()){
			
				system.debug('lgThatHasChangedItsDeclaredNroFromNullZero: ' + lgThatHasChangedItsDeclaredNroFromNullZero);
				system.debug('lgThatHasChangedItsDeclaredNroToNullZero: ' + lgThatHasChangedItsDeclaredNroToNullZero);
				
				Set<Id> lgThatHasChangedItsDeclaredNroToNullZero_PerStudent = new Set<Id>();
				Id recordTypeId = Schema.SObjectType.Group_Income_Per_Month__c.getRecordTypeInfosByName().get('Calculated Student').getRecordTypeId();
				List<LG_Payment__c> lgPayments2Del = new List<LG_Payment__c>();
				List<Group_Income_Per_Month__c> gipm2Del = new List<Group_Income_Per_Month__c>();								 
				for(LG__c lg : [SELECT Id, Price_Type__c, (SELECT Id, Actual_Price__c FROM LG_Payments__r), (SELECT Id, RecordTypeId FROM Royalties_Month_Students__r) FROM LG__c WHERE (Id IN: lgThatHasChangedItsDeclaredNroFromNullZero OR Id IN: lgThatHasChangedItsDeclaredNroToNullZero)]){
					
					Boolean couldContinue = true;
					if(lg.Price_Type__c == 'Per Student'){
						// Validate the requested validation criteria about if exist or not LG Payment with Actual_Price__c > 0.
						
						if(lgThatHasChangedItsDeclaredNroToNullZero.contains(lg.Id)){
							lgThatHasChangedItsDeclaredNroToNullZero_PerStudent.add(lg.Id);
						}
						
						Boolean needs2DeleteRecords = true;	
						for(LG_Payment__c lgPayment : lg.LG_Payments__r){
							
							if(lgPayment.Actual_Price__c > 0){
								
								needs2DeleteRecords = false;
								// adding the error validation requested.
								trigger.newMap.get(lg.Id).addError(Label.LG_Payment_Amount_Paid_Error_Message);
								
								// will not processing the restricted LG records by the VR
								lgThatHasChangedItsDeclaredNroFromNullZero.remove(lg.Id);
								lgThatHasChangedItsDeclaredNroToNullZero.remove(lg.Id);	
								couldContinue = false;
								break;
							}
						}
						
						if(needs2DeleteRecords){
							lgPayments2Del.addALL(lg.LG_Payments__r);
						}
					}
					
					if(couldContinue){
						// In case that we didn't reach the validation about Actual_Price__c.
						
						for(Group_Income_Per_Month__c gipm : lg.Royalties_Month_Students__r){
							
							Boolean condition2Del = gipm.RecordTypeId == recordTypeId; 
							condition2Del &= (lgThatHasChangedItsDeclaredNroToNullZero.contains(lg.Id) || lgThatHasChangedItsDeclaredNroFromNullZero.contains(lg.Id));   
							if(condition2Del){
								gipm2Del.add(gipm);
							}
						}	
					}				
				}	
				
				// Deleting the records and we will create again consider the new scenario (field value).
				if(!gipm2Del.isEmpty()){
					delete gipm2Del;
				}
				
				if(!lgPayments2Del.isEmpty()){
					delete lgPayments2Del;
				}
				
				
				//>>> Now we need to re create the LG Payments for LG Per Student and its student GIPM
				
				// 1 - Re Create the LG Payment to LG Students (considering the Declared_Number_of_Students__c as Null/Zero)
				system.debug('lgThatHasChangedItsDeclaredNroToNullZero_PerStudent: ' + lgThatHasChangedItsDeclaredNroToNullZero_PerStudent);
				if(!lgThatHasChangedItsDeclaredNroToNullZero_PerStudent.isEmpty()){
					
					Set<Id> lgStudentIds = new Set<Id>();
					for(LG_Student__c lgS : [SELECT Id, LG__r.Price_Type__c, Student_Start_Paying_Date__c FROM LG_Student__c WHERE LG__r.LG_Type__c != 'Demo Lesson' AND Status_in_LG__c = 'Registered' AND LG__c IN: lgThatHasChangedItsDeclaredNroToNullZero_PerStudent]){
						lgStudentIds.add(lgS.Id);
					}
					LGHelperMethods.doRecreateLGPayment2LGStudent(lgStudentIds);
				}
				
				// 2 - Re Create the LG Payment to LG Students (considering the Declared_Number_of_Students__c as NOT(Null/Zero))
				// Comment this scenario was consider on the method "createLGPaymentToLG" where we included an additional criteria when 
				// the Declared_Number_of_Students__c is being changed.
				
			 	// The GIPM (when Declared_Number_of_Students__c > 0) will be created when the method "LG_CreateGroupIncomePerMonth" take place during the execution trigger order .		
				// Now, the GIPM (when Declared_Number_of_Students__c = 0/null) will be created using the method "LG_Student_CreateGroupIncomePerMonth_Helper" with our explicit call.
				
				if(!lgThatHasChangedItsDeclaredNroToNullZero.isEmpty()){
					
					Map<Id, List<LG_Student__c>> studentMap = new Map<Id, List<LG_Student__c>>();
					Set<Id> contactIds = new Set<Id>();
					
					for(LG_Student__c student : [SELECT Id, LG__c, Student__c, Student_Course_Start_Date__c, Student_Course_End_Date__c FROM LG_Student__c WHERE Status_in_LG__c = 'Registered' AND LG__c IN : lgThatHasChangedItsDeclaredNroToNullZero]){
						
						if(!studentMap.containsKey(student.LG__c)){
							studentMap.put(student.LG__c, new List<LG_Student__c>());
						}					
						studentMap.get(student.LG__c).add(student);
						contactIds.add(student.Student__c);
					}
					
					if(!studentMap.isEmpty()){
						LG_Student_TriggerHandler.LG_Student_CreateGroupIncomePerMonth_Helper(studentMap, contactIds);
					}
				}
				
				
				/*
				Boolean condition = (r.Declared_Number_of_Students__c != null && r.Declared_Number_of_Students__c != 0);
				condition |= (!condition && r.Price_Type__c == 'Per Group'); // New condition SW-23645
				
				==> LG Payment2LG
				
				LG Payment2LGStudent
				(Declared_Number_of_Students__c = NULL OR Declared_Number_of_Students__c = 0) AND Price_Type__c = 'Per Student'
				
				==> LG Payment2LG
				*/
			}
		}
	}
}