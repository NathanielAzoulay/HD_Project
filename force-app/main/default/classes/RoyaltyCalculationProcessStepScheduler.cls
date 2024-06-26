/**************************************************************************************** 
    Name              : RoyaltyCalculationProcessStep1
    Description       : Step 1 - The process will delete records that doesn't have checkbox field:  Allow to Delete = True in Royalty Calculation
    Revision History  :-
    Created/Modified by         Created/Modified Date     Requested by      Related Task/Issue  
    ----------------------------------------------------------------------------------------
    1. Hernan (Created)         07/07/2016                Yaara                [SW-18002] / [SW-19971]
    2.Rashad Saeed              15-Oct-2017               Hide Lines 16-19 add new Lines 20-21
    ----------------------------------------------------------------------------------------    
****************************************************************************************/
global class RoyaltyCalculationProcessStepScheduler implements Schedulable{

   // Hide By Rashad
   global void execute(SchedulableContext SC){
    
       /* RoyaltyCalculationProcessStep1 b = new RoyaltyCalculationProcessStep1();
        b.rollback_key              = system.now().getTime();
        b.processName               = 'Batch - Create Royalty Calculation';
        Database.executeBatch(b); */
        RSRoyaltyCalculation rs = new RSRoyaltyCalculation();
        Database.executeBatch(rs,5);
    }

}