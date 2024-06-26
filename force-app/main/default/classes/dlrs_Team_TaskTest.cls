/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Team_TaskTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Team_TaskTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Team_Task__c());
    }
}