/*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name:            RS_VFC_CourseSubTypesShringReport.cls
Description:    dispaly all the sharing records on the Active course sub type
Date             Author          Summary of Changes 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
19-07-2017     Rashad Saeed  Initial Implementation 
25-07-2017     Rashad Saeed  Add account Name and Email to the reoprt exported to excel 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
public with sharing class RS_VFC_CourseSubTypesShringReport {
    Public Map  <Course_Sub_Type__c, List <user>> viewMap {set;get;}
    
    Public RS_VFC_CourseSubTypesShringReport (){
        
        List<Course_Sub_Type__c> CourseSubType = new List <Course_Sub_Type__c>();
        Map <Id,Course_Sub_Type__c> CourseSubTypeMap = new Map <Id,Course_Sub_Type__c>([select Id , Name from Course_Sub_Type__c where Active__c = true and
                                                                                       MF_ID__c =: ApexPages.currentPage().getParameters().get('PartnerUserId')]);
        Map <Id,Course_Sub_Type__Share> CourseSubTypeShare = new Map <Id,Course_Sub_Type__Share>([select Id,UserOrGroupId,ParentID from Course_Sub_Type__Share
                                                                                                  where ParentID in:CourseSubTypeMap.keySet()]);
        Map <Id,user> UserMap = new Map <Id,user> ([select Id ,Name,Email,Contact.Account.Name from user ]) ;
        //UserInfo.getUserId();
        //ApexPages.currentPage().getParameters().get('Id');
        
        viewMap = new Map <Course_Sub_Type__c, List <User>>();
        
        for (Course_Sub_Type__Share Cshare : CourseSubTypeShare.Values()){
            System.debug(UserMap.get(Cshare.UserOrGroupId).name); 
            System.debug(CourseSubTypeMap.get(Cshare.ParentID).name); 
            if (!viewMap.containsKey(CourseSubTypeMap.get(Cshare.ParentID)))
            {
                //String rUserName = UserMap.get(Cshare.UserOrGroupId).name;
                viewMap.put(CourseSubTypeMap.get(Cshare.ParentID), new List<user>{UserMap.get(Cshare.UserOrGroupId)});
            }
            else
                viewMap.get(CourseSubTypeMap.get(Cshare.ParentID)).add(UserMap.get(Cshare.UserOrGroupId));
        }
      
    }
     public PageReference exportToExcel() {
       PageReference pg =Page.RS_CourseSubTypesShringReportexport;
       pg.getParameters().put('PartnerUserId', ApexPages.currentPage().getParameters().get('PartnerUserId'));
       return pg;
   }
    
    
    
}