/******************************************************************************* 
Name              : LG_Student_Buttons
Description       : Contains general Methods for buttons on LG Student object 
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan         			06/07/2016          	
*******************************************************************************/
global class LG_Student_Buttons {
	
	/******************************************************************************* 
	Name              : generate_LGPayments2LGStudent
	Description       : Method that will allow to re-create the LG payment to LG Student from the LG Student. 
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Hernan         			06/07/2016          	Yaara                 SW-19460
	2. Hernan         			02/17/2016          	Yaara                 SW-23716
	3. Hernan         			03/07/2017          	Yaara                 SW-23973
	*******************************************************************************/
	@AuraEnabled
	static webservice string generate_LGPayments2LGStudent(String lgSId){
		
		Savepoint sp = Database.setSavepoint();
		try{
			List<LG_Student__c> lgSs = [SELECT Id, LG__r.LG_Type__c, LG__r.Price_Type__c, LG__r.Declared_Number_of_Students__c, Student_Start_Paying_Date__c FROM LG_Student__c WHERE Id =: lgSId];			
			if(lgSs[0].LG__r.LG_Type__c != 'Demo Lesson'){
				String result = LGHelperMethods.checkCondition2RecreateLGPayment2LGStudent(lgSs[0]); 
				if(!String.isBlank(result)){
					return 'Error: ' + result;
				}
				
				LGHelperMethods.doRecreateLGPayment2LGStudent(new Set<Id>{lgSId});
			}		
		}catch(Exception e){
			Database.rollback(sp);
			return 'Error: ' + GlobalHelperMethods.ImproveErrorMessage(e);
		}
		return '';
	}


	@InvocableMethod(label='generate Payment LG students') 
	public static List<FlowOutput> generate_LGPayments2LGStudentFromFlow(List<FlowInput> params) {
		String lgSId = params[0].lgSId;
		List<FlowOutput> results = new List<FlowOutput>();
		String message = generate_LGPayments2LGStudent(lgSId);
		
		results.add(new FlowOutput(message));
        return results;
	}

	public class FlowInput
    {
      @InvocableVariable public String lgSId;
    }

    public class FlowOutput
    {
      @InvocableVariable public String message;
      public FlowOutput(String myMessage) {this.message = myMessage;}
    }

}