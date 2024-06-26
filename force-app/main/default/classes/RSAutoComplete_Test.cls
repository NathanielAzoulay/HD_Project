@isTest
private class RSAutoComplete_Test{
    static testMethod void RSAutoComplete(){
        //create some test account
        List<Account> accountList = new List<Account>();
        for(Integer i =0 ; i < 200 ; i++){
            accountList.add(new Account(Name='Test'+i, BillingCountry = 'France'));
        }
        //insert test records
        insert accountList;
        Test.startTest();
            System.assertEquals(accountList.size(),RSAutoComplete.getData('Account','Name','Id','T').size());
            System.assertEquals(1, RSAutoComplete.getData('Account','Name','Id','Test111').size());
            System.assertEquals(0, RSAutoComplete.getData('Account','Name','Id','xxxxxxx').size());
            RSAutoComplete controller = new RSAutoComplete();
            controller.setTargetFieldVar(accountList[0].Id);
            System.assertEquals(accountList[0].Id,controller.getTargetFieldVar());
            controller.setCacheField(null);
        Test.stopTest();
        
    }
}