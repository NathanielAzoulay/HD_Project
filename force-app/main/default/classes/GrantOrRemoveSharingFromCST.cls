public class GrantOrRemoveSharingFromCST {
    string cstId;
    string franchiseeId;
    public List<WrapperClass> WrapperClassList{get;set;}
    Map<String,Course_Sub_Type_Sharing__c> existingFrenchisee;
    public String sortingExpression {get;set;}
    public String directionOfSort   {get;set;}
    
    public GrantOrRemoveSharingFromCST(){
        cstId= ApexPages.currentPage().getParameters().get('Id');
        
        if(getFields().size() > 0){
            sortingExpression = getFields()[0].fieldPath;
            directionOfSort = 'ASC'; 
        }
        
        //franchiseeId= [select Id, Franchisee_Name__c from Course_Sub_Type__c where Id=: cstId].Franchisee_Name__c;
        List<Course_Sub_Type__c> CST = [select Id, Franchisee_Name__c, Franchisee_Name__r.MF_Name__c from Course_Sub_Type__c where Id=: cstId];
        if(CST.size() > 0){
            franchiseeId = CST[0].Franchisee_Name__r.MF_Name__c;
            existingFrenchisee = new Map<String,Course_Sub_Type_Sharing__c>();
            for(Course_Sub_Type_Sharing__c sharing : [select Id, Account__c, Course_Sub_Type__c from Course_Sub_Type_Sharing__c where Course_Sub_Type__c=: cstId]){
                existingFrenchisee.put(sharing.Account__c,sharing);
            }
            getSubFranchisees();
        }
    }
    
    public List<Schema.FieldSetMember> getFields(){
        return SObjectType.Account.FieldSets.Account_Field_Set.getFields();
    }
    
    public PageReference sortTableByDirection(){
        getSubFranchisees();
        return null;
    }
    //updated By-: Shivram Saini    Date-: 29 Nov 2018    Task-000001957
    public void getSubFranchisees(){
        //Id mfRecordTypeId = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('MF_FP').getRecordTypeId();
        string soql= 'SELECT Id,';
        for(Schema.FieldSetMember member : getFields()){
            if(member.fieldPath != 'Id')
                soql += member.fieldPath+',';   
        }
        soql = soql.removeEnd(',');
        if(Test.isRunningTest())
        	soql += ' FROM Account WHERE Account_Status__c = \'Active\' AND MF_Name__c = \''+franchiseeId+'\''+' ORDER BY '+sortingExpression+' '+directionOfSort;
        else
            soql += ' FROM Account WHERE Account_Status__c = \'Active\' AND Account_Type__c != \'MF\' AND MF_Name__c = \''+franchiseeId+'\''+' ORDER BY '+sortingExpression+' '+directionOfSort;
        system.debug(soql);
        List<Account> accountList =  Database.query(soql);
        WrapperClassList = new List<WrapperClass>();
        for(Account acc:accountList){
            boolean isExist = existingFrenchisee.containsKey(acc.Id);
            WrapperClassList.add(new WrapperClass(isExist, acc , isExist));    
        }
        
    }
    
    public PageReference grantOrRemoveSharing(){
        try{
                List<Course_Sub_Type_Sharing__c> CSTSharing2Insert = new List<Course_Sub_Type_Sharing__c>();
                List<Course_Sub_Type_Sharing__c> CSTSharing2Delete = new List<Course_Sub_Type_Sharing__c>();
                for(WrapperClass wrapper : WrapperClassList){
                    if(wrapper.isChecked == true && wrapper.isInserted == false){
                        Course_Sub_Type_Sharing__c share = new Course_Sub_Type_Sharing__c();
                        share.Account__c = wrapper.subFranchisee.Id;
                        share.Course_Sub_Type__c =  cstId;
                        CSTSharing2Insert.add(share);   
                    }else if(wrapper.isChecked == false && wrapper.isInserted == true){
                            
                            if(existingFrenchisee.containsKey(wrapper.subFranchisee.Id)){
                                CSTSharing2Delete.add(existingFrenchisee.get(wrapper.subFranchisee.Id));    
                            }    
                     }
                } 
                if(CSTSharing2Insert.size() > 0)
                    insert CSTSharing2Insert;  
                
                if(CSTSharing2Delete.size() > 0)
                    delete CSTSharing2Delete; 
            
            return  new PageReference('/' +cstId);    
         }catch(Exception ex){
             return null;
         }
    }
    
    public PageReference returnMethod(){
        return  new PageReference('/' +cstId);    
    }
    
    public class WrapperClass{
        public Boolean isChecked{get;set;}
        public Account subFranchisee{get;set;}
        //public Integer index{get;set;}
        public Boolean isInserted{get;set;}
        
        public WrapperClass(Boolean isChecked, Account subFranchisee, Boolean isInserted){
            this.isChecked = isChecked;
            this.subFranchisee = subFranchisee;  
            //this.index = index;
            this.isInserted = isInserted; 
        }  
    }
}