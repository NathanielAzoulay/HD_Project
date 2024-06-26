@isTest
private class BC_Assessment_TriggerHandler_Test {
    
    @isTest(seeAllData=false)
    static void createLGStudentAssessments_Test() {
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        Map<String,Set<Id>> bcAssessMap = new Map<String,Set<Id>>();

        LG_Student__c lgStudent = new LG_Student__c(Id = testEnv.studentId);
        lgStudent.Status_in_LG__c = 'Registered';
        update lgStudent;

        LG__c lg = new LG__c(Id = testEnv.lgId);
        lg.LG_End_Date__c = System.today().addDays(2);
        update lg;

        BC_Assessment__c newAssess = new BC_Assessment__c();
        newAssess.Base_Course__c = testEnv.baseCurseId;
        newAssess.Active__c = true;
        newAssess.Test_Type__c = 'Read';
        insert newAssess;
                    
        String id15 = String.valueOf(testEnv.baseCurseId).substring(0, 15);
        bcAssessMap.put(id15, new Set<Id>{newAssess.Id});

        lgStudent = [SELECT Id, Completed__c, Status_in_LG__c, Base_Course_Id__c, LG__r.Course_Sub_Type__r.Base_Course__r.Status__c FROM LG_Student__c WHERE Id = :lgStudent.Id];   

        Test.startTest();

            Batch_CreateLGStudentAssessments b = new Batch_CreateLGStudentAssessments();
            b.bcAssessMap = bcAssessMap;
            Database.executeBatch(b);

        Test.stopTest();

        System.assert([SELECT Id FROM LG_Student_Assessment__c WHERE BC_Assessment__c = :newAssess.Id AND LG_Student__c = :testEnv.studentId].size() == 1);

    }

}