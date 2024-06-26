public class Utility{
    
    /** Populate parent object merge fields **/
    public static String PopulateMergeFields(String Body, Id Id, String ObjName){
        try{
            system.debug(' ==== merge fields ==='+Body+' = ========= '+Id+' ======= '+ObjName);
            if(Body != null && Body.containsIgnoreCase('{!'+ObjName+'.')){
                Sobject SObj;
                String tmpBody = Body;
                String tmpBody2 = '';
                
                Integer startPos = 0;
                Integer endPos = 0;
                
                Map<String,String> mapMergeFields = new Map<String,String>();
                
                /** Find all merge fields in body **/
                while(tmpBody.containsIgnoreCase('{!'+ObjName+'.')){
                    startPos = tmpBody.indexOfIgnoreCase('{!'+ObjName+'.');
                    tmpBody2 = tmpBody.subString(startPos, TmpBody.length());
                    
                    endPos = tmpBody2.indexOf('}');
                    endPos = endPos + startPos;
                    //system.debug(' ======= ====== '+TmpBody+' == '+startPos+' == '+endPos+' == '+TmpBody.subString(startPos, endPos+1));
                    
                    string mergeField = TmpBody.subString(startPos, endPos+1);
                    string field = mergeField.removeStartIgnoreCase('{!'+ObjName+'.');
                    field = field.replace('}','');

                    mapMergeFields.put(mergeField, field);
                    TmpBody = TmpBody.subString(0, startPos)+TmpBody.subString(endPos+1, TmpBody.length());
                }
                
                /** Prepare fields for query **/
                string fields = '';
                if(mapMergeFields.size() > 0){
                    Set<String> fieldSet = new Set<String>();
                    
                    for(string APIName : mapMergeFields.values()){
                        APIName = APIName.toLowerCase();
                        if(!fieldSet.contains(APIName)){
                            fields += fields != '' ? ', '+APIName : APIName;
                        }
                        fieldSet.add(APIName);
                    }
                }
                
                Map<String, Schema.SObjectField> mapFields = Schema.getGlobalDescribe().get(ObjName).getDescribe().fields.getMap();
                String query = 'Select '+ fields +' FROM '+ObjName+' WHERE Id = \''+Id+'\'';
                
                /** Fetch related record and replace merge field **/
                //system.assert(false,query);
                for(Sobject obj: (List<Sobject>) database.query(query)){
                    
                    for (string mergeField : mapMergeFields.keyset()) {
                        string fieldAPI = mapMergeFields.get(mergeField);
                        
                        string fieldVal ='';
                        Sobjectfield field = mapFields.get(fieldAPI.tolowercase());
                        
                        if(field != null){
                            fieldVal = getFieldValue(field,obj);
                        }
                        else{
                            /** Replace related object fields **/
                            if (fieldAPI.containsIgnoreCase('.')) {
                                List<String> str = fieldAPI.split('\\.');
                                
                                if (str.size() == 2) {
                                    Sobject refSobj = obj.getSobject(str[0]);
                                    //system.assert(false,refSobj+' === '+str[0]+' === '+Schema.getGlobalDescribe().get(ObjName).getDescribe().fields.getMap().get('advpm__Internal_Dept_Owner__c'));
                                    
                                    if(refSobj != null){
                                        for(sObjectType ST : Schema.getGlobalDescribe().get(ObjName).getDescribe().fields.getMap().get(str[0].endsWith('__r')?str[0].subString(0, str[0].length()-1)+'c':str[0]+'Id').getDescribe().getReferenceTo()){
                                            fieldVal = getFieldValue(ST.getDescribe().fields.getMap().get(str[1]), refSobj);
                                        }
                                    }
                                }
                            }
                        }
                        Body = Body.replace(mergeField , fieldVal);
                    }
                }
            }
            return Body;
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,e.getMessage()));
            return Body;
        }
    }
    
    /** Return value for merge field **/
    public static string getFieldValue(Sobjectfield field, Sobject obj) {
        string fieldVal = '';
        try{
            string fieldAPI = field.getdescribe().getname();
            
            if (field.getdescribe().gettype() == Displaytype.Date || field.getdescribe().gettype() == Displaytype.Datetime) {
                fieldVal = (obj.get(fieldAPI) != null ? Date.valueOf(obj.get(fieldAPI)).format() : '') ;
            }
            else if (field.getdescribe().gettype() == Displaytype.Currency) {
                fieldVal = (obj.get(fieldAPI) != null ? getCurrencySymbol(obj)+String.valueOf(obj.get(fieldAPI)) : '') ;
            }
            else if (field.getdescribe().gettype() == Displaytype.Boolean) {
                fieldVal = (obj.get(fieldAPI ) != null ? String.valueOf(obj.get(fieldAPI )).equalsIgnoreCase('TRUE')?'Yes':'No' : '') ;
            }
            else if (field.getdescribe().gettype() == Displaytype.Percent) {
                fieldVal = (obj.get(fieldAPI ) != null ? String.valueOf(obj.get(fieldAPI ))+'%' : '0%') ;
            }
            else if (field.getdescribe().gettype() == Displaytype.ADDRESS) {
                fieldVal = (obj.get(fieldAPI ) != null ? string.valueOf(getAddress(Obj, fieldAPI)) : '') ;
            }
            else{
                fieldVal = (obj.get(fieldAPI ) != null ? string.valueOf(obj.get(fieldAPI )) : '') ;
            }
        }
        catch(Exception e){
            system.debug(' *** Error in getFieldValue method *** '+ e.getMessage());
        }
        return fieldVal ;
    } 
    
    /** get Currency Symbol **/
    public static String getCurrencySymbol(SObject someObject) {
        return getCurrencySymbolFromIso(getCurrencyIsoCode(someObject));
    }
    
    public static String getCurrencyIsoCode(SObject someObject){
        String currencyIso = UserInfo.isMultiCurrencyOrganization() ? (String) someObject.get('CurrencyIsoCode') : UserInfo.getDefaultCurrency();
        return currencyIso;
    }
    
    public static String getCurrencySymbolFromIso(String Iso) {
         String currencySymbol = 
           ('USD' == Iso ? '$' : 
           ('CAD' == Iso ? '$' : 
           ('EUR' == Iso ? '€' : 
           ('GBP' == Iso ? '£' : 
           ('JPY' == Iso ? '¥' : 
           ('KRW' == Iso ? '₩' : 
           ('CNY' == Iso ? '元' : 
           Iso)))))));
           return currencySymbol;
    }
    
    /** Get formatted address for compound field **/
    public static String getAddress(Sobject Obj, String FieldName){
        try{
            Address Add = (Address) Obj.get(FieldName);
            String Address = '';
            
            if(Add.getStreet() != null){
                Address += Address == ''?Add.getStreet():Add.getStreet();
            }
            
            if(Add.getCity() != null){
                Address += Address == ''?Add.getCity():', '+Add.getCity();
            }
            
            if(Add.getState() != null){
                Address += Address == ''?Add.getState():', '+Add.getState();
            }
            
            if(Add.getCountry() != null){
                Address += Address == ''?Add.getCountry():', '+Add.getCountry();
            }
            
            if(Add.getPostalCode() != null){
                Address += Address == ''?Add.getPostalCode():', '+Add.getPostalCode();
            }
            return Address;
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,e.getMessage()));
        }
        return null;
    }
    
    /** Populate relatedlist **/
    public static string ParseRelatedList(String body, Id parentId, String ParentObject){
        String retBody = body;
        Integer startIndex = 0;
        Integer endIndex = 0;
        String Content = '<table border="2"><tr>';
        
        try{
            system.debug(' ===== processing relatedlist ====== '+body);
            
            String JsonBody = '';
            String childObject = '';
            String startElement = '{"relatedList"';
            String endElement = '"filter": "';
                        
            String queryString = '';
            String fields = '';
            Map<String, SObjectField> mapSobjFields = new Map<String, SObjectField>();
            System.debug('index of startElement'+body.indexOf(startElement));
            System.debug('index of endElement'+body.indexOf(EndElement));
            if(body != null && body.indexOf(startElement) != -1 && body.indexOf(EndElement) != -1){
                system.debug(' == 1 == ');
                StartIndex = body.indexOf(startElement);
                
                if(startIndex-28 >= 0){
                    if(body.subString(StartIndex-28,StartIndex) == '<div style="display: none;">'){
                        body = body.substring(0, StartIndex-28)+body.substring(StartIndex, body.length());
                    }
                }
                
                StartIndex = body.indexOf(startElement);
                endIndex = body.indexOf(endElement);
                
                String tmpBody = body.subString(endIndex, body.length());
                Integer tmpEndIndex = tmpBody.indexOf('}')+2;
                endIndex += tmpEndIndex+1;
                
                if(endIndex <= body.length()){
                    //system.assert(false,body+' = '+endIndex+' = '+body.subString(endIndex,endIndex+6));
                    if(body.subString(endIndex,endIndex+6) == '</div>'){
                        body = body.substring(0, endIndex)+body.substring(endIndex+6, body.length());
                    }
                }
                
                if(body.containsIgnoreCase('<table')){
                    tmpBody = body.substring(endIndex, body.length());
                    Content = body.substring(endIndex, endIndex+tmpBody.indexOf('>'));
                    Content += '><tr>';
                    
                    body = body.substring(0, endIndex)+body.substring(endIndex+tmpBody.indexOf('</table>')+8, body.length());
                }
                
                JsonBody = body.substring(StartIndex, endIndex);
                JsonBody = JsonBody.replaceAll('\\<.*?\\>', '');
                
                //system.assert(false,JsonBody+' == '+body);
                TemplateWrapper TW = (TemplateWrapper)JSON.deserialize(JsonBody, TemplateWrapper.class);
                //system.assert(false, JsonBody+' == '+TW);
                
                String refVar = '';
                if(TW != null && TW.relatedList.tableSchema.columns != null && TW.relatedList.tableSchema.columns.size() > 0){
                    queryString = 'Select ';
                    childObject = TW.relatedList.ObjectName;
                    mapSobjFields = schema.getGlobalDescribe().get(childObject).getDescribe().fields.getMap();
                    
                    for(FieldWrapper FW : TW.relatedList.tableSchema.columns){
                        FW.Name = FW.Name.toLowerCase();
                        
                        if(fields != ''){
                            fields += ',';
                        }
                        fields += FW.Name;
                        Content += '<th>'+mapSobjFields.get(FW.Name).getDescribe().getLabel()+'<th>';
                    }
                    
                    queryString += fields+' FROM ';
                    queryString += TW.relatedList.ObjectName;
                    
                    for(String field : mapSobjFields.keySet()){
                        if(refVar != ''){
                            break;
                        }
                        
                        if(mapSobjFields.get(field).getDescribe().getType() == Displaytype.Reference){
                            for(SObjectType ST : mapSobjFields.get(field).getDescribe().getReferenceTo()){
                                //system.debug(' =============== '+field+' = '+childObject+' = '+ST+'==== '+ST.getDescribe().getName()+' == '+ParentObject);
                                if(String.valueOf(ST.getDescribe().getName()).equalsIgnoreCase(ParentObject)){
                                    refVar = field;
                                    break;
                                }
                            }
                        }
                    }
                    
                    queryString += ' WHERE '+refVar+' = \''+parentId+'\'';
                    if(TW.relatedList.filter != null && TW.relatedList.filter != ''){
                        TW.relatedList.filter = string.escapeSingleQuotes(TW.relatedList.filter);
                        queryString += ' AND '+TW.relatedList.filter;
                    }
                    
                    if(TW.relatedList.SortOrder != null && TW.relatedList.SortOrder != ''){
                        TW.relatedList.SortOrder = string.escapeSingleQuotes(TW.relatedList.SortOrder);
                        queryString += ' ORDER BY '+TW.relatedList.SortOrder;
                    }
                }
                
                //system.assert(false,queryString);
                String fieldVal = '';
                if(queryString != '' && refVar != null && refVar != ''){
                    Content += '</tr>';
                    for(Sobject Sobj : (List<Sobject>)database.Query(queryString)){
                        system.debug(' == 2 ==');
                        Content += '<tr>';
                        for(String Field : fields.split(',')){
                            Sobjectfield Sfield = mapSobjFields.get(Field.tolowercase());
                            fieldVal = getFieldValue(Sfield, Sobj);
                            Content += Sobj.get(Field) != null ? '<td>'+fieldVal+'<td>' : '<td>&nbsp;<td>';
                        }
                        Content += '</tr>';
                    }
                    Content += '</table>';
                }
                
                retBody = body.substring(0, StartIndex)+Content+body.substring(endIndex, body.length());
                system.debug('== 3 =='+retBody);
            }
            return retBody;
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,e.getMessage()));
            Content += '</tr></table>';
            retBody = body.substring(0, StartIndex)+Content+body.substring(endIndex, body.length());
            return retBody;
        }
    }
    
    public class TemplateWrapper{
        public relatedListWrapper relatedList;
    }
    
    public class relatedListWrapper{
         public String ObjectName;
         public TableWrapper tableSchema;
         public String SortOrder;
         public String filter;
         
         public relatedListWrapper(String ObjectName){
             this.ObjectName = ObjectName;
         }
    }
    
    public class TableWrapper{
        public List<FieldWrapper> columns;
    }
    
    public class FieldWrapper{
        public String Name;
    }
    
    /** Populate parent object conditional fields **/
    public static String executeConditionalLogic(String Body, Id Id, String ObjName){
        try{
            String stmt = '{!IF(';
            //system.assert(false,body);
            if(Body != null && (Body.containsIgnoreCase(stmt)) ){
                Sobject SObj;
                String TmpBody = Body;
                String TmpBody2 = '';
                
                Integer startPos = 0;
                Integer endPos = 0;
                
                Map<String,String> mapMergeFields = new Map<String,String>();
                Map<String,List<String>> mapMergeFieldOptions = new Map<String,List<String>>();
                
                while(TmpBody.containsIgnoreCase(stmt)){
                    
                    startPos = TmpBody.indexOfIgnoreCase(stmt);
                    TmpBody2 = TmpBody.subString(startPos, TmpBody.length());
                    
                    endPos = TmpBody2.indexOf('}');
                    endPos = endPos + startPos;
                    
                    string mergeField = TmpBody.subString(startPos, endPos+1);
                    string field = mergeField.removeStartIgnoreCase('{!IF(');
                    
                    field = field.removeStartIgnoreCase(ObjName+'.');
                    field = field.replace('}','');
                    
                    if(field.containsIgnoreCase(',')){
                        List<String> tmpList = field.split(',');
                        if(tmpList.size() == 3){
                            field = tmpList[0];
                        }
                        tmpList[1] = tmpList[1].replace('\'','');
                        tmpList[2] = tmpList[2].replace('\'','');
                        tmpList[2] = tmpList[2].replace(')','');
                        
                        tmpList.remove(0);
                        mapMergeFieldOptions.put(mergeField, tmpList);
                    }
                    
                    mapMergeFields.put(mergeField, field);
                    TmpBody = TmpBody.subString(0, startPos)+TmpBody.subString(startPos+1, TmpBody.length());
                }

                string fields = '';
                if(mapMergeFields.size() > 0){
                    Set<String> fieldSet = new Set<String>();
                    
                    for(String field : mapMergeFields.values()){
                        if(field.startsWith('!')){
                            field = field.subString(1, field.length());
                        }
                        fieldSet.add(field.toLowerCase());
                    }
                    
                    for(string APIName : fieldSet){
                        fields += fields != '' ? ', '+APIName : APIName;
                    }
                }
                
                Map<String, Schema.SObjectField> mapFields = Schema.getGlobalDescribe().get(ObjName).getDescribe().fields.getMap();
                String query = 'Select '+ fields +' FROM '+ObjName+' WHERE Id = \''+Id+'\'';
                
                boolean isNot = false;
                for(Sobject obj: (List<Sobject>) database.query(query)){
                    
                    for(string mergeField : mapMergeFields.keyset()) {
                        string fieldAPI = mapMergeFields.get(mergeField);
                        isNot = false;
                        
                        if(fieldAPI.startsWith('!')){
                            isNot = true;
                            fieldAPI = fieldAPI.subString(1, fieldAPI.length());
                        }
                        
                        string fieldVal ='';
                        Sobjectfield field = mapFields.get(fieldAPI.tolowercase());
                        
                        if(field != null && mapMergeFieldOptions.containsKey(mergeField) && mapMergeFieldOptions.get(mergeField).size() == 2){
                            fieldVal = getFieldValue(field,obj);
                            //system.assert(false, isNot+' == '+fieldVal+' == '+mapMergeFieldOptions.get(mergeField));
                            
                            if(fieldVal.containsIgnoreCase('Yes') || isNot){
                                fieldVal = mapMergeFieldOptions.get(mergeField).get(0);
                            }
                            else{
                                fieldVal = mapMergeFieldOptions.get(mergeField).get(1);
                            }
                            system.debug(' ==== '+ fieldVal);
                        }
                        Body = Body.replace(mergeField , fieldVal);
                    }
                }
            }
            return Body;
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,e.getMessage()));
            return Body;
        }
    }
    
    /** Populate global object's merge fields **/
    public static String populateGlobalMergeFields(String Body, Id Id, String ObjName){
        try{
            if(Body != null){
                /** Replace Date and Time fields **/
                Map<String,String> expressionValMap = new Map<String,String>();
                expressionValMap.put('(?i)\\{!\\$system.now\\}', string.valueOf(System.now()));
                expressionValMap.put('(?i)\\{!\\$system.today\\}', string.valueOf(System.today()));
                expressionValMap.put('(?i)\\{!\\$system.month\\}', string.valueOf(System.today().Month()));
                expressionValMap.put('(?i)\\{!\\$system.year\\}', string.valueOf(System.today().Year()));
                expressionValMap.put('(?i)\\{!\\$system.day\\}', string.valueOf(System.today().Day()));
                
                for(string exp : expressionValMap.keySet()){
                    Body = Body.replaceAll(exp, expressionValMap.get(exp));
                }
            }
            
            if(Body != null && Body.containsIgnoreCase('{!$'+ObjName+'.')){
                Sobject SObj;
                String tmpBody = Body;
                
                Integer startPos = 0;
                Integer endPos = 0;
                    
                /** Find all merge fields in body **/
                while(Body.containsIgnoreCase('{!$'+ObjName+'.')){
                    startPos = Body.indexOfIgnoreCase('{!$'+ObjName+'.');
                    tmpBody = Body.subString(startPos, body.length());
                    
                    endPos = tmpBody.indexOf('}');
                    endPos = endPos + startPos;
                    //system.debug(' ======= ====== '+TmpBody+' == '+startPos+' == '+endPos+' == '+TmpBody.subString(startPos, endPos+1));
                    
                    String mergeField = body.subString(startPos, endPos+1);
                    mergeField = mergeField.replace('$','');
                    
                    Body = body.subString(0, startPos) + mergeField + body.subString(endPos+1, body.length());
                }
                system.debug(' ===== after global fields ===== ');
                body = PopulateMergeFields(body, Id, ObjName);
            }
            return body;
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,e.getMessage()));
            system.debug(' *** Error in populateGlobalMergeFields method *** '+e.getLineNumber()+' == '+e.getMessage());
            return body;
        }
    }
    
    public static List<SelectOption> getSortedList(List<SelectOption> ObjectFields){
        try{
            List<String> ObjectFieldstemp = new List<String>();
            Map<String,SelectOption> tempMap = new Map<String,SelectOption>();
            
            For(SelectOption so: ObjectFields){
                tempMap.put(so.getLabel(), so);
                ObjectFieldstemp.add(so.getlabel());
            }
            ObjectFieldstemp.sort();
            
            ObjectFields = new List<SelectOption>();
            for(String so : ObjectFieldstemp){
                ObjectFields.add(tempMap.get(so));    
            }
            return ObjectFields;
        }
        catch(Exception e){
            system.debug(' ===== Error in getSortedList ==== '+e.getMessage());
        }
        return null;
    }
}