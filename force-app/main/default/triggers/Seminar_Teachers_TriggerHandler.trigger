/******************************************************************************* 
Name              : Seminar_Teachers_TriggerHandler
Description       : Handler the  trigger on Seminar Teachers
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan                   02/25/2016   
2. Rashad Saeed             19/12/2017          fix the trigger logic & add the permissions methods .  
*******************************************************************************/
trigger Seminar_Teachers_TriggerHandler on Seminar_Teachers__c (after insert,after update, before insert, before update) {
   
    if (Trigger.Isbefore && !trigger.Isdelete)
    {
        //SW method 
        Seminar_Teachers_TriggerHandler.populateSeminarTeachersFielsOnBefore(); 
        // Update permissions fields  
        RS_SeminarTeachers_TriggerHandler.SeminarTeacherAux (Trigger.New);
    }
    
    //Shivram : 24 Jan 2018 : Task-000001415
    Map<Id,Seminar_Teachers__c> seminarTeachersMapForReadAccess = new Map<Id,Seminar_Teachers__c>();
    Map<Id,Seminar_Teachers__c> seminarTeachersMapForEditAccess = new Map<Id,Seminar_Teachers__c>();
    if(trigger.isAfter){
        for(Seminar_Teachers__c seminarTeacher : Trigger.newmap.values()){
            if(seminarTeacher.Teacher_Status_in_seminar__c == 'Cancelled'){
                seminarTeachersMapForReadAccess.put(seminarTeacher.Id,seminarTeacher);    
            }
            if(seminarTeacher.Teacher_Status_in_seminar__c != 'Cancelled'){
                seminarTeachersMapForEditAccess.put(seminarTeacher.Id,seminarTeacher);    
            }   
        }
    }
    
     //After Insert
    if(trigger.isAfter && trigger.isInsert ){
        
        // Grant Access to Hosting Franchisee Group And delete the Old One .
        System.debug ('@@@@@@@@@@@@  Seminar_Teachers_TriggerHandler After Update ');
        RSSHARING.RSHelper.RecalcGroup(JSON.serialize(trigger.newMap),JSON.serialize(trigger.OldMap),'HF_ID__c' ,'Hosting_Franchisee__c');
        // Grant Access to TT 
        //RSSHARING.RSHelper.RecalcUser(JSON.serialize(trigger.newMap),JSON.serialize(trigger.OldMap),'TT_ID__c' ,'Teacher_Trainer__c','Edit');
        //Shivram : 24 Jan 2018 : Task-000001415
        if(seminarTeachersMapForEditAccess.size()>0){
            RSSHARING.RSHelper.RecalcUser(JSON.serialize(seminarTeachersMapForEditAccess),JSON.serialize(trigger.OldMap),'TT_ID__c' ,'Teacher_Trainer__c','Edit');    
        }
        if(seminarTeachersMapForReadAccess.size()>0){
            RSSHARING.RSHelper.RecalcUser(JSON.serialize(seminarTeachersMapForReadAccess),JSON.serialize(trigger.OldMap),'TT_ID__c' ,'Teacher_Trainer__c','Read');    
        }
        
        // Grant Access to Teacher 
        RSSHARING.RSHelper.RecalcUser(JSON.serialize(trigger.newMap),JSON.serialize(trigger.OldMap),'TeacherUserID__c' ,'Teacher__c','Read');
        //Teacher_Franchisee_ID__c group 
        RSSHARING.RSHelper.RecalcGroup(JSON.serialize(trigger.newMap),JSON.serialize(trigger.OldMap),'Teacher_Franchisee_ID__c' ,'Teacher_Franchisee__c');
    }
 
    //After Update 
    if(trigger.isAfter && trigger.isUpdate ){
        // Grant Access to Hosting Franchisee Group And delete the Old One .
        System.debug ('@@@@@@@@@@@@  Seminar_Teachers_TriggerHandler After Update ');
        RSSHARING.RSHelper.RecalcGroup(JSON.serialize(trigger.newMap),JSON.serialize(trigger.OldMap),'HF_ID__c' ,'Hosting_Franchisee__c');
        
        //Shivram : 24 Jan 2018 : Task-000001415
        Map<Id,Seminar_Teachers__c> seminarTeachersOldMap = new Map<Id,Seminar_Teachers__c>();
        for(Seminar_Teachers__c seminarTeacher : Trigger.newmap.values()){
            seminarTeachersOldMap.put(seminarTeacher.Id,Trigger.oldMap.get(seminarTeacher.id).clone(true));
            if(seminarTeacher.Teacher_Status_in_seminar__c != Trigger.oldMap.get(seminarTeacher.id).Teacher_Status_in_seminar__c){
                seminarTeachersOldMap.get(seminarTeacher.Id).TT_ID__c=null;
            }
        }
        
        // Grant Access to TT 
        //RSSHARING.RSHelper.RecalcUser(JSON.serialize(trigger.newMap),JSON.serialize(trigger.OldMap),'TT_ID__c' ,'Teacher_Trainer__c','Edit');
        //Shivram : 24 Jan 2018 : Task-000001415
        System.debug('**********'+seminarTeachersMapForEditAccess);
        System.debug('**********'+seminarTeachersOldMap);
        if(seminarTeachersMapForEditAccess.size()>0){
            RSSHARING.RSHelper.RecalcUser(JSON.serialize(seminarTeachersMapForEditAccess),JSON.serialize(seminarTeachersOldMap),'TT_ID__c' ,'Teacher_Trainer__c','Edit');    
        }
        if(seminarTeachersMapForReadAccess.size()>0){
            RSSHARING.RSHelper.RecalcUser(JSON.serialize(seminarTeachersMapForReadAccess),JSON.serialize(seminarTeachersOldMap),'TT_ID__c' ,'Teacher_Trainer__c','Read');    
        }
        
        // Grant Access to Teacher 
        RSSHARING.RSHelper.RecalcUser(JSON.serialize(trigger.newMap),JSON.serialize(trigger.OldMap),'TeacherUserID__c' ,'Teacher__c','Read');
        //Teacher_Franchisee_ID__c group 
        RSSHARING.RSHelper.RecalcGroup(JSON.serialize(trigger.newMap),JSON.serialize(trigger.OldMap),'Teacher_Franchisee_ID__c' ,'Teacher_Franchisee__c');
    } 
}