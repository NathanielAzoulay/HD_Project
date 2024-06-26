/*******************************************************
Name              : RS_Seminar_TriggerHandler
Description       : Seminar Trigger Handler  
Revision History  :-
Created/Modified by   Created/Modified Date                 
-------------------------------------------------------
1. Rashad Saeed        13/11/2017            
********************************************************/   
public  class RS_Seminar_TriggerHandler {
    
    Public Static Void RunSeminarTeacherAux (Map <Id,Seminar__c> NewSeminars,Map <Id,Seminar__c> OldSeminars){
    
        Set <Id> SMIds = new Set <Id>();
        set <Id> SeminarIdsForUpdateSTS = new Set <Id>();
        
        for (Seminar__c Sm : NewSeminars.Values()){
            If (Sm.TT_UID__c <>OldSeminars.get(sm.id).TT_UID__c){
                SMIds.add(Sm.Id);
            }
            if (Sm.Hosting_Franchisee__c <>OldSeminars.get(sm.id).Hosting_Franchisee__c)
            {
                SeminarIdsForUpdateSTS.add(Sm.Id);
            }
        }
        List <Seminar_Teachers__c>STS= [select Id,seminar__r.Hosting_Franchisee__c,seminar__r.TT_UID__c
                                        from Seminar_Teachers__c where
                                        seminar__c in :SeminarIdsForUpdateSTS 
                                        Or seminar__c in:SMIds
                                        ];
        for(Seminar_Teachers__c st :STS){
                    st.HF_ID__c = st.seminar__r.Hosting_Franchisee__c;
                    st.TT_ID__c = st.seminar__r.TT_UID__c;
                    
        }  
        Update STS;
    }
    
}