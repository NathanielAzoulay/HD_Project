/******************************************************************************* 
Name              : BCJsonRest 
Description       : Create Apex rest returned JSON file with all the BC in the system controlled by FS.
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Aparna             05/10/2017                Rashad Saeed          [Task-000000923]
*******************************************************************************/
@RestResource(urlMapping='/BCJsonRest/*')
global without sharing class BCJsonRest {
  
    @HttpGet
    global static List<Base_Course__c> doGet() {
        //RestRequest req = RestContext.request;
        //RestResponse res = RestContext.response;
        List<Schema.FieldSetMember> lsBCFieldSet= readFieldSet('Base_Course__c').get('BCJsonRest');
        String query = 'SELECT ';
        for(Schema.FieldSetMember f : lsBCFieldSet) {
            query += f.getFieldPath() + ', ';
        }
        
         query = query.substring(0,query.lastIndexOf(','));
         query += ' FROM Base_Course__c ';
        System.debug('Database.query(query):::::::'+Database.query(query));
        return Database.query(query); 
    }
    
     public static Map<String,List<Schema.FieldSetMember>> readFieldSet(String ObjectName){
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Map<String,List<Schema.FieldSetMember>> mapFieldsOfFieldSet = new Map<String,List<Schema.FieldSetMember>>();
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        for(String fSetName : DescribeSObjectResultObj.FieldSets.getMap().KeySet()){
            Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fSetName);
            mapFieldsOfFieldSet.put(DescribeSObjectResultObj.FieldSets.getMap().get(fSetName).getLabel(),fieldSetObj.getFields());
            
        }
        return mapFieldsOfFieldSet; 
    }
  }