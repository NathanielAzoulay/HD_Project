/*
******************************************************************************************************************** 
Name              : TaskTriggerHandlerTest
Description       : Test class for TaskTriggerHandler.

Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. ShivRam Saini           05/02/2018           Gidi Abramovich          [Task-000001417]
*********************************************************************************************************************
*/

@isTest
public class TaskTriggerHandlerTest {
    @isTest
    static void beforeInsertMethod(){
        //insert account
        Account acc = new Account(Name = 'TestRECORD', BillingCountry = 'India');
        insert acc;
        
        //insert advice of payment
        Advice_of_payment__c aop = new Advice_of_payment__c();
        aop.Account__c = acc.Id;
        aop.Status__c = 'Payment Draft';
        aop.Account__c = acc.Id;
        insert aop;
        
        //insert closure form
        Closure_Form__c cf = new Closure_Form__c();
        cf.Closure_Type__c = 'cancelled';
        cf.Closure_Date__c = System.today();
        cf.Franchisee_Name__c = acc.Id;
         insert cf;
        
        //insert renewal advice
        Renewal_Advice__c ra = new Renewal_Advice__c();
        ra.Status__c  = 'New';
        ra.Link_to_LC_LCF__c = acc.Id;
        insert ra;
        
        //insert resale forms
        Resale_Forms__c rf = new Resale_Forms__c();
        rf.Currency__c = 'Euro';
        rf.Link_to_former_LC_LCF__c = acc.Id;
        insert rf;
        
        //insert new account advice
        New_Account_Advice__c naa = new New_Account_Advice__c();
        naa.Currency__c = 'Euro';
        naa.Link_to_Account__c = acc.Id;
        insert naa;
        
        //HDC Admin User
        User u3 = [SELECT Id FROM User WHERE Name='HDC Admin'];
        System.runAs(u3) {
            Task t = new Task();
            t.OwnerId = UserInfo.getUserId();
            t.Subject='Donni';
            t.Status='Not Started';
            t.Priority='Normal';
            t.WhatId = aop.id;
            insert t;
            
            Task t2 = new Task();
            t2.OwnerId = UserInfo.getUserId();
            t2.Subject='Donni';
            t2.Status='Not Started';
            t2.Priority='Normal';
            t2.WhatId = cf.id;
            insert t2; 
            
            Task t3 = new Task();
            t3.OwnerId = UserInfo.getUserId();
            t3.Subject='Donni';
            t3.Status='Not Started';
            t3.Priority='Normal';
            t3.WhatId = ra.id;
            insert t3; 
            
            Task t4 = new Task();
            t4.OwnerId = UserInfo.getUserId();
            t4.Subject='Donni';
            t4.Status='Not Started';
            t4.Priority='Normal';
            t4.WhatId = rf.id;
            insert t4; 
            
            Task t5 = new Task();
            t5.OwnerId = UserInfo.getUserId();
            t5.Subject='Donni';
            t5.Status='Not Started';
            t5.Priority='Normal';
            t5.WhatId = naa.id;
            insert t5; 
        }


    }
}