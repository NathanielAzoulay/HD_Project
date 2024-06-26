/*
*********************************************************************************************************************** 
Name              : TaskTriggerHandler
Description       : Change the task owner whenever task is created by HDC Admin user and reference whatId by
                    Advice of Payments OR Closure Forms OR Renewal Advices OR Resale Forms OR New Accounts Advice,
                    by the owner of the record.

Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. ShivRam Saini           05/02/2018           Gidi Abramovich          [Task-000001417]
***********************************************************************************************************************
*/
public class TaskTriggerHandler{

 public void changeOwnerMethod(List<Task> taskList){
        Set<Id> adviceofPaymentSet = new Set<Id>();
        Set<Id> closureformSet = new Set<Id>();
        Set<Id> renewaladviceSet = new Set<Id>();
        Set<Id> resaleformsSet = new Set<Id>();
        Set<Id> newaccountadviceSet = new Set<Id>();
        
        Map<Id, Advice_of_payment__c> adviceofPaymentMap = new Map<Id, Advice_of_payment__c>();
        Map<Id, Closure_Form__c> closureformMap = new Map<Id, Closure_Form__c>();
        Map<Id, Renewal_Advice__c> renewaladviceMap = new Map<Id, Renewal_Advice__c>();
        Map<Id, Resale_Forms__c> resaleformsMap = new Map<Id, Resale_Forms__c>();
        Map<Id, New_Account_Advice__c> newaccountadviceMap = new Map<Id, New_Account_Advice__c>();
        
        system.debug('taskList size '+taskList.size());
        system.debug('user '+userinfo.getName());
        
        for(Task newTask : taskList){
              if(newTask.WhatId != null && userinfo.getName() == 'HDC Admin'){
                 if(String.valueof(newTask.WhatId.getSobjectType()) ==  'Advice_of_payment__c'){
                     adviceofPaymentSet.add(newTask.WhatId);
                 }else if(String.valueof(newTask.WhatId.getSobjectType()) ==  'Closure_Form__c'){
                     closureformSet.add(newTask.WhatId);
                 }else if(String.valueof(newTask.WhatId.getSobjectType()) ==  'Renewal_Advice__c'){
                     renewaladviceSet.add(newTask.WhatId);
                 }else if(String.valueof(newTask.WhatId.getSobjectType()) ==  'Resale_Forms__c'){
                     resaleformsSet.add(newTask.WhatId);
                 }else if(String.valueof(newTask.WhatId.getSobjectType()) ==  'New_Account_Advice__c')
                     newaccountadviceSet.add(newTask.WhatId);          
              }   
        }
        
        if(adviceofPaymentSet.size() > 0){
           for(Advice_of_payment__c aop : [select id, Account__r.Id, Account__r.ownerId from Advice_of_payment__c where Id IN: adviceofPaymentSet]){
               adviceofPaymentMap.put(aop.id, aop);
           } 
        }
        
        if(closureformSet.size() > 0){
           for(Closure_Form__c aop : [select id, Franchisee_Name__r.Id, Franchisee_Name__r.ownerId from Closure_Form__c where Id IN: closureformSet]){
               closureformMap.put(aop.id, aop);
           } 
        }
        
        if(renewaladviceSet.size() > 0){
           for(Renewal_Advice__c aop : [select id, Link_to_LC_LCF__r.Id, Link_to_LC_LCF__r.ownerId from Renewal_Advice__c where Id IN: renewaladviceSet]){
               renewaladviceMap.put(aop.id, aop);
           } 
        }
        if(resaleformsSet.size() > 0){
           for(Resale_Forms__c aop : [select id, Link_to_former_LC_LCF__r.Id, Link_to_former_LC_LCF__r.ownerId from Resale_Forms__c where Id IN: resaleformsSet]){
               resaleformsMap.put(aop.id, aop);
           } 
        }
        if(newaccountadviceSet.size() > 0){
           for(New_Account_Advice__c aop : [select id, Link_to_Account__r.Id, Link_to_Account__r.ownerId from New_Account_Advice__c where Id IN: newaccountadviceSet]){
               newaccountadviceMap.put(aop.id, aop);
           } 
        }
        
        for(Task newTask : taskList){
              if(newTask.WhatId != null && userinfo.getName() == 'HDC Admin'){
                 if(String.valueof(newTask.WhatId.getSobjectType()) ==  'Advice_of_payment__c' && adviceofPaymentMap.containsKey(newTask.WhatId) && adviceofPaymentMap.get(newTask.WhatId).Account__r.Id != null){
                     newTask.OwnerId = adviceofPaymentMap.get(newTask.WhatId).Account__r.ownerId;
                 }else if(String.valueof(newTask.WhatId.getSobjectType()) ==  'Closure_Form__c' && closureformMap.containsKey(newTask.WhatId) && closureformMap.get(newTask.WhatId).Franchisee_Name__r.Id != null){
                     newTask.OwnerId = closureformMap.get(newTask.WhatId).Franchisee_Name__r.ownerId;
                    
                 }else if(String.valueof(newTask.WhatId.getSobjectType()) ==  'Renewal_Advice__c' && renewaladviceMap.containsKey(newTask.WhatId) && renewaladviceMap.get(newTask.WhatId).Link_to_LC_LCF__r.Id != null){
                     newTask.OwnerId = renewaladviceMap.get(newTask.WhatId).Link_to_LC_LCF__r.ownerId;
                    
                 }else if(String.valueof(newTask.WhatId.getSobjectType()) ==  'Resale_Forms__c' && resaleformsMap.containsKey(newTask.WhatId) && resaleformsMap.get(newTask.WhatId).Link_to_former_LC_LCF__r.Id != null){
                     newTask.OwnerId = resaleformsMap.get(newTask.WhatId).Link_to_former_LC_LCF__r.ownerId;
                     
                 }else if(String.valueof(newTask.WhatId.getSobjectType()) ==  'New_Account_Advice__c' && newaccountadviceMap.containsKey(newTask.WhatId) && newaccountadviceMap.get(newTask.WhatId).Link_to_Account__r.Id != null)
                     newTask.OwnerId = newaccountadviceMap.get(newTask.WhatId).Link_to_Account__r.ownerId; 
                           
              }   
        }
        
     }
}