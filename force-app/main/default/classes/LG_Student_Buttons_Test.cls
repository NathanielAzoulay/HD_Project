@IsTest(SeeAllData=true)
private class LG_Student_Buttons_Test {
    @isTest static void testGenerate_LGPayments2LGStudent() {
        LG_Student__c testStudent = [SELECT Id FROM LG_Student__c WHERE LG__r.LG_Type__c = 'Standard' LIMIT 1];

        // Call the method to test
        String result = LG_Student_Buttons.generate_LGPayments2LGStudent(testStudent.Id);

        // Assert the result
        System.assertEquals('', result);
    }

    @isTest static void testGenerate_LGPayments2LGStudentFromFlow() {
        // Prepare test data
        LG_Student__c testStudent = [SELECT Id FROM LG_Student__c WHERE LG__r.LG_Type__c = 'Standard' LIMIT 1];


        // Prepare the input parameter
        LG_Student_Buttons.FlowInput input = new LG_Student_Buttons.FlowInput();
        input.lgSId = testStudent.Id;

        // Call the method to test
        List<LG_Student_Buttons.FlowOutput> results = LG_Student_Buttons.generate_LGPayments2LGStudentFromFlow(new List<LG_Student_Buttons.FlowInput>{input});

        // Assert the result
        System.assertEquals(1, results.size());
        System.assertEquals('', results[0].message);
    }
}