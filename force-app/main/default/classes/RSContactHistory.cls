/**************************************************************
Name              : RSContactHistory.cls
Description       : Handler the before Update  trigger on Contact
                    track teachers status changes 
Created/Modified by   Created/Modified Date                       
-------------------------------------------------------------
1. Rashad Saeed        23/01/2017               
*************************************************************/
public class RSContactHistory{
    public static void Handler(Map<Id,Contact> NewContactList ,Map<Id,Contact> OldContactList ){
       Id recTypeTeacherId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId(); 
       Id recTypeFranchiseeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Franchisee').getRecordTypeId();  
    
        /* disabled changing kangi status by code, only change by PB YossiH 30-1-2022
      for(id conId:NewContactList.keyset()){
          if((OldContactList.get(conId).Status__c=='Not Active' 
              && NewContactList.get(conId).Status__c=='Active') 
              && (NewContactList.get(conId).recordtypeid==recTypeTeacherId 
              || NewContactList.get(conId).recordtypeid==recTypeFranchiseeId )){
                               
             // NewContactList.get(conId).Kangi_Status__c='Active';
             
           } 
      }*/
       
       List <Contact_History__c> CHI = new List <Contact_History__c>();
       for (Id ConId : NewContactList.keySet())
       {

           if (NewContactList.get(ConId).Status__c<>OldContactList.get(ConId).Status__c && 
               (NewContactList.get(ConId).RecordTypeId == recTypeTeacherId || NewContactList.get(ConId).RecordTypeId == recTypeFranchiseeId ))
           {
               Contact_History__c temp = new Contact_History__c();
               temp.New_Status__c = NewContactList.get(ConId).Status__c;
               temp.Old_Status__c = OldContactList.get(ConId).Status__c;
               temp.Contact__c = ConId;
               temp.Status_Date_Change__c = System.today();
               CHI.add (temp);
           }
       }
        insert CHI;
    }
}