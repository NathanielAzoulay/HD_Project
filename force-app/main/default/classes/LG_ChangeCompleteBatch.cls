/******************************************************************************* 
Name              : LG_ChangeCompleteBatch
Description       : 
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez         26/04/2016              Yaara Nadir              [SW-19188]
2. G. Fernandez         13/07/2016              Yaara Nadir              [SW-20370]
3. G. Fernandez         28/09/2016              Yaara Nadir              [SW-21647]
4. G. Fernandez         12/04/2016              Yaara Nadir              [SW-24460]
*******************************************************************************/

global class LG_ChangeCompleteBatch implements Database.Batchable<sObject> {

    public List<Id> lgIds = new List<Id>();
    public String query;
    Id completedRecordTypeID = LG__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Completed LG').getRecordTypeId();

    global Database.QueryLocator start(Database.BatchableContext bc) {
        query = 'SELECT Id, Completed__c FROM LG__c WHERE' +
        ' ((Group_Status__c = \'Completed\' AND Completed__c = True) OR' +
        ' (Group_Status__c = \'Active\' AND Completed__c = True) OR' +
        ' (Group_Status__c = \'Planned\' AND LG_Start_Date__c <= TOMORROW AND Completed__c = False)) AND' +
        ' (DBAmp_Date__c = null OR Franchisee__r.DBAmp_Stop_Migration__c = \'Yes\')';
        if(!lgIds.isEmpty()){
            query += ' AND Id IN :lgIds';
        }        
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, list<Sobject> scope) {
        
        try{  
            List<LG__c> lgs2up = new List<LG__c>(); 
            Set<Id> lgIds = new Set<Id>(); 
            for(LG__c lg : (List<LG__c>) scope){
                if(lg.Completed__c == true){
                    lg.Group_Status__c = 'Completed';
                    lg.RecordTypeId = completedRecordTypeID;
                    lgIds.add(lg.Id);
                }else{
                    lg.Group_Status__c = 'Active';
                }                
                lgs2up.add(lg);
            }

            List<Database.SaveResult> slr = Database.update(lgs2up,false);
            for(Integer i = 0; i < slr.size(); i++){
                Database.SaveResult sr = slr.get(i);
                if(!sr.isSuccess()){
                    System.debug(System.LoggingLevel.ERROR, 'LG Update Error --> ' + lgs2up[i] + ' ' + sr.getErrors());
                }
            }
            
            //SW-21647 update students in lg to complete
            List<LG_Student__c> student2up = new List<LG_Student__c>();
            for (LG_Student__c lgStudent : [SELECT Status_in_LG__c FROM LG_Student__c WHERE LG__c IN :lgIds AND Status_in_LG__c = 'Registered' and LG__r.Group_Status__c = 'Completed']) {
                lgStudent.Status_in_LG__c = 'Completed';
                student2up.add(lgStudent);
            }

            if(!student2up.isEmpty()){
                slr = Database.update(student2up,false);
                for(Integer i = 0; i < slr.size(); i++){
                    Database.SaveResult sr = slr.get(i);
                    if(!sr.isSuccess()){
                        System.debug(System.LoggingLevel.ERROR, 'LG Student Update Error --> ' + student2up[i] + ' ' + sr.getErrors());
                    }
                }
            }

        }catch(Exception e){
            System.debug(e.getMessage());
        }
    }

    global void finish(Database.BatchableContext BC) {

    }
}