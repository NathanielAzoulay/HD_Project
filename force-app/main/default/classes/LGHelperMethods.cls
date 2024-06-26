/******************************************************************************* 
Name              : LGHelperMethods
Description       : Contains general Methods for LG logic
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Nicolas                  02/25/2016              
2. Hernan                   02/24/2017                Yaara                [SW-23793]
3. Hernan                   03/30/2017                Daftna               [SW-24333]
4. Hernan                   04/10/2017                Daftna               [SW-24440]
5. Avihai Shindelman        03/07/2018          Gidi Abramovitch        Task-000001699
*******************************************************************************/
public class LGHelperMethods {

    public static List<LG_Lesson__c> getAllLessonsDays(Id lgId, Date fromStartDate){
        
        LG__c lg = [SELECT Id, Course_Sub_Type__r.Base_Course__r.Holiday_Course__c, OwnerId, LG_Type__c, Number_of_Lessons__c, LG_Start_Date__c, LG_End_Date__c, Franchisee__c, Franchisee__r.BillingCountry, Franchisee__r.ParentId, Holiday_Course__c, (SELECT LG__c, Day__c, Start_Hour__c, End_Hour__c, Teacher__c FROM LG_Days_Hours__r), (SELECT Id, Lesson_Date_Hour__c, Lesson_Status__c, LG__r.Holiday_Course__c FROM LG_Lessons__r) FROM LG__c WHERE Id =: lgId];//Avihai added LG__r.Holiday_Course__c and Holiday_Course__c on LG 3/07/2018
                
        if(fromStartDate <> null){ // This case is when from the LG create Lesson button the user should select a Date from the popup.
            lg.LG_Start_Date__c = fromStartDate;
        }
    
        return getAllLessonsDaysHelper(lg, null);
    }
    public static List<LG_Lesson__c> getAllLessonsDaysHelper(LG__c lg, Decimal limitLGLesson){
        
        // Gets all day where we should create a Lesson (we are considering that on same day we could have more than 1 lesson)      
        Map<String, List<LG_Days_Hours__c>> lessonWeekDays = new Map<String, List<LG_Days_Hours__c>>();
        for(LG_Days_Hours__c r : lg.LG_Days_Hours__r){
            if(!lessonWeekDays.containsKey(r.Day__c)){
                lessonWeekDays.put(r.Day__c, new List<LG_Days_Hours__c>());
            }
            lessonWeekDays.get(r.Day__c).add(r);
        }
        
        // TODO ask if we could have null end date...
        Map<Date, List<Holiday_Vacation__c>> holidaysByCountry =  new Map<Date, List<Holiday_Vacation__c>>();       
        if(lg.Franchisee__r.BillingCountry <> null){
            holidaysByCountry = getHolidaysBy([SELECT Start_Date__c, End_Date__c, Work_Day__c FROM Holiday_Vacation__c WHERE RecordTypeId =: Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('Country').getRecordTypeId() AND Country__c =: lg.Franchisee__r.BillingCountry AND ((Start_Date__c <=: lg.LG_Start_Date__c AND End_Date__c >=: lg.LG_Start_Date__c) OR (Start_Date__c >=: lg.LG_Start_Date__c AND End_Date__c <=: lg.LG_End_Date__c) OR (Start_Date__c <=: lg.LG_End_Date__c AND End_Date__c >=: lg.LG_End_Date__c) ) ]);
        }
        
        Map<Date, List<Holiday_Vacation__c>> holidaysByLC =  new Map<Date, List<Holiday_Vacation__c>>();        
        if(lg.Franchisee__c <> null){
            holidaysByLC = getHolidaysBy([SELECT Start_Date__c, End_Date__c, Work_Day__c FROM Holiday_Vacation__c WHERE RecordTypeId =: Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('LC').getRecordTypeId() AND LC__c =: lg.Franchisee__c AND ((Start_Date__c <=: lg.LG_Start_Date__c AND End_Date__c >=: lg.LG_Start_Date__c) OR (Start_Date__c >=: lg.LG_Start_Date__c AND End_Date__c <=: lg.LG_End_Date__c) OR (Start_Date__c <=: lg.LG_End_Date__c AND End_Date__c >=: lg.LG_End_Date__c) ) ]);
        }
        
        Map<Date, List<Holiday_Vacation__c>> holidaysByMF =  new Map<Date, List<Holiday_Vacation__c>>();        
        if(lg.Franchisee__r.ParentId <> null || lg.Franchisee__c <> null){
            holidaysByMF = getHolidaysBy([SELECT Start_Date__c, End_Date__c, Work_Day__c FROM Holiday_Vacation__c WHERE RecordTypeId =: Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('MF').getRecordTypeId() AND (MF__c =: lg.Franchisee__c /*SW-25305*/ OR MF__c =: lg.Franchisee__r.ParentId) AND ((Start_Date__c <=: lg.LG_Start_Date__c AND End_Date__c >=: lg.LG_Start_Date__c) OR (Start_Date__c >=: lg.LG_Start_Date__c AND End_Date__c <=: lg.LG_End_Date__c) OR (Start_Date__c <=: lg.LG_End_Date__c AND End_Date__c >=: lg.LG_End_Date__c) ) ]);
        }
        
        Integer dDiff = lg.LG_Start_Date__c.daysBetween(lg.LG_End_Date__c) + 1; // +1 for considering the same day; 
        Datetime currentDate = lg.LG_Start_Date__c;
        List<LG_Lesson__c> allLessons = new List<LG_Lesson__c>();
        
        Set<Datetime> existingLGdates = new Set<Datetime>();
        Set<String> existingLGdatesGMT = new Set<String>();
        Integer nroOfLGLessonAdded = 0;
        for(LG_Lesson__c lgLesson : lg.LG_Lessons__r){
            existingLGdates.add(lgLesson.Lesson_Date_Hour__c);
            if(lgLesson.Lesson_Status__c != 'Day Off'){
                nroOfLGLessonAdded++;
            }
        }
        
        User lgOwnerUser = [SELECT Id, TimeZoneSidKey FROM User WHERE Id =: lg.OwnerId];
        
        List<String> listDay = new List<String>{'Sat' , 'Sun' , 'Mon' , 'Tue' , 'Wed' , 'Thu' , 'Fri'};
        Date startDate = date.newInstance(0001, 1, 1);
        
        Date currentDateGMT = currentDate.dateGMT();
        
        // Get the Offset to create the LG Lessons on TimeZone User (LG Owner timezone)     
        Timezone tzLGOwner = Timezone.getTimeZone(lgOwnerUser.TimeZoneSidKey);
        Integer offSetInMinutes = tzLGOwner.getOffset(system.now()/*GMT*/)/1000/60;
        
        Long rollback_key = system.now().getTime();
        LG__c lg_ff = [SELECT Id, Holiday_Course__c FROM LG__c WHERE Id = : lg.Id];
        lg_ff.recalculateFormulas();
        
        for(Integer i = 0; i < dDiff; i++){
            
            Integer remainder = Math.mod(startDate.daysBetween(currentDateGMT), 7);
            String sDay = listDay.get(remainder); // currentDate.format('E'); Problem with the Timezone
            DayOff isDO = isDayOff(currentDateGMT, holidaysByCountry, holidaysByMF, holidaysByLC);
            if(lessonWeekDays.containsKey(sDay)){
                for(LG_Days_Hours__c r : lessonWeekDays.get(sDay)){
                    
                    List<String> sHour = r.Start_Hour__c.split(':');
                    List<String> eHour = r.End_Hour__c.split(':'); 
                    Datetime sDate = Datetime.newInstanceGMT(currentDateGMT.year(), currentDateGMT.month(), currentDateGMT.day(), Integer.valueOf(sHour[0]), Integer.valueOf(sHour[1]), 0);
                    Datetime eDate = Datetime.newInstanceGMT(currentDateGMT.year(), currentDateGMT.month(), currentDateGMT.day(), Integer.valueOf(eHour[0]), Integer.valueOf(eHour[1]), 0);
                    
                    system.debug(system.LoggingLevel.INFO, 'sDate: ' + sDate);
                    
                    // Move the datetimes to the correct GMT
                    sDate = sDate.addMinutes(-offSetInMinutes);
                    eDate = eDate.addMinutes(-offSetInMinutes);
                    system.debug(system.LoggingLevel.INFO, 'sDate2: ' + sDate);                 
                    
                    if(!existingLGdates.contains(sDate)){ // We skip already existing LG Lesson
                        system.debug('LG ID == '+lg.Id + ' lg.Holiday_Course__c == ' + lg.Holiday_Course__c + ' lg.Course_Sub_Type__r.Base_Course__r.Holiday_Course__c=='+lg.Course_Sub_Type__r.Base_Course__r.Holiday_Course__c);
                         //Avihai Task-000001699 - check if LG is Holiday Course, then Lesson Status should not markded as 'Day Off'                        
                        if (lg_ff.Holiday_Course__c == true){                            
                            allLessons.add(new LG_Lesson__c(LG_Days_Hours__c = r.Id, Rollback_Key__c = rollback_key, LG__c = lg.Id, Lesson_Type__c = lg.LG_Type__c, Lesson_Teacher__c = r.Teacher__c, Lesson_Original_Date__c = sDate, Lesson_Date_Hour__c = sDate, Lesson_End_Hour__c = eDate, Holiday__c = isDO.relatedWorkDay!=null?isDO.relatedWorkDay.Id:null, Lesson_Status__c = null));
                        }if (lg_ff.Holiday_Course__c == false) allLessons.add(new LG_Lesson__c(LG_Days_Hours__c = r.Id, Rollback_Key__c = rollback_key, LG__c = lg.Id, Lesson_Type__c = lg.LG_Type__c, Lesson_Teacher__c = r.Teacher__c, Lesson_Original_Date__c = sDate, Lesson_Date_Hour__c = sDate, Lesson_End_Hour__c = eDate, Holiday__c = isDO.relatedWorkDay!=null?isDO.relatedWorkDay.Id:null, Lesson_Status__c = isDO.isDayOff?'Day Off':null));
                        
                        if(!isDO.isDayOff){
                            nroOfLGLessonAdded++;
                        }
                        
                        if(limitLGLesson <> null && nroOfLGLessonAdded >= limitLGLesson){ // When we are creating the LG Lesson by Nro Of Lessons (and not by end date)
                            break;
                        }
                    }
                }
                
            }
            currentDateGMT = currentDateGMT.addDays(1);
            
            if(limitLGLesson <> null && nroOfLGLessonAdded >= limitLGLesson){ // When we are creating the LG Lesson by Nro Of Lessons (and not by end date)
                break;
            }           
        }
        return allLessons;
    }
    
    
    public static List<LG_Lesson__c> getAllLessonsDaysByNumberOfLessons(Id lgId, Decimal nroOfLessons, Date fromStartDate){
        
        LG__c lg = [SELECT Id, LG_Type__c, Number_of_Lessons__c, LG_Start_Date__c, LG_End_Date__c, Franchisee__c, Franchisee__r.BillingCountry, Franchisee__r.ParentId, OwnerId, (SELECT LG__c, Day__c, Start_Hour__c, End_Hour__c, Teacher__c FROM LG_Days_Hours__r), (SELECT Id, Lesson_Date_Hour__c, Lesson_Status__c FROM LG_Lessons__r) FROM LG__c WHERE Id =: lgId];
        
        // We will apply a trick for allowing us to re-use all the existing logic and avoid duplicate code. 
        // So, the trick here is to increase the end date until a possible end date that allow use to get/create the necessary "nroOfLessons" LG Lessons records.
        // Comment: the internal method will stop when reach the nroOfLessons LG Lessons records. 
        
        // Starting the trick
        // Get the maximun possible week leasson days.
        Integer nroOflessonWeekDays = 0;
        for(LG_Days_Hours__c r : lg.LG_Days_Hours__r){
            nroOflessonWeekDays += 1;
        }
        
        // Get the maximun Nro Of Lessons per months
        Decimal maximunNroOfLessonsPerMonth = nroOflessonWeekDays * 4; // without consider any holidays
        Integer neededMonthForCompleteTheNroOfLessons = Integer.valueOf(nroOfLessons / maximunNroOfLessonsPerMonth) + 1; // + 1 For saving the 0 
        
        // Dummy update (we will not save this) to increase the End Date untils safe place (that will allowing us to reach the goal)
        lg.LG_End_Date__c = lg.LG_Start_Date__c.addMonths(neededMonthForCompleteTheNroOfLessons+4); // since we didn't consider any holidays for being on safe place we are consider + 4 months nro of the month.
        if(fromStartDate <> null){ // This case is when from the LG create Lesson button the user should select a Date from the popup.
            lg.LG_Start_Date__c = fromStartDate;
        }
        
        return getAllLessonsDaysHelper(lg, nroOfLessons);
    }
    
    public static Map<Date, List<Holiday_Vacation__c>> getHolidaysBy(List<Holiday_Vacation__c> listOfHolidays){
        
        Map<Date, List<Holiday_Vacation__c>> holidaysBy =  new Map<Date, List<Holiday_Vacation__c>>();
        for(Holiday_Vacation__c h : listOfHolidays){
                
            Integer dDiff = h.Start_Date__c.daysBetween(h.End_Date__c) + 1; // +1 for considering the same day
            Date currentDate = h.Start_Date__c;
            for(Integer i = 0; i < dDiff; i++){
                if(!holidaysBy.containsKey(currentDate)){
                    holidaysBy.put(currentDate, new List<Holiday_Vacation__c>());
                }
                holidaysBy.get(currentDate).add(h);
                currentDate = currentDate.addDays(1);
            }
        }
        return holidaysBy;
    }
    
    public class DayOff{
        
        public boolean isDayOff {get;set;} 
        public Holiday_Vacation__c relatedWorkDay {get;set;}
        
        public DayOff(boolean isDayOff, Holiday_Vacation__c relatedWorkDay){
            this.isDayOff = isDayOff;
            this.relatedWorkDay = relatedWorkDay;
        }
    }
    
    public static DayOff isDayOff(Date currentDate, Map<Date, List<Holiday_Vacation__c>> hByCountry, Map<Date, List<Holiday_Vacation__c>> hByMF, Map<Date, List<Holiday_Vacation__c>> hByLC){
        
        Holiday_Vacation__c dayOffWorkDay;
        Holiday_Vacation__c dayOffNotWorkDay; 
        Boolean existHolidayByCountryWDOFF = false;
        Boolean existHolidayByCountryWDONFF = false;
        if(hByCountry.containsKey(currentDate)){
            for(Holiday_Vacation__c h : hByCountry.get(currentDate)){
                existHolidayByCountryWDOFF |= !h.Work_Day__c;
                existHolidayByCountryWDONFF |= h.Work_Day__c;
                if(h.Work_Day__c){
                    dayOffWorkDay = h;
                }else{
                    dayOffNotWorkDay = h;
                }
            }
        }
        
        Boolean existHolidayWDOFFByMF = false;
        Boolean existHolidayWDONByMF = false;
        if(hByMF.containsKey(currentDate)){
            for(Holiday_Vacation__c h : hByMF.get(currentDate)){
                existHolidayWDOFFByMF |= !h.Work_Day__c; // get Off
                existHolidayWDONByMF  |= h.Work_Day__c;  // get ON
                if(h.Work_Day__c){
                    dayOffWorkDay = h;
                }else{
                    dayOffNotWorkDay = h;
                }
            }
        }
        
        Boolean existHolidayWDOFFByLC = false;
        Boolean existHolidayWDONByLC = false;
        if(hByLC.containsKey(currentDate)){
            for(Holiday_Vacation__c h : hByLC.get(currentDate)){
                existHolidayWDOFFByLC |= !h.Work_Day__c; // get Off
                existHolidayWDONByLC  |= h.Work_Day__c;  // get ON
                if(h.Work_Day__c){
                    dayOffWorkDay = h;
                }else{
                    dayOffNotWorkDay = h;
                }
            }
        }
        
        // Checking the Hierarchy: (Weak) Country -> MF -> LC (Strong).
        Boolean condition = existHolidayByCountryWDOFF && !existHolidayWDONByMF && !existHolidayWDONByLC; // The Level MF or LC could invalidate the Country Level
        condition |= existHolidayWDOFFByMF && !existHolidayWDONByLC; // The Level LC could invalidate the MF Level
        condition |= existHolidayWDOFFByLC; // There is not invalidation here by Hierarchy.
        
        return new DayOff(condition, condition?dayOffNotWorkDay:dayOffWorkDay); 
    }

    /*  Description: 
        Method that calculate the LG Payment to Students taking into consideration the existing LG_Student_Attendance__c records related with the 'lgStudentIds' Lg Students.
        In addition, in case that the parameter reCalculateMonths is not empty, the logic will just consider the lastDayOfMonth included on the set 'reCalculateMonths'
        Comment: the rollback_key is just using on batch process for doing the rollback in case that it's necessary. 
    */
    public static List<LG_Payment__c> getLGPaymentBySessions(Set<Id> lgStudentIds, Set<String> reCalculateMonths, Decimal rollback_key){
        
        Map<Id, LG_Student__c> lgStudents = new Map<Id, LG_Student__c>([SELECT Id, LG__c, Payment_Method__c, Student__r.Payment_Method__c, Price_for_Payment__c, LG__r.CurrencyIsoCode FROM LG_Student__c WHERE Id IN: lgStudentIds]);
        List<LG_Payment__c> lgPayment2Insert = new List<LG_Payment__c>();
        
        //Updated By-: Shivram Saini    Date-: 29 Nov 2018    Task-000001961
        List<AggregateResult> ars;
        system.debug('******'+MonitorRecursionClass.isRunningInitialCreateAutomaticLGLessonsByBatch);
        if(MonitorRecursionClass.isRunningInitialCreateAutomaticLGLessonsByBatch == false){
            ars = [SELECT LG_Student__c, CALENDAR_YEAR(LG_Lesson__r.Lesson_Date_Hour__c) y, CALENDAR_MONTH(LG_Lesson__r.Lesson_Date_Hour__c) m, COUNT(Id) nro FROM LG_Student_Attendance__c WHERE LG_Lesson__r.Lesson_Status__c != 'Cancelled' AND LG_Lesson__r.Lesson_Status__c != 'Day Off' AND LG_Student__c IN: lgStudents.keySet() AND (LG_Student__r.Status_in_LG__c = 'Registered' OR LG_Student__r.Status_in_LG__c = 'Completed') AND (LG_Student__r.LG__r.Declared_Number_of_Students__c = NULL OR LG_Student__r.LG__r.Declared_Number_of_Students__c = 0) AND LG_Student__r.Billing_Type__c = 'Price per Session' GROUP By LG_Student__c, CALENDAR_YEAR(LG_Lesson__r.Lesson_Date_Hour__c), CALENDAR_MONTH(LG_Lesson__r.Lesson_Date_Hour__c)]; // (Declared_Number_of_Students__c = NULL OR Declared_Number_of_Students__c = 0) with this condition we are calculating just the LG payment to Student   
        }else{
            // SW-26135 when we are running the initial batch we should consider Status completed
            ars = [SELECT LG_Student__c, CALENDAR_YEAR(LG_Lesson__r.Lesson_Date_Hour__c) y, CALENDAR_MONTH(LG_Lesson__r.Lesson_Date_Hour__c) m, COUNT(Id) nro FROM LG_Student_Attendance__c WHERE LG_Lesson__r.Lesson_Status__c != 'Cancelled' AND LG_Lesson__r.Lesson_Status__c != 'Day Off' AND LG_Student__c IN: lgStudents.keySet() AND (LG_Student__r.Status_in_LG__c = 'Registered' OR (LG_Student__r.LG__r.Group_Status__c = 'Completed' AND (LG_Student__r.Status_in_LG__c = 'Drop-Out' OR LG_Student__r.Status_in_LG__c = 'Moved' OR LG_Student__r.Status_in_LG__c = 'Completed'))) AND (LG_Student__r.LG__r.Declared_Number_of_Students__c = NULL OR LG_Student__r.LG__r.Declared_Number_of_Students__c = 0) AND LG_Student__r.Billing_Type__c = 'Price per Session' GROUP By LG_Student__c, CALENDAR_YEAR(LG_Lesson__r.Lesson_Date_Hour__c), CALENDAR_MONTH(LG_Lesson__r.Lesson_Date_Hour__c)]; // (Declared_Number_of_Students__c = NULL OR Declared_Number_of_Students__c = 0) with this condition we are calculating just the LG payment to Student;
        }
        system.debug('ars'+ars.size());
        for(AggregateResult ar : ars){
                    
            Integer iMonth = (Integer)ar.get('m');
            Integer iYear = (Integer)ar.get('y');
                    
            Integer numberOfDays = Date.daysInMonth(iYear, iMonth);
            Date lastDayOfMonth  = Date.newInstance(iYear, iMonth, numberOfDays);
            
            LG_Student__c s = lgStudents.get((Id)ar.get('LG_Student__c'));
            String key = s.Id + '|' + lastDayOfMonth;           
            if(reCalculateMonths == null || reCalculateMonths.contains(key)){
                String paymentMenthod = string.isBlank(s.Payment_Method__c)?s.Student__r.Payment_Method__c:s.Payment_Method__c;
                lgPayment2Insert.add(new LG_Payment__c(Rollback_Key__c = rollback_key, LG__c = s.LG__c, CurrencyIsoCode = s.LG__r.CurrencyIsoCode, LG_Student__c = s.Id, Payment_Type__c = 'Standard', Payment_Method__c = string.isBlank(paymentMenthod)?'Credit Card':paymentMenthod, Planned_Date__c = lastDayOfMonth, Planned_Price__c = s.Price_for_Payment__c*(Integer)ar.get('nro')));   
            }
        }
        
        system.debug('>>> lgPayment2Insert: ' + lgPayment2Insert);
        
        return lgPayment2Insert;
    }
    
    /*  Description: 
        Method that calculate the LG Payment to LG taking into consideration the existing LG_Lesson__c records related with the 'lgIds' LGs.
        In addition, in case that the parameter reCalculateMonths is not empty, the logic will just consider the lastDayOfMonth included on the set 'reCalculateMonths'
        Comment: the rollback_key is just using on batch process for doing the rollback in case that it's necessary.
        
        1. Hernan Sinclair         02/16/2017            Yaara                   [SW-23645] 
    */
    public static List<LG_Payment__c> getLGPaymentByToLGSessions(Set<Id> lgIds, Set<String> reCalculateMonths, Decimal rollback_key){
        
        Map<Id, LG__c> allLGs = new Map<Id, LG__c>([SELECT Id, Billing_Type__c, Price_Charge__c, Price_for_Payment__c, Declared_Number_of_Students__c, Payment_Method__c, CurrencyIsoCode FROM LG__c WHERE Id IN: lgIds]);
        
        List<LG_Payment__c> lgPayment2Insert = new List<LG_Payment__c>();
        for(AggregateResult ar : [SELECT LG__c, CALENDAR_YEAR(Lesson_Date_Hour__c) y, CALENDAR_MONTH(Lesson_Date_Hour__c) m, COUNT(Id) nro FROM LG_Lesson__c WHERE Lesson_Status__c != 'Cancelled' AND Lesson_Status__c != 'Day Off' AND LG__c IN: lgIds AND LG__r.Billing_Type__c = 'Price per Session' AND ((LG__r.Declared_Number_of_Students__c != NULL AND LG__r.Declared_Number_of_Students__c != 0) OR LG__r.Price_Type__c = 'Per Group' /*New condition SW-23645*/) GROUP By LG__c, CALENDAR_YEAR(Lesson_Date_Hour__c), CALENDAR_MONTH(Lesson_Date_Hour__c)]){ // (Declared_Number_of_Students__c <> NULL && Declared_Number_of_Students__c <> 0) with this condition we are calculating just the LG payment to LG
                    
            Integer iMonth = (Integer)ar.get('m');
            Integer iYear = (Integer)ar.get('y');
                    
            Integer numberOfDays = Date.daysInMonth(iYear, iMonth);
            Date lastDayOfMonth  = Date.newInstance(iYear, iMonth, numberOfDays);
            
            LG__c lg = allLGs.get((Id)ar.get('LG__c'));
            
            String key = lg.Id + '|' + lastDayOfMonth;  
                
            if(reCalculateMonths == null || reCalculateMonths.contains(key)){
                Decimal price = lg.Price_Charge__c;
                if(lg.Billing_Type__c == 'Price per Session'){ // SW-24333
                    price = lg.Price_for_Payment__c;
                }
                lgPayment2Insert.add(new LG_Payment__c(Rollback_Key__c = rollback_key, LG__c = lg.Id, CurrencyIsoCode = lg.CurrencyIsoCode, Payment_Type__c = 'Standard', Payment_Method__c = lg.Payment_Method__c==null?'Credit Card':lg.Payment_Method__c, Planned_Date__c = lastDayOfMonth, Planned_Price__c =  price*(Integer)ar.get('nro') /* No need to multiply by Declare number of Students (QA-SW-18006) * lg.Declared_Number_of_Students__c */));    
            }
        }               
        return lgPayment2Insert;
    }
    
    /*  Description: 
        Method that will delete the LG Payment to Student related with the attendances 'studentsAtt2Del'. Also, if the parameters 'shouldDeleteAttendance' is true will delete the attendances 'studentsAtt2Del'.
        In additional this method will retrieve the remain (not yet on database) LG payments without consider the deleted att.    
    */
    public static Map<String, LG_Payment__c> deleteLGStudentAttendanceAndItsLGPayments(List<LG_Student_Attendance__c> studentsAtt2Del, Boolean shouldDeleteAttendance, Decimal rollback_key){
        
        Set<Id> attIds2Del  = new Set<Id>();
        Map<Id, LG_Payment__c> p2Del = new Map<Id, LG_Payment__c>();
        
        for(LG_Student_Attendance__c att : studentsAtt2Del){
            if(att.LG_Payment__c != null){                  
                attIds2Del.add(att.Id);
                p2Del.put(att.LG_Payment__c, new LG_Payment__c(Id = att.LG_Payment__c));
            }
        }
        
        Map<String, LG_Payment__c> p2Ins = new Map<String, LG_Payment__c>();
        Map<String, Integer> remainAttByPayment = new Map<String, Integer>();
        // Recalculate the LG Payment to Student without consider the Attendances 'studentsAtt2Del'
        for(LG_Student_Attendance__c att : [SELECT LG_Payment__c, LG_Payment__r.LG__c, LG_Payment__r.LG_Student__c, LG_Student__r.LG__r.CurrencyIsoCode, LG_Payment__r.LG_Student__r.Price_for_Payment__c, LG_Payment__r.Planned_Date__c, LG_Payment__r.Payment_Method__c, LG_Payment__r.Payment_Type__c FROM LG_Student_Attendance__c WHERE LG_Payment__c IN: p2Del.keySet() AND Id NOT IN: attIds2Del]){
            
            p2Ins.put(att.LG_Payment__c, new LG_Payment__c(Rollback_Key__c = rollback_key, LG__c = att.LG_Payment__r.LG__c, CurrencyIsoCode = att.LG_Student__r.LG__r.CurrencyIsoCode, LG_Student__c = att.LG_Payment__r.LG_Student__c, Payment_Type__c = att.LG_Payment__r.Payment_Type__c, Payment_Method__c =  att.LG_Payment__r.Payment_Method__c, Planned_Date__c = att.LG_Payment__r.Planned_Date__c, Planned_Price__c = att.LG_Payment__r.LG_Student__r.Price_for_Payment__c));
            // pending * on Planned_Price__c
            if(!remainAttByPayment.containsKey(att.LG_Payment__c)){
                remainAttByPayment.put(att.LG_Payment__c,0);
            } 
            remainAttByPayment.put(att.LG_Payment__c, remainAttByPayment.get(att.LG_Payment__c)+1);
        }
        
        // Basic price calculation. The Vat and Discount are calculating on LG Payment trigger.   
        for(String pId : p2Ins.KeySet()){
            // doing * on Planned_Price__c          
            p2Ins.get(pId).Planned_Price__c = (p2Ins.get(pId).Planned_Price__c * remainAttByPayment.get(pId));
        }
        
        // Delete the LG payments
        if(!p2Del.isEmpty()){
            delete p2Del.values();
        }
        
        // Delete the attendances
        if(shouldDeleteAttendance && !studentsAtt2Del.isEmpty()){
            delete studentsAtt2Del;
        }
        
        // Return the remain att payments 
        return p2Ins;
    }
    
    
    private static Set<Id> cacheDiscountIds = new Set<Id>(); 
    private static Map<Id, Map<String, LG_Discount__c>> oneTimeDiscountByLGIds = new Map<Id, map<String, LG_Discount__c>>(); 
    private static Map<Id, List<LG_Discount__c>> entireCourseWithoutLGStudentDiscountByLGIds = new Map<Id, List<LG_Discount__c>>();
    private static Map<Id, Map<Id, LG_Discount__c>> entireCourseWithLGStudentDiscountByLGIds = new Map<Id, Map<Id, LG_Discount__c>>();
    
    /*  Description: 
        Method that retrieve a Map structure with the LG discounts by Month/Year (+ optional LG Student in case that the Discount is for specifict student).
    */
    public static Map<Id, map<String, LG_Discount__c>> getOneTimeLGDiscounts(Set<Id> lgIds){
        getDiscounts(lgIds);
        return oneTimeDiscountByLGIds;
    }
    
    public static  Map<Id, List<LG_Discount__c>> getEntireCourseWithoutLGStudentLGDiscounts(Set<Id> lgIds){
        getDiscounts(lgIds);
        return entireCourseWithoutLGStudentDiscountByLGIds;
    }
    
    public static  Map<Id, Map<Id, LG_Discount__c>> getEntireCourseWithLGStudentLGDiscounts(Set<Id> lgIds){
        getDiscounts(lgIds);
        return entireCourseWithLGStudentDiscountByLGIds;
    }
        
    private static void getDiscounts(Set<Id> lgIds){ 

        Boolean hasNew = false;

        //check if already exist in cache
        for(Id lgId : lgIds){
            if(!cacheDiscountIds.contains(lgId)){
                hasNew = true;
            
                cacheDiscountIds.add(lgId);
                oneTimeDiscountByLGIds.put(lgId, new map<String, LG_Discount__c>());
                entireCourseWithLGStudentDiscountByLGIds.put(lgId, new Map<Id, LG_Discount__c>());
                entireCourseWithoutLGStudentDiscountByLGIds.put(lgId, new List<LG_Discount__c>());
            }               
        }
         
         //if not exist add them
        if(hasNew){
            // -- CALCULATING THE DISCOUNT --
            for(LG_Discount__c d : [SELECT LG__c, LG_Student__c, Month__c, Year__c,  Approved_Price_per_Session__c, Approved_Price_per_Month__c, Approved_Price__c, Approved_Course_Price__c, Discount_Type__c, Billing_Type__c FROM LG_Discount__c WHERE LG__c IN: cacheDiscountIds AND Discount_Status__c = 'Approved']){
                if(d.Discount_Type__c == 'One Time (Month)'){
                    String key = GlobalHelperMethods.getIMonth(d.Month__c) + '/' + d.Year__c + (d.LG_Student__c != null?(''+d.LG_Student__c):''); 
                    oneTimeDiscountByLGIds.get(d.LG__c).put(key, d);
                }else if(d.Discount_Type__c == 'Entire course'){
                    if(d.LG_Student__c <> null){
                        entireCourseWithLGStudentDiscountByLGIds.get(d.LG__c).put(d.LG_Student__c,d);
                    }else{                      
                        entireCourseWithoutLGStudentDiscountByLGIds.get(d.LG__c).add(d);
                    }
                }
            }
        }
    }
    


    /* Description: 
        Method that populate the VAT field taking from Trigger.new[i] (LG Payment) and generalized
        
        Observation: in case that the VAT logic should be change. Please keep update the related method "LG_Payment_TriggerHandler.applyVAT2LGPayments()" in case that should be necessary applyVAT2LGPayments
    */
    public static void applyVAT2LGPayments(Set<Id> franchiseeAccIds, Set<Id> payments){
        
        // -- CALCULATING THE VAT --
        Map<Id, List<Franchisee_VAT__c>> fVats = new Map<Id, List<Franchisee_VAT__c>>();
        
        try{
            
            for(Franchisee_VAT__c vat : [SELECT Id, Franchisee__c, VAT__c, VAT_From_Date__c , VAT_End_Date__c FROM Franchisee_VAT__c WHERE Franchisee__c IN: franchiseeAccIds ORDER BY VAT_From_Date__c ASC]){
                
                if(vat.Franchisee__c <> null){
                    
                    if(!fVats.containsKey(vat.Franchisee__c)){
                        fVats.put(vat.Franchisee__c, new List<Franchisee_VAT__c>());
                    }
                    fVats.get(vat.Franchisee__c).add(vat);
                }
            }       

            List<LG_Payment__c> payments2up = new List<LG_Payment__c>();
            for(LG_Payment__c payment : [SELECT Id, LG_Student__c, LG_Student__r.Not_include_VAT__c, LG_Student__r.LG__r.Franchisee__c, LG_Student__r.LG__r.Franchisee__r.ParentId, LG__c, LG__r.Franchisee__c , LG__r.Franchisee__r.ParentId, Planned_Date__c, VAT__c, Franchisee_VAT__c FROM LG_Payment__c WHERE (LG__r.Franchisee__c IN :franchiseeAccIds OR LG__r.Franchisee__r.ParentId IN :franchiseeAccIds OR LG_Student__r.LG__r.Franchisee__r.ParentId IN :franchiseeAccIds) AND Id IN :payments]){

                System.debug(System.LoggingLevel.ERROR, 'Payment Val --> ' + payment);
                    
                Boolean notIncludeVAT = false;
                Id franchiseId, parentFranchiseId;

                if(payment.LG_Student__c <> null){  
                    
                    // LG Payment to Student
                    notIncludeVAT = (payment.LG_Student__r.Not_include_VAT__c == true);
                    franchiseId = payment.LG_Student__r.LG__r.Franchisee__c;
                    parentFranchiseId = payment.LG_Student__r.LG__r.Franchisee__r.ParentId;
                }else{
                    
                    // LG Payment to LG             
                    franchiseId = payment.LG__r.Franchisee__c;
                    parentFranchiseId = payment.LG__r.Franchisee__r.ParentId;
                }   
                
                // By Default
                payment.VAT__c = 0; 
                payment.Franchisee_VAT__c = null;

                if(!notIncludeVAT){
                    
                    Boolean finish = false;
                    if(fVats.containsKey(franchiseId)){ // Check if exist a Vat range for the payment
                        
                        for(Franchisee_VAT__c f : fVats.get(franchiseId)){
                            
                            Boolean condition = payment.Planned_Date__c >= f.VAT_From_Date__c && (f.VAT_End_Date__c == null || payment.Planned_Date__c <= f.VAT_End_Date__c);    
                            if(condition){
                                payment.VAT__c = f.VAT__c;  
                                payment.Franchisee_VAT__c = f.Id;
                                finish = true;
                                break;
                            }
                        }
                    }
                    
                    if(!finish && parentFranchiseId <> null){
                        
                        if(fVats.containsKey(parentFranchiseId)){ // Check if exist a Vat range for the payment
                            
                            for(Franchisee_VAT__c f : fVats.get(parentFranchiseId)){
                                
                                Boolean condition = payment.Planned_Date__c >= f.VAT_From_Date__c && (f.VAT_End_Date__c == null || payment.Planned_Date__c <= f.VAT_End_Date__c);  
                                if(condition){
                                    payment.VAT__c = f.VAT__c;
                                    payment.Franchisee_VAT__c = f.Id;   
                                    finish = true;
                                    break;
                                }
                            }
                        }                       
                    }

                }

                System.debug(System.LoggingLevel.ERROR, 'Payment new Val --> ' + payment);

                payments2up.add(payment);
            }// end for.    

            if(!payments2up.isEmpty()){

                List<Database.SaveResult> slr = Database.update(payments2up,false); // due to the SW-18017 QA - Get Error when try it
                for(Integer i = 0; i < slr.size(); i++){
                    Database.SaveResult sr = slr.get(i);
                    if(!sr.isSuccess()){
                        System.debug(System.LoggingLevel.ERROR, 'Payment Update Error --> ' + payments2up[i] + ' ' + sr.getErrors());
                    }
                }
            }
        }catch(Exception e){
            System.debug( e.getMessage() + ' Line: ' + e.getLineNumber());        
        }
    }
    
    /******************************************************************************* 
    Name              : Helper method "checkCondition2RecreateLGPayment2LG"
    Description       : Method that will validate some conditions before generate LG payment to LG from the LG. 
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. Hernan                   06/07/2016              Yaara                 SW-19459
    2. Hernan                   02/17/2017              Yaara                 SW-23715
    3. Hernan                   03/07/2017              Yaara                 SW-23973
    *******************************************************************************/
    public static String checkCondition2RecreateLGPayment2LG(LG__c lg){
        
        Set<Id> profileWithPermission2CreatePaymentWithoutMonthLimit = new Set<Id>();
        if(HD_Settings_List__c.getInstance('Generate Payment Profiles') <> null){
            for(String profId : HD_Settings_List__c.getInstance('Generate Payment Profiles').Value__c.split(',')){
                profileWithPermission2CreatePaymentWithoutMonthLimit.add(Id.valueOf(profId));
            }
        }
        
        String result = '';
        if(lg.Price_Type__c == 'Per Student' && (lg.Declared_Number_of_Students__c == 0 || lg.Declared_Number_of_Students__c == null)){
            result = Label.PriceType_Per_Student_on_LG_Payments;
        }else if(lg.LG_Start_Paying_Date__c <> null && lg.LG_Start_Paying_Date__c.addDays(30) < system.today() && !profileWithPermission2CreatePaymentWithoutMonthLimit.contains(Userinfo.getProfileId())){
            result = Label.Generate_payments_to_LG_days_after_the_LG_Start_paying_Date;
        }       
        return result;
    }
    
    /******************************************************************************* 
    Name              : Helper method "checkCondition2RecreateLGPayment2LGStudent"
    Description       : Method that will validate some conditions before generate LG Payment to Student from LG Student. 
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. Hernan                   06/07/2016              Yaara                 SW-19460
    2. Hernan                   02/17/2017              Yaara                 SW-23716
    3. Hernan                   03/07/2017              Yaara                 SW-23973
    *******************************************************************************/
    public static String checkCondition2RecreateLGPayment2LGStudent(LG_Student__c lgS){
        
        Set<Id> profileWithPermission2CreatePaymentWithoutMonthLimit = new Set<Id>();
        if(HD_Settings_List__c.getInstance('Generate Payment Profiles') <> null){
            for(String profId : HD_Settings_List__c.getInstance('Generate Payment Profiles').Value__c.split(',')){
                profileWithPermission2CreatePaymentWithoutMonthLimit.add(Id.valueOf(profId));
            }
        }
        
        String result = '';
        if(lgS.LG__r.Price_Type__c == 'Per Group' || (lgS.LG__r.Price_Type__c == 'Per Student' && lgS.LG__r.Declared_Number_of_Students__c > 0)){
            result = Label.Generate_payments_to_LG_Student_PriceType_Per_Group_on_LG_Payments;
        }else if(lgS.Student_Start_Paying_Date__c <> null && lgS.Student_Start_Paying_Date__c.addDays(30) < system.today() && !profileWithPermission2CreatePaymentWithoutMonthLimit.contains(Userinfo.getProfileId())){
            result = Label.Generate_payments_to_LG_Student_days_after_the_LG_Start_paying_Date;
        }       
        return result;
    }
    
    /******************************************************************************* 
    Name              : generate_LGPayments2LG
    Description       : Method that will allow to re-create the LG payment to LG from the LG. 
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. Hernan                   06/07/2016              Yaara                 SW-19459
    2. Hernan                   02/17/2017              Yaara                 SW-23715
    3. Hernan                   03/07/2017              Yaara                 SW-23973
    *******************************************************************************/
    public static void doRecreateLGPayment2LG(Set<Id> lgIds){
        
        String sQuery = GlobalHelperMethods.getQueryString(new LG__c());        
        sQuery = 'SELECT ' + ' (SELECT Id FROM LG_Payments__r WHERE LG_Student__c = null AND (Actual_Price__c = null OR Actual_Price__c = 0) AND Payment_Type__c = \'Standard\'), ' + sQuery.subString(7) + ' WHERE Id IN: lgIds'; 
        
        List<LG_Payment__c> lgPayment2Del = new List<LG_Payment__c>();
        List<LG__c> lgs = new List<LG__c>();    
        for(LG__c r : (List<LG__c>)database.query(sQuery)){
            
            if(r.Price_Type__c != 'Per Student' || (r.Price_Type__c == 'Per Student' && r.Declared_Number_of_Students__c > 0)){
                lgs.add(r); 
            }
            
            if(!r.LG_Payments__r.isEmpty()){
                lgPayment2Del.addAll(r.LG_Payments__r);
            }
        } 
        
        if(!lgPayment2Del.isEmpty()){
            delete lgPayment2Del;
        }   
        
        if(!lgs.isEmpty()){
            LG_TriggerHandler.lgs2ReCreatedLGPaymentToLG = lgs; // fill the list that the method "createLGPaymentToLG" will process.
            LG_TriggerHandler.createLGPaymentToLG();
        }
    }
    
    
    public static void doRecreateLGPayment2LGStudent(Set<Id> lgSIds){
        
        String sQuery = GlobalHelperMethods.getQueryString(new LG_Student__c());        
        sQuery = 'SELECT ' + ' (SELECT Id, Actual_Price__c FROM LG_Payments__r WHERE Payment_Type__c = \'Standard\'), ' + sQuery.subString(7) + ' WHERE Id IN: lgSIds'; 
        
        List<LG_Payment__c> lgPayment2Del   = new List<LG_Payment__c>();
        List<LG_Payment__c> lgPayment2Up    = new List<LG_Payment__c>();
        List<LG_Student__c> lgStudents      = new List<LG_Student__c>();
        
        //updated By-: Shivram Saini    Date-: 28 Nov 2018    Task-000001961
        for(LG_Student__c r : (List<LG_Student__c>)database.query(sQuery)){
            if(r.Status_in_LG__c == 'Registered' || r.Status_in_LG__c == 'Completed'){
                lgStudents.add(r);
            }
            for(LG_Payment__c lgP : r.LG_Payments__r){
                if(lgP.Actual_Price__c == null || lgP.Actual_Price__c == 0){
                    lgPayment2Del.add(lgP);
                }else{                  
                    lgP.Planned_Price__c = 0;
                    lgPayment2Up.add(lgP);
                }
            }
        }
        
        if(!lgPayment2Del.isEmpty()){
            delete lgPayment2Del;
        }
        
        if(!lgPayment2Up.isEmpty()){
            update lgPayment2Up;
        }   
        
        LG_Student_TriggerHandler.lgStudents2ReCreatedLGPaymentToLGStudents = lgStudents; // fill the list that the method "createLGPaymentToLG" will process.
        
        system.debug('LG_Student_TriggerHandler.lgStudents2ReCreatedLGPaymentToLGStudents: ' + LG_Student_TriggerHandler.lgStudents2ReCreatedLGPaymentToLGStudents);
        
        if(!lgStudents.IsEmpty()){
            LG_Student_TriggerHandler.createLGPaymentToStudent();
        }
    }
    
    /*******************************************************************************  
    Description       : Creates/Update/Deete LG Payment to LG Student when the LG End Paying Date has changed and update the field "LG End Paying Date" on LG Students  
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. Hernan Sinclair         10/31/2016            Yaara                   [SW-21977]
    *******************************************************************************/
    public static void doUpdateLGEndPayingDate(Map<Id, Date> lgIdsAndPrevEndDate){
        
        system.debug('lgIdsAndPrevEndDate: ' + lgIdsAndPrevEndDate);
        
        List<LG_Student__c> lgs2Up = new List<LG_Student__c>();
        List<LG_Payment__c> r2Insert = new List<LG_Payment__c>();
        Map<Id, Date> prevLGEndPayingDate = new Map<Id, Date>();
        Map<Id, Date> deleteFromPrevLGEndPayingDate = new Map<Id, Date>();
        Set<Id> studentWithBillingSession = new Set<Id>();
        
        // For each LG Student related with the LG that has changed its LG End Paying Date...
        for(LG_Student__c s : [SELECT Id, Billing_Type__c, Price_for_Payment__c, Payment_Method__c, Student_Start_Paying_Date__c, Student_End_Paying_Date__c, LG__c, LG__r.LG_End_Paying_Date__c, LG__r.First_Month_Price__c, LG__r.LG_Start_Paying_Date__c, LG__r.Last_Month_Price__c FROM LG_Student__c WHERE (Status_in_LG__c = 'Registered' OR Status_in_LG__c = 'Complete') AND (Billing_Type__c = 'Price per Month' OR Billing_Type__c = 'Price per Session') AND LG__c IN: lgIdsAndPrevEndDate.keySet()]){
            
            system.debug('s: ' + s);
            
            if(s.Student_End_Paying_Date__c == lgIdsAndPrevEndDate.get(s.LG__c)){ // Just when the condition "Student End Paying Date == previous LG End Paying Date" is true
            
                system.debug('Entre');
            
                if(s.Student_End_Paying_Date__c > s.LG__r.LG_End_Paying_Date__c){ // if the new end date value is less that the previous ones it means that we should delete lg paymemts
                    deleteFromPrevLGEndPayingDate.put(s.Id, s.LG__r.LG_End_Paying_Date__c);
                }
            
                prevLGEndPayingDate.put(s.Id, s.Student_End_Paying_Date__c);
                s.Student_End_Paying_Date__c = s.LG__r.LG_End_Paying_Date__c;
            
                if(s.Billing_Type__c == 'Price per Month'){
            
                    system.debug('we are on Price per Month');
            
                    // Re calculate all Payments
                    Date paymentDate = s.Student_Start_Paying_Date__c;
                    
                    if(s.LG__r.First_Month_Price__c <> null && s.LG__r.LG_Start_Paying_Date__c <> null && s.Student_Start_Paying_Date__c != null && s.LG__r.LG_Start_Paying_Date__c.month() == s.Student_Start_Paying_Date__c.month() && s.LG__r.LG_Start_Paying_Date__c.year() == s.Student_Start_Paying_Date__c.year()){ 
                        // Update First Payment is it's on the start middle of the month
                        r2Insert.add(new LG_Payment__c(LG__c = s.LG__c, LG_Student__c = s.Id, Payment_Type__c = 'Standard', Payment_Method__c = s.Payment_Method__c==null?'Credit Card':s.Payment_Method__c, Planned_Date__c = paymentDate, Planned_Price__c = s.LG__r.First_Month_Price__c));
                        paymentDate = paymentDate.addMonths(1); 
                    }
                    
                    system.debug('paymentDate: ' + paymentDate);
                    system.debug('s.Student_End_Paying_Date__c: ' + s.Student_End_Paying_Date__c);
                    
                    while(paymentDate <= s.Student_End_Paying_Date__c){
                        r2Insert.add(new LG_Payment__c(LG__c = s.LG__c, LG_Student__c = s.Id, Payment_Type__c = 'Standard', Payment_Method__c = s.Payment_Method__c==null?'Credit Card':s.Payment_Method__c, Planned_Date__c = paymentDate, Planned_Price__c = s.Price_for_Payment__c));
                        paymentDate = paymentDate.addMonths(1);
                    }
                    
                    system.debug('r2Insert: ' + r2Insert.size()); 
                    system.debug('r2Insert: ' + r2Insert);
                    
                    if(s.LG__r.Last_Month_Price__c <> null && s.LG__r.LG_End_Paying_Date__c != null && s.Student_End_Paying_Date__c != null && s.LG__r.LG_End_Paying_Date__c.month() == s.Student_End_Paying_Date__c.month() && s.LG__r.LG_End_Paying_Date__c.year() == s.Student_End_Paying_Date__c.year()){ 
                        // Update First Payment is it's on the start middle of the month
                        r2Insert[r2Insert.size()-1].Planned_Price__c = s.LG__r.Last_Month_Price__c;
                    }
                }else if(s.Billing_Type__c == 'Price per Session'){
                    
                    system.debug('we are on Price per Session');
                    
                    // Pre-condition: the LG_Student_Attendance__c are already created!!!
                    studentWithBillingSession.add(s.Id);
                }
                
                lgs2Up.add(s); // We will update the LG Student its new End Date value
            }
        }
        
        if(!studentWithBillingSession.isEmpty()){
            r2Insert.addAll(getLGPaymentBySessions(studentWithBillingSession, null, null));
        }   
        
        system.debug('r2Insert2: ' + r2Insert);
        
        // Get all existing LG Payment to LG Students realted with the related LGs
        List<LG_Payment__c> lgPayment2Del = new List<LG_Payment__c>();
        Map<String, LG_Payment__c> existingLGPaymentToLGStudent = new Map<String, LG_Payment__c>();
        for(LG_Payment__c p : [SELECT Id, LG__c, LG_Student__c, Planned_Date__c FROM LG_Payment__c WHERE LG__c IN : lgIdsAndPrevEndDate.keySet()]){ // Get existing LG Payments To LG Students
            existingLGPaymentToLGStudent.put(p.LG__c + '_' + p.LG_Student__c + '_' + p.Planned_Date__c, p);
            
            // Get the LG payments that should be deleted!!!
            if(deleteFromPrevLGEndPayingDate.containsKey(p.LG_Student__c) && p.Planned_Date__c > deleteFromPrevLGEndPayingDate.get(p.LG_Student__c)){
                lgPayment2Del.add(p);
            }
        }
        
        if(!lgs2Up.isEmpty()){
            update lgs2Up;
        }
        
        system.debug('r2Insert3: ' + r2Insert);
        
        if(!r2Insert.isEmpty()){
            
            List<LG_Payment__c> lgPayment2Insert = new List<LG_Payment__c>();
            List<LG_Payment__c> lgPayment2Update = new List<LG_Payment__c>();
            for(LG_Payment__c p : r2Insert){
                
                if(!existingLGPaymentToLGStudent.containsKey(p.LG__c + '_' + p.LG_Student__c + '_' + p.Planned_Date__c)){
                    lgPayment2Insert.add(p);
                }else{                  
                    Date prevDate = prevLGEndPayingDate.get(p.LG_Student__c);
                    if(p.Planned_Date__c >= prevDate.toStartOfMonth()){
                        p.Id = existingLGPaymentToLGStudent.get(p.LG__c + '_'+ p.LG_Student__c + '_' + p.Planned_Date__c).Id;
                        lgPayment2Update.add(p);
                    }
                }
            }
            
            system.debug('lgPayment2Insert: ' + lgPayment2Insert);
            
            if(!lgPayment2Insert.isEmpty()){
                insert lgPayment2Insert;  // This will fire the trigger that will calculate the related Vat and Discount for each payment created...
            }
            
            system.debug('lgPayment2Insert2: ' + lgPayment2Insert);
            
            if(!lgPayment2Update.isEmpty()){ // All payments that were in the limit (same month) of the previous end date and should be update just in case (all the previous we will ignore)
                update lgPayment2Update;
            }
        }
        
        if(!lgPayment2Del.isEmpty()){ // All the payments that has Planned date greater that the new end date.
            delete lgPayment2Del;
        }
    }
    
    /*******************************************************************************  
    Description       : Delete LG Payment to LG Student when the LG End Paying Date has changed for less date  
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. Hernan Sinclair         10/31/2016            Yaara                   [SW-21977]
    *******************************************************************************/
    public static void doRemoveLGPaymentToLG(Map<Id, Date> lgIdsAndNewEndDate){
        
        List<LG_Payment__c> lgPayment2Del = new List<LG_Payment__c>();
        for(LG_Payment__c p : [SELECT Id, LG__c, Planned_Date__c FROM LG_Payment__c WHERE LG__c IN : lgIdsAndNewEndDate.keySet() AND LG_Student__c = null AND (Actual_Price__c = null OR Actual_Price__c = 0) AND Payment_Type__c = 'Standard']){ // Get existing LG Payments To LG
        
            if(p.Planned_Date__c > lgIdsAndNewEndDate.get(p.LG__c) ){
                lgPayment2Del.add(p);
            }
        }           
        
        if(!lgPayment2Del.isEmpty()){ // All the payments that has Planned date greater that the new end date.
            delete lgPayment2Del;
        }
    }
}