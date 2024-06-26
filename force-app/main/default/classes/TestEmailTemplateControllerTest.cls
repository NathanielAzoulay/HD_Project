@isTest
private class TestEmailTemplateControllerTest {

    @isTest(seeAllData=false) 
    static void TestEmailTemplateController_Test() {
        
        TestEmailTemplateController controller = new TestEmailTemplateController();
        controller.doInit();
        controller.doSave();
    }
}