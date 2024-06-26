@isTest
private class RS_VFC_CourseSubTypesShringReport_Test {
    @isTest(seeAllData=false)
    static void RS_VFC_CourseSubTypesShringReport_Test(){
    	ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        Course_Sub_Type__Share csShare = new Course_Sub_Type__Share (ParentId = testEnv.curseSubTypeId, UserOrGroupId =UserInfo.getUserId(), AccessLevel = 'Read'); 
        ApexPages.currentPage().getParameters().put('studentid',testEnv.studentId);
        RS_VFC_CourseSubTypesShringReport ctrl = new RS_VFC_CourseSubTypesShringReport();
        ctrl.exportToExcel();
    }
}