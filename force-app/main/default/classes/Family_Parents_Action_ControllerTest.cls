@isTest
private class Family_Parents_Action_ControllerTest {

    @isTest(seeAllData=false)
    static void myUnitTest_Family_Parents_Action_Controller() {
        
		ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
		
		ApexPages.StandardController sc = new ApexPages.StandardController(new Contact(id = testEnv.studentContactId));
        ApexPages.currentPage().getParameters().put('contactID', testEnv.studentContactId);
        Family_Parents_Action_Controller controller = new Family_Parents_Action_Controller(sc);
        controller.getCloseWindow();
    }
}