/******************************************************************************* 
Name              : Seminar_Type_TriggerHandler
Description       : Handler the before/after trigger on Seminar Teachers
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez              06/21/2016                     
*******************************************************************************/
public class Seminar_Type_TriggerHandler {
    
    public static void executeTriggerHandler(){
        
        //  ---------------------------- AFTER EVENTS -----------------------------
        
        /*if (Trigger.isBefore && Trigger.isInsert) 
        {
        }
        else if (Trigger.isBefore && Trigger.isUpdate) 
        {
        }
        /*
        else if (Trigger.isBefore && Trigger.isDelete) // Before Delete
        {
        }
        */
        
        //  ---------------------------- AFTER EVENTS -----------------------------
        
        
        if (Trigger.isAfter && Trigger.isUpdate) // After Update
        {
            SeminarType_CreateSharingRules();
        }       
        else if (Trigger.isAfter && Trigger.isInsert) // After Insert
        {
            SeminarType_CreateSharingRules();
        }
        /*
        else if (Trigger.isAfter && Trigger.isDelete) // After Delete
        {
            
        }
        else if (Trigger.isAfter && Trigger.isUnDelete) // After UnDelete
        {
            
        }
        */      
    }
    
    
    /******************************************************************************* 
    Name              : SeminarType_CreateSharingRules
    Description       : Populate fields before duplicatecheck
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez              06/21/2016          Yaara Nadir              SW-20016          
    2. G. Fernandez              02/01/2017          Dafna Margalit           SW-22980
    *******************************************************************************/
    public static void SeminarType_CreateSharingRules(){
        if( HD_TriggerSettings.IsTriggerActive('SeminarType_CreateSharingRules') ){
            
            List<Seminar_Type__c> seminarTypeList = new List<Seminar_Type__c>();
            for(Integer i=0; i < trigger.size; i++ ){
                Seminar_Type__c st = (Seminar_Type__c) trigger.new[i];
                Boolean cond = false;
                if(trigger.isUpdate){
                    cond = trigger.isUpdate && ((Seminar_Type__c)trigger.old[i]).Active__c <> st.Active__c || ((Seminar_Type__c) trigger.old[i]).OwnerId <> st.OwnerId;
                    cond |= trigger.isUpdate && (((Seminar_Type__c)trigger.old[i]).Program_Type__c <> st.Program_Type__c);
                }
                
                if(st.Active__c == true && (trigger.isInsert || cond) ){
                    seminarTypeList.add(st);
                }
            }

            if(!seminarTypeList.isEmpty()){
                HD_SharingMethods.SeminarType_CreateSharingRules(seminarTypeList);              
            }
        }
    }

}