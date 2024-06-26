Global  class RSAutoComplete {

    Global  String labelFieldVar{ get; set; }
    Global  String valueFieldVar{ get; set; }
    Global  String sObjVal{get;set;}
    Global  Integer randomJsIden{get;set;}
    Global  Object cacheField{get;private set;} 
    
    private Object targetFieldVar;
    
    Global  RSAutoComplete (){
        randomJsIden = getRandomNumber(1000000);
        sObjVal='Account';
        labelFieldVar='Name';
        valueFieldVar='Id';
    }
    
    /*Dummy setter Method*/
    Global  void setCacheField(Object cacheField){}
    
    Global  void setTargetFieldVar(Object targetFieldVar){
        
        if(targetFieldVar != this.targetFieldVar){
            cacheField = getCacheFieldValue(targetFieldVar);
            this.targetFieldVar = targetFieldVar;
           
        }
        
    }
    
    Global  Object getTargetFieldVar(){
        return targetFieldVar;
    }
    
    private Object getCacheFieldValue(Object targetFieldVar){
        Object retVal = targetFieldVar;
        if(targetFieldVar!=null){
            for(sObject sObj : Database.query('SELECT '+valueFieldVar+','+labelFieldVar+' FROM '+sObjVal+' WHERE '+valueFieldVar+' =:targetFieldVar')){
                retVal = sObj.get(labelFieldVar);
                break;
            }
        }
        
        return retVal;
    }

    
    /*
    *Random number generator to change the js function name if multiple components us
    ***/
    private Integer getRandomNumber(Integer size){
        Double d = Math.random() * size;
        return d.intValue();
    }
    
    /*
    *This method queries data according to the passed parameters
    ***/
    @RemoteAction
    Global  static List<AutoCompleteData> getData(String sObjVal,String labelFieldVar,String valueFieldVar,String param){
       
        List<AutoCompleteData> AutoCompleteDatas = new List<AutoCompleteData>();
        param = String.escapeSingleQuotes(param);
        for( Sobject sObj : Database.query('SELECT '+valueFieldVar+','+labelFieldVar+' FROM '+sObjVal+' WHERE '+labelFieldVar+' LIKE \'%'+param+'%\'')){
            AutoCompleteDatas.add(new AutoCompleteData(sObj.get(valueFieldVar),sObj.get(labelFieldVar)));
        }
        
        return AutoCompleteDatas;
        
    }
    
    Global  class AutoCompleteData{
        Global  String id;
        Global  String text;
        
        Global  AutoCompleteData(Object id, Object text){
            this.id = String.valueOf(id);
            this.text = String.valueOf(text);
        }
    }

    
}