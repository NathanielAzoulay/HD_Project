public with sharing class CaseComment_Handler {
    //public static void CaseComment_Manager(list<CaseComment> newCaseCommentList, list<CaseComment> oldCaseCommentList, map<Id,CaseComment> newMap, map<Id, CaseComment> oldMap,boolean isBefore, boolean isInsert){                                          
    public String hdc_admin_id;
    public String profileId; 
    public List<HD_Log__c> errorLogs = new List<HD_Log__c>();
    //private boolean m_isExecuting = false;
    //private integer BatchSize = 0;
    
    public CaseComment_Handler(){//String hdc_admin_id, String profileId
        this.hdc_admin_id = UserInfo.getUserId();
		this.profileId = UserInfo.getProfileId();
        //BatchSize = size;
    }            

    public void OnBeforeInsert(List<CaseComment> newCaseComment_list){
        //system.debug('CaseComment Trigger On Before Insert');
        //list<CaseComment> CaseComment_list = new list<CaseComment>();
        try{
        	CaseComment_Manager.NewCaseCommentOnResolvedCase(newCaseComment_list, hdc_admin_id, profileId);
        }
        catch(Exception ex){
            errorLogs.add(new HD_Log__c(Process_Name__c = 'Before Insert New Comment on Resolved Case', Error_Description__c = ex.getMessage(), Status__c = 'Fail'));
        }
        //for (CaseComment CC : CaseComment_map)
        //	CC.addError(CaseComment_map.get(CC));
        
    }
  /*  public void OnAfterUpdate( List<CaseComment> newCaseComment, List<CaseComment> oldCaseComment_list, Map<ID, CaseComment> newCaseCommentMap , Map<ID, CaseComment> oldCaseCommentMap )
    {
        system.debug('CaseComment Trigger On After Update ');
       
    }
    public void OnBeforeUpdate( List<CaseComment> newCaseComment, List<CaseComment> oldCaseComment_list, Map<ID, CaseComment> newCaseCommentMap , Map<ID, CaseComment> oldCaseCommentMap )
    {
        system.debug('CaseComment Trigger On Before Update ');
    }*/
      
}