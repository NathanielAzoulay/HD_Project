public class CaseComment_Manager {
/****************************************************************************************************************************
---------------------------------------------------------------------------------------------------------------------------
Created/Modified by    | Created/Modified Date  |   Requested by      | Related Task/Issue |	Description
---------------------------------------------------------------------------------------------------------------------------
1. Avihai Shindelman   | 12/07/2018 			|	Gidi \ Gili       |	Task-000001922	   |	NewCaseCommentOnResolvedCase created to prevent users to add new comments on resolved case
****************************************************************************************************************************/
    public static map<CaseComment, String> NewCaseCommentOnResolvedCase(List<CaseComment> newCaseComment, String hdc_admin_id, String profileId){
        map<CaseComment, String> CaseComment_map = new map<CaseComment, String>();
        Case c;
        for (CaseComment CC : newCaseComment){ 
        	c = [Select Status From Case Where Id = : CC.ParentId];
            system.debug(' Case == ' + c);
            if (c.Status == 'Resolved' && hdc_admin_id != Label.HDC_Admin_ID){               
                if (profileId != Label.System_Admin_ProfileId || CC.IsPublished == true){
                	//CaseComment_list_err.add(CC);
                    CaseComment_map.put(CC, Label.VR_message_Task_000001922);
                    CC.addError(Label.VR_message_Task_000001922);
                }
            }
        }
        return CaseComment_map;
    }

}