/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Group_Income_Per_MonthTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Group_Income_Per_MonthTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Group_Income_Per_Month__c());
    }
}