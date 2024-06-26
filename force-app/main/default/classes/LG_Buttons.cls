/******************************************************************************* 
Name              : LG_Buttons
Description       : Contains general Methods for buttons on LG object 
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan         			06/07/2016          	
*******************************************************************************/
global class LG_Buttons {
	
	/******************************************************************************* 
	Name              : generate_LGPayments2LG
	Description       : Method that will allow to re-create the LG payment to LG from the LG. 
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Hernan         			06/07/2016          	Yaara                 SW-19459
	2. Hernan         			02/17/2017          	Yaara                 SW-23715
	3. Hernan         			03/07/2017          	Yaara                 SW-23973
	*******************************************************************************/
	static webservice string generate_LGPayments2LG(String lgId){
		
		Savepoint sp = Database.setSavepoint();
		try{
			List<LG__c> lgs = [SELECT Id, LG_Type__c, Price_Type__c, Group_Status__c, LG_Start_Paying_Date__c, Declared_Number_of_Students__c FROM LG__c WHERE Id =: lgId];
			
			/*
				In the 3 cases where you calculate payments for Group, the Group_Status__c should be 'Active'
					Price Type = Per Group + Declared Number of payments >0
					Price Type = Per Group + Declared Number of payments = Null/0
					Price Type = Per Studenr + Declared Number of payments >0
	
			*/
			Boolean extraCondition = lgs[0].Price_Type__c == 'Per Group' || (lgs[0].Price_Type__c == 'Per Student' && lgs[0].Declared_Number_of_Students__c > 0);
						
			if(lgs[0].LG_Type__c != 'Demo Lesson' && (!extraCondition || (extraCondition && lgs[0].Group_Status__c == 'Active'))){
				String result = LGHelperMethods.checkCondition2RecreateLGPayment2LG(lgs[0]); 
				if(!String.isBlank(result)){
					return 'Error: ' + result;
				}
				
				LGHelperMethods.doRecreateLGPayment2LG(new Set<Id>{lgId});
			}						
		}catch(Exception e){
			Database.rollback(sp);
			return 'Error: ' + GlobalHelperMethods.ImproveErrorMessage(e); 
		}
		return '';
	}

}