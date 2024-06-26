@isTest
private class LGDeleteLessons_CtlTest {
    /******************************************************************************* 
	Name              : LGDeleteLessons_CtlTest
	Description       : 
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G.Fernandez             21/04/2016           Hernan Sinclair
	*******************************************************************************/
	@isTest(seeAllData=false)
    static void LGDeleteLessons_CtlTest(){
    	ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

    	LG__c lg = new LG__c(Id = testEnv.lgId);
	    lg.Group_Status__c = 'Planned';
    	lg.LG_Start_Date__c = System.today();
    	lg.LG_End_Date__c = System.today().addDays(30);
    	update lg;

    	LG_Days_Hours__c lgDH = new LG_Days_Hours__c(Id = testEnv.lgDHId);
    	lgDH.End_Hour__c = '19:30';				
		update lgDH;

		LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson(lg.Id, testEnv.teacherContactId, lgDH.Id);		        		
		insert lesson;

		LG_Payment__c payment = ObjectCreator.getNewLGPayment(testEnv.lgId, testEnv.studentId, testEnv.studentContactId);
		insert payment;

		LG_Student_Attendance__c studentAtt = ObjectCreator.getNewStudentAttendance(lesson.Id, testEnv.studentId);
		studentAtt.LG_Payment__c = payment.Id;
		insert studentAtt;

		System.debug([SELECT Number_of_Lessons__c FROM LG__c WHERE Id = :lg.Id]);
		System.debug([SELECT Id FROM LG_Lesson__c WHERE LG__c = :lg.Id]);

		ApexPages.StandardController sc = new ApexPages.StandardController(lg);
        LGDeleteLessons_Ctl controller = new LGDeleteLessons_Ctl(sc);
        controller.selectedDate = System.today();
        controller.doDelete();
        controller.doAgain();

    	LG_Days_Hours__c lgDH2 = ObjectCreator.getNewLG_Days_Hours(lg.Id);
    	lgDH2.End_Hour__c = '20:00';
    	lgDH2.Day__c = 'Thu';				
		insert lgDH2;
		
		Test.startTest();
		LG_Lesson__c lesson2 = ObjectCreator.getNewLG_Lesson(lg.Id, testEnv.teacherContactId, lgDH2.Id);
		lesson2.Lesson_Date_Hour__c = system.today().addDays(2);	        		
		insert lesson2;

		LG_Payment__c payment2 = ObjectCreator.getNewLGPayment(testEnv.lgId, testEnv.studentId, testEnv.studentContactId);
		insert payment2;

		LG_Student_Attendance__c studentAtt2 = ObjectCreator.getNewStudentAttendance(lesson2.Id, testEnv.studentId);
		studentAtt2.LG_Payment__c = payment2.Id;
		insert studentAtt2;

		List<LG_Lesson__c> lessons2Del = [SELECT Id, (Select Id, LG_Payment__c, LG_Student__c, LG_Student__r.LG__r.CurrencyIsoCode From LG_Students_Attendance__r) FROM LG_Lesson__c WHERE LG__c =: testEnv.lgId AND Lesson_Status__c = null AND Lesson_Date_Hour__c >= : System.today()]; 		
		LGDeleteLessonBatch b = new LGDeleteLessonBatch();
		b.lgId = testEnv.lgId; 
		b.processName  		= 'Batch - Update LG Days & Hour';
		b.rollback_key 		= System.now().getTime();
		b.selectedDate 		= System.today();
		b.records2process 	= lessons2Del;
		Database.executeBatch(b);
    	Test.stopTest();
        
    }

    @isTest(seeAllData=false)
    static void LGDeleteLessonBatch_CtlTest(){
    	ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

    	LG__c lg = new LG__c(Id = testEnv.lgId);
	    lg.Group_Status__c = 'Planned';
    	lg.LG_Start_Date__c = System.today();
    	lg.LG_End_Date__c = System.today().addDays(30);
    	update lg;

    	LG_Days_Hours__c lgDH = new LG_Days_Hours__c(Id = testEnv.lgDHId);
    	lgDH.End_Hour__c = '21:30';				
		update lgDH;

		LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson(lg.Id, testEnv.teacherContactId, lgDH.Id);		        		
		insert lesson;

		LG_Payment__c payment = ObjectCreator.getNewLGPayment(testEnv.lgId, testEnv.studentId, testEnv.studentContactId);
		insert payment;

		LG_Student_Attendance__c studentAtt = ObjectCreator.getNewStudentAttendance(lesson.Id, testEnv.studentId);
		studentAtt.LG_Payment__c = payment.Id;
		insert studentAtt;

		lg = [SELECT Id, LG_Type__c, Number_of_Lessons__c, LG_Start_Date__c, LG_End_Date__c, Franchisee__c, Franchisee__r.BillingCountry, Franchisee__r.ParentId, (SELECT LG__c, Day__c, Start_Hour__c, End_Hour__c, Teacher__c FROM LG_Days_Hours__r) FROM LG__c WHERE Id =: testEnv.lgId];

		System.debug(lg.LG_Days_Hours__r);

		List<LG_Lesson__c> lessons2Del = [SELECT Id, (Select Id, LG_Payment__c, LG_Student__c, LG_Student__r.LG__r.CurrencyIsoCode From LG_Students_Attendance__r) FROM LG_Lesson__c WHERE LG__c =: testEnv.lgId AND Lesson_Status__c = null AND Lesson_Date_Hour__c >= : System.today().addDays(-10)]; 		
		
		LGDeleteLessonBatch b = new LGDeleteLessonBatch();
		b.lgId = testEnv.lgId; 
		b.processName  		= 'Batch - Update LG Days & Hour';
		b.rollback_key 		= System.now().getTime();
		b.records2process 	= lessons2Del;

		Test.startTest();			
    		Database.executeBatch(b);
    	Test.stopTest();

    	System.debug([SELECT Error_Description__c FROM HD_Log__c]);
        
    }
}