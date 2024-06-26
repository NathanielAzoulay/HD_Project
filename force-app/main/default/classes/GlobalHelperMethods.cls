/******************************************************************************* 
Name              : GlobalHelperMethods
Description       : For Generic Propouse
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan         			02/29/2016          	
*******************************************************************************/
public class GlobalHelperMethods {
	
	public static String findObjectNameFromRecordIdPrefix(String recordIdOrPrefix){
        String objectName = '';
        try{
            //Get prefix from record ID
            //This assumes that you have passed at least 3 characters
            String myIdPrefix = String.valueOf(recordIdOrPrefix).substring(0,3);
             
            //Get schema information
            Map<String, Schema.SObjectType> gd =  Schema.getGlobalDescribe(); 
             
            //Loop through all the sObject types returned by Schema
            for(Schema.SObjectType stype : gd.values()){
                Schema.DescribeSObjectResult r = stype.getDescribe();
                String prefix = r.getKeyPrefix();
                //System.debug('Prefix is ' + prefix);
                 
                //Check if the prefix matches with requested prefix
                if(prefix!=null && prefix.equals(myIdPrefix)){
                    objectName = r.getName();
                    System.debug('Object Name! ' + objectName);
                    break;
                }
            }
        }catch(Exception e){
            System.debug(e);
        }
        return objectName;
    }
	/*
		Method that will return the Index of the month passing by parameter
	*/
	public static Integer getIMonth(String mName){
		return new Map<String, Integer>{'January'=>1,'February'=>2,'March'=>3,'April'=>4,'May'=>5,'June'=>6,'July'=>7,'August'=>8,'September'=>9,'October'=>10,'November'=>11,'December'=>12}.get(mName);
	}
	
	/* 
		Query util method 
	*/
	public static String getQueryString(SObject sObj){
		
		DescribeSObjectResult describeResult = sObj.getSObjectType().getDescribe();
		List<String> fieldNames = new List<String>( describeResult.fields.getMap().keySet() );
		return ' SELECT ' + String.join( fieldNames, ',' ) + ' FROM ' + describeResult.getName();
    }

	/* Methods for debugin and clear errors */
	public static Exception debugErrorMsg( Exception e ){
        System.debug(System.Logginglevel.ERROR, 'errorMsg: ' 
        	+ e.getMessage() 
        	+ '\nStack Trace:' + e.getStackTraceString() 
        	+ '\nLine Number:' + e.getLineNumber() 
        	+ '\nException Type:' + e.getTypeName()
        );
        return e;
	}
	
	public static String IncludeAllErrorMessage(Exception e){
		String errorMsg = e.getMessage() 
        	+ '\nStack Trace:' + e.getStackTraceString() 
        	+ '\nLine Number:' + e.getLineNumber() 
        	+ '\nException Type:' + e.getTypeName();
        	return errorMsg;
	}
	
	public static String ImproveErrorMessage(Exception e){
		debugErrorMsg(e);
		return ImproveErrorMessage(e.getMessage());
	}
	
	public static String ImproveErrorMessage(String msj){
		String result = msj;
		
		if(result.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
		    Integer lastIndex = result.length();
		    if(result.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION') < result.lastIndexOf(':')){
		        lastIndex = result.lastIndexOf(':');
		    }
		    result = result.substring(result.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION') + 'FIELD_CUSTOM_VALIDATION_EXCEPTION'.length()+2, lastIndex);
		}
		return result;
	}
	
	public static long ifnull(long num ) {
		if (num == null) num = 0;
		return num;
	}
	
	public static integer ifnull(integer num ) {
		if (num == null) num = 0;
		return num;
	}
	
	public static decimal ifnull(decimal num ) {
		if (num == null) num = 0;
		return num;
	}

}