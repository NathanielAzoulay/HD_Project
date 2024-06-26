@isTest
private class LG_ChangeCompleteBatch_Test {
   
    @isTest(seeAllData=false)
    static void LG_ChangeCompleteBatch_Test() {
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        Account acc = new Account(Id = testEnv.accId);
        acc.DBAmp_Stop_Migration_MF__c  = 'Yes';
        acc.Account_Type__c = 'MF';
        update acc;

        LG__c lg = new LG__c(Id = testEnv.lgId);
        lg.LG_Start_Date__c = System.today().addDays(-20);
        lg.LG_End_Date__c = System.today().addDays(-2);
        lg.LG_Start_Paying_Date__c = System.today().addDays(-20);
        //lg.LG_End_Paying_Date__c = System.today().addDays(-2);
        lg.LG_Type__c = 'Standard';        
        lg.Group_Status__c = 'Planned';
        lg.DBAmp_Date__c = null;
        lg.Franchisee__c = acc.Id;
        update lg;

        lg.Group_Status__c = 'Active';
        update lg;

        LG_Student__c lgstudent = new LG_Student__c(Id = testEnv.studentId);
        lgstudent.Status_in_LG__c= 'Registered';
        lgstudent.Student_Start_Paying_Date__c = System.today().addDays(-20);
        lgstudent.Student_End_Paying_Date__c = System.today().addDays(-2);
        lgstudent.Student_Course_Start_Date__c = System.today().addDays(-20);
        lgstudent.Student_Course_End_Date__c = System.today().addDays(-2); 
        update lgstudent;

        System.assertEquals(1, [SELECT Id FROM LG__c WHERE Id = :lg.Id AND Completed__c = true AND Group_Status__c = 'Active'].size());

        String query = 'SELECT Id, Completed__c, DBAmp_Date__c, Franchisee__r.DBAmp_Stop_Migration__c FROM LG__c WHERE' +
        ' ((Group_Status__c = \'Completed\' AND Completed__c = True) OR' +
        ' (Group_Status__c = \'Active\' AND Completed__c = True) OR' +
        ' (Group_Status__c = \'Planned\' AND LG_Start_Date__c <= TOMORROW AND Completed__c = False))';

        lg = Database.query(query);
        System.debug(System.LoggingLevel.ERROR, lg.Franchisee__r.DBAmp_Stop_Migration__c);
        System.debug(System.LoggingLevel.ERROR, lg.DBAmp_Date__c);
        acc = [SELECT Id, Account_Type__c, DBAmp_Stop_Migration_MF__c, DBAmp_Stop_Migration__c FROM Account WHERE Id = :acc.Id];
        System.debug(System.LoggingLevel.ERROR, acc.Account_Type__c);
        System.debug(System.LoggingLevel.ERROR, acc.DBAmp_Stop_Migration_MF__c);
        System.debug(System.LoggingLevel.ERROR, acc.DBAmp_Stop_Migration__c);

        Test.startTest();
            LG_ChangeCompleteBatch batch = new LG_ChangeCompleteBatch();
            batch.lgIds.add(lg.Id);

            Database.executeBatch(batch);
        Test.stopTest();

        System.assertEquals(1, [SELECT Id FROM LG__c WHERE Id = :lg.Id AND Group_Status__c = 'Completed'].size());
        System.assertEquals(1, [SELECT Id FROM LG_Student__c WHERE Id = :lgstudent.Id AND Status_in_LG__c = 'Completed'].size());

    }
}