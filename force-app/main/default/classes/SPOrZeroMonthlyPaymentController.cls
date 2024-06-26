public with sharing class SPOrZeroMonthlyPaymentController {
    
    public string                      selectedIds       {get;set;}
    public LG_Discount__c              lgSpecialFields   {get;set;}
    public LG__c                       lgFields          {get;set;}
    public String                      queryStringByFs   {get;set;}
    public List<LgSpecialPriceWrapper> lstLgSpecialPrice {get;set;}
    public String                      sortingExpression  {get;set;}
    public String                      directionOfSort    {get;set;}
    public boolean                     isError            {get;set;}
    public String                      lstLgSpStr         {get;set;}
    public String                      createdByName      { get; set; }
    public String                      cById        { get; set; }
    
    public SPOrZeroMonthlyPaymentController(ApexPages.StandardController controller) {
        selectedIds           = ApexPages.currentPage().getParameters().get('selectedIds');
        isError               = false;
        lstLgSpStr            = '';
        lgSpecialFields       = new LG_Discount__c();
        lgFields              = new LG__c();
        sortingExpression     = 'CreatedDate';
        directionOfSort       = 'DESC';
        queryStringByFs       = makeQueryString('LG_Discount__c','SPOrZeroMonthlyPayment',selectedIds);
        String queryStrOnload = queryStringByFs+' ORDER BY '+sortingExpression+' '+directionOfSort;
        List<LgSpecialPriceWrapper> lstBeforePageLoad = getSObjectList(queryStrOnload);
        lstLgSpecialPrice  =  copyRequestedFieldsToApprovedFields(lstBeforePageLoad);
    }
    
    
    
    public  List<LgSpecialPriceWrapper> copyRequestedFieldsToApprovedFields(List<LgSpecialPriceWrapper> lstBeforePageLoad){
        List<LgSpecialPriceWrapper> lstAfterUpdate = new List<LgSpecialPriceWrapper>();
        for(LgSpecialPriceWrapper df : lstBeforePageLoad){
            if(df.lgSpecialPrice.Requested_Course_Price__c != null){
                df.lgSpecialPrice.Approved_Course_Price__c = null;
            }
            if(df.lgSpecialPrice.Requested_Price_per_Month__c != null){
                df.lgSpecialPrice.Approved_Price_per_Month__c = null;
            }
            if(df.lgSpecialPrice.Requested_Price_per_Session__c != null){
                df.lgSpecialPrice.Approved_Price_per_Session__c = null;
            } 
            lstAfterUpdate.add(df);
        }
        
        return lstAfterUpdate;
    }
    
    /*
    ---------------------------------
        Modified By -: Shivram Saini
        Date -: 8 Feb 2018
    ---------------------------------
    */
    
    public PageReference approveOrRejectLgsps(String reqStatus) {
        try
        {
            boolean noError = true;
            
            List<LG_Discount__c> lgSps  = new List<LG_Discount__c >();
            for(LgSpecialPriceWrapper lgSpJs : lstLgSpecialPrice){
                
                if(lgSpJs.isChecked){
                    if(lgSpJs.lgSpecialPrice.Approved_Course_Price__c == null && lgSpJs.lgSpecialPrice.Requested_Course_Price__c != null)
                        lgSpJs.lgSpecialPrice.Approved_Course_Price__c = lgSpJs.lgSpecialPrice.Requested_Course_Price__c;
                    if(lgSpJs.lgSpecialPrice.Approved_Price_per_Month__c == null && lgSpJs.lgSpecialPrice.Requested_Price_per_Month__c != null)
                        lgSpJs.lgSpecialPrice.Approved_Price_per_Month__c = lgSpJs.lgSpecialPrice.Requested_Price_per_Month__c;
                    if(lgSpJs.lgSpecialPrice.Approved_Price_per_Session__c == null && lgSpJs.lgSpecialPrice.Requested_Price_per_Session__c != null)
                        lgSpJs.lgSpecialPrice.Approved_Price_per_Session__c = lgSpJs.lgSpecialPrice.Requested_Price_per_Session__c;
                    
                    if(reqStatus == 'Rejected'){
                        lgSpJs.lgSpecialPrice.Approved_Course_Price__c = null;
                        lgSpJs.lgSpecialPrice.Approved_Price_per_Month__c = null;
                        lgSpJs.lgSpecialPrice.Approved_Price_per_Session__c = null;
                    }
                    lgSpJs.lgSpecialPrice.Discount_Status__c = reqStatus;
                    lgSps.add(lgSpJs.lgSpecialPrice);
                }
            }
            system.debug('____check1');
            bypassValidations(); 
                     
            List<Database.SaveResult> updateResults = Database.update(lgSps, false);
            for(Integer i=0;i<updateResults.size();i++){
                if (!updateResults.get(i).isSuccess()){
                    Database.Error error = updateResults.get(i).getErrors().get(0);
                    String failedDML = error.getMessage();
                    system.debug('Failed ID______'+lgSps.get(i).Id+' '+failedDML);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,lgSps.get(i).Name+' '+ failedDML));
                    isError = true;
                    noError = false;
                }
            }
            if(noError){
                activateValidations();
                String queryStrOnSaveLg = queryStringByFs+' ORDER BY '+sortingExpression+' '+directionOfSort;
                List<LgSpecialPriceWrapper> lstLgSpWs = getSObjectList(queryStrOnSaveLg);
                if(lstLgSpWs.size()>0)
                    lstLgSpecialPrice = copyRequestedFieldsToApprovedFields(lstLgSpWs);
                else
                    lstLgSpecialPrice = new List<LgSpecialPriceWrapper>();
                isError = false;
            }
            return null;
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,+e.getMessage()));
            System.debug('Error___________'+e.getMessage()+'---'+e.getLineNumber()+'---'+e.getTypeName()+'---'+e.getStackTraceString());
            isError = true; 
            return null;
        }
        
    }
    
    public PageReference approveLgsPrice(){
        approveOrRejectLgsps('Approved');
        return null;
    }
    
    public PageReference rejectLgsPrice(){
        approveOrRejectLgsps('Rejected');
        return null;
    }
    
    
    
    public List<Schema.FieldSetMember> getFields() {
        return SObjectType.LG_Discount__c.FieldSets.SPOrZeroMonthlyPayment.getFields();
    }
    
    public PageReference sortTableByDirection(){
        String queryStrOnSort = queryStringByFs+' ORDER BY '+sortingExpression+' '+directionOfSort;
        List<LgSpecialPriceWrapper> lstBeforePageLoad = getSObjectList(queryStrOnSort);
        lstLgSpecialPrice                             = copyRequestedFieldsToApprovedFields(lstBeforePageLoad);
        return null;
    }
    
    public PageReference exitToPrevious(){
        String returnURL = ApexPages.currentPage().getParameters().get('retURL');
        //System.assert(false,returnURL);
        return new PageReference(returnURL);
    }
    
    public PageReference searchLGSpecialPrice(){
        try{
            //System.assert(false,'Hello');
            String queryStr       = queryStringByFs;
            String criteriaStr    = '';
            String zeroMonthlyStr = 'Zero Monthly Payment';
            System.debug('lgSpecialFields::::::------'+lgSpecialFields);
            
            if(lgSpecialFields.Record_Type__c != '' && lgSpecialFields.Record_Type__c != null && lgSpecialFields.Record_Type__c == 'Special Price')
                criteriaStr += ' AND Discount_Reason__c != \''+zeroMonthlyStr+'\' ';
            else if(lgSpecialFields.Record_Type__c != '' && lgSpecialFields.Record_Type__c != null && lgSpecialFields.Record_Type__c == 'Zero Monthly Payment')
                criteriaStr += ' AND Discount_Reason__c = \''+lgSpecialFields.Record_Type__c+'\' ';
            
            //system.assert(false,lgFields.Franchisee__c);
            if(cById != '' && cById != null)
                criteriaStr += ' AND CreatedById =\''+cById+'\'';
            //criteriaStr += ' AND LG__r.Franchisee__c =\''+lgFields.Franchisee__c+'\'';
            
            if(lgSpecialFields.Discount_Type__c != '' && lgSpecialFields.Discount_Type__c != null)
                criteriaStr += ' AND Discount_Type__c =\''+lgSpecialFields.Discount_Type__c+'\'';
            
            
            queryStr = queryStr + criteriaStr +' ORDER BY '+sortingExpression+' '+directionOfSort;
            if(String.isNotBlank(criteriaStr)){
                List<LgSpecialPriceWrapper> lstSearched = getSObjectList(queryStr);
                if(lstSearched.size()>0){
                    lstLgSpecialPrice = copyRequestedFieldsToApprovedFields(lstSearched);
                }
                else{
                    lstLgSpecialPrice = new List<LgSpecialPriceWrapper>();
                }
            }
            return null;
        }
        catch(Exception e){ return null; }
    }
    
    public PageReference resetLGSpecialPrice(){
        try{
            lgSpecialFields = new LG_Discount__c();
            lgFields        = new LG__c();
            createdByName   = '';
            cById           = '';
            String queryStrOnReset = queryStringByFs+' ORDER BY '+sortingExpression+' '+directionOfSort;
            List<LgSpecialPriceWrapper> lstBeforePageLoad = getSObjectList(queryStrOnReset); 
            lstLgSpecialPrice = copyRequestedFieldsToApprovedFields(lstBeforePageLoad);
            return null;
        }
        catch(Exception e){ return null; }
    }
    
    
    
    public static String makeQueryString(String SObj, String fieldSetName, String selectedLgSpIds) {
        try{
            List<String> sids = selectedLgSpIds.split(',');
            Map<String, SObjectField> selectedObjectFieldMap = new Map<String, SObjectField>();
            String str = '';
            for(String st:sids){
                str += '\''+st+'\',';
            }
            str = str.removeEnd(',');
            String criteriaStr = 'Requested';
            String queryStr = 'SELECT Id,';
            if(SObj != null && fieldSetName != null){
               
                for(FieldSetMember fsm : Utility1.getFieldSet(SObj, fieldSetName)){
                    if(fsm.fieldPath != 'Id')
                          queryStr += +fsm.fieldPath+',';
                }
             /*   
                selectedObjectFieldMap= Schema.getGlobalDescribe().get('LG_Discount__c').getDescribe().fields.getMap();
                 for(Schema.SObjectField fieldAPI : selectedObjectFieldMap.values()){
                     if(fieldAPI.getDescribe().isAccessible() && fieldAPI.getDescribe().getName() != 'Id'){
                         queryStr += ','+fieldAPI.getDescribe().getName();        
                     }
                 }
              */
                if(!queryStr.contains(',Name,'))
                       queryStr += 'Name,';
                if(!queryStr.contains(',Discount_Reason__c,'))
                       queryStr += 'Discount_Reason__c,';
                if(!queryStr.contains(',Requested_Course_Price__c,'))
                       queryStr += 'Requested_Course_Price__c,';
                if(!queryStr.contains(',Requested_Price_per_Month__c,'))
                       queryStr += 'Requested_Price_per_Month__c,';
                if(!queryStr.contains(',Requested_Price_per_Session__c,'))
                       queryStr += 'Requested_Price_per_Session__c,';
                if(!queryStr.contains(',Approved_Course_Price__c,'))
                       queryStr += 'Approved_Course_Price__c,';
                if(!queryStr.contains(',Approved_Price_per_Month__c,'))
                       queryStr += 'Approved_Price_per_Month__c,';
                if(!queryStr.contains(',Approved_Price_per_Session__c,'))
                       queryStr += 'Approved_Price_per_Session__c,';
                if(!queryStr.contains(',Month__c,'))
                       queryStr += 'Month__c,';
                if(!queryStr.contains(',Year__c,'))
                       queryStr += 'Year__c,';
                if(!queryStr.contains(',Discount_Type__c,'))
                       queryStr += 'Discount_Type__c,';
                if(!queryStr.contains(',Record_Type__c,'))
                       queryStr += 'Record_Type__c,';
                if(!queryStr.contains(',LG_Student__r.Name,'))
                       queryStr += 'LG_Student__r.Name,';
                if(!queryStr.contains(',Student__r.Name,'))
                       queryStr += 'Student__r.Name,';
                               
                queryStr = queryStr.removeEnd(',');
                
                queryStr += ' FROM '+SObj+' WHERE Id IN ('+str+') AND Discount_Status__c =\''+criteriaStr+'\'';
            }
            return queryStr;
        }
        catch(Exception e){ return null; }
    }
    
    public static List<LgSpecialPriceWrapper> getSObjectList(String queryStr){
        try{
            List<LG_Discount__c> lstSp = new List<LG_Discount__c>();
            if(String.isNotBlank(queryStr))
                lstSp = Database.query(queryStr);
            
            List<LgSpecialPriceWrapper> lstLgSpW = new List<LgSpecialPriceWrapper>();
            if(lstSp.size()>0){
                for(Integer i=0;i<lstSp.size();i++){
                    LgSpecialPriceWrapper lgSpW = new LgSpecialPriceWrapper();
                    lgSpW.count = i;
                    lgSpW.isChecked = false;
                    lgSpW.lgSpecialPrice = lstSp[i];
                    lstLgSpW.add(lgSpW);
                }
            }
            
            return lstLgSpW;
        }
        catch(Exception e){ return null; }
    }
    
    
    /* To bypass validation rules set current user's Bypass Automation field to true */
    public PageReference bypassValidations(){
        List<User> userFieldUpdate = new List<User>();
        
        for(User u : [Select Id, Bypass_Automation__c From User Where Id =: UserInfo.getUserId()]){
            u.Bypass_Automation__c = true;
            userFieldUpdate.add(u);
        }
        
        if(!userFieldUpdate.isEmpty()){
            update userFieldUpdate;
        }
        
        return null;
    }
    
    
    
    /* To reset validation rules set current user's Bypass Automation field to false */
    public PageReference activateValidations(){
        List<User> userFieldUpdate = new List<User>();
        
        for(User u : [Select Id, Bypass_Automation__c From User Where Id =: UserInfo.getUserId()]){
            u.Bypass_Automation__c = false;
            userFieldUpdate.add(u);
        }
        
        if(!userFieldUpdate.isEmpty()){
            update userFieldUpdate;
        }
        
        return null;
    }
    
    public class LgSpecialPriceWrapper{
        public integer count{get;set;}
        public boolean isChecked{get;set;}
        public LG_Discount__c lgSpecialPrice{get;set;}
    }
    
    
}