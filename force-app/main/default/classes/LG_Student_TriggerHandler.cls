/******************************************************************************* 
Name              : LG_Student_TriggerHandler
Description       : Handler the before/after trigger on LG Student
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan         			02/25/2016          	
*******************************************************************************/
public class LG_Student_TriggerHandler {
    
    
    public static void executeTriggerHandler(){
        
        //  ---------------------------- BEFORE EVENTS -----------------------------
        
        if (Trigger.isBefore && Trigger.isInsert) // Before Insert
        {
            System.debug('executeTriggerHandler --->Trigger.isBefore && Trigger.isInsert');
            populateLGStudentFielsOnBefore();
        }
        else if (Trigger.isBefore && Trigger.isUpdate) // Before Update
        {
            System.debug('executeTriggerHandler --->Trigger.isBefore && Trigger.isUpdate');
            populateLGStudentFielsOnBefore();
        }
        
        
        //  ---------------------------- AFTER EVENTS -----------------------------
        
        if (Trigger.isAfter && Trigger.isInsert) // After Insert
        {
            System.debug('executeTriggerHandler -  AFTER EVENTS --->Trigger.isAfter && Trigger.isInsert) // After Insert');
            
            lgStudentCreateSharingRules();
            createLGLessonsToStudent();
            createLGPaymentToStudent();
            
            LG_Student_CreateGroupIncomePerMonth();
        }
        
        else if (Trigger.isAfter && Trigger.isUpdate) // After Update
        {
            System.debug('executeTriggerHandler -  AFTER EVENTS --->Trigger.isAfter && Trigger.isUpdate) // After Update');
            
            recreateLGPayment2LGStudentBillingTypeChange();
            
            deleteLGLessonsToStudent();
            createLGLessonsToStudent();
            createLGPaymentToStudent();
            
            LG_Student_CreateGroupIncomePerMonth();
            LG_Student_DeleteGroupIncomePerMonth();
            
            reCallTheDiscountLogic();
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
        
        if(!LG_Discount_TriggerHandler.lgDiscountStudentApproved.isEmpty()){
            
            Set<Id> lgStudentWithDiscount = new Set<Id>();
            for(Integer i=0; i < trigger.size; i++ ){
                
                LG_Student__c r = (LG_Student__c)trigger.new[i];
                LG_Student__c rOld = (LG_Student__c)trigger.old[i];
                if(r.Approved_Price__c <> rOld.Approved_Price__c){
                    lgStudentWithDiscount.add(r.Id);
                }
            }
            
            if(!lgStudentWithDiscount.isEmpty()){
                LG_Discount_TriggerHandler.updateLGPaymentWhenLGDiscountIsApproved(LG_Discount_TriggerHandler.lgDiscountStudentApproved);
                LG_Discount_TriggerHandler.lgDiscountStudentApproved.clear();
            }
        }		
    }
    
    /******************************************************************************* 
Description       : Populate fields before duplicatecheck
1) Update LG Number before insert and when edited
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez         02/08/2016          Ella  Bernachik           [SW-17616]
2. Hernan Sinclair      05/27/2016          Ella  Bernachik           [SW-19672]
*******************************************************************************/
    public static void populateLGStudentFielsOnBefore(){
        
        if( HD_TriggerSettings.IsTriggerActive('populateLGStudentFielsOnBefore') ){
            
            Map<Id, List<LG_Student__c>> lgStudents = new Map<Id,List<LG_Student__c>>();
            for(Integer i=0; i < trigger.size; i++ ){
                //if lg in this student is null step to the next student
                LG_Student__c r = (LG_Student__c)trigger.new[i];
                System.debug('LG_Student__c ----> r : '+  r);
                System.debug('111LG_Student__c ----> r.Student_Start_Paying_Date__c : '+  r.Student_Start_Paying_Date__c);
                
                if(r.LG__c == Null)
                    continue;
                
                if(trigger.isInsert || r.LG__c <> ((LG_Student__c)trigger.old[i]).LG__c){
                    //create new list of students on lg
                    if(!lgStudents.containsKey(r.LG__c)){
                        lgStudents.put(r.LG__c, new List<LG_Student__c>());
                        System.debug('111lgStudents : '+  lgStudents);
                        
                        
                    }
                    
                    //add student to lg
                    lgStudents.get(r.LG__c).add(r);
                    System.debug('222lgStudents : '+  lgStudents);
                    
                }
            }
            
            if(!lgStudents.isEmpty()){
                
                //look if lgs were already queried
                Map<Id, LG__c> lgMap = MonitorRecursionClass.getLgFromCache(lgStudents.keySet());
                System.debug('lgMap.values(): '+  lgMap.values());
                
                for(LG__c lg : lgMap.values()){
                    System.debug('FOR---##lg: '+  lg);
                    
                    List<LG_Student__c> listLGStudents = lgStudents.get(lg.Id);
                    
                    if(listLGStudents <> null){
                        for(LG_Student__c student : listLGStudents){
                            
                            student.LG_Number__c = lg.Name;
                            if(Trigger.isInsert){ 
                                // IMPORTANT: This section will prepropulate the default values of LG Student empty fields (since Field Update will run after trigger runnings)
                                System.debug('student'+  student);
                                System.debug('AAA#student.Student_Course_Start_Date__c'+  student.Student_Course_Start_Date__c);
                                
                                // Student Course Start Date
                                if(student.Student_Course_Start_Date__c == null || student.Student_Course_Start_Date__c < lg.LG_Start_Date__c){
                                    student.Student_Course_Start_Date__c = lg.LG_Start_Date__c;
                                }
                                System.debug('BBB#student.Student_Course_Start_Date__c'+  student.Student_Course_Start_Date__c);
                                
                                if(student.Student_Course_End_Date__c == null || student.Student_Course_End_Date__c > lg.LG_End_Date__c){
                                    student.Student_Course_End_Date__c = lg.LG_End_Date__c;
                                }
                                System.debug('---##lg.LG_Start_Paying_Date__c'+  lg.LG_Start_Paying_Date__c);
                                
                                System.debug('1111---##student.Student_Start_Paying_Date__c'+  student.Student_Start_Paying_Date__c);
                                student.Student_Start_Paying_Date__c = student.Student_Course_Start_Date__c ;
                                System.debug('1122---##student.Student_Start_Paying_Date__c'+  student.Student_Start_Paying_Date__c);
                                
                                if(student.Student_Start_Paying_Date__c == null){
                                    student.Student_Start_Paying_Date__c = lg.LG_Start_Paying_Date__c;
                                    if(lg.LG_Start_Paying_Date__c < system.today()){
                                        student.Student_Start_Paying_Date__c = system.today();
                                    }
                                }
                                System.debug('2222---##student.Student_Start_Paying_Date__c'+  student.Student_Start_Paying_Date__c);
                                
                                if(student.Student_End_Paying_Date__c == null){
                                    student.Student_End_Paying_Date__c = lg.LG_End_Paying_Date__c;
                                }
                                
                                if(student.Billing_Type__c == null){
                                    student.Billing_Type__c = lg.Billing_Type__c;
                                }				
                            }
                        }
                    }
                }	
            }	
            
        }
    }		
    
    /******************************************************************************* 
Description       : Creates LG Lesson for the Students
When new LG Student is created and Status in LG  is "Registered" or "Signed for Demo" or existing student change Status in LG to "Registered"/"Signed for Demo", 
and there are already LG Lessons to LG (Number of Lessons > 0). Create LG Student Attendance related to LG Student and existing LG Lessons
from LG Lesson with Lesson Date/Hour between Student Course Start Date until Student Course End Date.
Revision History  :- 
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Nicolas 		         02/29/2016          	 Yaara          		 [SW-18012]
2. Hernan 				 05/02/2017              Yaara		           	 [SW-24707]
*******************************************************************************/
    public static boolean SKIP_createLGLessonsToStudent = false;
    public static void createLGLessonsToStudent(){
        if( HD_TriggerSettings.IsTriggerActive('createLGLessonsToStudent') && !SKIP_createLGLessonsToStudent){
            
            Map<Id, List<Id>> studentsByLgId = new Map<Id, List<Id>>(); 
            for(Integer i=0; i < trigger.size; i++ ){
                
                LG_Student__c r = (LG_Student__c)trigger.new[i];
                LG_Student__c rOld;
                if(trigger.isUpdate){
                    rOld = (LG_Student__c)trigger.old[i];
                }
                
                Boolean condition = r.Status_in_LG__c == 'Registered' || r.Status_in_LG__c == 'Signed for Demo';
                condition &= trigger.isInsert || (trigger.isUpdate && r.Status_in_LG__c <> rOld.Status_in_LG__c && !(rOld.Status_in_LG__c == 'Registered' || rOld.Status_in_LG__c == 'Signed for Demo'));
                if(condition){
                    if(!studentsByLgId.containsKey(r.LG__c)){
                        studentsByLgId.put(r.LG__c, new List<Id>());
                    }
                    studentsByLgId.get(r.LG__c).add(r.Id);
                }
            }
            
            if(!studentsByLgId.isEmpty()){
                
                Map<String,LG_Student_Attendance__c> mapAtt2Ins = new Map<String,LG_Student_Attendance__c>();
                Set<Id> lgls = new Set<Id>(); 
                //List<LG_Student_Attendance__c> mapAtt2Ins = new List<LG_Student_Attendance__c>();
                
                for(LG__c lg : [SELECT id, LG_End_Date__c, (SELECT Id, Lesson_Type__c, Lesson_Date_Hour__c, Lesson_End_Hour__c FROM LG_Lessons__r WHERE Lesson_Status__c != 'Day Off') FROM LG__c WHERE Id in: studentsByLgId.keySet()]){
                    for(LG_Lesson__c ls : lg.LG_Lessons__r){
                        lgls.add(ls.Id);
                        for(Id sId : studentsByLgId.get(lg.Id)){
                            LG_Student__c lStudent = (LG_Student__c)trigger.newMap.get(sId);
                            if(ls.Lesson_Date_Hour__c <> null && lStudent.Student_Course_Start_Date__c <= ls.Lesson_Date_Hour__c.date() && lStudent.Student_Course_End_Date__c >= ls.Lesson_Date_Hour__c.date() /* could be null this ls.Lesson_End_Hour__c.date() anyway is the same date*/ ){ // Check the conditon LG Student Course Start Date <=Lesson Date and LG Student Course End Date >= Lesson Date
                                String key = String.valueOf(ls.Id).substring(0, 15) + '_' + String.valueOf(lStudent.Id).substring(0, 15);
                                mapAtt2Ins.put(key,new LG_Student_Attendance__c(LG_Lesson__c = ls.Id, Lesson_Type__c = lStudent.Lesson_Type__c, LG_Student__c = lStudent.Id, Attended__c = 'None'));
                            } 
                        }
                    }
                }
                
                if(!mapAtt2Ins.isEmpty()){
                    Set<String> existentAttendance = new Set<String>();
                    for (LG_Lesson__c lgl : [SELECT Id, (SELECT LG_Student__c FROM LG_Students_Attendance__r) FROM LG_Lesson__c WHERE Id IN :lgls]) {
                        for (LG_Student_Attendance__c lsa : lgl.LG_Students_Attendance__r) {
                            String key = String.valueOf(lgl.Id).substring(0, 15) + '_' + String.valueOf(lsa.LG_Student__c).substring(0, 15);
                            existentAttendance.add(key);
                        }
                    }
                    
                    //SW-26336
                    List<LG_Student_Attendance__c> att2ins = new List<LG_Student_Attendance__c>();
                    for (String key : mapAtt2Ins.keySet()) {
                        if(!existentAttendance.contains(key)){
                            att2ins.add(mapAtt2Ins.get(key));
                        }
                    }
                    // The related payment will be created on method "createLGPaymentToStudent"
                    if(!att2ins.isEmpty()){
                        insert att2ins; 
                    }
                }
            }
            
        }
    }
    
    /******************************************************************************* 
Description       : Delete LG Lesson for the Students
When LG Student change Status in LG to "Move" or "Drop-Out" or  Student Course End Date is change to lower value, 
delete all it LG Student Attendance from the Student Course End date that doesn't have status "Attend" = Yes.
Revision History  :- 
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Nicolas 		         03/01/2016          	 Yaara          		 [SW-18012]
*******************************************************************************/
    
    public static void deleteLGLessonsToStudent(){
        if( HD_TriggerSettings.IsTriggerActive('deleteLGLessonsToStudent') ){
            
            Set<Id> studentIds = new Set<Id>(); 
            Set<Id> studentIds2DelLGLessonAtt = new Set<Id>(); 
            Map<Id, Date> endDateByLGStudents = new Map<Id, Date>(); 
            for(Integer i=0; i < trigger.size; i++ ){
                
                LG_Student__c r = (LG_Student__c)trigger.new[i];
                LG_Student__c rOld = (LG_Student__c)trigger.old[i];
                
                Boolean condition = r.Status_in_LG__c <> rOld.Status_in_LG__c && (r.Status_in_LG__c == 'Move' || r.Status_in_LG__c == 'Drop-Out');
                condition |=  r.Student_Course_End_Date__c <> rOld.Student_Course_End_Date__c && r.Student_Course_End_Date__c < rOld.Student_Course_End_Date__c;
                if(condition){ // Just with the above 2 condition I could delete the LG Leasson Atts.
                    studentIds2DelLGLessonAtt.add(r.Id);
                }
                condition |=  r.Student_End_Paying_Date__c <> rOld.Student_End_Paying_Date__c && r.Student_End_Paying_Date__c < rOld.Student_End_Paying_Date__c;
                if(condition){
                    endDateByLGStudents.put(r.Id, r.Student_End_Paying_Date__c); // Since it's related with the payments
                    studentIds.add(r.Id);
                }
            }
            
            if(!studentIds.isEmpty()){
                
                List<LG_Student_Attendance__c> att2Del = new List<LG_Student_Attendance__c>();
                List<LG_Payment__c> lgPayment2Update = new List<LG_Payment__c>();
                for(LG_Student__c s : [SELECT Id, Billing_Type__c, (SELECT Id, LG_Lesson__r.Lesson_Date_Hour__c, LG_Lesson__r.Lesson_End_Hour__c, LG_Payment__c FROM LG_Students_Attendance__r WHERE Attended__c != 'Yes'), (Select Planned_Date__c, Planned_Price__c From LG_Payments__r) FROM LG_Student__c WHERE Id In: studentIds]){
                    
                    LG_Student__c r = (LG_Student__c)trigger.newMap.get(s.Id);
                    for(LG_Student_Attendance__c att : s.LG_Students_Attendance__r){
                        if(/*r.Status_in_LG__c == 'Move' || r.Status_in_LG__c == 'Drop-Out' ||*/ studentIds2DelLGLessonAtt.contains(s.Id) && att.LG_Lesson__r.Lesson_Date_Hour__c <> null &&  r.Student_Course_End_Date__c < att.LG_Lesson__r.Lesson_Date_Hour__c.date() /* could be null this att.LG_Lesson__r.Lesson_End_Hour__c.date() anyway is the same date*/){
                            att2Del.add(att);
                        }
                    }
                    if(s.Billing_Type__c != 'Price per Session'){ 
                        
                        // The rest of the payment will be updated on the method deleteLGStudentAttendanceAndItsLGPayments
                        for(LG_Payment__c lgPayment : s.LG_Payments__r){
                            if(lgPayment.Planned_Date__c > endDateByLGStudents.get(s.Id)){
                                lgPayment.Planned_Price__c = 0;
                                lgPayment2Update.add(lgPayment);
                            }
                        }
                    }
                }
                
                if(!lgPayment2Update.isEmpty()){
                    update lgPayment2Update;
                }
                
                if(!att2Del.isEmpty()){
                    Map<String, LG_Payment__c> p2Ins = LGHelperMethods.deleteLGStudentAttendanceAndItsLGPayments(att2Del, true, null);
                    if(!p2Ins.isEmpty()){
                        // Insert the LG Payment realculated with the remaind att
                        insert p2Ins.values(); 
                    }
                }
            }	
            
        }	
    }
    
    /******************************************************************************* 
Description       : Creates LG Payment for the Students
When LG.Declared Number of Student is Null and (LG Student created with Status in LG = "Registered" or existing LG Student. Status in LG change to "Registered" ) and 
(LG Student. Billing Type  is not Price per Session or LG Student. Billing Type  is Price per Session and LG.Number of Lessons is not null)
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan Sinclair         02/26/2016          	 Yaara          		 [SW-18004]
2. Hernan Sinclair         06/07/2016          	 Yaara          		 [SW-19460]
3. Hernan Sinclair         06/08/2016          	 Yaara          		 [SW-19456]
4. Hernan Sinclair         02/17/2016          	 Yaara          		 [SW-23645]
5. Hernan Sinclair         04/10/2017            Daftna	           		 [SW-24440]
*******************************************************************************/
    public static Boolean SKIP_lgStudents2ReCreatedLGPaymentToLGStudents = false;
    public static List<LG_Student__c> lgStudents2ReCreatedLGPaymentToLGStudents = new List<LG_Student__c>();
    public static void createLGPaymentToStudent(){
        if( HD_TriggerSettings.IsTriggerActive('createLGPaymentToStudent') && !SKIP_lgStudents2ReCreatedLGPaymentToLGStudents){
            System.debug('##### - createLGPaymentToStudent()');
            Map<Id, Id> lgIdByStudentIds = new Map<Id, Id>(); 
            Map<Id, LG_Student__c> allLGStudentMap = new Map<Id, LG_Student__c>();
            Set<Id> lgStudent2ReCalculateLGPayment = new Set<Id>();
            System.debug('lgStudents2ReCreatedLGPaymentToLGStudents'+  lgStudents2ReCreatedLGPaymentToLGStudents);
            
            if(lgStudents2ReCreatedLGPaymentToLGStudents.isEmpty()){
                for(Integer i=0; i < trigger.size; i++ ){
                    
                    LG_Student__c r = (LG_Student__c)trigger.new[i];
                    LG_Student__c rOld;
                    if(trigger.isUpdate){
                        rOld = (LG_Student__c)trigger.old[i];
                    }
                    System.debug('r: '+  r);
                    System.debug('rOld: '+  rOld);
                    
                    
                    
                    
                    Boolean condition = r.Status_in_LG__c == 'Registered';
                    condition &= trigger.isInsert || (trigger.isUpdate && (r.Status_in_LG__c <> rOld.Status_in_LG__c)); 
                    if(condition){
                        lgIdByStudentIds.put(r.Id, r.LG__c);
                    }else if(trigger.isUpdate && r.Status_in_LG__c == 'Registered' && r.Price_for_Payment__c <> rOld.Price_for_Payment__c){ //SW-24275
                        lgStudent2ReCalculateLGPayment.add(r.Id); // We should fire the re calcuation of the LG Payment since has changed its price...
                    }					
                    allLGStudentMap.put(r.Id, r);
                }
                System.debug('lgIdByStudentIds: '+  lgIdByStudentIds);
                System.debug('lgStudent2ReCalculateLGPayment: '+  lgStudent2ReCalculateLGPayment);
                System.debug('allLGStudentMap: '+  allLGStudentMap);
                
                System.debug('---lgStudent2ReCalculateLGPayment'+  lgStudent2ReCalculateLGPayment);
                
                if(!lgStudent2ReCalculateLGPayment.isEmpty()){
                    LGHelperMethods.doRecreateLGPayment2LGStudent(lgStudent2ReCalculateLGPayment);
                }				
            }else{ // SW-19460
                for(LG_Student__c lgS : lgStudents2ReCreatedLGPaymentToLGStudents){	
                    allLGStudentMap.put(lgS.Id, lgS);
                    lgIdByStudentIds.put(lgS.Id, lgS.LG__c);
                }	
                lgStudents2ReCreatedLGPaymentToLGStudents.clear();
            }				
            
            if(!lgIdByStudentIds.IsEmpty()){
                
                Map<Id, LG__c> lgFilterByCriteria = new Map<Id, LG__c>();
                
                for(LG__c lg : [SELECT Id, Gap_between_Price_Payments__c, Number_of_Payments__c, First_Month_Price__c, Last_Month_Price__c, Number_of_Lessons__c, Franchisee__c, Franchisee__r.ParentId, LG_Start_Paying_Date__c, LG_End_Paying_Date__c, Declared_Number_of_Students__c FROM LG__c WHERE Id IN: lgIdByStudentIds.values() AND Price_Type__c = 'Per Student' /*New condition SW-23645*/]){
                    if(lg.Declared_Number_of_Students__c == NULL || lg.Declared_Number_of_Students__c == 0){ /* New condition SW-23645 */
                        lgFilterByCriteria.put(lg.Id, lg);
                    }	
                }
                
                Set<Id> accIds = new Set<Id>();
                for(LG__c lg : lgFilterByCriteria.values()){
                    if(lg.Franchisee__c <> null){
                        accIds.add(lg.Franchisee__c);	
                    }
                    if(lg.Franchisee__r.ParentId <> null){
                        accIds.add(lg.Franchisee__r.ParentId);	
                    }
                }
                
                Set<Id> student4LGPayment = new Set<Id>();
                Boolean existLGStudentWithEmptyPaymentMethod = false;
                // Get all the Students in which we should create the LG Payment
                for(Id studentId : lgIdByStudentIds.keySet()){
                    if(lgFilterByCriteria.containsKey(lgIdByStudentIds.get(studentId))){ 
                        
                        // Filtered by the LG criteria requested to apply.
                        LG__c lg = lgFilterByCriteria.get(lgIdByStudentIds.get(studentId));
                        LG_Student__c r = allLGStudentMap.get(studentId);
                        
                        existLGStudentWithEmptyPaymentMethod |= string.isBlank(r.Payment_Method__c);
                        
                        if(r.Billing_Type__c <> 'Price per Session'){
                            student4LGPayment.add(studentId);
                        }else if(r.Billing_Type__c == 'Price per Session' && lg.Number_of_Lessons__c <> null && lg.Number_of_Lessons__c <> 0 ){
                            student4LGPayment.add(studentId);
                        }
                    }
                }
                System.debug('&&& student4LGPayment: '+  student4LGPayment);
                
                
                List<LG_Payment__c> r2Insert = new List<LG_Payment__c>();
                
                if(!student4LGPayment.isEmpty()){
                    
                    Map<Id, LG_Student__c> allLGStudentMapWithAdditionalInfo = new Map<Id, LG_Student__c>();
                    
                    if( existLGStudentWithEmptyPaymentMethod ){ // SW-24440
                        for(LG_Student__c lgS : [SELECT Id, Student__r.Payment_Method__c FROM LG_Student__c WHERE Id IN: student4LGPayment]){
                            allLGStudentMapWithAdditionalInfo.put(lgS.Id, lgS);
                        }
                    }
                    System.debug('allLGStudentMapWithAdditionalInfo: '+  allLGStudentMapWithAdditionalInfo);
                    
                    Set<Id> studentWithBillingSession = new Set<Id>();
                    System.debug('student4LGPayment.size: '+  student4LGPayment.size());
                    System.debug('student4LGPayment: '+  student4LGPayment);
                    
                    for(Id sId : student4LGPayment){
                        
                        LG_Student__c s = allLGStudentMap.get(sId);
                        System.debug('s.Student_Start_Paying_Date__c: '+  s.Student_Start_Paying_Date__c);
                        
                        System.debug('s: '+  s);
                        
                        
                        String paymentMenthod = string.isBlank(s.Payment_Method__c) && allLGStudentMapWithAdditionalInfo.containsKey(s.Id)?allLGStudentMapWithAdditionalInfo.get(s.Id).Student__r.Payment_Method__c:s.Payment_Method__c;
                        System.debug('s.Billing_Type__c: '+  s.Billing_Type__c);
                        
                        if(s.Billing_Type__c == 'Course Price'){
                            
                            LG__c lg = lgFilterByCriteria.get(lgIdByStudentIds.get(sId));
                            
                            Decimal numberOfPayments = 1;
                            if(s.Number_of_Payments__c != null && s.Number_of_Payments__c != 0){
                                numberOfPayments = s.Number_of_Payments__c;
                            }else if(lg.Number_of_Payments__c != null){
                                numberOfPayments = lg.Number_of_Payments__c; // Because the PB run after this trigger
                            }
                            
                            Decimal gapBetweenPayments = 1;
                            if(s.Gap_Between_Payments__c != null && s.Gap_Between_Payments__c != 0){
                                gapBetweenPayments = s.Gap_Between_Payments__c;
                            }else if(lg.Gap_between_Price_Payments__c != null){
                                gapBetweenPayments = lg.Gap_between_Price_Payments__c; // Because the PB run after this trigger
                            }	
                            
                            Double Price_for_Payment;
                            if(Test.isRunningTest() && s.Student_Price__c == null){
                                Price_for_Payment = 1;
                            }else{
                                Price_for_Payment = s.Student_Price__c / numberOfPayments;  // since when Number_of_Payments__c or Gap_between_Price_Payments__c where already load by the PB the field  s.Price_for_Payment__c; not has the correct value  
                            }
                            Date paymentDate = s.Student_Start_Paying_Date__c; 
                            
                            if(Test.isRunningTest() && paymentDate == null){
                                paymentDate = system.today();
                            }
                            
                            for(Integer i = 0; i < numberOfPayments; i++){
                                r2Insert.add(new LG_Payment__c(LG__c = s.LG__c, LG_Student__c = s.Id, Payment_Type__c = 'Standard', Payment_Method__c = string.isBlank(paymentMenthod)?'Credit Card':paymentMenthod, Planned_Date__c = paymentDate, Planned_Price__c = Price_for_Payment)); 	
                                paymentDate = paymentDate.addMonths(Integer.valueOf(gapBetweenPayments));
                            }
                        }else if(s.Billing_Type__c == 'Price per Month'){
                            
                            LG__c lg = lgFilterByCriteria.get(lgIdByStudentIds.get(sId));
                            
                            Date paymentDate = s.Student_Start_Paying_Date__c;
                            system.debug('111paymentDate: '+paymentDate);
                            
                            if(lg.First_Month_Price__c <> null && lg.LG_Start_Paying_Date__c <> null && s.Student_Start_Paying_Date__c != null && lg.LG_Start_Paying_Date__c.month() == s.Student_Start_Paying_Date__c.month() && lg.LG_Start_Paying_Date__c.year() == s.Student_Start_Paying_Date__c.year()){ 
                                // Update First Payment is it's on the start middle of the month
                                
                                system.debug(system.LoggingLevel.INFO, 'lg.First_Month_Price__c: ' + lg.First_Month_Price__c);
                                system.debug(system.LoggingLevel.INFO, 's.Price_for_Payment__c: ' + s.Price_for_Payment__c);
                                
                                r2Insert.add(new LG_Payment__c(LG__c = s.LG__c, LG_Student__c = s.Id, Payment_Type__c = 'Standard', Payment_Method__c = string.isBlank(paymentMenthod)?'Credit Card':paymentMenthod, Planned_Date__c = paymentDate, Planned_Price__c = (lg.First_Month_Price__c>s.Price_for_Payment__c)?s.Price_for_Payment__c:lg.First_Month_Price__c));
                                
                                system.debug(system.LoggingLevel.INFO, 'r2InsertA: ' + r2Insert[r2Insert.size()-1]);
                                
                                paymentDate = paymentDate.addMonths(1);	
                            }
                            system.debug('222paymentDate: '+paymentDate);
                            
                            while(paymentDate <= s.Student_End_Paying_Date__c){
                                r2Insert.add(new LG_Payment__c(LG__c = s.LG__c, LG_Student__c = s.Id, Payment_Type__c = 'Standard', Payment_Method__c = string.isBlank(paymentMenthod)?'Credit Card':paymentMenthod, Planned_Date__c = paymentDate, Planned_Price__c = s.Price_for_Payment__c));
                                
                                system.debug(system.LoggingLevel.INFO, 'r2InsertB: ' + r2Insert[r2Insert.size()-1]);
                                
                                paymentDate = paymentDate.addMonths(1);
                            }
                            system.debug('333paymentDate: '+paymentDate);
                            
                            if(lg.Last_Month_Price__c <> null && lg.LG_End_Paying_Date__c != null && s.Student_End_Paying_Date__c != null && lg.LG_End_Paying_Date__c.month() == s.Student_End_Paying_Date__c.month() && lg.LG_End_Paying_Date__c.year() == s.Student_End_Paying_Date__c.year()){ 
                                // Update First Payment is it's on the start middle of the month
                                r2Insert[r2Insert.size()-1].Planned_Price__c = lg.Last_Month_Price__c>s.Price_for_Payment__c?s.Price_for_Payment__c:lg.Last_Month_Price__c; 
                            }							
                        }else if(s.Billing_Type__c == 'Price per Session'){
                            // Pre-condition: the LG_Student_Attendance__c are already created!!!
                            studentWithBillingSession.add(s.Id);
                        }				
                    }	
                    
                    if(!studentWithBillingSession.isEmpty()){
                        r2Insert.addAll(LGHelperMethods.getLGPaymentBySessions(studentWithBillingSession, null, null));
                    }		
                }
                
                if(!r2Insert.isEmpty()){
                    // This will fire the trigger that will calculate the related Vat and Discount for each payment created...
                    system.debug('r2Insert: ' + r2Insert);    
                    insert r2Insert; 
                }
            }	
            
        }	
    }
    
    
    /******************************************************************************* 
Description       : Creates Group Income Per Month from the Students
LG Student.LG is not Fixed Number of Students  & Declared Number of Students is not null and
new LG Student with Status in LG = Registered or Change LG Student status in LG to Registered

Then we create Group Income Per Month for each month in which the Student is included in the LG

Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio 		         03/18/2016          	 Yaara          		 [SW-18018]
2. Sergio 		         04/08/2016          	 Yaara          		 [SW-18891]
3. Hernan 		         01/25/2017          	 Yaara          		 [SW-23388]
4. Hernan 			     02/17/2016          	 Yaara          		 [SW-23645]
5. Hernan          		 05/10/2017          	 Yaara          		 [SW-24849]
*******************************************************************************/
    public static Boolean SKIP_LG_Student_CreateGroupIncomePerMonth = false;
    public static void LG_Student_CreateGroupIncomePerMonth(){
        if( HD_TriggerSettings.IsTriggerActive('LG_Student_CreateGroupIncomePerMonth') && !SKIP_LG_Student_CreateGroupIncomePerMonth){
            system.debug('LG_Student_CreateGroupIncomePerMonth');
            try{
                Map<Id, List<LG_Student__c>> studentMap = new Map<Id, List<LG_Student__c>>();
                Set<Id> deleteGroupIncomes = new Set<Id>();
                Set<Id> contactIds = new Set<Id>();
                
                for( Integer i = 0; i < trigger.size; i++){
                    LG_Student__c student = (LG_Student__c) trigger.new[i];
                    
                    Boolean deleteCondition = trigger.isUpdate && String.isNotBlank(student.Status_in_LG__c) && student.Status_in_LG__c.equalsIgnoreCase( 'Registered' ) && ( student.Student_Course_Start_Date__c != trigger.old[i].get('Student_Course_Start_Date__c') || student.Student_Course_End_Date__c != trigger.old[i].get('Student_Course_End_Date__c') );
                    
                    Boolean insertCondition = String.isNotBlank(student.Status_in_LG__c) && student.Status_in_LG__c.equalsIgnoreCase( 'Registered' );
                    insertCondition &= (trigger.isInsert || ( trigger.isUpdate && student.Status_in_LG__c != trigger.old[i].get('Status_in_LG__c') ) || deleteCondition );
                    
                    
                    if( insertCondition || deleteCondition ){
                        if( insertCondition ){
                            if( studentMap.containsKey( student.LG__c) == false ){
                                studentMap.put( student.LG__c, new List<LG_Student__c>() );
                            }
                            
                            studentMap.get( student.LG__c ).add( student );
                            contactIds.add( student.Student__c );
                        }
                        
                        if( deleteCondition ){
                            deleteGroupIncomes.add( student.Id );
                        }
                    }
                }
                system.debug('contactIds: ' + contactIds);
                Id recordTypeId = Schema.SObjectType.Group_Income_Per_Month__c.getRecordTypeInfosByName().get('Calculated Student').getRecordTypeId();
                
                if( deleteGroupIncomes.isEmpty() == false ){
                    delete [SELECT Id FROM Group_Income_Per_Month__c WHERE LG_Student__c IN :deleteGroupIncomes AND RecordTypeId = :recordTypeId ];
                }
                
                if( studentMap.isEmpty() == false ){
                    LG_Student_CreateGroupIncomePerMonth_Helper(studentMap, contactIds);
                }
                
            }catch(Exception e){
                trigger.new[0].addError( e.getMessage() );
            }
            
        }
    }
    
    /* This method was created for encapsulating the creation logic that we need to call from different places */
    // IMPORTANT: if we need to add more fields on the related student of the studentMap please check the places where this method is being called and verify if needed
    //			  to add those new fields ;)
    public static void LG_Student_CreateGroupIncomePerMonth_Helper(Map<Id, List<LG_Student__c>> studentMap, Set<Id> contactIds){
        
        Id recordTypeId = Schema.SObjectType.Group_Income_Per_Month__c.getRecordTypeInfosByName().get('Calculated Student').getRecordTypeId();
        
        List<Group_Income_Per_Month__c> gm2Ins = new List<Group_Income_Per_Month__c>();
        Map<Id, Map<Id, Set<Date>>> actualStudent = new Map<Id, Map<Id, Set<Date>>>();
        
        for( Group_Income_Per_Month__c gipm : [SELECT Id, Agreement__c, Student__c, LG_Student__c, Royalty_Start_Date__c FROM Group_Income_Per_Month__c WHERE RecordTypeId = :recordTypeId AND Student__c IN :contactIds ] ){
            if( !actualStudent.containsKey( gipm.Student__c ) ){
                actualStudent.put( gipm.Student__c, new Map<Id, Set<Date>>() );
            }
            
            if( !actualStudent.get(gipm.Student__c).containsKey( gipm.Agreement__c ) ){
                actualStudent.get(gipm.Student__c).put( gipm.Agreement__c, new Set<Date>() );
            }
            
            Date dt = gipm.Royalty_Start_Date__c;
            system.debug( 'gipm.Id: ' + gipm.Id );
            system.debug( 'gipm.Student__c: ' + gipm.Student__c );
            system.debug( 'dt: ' + dt );
            actualStudent.get( gipm.Student__c ).get( gipm.Agreement__c).add( Date.newInstance( dt.year(), dt.month(), 1) );
        }
        
        for( LG__c lg : [SELECT Id, Agreement__c, Price_Type__c, Declared_Number_of_Students__c FROM LG__c WHERE Id IN :studentMap.keySet()] ){
            
            Boolean condition = (lg.Price_Type__c == 'Per Student' && (lg.Declared_Number_of_Students__c == null || lg.Declared_Number_of_Students__c == 0 /*SW-23388*/));
            condition |= (/*new condition SW-23645*/ lg.Price_Type__c == 'Per Group' && (lg.Declared_Number_of_Students__c == null || lg.Declared_Number_of_Students__c == 0));
            
            if(condition){ // The condition it's not on the Query since we don't want to crash the index checking null values.
                system.debug('actualStudent: ' + actualStudent);
                for( LG_Student__c student : studentMap.get(lg.Id) ){
                    
                    Group_Income_Per_Month__c gm;
                    for(Date dt = student.Student_Course_Start_Date__c; dt <= student.Student_Course_End_Date__c; dt = dt.addMonths(1) ){
                        gm = new Group_Income_Per_Month__c();
                        gm.RecordTypeId = recordTypeId;
                        gm.Agreement__c = lg.Agreement__c;
                        gm.LG_Student__c = student.Id;
                        gm.LG__c = lg.Id;
                        gm.Student__c = student.Student__c;
                        
                        if( dt == student.Student_Course_Start_Date__c ){
                            gm.Royalty_Start_Date__c = student.Student_Course_Start_Date__c;
                            dt = student.Student_Course_Start_Date__c.toStartOfMonth(); // SW-25293
                        }else{
                            gm.Royalty_Start_Date__c = Date.newInstance( dt.year(), dt.month(), 1 );
                            dt = gm.Royalty_Start_Date__c;
                        }
                        
                        Date actualStudentDT = Date.newInstance( gm.Royalty_Start_Date__c.year(), gm.Royalty_Start_Date__c.month(), 1);
                        gm.Actual_Student__c = 1;
                        system.debug( 'student.Student__c: ' + student.Student__c );
                        system.debug( 'actualStudentDT: ' + actualStudentDT );
                        system.debug( 'gm.Royalty_Start_Date__c: ' + gm.Royalty_Start_Date__c );
                        
                        system.debug('actualStudent.containsKey( student.Student__c ): ' + actualStudent.containsKey( student.Student__c ));
                        Boolean matchCondition = false;
                        if( actualStudent.containsKey( student.Student__c ) && actualStudent.get(student.Student__c).containsKey( gm.Agreement__c ) && actualStudent.get( student.Student__c ).get( gm.Agreement__c ).contains( actualStudentDT ) ){
                            gm.Actual_Student__c = 0;
                            matchCondition = true;
                        }
                        
                        if(!MonitorRecursionClass.isRunningInitialCreateAutomaticLGLessonsByBatch || (MonitorRecursionClass.isRunningInitialCreateAutomaticLGLessonsByBatch && !matchCondition /*SW-26135*/)){
                            gm2Ins.add(gm);
                        }
                    }
                    
                    if( gm != null ){
                        gm.Royalty_End_Date__c = student.Student_Course_End_Date__c;
                    }
                }
            }
        }
        
        if( gm2Ins.isEmpty() == false ){
            insert gm2Ins;
        }
        
    }
    
    /******************************************************************************* 
Description       : Delete Group Income Per Month from the Students
LG Student.Staus in LG change to Moved/Drop-Out and Student Course End Date is changed

Then we delete Group Income Per Month for each month after the new End Date

Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio 		         03/18/2016          	 Yaara          		 [SW-18018]
*******************************************************************************/
    public static void LG_Student_DeleteGroupIncomePerMonth(){
        if( HD_TriggerSettings.IsTriggerActive('LG_Student_DeleteGroupIncomePerMonth') ){
            try{
                Map<Id, LG_Student__c> studentMap = new Map<Id, LG_Student__c>();
                
                for( Integer i = 0; i < trigger.size; i++){
                    LG_Student__c student = (LG_Student__c) trigger.new[i];
                    
                    Boolean condition = String.isNotBlank(student.Status_in_LG__c) && (student.Status_in_LG__c.equalsIgnoreCase( 'Moved' ) || student.Status_in_LG__c.equalsIgnoreCase( 'Drop-Out' ) );
                    condition &= student.Student_Course_End_Date__c != trigger.old[i].get('Student_Course_End_Date__c');
                    
                    if( condition ){
                        studentMap.put( student.Id, student );
                    }
                }
                
                if( studentMap.isEmpty() == false ){
                    
                    List<Group_Income_Per_Month__c> gm2Del = new List<Group_Income_Per_Month__c>();
                    List<Group_Income_Per_Month__c> gm2Upd = new List<Group_Income_Per_Month__c>();
                    
                    for( Group_Income_Per_Month__c gm : [SELECT Id, LG_Student__c, Royalty_Start_Date__c FROM Group_Income_Per_Month__c WHERE LG_Student__c IN :studentMap.keySet() ] ){
                        LG_Student__c student = studentMap.get(gm.LG_Student__c);
                        
                        //Same month and year
                        if( gm.Royalty_Start_Date__c.month() == student.Student_Course_End_Date__c.month() && gm.Royalty_Start_Date__c.year() == student.Student_Course_End_Date__c.year() ){
                            gm.Royalty_End_Date__c = student.Student_Course_End_Date__c;
                            gm2Upd.add(gm);
                        }else if( gm.Royalty_Start_Date__c > student.Student_Course_End_Date__c ){
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
                trigger.new[0].addError( e.getMessage() );
            }
            
        }
    }
    
    /******************************************************************************* 
Name              : lgStudentCreateSharingRules
Description       : Handler the sharing record of LG_Student__c object
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez         	05/11/2016          	Yaara				  [SW-19268]
*******************************************************************************/
    
    public static void lgStudentCreateSharingRules(){
        if( HD_TriggerSettings.IsTriggerActive('lgStudentCreateSharingRules') ){
            
            Set<Id> lgStudentIds = new Set<Id>();
            for(Integer i=0; i < trigger.size; i++ ){
                if(((LG_Student__c)trigger.new[i]).DBAmp_Date__c == null){
                    lgStudentIds.add(trigger.new[i].Id);
                }
            }
            
            if(!lgStudentIds.isEmpty()){
                HD_SharingMethods.lgStudent_CreateSharingRules(lgStudentIds);
            }
        }
    }
    
    
    /*******************************************************************************  
Description       : Re Creates LG Payment to LG Students
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan Sinclair         06/09/2016          	 Yaara          		 [SW-19460]
2. Hernan         		   03/07/2017          	 Yaara                   [SW-23973]
3. Hernan         		   04/07/2017          	 Dafna                   [SW-24275] #2.2 Student / 4.1 Approve price (consider on reCallTheDiscountLogic) 
*******************************************************************************/
    public static void recreateLGPayment2LGStudentBillingTypeChange(){
        
        if( HD_TriggerSettings.IsTriggerActive('recreateLGPayment2LGStudentBillingTypeChange') ){
            
            Set<Id> relatedLGIds = new Set<Id>();
            for(Integer i=0; i < trigger.size; i++ ){
                relatedLGIds.add(((LG_Student__c)trigger.new[i]).LG__c);
            }
            
            Map<Id, LG__c> relatedLGMap = MonitorRecursionClass.getLgFromCache(relatedLGIds);
            Set<Id> lgSIds = new Set<Id>();
            for(Integer i=0; i < trigger.size; i++ ){
                
                LG_Student__c r 	= (LG_Student__c)trigger.new[i];
                LG_Student__c rOld 	= (LG_Student__c)trigger.old[i];
                
                LG__c relatedLG = relatedLGMap.get(r.LG__c);
                
                // Original condition.
                Boolean conditions = rOld.Billing_Type__c <> null && r.Billing_Type__c <> rOld.Billing_Type__c;
                // # 2.2 Student
                conditions |= r.Billing_Type__c == 'Course Price' && relatedLG.Price_Type__c == 'Per Student' && (relatedLG.Declared_Number_of_Students__c == Null || relatedLG.Declared_Number_of_Students__c == 0) && (rOld.Number_of_Payments__c <> r.Number_of_Payments__c || rOld.Gap_Between_Payments__c <> r.Gap_Between_Payments__c);
                if(conditions){
                    lgSIds.add(r.Id);
                }
            }
            
            if(!lgSIds.IsEmpty()){
                
                Set<Id> lgStudentIds = new Set<Id>();
                for(LG_Student__c lgs : [SELECT Id, LG__r.Price_Type__c, LG__r.Declared_Number_of_Students__c, Student_Start_Paying_Date__c FROM LG_Student__c WHERE LG__r.LG_Type__c != 'Demo Lesson' AND Id IN: lgSIds AND Status_in_LG__c = 'Registered']){
                    
                    String result = LGHelperMethods.checkCondition2RecreateLGPayment2LGStudent(lgs);
                    if(!String.isBlank(result)){
                        trigger.newMap.get(lgs.Id).addError(result);
                    }else{
                        lgStudentIds.add(lgs.Id);
                    }
                }				
                
                if(!lgStudentIds.IsEmpty()){
                    LGHelperMethods.doRecreateLGPayment2LGStudent(lgStudentIds);
                }
            }
        }
    }
}