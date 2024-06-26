/******************************************************************************* 
Name              : Seminar_TriggerHandler
Description       : Handler the  trigger on Account
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez             06/22/2016      
2. Rashad Saeed             19/12/2017          fix the trigger logic & add the permissions methods .
*******************************************************************************/
trigger Seminar_TriggerHandler on Seminar__c (after insert,after update,Before Update) {

    //Seminar_TriggerHandler.executeTriggerHandler();
    
     //After Insert
    if(trigger.isAfter && trigger.isInsert ){
        // Grant Access to Hosting Franchisee Group.
        RSSHARING.RSHelper.RecalcGroup(JSON.serialize(trigger.newMap),JSON.serialize(trigger.OldMap),'Hosting_Franchisee__c' ,'Hosting_Franchisee__c');
        //Grant Access to Teacher Trainer for Seminar .
        RSSHARING.RSHelper.RecalcUser (JSON.serialize(trigger.newMap),JSON.serialize(trigger.OldMap),'TT_UID__c' ,'Teacher_Trainer__c', 'Edit'); 
         
    }
   
    //After Update
    if(trigger.isAfter && trigger.isUpdate  ){ 
        //On change  Grant Access to the new Hosting Franchisee Group.
        RSSHARING.RSHelper.RecalcGroup(JSON.serialize(trigger.newMap),JSON.serialize(trigger.OldMap),'Hosting_Franchisee__c' ,'Hosting_Franchisee__c');
        //On change Grant Access to the new Teacher Trainer for Seminar .
        RSSHARING.RSHelper.RecalcUser (JSON.serialize(trigger.newMap),JSON.serialize(trigger.OldMap),'TT_UID__c' ,'Teacher_Trainer__c', 'Edit');
        // Grant Access for TT to Teachers Registration And Delete Old permissoins . 
          RS_Seminar_TriggerHandler.RunSeminarTeacherAux (trigger.newMap,trigger.OldMap); 
        
    } 
}