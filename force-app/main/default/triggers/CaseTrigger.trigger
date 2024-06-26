/**************************************************************
Name              : CaseTrigger 
Description       : Trigger On case for service  
Created/Modified by   Created/Modified Date                       
-------------------------------------------------------------
1. Rashad Saeed        18/1/2017                 
*************************************************************/
trigger CaseTrigger on Case (before Update , After Update ) {
    list<CaseShare> csh = new list<CaseShare>();
    /******************* before Update    ************************/
    if (Trigger.isBefore && Trigger.isUpdate) {// before Update 
          for(Case C :Trigger.new){
            if (Trigger.oldMap.get(c.Id).Agent_Status__c != C.Agent_Status__c)
               C.Status = C.Agent_Status__c;
               
          }
   }
    /******************* After Update    ************************/
    
    else  if (Trigger.isAfter && Trigger.isUpdate) { // After Update
          for( Case rCase : (List<Case>) trigger.new )
          {
            if (rCase.CreatedById <>  rCase.OwnerId && rCase.IsCreatorActive__c== true )
                {
                    CaseShare ShareTemp = new CaseShare();
                    ShareTemp.CaseAccessLevel = 'Edit';
                    ShareTemp.CaseId = rCase.id;  
                    ShareTemp.UserOrGroupId = rCase.CreatedById;
                    csh.add(ShareTemp);
                   /* if (rCase.UserContactId__c<>null){
                        CaseShare ShareTemp2 = new CaseShare();
                        ShareTemp2.CaseAccessLevel = 'Edit';
                        ShareTemp2.CaseId = rCase.id;  
                        ShareTemp2.UserOrGroupId = rCase.UserContactId__c;
                        csh.add(ShareTemp);
                        }*/
              }
          }
       insert csh; 
    }
    //insert csh;
}