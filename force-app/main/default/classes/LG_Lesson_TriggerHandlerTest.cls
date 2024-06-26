@isTest
private class LG_Lesson_TriggerHandlerTest {

    @isTest(seeAllData=false)
    static void myUnitTest() {
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

		Course_Sub_Type__c curseSubType = new Course_Sub_Type__c(id = testEnv.curseSubTypeId, Price_per_Session__c  = 10);
    	update curseSubType;
	
    	LG__c lg = new LG__c(Id = testEnv.lgId);
	    lg.Group_Status__c = 'Planned';
    	lg.LG_Start_Date__c = System.today();
    	lg.LG_End_Date__c = System.today().addDays(30);
    	lg.Billing_Type__c = 'Price per Session';
    	update lg;

    	LG_Days_Hours__c lgDH = new LG_Days_Hours__c(Id = testEnv.lgDHId);
    	lgDH.End_Hour__c = '19:30';				
		update lgDH;
        test.startTest();

		LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson(lg.Id, testEnv.teacherContactId, lgDH.Id);		        		
		insert lesson;

		LG_Payment__c payment = ObjectCreator.getNewLGPayment(testEnv.lgId, testEnv.studentId, testEnv.studentContactId);
		insert payment;

		LG_Student_Attendance__c studentAtt = ObjectCreator.getNewStudentAttendance(lesson.Id, testEnv.studentId);
		studentAtt.LG_Payment__c = payment.Id;
		insert studentAtt;
        
        LG_Lesson_TriggerHandler.lgLessonsThatNeedReCalculationLGPayments.add(lesson.Id);
        update lesson;
        
        delete lesson;
        test.stopTest();
    }
    
     @isTest(seeAllData=false)
    static void myUnitTest2() {
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

		Course_Sub_Type__c curseSubType = new Course_Sub_Type__c(id = testEnv.curseSubTypeId, Price_per_Session__c  = 10);
    	update curseSubType;
	
    	LG__c lg = new LG__c(Id = testEnv.lgId);
	    lg.Group_Status__c = 'Planned';
    	lg.LG_Start_Date__c = System.today();
    	lg.LG_End_Date__c = System.today().addDays(30);
    	lg.Billing_Type__c = 'Price per Session';
    	lg.Price_per_Session__c = 10;
    	lg.Declared_Number_of_Students__c = null;
    	update lg;

    	LG_Days_Hours__c lgDH = new LG_Days_Hours__c(Id = testEnv.lgDHId);
    	lgDH.End_Hour__c = '19:30';				
		update lgDH;
        
        test.startTest();

		LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson(lg.Id, testEnv.teacherContactId, lgDH.Id);		        		
		insert lesson;

		LG_Payment__c payment = ObjectCreator.getNewLGPayment(testEnv.lgId, testEnv.studentId, testEnv.studentContactId);
		insert payment;

		LG_Student_Attendance__c studentAtt = ObjectCreator.getNewStudentAttendance(lesson.Id, testEnv.studentId);
		studentAtt.LG_Payment__c = payment.Id;
		insert studentAtt;
        
       
        Contact studentContact 	= ObjectCreator.getNewContact(testEnv.accId, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId());              
        insert studentContact;
        
        LG_Student__c student = ObjectCreator.getNewLGStudent(studentContact.Id, lg.Id);
        student.Approved_Price__c = 22;
        student.Lesson_Type__c = 'Standard';
        student.Status_in_LG__c = 'Registered';
        student.Billing_Type__c = 'Price per Session';
        student.Student_Start_Paying_Date__c = System.today();
        insert student;
        
        LG_Lesson_TriggerHandler.lgLessonsThatNeedReCalculationLGPayments.add(lesson.Id);
        update lesson;
        
        delete lesson;
        test.stopTest();
    }
    
    
}