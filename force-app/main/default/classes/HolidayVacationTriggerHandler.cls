public class HolidayVacationTriggerHandler{
  
    /******************************************************************************* 
    Name              : holydayVacationResetLesson
    Description       : Handler the delete of Holiday_Vacation__c object
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez           17/05/2016           Yaara Nadir          [SW-23412]
    *******************************************************************************/
    public static void holydayVacationResetLesson(){
        if( HD_TriggerSettings.IsTriggerActive('holydayVacationResetLesson') ){
    
            Set<Id> holidays = new Set<Id>();
            for(Integer i=0; i < trigger.size; i++ ){
                Boolean cond = Trigger.isBefore && Trigger.isDelete;
                if (cond) {
                    Holiday_Vacation__c hd = (Holiday_Vacation__c) trigger.old[i];
                    holidays.add(hd.Id);            
                }
    
                cond = Trigger.isAfter && Trigger.isUpdate && ((Holiday_Vacation__c) trigger.new[i]).Work_Day__c == true;
                if (cond) {
                    Boolean cond2 = ((Holiday_Vacation__c) trigger.old[i]).Work_Day__c != ((Holiday_Vacation__c) trigger.new[i]).Work_Day__c;
                    if (cond2) {
                        Holiday_Vacation__c hd = (Holiday_Vacation__c) trigger.new[i];
                        holidays.add(hd.Id);
                    }          
                }
            }
            System.debug('************'+holidays);
            if(!holidays.isEmpty()){
                List<LG_Lesson__c> lessons2up = new List<LG_Lesson__c>();
                for(LG_Lesson__c lesson : [SELECT Lesson_Status__c FROM LG_Lesson__c WHERE Holiday__c IN :holidays AND Lesson_Status__c = 'Day Off']){
                    lesson.Lesson_Status__c = null;
                    lessons2up.add(lesson);
                }
    
                if (!lessons2up.isEmpty()) {
                    update lessons2up;
                }
            }        
        }
    }
    
    /******************************************************************************* 
    Name              : holydayVacationCreateSharingRules
    Description       : Handler the sharing record of Holiday_Vacation__c object
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez           17/05/2016           Yaara Nadir          [SW-19266]
    *******************************************************************************/
    public static void holydayVacationCreateSharingRules(){
        if( HD_TriggerSettings.IsTriggerActive('holydayVacationCreateSharingRules') ){
            Map<Id,Holiday_Vacation__c> holidays = new Map<Id,Holiday_Vacation__c>();
            for(Integer i=0; i < trigger.size; i++ ){
                Holiday_Vacation__c hd = (Holiday_Vacation__c)trigger.new[i];
                if(trigger.isInsert || ((Holiday_Vacation__c)trigger.old[i]).OwnerId <> hd.OwnerId || ((Holiday_Vacation__c)trigger.old[i]).MF__c <> hd.MF__c || ((Holiday_Vacation__c)trigger.old[i]).LC__c <> hd.LC__c){
                    holidays.put(hd.Id, hd);
                }
            }
        
            if(!holidays.isEmpty()){
                HD_SharingMethods.HolidayVacation_CreateSharingRules(holidays.values());
            }        
        }
    }
    
    
    /******************************************************************************* 
    Name              : updateLessonsWhenCreateHoliday
    Description       : Look for lessons affected with the new holiday inserted and relate them
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G.Fernandez            18/03/2016          Yaara Nadir          SW-18016
    2. G.Fernandez            18/01/2017          Yaara Nadir          SW-23238
    3. G.Fernandez            26/01/2017          Yaara Nadir          SW-23412
	4. Avihai Shindelman	  30/04/2018							   Task-000001699
    *******************************************************************************/
    
    public static void updateLessonsWhenCreateHoliday(){
        if( HD_TriggerSettings.IsTriggerActive('updateLessonsWhenCreateHoliday') ){
    
            Id countryType = Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('Country').getRecordTypeId();
            Id mfType = Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('MF').getRecordTypeId();
            Id lcType = Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('LC').getRecordTypeId();
    
            Map<String,List<Holiday_Vacation__c>> holidayLCMap = new Map<String,List<Holiday_Vacation__c>>();
            Map<String,List<Holiday_Vacation__c>> holidayMFMap = new Map<String,List<Holiday_Vacation__c>>();
            Map<String,List<Holiday_Vacation__c>> holidayCountryMap = new Map<String,List<Holiday_Vacation__c>>();
    
            Set<Id> holidayslessons2up = new Set<Id>();

            //TOO MANY SOQL ERROR - FIX
            Set<Id> holidaysIds = new Set<Id>();
            
            Date holidaysStartDate;
            Date holidaysEndDate;
            
            //collect LCs, MFs, Countrys
            for( Integer i=0; i < trigger.size; i++ ){
            
                Holiday_Vacation__c holidayVacation = (Holiday_Vacation__c) trigger.new[i];

                Boolean cond = true;
                Holiday_Vacation__c oldholidayVacation;
                if (Trigger.isUpdate){
                    oldholidayVacation = (Holiday_Vacation__c) trigger.old[i];          
                    cond = oldholidayVacation.Start_Date__c != holidayVacation.Start_Date__c ||  oldholidayVacation.End_Date__c != holidayVacation.End_Date__c;
                    cond = cond || (holidayVacation.LC__c != null && oldholidayVacation.LC__c != holidayVacation.LC__c);
                    cond = cond || (holidayVacation.MF__c != null && oldholidayVacation.MF__c != holidayVacation.MF__c);
                    //SW-26638
                    //Shivram 17 Nov 2017 : commented this
                    //cond = cond || (oldholidayVacation.Change_Existing_Lessons_to_Day_Off__c != holidayVacation.Change_Existing_Lessons_to_Day_Off__c);
                }
                
                System.debug('holidayVacation '+holidayVacation);
                System.debug('cond '+cond);
                if(cond){
                    if(holidayVacation.RecordTypeId == lcType && holidayVacation.LC__c != null){
                        String lcId = String.valueOf(holidayVacation.LC__c).substring(0,15);
                        if(!holidayLCMap.containsKey(lcId)){
                            holidayLCMap.put(lcId, new List<Holiday_Vacation__c>());
                        }
                        holidayLCMap.get(lcId).add(holidayVacation);
                    }else if(holidayVacation.RecordTypeId == mfType && holidayVacation.MF__c != null){
                        String mfId = String.valueOf(holidayVacation.MF__c).substring(0,15);
                        if(!holidayMFMap.containsKey(mfId)){
                            holidayMFMap.put(mfId, new List<Holiday_Vacation__c>());
                        }
                        holidayMFMap.get(mfId).add(holidayVacation);
                    }else if(holidayVacation.RecordTypeId == countryType && holidayVacation.Country__c != null){
                        if(!holidayCountryMap.containsKey(holidayVacation.Country__c)){
                            holidayCountryMap.put(holidayVacation.Country__c, new List<Holiday_Vacation__c>());
                        }          
                        holidayCountryMap.get(holidayVacation.Country__c).add(holidayVacation);
                    }
                    
                }
                //SW-23412
                //Shivram 17 Nov 2017 : commented this 
                //cond = holidayVacation.Change_Existing_Lessons_to_Day_Off__c == true && holidayVacation.Work_Day__c == false;
                
                //Shivram : updated this condition
                if(holidayVacation.Change_Existing_Lessons_to_Day_Off__c == true && holidayVacation.Work_Day__c == false 
                   && (cond || oldholidayVacation.Change_Existing_Lessons_to_Day_Off__c != holidayVacation.Change_Existing_Lessons_to_Day_Off__c)){
                    holidayslessons2up.add(holidayVacation.Id);
                }
                //TOO MANY SOQL ERROR - FIX
                holidaysIds.add(holidayVacation.Id);
                holidaysStartDate = holidaysStartDate == null || holidayVacation.Start_Date__c < holidaysStartDate ? holidayVacation.Start_Date__c : holidaysStartDate;
                holidaysEndDate = holidaysStartDate == null || holidayVacation.End_Date__c > holidaysEndDate ? holidayVacation.End_Date__c : holidaysEndDate;
            }

            System.debug('***********'+holidayCountryMap);
            System.debug('***********'+holidayslessons2up);
            System.debug('************'+holidayLCMap);
            System.debug('************'+holidayMFMap);
            Map<Id, LG_Lesson__c> lessons2up = new Map<Id, LG_Lesson__c>();
            if(!holidayLCMap.isEmpty() || !holidayMFMap.isEmpty() || !holidayCountryMap.isEmpty()){
    
                //Look for matching lessons with country, mf - direct franchise, lc - franchise
                // and updating in herarchy order LC > MFs > Country
                for(LG_Lesson__c lesson : [SELECT Country__c, Franchisee__c, Direct_Franchisee__c, Lesson_Date_Hour__c, Holiday__r.RecordTypeId,LG__c,LG__r.Holiday_Course__c 
                                           FROM LG_Lesson__c 
                                           WHERE (Country__c IN :holidayCountryMap.keySet() OR (Franchisee__c IN :holidayLCMap.keySet() OR Franchisee__c IN :holidayMFMap.keySet()/*SW-25305*/) OR Direct_Franchisee__c IN :holidayMFMap.keySet()) AND
                                           (Holiday__c IN :holidaysIds OR (DAY_ONLY(Lesson_Date_Hour__c) >= :holidaysStartDate AND DAY_ONLY(Lesson_Date_Hour__c) <= :holidaysEndDate))]){  //Avihai 25/04/2018 added holiday_lesson and course
                    if(holidayLCMap.keySet().contains(lesson.Franchisee__c)){
                        for(Holiday_Vacation__c holiday : holidayLCMap.get(lesson.Franchisee__c)){
                            if( lesson.Lesson_Date_Hour__c <> null && holiday.Start_Date__c <= lesson.Lesson_Date_Hour__c.date() && lesson.Lesson_Date_Hour__c.date() <= holiday.End_Date__c){// && lesson.LG__r.Holiday_Course__c == false){/*Avihai : add this condition regarding team task Task-000001676   && lg.Holiday_Course__c == false*/
                                //insert relation if match
                                lesson.Holiday__c = holiday.Id;
                                lessons2up.put(lesson.Id,lesson);
                            }else if(lesson.Holiday__c == holiday.Id){
                                //clean if stop matching
                                lesson.Holiday__c = null;
                                lessons2up.put(lesson.Id,lesson);
                            }
                        }             
                    }
    
                    Boolean checkExistentHoliday = lesson.Holiday__c == null || (lesson.Holiday__c != null && lesson.Holiday__r.RecordTypeId != lcType);
                    if(checkExistentHoliday && !lessons2up.containsKey(lesson.Id) && (holidayMFMap.keySet().contains(lesson.Franchisee__c) /*SW-25305*/ || holidayMFMap.keySet().contains(lesson.Direct_Franchisee__c))){
    
                        List<Holiday_Vacation__c>  hDays = new List<Holiday_Vacation__c>();
                        if(holidayMFMap.containsKey(lesson.Direct_Franchisee__c)){
                            hDays.addAll(holidayMFMap.get(lesson.Direct_Franchisee__c));
                        }
                        if(holidayMFMap.containsKey(lesson.Franchisee__c)){ /*SW-25305*/
                            hDays.addAll(holidayMFMap.get(lesson.Franchisee__c));
                        }             
    
                        for(Holiday_Vacation__c holiday : hDays){
                            if( lesson.Lesson_Date_Hour__c <> null && holiday.Start_Date__c <= lesson.Lesson_Date_Hour__c.date() && lesson.Lesson_Date_Hour__c.date() <= holiday.End_Date__c){
                                lesson.Holiday__c  = holiday.Id;
                                lessons2up.put(lesson.Id,lesson);
                            }else if(lesson.Holiday__c == holiday.Id){
                                lesson.Holiday__c = null;
                                lessons2up.put(lesson.Id,lesson);
                            }
                        }
                    }
    
                    checkExistentHoliday = lesson.Holiday__c == null || (lesson.Holiday__c != null && lesson.Holiday__r.RecordTypeId == countryType);
                    if(checkExistentHoliday && !lessons2up.containsKey(lesson.Id) && holidayCountryMap.keySet().contains(lesson.Country__c)){
                        for(Holiday_Vacation__c holiday : holidayCountryMap.get(lesson.Country__c)){
                            //if( holiday.Start_Date__c <= lesson.Lesson_Date_Hour__c.date() && lesson.Lesson_Date_Hour__c.date() <= holiday.End_Date__c)
                            Boolean cond = lesson.Lesson_Date_Hour__c != null && holiday.Start_Date__c <= lesson.Lesson_Date_Hour__c.date();
                            cond &= lesson.Lesson_Date_Hour__c != null && lesson.Lesson_Date_Hour__c.date() <= holiday.End_Date__c;
                            if( cond ){  
                                lesson.Holiday__c = holiday.Id;
                                lessons2up.put(lesson.Id,lesson);
                            }else if(lesson.Holiday__c == holiday.Id){
                                lesson.Holiday__c = null;
                                lessons2up.put(lesson.Id,lesson);
                            }
                        }
                    }
                }
            }
    
            //SW-23412
            if(!holidayslessons2up.isEmpty()){
                for(LG_Lesson__c lgLesson : lessons2up.values()){
                    //system.debug('lgLesson.LG__r.Holiday_Course__c ==' +lgLesson.LG__r.Holiday_Course__c);
                	//system.debug('lgLesson.Lesson_Status__c ==' + lgLesson.Lesson_Status__c);
                    if(lgLesson.Holiday__c <> null && holidayslessons2up.contains(lgLesson.Holiday__c) && lgLesson.LG__r.Holiday_Course__c == false){//Avihai added Holiday Course == false condition 30/04/2018 Task-000001699
                        lgLesson.Lesson_Status__c = 'Day Off';
                    }
                }            
    
                for (LG_Lesson__c  lesson2up: [SELECT Id,LG__r.Holiday_Course__c FROM LG_Lesson__c WHERE Holiday__c IN :holidayslessons2up]) {
                    if(lessons2up.containsKey(lesson2up.Id)){
                        lesson2up = lessons2up.get(lesson2up.Id);
                    }
                    //system.debug('lesson2up.Lesson_Status__c ==' + lesson2up.Lesson_Status__c);
                    if (lesson2up.LG__r.Holiday_Course__c == false)//Avihai added on 30/04/2018 Task-000001699
                    	lesson2up.Lesson_Status__c = 'Day Off';
                    lessons2up.put(lesson2up.Id, lesson2up);
                }
            }
    
            System.debug(System.LoggingLevel.ERROR, 'lessons2up ' + lessons2up);
            if(!lessons2up.isEmpty()){
                Update lessons2up.values();
            }
    
        }
    }    
}