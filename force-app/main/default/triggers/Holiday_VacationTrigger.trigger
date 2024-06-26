trigger Holiday_VacationTrigger on Holiday_Vacation__c (before delete,after insert,after update) {
    
    //Before Delete
    if(trigger.isBefore && trigger.isDelete && checkRecursive.runOnce('Holiday_Vacation_BeforeDelete')){
        //Get related LG_Lesson__c where Lesson_Status__c = 'Day Off' and update Lesson_Status__c = Null when Holiday_Vacation__c is deleted
        HolidayVacationTriggerHandler.holydayVacationResetLesson();
    }
    
    //After Insert
    if(trigger.isAfter && trigger.isInsert && checkRecursive.runOnce('Holiday_Vacation_AfterInsert')){
        //Create Holiday Sharing rules when Holiday_Vacation__c is inserted
        HolidayVacationTriggerHandler.holydayVacationCreateSharingRules();
        
        //Update Lessionrecords when Holiday_Vacation__c is inserted
        HolidayVacationTriggerHandler.updateLessonsWhenCreateHoliday();
    }
    
    //After Update
    if(trigger.isAfter && trigger.isUpdate && checkRecursive.runOnce('Holiday_Vacation_AfterUpdate')){
        //Create Holiday Sharing rules when Holiday_Vacation__c is inserted
        HolidayVacationTriggerHandler.holydayVacationCreateSharingRules();
        
        //Update Lessionrecords when Holiday_Vacation__c is inserted
        HolidayVacationTriggerHandler.updateLessonsWhenCreateHoliday();
        
        HolidayVacationTriggerHandler.holydayVacationResetLesson();
   } 
}