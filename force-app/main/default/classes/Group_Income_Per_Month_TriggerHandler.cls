/******************************************************************************* 
Name              : Group_Income_Per_Month_TriggerHandler
Description       : Handler the before/after trigger on Group_Income_Per_Month
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio Caputo                    08/03/2016              
*******************************************************************************/
public class Group_Income_Per_Month_TriggerHandler {
    public static void executeTriggerHandler(){
        
        //  ---------------------------- BEFORE EVENTS -----------------------------
        
        if (Trigger.isBefore && Trigger.isInsert) // Before Insert
        {
            updateDuration(Trigger.New);   
        }
        else if (Trigger.isBefore && Trigger.isUpdate) // Before Update
        {
            updateDuration(Trigger.New);
        }
        /*
        else if (Trigger.isBefore && Trigger.isDelete){
        }*/
        
        //  ---------------------------- AFTER EVENTS -----------------------------
        
        /*if (Trigger.isAfter && Trigger.isInsert) // After Insert
        {
        }
        
        else if (Trigger.isAfter && Trigger.isUpdate) // After Update
        {
        }   */
        if( Trigger.isAfter && Trigger.isDelete ){
            updateActualStudentFieldOnDelete();
        }   
    }
    
    /******************************************************************************* 
    Description       : When deleting GIPM with Actual Student = 1, need to check if there are other GIPM with Record Type = Calculated Student & same Agreement & Same Month & Same Student 
                        If yes - update the Actual Student for that student to 1
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. Sergio                08/03/2016             Yaara Nadir           [SW-18891]
    *******************************************************************************/
    public static void updateActualStudentFieldOnDelete(){
        if( HD_TriggerSettings.IsTriggerActive('updateActualStudentFieldOnDelete') ){
            Map<Id, Map<Id, Map<Date, Group_Income_Per_Month__c>>> gipmByDateByAgreementByStudent = new Map<Id, Map<Id, Map<Date, Group_Income_Per_Month__c>>>();
            Set<Id> agreementIds = new Set<Id>();
            Id recordTypeId = Schema.SObjectType.Group_Income_Per_Month__c.getRecordTypeInfosByName().get('Calculated Student').getRecordTypeId();
            
            for( Group_Income_Per_Month__c gipm : (List<Group_Income_Per_Month__c>) trigger.old ){
                if( gipm.RecordTypeId == recordTypeId && gipm.Actual_Student__c == 1){
                    if( !gipmByDateByAgreementByStudent.containsKey( gipm.Student__c ) ){
                        gipmByDateByAgreementByStudent.put( gipm.Student__c, new Map<Id, Map<Date, Group_Income_Per_Month__c>>() );
                    }
                    
                    if( !gipmByDateByAgreementByStudent.get( gipm.Student__c).containsKey( gipm.Agreement__c ) ){
                        gipmByDateByAgreementByStudent.get( gipm.Student__c).put( gipm.Agreement__c, new Map<Date, Group_Income_Per_Month__c>() );
                    }
                    
                    Date dt = Date.newInstance( gipm.Royalty_Start_Date__c.year(), gipm.Royalty_Start_Date__c.month(), 1);
                    
                    gipmByDateByAgreementByStudent.get( gipm.Student__c).get( gipm.Agreement__c).put( dt, gipm );
                    
                    agreementIds.add( gipm.Agreement__c );
                }
            }
            
            if( !gipmByDateByAgreementByStudent.isEmpty() ){
                List<Group_Income_Per_Month__c> gipm2Upd = new List<Group_Income_Per_Month__c>();
                
                for( Group_Income_Per_Month__c gipm : [SELECT Id, Royalty_Start_Date__c, Student__c, LG_Student__c, Agreement__c FROM Group_Income_Per_Month__c WHERE Student__c IN :gipmByDateByAgreementByStudent.keySet() AND Actual_Student__c = 0 AND Agreement__c IN :agreementIds AND RecordTypeId = :recordTypeId ] ){
                    if( gipmByDateByAgreementByStudent.containsKey( gipm.Student__c ) ){
                        if( gipmByDateByAgreementByStudent.get( gipm.Student__c ).containsKey( gipm.Agreement__c ) ){
                            Date dt = Date.newInstance( gipm.Royalty_Start_Date__c.year(), gipm.Royalty_Start_Date__c.month(), 1);
                            
                            if( gipmByDateByAgreementByStudent.get( gipm.Student__c ).get( gipm.Agreement__c ).containsKey( dt ) ){
                                //This GIPM has Actual_Student__c == 0 and also is on the same month than a GIPM thats been deleted.
                                gipm.Actual_Student__c = 1;
                                gipm2Upd.add(gipm);
                            }
                        }
                    }
                }
                
                if( !gipm2Upd.isEmpty() ){
                    update gipm2Upd;
                }
            }
        }
    }
      /*
        Description -: on Before insert / update, following method will updates the value in Duration (Trigger) field.
        
            Created/Modified by   Created/Modified Date     Related Task/Issue             
        --------------------------------------------------------------------------
            1. Shivram Saini                01/01/2018      [Task-000001411]
           
      */
        
    public static void updateDuration(List<Group_Income_Per_Month__c> newTgr){
        Id calculatedStudentRecordTypeId = Schema.SObjectType.Group_Income_Per_Month__c.getRecordTypeInfosByName().get('Calculated Student').getRecordTypeId();
        
        for(Group_Income_Per_Month__c gipm : newTgr){
            if(gipm.recordTypeID== calculatedStudentRecordTypeId){
        
                if(gipm.Royalty_Start_Date__c !=null && gipm.Royalty_Start_Date__c < Date.newInstance(2018, 01, 01)){
                    System.debug('********1 if');
                    if(gipm.Royalty_End_Date__c == null){
                        System.debug('********2 if');
                        gipm.Duration_Trigger__c = gipm.Royalty_Start_Date__c.Day() > 14 ? 0.5 : 1;
                    }else if(gipm.Royalty_End_Date__c != null){
                        System.debug('********3 if');
                        gipm.Duration_Trigger__c = gipm.Royalty_End_Date__c.Day() < 15 ? 0.5 : 1;
                    } 
                }else{
                    if(gipm.Royalty_End_Date__c == null){
                        if(gipm.Number_of_days_in_Royalty_Month__c != null && gipm.Royalty_Start_Date__c != null && gipm.Number_of_days_in_Royalty_Month__c != null)
                            gipm.Duration_Trigger__c = ((gipm.Number_of_days_in_Royalty_Month__c - ((gipm.Royalty_Start_Date__c).Day())) + 1) / gipm.Number_of_days_in_Royalty_Month__c ;
                    }else{
                        if(gipm.Royalty_End_Date__c != null && gipm.Number_of_days_in_Royalty_Month__c != null)
                                gipm.Duration_Trigger__c = ((gipm.Royalty_End_Date__c).Day()) / gipm.Number_of_days_in_Royalty_Month__c;  
                    }  
                            
                }         
            }
        }  
        
    }
}