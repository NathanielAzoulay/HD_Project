/******************************************************************************* 
Name              : Account_TriggerHandler
Description       : Handler the before/after trigger on Account
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan Sinclair          05/11/2016              
*******************************************************************************/
public class Account_TriggerHandler {

    public static void executeTriggerHandler(){
        
        //  ---------------------------- BEFORE EVENTS -----------------------------
        if (Trigger.isBefore && Trigger.isUpdate){ // Before Insert
            deactivateAccountUsers();
        }
        
        
        //  ---------------------------- AFTER EVENTS -----------------------------
        if (Trigger.isAfter && Trigger.isInsert){
            accCreateSharingRules();
        }
        
        else if (Trigger.isAfter && Trigger.isUpdate){
            accCreateSharingRules();
            HandleNcOrManagerChange();
        }               
    }
    
    /******************************************************************************* 
    Name              : accCreateSharingRules
    Description       : Handler the sharing record of Account object
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. Hernan Sinclair          05/11/2016              Yaara                 [SW-19263]
    *******************************************************************************/
    
    public static void accCreateSharingRules(){
        
        if( HD_TriggerSettings.IsTriggerActive('accCreateSharingRules') ){
        
            Set<Id> accIds = new Set<Id>();
            for(Integer i=0; i < trigger.size; i++ ){
                Account r = (Account)trigger.new[i];
                if(trigger.isInsert || ((Account)trigger.old[i]).OwnerId <> r.OwnerId || (r.ParentId != null && ((Account)trigger.old[i]).ParentId <> r.ParentId) ){
                    accIds.add(r.Id);
                }
            }
            
            if(!accIds.isEmpty()){
                HD_SharingMethods.Account_CreateSharingRules(accIds);
            }
        }
    }

    /******************************************************************************* 
    Name              : deactivateAccountUsers
    Description       : Disable users when account is not active
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             05/30/2016              Yaara               [SW-19583]
    2. G. Fernandez             11/04/2017              Yaara               [SW-24452]
    *******************************************************************************/
    
    public static void deactivateAccountUsers(){
        if( HD_TriggerSettings.IsTriggerActive('deactivateAccountUsers') ){         
            
            List<Id> accIds = new List<Id>();
            for(Integer i=0; i < trigger.size; i++ ){
                Account acc = (Account)trigger.new[i];
                if( acc.IsPartner == true && ((Account)trigger.old[i]).Account_Status__c == 'Active' && ((Account)trigger.old[i]).Account_Status__c != acc.Account_Status__c){
                    //acc.IsPartner = false;
                    accIds.add(acc.Id);
                }               
            }
            if( !Test.isRunningTest() && !System.isBatch()){
                DeactivateUsersFuture(accIds);
            }
            if( !Test.isRunningTest() && System.isBatch()){
                DeactivateUsers(accIds);
            }
        }
    }

    //SW-24452 MIXED_DML_OPERATION
    @future
    public static void DeactivateUsersFuture(List<Id> accIds){
        if(!accIds.isEmpty()){
            List<User> users2up = new List<User>();
            for(User deactivateUser : [SELECT Id FROM User WHERE AccountId IN :accIds AND IsActive = true]){
                deactivateUser.IsActive = false;
                users2up.add(deactivateUser);
            }

            update users2up;
        }
    }

    //SW-23944 Future method cannot be called from a future or batch method
    public static void DeactivateUsers(List<Id> accIds){
        if(!accIds.isEmpty()){
            List<User> users2up = new List<User>();
            for(User deactivateUser : [SELECT Id FROM User WHERE AccountId IN :accIds AND IsActive = true]){
                deactivateUser.IsActive = false;
                users2up.add(deactivateUser);
            }

            update users2up;
        }
    }

    /******************************************************************************* 
    Name              : HandleNcOrManagerChange
    Description       : Give share to new nc or manager when change
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             16/01/2016              Yaara               [SW-23253]
    *******************************************************************************/
    
    public static void HandleNcOrManagerChange(){
        if( HD_TriggerSettings.IsTriggerActive('HandleNcOrManagerChange') ){         
            
            Id mcTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();
            Id lcsetlsfTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('LC/SET/LSF').getRecordTypeId();
            
            Map<Id,Id> updateNCIds = new Map<Id,Id>();
            Map<Id,Id> updateManagerIds = new Map<Id,Id>();
            for(Integer i=0; i < trigger.size; i++ ){
                Account acc = (Account) trigger.new[i];
                Boolean condType = lcsetlsfTypeId == acc.RecordTypeId || mcTypeId == acc.RecordTypeId;
                if( condType && acc.Partner_Account_NC__c != null && ((Account)trigger.old[i]).Partner_Account_NC__c != acc.Partner_Account_NC__c ){
                    /*if(!updateNCIds.containsKey(acc.Id)){
                        updateNCIds.put(acc.Id, new Set<Id>());
                    }
                    updateNCIds.get(acc.Id).add(acc.Partner_Account_NC__c);*/
                    updateNCIds.put(acc.Id, acc.Partner_Account_NC__c);
                }

                if( condType && acc.Partner_Account_Manager__c != null && ((Account)trigger.old[i]).Partner_Account_Manager__c != acc.Partner_Account_Manager__c){
                    /*if(!updateManagerIds.containsKey(acc.Id)){
                        updateManagerIds.put(acc.Id, new Set<Id>());
                    }
                    updateManagerIds.get(acc.Id).add(acc.Partner_Account_Manager__c);*/
                    updateManagerIds.put(acc.Id, acc.Partner_Account_Manager__c);
                }               
            }

            if( !updateNCIds.isEmpty() ){
                HD_SharingMethods.Account_CreateNCSharingRules(updateNCIds);
            }
            
            if( !updateManagerIds.isEmpty() ){
                HD_SharingMethods.Account_CreateManagerSharingRules(updateManagerIds);
            }
        }
    }

}