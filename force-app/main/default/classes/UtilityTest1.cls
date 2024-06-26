@isTest
public class UtilityTest1 {
    @isTest
    static void unitTest1(){
        Utility1.readFieldSet('LG_Discount__c');
        Utility1.getFieldSet('LG_Discount__c','SPOrZeroMonthlyPayment');
    }
}