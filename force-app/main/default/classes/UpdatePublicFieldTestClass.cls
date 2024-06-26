@isTest
private class UpdatePublicFieldTestClass {
    static testMethod void validatePublicField() {
        task t = new task ();
        //Show value before update
        system.debug('Public field before update:' + t.IsVisibleInSelfService);
        //Create new task
        insert t;
        //Test that the trigger correctly updated the 'Public' field
        System.debug('Public field after the trigger fired: ' + t.IsVisibleInSelfService);
    }
}