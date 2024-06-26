trigger CourseSubTypeShare_TriggerHandler on Course_Sub_Type_Sharing__c (after insert,after update, before delete) {
    If (trigger.IsAfter&& !trigger.isDelete){
        // Grant Access to  Franchisee Group.
        //AddGroupSharingToParent(String Mapaccsstr,String OldAccsStr ,String ParentPrefix,String AccountLookupName,String ParentLookup,String Reason)
        //RSSHARING.RSHelper.AddGroupSharingToParent(JSON.serialize(trigger.newMap),JSON.serialize(trigger.OldMap),'a10','Account__c' ,'SubFranchisee');
        RSSHARING.RSHelper.AddGroupSharingToParent(JSON.serialize(trigger.newMap),JSON.serialize(trigger.OldMap),'a10','Account__c','Course_Sub_Type__c','SubFranchisee__c');
       
    }
    //Before Delete
    if(Trigger.isBefore && Trigger.isDelete){
            CourseSubTypeShare_TriggerHandler.deleteSubFranchiseeSharings();
        }
    
    
    
}