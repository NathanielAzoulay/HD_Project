@isTest
private class LGRemoveStudentController_Test {
    @isTest(seeAllData=false)
    static void LGRemoveStudentController_Test(){
    	ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

        ApexPages.currentPage().getParameters().put('studentid',testEnv.studentId);
        LGRemoveStudentController ctrl = new LGRemoveStudentController();
        ctrl.dummyStudent.Student_Course_End_Date__c = System.today().addDays(30);
        ctrl.dummyStudent.LG__c = testEnv.lgId;            

		ctrl.doChange();
		ctrl.ChangeForm();
		ctrl.getStep();

        ctrl.dummyStudent.Student_End_Paying_Date__c = System.today().addDays(30);		
		ctrl.dummyStudent.Drop_Out_Reason__c = 'Financial reasons';
		ctrl.dummyStudent.Status_in_LG_Comment__c = 'test';

		ctrl.doRemove();
    }
}