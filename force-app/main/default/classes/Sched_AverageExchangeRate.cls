/******************************************************************************* 
Name              : Sched_AverageExchangeRate
Description       : 
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio	             07/05/2016  	        Yaara Nadir               [SW-19970]
*******************************************************************************/

global class Sched_AverageExchangeRate implements Schedulable{
	global void execute(SchedulableContext SC){
        Batch_AverageExchangeRate b = new Batch_AverageExchangeRate();
        database.executebatch(b);        
    }
    /*
    static testmethod void Sched_AverageExchangeRate_Test() {        
        Test.startTest();
        String jobId = System.schedule('testBasicScheduledApex', '0 0 0 3 9 ? 2042', new Sched_AverageExchangeRate());
        Test.stopTest();        
    }*/
}