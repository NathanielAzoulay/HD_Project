/******************************************************************************* 
Name              : Utility1
Description       : Class to read the Field Set' fields of the respective Object.
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Aparna             05/10/2017/29/08/2017                Rashad Saeed          [Task-000000923]
*******************************************************************************/
public class Utility1{

    //Method to get the field set fields' API names and Label.
    
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
    
     //Receives sObject name and fieldset name and return list of all fields details wrapped in FieldSetMember
    public static List<FieldSetMember> getFieldSet(String objectName,String fieldsetName){
        List<FieldSetMember> fields = new List<FieldSetMember>();
        Schema.FieldSet fieldSetObj = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().FieldSets.getMap().get(fieldSetName);
        for (Schema.FieldSetMember f: fieldSetObj.getFields()) {
            fields.add(new FieldSetMember(f));
        }
        return fields; 
    }
    
}