/******************************************************************************* 
Name              : CustomLinkExecute
Description       : class called from javascript in custom links to run batch
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez         28/04/2016              Yaara Nadir              [SW-19188]
*******************************************************************************/

global class CustomLinkExecute {
    webService static void LG_ChangeCompleteBatch() {
        LG_ChangeCompleteBatch batch = new LG_ChangeCompleteBatch();
        Database.executeBatch(batch);
    } 

    webService static void Contact_ChangeToPostStudentBatch() {
        Contact_ChangeToPostStudentBatch batch = new Contact_ChangeToPostStudentBatch();
        Database.executeBatch(batch);
    } 
    
    webService static void Run_RoyaltyCalculationProcess() {
        RoyaltyCalculationProcessStep1 b = new RoyaltyCalculationProcessStep1();
        b.rollback_key              = system.now().getTime();
        b.processName               = 'Batch - Create Royalty Calculation';
        Database.executeBatch(b);
    }
    
    webService static void Batch_CFM_Contacts() {
        /*
        Batch_CFM_Contacts batch = new Batch_CFM_Contacts();
        Database.executeBatch(batch);
        */
    } 
    
    webService static String Batch_CFM_Membership() {
        
        String retVal = 'The Batch is Running';
        
        if( [SELECT count() FROM AsyncApexJob WHERE (ApexClass.Name = 'Batch_CFM_Membership' OR ApexClass.Name = 'Batch_CFM_Users' OR ApexClass.Name = 'Batch_CFM_Contacts') AND (Status = 'Processing' OR Status = 'Preparing')] == 0 ){
            Integer recLimit = 1000;
            Integer limitBatch = 10;
            
            for( HD_Settings_List__c hdSetting : [SELECT Value__c, Name FROM HD_Settings_List__c WHERE Name = 'CFM Batch Iteration Limit' OR Name = 'CFM Batch Record Limit'] ){
                if( hdSetting.Name == 'CFM Batch Record Limit' ){
                    recLimit = Integer.valueOf(hdSetting.Value__c);
                }else{
                    limitBatch = Integer.valueOf(hdSetting.Value__c);
                }
            }
            
            Batch_CFM_Membership batch = new Batch_CFM_Membership();
            batch.step = 0;
            batch.recLimit = recLimit;
            Batch_CFM_Membership.RunBatch(batch, limitBatch);
            //Database.executeBatch(batch);
        }else{
            retVal = 'Please try again in few minutes, the logic is already running';
        }
        
        return retVal;
        /*
        batch = new Batch_CFM_Membership();
        batch.running4CV = false;
        Database.executeBatch(batch);
        */
    } 
    
    webService static void Batch_CFM_Users() {
        /*
        Batch_CFM_Users batch = new Batch_CFM_Users();
        Database.executeBatch(batch);
        */
    } 

    webService static void Batch_SharingForAccountContactRelated() {
        Batch_SharingForAccountContactRelated batch = new Batch_SharingForAccountContactRelated();
        Database.executeBatch(batch);
    } 

    webService static void Batch_CreateUserFromContactBulk() {
        Batch_CreateUserFromContactBulk batch = new Batch_CreateUserFromContactBulk();
        Database.executebatch(batch,1);
    } 

    webService static void Batch_SeminarTypesCreateSharingRules() {
        Batch_SeminarTypesCreateSharingRules batch = new Batch_SeminarTypesCreateSharingRules();
        Database.executebatch(batch,10);
    }
     
    webService static String Batch_CreateAutomaticLGLessonsByBatch_Initial() {
		
		String retVal = 'The Batch is Running';
		if( [SELECT count() FROM AsyncApexJob WHERE (ApexClass.Name = 'CreateAutomaticLGLessonsByBatch') AND (Status = 'Processing' OR Status = 'Preparing')] == 0 ){
			
			CreateAutomaticLGLessonsByBatch b = new CreateAutomaticLGLessonsByBatch();
			b.processName = 'Batch - Create Automatic LG Lessons (Initial)';
			database.executebatch(b);
		}else{
			retVal = 'Please try again in few minutes, the logic is already running';
		}
		
		return retVal;
	}

}