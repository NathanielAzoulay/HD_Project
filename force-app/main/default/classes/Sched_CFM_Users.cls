/******************************************************************************* 
Name              : Sched_CFM_Users
Description       : Goes through all ContentVersion and checks whether they can be associated to Users.
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio Caputo	  		26/09/2016          	
*******************************************************************************/
global class Sched_CFM_Users implements Schedulable{
	global void execute(SchedulableContext SC){
        Batch_CFM_Users b = new Batch_CFM_Users();
        database.executebatch(b);        
    }

}