/******************************************************************************* 
Name              : ContactTransferOwnership_Ctrl 
Description       : Used for Transfering ownership of Contacts
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio              17/02/2017                  Yaara Nadir            [SW-23722]
*******************************************************************************/

public without sharing class ContactTransferOwnership_Ctrl {
    public Contact contact {get;set;}
    public String resp {get;set;}
    
    public ContactTransferOwnership_Ctrl(ApexPages.StandardController controller) {
        contact = (Contact) controller.getRecord();
    }
    
    public PageReference Save(){
        PageReference returnPage = null;
        try{
            contact.AccountId = contact.Transfer_to_Franchise__c;
            
            for( Account acc : [SELECT Id, Partner_Account_User__c FROM Account WHERE Id = :contact.Transfer_to_Franchise__c LIMIT 1]){
                contact.OwnerId = acc.Partner_Account_User__c;
            }
            
            update contact;
            
            resp = '{"success":"true"}';
        }catch(Exception e){
            resp = '{"success":"false","msg":"'+    GlobalHelperMethods.ImproveErrorMessage( e ) +'"}';
        }
        return returnPage;
    }
}