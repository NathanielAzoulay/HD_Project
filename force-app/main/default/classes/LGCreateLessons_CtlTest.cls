@isTest
private class LGCreateLessons_CtlTest {
    /******************************************************************************* 
	Name              : LGCreateLessons_CtlTest
	Description       : 
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G.Fernandez             21/04/2016           Hernan Sinclair
	*******************************************************************************/
	@isTest(seeAllData=false)
    static void LGCreateLessons_CtlTest(){
    	ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

    	LG__c lg = new LG__c(Id = testEnv.lgId);
        lg.Group_Status__c = 'Planned';
        lg.LG_Start_Date__c = System.today();
        lg.LG_End_Date__c = System.today().addDays(30);
        update lg;

        LG_Days_Hours__c lgDH = new LG_Days_Hours__c(Id = testEnv.lgDHId);
        lgDH.End_Hour__c = '21:30';             
        update lgDH;

        /*LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson(lg.Id, testEnv.teacherContactId, lgDH.Id);                      
        insert lesson;

        LG_Payment__c payment = ObjectCreator.getNewLGPayment(testEnv.lgId, testEnv.studentId, testEnv.studentContactId);
        insert payment;

        LG_Student_Attendance__c studentAtt = ObjectCreator.getNewStudentAttendance(lesson.Id, testEnv.studentId);
        studentAtt.LG_Payment__c = payment.Id;
        insert studentAtt;*/

    	ApexPages.StandardController sc = new ApexPages.StandardController (lg);
        LGCreateLessons_Ctl controller = new LGCreateLessons_Ctl(sc);

        controller.selectedDate = System.today().addDays(25);
		controller.doCreate();
        controller.selectedDate = System.today().addDays(35);
		controller.doCreateForEndDate();
    }
    
    @isTest(seeAllData=false)
    static void LGCreateLessons_CtlTest2(){
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
        LGCreateLessons_Ctl controller = new LGCreateLessons_Ctl(sc);

		controller.updateEndPayingDate = true;
		controller.currentLG.LG_Lessons__c = 1;
		controller.doCreateForNumOfLessons();
		
		LGCreateLessons_Ctl.sendNotifications(new List<LG__c>{lg});
    }

    @isTest(seeAllData=false)
    static void LGCreateLessonBatch_Test(){
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

        LG__c lg = new LG__c(Id = testEnv.lgId);
        lg.Group_Status__c = 'Planned';
        lg.LG_Start_Date__c = System.today();
        lg.LG_End_Date__c = System.today().addDays(30);
        update lg;

        LG_Days_Hours__c lgDH = new LG_Days_Hours__c(Id = testEnv.lgDHId);
        lgDH.End_Hour__c = '21:30';             
        update lgDH;

        LGCreateLessonBatch b = new LGCreateLessonBatch();
        
        b.records2process = LGHelperMethods.getAllLessonsDays(testEnv.lgId, System.today());
        b.records2process[0].Lesson_Date_Hour__c = System.today().addDays(-2);
        b.rollback_key = b.records2process[0].Rollback_Key__c;                        
        b.doInsert = true;            
        Database.executeBatch(b);

        /*Test.startTest();
            LGCreateLessonBatch b2 = new LGCreateLessonBatch();
            b2.records2process = LGHelperMethods.getAllLessonsDays(testEnv.lgId, null);
            system.debug('b2.records2process  ' + b2.records2process);
            b2.doInsert = true;
            b2.lgStudents = [SELECT Id, Student_Course_Start_Date__c, Student_Course_End_Date__c, Billing_Type__c, Lesson_Type__c, (Select Planned_Date__c, Planned_Price__c From LG_Payments__r) FROM LG_Student__c WHERE LG__c =: testEnv.lgId AND (Status_in_LG__c = 'Registered' OR Status_in_LG__c = 'Signed for Demo')];
            b2.processName = 'Batch - Create LG Lessons';
            b2.selectedDate = System.today().addDays(35); 
            b2.rollback_key = b2.records2process[0].Rollback_Key__c; 

            b2.records2process = LGHelperMethods.getAllLessonsDays(testEnv.lgId, null);
            Database.executeBatch(b2); 

        Test.stopTest();*/
    }
}