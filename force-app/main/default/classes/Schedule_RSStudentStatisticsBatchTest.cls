@isTest
global class Schedule_RSStudentStatisticsBatchTest {
  @isTest
     static void testschedule(){
        Test.StartTest();
    Schedule_RSStudentsStatistics_Batch schedular = new Schedule_RSStudentsStatistics_Batch();
        schedular.execute(null);
        Test.stopTest(); 
        
    }
}