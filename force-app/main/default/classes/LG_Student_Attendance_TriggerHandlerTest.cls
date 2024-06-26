/******************************************************************************* 
Name              : LG_Student_Attendance_TriggerHandlerTest
Description       : Contains the test methods of all triggers on LG Student Attendance object
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Nicolas                   03/08/2016              
*******************************************************************************/
@isTest
private class LG_Student_Attendance_TriggerHandlerTest {

	@isTest(seeAllData=false)
    static void updateRelatedPayments() {
		
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
		
		delete studentAtt;
	}
}