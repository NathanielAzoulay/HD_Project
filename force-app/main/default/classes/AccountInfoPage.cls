public with sharing class AccountInfoPage {

    public String name { get; set; }
    public List<Account> accounts { get; set; }
    public String accountBuisness { get; set; }
    public String country { get; set; }
    
    public AccountInfoPage() {

        String accountId = ApexPages.currentPage().getParameters().get('acountId');
       // System.debug(accountId);
        accounts = [SELECT Id, BillingCountry, Account_No_in_Priority__c, Name FROM Account WHERE Id = :accountId LIMIT 1];

        if (!accounts.isEmpty()) { 
            Account selectedAccount = accounts[0]; // Récupérer le premier enregistrement de la liste
            country = selectedAccount.BillingCountry;
            accountBuisness = selectedAccount.Account_No_in_Priority__c;
            name = selectedAccount.Name;
        }
    }
}