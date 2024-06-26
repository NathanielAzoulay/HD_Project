/*******************************************************
Name              : RS_SeminarTeachers_TriggerHandler
Description       : Seminar_Teachers__c Trigger Handler 
Revision History  :-
Created/Modified by   Created/Modified Date                 
-------------------------------------------------------
1. Rashad Saeed        10/12/2017       
********************************************************/	
public class RS_SeminarTeachers_TriggerHandler {
    Public Static Void SeminarTeacherAux(List <Seminar_Teachers__c> Sts ){
    	 set <Id> SeminarIds = new Set <Id>();
		 set <Id> TeachersIds = new Set <Id>();
		for (Seminar_Teachers__c st : Sts)
		{
			SeminarIds.add (st.Seminar__c);
			TeachersIds.add(St.Teacher__c);
		}
		Map <Id,Seminar__c> SMS = new Map <Id,Seminar__c> ([select Id,Hosting_Franchisee__c,TT_UID__c
															from Seminar__c where Id in:SeminarIds ]);	
		Map <Id,Contact> ConMap = new Map <Id,Contact> ([select Id,AccountId,Contact_Partner_User__c
															from Contact where Id in:TeachersIds ]);														
		for (Seminar_Teachers__c St : Sts)
			{
				if (SMS.get(st.seminar__c)<>null)
				{
					st.HF_ID__c = SMS.get(st.seminar__c).Hosting_Franchisee__c;
					st.TT_ID__c = SMS.get(st.seminar__c).TT_UID__c;
					st.TeacherUserID__c = ConMap.get(st.Teacher__c).Contact_Partner_User__c;
					st.Teacher_Franchisee_ID__c = ConMap.get(st.Teacher__c).AccountId;
				}
			}	
    }
}