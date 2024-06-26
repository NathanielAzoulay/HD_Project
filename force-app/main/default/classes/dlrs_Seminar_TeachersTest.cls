/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Seminar_TeachersTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Seminar_TeachersTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Seminar_Teachers__c());
    }
}