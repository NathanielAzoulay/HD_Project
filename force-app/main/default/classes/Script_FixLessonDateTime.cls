global class Script_FixLessonDateTime implements Database.Batchable<SObject>{
	public String query = 'SELECT Id, Lesson_Date_Time__c, Lesson_Date_Hour__c FROM LG_Lesson__c WHERE Lesson_Date_Hour__c != null AND Lesson_Date_Time__c != null ';
    public Set<Id> restrictIds = new Set<Id>();
    public Integer queryLimit = 0;
    public Boolean allOrNothing = false;
    
    global Database.querylocator start(Database.BatchableContext BC){
		if( !restrictIds.isEmpty() ){
			query += ' AND Id IN :restrictIds ';
		}
        
        if( queryLimit > 0 ){
            query += ' LIMIT ' + queryLimit;
        }
        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        String newLessonDateHour;
        List<LG_Lesson__c> lesson2Upd = new List<LG_Lesson__c>();
        
        for( LG_Lesson__c lesson : (List<LG_Lesson__c>) scope ){
            newLessonDateHour = lesson.Lesson_Date_Hour__c.formatGmt( 'yyyy-MM-dd HH:mm:ss' );
            if( lesson.Lesson_Date_Time__c != newLessonDateHour ){
            	lesson.Lesson_Date_Time__c = lesson.Lesson_Date_Hour__c.formatGmt( 'yyyy-MM-dd HH:mm:ss' );
                lesson2Upd.add( lesson );
            }
        }
        
        if( !lesson2Upd.isEmpty() ){
            database.update( lesson2Upd, allOrNothing );
        }
    }
    
    global void finish(Database.BatchableContext BC){
    }
}