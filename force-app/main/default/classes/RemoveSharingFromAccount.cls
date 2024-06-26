public class RemoveSharingFromAccount{
    string franchiseeId;
    public List<WrapperClass> WrapperClassList{get;set;}
    List<Course_Sub_Type_Sharing__c> CSTSharing2Delete;
    Map<Id, Course_Sub_Type_Sharing__c> existingCSTSharingMap;
    public String sortingExpression {get;set;}
    public String directionOfSort   {get;set;}
    List<Account> contextAccount;
    
    public RemoveSharingFromAccount(){
        franchiseeId= ApexPages.currentPage().getParameters().get('Id');
        
         if(getFields().size() > 0){
            sortingExpression = getFields()[0].fieldPath;
            directionOfSort = 'ASC'; 
        }
        
        if(String.isNotBlank(franchiseeId)){
            
            existingCSTSharingMap= new Map<Id, Course_Sub_Type_Sharing__c>();
            if(franchiseeId.length() > 15){
                franchiseeId = franchiseeId.substring(0, 15);
                
            }
            
            //Get CST of Direct Franchisee
            contextAccount = [Select Id, MF_ID__c, MF_Name__c, Name from Account where Id=: franchiseeId];
            if(contextAccount.size() > 0){
                for(Course_Sub_Type_Sharing__c sharing : [select Id, Account__c, Course_Sub_Type__c from Course_Sub_Type_Sharing__c where Account__c=: franchiseeId]){
                    existingCSTSharingMap.put(sharing.Course_Sub_Type__c, sharing);
                }    
                getRelatedCSTs(franchiseeId, contextAccount[0].MF_Name__c);
            }
        }
    }
    
    public List<Schema.FieldSetMember> getFields(){
        return SObjectType.Course_Sub_Type__c.FieldSets.CST_Field_Set.getFields();
    }
    
    public PageReference sortTableByDirection(){
        getRelatedCSTs(franchiseeId, contextAccount[0].MF_Name__c);
        return null;
    }
    
    public void  getRelatedCSTs(String cstFranchiseeId, String cstFranchiseeMFName){
        string soql= 'SELECT Id,';
        for(Schema.FieldSetMember member : getFields()){
            if(member.fieldPath != 'Id')
                soql += member.fieldPath+',';   
        }
        soql = soql.removeEnd(',');
        soql += ' FROM Course_Sub_Type__c WHERE Active__c = true AND (Franchisee_Name__c = \''+cstFranchiseeId+'\''+' OR Franchisee_Name__r.Name = \''+cstFranchiseeMFName+'\''+')'+' ORDER BY '+sortingExpression+' '+directionOfSort;
        system.debug(soql);
        List<Course_Sub_Type__c> cstList =  Database.query(soql);
        WrapperClassList = new List<WrapperClass>();
        for(Course_Sub_Type__c cst : cstList){
            boolean isExist = existingCSTSharingMap.containsKey(cst.Id);
            WrapperClassList.add(new WrapperClass(isExist, cst , isExist));    
        }
    }
    
    
     
    public PageReference grantOrRemoveSharing(){
        try{
            List<Course_Sub_Type_Sharing__c> CSTSharing2Insert = new List<Course_Sub_Type_Sharing__c>(); 
            List<Course_Sub_Type_Sharing__c> CSTSharing2Delete= new List<Course_Sub_Type_Sharing__c>();
            for(WrapperClass wrapper : WrapperClassList){
                if(wrapper.isChecked == true && wrapper.isInserted == false){
                    Course_Sub_Type_Sharing__c share = new Course_Sub_Type_Sharing__c();
                    share.Account__c = franchiseeId;
                    share.Course_Sub_Type__c =  wrapper.cstRecord.Id;
                    CSTSharing2Insert.add(share);   
                }else if(wrapper.isChecked == false && wrapper.isInserted == true){
                        
                        if(existingCSTSharingMap.containsKey(wrapper.cstRecord.Id)){
                            CSTSharing2Delete.add(existingCSTSharingMap.get(wrapper.cstRecord.Id));    
                        }    
                 }
            } 
            if(CSTSharing2Insert.size() > 0)
                insert CSTSharing2Insert;  
            
            if(CSTSharing2Delete.size() > 0)
                delete CSTSharing2Delete; 
        
            return  new PageReference('/' +franchiseeId); 
        }Catch(Exception ex){ return null;} 
    }
    
    public PageReference returnMethod(){
        return  new PageReference('/' +franchiseeId);    
    }
    
    public class WrapperClass{
        public Boolean isChecked{get;set;}
        public Course_Sub_Type__c cstRecord{get;set;}
        public Boolean isInserted{get;set;}
        
        public WrapperClass(Boolean isChecked, Course_Sub_Type__c cstRecord, Boolean isInserted){
            this.isChecked = isChecked;
            this.cstRecord = cstRecord;  
            this.isInserted = isInserted;
        }  
    }

}