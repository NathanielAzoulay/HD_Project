/******************************************************************************* 
Name              : Sched_CFM_Contacts
Description       : Goes through all Users and checks whether they can be associated to new/changed Content Version files.
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio Caputo	  		26/09/2016          	
*******************************************************************************/
global class Sched_CFM_Contacts implements Schedulable{
	global void execute(SchedulableContext SC){
        Batch_CFM_Contacts b = new Batch_CFM_Contacts();
        database.executebatch(b);        
    }
}