/*******************************************************************************
Name              : LGStudentAttandanceToYesCtrTest  
Description		  : Test class for the apex class "LGStudentAttandanceToYesCtr" 					
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan (Created)        02/10/2016              Yaara                   [SW-17775]
*******************************************************************************/
@isTest
private class LGStudentAttandanceToYesCtrTest {

	@isTest(seeAllData=false)
    static void myUnitTest() {
        
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
		
        Test.setCurrentPage( new PageReference('/apex/LGStudentAttandanceToYes') );  
		ApexPages.currentPage().getParameters().put('id',lesson.Id);	
        
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(Database.getQueryLocator([SELECT Id FROM LG_Student_Attendance__c WHERE Id = :studentAtt.Id LIMIT 1]) );
        sc.setSelected( [SELECT Id FROM LG_Student_Attendance__c WHERE Id = :studentAtt.Id LIMIT 1] );
        LGStudentAttandanceToYesCtr controller = new LGStudentAttandanceToYesCtr(sc);
        
        controller.testErrorMsg = true;
        controller.doUpdate();
    }
}