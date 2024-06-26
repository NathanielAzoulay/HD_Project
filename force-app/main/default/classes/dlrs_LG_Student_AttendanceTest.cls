/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_LG_Student_AttendanceTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_LG_Student_AttendanceTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new LG_Student_Attendance__c());
    }
}