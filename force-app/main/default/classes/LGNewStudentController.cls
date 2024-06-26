/*******************************************************************************
Name              : LGNewStudentController
Description       : Controller logic of quick create Student called from LGStudents VF page
Revision History  : - 
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan             12/01/2015                  Yaara                   [SW-16459]
*******************************************************************************/
public with sharing class LGNewStudentController {
    
    public Contact newStudent {get; set;}
    public String resultJSON {get; set;}
    
    public LGNewStudentController(){
    	resultJSON = '"Result":"{0}","Id":"{1}","Message":"{2}"';	
    	newStudent = new Contact(RecordTypeId = Contact.sObjectType.getDescribe().getRecordTypeInfosByName().get('Student').getRecordTypeId());
    }
    
    
    public void doSave(){
    	
    	resultJSON = '"Result":"{0}","Id":"{1}","Message":"{2}"';
    	try{
    		insert newStudent;
    		resultJSON = string.format(resultJSON, new List<String>{'success', newStudent.id,''});
    	}catch(Exception e){
    		resultJSON = string.format(resultJSON, new List<String>{'fail', null, e.getMessage()});
    	}    	
    	resultJSON = '{'+resultJSON+'}';
    }
}