/******************************************************************************* 
Name              : LG_ChangeCompleteBatchScheduler
Description       : 
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez         26/04/2016              Yaara Nadir              [SW-19188]
*******************************************************************************/


global class LG_ChangeCompleteBatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
		LG_ChangeCompleteBatch batch = new LG_ChangeCompleteBatch();
		Database.executeBatch(batch); 
    }
}
/*
static testMethod void LG_ChangeCompleteBatchScheduler_Test() {     
           
    System.schedule('LG_ChangeCompleteBatchScheduler', '0 0 01 * * ?', new LG_ChangeCompleteBatchScheduler());
}*/