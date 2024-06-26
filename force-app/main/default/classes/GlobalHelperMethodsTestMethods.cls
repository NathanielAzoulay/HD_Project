/******************************************************************************* 
Name              : GlobalHelperMethodsTestMethods
Description       : Test class for GlobalHelperMethods 
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan         			02/29/2016          	
*******************************************************************************/
@isTest
private class GlobalHelperMethodsTestMethods {
	
	@isTest(seeAllData=false)
	static void getIMonth_Test(){		
		GlobalHelperMethods.getIMonth('January');
	}
	
	@isTest(seeAllData=false)
	static void getQueryString_Test(){		
		GlobalHelperMethods.getQueryString(new LG__c());
	}
	
	@isTest(seeAllData=false)
	static void ImproveErrorMessage_Test(){		
		try{
			system.debug(0/0);
		}catch(Exception ex){
			GlobalHelperMethods.ImproveErrorMessage(ex);
		}
	}
	
	@isTest(seeAllData=false)
	static void IncludeAllErrorMessage_Test(){		
		try{
			system.debug(0/0);
		}catch(Exception ex){
			GlobalHelperMethods.IncludeAllErrorMessage(ex);
		}
	}
	
	@isTest(seeAllData=false)
	static void ImproveErrorMessage2_Test(){		
		GlobalHelperMethods.ImproveErrorMessage('asdsadsadsa FIELD_CUSTOM_VALIDATION_EXCEPTION : asdasdsdaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa: asdasdsdaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
	}
	
	@isTest(seeAllData=false)
	static void isnull_Test(){		
		long l;
		GlobalHelperMethods.ifnull(l);
		Decimal d;
		GlobalHelperMethods.ifnull(d);
		Decimal i;
		GlobalHelperMethods.ifnull(i);
	}
	
}