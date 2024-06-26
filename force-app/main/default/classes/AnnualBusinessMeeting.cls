public with sharing class AnnualBusinessMeeting {

    public String accountBuisness { get; set; }
    public List<Account> accounts { get; set; }

    public AnnualBusinessMeeting() {

        String accountId = ApexPages.currentPage().getParameters().get('acountId');
        System.debug(accountId);

        accounts = [SELECT Id, BillingCountry, Account_No_in_Priority__c, Name FROM Account WHERE Id = :accountId LIMIT 1];

        if (!accounts.isEmpty()) { 
            Account selectedAccount = accounts[0]; //
            accountBuisness = selectedAccount.Account_No_in_Priority__c;
        }
    }
}