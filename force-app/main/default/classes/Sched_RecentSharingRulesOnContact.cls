/******************************************************************************* 
Name              : Sched_RecentSharingRulesOnContact
Description       : shceduler Batch_SharingRulesOnLastSubFranchisee to run each our
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez             05/08/2016          Yaara Nadir               [SW-20744]
*******************************************************************************/


global class Sched_RecentSharingRulesOnContact implements Schedulable {
    global void execute(SchedulableContext sc) {
		Batch_RecentSharingRulesOnContact batch = new Batch_RecentSharingRulesOnContact();
		Database.executeBatch(batch); 
    }
}
/*
static testMethod void Sched_RecentSharingRulesOnContact_Test() {     
    //Seconds Minutes Hours Day_of_month Month Day_of_week optional_year       
    System.schedule('Sched_RecentSharingRulesOnContact', '0 0 * * * ?', new Sched_RecentSharingRulesOnContact());
}*/