/******************************************************************************* 
Name              : Sched_CFM_Membership
Description       : Goes through all CollaborationGroupMember and checks if they are still valid. If not, they get deleted.
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio Caputo	  		26/09/2016          	
*******************************************************************************/
global class Sched_CFM_Membership implements Schedulable{
	global void execute(SchedulableContext SC){
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
		}
		/*
		//Run for Content Versions
        Batch_CFM_Membership b = new Batch_CFM_Membership();
        b.running4CV = true;
        database.executebatch(b);
        
        //Run for Contacts
        b = new Batch_CFM_Membership();
        b.running4CV = false;
        database.executebatch(b);
        */
    }

}