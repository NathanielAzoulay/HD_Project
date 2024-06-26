/*******************************************************************************
Name              : LGDaysHoursController
Description       : Controller logic of the List LG Days & Hours related list on LG Layout
Revision History  : - 
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Nico             11/27/2015                  Yaara                   [SW-16412]
2. Hernan           04/19/2016                  Yaara                   [SW-18847]
3. Hernan           03/29/2017                  Dafna                   [SW-23793]
*******************************************************************************/
public with sharing class LGDaysHoursController{
    
    /***
    * ObjectWrapper - subclass for the sObject record with additional properties
    ***/
    public class ObjectWrapper { 
        public LG_Days_Hours__c obj {get; set;}
        public Boolean IsEditMode {get; set;}
        public String AddedRowNumber {get; set;}
        
        public ObjectWrapper(sObject obj, Boolean IsEditMode) {
            this.obj = (LG_Days_Hours__c )obj;
            this.IsEditMode = IsEditMode;
        }
        
        public ObjectWrapper(sObject obj, Boolean IsEditMode, Integer rowNumber) {
            this.obj = (LG_Days_Hours__c )obj;
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
    public String Action2DelId {get; set;}
    
    public list<ObjectWrapper> ObjectList {get; set;}
    public list<ObjectWrapper> ObjectListOriginal {get; set;}
    private Map<Id, LG_Days_Hours__c> existingDateHourById = new Map<Id, LG_Days_Hours__c>();
        
    public String RelationField = 'LG__c';
    public Id ParentRecId;
    private String sObjectType = 'LG_Days_Hours__c';
    private String OrderByField = 'CreatedDate';
    private List<String> FieldList = getFields();    
    private map<String, String> DefaultValueMap;
    public map<String, String> DefaultFormulaMap {get; set;}
    public LG__c dummyLG {get; set;}
    public LG__c currentLG {get; set;} 
    public Boolean showPopup {get; set;}
    public Boolean showPopupDone {get; set;}
    public Boolean showPopupDel {get; set;}
    public Boolean showPopupDelDone {get; set;}
    
    public LGDaysHoursController(ApexPages.StandardController controller){
        
        try{
            
            // TODO check the condition by profile
            AllowAdd = true;
            AllowEdit = true;
            AllowDelete = true;        
            DisableSave = true;
            DisableCancel = true;        
			
			showPopup = false;
			showPopupDone = false;
			showPopupDel = false;
			showPopupDelDone = false; 
			dummyLG = new LG__c(Id = controller.getId()); // this object shouldn't be save it. It's just for helping the development
			
            ParentRecId = controller.getId();
            
            currentLG = [SELECT Id, LG_Start_Date__c, Number_of_Lessons__c FROM LG__c WHERE Id =: ParentRecId];
            
            setDefaultValues();
            
            ObjectList = LoadObjectList(ParentRecId, sObjectType, FieldList, RelationField, OrderByField);
            ObjectListOriginal  = LoadObjectList(ParentRecId, sObjectType, FieldList, RelationField, OrderByField);
            for(ObjectWrapper ow : ObjectList){
            	existingDateHourById.put(ow.obj.Id, ow.obj.clone());
            }
            AddedRowCount = ObjectList.size();
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'An error opening the section: ' + e.getMessage()));
        }
    }
    
    /***
    * getFields - gets the fields from the related fieldset 
    ***/
    public List<String> getFields(){
        
        List<String> fields = new List<String>();
        for(Schema.FieldSetMember f : Schema.SObjectType.LG_Days_Hours__c.FieldSets.Days_Hour_section.getFields()){
            fields.add(f.getFieldPath());
        }        
        return fields;    
    }
    
    /***
    * setDefaultValues - define the default values that should appear on predefined fields on new records
    ***/
    
    public void setDefaultValues(){
        LG__c l = [SELECT Teacher__c, Lesson_Length__c, Classroom__c FROM LG__c WHERE Id =: ParentRecId];
        DefaultValueMap   = new Map<String,String>{'Teacher__c'=>l.Teacher__c, 'Classroom__c'=>l.Classroom__c};
        DefaultFormulaMap = new Map<String,String>{'Lesson_Length__c'=>l.Lesson_Length__c};
    }
    
    /***
    * getHourAndMinutes - get the sum of time in HH:MM format
    ***/
    
    public String getHourAndMinutes(String StartHour, String lengthTime){
        
        List<String> splitSH = StartHour.split(':',-1);
        List<String> splitLL = lengthTime.split(':',-1);
    	
    	String m  = splitSH[1];
		String m2 = splitLL[1];
		
		String h  = splitSH[0];
		String h2 = splitLL[0];
				
		// Convert to Seconds				
		Integer minutes 	= (Integer.valueOf(m) + Integer.valueOf(m2)) * 60;
		Integer hour 		= (Integer.valueOf(h) + Integer.valueOf(h2)) * 3600;
		Integer seconds = hour + minutes;
		
		// Get the hour & minutes
		Long hResult = math.roundToLong(math.FLOOR(seconds/3600));
		Long mResult = math.roundToLong(math.FLOOR(math.MOD(seconds,3600)/60));
		
		// Apply the format HH:MM
		String hWithHHFormat = String.valueOf( (hResult>9?'':'0') + hResult );
		String mWithMMFormat = String.valueOf( (mResult>9?'':'0') + mResult );
		
		return hWithHHFormat  + ':' + mWithMMFormat;
    }
    
    public String getHourAndMinutesDiff(String StartHour, String EndHour){
    	
    	List<String> splitSH = StartHour.split(':',-1);
        List<String> splitEH = EndHour.split(':',-1);
    	
    	String m  = splitSH[1];
		String m2 = splitEH[1];
		
		String h  = splitSH[0];
		String h2 = splitEH[0];
		
		Integer hDiff = Integer.valueOf(h2)-Integer.valueOf(h);
		Integer mDiff = Integer.valueOf(m2)-Integer.valueOf(m);
		
		String hWithHHFormat = String.valueOf( (hDiff>9?'':'0') + hDiff );
		String mWithMMFormat = String.valueOf( (mDiff>9?'':'0') + mDiff );
		
		return hWithHHFormat  + ':' + mWithMMFormat;
    }
    
    /***
    * DoUpdateEndHour - automatically update the end hour after changing the start hour
    ***/
    public void doUpdateEndHour() {
        if (ActionRowNumber == null || ActionRowNumber.trim().length() == 0) {
            return;
        }
        for (Integer i=0; i < ObjectList.size(); i++) {
            if (ActionRowNumber == ObjectList[i].AddedRowNumber) {
                String lLenght = ObjectList[i].obj.Lesson_Length__c; 
                if(ObjectList[i].obj.Lesson_Length__c == null){
                	lLenght = '00:00';
                }
                if(ObjectList[i].obj.Lesson_Length__c == null && DefaultFormulaMap.get('Lesson_Length__c')<>null){
                    lLenght = DefaultFormulaMap.get('Lesson_Length__c');
                }
                ObjectList[i].obj.End_Hour__c = getHourAndMinutes(ObjectList[i].obj.Start_Hour__c, lLenght);
                break;
            }
        }
        ActionRowNumber = null;
        return;
    }
    
    /***
    * DoAdd - add a record to the list
    ***/
    public void DoAdd() {
        DisableSave = false;
        DisableCancel = false;
        ObjectWrapper TmpObjWrap = new ObjectWrapper(Schema.getGlobalDescribe().get(sObjectType).newSObject(), true);
        TmpObjWrap.obj.put(RelationField, ParentRecId);
        for (String s : DefaultValueMap.keySet()) {
           if(DefaultValueMap.get(s) <> null){
               TmpObjWrap.obj.put(s, DefaultValueMap.get(s));
           }
        }
        AddedRowCount += 1;
        TmpObjWrap.AddedRowNumber = String.valueOf(AddedRowCount);
        system.debug('TmpObjWrap : ' + TmpObjWrap) ;
        ObjectList.add( TmpObjWrap );
    }

    /***
    * DoCancel - remove added lines and change lines back to display mode
    ***/
    public void DoCancelRow() {
        
        if (ActionId == null || ActionId.trim().length() == 0) {
            return;
        }
       
        for (ObjectWrapper o : ObjectList) {
            if (o.obj.Id != null && ActionId == o.obj.Id) {
            	for (ObjectWrapper oOri : ObjectListOriginal) {
            		if (oOri.obj.Id != null && ActionId == oOri.obj.Id) {
		            	o.IsEditMode = false;
		            	o.obj = oOri.obj;
            		}
            	} 
            }
        }
    }
    
    public void DoCancel() {
        DisableSave = true;
        DisableCancel = true;
        for (Integer i=0; i < ObjectList.size(); i++) {
            // remove added lines that were not saved
            if (ObjectList[i].obj.Id == null) {
                ObjectList.remove(i);
                i--;
                continue;
            }else{
            	ActionId = ObjectList[i].obj.Id;
            	DoCancelRow();
            }
            // change to display mode
            //ObjectList[i].IsEditMode = false;
        }
    }
    
    /***
    * DoSave - Save edited and added records. then refresh/requery the list
    ***/
    
    public void DoSave() {
        list<sObject> UpdateList = new list<sObject>();
        list<sObject> InsertList = new list<sObject>();
        
        Boolean condition2reCalculateButFirstAsk = false;
        for (ObjectWrapper o : ObjectList) {
            if (o.IsEditMode == true) {
                if (o.obj.Id == null) {
                	condition2reCalculateButFirstAsk = condition2reCalculateButFirstAsk || currentLG.Number_of_Lessons__c > 0;
                    InsertList.add(o.obj);                    
                } else {
                	
                	condition2reCalculateButFirstAsk |= existingDateHourById.get(o.obj.Id).Day__c <> o.obj.Day__c;
                	condition2reCalculateButFirstAsk |= existingDateHourById.get(o.obj.Id).Start_Hour__c <> o.obj.Start_Hour__c;
                	condition2reCalculateButFirstAsk |= existingDateHourById.get(o.obj.Id).End_Hour__c <> o.obj.End_Hour__c;
                	condition2reCalculateButFirstAsk = condition2reCalculateButFirstAsk && currentLG.Number_of_Lessons__c > 0;
                	UpdateList.add(o.obj);
                	system.debug('>>> condition2reCalculateButFirstAsk2: ' + condition2reCalculateButFirstAsk);
                }
            }
        }
        
        system.debug('>>> condition2reCalculateButFirstAsk3: ' + condition2reCalculateButFirstAsk);
        
        if(!condition2reCalculateButFirstAsk || (condition2reCalculateButFirstAsk && dummyLG.LG_Start_Date__c <> null)){
        	
        	showPopup = false;
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
	            
	            if((condition2reCalculateButFirstAsk && dummyLG.LG_Start_Date__c <> null)){
		            
		            if(dummyLG.LG_Start_Date__c < currentLG.LG_Start_Date__c){
		            	dummyLG.LG_Start_Date__c = currentLG.LG_Start_Date__c;
		            }
		            
		            List<LG_Lesson__c> lessons2Del = [SELECT Id, (Select Id, LG_Payment__c, LG_Student__c, LG_Student__r.LG__r.CurrencyIsoCode From LG_Students_Attendance__r) FROM LG_Lesson__c WHERE LG__c =: dummyLG.Id AND Lesson_Status__c != 'Done' AND Lesson_Date_Hour__c >= : dummyLG.LG_Start_Date__c]; 		
		    		LGDeleteLessonBatch b = new LGDeleteLessonBatch();
		    		b.selectedDate = dummyLG.LG_Start_Date__c;
		    		b.lgId = dummyLG.Id; 
		    		b.processName = 'Batch - Update LG Days & Hour';
		    		b.rollback_key = system.now().getTime();
		    		b.records2process = lessons2Del;
		    		
		    		if(!b.records2process.isEmpty()){
			    		Database.executeBatch(b);
			    	}
			    	
			    	showPopupDone = true;			    	
	            }        
	        } catch (System.DmlException e) {
	            system.debug('error: ' + e);
	            Database.rollback(sp1);
	            for (Integer i=0; i < e.getNumDml(); i++) {
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getDmlMessage(i)));
	            }
	            return;
	        } catch (exception e) {
	            system.debug('error: ' + e);
	            Database.rollback(sp1);
	            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'An error updating the records: ' + e.getMessage()));
	            return;
	        }
	        // requery in case field list contains fields referencing related objects
	        if (UpdateList.size() > 0 || InsertList.size() > 0) {
	            ObjectList.clear();
	            ObjectList = LoadObjectList(ParentRecId, sObjectType, FieldList, RelationField, OrderByField);
	            ObjectListOriginal = LoadObjectList(ParentRecId, sObjectType, FieldList, RelationField, OrderByField);
	            dummyLG.LG_Start_Date__c = null;
	            for(ObjectWrapper ow : ObjectList){
	            	existingDateHourById.put(ow.obj.Id, ow.obj.clone());
	            }
	            AddedRowCount = ObjectList.size();
	        }
            
            DisableSave = true;
            DisableCancel = true;
        }else{
        	system.debug('>>> ');
        	showPopup = true;
        }
    }
    
    /***
    * DoDelete - delete the selected record
    ***/
    public void DoDelete() {
        
        system.debug('>>> ActionId: ' + ActionId);
        system.debug('>>> dummyLG.LG_Start_Date__c: ' + dummyLG.LG_Start_Date__c);
        
        if (ActionId == null || ActionId.trim().length() == 0) {
        	if(Action2DelId == null || Action2DelId.trim().length() == 0){
            	return;
        	}else{
        		ActionId = Action2DelId;
        	}
        }else{
        	Action2DelId = ActionId;
        }
        try {
        	
        	Boolean condition2reCalculateButFirstAsk = false;
        	for (Integer i=0; i < ObjectList.size(); i++) {
                if (ActionId == ObjectList[i].obj.Id && ObjectList[i].obj.Id <> null) {
        			condition2reCalculateButFirstAsk = currentLG.Number_of_Lessons__c > 0;
                }
        	}
        	system.debug('>>> condition2reCalculateButFirstAsk: ' + condition2reCalculateButFirstAsk);
        	if(!condition2reCalculateButFirstAsk || (condition2reCalculateButFirstAsk && dummyLG.LG_Start_Date__c <> null)){
	            
	            showPopupDel = false;
	            
	            if((condition2reCalculateButFirstAsk && dummyLG.LG_Start_Date__c <> null)){
		            List<LG_Lesson__c> lessons2Del = [SELECT Id, (Select Id, LG_Payment__c, LG_Student__c, LG_Student__r.LG__r.CurrencyIsoCode From LG_Students_Attendance__r) FROM LG_Lesson__c WHERE LG__c =: currentLG.Id AND Lesson_Status__c != 'Done' AND LG_Days_Hours__c =: ActionId AND Lesson_Date_Hour__c >= : dummyLG.LG_Start_Date__c]; 		
		    		LGDeleteLessonBatch b = new LGDeleteLessonBatch();
		    		b.lgId = currentLG.Id; 
		    		b.processName = 'Batch - Delete LG Days & Hour';
		    		b.rollback_key = system.now().getTime();
		    		b.records2process = lessons2Del;
		    		
		    		if(!b.records2process.isEmpty()){
			    		Database.executeBatch(b);	            
		    		}
	            	
	            	showPopupDelDone = true;
	            }
	    		
	    		database.delete(ActionId);
	    		
	    		Action2DelId = null;
	            
	            dummyLG.LG_Start_Date__c = null;
	            for (Integer i=0; i < ObjectList.size(); i++) {
	                if (ActionId == ObjectList[i].obj.Id) {
	                    ObjectList.remove(i);
	                    break;
	                }
	            }
        	}else{
        		showPopupDel = true;
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
    * closeModalDialog - close the popup on the VF page that allow to choose a date for new LG Lessons
    ***/ 
    
    public void closeModalDialog(){    	
    	showPopup = false;
    }
    
    public void closeModalDialogDone(){    	
    	showPopupDone = false;
    }
    
    public void closeModalDelDialog(){    	
    	showPopupDel = false;
    }
    
    public void closeModalDelDialogDone(){    	
    	showPopupDelDone = false;
    }
   
    /***
    * LoadObjectList - query the object, and load results into the object wrapper list
    ***/
    public static list<ObjectWrapper> LoadObjectList(String InitRecId, String InitSObj, list<String> InitFieldList, String InitRelField, String InitOrderByField) {
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
                    ' ORDER BY ' + String.escapeSingleQuotes( InitOrderByField ) +
                    ' LIMIT 1000';
        system.debug('Query: ' + TmpQuery);
                
        list<sObject> TmpObjectList = database.query(TmpQuery);
        Integer index = 0;
        for (sObject o : TmpObjectList) {
            ObjWrapList.add(new ObjectWrapper(o, false, index));
            index++;
        }
        return ObjWrapList;
    }
    // http://www.davehelgerson.com/?p=849
}