/**************************************************************************************** 
Name              : LGCreateLessonWithoutBatch 
Description     : Create LG Leassons and its related objects on sync mode.
Revision History  :-
Created/Modified by       Created/Modified Date     Requested by      Related Task/Issue  
----------------------------------------------------------------------------------------
1. Aparna (Created)      05/08/2017                 Rashad               []
2. Avihai Shindelman     03/07/2018          Gidi Abramovitch        Task-000001699
----------------------------------------------------------------------------------------  
****************************************************************************************/
global class LGCreateLessonWithoutBatch {
global class MyException extends Exception {}

global Date selectedDate          {get; set;}
global String processName          {get; set;}
global List<HD_Log__c> errorLogs      {get; set;}
global Decimal rollback_key          {get; set;}  
global List<LG_Lesson__c> records2process  {get; set;}
global List<LG_Student__c> lgStudents     {get; set;}
global Boolean doInsert           {get; set;}

public static boolean notNeed2CheckRangeDateOnNewLesson = false; // Just we will put in true when the leasson is created because the user extend the lessons
public static boolean theLessonWasCreatedDueToChangeLGEndDate = false; // Just we will put in true when the leasson is created not manually and when the user change the LG End Date.

global void doSyncTask(List<LG_Lesson__c> scope){
    
    try{
        this.errorLogs = new List<HD_Log__c>();
        // Avoiding the possible duplicate lessons
        Set<Datetime> existingLGdates = new Set<Datetime>();
        //if (!Test.isRunningTest()){
        	for(LG_Lesson__c existingLG : [SELECT Id, Lesson_Date_Hour__c, LG__r.Holiday_Course__c, Lesson_Status__c FROM LG_Lesson__c WHERE LG__c =: records2process[0].LG__c]){//Avihai added Holiday_Course__c Task-000001699
            	existingLGdates.add(existingLG.Lesson_Date_Hour__c);
        	}
       /* }else{
            for(LG_Lesson__c existingLG : [SELECT Id, Lesson_Date_Hour__c, LG__r.Holiday_Course__c, Lesson_Status__c FROM LG_Lesson__c WHERE LG__c =: records2process[0].LG__c LIMIT 0]){//Avihai added LIMIT 0 in regards to exception: System.UnexpectedException: Start did not return a valid iterable object.
            	existingLGdates.add(existingLG.Lesson_Date_Hour__c);
        	}
        }*/
        
        List<LG_Lesson__c> lss2Process = new List<LG_Lesson__c>();
        for(LG_Lesson__c lss : scope){
            if(!existingLGdates.contains(lss.Lesson_Date_Hour__c)){
                system.debug('lss.Lesson_Status__c == ' + lss.Lesson_Status__c);
                if (lss.LG__r.Holiday_Course__c == false)//Avihai added Holiday_Course__c Task-000001699
                    lss.Lesson_Status__c = null;
                lss2Process.add(lss);
            }
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
        
        Date lastDayOfMonth; // In case that the Batch was called with a selecteDate (from Create Button), we will need just create (maintenance) the LG Payment from that seleted date
        if(selectedDate <> null){
            Integer iYear = selectedDate.year();
            Integer iMonth = selectedDate.month();
            lastDayOfMonth  = Date.newInstance(iYear, iMonth, Date.daysInMonth(iYear, iMonth));
        }
        System.debug('rollback_key:::'+rollback_key);
        
        MonitorRecursionClass.SetProcessKey(rollback_key);
        
        /*createStudentsAttAndLGPayments(lss2Process, lgStudents, selectedDate, lastDayOfMonth, rollback_key, true);*/
        
        /********similar functionality of Finish Method of LGCreateLessonBatch class.*********/ 
        if(errorLogs.isEmpty()){
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
        
    }catch(Exception ex){
      errorLogs.add(new HD_Log__c(Process_Key__c = rollback_key, LG__c = records2process[0].LG__c, Process_Name__c = processName, Error_Description__c = ex.getMessage(), Status__c = 'Fail'));  
    }
}
}