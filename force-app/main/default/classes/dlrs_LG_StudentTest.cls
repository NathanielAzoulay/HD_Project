/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_LG_StudentTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_LG_StudentTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new LG_Student__c());
    }
}