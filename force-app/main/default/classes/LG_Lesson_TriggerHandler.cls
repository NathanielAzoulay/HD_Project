/******************************************************************************* 
Name              : LG_Lesson_TriggerHandler
Description       : Handler the before/after trigger on LG Lesson
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan Sinclair          03/17/2016              
*******************************************************************************/
public class LG_Lesson_TriggerHandler {

    public static void executeTriggerHandler(){
        
        //  ---------------------------- AFTER EVENTS -----------------------------
        
        if (Trigger.isBefore && Trigger.isInsert) // Before Insert
        {
            populateLGLessonFielsOnBefore();
        }
        
        else if (Trigger.isBefore && Trigger.isUpdate) // Before Update
        {
            populateLGLessonFielsOnBefore();
        }
        else if (Trigger.isBefore && Trigger.isDelete) // Before Delete
        {
            deleteRelatedLGPayments();
        }
        
        
        //  ---------------------------- AFTER EVENTS -----------------------------
        
        
        if (Trigger.isAfter && Trigger.isInsert) // After Insert
        {
            onCreateLGLessons();
        }       
        
        else if (Trigger.isAfter && Trigger.isUpdate) // After Update
        {
            reCalculateLGPaymentsToLGLesson();
        }
        
        else if (Trigger.isAfter && Trigger.isDelete) // After Delete
        {
            reCalculateLGPaymentsToLGLesson();
        }
        /*
        else if (Trigger.isAfter && Trigger.isUnDelete) // After UnDelete
        {
            
        }
        */
                
    }
    
    /******************************************************************************* 
    Description       : Populate fields before duplicatecheck
                        1) Update LG Lesson before insert and when edited
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. Hernan Sinclair       03/29/2016            Ella  Bernachik           [SW-18618]
    *******************************************************************************/
    public static void populateLGLessonFielsOnBefore(){
        if( HD_TriggerSettings.IsTriggerActive('populateLGLessonFielsOnBefore') ){
        
            for(Integer i=0; i < trigger.size; i++ ){
                
                LG_Lesson__c r = (LG_Lesson__c)trigger.new[i];
                
                Boolean convertLDay2String = r.Lesson_Date_Hour__c <> null;
                Boolean cond = r.Lesson_Date_Hour__c <> null;
                cond = cond && (trigger.isInsert || ((LG_Lesson__c)trigger.old[i]).Lesson_Date_Hour__c <> r.Lesson_Date_Hour__c);
                if(cond){
                    //r.Lesson_Date_Time__c = String.valueOf(r.Lesson_Date_Hour__c);
                    r.Lesson_Date_Time__c = r.Lesson_Date_Hour__c.formatGmt( 'yyyy-MM-dd HH:mm:ss' );
                }
            }

        }
    }
    
    /*
        When LG Lesson is being created we should take care the related LG Student Attendances and LG Payments (if depend on the Lesson or Attendances)...
    */
    public static void onCreateLGLessons(){     
        
        if( HD_TriggerSettings.IsTriggerActive('onCreateLGLessons') ){
        
            Map<Id, List<LG_Lesson__c>> lgIdsAndLGLessons = new Map<Id, List<LG_Lesson__c>>();
            for(Integer i=0; i < trigger.size; i++ ){
                
                LG_Lesson__c r = (LG_Lesson__c)trigger.new[i];
                if(trigger.isInsert){ 
                    if(!lgIdsAndLGLessons.containsKey(r.LG__c)){
                        lgIdsAndLGLessons.put(r.LG__c, new List<LG_Lesson__c>());
                    }
                    lgIdsAndLGLessons.get(r.LG__c).add(r);
                }
            }
            
            if(!lgIdsAndLGLessons.isEmpty()){
                
                Map<Id, LG_Lesson__c> lgLesson2RecalculateLGPayments = new Map<Id, LG_Lesson__c>();
                Map<Id, LG__c> lgMap = MonitorRecursionClass.getLgFromCache(lgIdsAndLGLessons.keySet());
                
                for(LG__c lg : lgMap.values()){ // In real logic, there shouldn't be more than 1 LG on this logic anyway we leave it since in case that the re are more than one the trigger will run it as well
                    
                    List<LG_Student__c> lgStudents;
                    /* SW-22542
                    if(!system.isBatch()){ // The leasson are being created manually...
                        // when is being inserted manually we don't allow demo (https://servicewise.my.salesforce.com/a1FD0000007mbHM)
                         lgStudents = [SELECT Id, Student_Course_Start_Date__c, Student_Course_End_Date__c, Billing_Type__c, Lesson_Type__c, (Select Planned_Date__c, Planned_Price__c From LG_Payments__r) FROM LG_Student__c WHERE LG__c =: lg.Id AND (Status_in_LG__c = 'Registered')];
                    }else{
                         // when is being inserted by process then we allow Demo
                         lgStudents = [SELECT Id, Student_Course_Start_Date__c, Student_Course_End_Date__c, Billing_Type__c, Lesson_Type__c, (Select Planned_Date__c, Planned_Price__c From LG_Payments__r) FROM LG_Student__c WHERE LG__c =: lg.Id AND (Status_in_LG__c = 'Registered' OR Status_in_LG__c = 'Signed for Demo')];
                    }
                    */
                    
                    // SW-22542 -> lgStudents
                    if(MonitorRecursionClass.isRunningInitialCreateAutomaticLGLessonsByBatch == false){
                        lgStudents = [SELECT Id, Student_Course_Start_Date__c, Student_Course_End_Date__c, Billing_Type__c, Lesson_Type__c, (Select Planned_Date__c, Planned_Price__c From LG_Payments__r) FROM LG_Student__c WHERE LG__c =: lg.Id AND (Status_in_LG__c = 'Registered' OR Status_in_LG__c = 'Signed for Demo')];
                    }else{                  
                        // SW-26135 when we are running the initial batch we should consider Status completed
                        lgStudents = [SELECT Id, Student_Course_Start_Date__c, Student_Course_End_Date__c, Billing_Type__c, Lesson_Type__c, (Select Planned_Date__c, Planned_Price__c From LG_Payments__r) FROM LG_Student__c WHERE LG__c =: lg.Id AND ((Status_in_LG__c = 'Registered' OR Status_in_LG__c = 'Signed for Demo') OR (LG__r.Group_Status__c = 'Completed' AND (Status_in_LG__c = 'Drop-Out' OR Status_in_LG__c = 'Moved' OR Status_in_LG__c = 'Completed')))];
                    }
                    
                    if(!lgStudents.isEmpty()){
                            
                            // Creating the attendaces...
                            if(!system.isBatch() && !LGCreateLessonBatch.theLessonWasCreatedDueToChangeLGEndDate){ // The leasson are being created manually (NOT throw the process...) & for issue SW-21976 (QA: "Attendance after Student End Date")  
                                LGCreateLessonBatch.notNeed2CheckRangeDateOnNewLesson = true;
                            }
                            LGCreateLessonBatch.createStudentsAttAndLGPayments(lgIdsAndLGLessons.get(lg.Id), lgStudents, null, null, MonitorRecursionClass.GetProcessKey(), false);
                            if(!system.isBatch() && !LGCreateLessonBatch.theLessonWasCreatedDueToChangeLGEndDate){
                                LGCreateLessonBatch.notNeed2CheckRangeDateOnNewLesson = false;
                            }
                            
                            Boolean hasLGStudentWithSessionPaymentType = false;
                            for(LG_Student__c ls : lgStudents){
                                if(ls.Billing_Type__c == 'Price per Session'){  
                                    hasLGStudentWithSessionPaymentType = true; // We know that all those student are registered so not need to check Group Status Active
                                }
                            }
                            
                            system.debug('lg.Group_Status__c: ' + lg.Group_Status__c);
                            system.debug('lg.Billing_Type__c: ' + lg.Billing_Type__c);
                            system.debug('hasLGStudentWithSessionPaymentType: ' + hasLGStudentWithSessionPaymentType);
                            
                            //SW-23089if((lg.Billing_Type__c == 'Price per Session' || hasLGStudentWithSessionPaymentType) && lg.LG_Type__c == 'Standard' && lg.Group_Status__c == 'Active'){ // SW-21838
                            Boolean condition = lg.LG_Type__c == 'Standard';
                            condition &= (lg.Billing_Type__c == 'Price per Session' && lg.Group_Status__c == 'Active') || hasLGStudentWithSessionPaymentType || (lg.Billing_Type__c == 'Price per Session' && lg.Group_Status__c == 'Completed' && MonitorRecursionClass.isRunningInitialCreateAutomaticLGLessonsByBatch == true /*SW-26135*/);  
                            
                            if(condition){ // SW-21838
                                for(LG_Lesson__c lss : lgIdsAndLGLessons.get(lg.Id)){
                                    lgLesson2RecalculateLGPayments.put(lss.Id, new LG_Lesson__c(Id = lss.Id));
                                }
                            }
                            
                            system.debug('lgLesson2RecalculateLGPayments: ' + lgLesson2RecalculateLGPayments);
                            /*
                            Boolean isLGPaymentByStudent = lg.Declared_Number_of_Students__c == null || lg.Declared_Number_of_Students__c == 0;
                            if(isLGPaymentByStudent){
                                for(LG_Lesson__c ls : lgIdsAndLGLessons.get(lg.Id)){
                                    lgLesson2RecalculateLGPayments.put(ls.Id, new LG_Lesson__c(Id = ls.Id));
                                }   
                            }
                            */          
                    }else if(lg.Billing_Type__c == 'Price per Session' && lg.LG_Type__c == 'Standard' && (lg.Group_Status__c == 'Active' || (lg.Group_Status__c == 'Completed' && MonitorRecursionClass.isRunningInitialCreateAutomaticLGLessonsByBatch == true /*SW-26135*/))){
                        for(LG_Lesson__c ls : lgIdsAndLGLessons.get(lg.Id)){
                            lgLesson2RecalculateLGPayments.put(ls.Id, new LG_Lesson__c(Id = ls.Id));
                        }   
                    }       
                }
                
                system.debug('lgLesson2RecalculateLGPayments: ' + lgLesson2RecalculateLGPayments);
                if(!lgLesson2RecalculateLGPayments.isEmpty()){
                    lgLessonsThatNeedReCalculationLGPayments.addAll(lgLesson2RecalculateLGPayments.keySet());
                    system.debug('lgLessonsThatNeedReCalculationLGPayments: ' + lgLessonsThatNeedReCalculationLGPayments);
                    update lgLesson2RecalculateLGPayments.values(); // execute reCalculateLGPaymentsToLGLesson
                }
            }

        }
    }
    
    
    /******************************************************************************* 
    Description       : Logic that will be apply when
                        1) Update when Lesson change Date (LG Lesson.Lesson Date/Hour change to different Month)
                            For all LG Payment related to the changed LG Lesson and to LG Student Attendance that related to LG Lesson:
                            a) Re-calculate the LG Payments.Planned Price to not include the changed Lesson.
                            b) Check if there is LG Payment to the new month for the LG/LG Student,
                                b1) If exists: Re-Calculate the LG Payment to include the LG Lesson and relate the LG Lesson/LG Student Attendance to the LG Payment
                                b2) If not exists: Create new LG Payment to that month and relate it to the LG Lesson/LG Student Attendance
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. Hernan Sinclair       04/07/2016             Yaara Nadir               [SW-18007]
    2. Hernan Sinclair       03/15/2017             Dafna Margalit            [SW-24098]
    *******************************************************************************/
    public static Set<Id> lgLessonsThatNeedReCalculationLGPayments = new Set<Id>();
    public static void reCalculateLGPaymentsToLGLesson(){
        if( HD_TriggerSettings.IsTriggerActive('reCalculateLGPaymentsToLGLesson') ){
        
            Map<Id, Set<Date>> relatedLGIds = new Map<Id, Set<Date>>();
            for(Integer i=0; i < trigger.size; i++ ){
                
                LG_Lesson__c r;
                LG_Lesson__c rOld = (LG_Lesson__c)trigger.old[i];
                
                if(Trigger.isDelete){
                    r = rOld;
                }else{
                    r = (LG_Lesson__c)trigger.new[i];
                }
                system.debug('lgLessonsThatNeedReCalculationLGPayments: ' + lgLessonsThatNeedReCalculationLGPayments);
                system.debug('r.Id: ' + r.Id);
                Boolean condition = lgLessonsThatNeedReCalculationLGPayments.contains(r.Id); 
                system.debug('condition: ' + condition);
                condition = condition || ( rOld.Lesson_Date_Hour__c <> null &&  r.Lesson_Date_Hour__c <> null && rOld.Lesson_Date_Hour__c <> r.Lesson_Date_Hour__c && rOld.Lesson_Date_Hour__c.month() <> r.Lesson_Date_Hour__c.month());
                condition = condition || rOld.Lesson_Status__c <> r.Lesson_Status__c && (r.Lesson_Status__c == 'Cancelled' || r.Lesson_Status__c == 'Day Off'); 
                condition = condition || Trigger.isDelete;
                
                if(condition){
                    
                    lgLessonsThatNeedReCalculationLGPayments.remove(r.Id); // In case that we came from onCreateLGLessons() and we need to avoid recursion here
                    
                    if(!relatedLGIds.containsKey(r.LG__c)){
                        relatedLGIds.put(r.LG__c, new Set<Date>());
                    }
                    
                    // Old Month
                    Integer iMonth = rOld.Lesson_Date_Hour__c.month();
                    Integer iYear = rOld.Lesson_Date_Hour__c.year();                        
                    Integer numberOfDays = Date.daysInMonth(iYear, iMonth);
                    Date lastDayOfMonth  = Date.newInstance(iYear, iMonth, numberOfDays);
                    
                    relatedLGIds.get(r.LG__c).add(lastDayOfMonth); 
                    
                    // New Month
                    iMonth = r.Lesson_Date_Hour__c.month();
                    iYear = r.Lesson_Date_Hour__c.year();                       
                    numberOfDays = Date.daysInMonth(iYear, iMonth);
                    lastDayOfMonth  = Date.newInstance(iYear, iMonth, numberOfDays);
                
                    relatedLGIds.get(r.LG__c).add(lastDayOfMonth); // 
                }
            }
            
            system.debug('relatedLGIds: ' + relatedLGIds);
            
            if(!relatedLGIds.isEmpty()){
                
                Set<Id> lgStudentIds = new Set<Id>();
                Map<Id, Set<Id>> lg2ReCalculateLGPayment2Student = new Map<Id, Set<Id>>();
                Set<Id> lg2ReCalculateLGPayment2Lg = new Set<Id>();
                
                List<LG__c> lg2Process;
                if(MonitorRecursionClass.isRunningInitialCreateAutomaticLGLessonsByBatch == false){
                    lg2Process = [SELECT Id, Declared_Number_of_Students__c, Billing_Type__c, Price_Type__c,(SELECT Id FROM LG_Students__r WHERE Status_in_LG__c = 'Registered' AND Billing_Type__c = 'Price per Session') FROM LG__c WHERE LG_Type__c != 'Demo Lesson' AND Id IN: relatedLGIds.keySet()];
                }else{
                    // SW-26135 when we are running the initial batch we should consider Status completed
                    lg2Process = [SELECT Id, Declared_Number_of_Students__c, Billing_Type__c, Price_Type__c,(SELECT Id FROM LG_Students__r WHERE Billing_Type__c = 'Price per Session' AND (Status_in_LG__c = 'Registered' OR (LG__r.Group_Status__c = 'Completed' AND (Status_in_LG__c = 'Drop-Out' OR Status_in_LG__c = 'Moved' OR Status_in_LG__c = 'Completed')))) FROM LG__c WHERE LG_Type__c != 'Demo Lesson' AND Id IN: relatedLGIds.keySet()];
                } 
                
                for(LG__c lg : lg2Process){
                    
                    Boolean isLGPaymentByStudent = lg.Declared_Number_of_Students__c == null || lg.Declared_Number_of_Students__c == 0;
                    /*
                        Description -: While creating Lessons if Price Type on LG is Per Group then Payments should be
                        Created according to the number of Lessons in  month lines.
                        ***********************************************************
                        Modified By-: Shivram Saini
                        Date-: 24-Feb-2018
                        ***********************************************************
                    */
                    if(isLGPaymentByStudent && !lg.LG_Students__r.isEmpty()  && lg.Price_Type__c <> 'Per Group'){ // LG Payment to Student
                        
                        lg2ReCalculateLGPayment2Student.put(lg.Id, new Set<Id>());
                        for(LG_Student__c lgS : lg.LG_Students__r){
                            lg2ReCalculateLGPayment2Student.get(lg.Id).add(lgS.Id); 
                            lgStudentIds.add(lgS.Id);   
                        }
                    }else if(lg.Billing_Type__c == 'Price per Session'){ // LG Payment to LG 
                        
                        lg2ReCalculateLGPayment2Lg.add(lg.Id);
                    }                       
                }
                
                List<LG_Payment__c> lgPayment2Update = new List<LG_Payment__c>();
                List<LG_Payment__c> lgPayment2Insert = new List<LG_Payment__c>(); 
                
                if(!lg2ReCalculateLGPayment2Student.IsEmpty()){
                    
                    system.debug('yyyyyyyyyyyyyyyyyyyyyyy');
                    
                    // Get all LG Payment of the following "lgStudentIds"  
                    Map<Id, Map<Date, LG_Payment__c>> lgPaymentByStudents = new Map<Id, Map<Date, LG_Payment__c>>();
                    for(LG_Payment__c lgP : [SELECT Id, LG_Student__c, LG__c, Planned_Date__c FROM LG_Payment__c WHERE LG_Student__c IN: lgStudentIds]){
                        
                        if(relatedLGIds.get(lgP.LG__c).contains(lgP.Planned_Date__c)){ // Just consider the LG Payments int the LG Lesson month affected.                   
                            if(!lgPaymentByStudents.containsKey(lgP.LG_Student__c)){
                                lgPaymentByStudents.put(lgP.LG_Student__c, new Map<Date, LG_Payment__c>());
                            }
                            lgPaymentByStudents.get(lgP.LG_Student__c).put(lgP.Planned_Date__c, lgP);
                        }
                    }
                    
                    for(LG_Payment__c lgP : LGHelperMethods.getLGPaymentBySessions(lgStudentIds, null, MonitorRecursionClass.GetProcessKey())){
                        
                        // Check if the LG Payment should be inserted because doesn't exist a LG payment for the new month of the related Leasson
                        if(relatedLGIds.get(lgP.LG__c).contains(lgP.Planned_Date__c)){ // Just consider the LG Payments int the LG Lesson month affected.
                            
                            Boolean condition2Insert = !lgPaymentByStudents.containsKey(lgP.LG_Student__c) || (lgPaymentByStudents.containsKey(lgP.LG_Student__c) && !lgPaymentByStudents.get(lgP.LG_Student__c).containsKey(lgP.Planned_Date__c));
                            if(condition2Insert){
                                
                                // Doesn't have LG payment for the specific Planned_Date__c, so we will insert  
                                lgPayment2Insert.add(lgP);
                            }
                            
                            Boolean condition2Update = lgPaymentByStudents.containsKey(lgP.LG_Student__c) && lgPaymentByStudents.get(lgP.LG_Student__c).containsKey(lgP.Planned_Date__c); 
                            if(condition2Update){
                                
                                // Already exist a LG payment for the specific Planned_Date__c, so we will update
                                LG_Payment__c existingLGPayment = lgPaymentByStudents.get(lgP.LG_Student__c).get(lgP.Planned_Date__c);
                                existingLGPayment.Planned_Price__c = lgP.Planned_Price__c;
                                lgPayment2Update.add(existingLGPayment);
                                LG_Payment_TriggerHandler.lgPaymentUpdated.add(existingLGPayment.Id); // Allowing to run the logic of Discount / VAT again
                            }
                            
                            // This will help us to know if the LG Payment should be delete (update to 0).
                            if(lgPaymentByStudents.get(lgP.LG_Student__c) <> null && lgPaymentByStudents.get(lgP.LG_Student__c).containsKey(lgP.Planned_Date__c)){
                                lgPaymentByStudents.get(lgP.LG_Student__c).remove(lgP.Planned_Date__c);
                            }
                        }                   
                    }
                    
                    for(Id lgSId : lgPaymentByStudents.keySet()){
                        
                        // Update the LG Payments that doesn't have any LG Leasson on specific month
                        for(LG_Payment__c lgP : lgPaymentByStudents.get(lgSId).values()){
                            lgP.Planned_Price__c = 0;
                            lgPayment2Update.add(lgP);
                            LG_Payment_TriggerHandler.lgPaymentUpdated.add(lgP.Id); // Allowing to run the logic of Discount / VAT again
                        }
                    }               
                }   
                
                if(!lg2ReCalculateLGPayment2Lg.IsEmpty()){
                    
                    
                    system.debug('xxxxxxxxxxxxxxxxxxxxxxxx');
                    
                    // Get all LG Payment of the following "lgStudentIds"  
                    Map<Id, Map<Date, LG_Payment__c>> lgPaymentByLGs = new Map<Id, Map<Date, LG_Payment__c>>();
                    for(LG_Payment__c lgP : [SELECT Id, LG__c, Planned_Date__c FROM LG_Payment__c WHERE LG__c IN: lg2ReCalculateLGPayment2Lg]){
                        
                        if(relatedLGIds.get(lgP.LG__c).contains(lgP.Planned_Date__c)){ // Just consider the LG Payments int the LG Lesson month affected.
                            if(!lgPaymentByLGs.containsKey(lgP.LG__c)){
                                lgPaymentByLGs.put(lgP.LG__c, new Map<Date, LG_Payment__c>());
                            }
                            lgPaymentByLGs.get(lgP.LG__c).put(lgP.Planned_Date__c, lgP);
                        }
                    }
                    
                    system.debug('lgPaymentByLGs: ' + lgPaymentByLGs);
                    
                    for(LG_Payment__c lgP : LGHelperMethods.getLGPaymentByToLGSessions(lg2ReCalculateLGPayment2Lg, null, MonitorRecursionClass.GetProcessKey())){
                        
                        if(relatedLGIds.get(lgP.LG__c).contains(lgP.Planned_Date__c)){ // Just consider the LG Payments int the LG Lesson month affected.
                            
                            // Check if the LG Payment should be inserted because doesn't exist a LG payment for the new month of the related Leasson
                            Boolean condition2Insert = !lgPaymentByLGs.containsKey(lgP.LG__c) || (lgPaymentByLGs.containsKey(lgP.LG__c) && !lgPaymentByLGs.get(lgP.LG__c).containsKey(lgP.Planned_Date__c));
                            if(condition2Insert){
                                
                                // Doesn't have LG payment for the specific Planned_Date__c, so we will insert  
                                lgPayment2Insert.add(lgP);
                            }
                            
                            Boolean condition2Update = lgPaymentByLGs.containsKey(lgP.LG__c) && lgPaymentByLGs.get(lgP.LG__c).containsKey(lgP.Planned_Date__c);
                            if(condition2Update){
                                
                                // Already exist a LG payment for the specific Planned_Date__c, so we will update
                                LG_Payment__c existingLGPayment = lgPaymentByLGs.get(lgP.LG__c).get(lgP.Planned_Date__c);
                                existingLGPayment.Planned_Price__c = lgP.Planned_Price__c;
                                lgPayment2Update.add(existingLGPayment);
                                LG_Payment_TriggerHandler.lgPaymentUpdated.add(existingLGPayment.Id); // Allowing to run the logic of Discount / VAT again
                            }
                            
                            // This will help us to know if the LG Payment should be delete (update to 0).
                            if(lgPaymentByLGs.get(lgP.LG__c) <> null && lgPaymentByLGs.get(lgP.LG__c).containsKey(lgP.Planned_Date__c)){
                                lgPaymentByLGs.get(lgP.LG__c).remove(lgP.Planned_Date__c);
                            }
                        }
                    }
                    
                    system.debug('lgPayment2Update: ' + lgPayment2Update);
                    
                    for(Id lgId : lgPaymentByLGs.keySet()){
                        
                        // Update the LG Payments that doesn't have any LG Leasson on specific month
                        for(LG_Payment__c lgP : lgPaymentByLGs.get(lgId).values()){
                            lgP.Planned_Price__c = 0;
                            lgPayment2Update.add(lgP);
                            LG_Payment_TriggerHandler.lgPaymentUpdated.add(lgP.Id); // Allowing to run the logic of Discount / VAT again
                        }
                    }               
                }   
                
                if(!lgPayment2Update.isEmpty()){
                    for(LG_Payment__c p : lgPayment2Update){
                        LG_Payment_TriggerHandler.payment2CheckTheRelink.add(p.Id); 
                    }
                    update lgPayment2Update;
                }
                
                if(!lgPayment2Insert.isEmpty()){
                    insert lgPayment2Insert;
                }       
            }   
        }       
    }
    
    public static void deleteRelatedLGPayments(){
        
        if( HD_TriggerSettings.IsTriggerActive('deleteRelatedLGPayments') ){
            if(Trigger.isDelete){
                                
                Map<Id, LG_Payment__c> lgPayment2Del = new Map<Id, LG_Payment__c>();
                for(Integer i=0; i < trigger.size; i++ ){
                    
                    LG_Lesson__c rOld = (LG_Lesson__c)trigger.old[i];
                    if(rOld.LG_Payment__c <> null){
                        lgPayment2Del.put(rOld.LG_Payment__c, new LG_Payment__c(Id = rOld.LG_Payment__c));
                    }
                }
                
                if(!lgPayment2Del.isEmpty()){
                    delete lgPayment2Del.values();
                }
            }
        }
        
    }
}