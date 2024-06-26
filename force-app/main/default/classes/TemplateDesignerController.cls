public with sharing class TemplateDesignerController{
   
    public Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    public String selectedObject {get; set;}
    public String baseObject {get; set;}
    public String RelatedObject {get; set;} 
    
    public string refselectedField {get;set;}
    public String selectedField {get; set;}
    public String selectedField2 {get; set;}
    public String htmlValue {get; set;}
    
    public String body {get;set;}
    public Email_Template__c emailTemp{get; set;}
    public boolean isConditional{get;set;}
    public String leftselected{get;set;}
    
    public String rightselected{get;set;}
    public Set<String> leftvalues{get;set;}
    public List<string> rightvalues{get;set;}
    public Set<string> rightvaluesSet{get;set;}
    public String selected{get;set;}
    
    public map<string,string> fieldsMap;
    public List<SelectOption> ObjectNames{get;set;}
    public List<SelectOption> ObjectFields{get;set;}
    public map<string,string> referenceFieldMap{get;set;}
    public List<SelectOption> refObjectFields{get;set;}
    public String conditionChoice{get;set;}
    public string fieldLimitAlert{get;set;}
    
    /** Number of field, an user can select for related list **/
    public static Integer numberOfAllowedFields = 10;
    
    public TemplateDesignerController(ApexPages.StandardController controller) {
        selectedObject = '' ;
        baseObject = '';
        RelatedObject = '';
        refselectedField = '';
        
        emailTemp= new Email_Template__c();
        ObjectNames = new List<SelectOption>();
        ObjectFields = new List<SelectOption>();
        refObjectFields = new List<SelectOption>();
        fieldsMap = new Map<String,String>();
        
        referenceFieldMap =  new map<string,string>();
        emailTemp= [select Id, name, Body__c, Html_Value__c,Related_To_Base_Object__c from Email_Template__c where Id = :controller.getId()];
        body = '' ;
        baseObject = selectedObject = emailTemp.Related_To_Base_Object__c;
        System.debug('baseObject :::'+baseObject);
        isConditional = false;
        
        leftselected = '';
        rightselected = '';
        leftvalues = new Set<String>();
        rightvalues = new List<string>();
        
        rightvaluesSet = new Set<string>();
        selected = '';
        conditionChoice = 'true';
        fieldLimitAlert = '';
        fetchsobjects();
    }
    
    public void fetchsobjects() {
        try{
            mergeField = '' ;
            ObjectNames = new List<SelectOption>();
            
            for(String SObjName : schemaMap.keySet()){
                Schema.DescribeSObjectResult SR = schemaMap.get(SObjName).getDescribe();
                if(baseObject != '' && SR.getName() == baseObject && SR.isUpdateable() && SR.getKeyPrefix()!=null && !SR.isCustomSetting() && SR.isCreateable()){
                    ObjectNames.add(new SelectOption(SR.getName(),SR.getLabel()));
                }
                else if(baseObject == '' && SR.isUpdateable() && SR.getKeyPrefix()!=null && !SR.isCustomSetting() && SR.isCreateable()){
                    ObjectNames.add(new SelectOption(SR.getName(),SR.getLabel()));
                }
                
            }
            if(baseObject != '' && baseObject == 'LG__c')
                    ObjectNames.add(new SelectOption('LG_Student__c', 'LG Student'));
                    
                    
            ObjectNames.sort();
            
            if(!isConditional){
                ObjectNames.add(new SelectOption('$Organization','$Organization'));
                ObjectNames.add(new SelectOption('$User','$User'));
                ObjectNames.add(new SelectOption('$System','$System'));
            }
            //return objNames;
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,e.getMessage()));
        }
        //return null;
    }
    public void fetchsobjectFields() {
        
        try{
           
            String selectedObj = selectedObject;
            
            if(selectedObj != null && selectedObj != '' && selectedObj != '$System') {
                mergeField  = '' ;
                if(selectedObj.startsWith('$')){
                    selectedObj = selectedObj.replace('$','');
                }
                System.debug('selectedObj  :: '+selectedObj);
                Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
                Schema.SObjectType ObjectSchema = schemaMap.get(selectedObj);
                Map<String, Schema.SObjectField> fieldMap = ObjectSchema.getDescribe().fields.getMap();
                
                ObjectFields = new List<SelectOption>();
                referenceFieldMap =  new map<string,string>();
                
                if(fieldMap != null && fieldMap.size() > 0){
                    for (schema.SObjectField fieldName: fieldMap.values()) {  
                        Schema.DescribeFieldResult dfr = fieldName.getDescribe();
                        if(isConditional){
                            if (string.valueOf(dfr.getType()) == 'BOOLEAN') {
                                ObjectFields.add(new SelectOption(dfr.getName(), dfr.getLabel()));//It provides to get the object fields label.
                            }
                        }
                        else{
                            ObjectFields.add(new SelectOption(dfr.getName(), dfr.getLabel()));//It provides to get the object fields label.
                            if (string.valueOf(dfr.getType()) == 'REFERENCE') {
                                //system.debug(dfr.getRelationshipName()+' ==== Ref Fields ===== '+dfr.getLabel());
                                if(dfr.getRelationshipName() != null && dfr.getLabel() != null){
                                    ObjectFields.add(new SelectOption(dfr.getRelationshipName(), dfr.getLabel()+' >'));
                                    referenceFieldMap.put(dfr.getRelationshipName(),string.valueOf(dfr.getReferenceTo()[0].getDescribe().getName()));
                                }
                            }
                        }
                    }
                }
                ObjectFields = Utility.getSortedList(ObjectFields);
            }
            else{
                ObjectFields = new List<SelectOption>();
                ObjectFields.add(new SelectOption('Today', 'Today'));
                ObjectFields.add(new SelectOption('Now', 'Now'));
                ObjectFields.add(new SelectOption('Month', 'Month'));
                ObjectFields.add(new SelectOption('Day', 'Day'));
                ObjectFields.add(new SelectOption('Year', 'Year'));
                ObjectFields = Utility.getSortedList(ObjectFields);
            }
        }
        catch(Exception e){
            //system.debug(' ====== '+e.getlineNumber()+' ======= '+e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,e.getMessage()));
        }
    }
    
    public String mergeField {get;set;}
    public String mergeField2 {get;set;}
    
    public void createMergeField(){
        try{
            System.debug('reff:: '+referenceFieldMap);
            System.debug('selObj:: '+selectedObject);
            System.debug('selfield:: '+selectedField);
            mergeField = '' ;
            if(selectedObject != null && selectedField != null && selectedField != '' && selectedField != '--Select--'){
                if(refselectedField == '' && referenceFieldMap != null && referenceFieldMap.containsKey(selectedField) && referenceFieldMap.get(selectedField) != ''){
                    mergeField  = '' ;
                    Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
                    Schema.SObjectType ObjectSchema = schemaMap.get(referenceFieldMap.get(selectedField).toLowerCase());
                    Map<String, Schema.SObjectField> fieldMap = ObjectSchema.getDescribe().fields.getMap();
                    refObjectFields = new List<SelectOption>();
                    if(fieldMap != null && fieldMap.size() > 0){
                        for (schema.SObjectField fieldName: fieldMap.values()) {  
                            Schema.DescribeFieldResult dfr = fieldName.getDescribe();
                            refObjectFields.add(new SelectOption(dfr.getName(), dfr.getLabel()));//It provides to get the object fields label.
                        }
                    }
                    
                    refObjectFields = Utility.getSortedList(refObjectFields);
                    
                    system.debug('refObjectFields------'+refObjectFields);
                }
                else{
                    if(refselectedField != '')
                        mergeField = '{!'+selectedObject +'.'+selectedField+'.'+refselectedField+'}';
                    else{
                        mergeField = '{!'+selectedObject +'.'+selectedField+'}';
                        refObjectFields = new List<SelectOption>();
                    }
                    
                    if(selectedObject.startsWith('$')){
                        mergeField = mergeField;
                    }
                }
                system.debug('mergeField------'+mergeField);
            }
            system.debug('------no field selected');
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,e.getLineNumber()+' : '+e.getMessage()));
        }
    }
    
    public PageReference createTemplateRecord(){
        try{
            if(baseObject != null && (emailTemp.Body__c != null)){
            if(htmlValue != null){
            if(emailTemp!= null){
                    //Email_Template__c emailTemp= new  Email_Template__c();
                    emailTemp.Related_To_Base_Object__c = baseObject;
                    emailTemp.Body__c = emailTemp.Body__c ; // Body ;
                    emailTemp.Html_Value__c = htmlValue;
                    System.debug('HTML Value:::::'+htmlValue);
                    System.debug('HTML Value in Api:::::'+emailTemp.Html_Value__c);
                }
                else{
                    emailTemp.Body__c = emailTemp.Body__c ;
                    emailTemp.Html_Value__c = htmlValue;
                    System.debug('HTML Value in Api in else:::::'+emailTemp.Html_Value__c);
                }
                System.debug('Email Temp::::::'+emailTemp);
                upsert emailTemp;
                System.debug('Email Temp after upsert::::::'+emailTemp);
            }
                
            }
            return new PageReference('/'+emailTemp.Id);
        }
        catch(exception e){
            System.debug('Exception::'+e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,e.getMessage()));
        }   
        return null;
    }
    
    public PageReference Cancel(){
        try{
            return new PageReference('/'+emailTemp.Id);
        }
        catch(exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,e.getMessage()));
        }   
        return null;
    }
    
    /** Fetch List of all related Objects **/
    public Set<SelectOption> getAllRelatedObjects(){
        try{
            Set<SelectOption> RelatedObjLst = new Set<SelectOption>();
            Map<string, Schema.DescribeSObjectResult> sobjectMap = new Map<string, Schema.DescribeSObjectResult>();
            RelatedObjLst.add(new SelectOption('--Select--', '--Select--'));

            if(baseObject != null && baseObject != ''){
                sObject sObj = Schema.getGlobalDescribe().get(baseObject).newSObject() ;
                
                for(ChildRelationship r: sobj.getSObjectType().getDescribe().getChildRelationships()) {
                    if(r.getChildSObject().getDescribe().isQueryable() && r.getChildSObject().getDescribe().isAccessible()){
                        sobjectMap.put(r.getChildSObject().getDescribe().getLabel(), r.getChildSObject().getDescribe());
                    }
                }
                
                if(sobjectMap.size() > 0){
                    List<string> sortedList=new List<string>();
                    sortedList.addAll(sobjectMap.keySet());
                    sortedList.sort();
                    
                    for(string field : sortedList){
                        if(sobjectMap.get(field) != null){
                            RelatedObjLst.add(new SelectOption(sobjectMap.get(field).getName(), sobjectMap.get(field).getLabel()));
                        }
                    }
                }
            }
            return RelatedObjLst;
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,e.getMessage()));
        }
        return null;
    }
    
    /** To get list of all the Fields of related Object **/
    public void RObjectFields() {
        try{
            mergeField2  = '' ;
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            List<SelectOption> fieldNames = new List<SelectOption>();
            leftvalues = new Set<String>();
            rightvalues = new List<String>();
            rightvaluesSet = new Set<string>();
            
            fieldNames.add(new SelectOption('--Select--','--Select--'));
            //system.debug(relatedObject );
            
            if(relatedObject != null && relatedObject != '' && relatedObject != '--Select--'){
                Schema.SObjectType ObjectSchema = schemaMap.get(relatedObject);
                Map<String, Schema.SObjectField> fieldMap = ObjectSchema.getDescribe().fields.getMap();
                
                if(fieldMap != null && fieldMap.size() > 0){
                    for (schema.SObjectField fieldName: fieldMap.values()) {  
                        if(fieldName.getDescribe().isAccessible()){
                            fieldNames.add(new SelectOption(fieldName.getDescribe().getName(),fieldName.getDescribe().getLabel()));
                            //fieldMap.get(fieldName).getDescribe().getLabel();//It provides to get the object fields label.
                            leftvalues.add(fieldName.getDescribe().getLabel());
                            fieldsMap.put(fieldName.getDescribe().getLabel(), fieldName.getDescribe().getName());
                        }
                    }
                }
            }
            fieldNames = Utility.getSortedList(fieldNames);
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,e.getMessage()));
        }
    } 
    
    public void createMergeField2(){
        try{
            mergeField2 = '' ;
            
            if(relatedObject != null && selectedField2 != null && selectedField2 != '' && selectedField2 != '--Select--'){
                mergeField2 = '{!'+relatedObject+'.'+selectedField2+'}' ;
            }    
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,e.getMessage()));
        }
    }
    
    /** Field Multi Select Functionality **/
    public PageReference selectclick(){
        rightselected = '';
        
        if(leftselected != null && leftselected != ''){
            List<string> fields = leftselected.split('#@#');
            if(fields.size()+rightvaluesSet.size() <= numberOfAllowedFields){
                for(String s : fields){
                    rightvalues = new List<String>();
                    leftvalues.remove(s);
                    rightvaluesSet.add(s);
                    rightvalues.addAll(rightvaluesSet);
                }
                fieldLimitAlert = '';
                getSelectedProducts(); 
            }
            else{
                fieldLimitAlert = '* You can select maximum '+numberOfAllowedFields+' fields.';
            }
        }
           
        return null;
    }
     
    public PageReference unselectclick(){
        leftselected='';
        
        if(rightselected != null && rightselected != ''){
            for(String s : rightselected.split('#@#')){
                rightvaluesSet.remove(s);
                leftvalues.add(s);
                rightvalues = new List<String>();
                rightvalues.addAll(rightvaluesSet);
            }
            getSelectedProducts(); 
        }   
        return null;
    }
    
    public PageReference moveUpward(){
        if(rightselected != null && rightselected != ''){
            Integer index = 0;
            String tmp = '';
            
            for(String s : rightvalues){
                if(rightselected == s && index > 0){
                    //system.assert(false,rightvalues+' = '+index+' = '+rightselected);
                    tmp = rightvalues[index];
                    rightvalues[index] = rightvalues[index-1];
                    rightvalues[index-1] = tmp;
                    break;
                }
                index++;
            }
            getSelectedProducts();   
        } 
        return null;
    }
    
    public PageReference moveDownward(){
        if(rightselected != null && rightselected != ''){
            Integer index = 0;
            String tmp = '';
            
            for(String s : rightvalues){
                if(rightselected == s && index != rightvalues.size()-1){
                    //system.assert(false,rightvalues+' = '+index+' = '+rightselected);
                    tmp = rightvalues[index];
                    rightvalues[index] = rightvalues[index+1];
                    rightvalues[index+1] = tmp;
                    break;
                }
                index++;
            }
            getSelectedProducts();   
        } 
        return null;
    }
    
    public List<SelectOption> getunSelectedValues(){
        List<SelectOption> options = new List<SelectOption>();
        List<string> tempList = new List<String>();
        
        tempList.addAll(leftvalues);
        tempList.sort();
        
        if(tempList.size() > 0){
            for(String str : tempList){
                if(fieldsMap.containsKey(str))
                    options.add(new SelectOption(fieldsMap.get(str), str));
            }
        }
        return options;
    }
    
    public List<SelectOption> getSelectedValues(){
        List<SelectOption> options = new List<SelectOption>();
        List<string> tempList = new List<String>();
        tempList.addAll(rightvalues);
        //tempList.sort();
        
        for(String s : tempList){
            if(fieldsMap.containsKey(s))
                options.add(new SelectOption(fieldsMap.get(s),s));
        }
        return options;
    }
    
    public String getSelectedProducts(){
        selected = '';
        Integer Flag = 1;
        for(String str : rightvalues){
            if(rightvalues.size() != Flag){
                selected += str+';';
            }  
            else{
                selected  += str;
            } 
            Flag += 1; 
        }
        return selected ;
    }
    
    public void InitializeInsertFields(){
        try{
            selectedField = '';
            mergeField = '';
            refselectedField = '';
            rightvalues = new List<string>();
            rightvaluesSet = new Set<string>();
            refObjectFields = new List<SelectOption>();
            
            System.debug('baseObject ::'+baseObject);
            
            if(baseObject != null && baseObject != null){
                fetchsobjects();
                fetchsobjectFields();
            }
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,e.getMessage()));
        }
    }
    
    public void InitializeRelatedFields(){
        try{
            leftselected = '';
            rightselected = '';
            leftvalues = new Set<String>();
            rightvalues = new List<String>();
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,e.getMessage()));
        }
    }
}