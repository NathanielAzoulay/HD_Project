/*******************************************************************************
Name              : LGStudentsController
Description       : Controller logic of the List Student related list on LG Layout
Revision History  : - 
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan             12/01/2015                  Yaara                   [SW-16459]
2. G. Fernandez       12/15/2015                  Yaara                   [SW-16692]
*******************************************************************************/
public with sharing class LGStudentsController{

	/***
    * ObjectWrapper - subclass for the sObject record with additional properties
    ***/
    public class ObjectWrapper { 
    	
        public LG_Student__c obj {get; set;}
        public Boolean IsEditMode {get; set;}
        public String AddedRowNumber {get; set;}
        public Boolean hasLGDiscount {get; set;}
        
        public ObjectWrapper(sObject obj, Boolean IsEditMode) {
            this.obj = (LG_Student__c )obj;
            this.IsEditMode = IsEditMode;
        }
        
        public ObjectWrapper(sObject obj, Boolean IsEditMode, Integer rowNumber) {
            this.obj = (LG_Student__c )obj;
            this.IsEditMode = IsEditMode;
            this.AddedRowNumber = String.valueOf(rowNumber);
        }
    }
    
    public Boolean AllowAdd {get; set;}
    public Boolean AllowEdit {get; set;}
    public Boolean AllowDelete {get; set;}    
    public Boolean DisableSave {get; set;}
    public Boolean DisableCancel {get; set;}
    
    public String ActionId {get; set;}
    public String ActionRowNumber {get; set;}
    private Integer AddedRowCount = 0;
    
    public list<ObjectWrapper> ObjectList {get; set;}
    public String RelationField = 'LG__c';
    public Id ParentRecId;
    private String sObjectType = 'LG_Student__c';
    private String OrderByField = 'Lesson_Type__c, Status_in_LG__c';
    private List<String> FieldList = getFields();    
    public map<String, String> DefaultValueMap;
    public map<String, String> DefaultFormulaMap {get; set;}
    private String extraCondition;

    public Integer approvedStudents {get; set;}
    public Integer allStudents {get; set;}
    public Id currentStudent{get;set;}
    
    
    public LGStudentsController(ApexPages.StandardController controller){
        
        try{
            
            // TODO check the condition by profile
            AllowAdd = true;
            AllowEdit = true;
            AllowDelete = true;        
            DisableSave = false;
            DisableCancel = false;        

            ParentRecId = controller.getId();
            
            setDefaultValues();
            
            extraCondition = '';
            approvedStudents = 0;
            ObjectList = LoadObjectList(ParentRecId, sObjectType, FieldList, RelationField, OrderByField, extraCondition);
            AddedRowCount = ObjectList.size();
            allStudents  = ObjectList.size();

        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'An error opening the section: ' + e.getMessage()));
        }
    }
    
    // use apex describe to build the picklist values
	public List<String> lessonTypes {
	    get {
	      if (lessonTypes  == null) {
	
	        lessonTypes = new List<String>();
	        Schema.DescribeFieldResult field = LG_Student__c.Lesson_Type__c.getDescribe();
	
	        for (Schema.PicklistEntry f : field.getPicklistValues())
	          lessonTypes.add(f.getLabel());
	
	      }
	      return lessonTypes;          
	    }
	    set;
    }
    
    // use apex describe to build the picklist values
	public List<String> statusInLG {
	    get {
	      if (statusInLG  == null) {
	
	        statusInLG = new List<String>();
	        Schema.DescribeFieldResult field = LG_Student__c.Status_in_LG__c.getDescribe();
	
	        for (Schema.PicklistEntry f : field.getPicklistValues())
	          statusInLG.add(f.getLabel());
	
	      }
	      return statusInLG;          
	    }
	    set;
    }
    
    /***
    * getFields - gets the fields from the related fieldset 
    ***/
    public List<String> getFields(){
        
        List<String> fields = new List<String>();
        for(Schema.FieldSetMember f : Schema.SObjectType.LG_Student__c.FieldSets.LG_Student_Section.getFields()){
            fields.add(f.getFieldPath());
        }        
        return fields;    
    }
    
    /***
    * setDefaultValues - define the default values that should appear on predefined fields on new records
    ***/
    
    public void setDefaultValues(){
        LG__c l = [SELECT Teacher__c, Lesson_Length__c FROM LG__c WHERE Id =: ParentRecId];
        DefaultValueMap   = new Map<String,String>{};
        DefaultFormulaMap = new Map<String,String>{};
    }
    
    /***
    * DoAdd - insert new record and add to the list
    ***/
    public void DoAdd() {
        DisableSave = false;
        DisableCancel = false;
        ObjectWrapper TmpObjWrap = new ObjectWrapper(Schema.getGlobalDescribe().get(sObjectType).newSObject(), true);
        TmpObjWrap.obj.put(RelationField, ParentRecId);

        LG__c currentLesson = [SELECT LG_Start_Date__c, LG_End_Date__c, LG_Start_Paying_Date__c, LG_End_Paying_Date__c, LG_Type__c, Maximum_Number_for_Children_on_Course__c, (SELECT Id FROM LG_Students__r) FROM LG__c WHERE Id = :ParentRecId];
        
        TmpObjWrap.obj.put('Student__c', ActionId);
        TmpObjWrap.obj.put('Student_Course_Start_Date__c', currentLesson.LG_Start_Date__c );
        TmpObjWrap.obj.put('Student_Course_End_Date__c', currentLesson.LG_End_Date__c );
        TmpObjWrap.obj.put('Student_Start_Paying_Date__c', currentLesson.LG_Start_Paying_Date__c );
        TmpObjWrap.obj.put('Student_End_Paying_Date__c', currentLesson.LG_End_Paying_Date__c );
        TmpObjWrap.obj.put('Lesson_Type__c', currentLesson.LG_Type__c );
        TmpObjWrap.obj.put('Status_in_LG__c', 'Potential' );        

        for (String s : DefaultValueMap.keySet()) {
           if(DefaultValueMap.get(s) <> null){
               TmpObjWrap.obj.put(s, DefaultValueMap.get(s));
           }
        }

        insert (LG_Student__c) TmpObjWrap.obj;
        AddedRowCount += 1;
        TmpObjWrap.AddedRowNumber = String.valueOf(AddedRowCount);
        system.debug('TmpObjWrap : ' + TmpObjWrap) ;
        ObjectList.add( TmpObjWrap );
        if( currentLesson.LG_Students__r.size() >= currentLesson.Maximum_Number_for_Children_on_Course__c ){
            ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.Warning,'Exceded Maximum number for children to this course.'));     
        }
        
    }

	/***
    * DoAdd - add a record to the list
    ***/
    public void DoAddFromNewStudent() {
		DoAdd();
		ObjectList[ObjectList.size()-1].Obj.Student__c = ActionId;
		ActionRowNumber = String.valueOf(ObjectList.size() - 1);
		doStudentRowCheckDiscount();


	}
	

    /***
    * DoCancel - remove added lines and change lines back to display mode
    ***/
    public void DoCancel() {
        //DisableSave = true;
        //DisableCancel = true;
        /*
        for (Integer i=0; i < ObjectList.size(); i++) {
            // remove added lines that were not saved
            if (ObjectList[i].obj.Id == null) {
                ObjectList.remove(i);
                i--;
                continue;
            }
            // change to display mode
            //ObjectList[i].IsEditMode = false;
        }
        */        
        ObjectList.clear();
        ObjectList = LoadObjectList(ParentRecId, sObjectType, FieldList, RelationField, OrderByField,extraCondition);
        AddedRowCount = ObjectList.size();        
    }
    
    /***
    * DoSave - Save edited and added records. then refresh/requery the list
    ***/
    public void DoSave() {
        //DisableSave = true;
        //DisableCancel = true;
        list<sObject> UpdateList = new list<sObject>();
        list<sObject> InsertList = new list<sObject>();
        for (ObjectWrapper o : ObjectList) {
            if (o.IsEditMode == true) {
                if (o.obj.Id == null) {
                   // InsertList.add(o.obj);
                } else {
                    UpdateList.add(o.obj);
                }
            }
        }
        System.Savepoint sp1 = Database.setSavepoint();
        try {
            system.debug('UpdateList: ' + UpdateList);
            system.debug('InsertList: ' + InsertList);
            if (UpdateList.size() > 0) {
                update UpdateList;
            }
            if (InsertList.size() > 0) {
                insert InsertList;
            }
        } catch (System.DmlException e) {
            system.debug('error: ' + e);
            Error(e, sp1);
            return;
        } catch (exception e) {
            system.debug('error: ' + e);
            Error(e, sp1);
            return;
        }
        // requery in case field list contains fields referencing related objects
        if (UpdateList.size() > 0 || InsertList.size() > 0) {
            ObjectList.clear();
            ObjectList = LoadObjectList(ParentRecId, sObjectType, FieldList, RelationField, OrderByField,extraCondition);
            AddedRowCount = ObjectList.size();
        }
    }
    
    public void Error( Exception e, System.Savepoint sp ){
        if( sp != null ){
        	Database.rollback(sp);
        }
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'An error updating the records: ' + e.getMessage()));
    }
    
    public void Error( System.DmlException e, System.Savepoint sp ){
        if( sp != null ){
        	Database.rollback(sp);
        }
        for (Integer i=0; i < e.getNumDml(); i++) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getDmlMessage(i)));
        }
    }
    
    /***
    * DoDelete - delete the selected record
    ***/
    public void DoDelete() {
        if (ActionId == null || ActionId.trim().length() == 0) {
            return;
        }
        try {
            database.delete(ActionId);
            for (Integer i=0; i < ObjectList.size(); i++) {
                if (ActionId == ObjectList[i].obj.Id) {
                    ObjectList.remove(i);
                    break;
                }
            }
        } catch (exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()));
        }
        ActionId = null;
        return;
    }

    /***
    * DoRemove - remove usaved added rows of the list
    ***/
    public void DoRemove() {
        if (ActionRowNumber == null || ActionRowNumber.trim().length() == 0) {
            return;
        }
        for (Integer i=0; i < ObjectList.size(); i++) {
            if (ActionRowNumber == ObjectList[i].AddedRowNumber) {
                ObjectList.remove(i);
                break;
            }
        }
        ActionRowNumber = null;
        return;
    }
    
    /***
    * DoEdit - dispaly a record with editable fields
    ***/
    public void DoEdit() {
        if (ActionId == null || ActionId.trim().length() == 0) {
            return;
        }
        DisableSave = false;
        DisableCancel = false;
        for (ObjectWrapper o : ObjectList) {
            if (o.obj.Id != null && ActionId == o.obj.Id) {
                o.IsEditMode = true;
                break;
            }
        }
        ActionId = null;
        return;
    }
    
    /***
    * LoadObjectList - query the object, and load results into the object wrapper list
    ***/
    public list<ObjectWrapper> LoadObjectList(String InitRecId, String InitSObj, list<String> InitFieldList, String InitRelField, String InitOrderByField, String extraConditions) {
        list<ObjectWrapper> ObjWrapList = new list<ObjectWrapper>();
        list<String> QueryFieldList = new list<String>();
        set<String> QueryFieldSet = new set<String>();
        
        // add id to field
        QueryFieldList.addAll(InitFieldList);
        QueryFieldSet.addAll(InitFieldList);
        if (QueryFieldSet.contains('id')) {
            QueryFieldList.add('id');
        }
        
        if (InitOrderByField == null || InitOrderByField.trim().length() == 0) {
            InitOrderByField = 'CreatedDate';
        }
        String TmpQuery;
        TmpQuery = 'SELECT ' + String.escapeSingleQuotes( String.join(QueryFieldList,', ') )+ 
                    ' FROM ' + String.escapeSingleQuotes( InitSObj ) + 
                    ' WHERE ' + String.escapeSingleQuotes( InitRelField ) + '=\'' + String.escapeSingleQuotes( InitRecId ) + '\'' +
                    (extracondition<>''?extracondition:'') +
                    ' ORDER BY ' + String.escapeSingleQuotes( InitOrderByField ) +
                    ' LIMIT 1000';
        system.debug(System.LoggingLevel.ERROR, 'Query: ' + TmpQuery);
                
        list<SObject> TmpObjectList = database.query(TmpQuery);
        Integer index = 0;
        Boolean approvedSeted = approvedStudents == 0;
        for(SObject o : TmpObjectList) {
        	ObjWrapList.add(new ObjectWrapper(o, true, index));
            if(o.get('Status_in_LG__c') == 'Registered' && approvedSeted){
              approvedStudents++;  
            }
            index++;
        }
        
        studentCheckDiscount(ObjWrapList);
        
        return ObjWrapList;
    }
    
    // runs the search with parameters passed via Javascript
  public PageReference runSearch() {

	extraCondition = '';

    String status = Apexpages.currentPage().getParameters().get('StatusInLG');
    String lessonType = Apexpages.currentPage().getParameters().get('LessonType');

    if (status <> null && !status.equals('All'))
      extraCondition += ' AND Status_in_LG__c IN (\''+status+'\')';
    if (lessonType <> null && !lessonType.equals('All'))
      extraCondition += ' AND Lesson_Type__c IN (\''+lessonType+'\')';

	ObjectList.clear();
    ObjectList = LoadObjectList(ParentRecId, sObjectType, FieldList, RelationField, OrderByField,extraCondition);
    AddedRowCount = ObjectList.size();

    return null;
  }
    
    /***
    * doDummyCall - just for refreshing
    ***/
    public void doChangeStatus(){
    	
    }
    
    /***
    * doDummyCall - just for refreshing
    ***/
    public void doChangeLessonType(){
    	
    	if (ActionRowNumber == null || ActionRowNumber.trim().length() == 0) {
            return;
        }
        
        for (Integer i=0; i < ObjectList.size(); i++) {
            if (ActionRowNumber == ObjectList[i].AddedRowNumber) {
         		ObjectList[i].Obj.Status_in_LG__c = null;	   	
            }
        }
    }
    
    /***
    * doStudentRowCheckDiscount - updating internal variable for the control of the color row on the VF
    ***/
    public void doStudentRowCheckDiscount(){
    	
    	if (ActionRowNumber == null || ActionRowNumber.trim().length() == 0) {
            return;
        }
        
        for (Integer i=0; i < ObjectList.size(); i++) {
            if (ActionRowNumber == ObjectList[i].AddedRowNumber) {
            	ObjectList[i].hasLGDiscount = false;
                if(ObjectList[i].obj.Student__c <> null){
                	ObjectList[i].hasLGDiscount = ![SELECT Id FROM LG_Discount__c WHERE Discount_Status__c = 'Requested' AND LG_Student__c =: ObjectList[i].obj.Id limit 1].isEmpty();	
                }
                break;
            }
        }
        ActionRowNumber = null;
        return;        
    }
    
    /***
    * studentCheckDiscount - updating internal variable for the control of the color row on the VF
    ***/
    private void studentCheckDiscount(List<ObjectWrapper> ObjectList){
    	
    	if(ObjectList <> null){
	    	Map<Id, List<ObjectWrapper>> studentCheckDiscount = new Map<Id, List<ObjectWrapper>>(); 
	    	for(ObjectWrapper ow : ObjectList) {
		    	LG_Student__c lgStudent = (LG_Student__c)ow.Obj;
		    	if(lgStudent.Student__c <> null){
			    	if(!studentCheckDiscount.containsKey(lgStudent.Id)){
			    		studentCheckDiscount.put(lgStudent.Id, new List<ObjectWrapper>());
			    	}
			    	studentCheckDiscount.get(lgStudent.Id).add(oW);
			    }
	    	}
	    	
	    	if(!studentCheckDiscount.isEmpty()){
		    	for(LG_Discount__c lgDisc : [SELECT Id, LG_Student__c FROM LG_Discount__c WHERE Discount_Status__c = 'Requested' AND LG_Student__c IN: studentCheckDiscount.keySet()]){
		        	for(ObjectWrapper ow : studentCheckDiscount.get(lgDisc.LG_Student__c)){
		        		ow.hasLGDiscount = true;
		        	}
		        }
	    	}
    	}	  
    }

    /***
    * doReloadData - get the previous data when cancel the student row edited
    ***/
    public void doReloadData(){
        LG_Student__c studentReloaded;

        List<ObjectWrapper> defaultList = LoadObjectList(ParentRecId, sObjectType, FieldList, RelationField, OrderByField, '');            
        for( ObjectWrapper owFromDB :defaultList ){
            if(owFromDB.obj.Id == currentStudent){
                studentReloaded = owFromDB.obj;
            }
        }

        for( ObjectWrapper owFromTable :ObjectList ){
            if(owFromTable.obj.Id == currentStudent){
                owFromTable.obj = studentReloaded;                
            }
        }           
    }	    
}