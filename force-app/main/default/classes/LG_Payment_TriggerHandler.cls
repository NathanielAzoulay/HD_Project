/******************************************************************************* 
Name              : LG_Payment_TriggerHandler
Description       : Handler the before/after trigger on LG Payment
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Nicolas         	02/29/2016          	
*******************************************************************************/
/*
	Important note about Payment:
	
	In the 3 cases where you calculate payments for Group, the Group_Status__c should be 'Active'
		Price Type = Per Group + Declared Number of payments >0
		Price Type = Per Group + Declared Number of payments = Null/0
		Price Type = Per Studenr + Declared Number of payments >0
	
	In the case where you calculate payments for Student, the Group_Status__c is not relevant, only LG_Student__c.Status_in_LG = "Registered"
	
		Price Type = Per Student + Declared Number of payments = Null/0

*/
public class LG_Payment_TriggerHandler {
	
	public static void executeTriggerHandler(){
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		
		if (Trigger.isBefore && Trigger.isInsert) // Before Update
		{
			updateLGStudentPaymentOnInsert();
		}
		/*else if (Trigger.isBefore && Trigger.isUpdate) // Before Insert
		{
			
		}
		*/
		else if (Trigger.isBefore && Trigger.isDelete) // Before Delete
		{
			deleteIncomeGroupOnPaymentDel();
		}
		
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		
		
		//else 
		if (Trigger.isAfter && Trigger.isInsert) // After Update
		{
			updateLGStudentAttendanceFromPayment();
			LG_Payment_CreateGroupIncomePerMonth();
		}
		
		else if (Trigger.isAfter && Trigger.isUpdate) // After Insert
		{
			updateLGStudentAttendanceFromPayment();
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
	Description       : Update LG Payment Vat/Discount
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Hernan 		         02/29/2016          	 Yaara          		 [SW-18004]
	2. Hernan 		         03/11/2016          	 Yaara          		 [SW-18006]
	3. Hernan 		         04/07/2016          	 Yaara          		 [SW-18007] -> Allowing execute the logic from lgPaymentUpdated set
	4. Hernan 		         04/03/2017          	 Daftna          		 [SW-24329] -> Updating Discount logic
	*******************************************************************************/
	public static Set<Id> lgPaymentUpdated = new Set<Id>();
	public static List<LG_Payment__c> lgPayment2ApplyDiscount = new List<LG_Payment__c>();
	public static Set<Id> applyOnlyOnDiscountIds = new Set<Id>(); 
	public static Boolean updateLGStudentPaymentOnInsert_HasRunIt = false; 
	public static void updateLGStudentPaymentOnInsert(){		
		if( HD_TriggerSettings.IsTriggerActive('updateLGStudentPaymentOnInsert') && !updateLGStudentPaymentOnInsert_HasRunIt){
		
			// Pre-condition: the LG Payment didn't apply yet the VAT & Discount (I mean, the LG Payment were created without those calculations yet)
			Set<Id> paymentLGIds = new Set<Id>(); 
			Set<Id> paymentLGStudentIds = new Set<Id>();
			
			Set<Integer> indexes4LGPayment2Students = new Set<Integer>();
			Set<Integer> indexes4LGPayment2LGs = new Set<Integer>();
			
			List<LG_Payment__c> listLGPayments = new List<LG_Payment__c>();
			if(lgPayment2ApplyDiscount.isEmpty()){
				listLGPayments = trigger.new;
			}else{
				listLGPayments = lgPayment2ApplyDiscount;
			}
								
			for(Integer i=0; i < listLGPayments.size(); i++ ){
				
				LG_Payment__c p = (LG_Payment__c)listLGPayments[i];
				
				if((trigger.isInsert || lgPaymentUpdated.contains(p.Id) || !lgPayment2ApplyDiscount.isEmpty()) && p.LG_Student__c <> null){ // Using this condition we determine that the LG Payment is related with a LG Payment to Student (instead of LG payment to LG)
					
					paymentLGIds.add(p.LG__c);	
					paymentLGStudentIds.add(p.LG_Student__c);
					indexes4LGPayment2Students.add(i);
				}else if((trigger.isInsert || lgPaymentUpdated.contains(p.Id) || !lgPayment2ApplyDiscount.isEmpty()) && p.LG_Student__c == null){
					
					paymentLGIds.add(p.LG__c);
					indexes4LGPayment2LGs.add(i);
				}		
			}
			
			if(!indexes4LGPayment2Students.IsEmpty()){
				
				Map<String, List<LG_Student_Attendance__c>> attByKey = new Map<String, List<LG_Student_Attendance__c>>();
				Map<Id,LG_Student__c> relatedStudentIds = new Map<Id,LG_Student__c>();
				Set<Id> accIds = new Set<Id>();
				
				for(LG_Student__c s : [SELECT Id, LG__c, LG__r.Franchisee__c, LG__r.Franchisee__r.ParentId, LG__r.Price_for_Payment__c, LG__r.Declared_Number_of_Students__c, LG__r.Price_Type__c, Billing_Type__c, Price_for_Payment__c, Number_of_Payments__c, Not_include_VAT__c, (SELECT Id, LG_Student__c, LG_Lesson__r.Lesson_Date_Hour__c, LG_Payment__c FROM LG_Students_Attendance__r WHERE LG_Lesson__r.Lesson_Status__c != 'Cancelled' AND LG_Lesson__r.Lesson_Status__c != 'Day Off') FROM LG_Student__c WHERE Id IN: paymentLGStudentIds]){
					
					relatedStudentIds.put(s.Id, s);
					if(s.LG__r.Franchisee__c <> null && !s.Not_include_VAT__c){
						accIds.add(s.LG__r.Franchisee__c);
					}
					if(s.LG__r.Franchisee__r.ParentId <> null && !s.Not_include_VAT__c){
						accIds.add(s.LG__r.Franchisee__r.ParentId);
					}
					
					for(LG_Student_Attendance__c att : s.LG_Students_Attendance__r ){
						
						if(att.LG_Lesson__r.Lesson_Date_Hour__c <> null){
							
							Integer iMonth = att.LG_Lesson__r.Lesson_Date_Hour__c.month();
							Integer iYear = att.LG_Lesson__r.Lesson_Date_Hour__c.year();
									
							Integer numberOfDays = Date.daysInMonth(iYear, iMonth);
							Date lastDayOfMonth  = Date.newInstance(iYear, iMonth, numberOfDays);
							
							String key = att.LG_Student__c + '|' + lastDayOfMonth;			
							
							if(!attByKey.containsKey(key)){
								attByKey.put(key, new List<LG_Student_Attendance__c>());
							}
							attByKey.get(key).add(att);
						}
					}
					
				}
				
				Map<Id, map<String, LG_Discount__c>> oneTimeDiscountByLGIds 		= LGHelperMethods.getOneTimeLGDiscounts(paymentLGIds);
				Map<Id, Map<Id, LG_Discount__c>> entireCourseWithLGStudentByLGIds 	= LGHelperMethods.getEntireCourseWithLGStudentLGDiscounts(paymentLGIds);
				Map<Id, List<LG_Discount__c>> entireCourseWithoutLGStudentByLGIds 	= LGHelperMethods.getEntireCourseWithoutLGStudentLGDiscounts(paymentLGIds);
				
				for(Integer i : indexes4LGPayment2Students){
					
					LG_Payment__c p = (LG_Payment__c)listLGPayments[i];		
					
					if(p.Planned_Date__c <> null){
					
						LG_Student__c s = relatedStudentIds.get(p.LG_Student__c);
						LG__c lg = s.LG__r;
						
						String key = p.LG_Student__c + '|' + p.Planned_Date__c;
						List<LG_Student_Attendance__c> relatedAtt = attByKey.get(key);
						
						if(relatedAtt == null){
							relatedAtt = new List<LG_Student_Attendance__c>();
						}
						
						if(!lgPayment2ApplyDiscount.isEmpty()){
							
							// When LG Discount with Discount Type = "Entire course", get Discount Status = Approved and LG Student is null and there are LG Payments to LG Students
							// Go Over all LG Payment connected to LG and update LG Payment.Planned Price to LG Student.Price for Payment
							for(LG_Discount__c lgD : entireCourseWithoutLGStudentByLGIds.get(p.LG__c)){
								if(applyOnlyOnDiscountIds.contains(lgD.Id) && !entireCourseWithLGStudentByLGIds.get(p.LG__c).containsKey(s.Id)){ // check the additional condition that there is not Discount by LG Student
									Decimal valueWithDiscount = discountValue(lgD, lg, s.Billing_Type__c, s.Number_of_Payments__c, relatedAtt.size());
									if(valueWithDiscount <> null){
										p.Planned_Price__c = valueWithDiscount;
									}
								}
							}
							
							// When LG Discount with Discount Type = "Entire course", get Discount Status = Approved and LG Student is not null and there are already LG Payments to the LG Student
							// Go Over all LG Payment connected to LG Student and update LG Payment.Planned Price to MIN (LG Payment.Planned Price, LG Student.Price for Payment)
							if(entireCourseWithLGStudentByLGIds.get(p.LG__c).containsKey(s.Id)){
								if(applyOnlyOnDiscountIds.contains(entireCourseWithLGStudentByLGIds.get(p.LG__c).get(s.Id).Id)){
									
									LG_Discount__c lgD = entireCourseWithLGStudentByLGIds.get(p.LG__c).get(s.Id);
									Decimal valueWithDiscount = discountValue(lgD, lg, s.Billing_Type__c, s.Number_of_Payments__c, relatedAtt.size());
									
									if(valueWithDiscount <> null && p.Planned_Price__c > valueWithDiscount){
										p.Planned_Price__c = valueWithDiscount;
									}
								}
							}						 
						}					
						
						if(oneTimeDiscountByLGIds.containsKey(p.LG__c)){ // Exist Discounts
						
							String keyDiscount = p.Planned_Date__c.month()+ '/' + p.Planned_Date__c.year();
							LG_Discount__c d = oneTimeDiscountByLGIds.get(p.LG__c).get(keyDiscount); // Discount by LG less priority (null if not exist)
							
							if(oneTimeDiscountByLGIds.get(p.LG__c).containsKey(keyDiscount+p.LG_Student__c)){ // Discount by LG hight priority
								d = oneTimeDiscountByLGIds.get(p.LG__c).get(keyDiscount+p.LG_Student__c);
							}
												
							if(d <> null){		
								
								Decimal valueWithDiscount = discountValue(d, lg, s.Billing_Type__c, s.Number_of_Payments__c, relatedAtt.size());
								
								if(valueWithDiscount <> null && valueWithDiscount < p.Planned_Price__c){ // Override the precalculated price by trigger createLGPaymentToStudent
									p.Planned_Price__c = valueWithDiscount;	
									p.LG_Discount_One_Time__c = d.Id;
								}
								
								/*
								if(s.Billing_Type__c == 'Course Price' && d.Approved_Price__c < s.Price_for_Payment__c){ // Override the precalculated price by trigger createLGPaymentToStudent
									p.Planned_Price__c = d.Approved_Price__c;	
									p.LG_Discount_One_Time__c = d.Id;
								}else if(s.Billing_Type__c == 'Price per Month' && d.Approved_Price__c < s.Price_for_Payment__c){
									p.Planned_Price__c = d.Approved_Price__c;
									p.LG_Discount_One_Time__c = d.Id;
								}else if(s.Billing_Type__c == 'Price per Session'){
									
									//String key = p.LG_Student__c + '|' + p.Planned_Date__c;
									//List<LG_Student_Attendance__c> relatedAtt = attByKey.get(key);
									
									if(relatedAtt <> null && (d.Approved_Price__c * relatedAtt.size() < p.Planned_Price__c)){
										p.Planned_Price__c = d.Approved_Price__c * relatedAtt.size();
										p.LG_Discount_One_Time__c = d.Id;
									}
								}
								*/
							}					
						}	
					}		
				}			
				
				// Populating the VAT...
				if(lgPayment2ApplyDiscount.isEmpty()){
					applyVAT2LGPayments(indexes4LGPayment2Students, accIds, relatedStudentIds, null);
				}	
			}
			
			if(!indexes4LGPayment2LGs.isEmpty()){ 
				
				Map<String, List<LG_Lesson__c>> lessonsByKey = new Map<String, List<LG_Lesson__c>>();
				Set<Id> accIds = new Set<Id>();
				Map<Id, LG__c> relatedLGs = new Map<Id, LG__c>();
				system.debug(system.LoggingLevel.INFO, 'indexes4LGPayment2LGs: ' + indexes4LGPayment2LGs);
				for(LG__c lg : [SELECT Id, Billing_Type__c, Price_for_Payment__c, Price_Type__c, Price_Charge__c, Declared_Number_of_Students__c, Number_of_Payments__c, Franchisee__c, Franchisee__r.ParentId, (SELECT Id, LG__c, Lesson_Date_Hour__c, LG_Payment__c FROM LG_Lessons__r WHERE Lesson_Status__c != 'Cancelled' AND Lesson_Status__c != 'Day Off') FROM LG__c WHERE Id IN : paymentLGIds]){
					
					relatedLGs.put(lg.Id, lg);
					
					if(lg.Franchisee__c <> null){
						accIds.add(lg.Franchisee__c);
					}
					
					if(lg.Franchisee__r.ParentId <> null){
						accIds.add(lg.Franchisee__r.ParentId);
					}
					
					for(LG_Lesson__c lss : lg.LG_Lessons__r){
						
						if(lss.Lesson_Date_Hour__c <> null){	
							Integer iMonth = lss.Lesson_Date_Hour__c.month();
							Integer iYear = lss.Lesson_Date_Hour__c.year();
									
							Integer numberOfDays = Date.daysInMonth(iYear, iMonth);
							Date lastDayOfMonth  = Date.newInstance(iYear, iMonth, numberOfDays);
							
							String key = lss.LG__c + '|' + lastDayOfMonth;			
							
							if(!lessonsByKey.containsKey(key)){
								lessonsByKey.put(key, new List<LG_Lesson__c>());
							}
							lessonsByKey.get(key).add(lss);
						}
					}
				}
							
				Map<Id, map<String, LG_Discount__c>> oneTimeDiscountByLGIds = LGHelperMethods.getOneTimeLGDiscounts(paymentLGIds);
				Map<Id, List<LG_Discount__c>> entireCourseWithoutLGStudentByLGIds = LGHelperMethods.getEntireCourseWithoutLGStudentLGDiscounts(paymentLGIds);
				
				system.debug(system.LoggingLevel.INFO, 'oneTimeDiscountByLGIds: ' + oneTimeDiscountByLGIds);
				system.debug(system.LoggingLevel.INFO, 'entireCourseWithoutLGStudentByLGIds: ' + entireCourseWithoutLGStudentByLGIds);
				system.debug(system.LoggingLevel.INFO, 'indexes4LGPayment2LGs: ' + indexes4LGPayment2LGs);
				
				for(Integer i : indexes4LGPayment2LGs){
					
					LG_Payment__c p = (LG_Payment__c)listLGPayments[i];	
					
					if(p.Planned_Date__c <> null){
						
						LG__c lg = relatedLGs.get(p.LG__c);
						
						String key = p.LG__c + '|' + p.Planned_Date__c;
						List<LG_Lesson__c> relatedLss = lessonsByKey.get(key);
						
						if(relatedLss == null){
							relatedLss = new List<LG_Lesson__c>();
						}
						
						system.debug(system.LoggingLevel.INFO, 'lgPayment2ApplyDiscount: ' + lgPayment2ApplyDiscount);
						
						if(!lgPayment2ApplyDiscount.isEmpty()){
							
							// When LG Discount with Discount Type = "Entire course" get Discount Status = Approved and LG Student is null and there are already LG Payments to the LG
							// Go Over all LG Payment connected to LG and update LG Payment.Planned Price to MIN (LG Payment .Planned Price, LG.Price Charge)
							for(LG_Discount__c lgD : entireCourseWithoutLGStudentByLGIds.get(p.LG__c)){
								
								system.debug(system.LoggingLevel.INFO, 'lgD: ' + lgD);
								
								Decimal valueWithDiscount = discountValue(lgD, lg, lg.Billing_Type__c, lg.Number_of_Payments__c, relatedLss.size());
								if(valueWithDiscount <> null && valueWithDiscount != null && p.Planned_Price__c > valueWithDiscount && applyOnlyOnDiscountIds.contains(lgD.Id)){
									p.Planned_Price__c = valueWithDiscount;
								}
								
								system.debug(system.LoggingLevel.INFO, 'valueWithDiscount: ' + valueWithDiscount);
							}
						}
						
						if(!oneTimeDiscountByLGIds.isEmpty() && oneTimeDiscountByLGIds.containsKey(p.LG__c)){ // Exist Discounts
						
							String keyDiscount = p.Planned_Date__c.month()+ '/' + p.Planned_Date__c.year();
							LG_Discount__c d = oneTimeDiscountByLGIds.get(p.LG__c).get(keyDiscount); // Discount by LG less priority (null if not exist)
							
							if(d <> null){	
								
								Decimal valueWithDiscount = discountValue(d, lg, lg.Billing_Type__c, lg.Number_of_Payments__c, relatedLss.size());
								
								if(valueWithDiscount <> null && valueWithDiscount < p.Planned_Price__c){ // Override the precalculated price by trigger createLGPaymentToStudent
									p.Planned_Price__c = valueWithDiscount;	
									p.LG_Discount_One_Time__c = d.Id;
								}
								
								/*
								Double priceWithDiscount = d.Approved_Price__c // No need to multiply by Declare number of Students (QA-SW-18006) * lg.Declared_Number_of_Students__c; 							
								if(lg.Billing_Type__c == 'Course Price' && priceWithDiscount < p.Planned_Price__c){ // Override the precalculated price by trigger createLGPaymentToStudent
									p.Planned_Price__c = priceWithDiscount;	
									p.LG_Discount_One_Time__c = d.Id;
								}else if(lg.Billing_Type__c == 'Price per Month' && priceWithDiscount < p.Planned_Price__c){
									p.Planned_Price__c = priceWithDiscount;
									p.LG_Discount_One_Time__c = d.Id;
								}else if(lg.Billing_Type__c == 'Price per Session'){
									
									String key = p.LG__c + '|' + p.Planned_Date__c;
									List<LG_Lesson__c> relatedLss = lessonsByKey.get(key);
									Double Price_with_discount = priceWithDiscount * relatedLss.size();
									
									if(relatedLss <> null && Price_with_discount < p.Planned_Price__c){
										p.Planned_Price__c = Price_with_discount;
										p.LG_Discount_One_Time__c = d.Id;
									}							
								}
								*/
							}					
						}			
					}
				}
				
				// Populating the VAT...
				if(lgPayment2ApplyDiscount.isEmpty()){
					applyVAT2LGPayments(indexes4LGPayment2LGs, accIds, null, relatedLGs);
				}	
			}
		}
	}
	
	public static String testValue4testMethod;
	/*
	public static Decimal discountValue(LG_Discount__c lgD, String BillingType, Decimal nroOfPayments, Integer nroOfAtt){
		Decimal valueWithDiscount;
		
		String bType = lgD.Billing_Type__c;
		
		if(Test.isRunningTest() && testValue4testMethod <> null){
			bType = testValue4testMethod;
		}
		
		if(bType == BillingType){
			if(BillingType == 'Course Price'){
				valueWithDiscount = lgD.Approved_Course_Price__c / ((nroOfPayments==null || nroOfPayments== 0)?1:nroOfPayments);	
			}else if(BillingType == 'Price per Month'){
				valueWithDiscount = lgD.Approved_Price_per_Month__c;
			}else if(BillingType == 'Price per Session'){
				valueWithDiscount = lgD.Approved_Price_per_Session__c * nroOfAtt;
			}
		}
		return valueWithDiscount;
	}
	*/
	
	public static Decimal discountValue(LG_Discount__c lgD, LG__c lg, String BillingType, Decimal nroOfPayments, Integer nroOfAtt){
		Decimal valueWithDiscount;
		
		String bType = lgD.Billing_Type__c;
		
		if(Test.isRunningTest() && testValue4testMethod <> null){
			bType = testValue4testMethod;
		}
		
		if(bType == BillingType){
			
			Boolean condition_ByDeclared = lg.Price_Type__c == 'Per Student' && lg.Declared_Number_of_Students__c > 0;			
			if(condition_ByDeclared){ // New logic SW-24329
				if(BillingType == 'Course Price'){
					valueWithDiscount = lgD.Approved_Course_Price__c / ((nroOfPayments==null || nroOfPayments== 0)?1:nroOfPayments); // default case will be "One Time (Month)".
					if(lgD.Discount_Type__c == 'Entire Course'){
						valueWithDiscount = lg.Price_for_Payment__c;
					}	
				}else if(BillingType == 'Price per Month'){
					valueWithDiscount = lg.Declared_Number_of_Students__c * lgD.Approved_Price_per_Month__c ; // default case will be "One Time (Month)".
					if(lgD.Discount_Type__c == 'Entire Course'){
						valueWithDiscount = lg.Price_for_Payment__c;
					}
				}else if(BillingType == 'Price per Session'){
					valueWithDiscount = lg.Declared_Number_of_Students__c * lgD.Approved_Price_per_Session__c * nroOfAtt; // default case will be "One Time (Month)".
					if(lgD.Discount_Type__c == 'Entire Course'){
						valueWithDiscount = lg.Price_for_Payment__c * nroOfAtt;
					}
				}				
			}else{				
				if(BillingType == 'Course Price'){
					valueWithDiscount = lgD.Approved_Course_Price__c / ((nroOfPayments==null || nroOfPayments== 0)?1:nroOfPayments);	
				}else if(BillingType == 'Price per Month'){
					valueWithDiscount = lgD.Approved_Price_per_Month__c;
				}else if(BillingType == 'Price per Session'){
					valueWithDiscount = lgD.Approved_Price_per_Session__c * nroOfAtt;
				}
			}
		}
		return valueWithDiscount;
	}
	
	
	/* 
		Method that populate the VAT field on Trigger.new[i] (LG Payment) where i belong to indexes 
		
		Observation: in case that the VAT logic should be change. Please keep update the related method "LGHelperMethods.applyVAT2LGPayments()" in case that should be necessary applyVAT2LGPayments
	*/
	public static void applyVAT2LGPayments(Set<Integer> indexes, Set<Id> accIds, Map<Id,LG_Student__c> relatedStudentIds, Map<Id,LG__c> relatedLGs){
		
		// -- CALCULATING THE VAT --
		Map<Id, List<Franchisee_VAT__c>> fVats = new Map<Id, List<Franchisee_VAT__c>>();
		
		for(Franchisee_VAT__c v : [SELECT Id, Franchisee__c, VAT__c, VAT_From_Date__c , VAT_End_Date__c FROM Franchisee_VAT__c WHERE Franchisee__c IN: accIds ORDER BY VAT_From_Date__c ASC]){
			
			if(v.Franchisee__c <> null){
				
				if(!fVats.containsKey(v.Franchisee__c)){
					fVats.put(v.Franchisee__c, new List<Franchisee_VAT__c>());
				}
				fVats.get(v.Franchisee__c).add(v);
			}
		}		
		
		for(Integer i : indexes){
			
			Boolean notIncludeVAT = false;
			Id franchiseId, parentFranchiseId;
			
			LG_Payment__c p = (LG_Payment__c)trigger.new[i];	
			if(relatedStudentIds <> null){	
				
				// LG Payment to Student
				LG_Student__c s = relatedStudentIds.get(p.LG_Student__c);
				notIncludeVAT = (s.Not_include_VAT__c == true);
				franchiseId = s.LG__r.Franchisee__c;
				parentFranchiseId = s.LG__r.Franchisee__r.ParentId;
			}else{
				
				// LG Payment to LG				
				LG__c lg = relatedLGs.get(p.LG__c);
				franchiseId = lg.Franchisee__c;
				parentFranchiseId = lg.Franchisee__r.ParentId;
			}	
			
			p.VAT__c = 0; // By Default	
			p.Franchisee_VAT__c = null;

			if(!notIncludeVAT){
				
				Boolean finish = false;
				
				if(p.Planned_Date__c <> null){
				
					if(fVats.containsKey(franchiseId)){ // Check if exist a Vat range for the payment
						
						for(Franchisee_VAT__c f : fVats.get(franchiseId)){
							
							Boolean condition = p.Planned_Date__c >= f.VAT_From_Date__c && (f.VAT_End_Date__c == null || p.Planned_Date__c <= f.VAT_End_Date__c);    
							if(condition){
								p.VAT__c = f.VAT__c;	
								p.Franchisee_VAT__c = f.Id;
								finish = true;
								break;
							}
						}
					}
					
					if(!finish && parentFranchiseId <> null){
						
						if(fVats.containsKey(parentFranchiseId)){ // Check if exist a Vat range for the payment
							
							for(Franchisee_VAT__c f : fVats.get(parentFranchiseId)){
								
								Boolean condition = p.Planned_Date__c >= f.VAT_From_Date__c && (f.VAT_End_Date__c == null || p.Planned_Date__c <= f.VAT_End_Date__c);  
								if(condition){
									p.VAT__c = f.VAT__c;
									p.Franchisee_VAT__c = f.Id;	
									finish = true;
									break;
								}
							}
						}						
					}
				}	
			}
		}		
	}
	
	
	/******************************************************************************* 
	Description       : Update LG Student Attendance from New LG Payment
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Hernan 		         03/04/2016          	 Yaara          		 [SW-18004]
	2. Hernan 		         03/11/2016          	 Yaara          		 [SW-18006]
	*******************************************************************************/
	public static Set<Id> payment2CheckTheRelink = new Set<Id>();
	public static void updateLGStudentAttendanceFromPayment(){
		if( HD_TriggerSettings.IsTriggerActive('updateLGStudentAttendanceFromPayment') ){
		
			Set<Id> paymentLGIds = new Set<Id>(); 
			Set<Id> paymentLGStudentIds = new Set<Id>();
			
			Set<Integer> indexes4LGPayment2Students = new Set<Integer>();
			Set<Integer> indexes4LGPayment2LGs = new Set<Integer>();
			
			for(Integer i=0; i < trigger.size; i++ ){
				
				LG_Payment__c p = (LG_Payment__c)trigger.new[i];
				if((trigger.isInsert || payment2CheckTheRelink.contains(p.Id)) && p.LG_Student__c <> null){ // Using this condition we determine that the LG Payment is related with a LG Payment to Student (instead of LG payment to LG)
					
					paymentLGStudentIds.add(p.LG_Student__c);
					indexes4LGPayment2Students.add(i);
				}else if((trigger.isInsert || payment2CheckTheRelink.contains(p.Id)) && p.LG_Student__c == null){
					
					paymentLGIds.add(p.LG__c);
					indexes4LGPayment2LGs.add(i);
				}			
			}
			
			if(!indexes4LGPayment2Students.IsEmpty()){
				
				Map<String, List<LG_Student_Attendance__c>> attByKey = new Map<String, List<LG_Student_Attendance__c>>();
					
				for(LG_Student_Attendance__c att : [SELECT Id, LG_Student__c, LG_Lesson__r.Lesson_Date_Hour__c, LG_Payment__c FROM LG_Student_Attendance__c WHERE LG_Student__r.Billing_Type__c = 'Price per Session' AND LG_Lesson__r.Lesson_Status__c != 'Cancelled' AND LG_Lesson__r.Lesson_Status__c != 'Day Off' AND LG_Student__c IN: paymentLGStudentIds]){
					
					if(att.LG_Lesson__r.Lesson_Date_Hour__c <> null){
						
						Integer iMonth = att.LG_Lesson__r.Lesson_Date_Hour__c.month();
						Integer iYear = att.LG_Lesson__r.Lesson_Date_Hour__c.year();
								
						Integer numberOfDays = Date.daysInMonth(iYear, iMonth);
						Date lastDayOfMonth  = Date.newInstance(iYear, iMonth, numberOfDays);
						
						String key = att.LG_Student__c + '|' + lastDayOfMonth;			
						
						if(!attByKey.containsKey(key)){
							attByKey.put(key, new List<LG_Student_Attendance__c>());
						}
						attByKey.get(key).add(att);
					}
				}
				
				List<LG_Student_Attendance__c> att2Up = new List<LG_Student_Attendance__c>(); // Populating the relationship with the LG Payment on LG_Student_Attendance__c
				for(Integer i : indexes4LGPayment2Students){
				
					LG_Payment__c p = (LG_Payment__c)trigger.new[i];		
					
					if(p.Planned_Date__c <> null){
					
						String key = p.LG_Student__c + '|' + p.Planned_Date__c;
						if(attByKey.containsKey(key)){
					
							for(LG_Student_Attendance__c relatedAtt : attByKey.get(key)){
								if(relatedAtt.LG_Payment__c == null || relatedAtt.LG_Payment__c <> p.Id){
									relatedAtt.LG_Payment__c = p.Id;
									att2Up.add(relatedAtt);
								}
							}
						}
					}
				}
				
				if(!att2Up.IsEmpty()){
					update att2Up;
				}
			}
			
			if(!indexes4LGPayment2LGs.IsEmpty()){ 
				
				Map<String, List<LG_Lesson__c>> lessonsByKey = new Map<String, List<LG_Lesson__c>>();
				for(LG_Lesson__c lss : [SELECT Id, LG__c, Lesson_Date_Hour__c, LG_Payment__c FROM LG_Lesson__c WHERE Lesson_Status__c != 'Cancelled' AND Lesson_Status__c != 'Day Off' AND LG__r.Billing_Type__c = 'Price per Session' AND LG__c IN: paymentLGIds]){
					
					if(lss.Lesson_Date_Hour__c <> null){
						
						Integer iMonth = lss.Lesson_Date_Hour__c.month();
						Integer iYear = lss.Lesson_Date_Hour__c.year();
								
						Integer numberOfDays = Date.daysInMonth(iYear, iMonth);
						Date lastDayOfMonth  = Date.newInstance(iYear, iMonth, numberOfDays);
						
						String key = lss.LG__c + '|' + lastDayOfMonth;			
						
						if(!lessonsByKey.containsKey(key)){
							lessonsByKey.put(key, new List<LG_Lesson__c>());
						}
						lessonsByKey.get(key).add(lss);
					}
				}
				
				List<LG_Lesson__c> lss2Up = new List<LG_Lesson__c>(); // Populating the relationship with the LG Payment on LG_Student_Attendance__c
				for(Integer i : indexes4LGPayment2LGs){
				
					LG_Payment__c p = (LG_Payment__c)trigger.new[i];		
					
					if(p.Planned_Date__c <> null){
						String key = p.LG__c + '|' + p.Planned_Date__c;
						if(lessonsByKey.containsKey(key)){
					
							for(LG_Lesson__c relatedLss : lessonsByKey.get(key)){
								if(relatedLss.LG_Payment__c == null || relatedLss.LG_Payment__c <> p.Id){
									relatedLss.LG_Payment__c = p.Id;
									lss2Up.add(relatedLss);
								}
							}
						}
					}
				}
				
				if(!lss2Up.IsEmpty()){
					update lss2Up;
				}
			}

		}
	}
	
	/******************************************************************************* 
	Description       : Creates Group Income Per Month from the Payment
						LG Payment created
						
						Then we create Group Income Per Month for LG Payment
						
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Sergio 		         03/18/2016          	 Yaara          		 [SW-18018]
	*******************************************************************************/
	public static void LG_Payment_CreateGroupIncomePerMonth(){
		if( HD_TriggerSettings.IsTriggerActive('LG_Payment_CreateGroupIncomePerMonth') ){

			try{
				Set<Id> paymentIds = new Set<Id>();
				
				for(Integer i=0; i < trigger.size; i++){
					LG_Payment__c payment = (LG_Payment__c) trigger.new[i];
					
					if( trigger.isInsert && payment.Payment_Type__c == 'Standard' && payment.Planned_Date__c <> null){
						paymentIds.add(payment.Id);
					}
				}
				
				if( paymentIds.isEmpty() == false ){
					List<Group_Income_Per_Month__c> gm2Ins = new List<Group_Income_Per_Month__c>();
					Id recordTypeId = Schema.SObjectType.Group_Income_Per_Month__c.getRecordTypeInfosByName().get('Price').getRecordTypeId();
					
					for( LG_Payment__c payment :[SELECT Id, LG_Student__c, LG_Student__r.Student__c, Planned_Date__c, LG__c, LG__r.Agreement__c FROM LG_Payment__c WHERE Id IN :paymentIds ] ){
						Group_Income_Per_Month__c gm = new Group_Income_Per_Month__c();
						
						gm.RecordTypeId = recordTypeId;
						gm.Agreement__c = payment.LG__r.Agreement__c;
						gm.LG__c = payment.LG__c;
						gm.LG_Student__c = payment.LG_Student__c;
						gm.Student__c = payment.LG_Student__r.Student__c;
						gm.Royalty_Start_Date__c = payment.Planned_Date__c;
						gm.Royalty_End_Date__c = payment.Planned_Date__c;
						gm.LG_Payment__c = payment.Id;
						
						gm2Ins.add(gm);
					}
					
					if( gm2Ins.isEmpty() == false ){
						insert gm2Ins;
					}
				}
			}catch(Exception e){
				trigger.new[0].addError( e.getMessage() );
			}

		}
	}

	/******************************************************************************* 
	Name 			: deleteIncomeGroupOnPaymentDel
	Description     : Delete Group Income Per Month related to the deleted LG Payment
						
	Revision History:-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G. Fernandez 		    03/23/2016  	       Yaara	         	 [SW-18536]
	*******************************************************************************/
	public static void deleteIncomeGroupOnPaymentDel(){
		if( HD_TriggerSettings.IsTriggerActive('deleteIncomeGroupOnPaymentDel') ){
			try{

				Id groupIncomeTypeId = Schema.SObjectType.Group_Income_Per_Month__c.getRecordTypeInfosByName().get('Price').getRecordTypeId();

				Set<Id> paymentIds = new Set<Id>();
				
				for(Integer i=0; i < trigger.size; i++){
					LG_Payment__c payment = (LG_Payment__c) trigger.old[i];
					paymentIds.add(payment.Id);				
				}

				List<Group_Income_Per_Month__c> groupIncome2Del = [SELECT Id FROM Group_Income_Per_Month__c WHERE LG_Payment__c IN :paymentIds AND RecordTypeId =:groupIncomeTypeId];

				if(!groupIncome2Del.isEmpty()){
					Delete groupIncome2Del;
				}						
				
			}catch(Exception e){
				trigger.new[0].addError( e.getMessage() );
			}
			
		}
	}

}