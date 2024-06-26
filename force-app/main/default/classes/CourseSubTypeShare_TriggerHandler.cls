/************************************************************************************
Name-: CourseSubTypeShare_TriggerHandler
Description-: Handler class for CourseSubTypeShare_TriggerHandler trigger on Course Sub Type.

Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue
========================================================================================
1.Shivram Saini        29-March-2018            Rashad Saeed           Task-000001430
*************************************************************************************/
public class CourseSubTypeShare_TriggerHandler{
    
    /**********************************************************************************
    Name-: deleteSubFranchiseeSharings Method
    Description-: Delete Sharing from Course sub type when related Course sub type 
                  sharing record deleted.
    
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue
    ========================================================================================
    1.Shivram Saini        29-March-2018            Rashad Saeed           Task-000001430
    ***********************************************************************************/   
    public static void deleteSubFranchiseeSharings(){
        Map<Id, Course_Sub_Type_Sharing__c> oldValueMap = new  Map<Id, Course_Sub_Type_Sharing__c>();
        for(Course_Sub_Type_Sharing__c sharing : ((List<Course_Sub_Type_Sharing__c>)trigger.oldMap.values())){
            oldValueMap.put(sharing.Id, ((Course_Sub_Type_Sharing__c)Trigger.oldMap.get(sharing.id).clone(true)));
            if(sharing.Account__c != null){
                oldValueMap.get(sharing.Id).Account__c = null;    
            }
                
        }
        
        RSSHARING.RSHelper.AddGroupSharingToParent(JSON.serialize(oldValueMap),JSON.serialize(trigger.OldMap),'a10','Account__c','Course_Sub_Type__c','SubFranchisee__c');
    }

}