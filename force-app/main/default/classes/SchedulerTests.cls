@isTest
private class SchedulerTests {
	@isTest(seeAllData=false)
    static void Contact_ChangeToPostStudentScheduler_Test() {
    	Test.startTest(); 
        System.schedule('Contact_ChangeToPostStudentSchedulerTest', '0 0 01 * * ?', new Contact_ChangeToPostStudentScheduler());
        Test.stopTest(); 
    }

    @isTest(seeAllData=false)
    static void LG_ChangeCompleteBatchScheduler_Test() {
    	Test.startTest(); 
    	System.schedule('LG_ChangeCompleteBatchSchedulerTest', '0 0 01 * * ?', new LG_ChangeCompleteBatchScheduler());
    	Test.stopTest();
    }

    @isTest(seeAllData=false)
    static void Sched_RecentSharingRulesOnContact_Test() {
    	Test.startTest(); 
    	System.schedule('Sched_RecentSharingRulesOnContactTest', '0 0 01 * * ?', new Sched_RecentSharingRulesOnContact());
    	Test.stopTest();
    }
}