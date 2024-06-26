@isTest
private class LGCreateLessonsNew_CtlTest {
    /******************************************************************************* 
    Name              : LGCreateLessonsNew_CtlTest
    Description       : 
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. Aparna             08/05/2017                Rashad Saeed
    *******************************************************************************/
    
    
    @isTest(seeAllData=false)
    static void testLGCreateLessonsTrigger(){

        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

        LG__c lg = new LG__c(Id = testEnv.lgId);
        lg.Group_Status__c = 'Planned';
        lg.LG_Start_Date__c = System.today();
        lg.LG_End_Date__c = System.today().addDays(30);
        update lg;

        LG_Days_Hours__c lgDH = new LG_Days_Hours__c(Id = testEnv.lgDHId);
        lgDH.End_Hour__c = '21:30';             
        update lgDH;

        Test.startTest();
        LGCreateLessons.handleCreateLessons(new List<Id>{lg.Id});
        Test.stopTest();

    }

    @isTest(seeAllData=false)
    static void LGCreateLessonsNew_CtlTest(){

        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

        LG__c lg = new LG__c(Id = testEnv.lgId);
        lg.Group_Status__c = 'Planned';
        lg.LG_Start_Date__c = System.today();
        lg.LG_End_Date__c = System.today().addDays(30);
        update lg;

        LG_Days_Hours__c lgDH = new LG_Days_Hours__c(Id = testEnv.lgDHId);
        lgDH.End_Hour__c = '21:30';             
        update lgDH;

        ApexPages.StandardController sc = new ApexPages.StandardController (lg);
        LGCreateLessonsNew_Ctl controller = new LGCreateLessonsNew_Ctl(sc);

        Test.startTest();
        controller.selectedDate = System.today().addDays(25);
        controller.doCreate();
        controller.selectedDate = System.today().addDays(35);
        controller.doCreateForEndDate();

        Test.stopTest();

    }
    
    @isTest(seeAllData=false)
    static void LGCreateLessonsNew_CtlTest2(){

        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

        LG__c lg = new LG__c(Id = testEnv.lgId);
        lg.Group_Status__c = 'Planned';
        lg.LG_Start_Date__c = System.today();
        lg.LG_End_Date__c = System.today().addDays(30);
        lg.Name = 'testxxxx';
        update lg;

        LG_Days_Hours__c lgDH = new LG_Days_Hours__c(Id = testEnv.lgDHId);
        lgDH.End_Hour__c = '21:30';             
        update lgDH;

        ApexPages.StandardController sc = new ApexPages.StandardController (lg);
        LGCreateLessonsNew_Ctl controller = new LGCreateLessonsNew_Ctl(sc);

        controller.updateEndPayingDate = true;
        controller.currentLG.LG_Lessons__c = 1;
        Test.startTest();
        controller.doCreateForNumOfLessons();
        Test.stopTest();
        
        LGCreateLessonsNew_Ctl.sendNotifications(new List<LG__c>{lg});

    }

    @isTest(seeAllData=false)
    static void LGCreateLessonWithoutBatch_Test(){


        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

        LG__c lg = new LG__c(Id = testEnv.lgId);
        lg.Group_Status__c = 'Planned';
        lg.LG_Start_Date__c = System.today();
        lg.LG_End_Date__c = System.today().addDays(30);

        LG_Days_Hours__c lgDH = new LG_Days_Hours__c(Id = testEnv.lgDHId);
        lgDH.End_Hour__c = '21:30';             
        update lgDH;

        Test.startTest();
        LGCreateLessonWithoutBatch b = new LGCreateLessonWithoutBatch();
        
        b.records2process = LGHelperMethods.getAllLessonsDays(testEnv.lgId, System.today());
        
        Test.stopTest();
        System.debug('records2process'+b.records2process);
        b.records2process[0].Lesson_Date_Hour__c = System.today().addDays(-2);
        b.rollback_key = b.records2process[0].Rollback_Key__c;
        if(!b.records2process.isEmpty()){
            b.doInsert = true;            
            b.doSyncTask(b.records2process);
        } 

    }
    
    @isTest(seeAllData=false)
    static void LGCreateLessonWithoutBatch_Test1(){

        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

        LG__c lg = new LG__c(Id = testEnv.lgId);
        lg.Group_Status__c = 'Planned';
        lg.LG_Start_Date__c = System.today();
        lg.LG_End_Date__c = System.today().addDays(30);
        update lg;
        
        Date d = System.today().addDays(10);
        
        LG_Lesson__c lglesson = new LG_Lesson__c();
        lglesson.LG__c = lg.Id;
        lglesson.Lesson_Date_Hour__c = DateTime.newInstance(d.year(),d.month(), d.day(), 8, 6, 16);
        insert lglesson;

        LG_Days_Hours__c lgDH = new LG_Days_Hours__c(Id = testEnv.lgDHId);
        lgDH.End_Hour__c = '21:30';             
        update lgDH;
        Test.startTest();

        LGCreateLessonWithoutBatch b = new LGCreateLessonWithoutBatch();
        
        b.records2process = LGHelperMethods.getAllLessonsDays(testEnv.lgId, System.today());
        Test.stopTest();  
        System.debug('records2process'+b.records2process);
        b.records2process[0].Lesson_Date_Hour__c = System.today().addDays(-2);
        b.rollback_key = b.records2process[0].Rollback_Key__c;
        if(!b.records2process.isEmpty()){
            b.doInsert = true;            
            b.doSyncTask(b.records2process);
        }                      
        
    }
}