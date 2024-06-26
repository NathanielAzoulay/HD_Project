/******************************************************************************* 
Name              : AdditionalHolidays_TriggerHandler
Description       : 
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G.Fernandez              25/04/2016         	
*******************************************************************************/

public class AdditionalHolidays_TriggerHandler {
	public static void executeTriggerHandler(){
    	
		//  ---------------------------- BEFORE EVENTS -----------------------------
		if (Trigger.isBefore && Trigger.isDelete){
			deleteHolidayVacation();
		}
		
		
		//  ---------------------------- AFTER EVENTS -----------------------------
		if (Trigger.isAfter && Trigger.isInsert){
			duplicateHolidayVacation();
		}
	}  

    /******************************************************************************* 
	Name              : duplicateHolidayVacation
	Description       : duplicate ONE identic holiday vacations on additional holiday created.
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G.Fernandez              25/04/2016         	Yaara Nadir 			SW-19138
	*******************************************************************************/

    public static void duplicateHolidayVacation(){
    	if( HD_TriggerSettings.IsTriggerActive('duplicateHolidayVacation') ){

    		Id mfRecordypeId = Holiday_Vacation__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('MF').getRecordTypeId();
    		Id lcRecordypeId = Holiday_Vacation__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('LC').getRecordTypeId();
	    	
	    	// Map <country, additionalHolidayId>
	    	Map<String, Franchisee_Additional_Holidays__c> holidaysPerCountry = new Map<String, Franchisee_Additional_Holidays__c>();
	    	for( Integer i=0; i < trigger.size; i++ ){
	    		Franchisee_Additional_Holidays__c additionalHoliday = (Franchisee_Additional_Holidays__c) trigger.new[i];
	    		holidaysPerCountry.put(additionalHoliday.Country_Religion__c, additionalHoliday);
	        }
	        
	        if(!holidaysPerCountry.isEmpty()){
	        	
	        	List<Holiday_Vacation__c> holidayVacationList = [SELECT Id, Country__c, Franchisee_Additional_Holiday__c, RecordTypeId, Name, Start_Date__c, End_Date__c, Work_Day__c, Teacher__c, State__c, MF__c, LC__c, CurrencyIsoCode FROM Holiday_Vacation__c WHERE Country__c IN :holidaysPerCountry.keySet()];
	        	
	        	//accumulate all the holidays that already have his duplicated 
	        	//seting keys to easyly check if already have clones later
	        	Integer i = 0;
	        	Set<String> holidaysIgnore = new Set<String>();
	        	while(i<holidayVacationList.size()){
	        		if(holidayVacationList[i].Franchisee_Additional_Holiday__c != null){
	        			String holidaykey = holidayVacationList[i].Country__c;
	        			holidaykey += '_' + holidayVacationList[i].Start_Date__c;
	        			holidaykey += '_' + holidayVacationList[i].End_Date__c;
	        			holidaykey += '_' + holidayVacationList[i].End_Date__c;

	        			if(holidaysPerCountry.get(holidayVacationList[i].Country__c).Account_Type__c == 'MF'){
	        				holidaykey += '_' + mfRecordypeId;
	        			}else if(holidaysPerCountry.get(holidayVacationList[i].Country__c).Account_Type__c == 'LC'){
	        				holidaykey += '_' + lcRecordypeId;
	        			}

        				holidaysIgnore.add(holidaykey);
	        			holidayVacationList.remove(i);
	        		}else{
	        			i++;
	        		}
	        	}

	        	i = 0;
	        	while(i<holidayVacationList.size() && !holidaysIgnore.isEmpty()){
	        		//filtering holidays that already have clones
	        		//record with the same Record Type, same Country/Religion, Same Holiday name and Same Date -> Don't create this record again
	        		String holidaykey = holidayVacationList[i].Country__c;
        			holidaykey += '_' + holidayVacationList[i].Start_Date__c;
        			holidaykey += '_' + holidayVacationList[i].End_Date__c;
        			holidaykey += '_' + holidayVacationList[i].End_Date__c;

        			if(holidaysPerCountry.get(holidayVacationList[i].Country__c).Account_Type__c == 'MF'){
        				holidaykey += '_' + mfRecordypeId;
        			}else if(holidaysPerCountry.get(holidayVacationList[i].Country__c).Account_Type__c == 'LC'){
        				holidaykey += '_' + lcRecordypeId;
        			}

	        		if(holidaysIgnore.contains(holidaykey)){
	        			holidayVacationList.remove(i);
	        		}else{
	        			i++;
	        		}	        		
	        	}
	        	
	        	List<Holiday_Vacation__c> holidayClones = new List<Holiday_Vacation__c>();
	        	for(Holiday_Vacation__c holidayVacation : holidayVacationList){
	        		//creating clones and editing fields
	        		Holiday_Vacation__c holidayVacationCloned = holidayVacation.clone(false,true);
	        		holidayVacationCloned.Franchisee_Additional_Holiday__c = holidaysPerCountry.get(holidayVacationCloned.Country__c).Id;
	        		holidayVacationCloned.RecordTypeId = lcRecordypeId;
	        		holidayVacationCloned.LC__c = holidaysPerCountry.get(holidayVacationCloned.Country__c).Franchisee__c;
	        		if(holidaysPerCountry.get(holidayVacationCloned.Country__c).Account_Type__c == 'MF'){
	        			holidayVacationCloned.RecordTypeId = mfRecordypeId;
	        			holidayVacationCloned.MF__c = holidaysPerCountry.get(holidayVacationCloned.Country__c).Franchisee__c;
	        			holidayVacationCloned.LC__c = null;
	        		}

	        		if(holidaysPerCountry.get(holidayVacationCloned.Country__c).Account_Type__c == 'MF' || holidaysPerCountry.get(holidayVacationCloned.Country__c).Account_Type__c == 'LC'){
	        			holidayVacationCloned.Country__c = null;
	        		}

	        		holidayClones.add(holidayVacationCloned);
	        	}
	        	
	        	if(!holidayClones.isEmpty()){
	        		 Batch_InsertHolidays batch = new Batch_InsertHolidays();
	        		 batch.holidays2Insert = holidayClones;
        			 
        			 HD_Settings_List__c doInsertFromBatch = HD_Settings_List__c.getInstance('InsertHolidayFromBatch');	   		
        			 if(doInsertFromBatch <> null && doInsertFromBatch.Value__c == 'true'){
        			 	Database.executeBatch(batch,50);	
        			 }else{
        			 	insert holidayClones;
        			 }
	        	}
	        	
	        }

	    }
    }

    /******************************************************************************* 
	Name              : deleteHolidayVacation
	Description       : Delete holidays vacations related to additional holidays being deleted
	Revision History  :-
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. G.Fernandez              26/04/2016         	Yaara Nadir 			   SW-19138
	*******************************************************************************/

    public static void deleteHolidayVacation(){
    	if( HD_TriggerSettings.IsTriggerActive('deleteHolidayVacation') ){

	    	Set<Id> deletedAdditionalHolidays = trigger.oldMap.keySet();

	        List<Holiday_Vacation__c> holidayVacationClones = [SELECT Id FROM Holiday_Vacation__c WHERE Franchisee_Additional_Holiday__c IN :deletedAdditionalHolidays];        	
        	if(!holidayVacationClones.isEmpty()){
        		delete holidayVacationClones;
        	}	        	
	    }
    }

}