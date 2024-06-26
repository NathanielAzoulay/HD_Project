/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_BC_Bundle_MemberTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_BC_Bundle_MemberTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new BC_Bundle_Member__c());
    }
}