@IsTest
global class ActionGeneratePaymentsTest {

    @isTest global static void ActionGeneratePaymentsTestV1(){
        List<String> listId = new List<String>();
        ListId.add('LSG_ID');
        ListId.add('LSG_ID2');
        Test.startTest();
        ActionGeneratePayments.ExecuteGeneratePayments(ListId);
        Test.stopTest();
    }

    
}