/*******************************************************************************
Name              : LGRemoveStudentController
Description       : Controller logic of quick change LG to Student called from LGStudents VF page
Revision History  : - 
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez             10/12/2015                  Yaara                   [SW-16692]
*******************************************************************************/

public with sharing class LGRemoveStudentController {

    public LG_Student__c dummyStudent{get;set;}
    public LG_Student__c currentStudent{get;set;}
    public String studentId{get;set;}
    public Integer formNro{get;set;}
    public Integer stepParam{get;set;}
    public String resultJSON {get; set;}
    public class MyException extends Exception {}

    public LGRemoveStudentController() {

        resultJSON = '';
        studentId = ApexPages.currentPage().getParameters().get('studentid');
        formNro = 0;
        dummyStudent = new LG_Student__c();

        currentStudent = [SELECT Name, Last_Name__c, First_Name__c, LG__r.Name, Student__c, Status_in_LG__c, Continue_from_LG__c FROM LG_Student__c WHERE Id = :studentId];

    }

    /***
    * doChange - update the current student to removed and create new student in selected lesson
    ***/
    public void doChange(){
        resultJSON = '"Result":"{0}","Id":"{1}","Message":"{2}"';

        Savepoint sp = Database.setSavepoint();
        try{
            if(dummyStudent.Student_Course_End_Date__c == null || dummyStudent.LG__c == null ){
                throw new MyException('Please fill End Date and choose Learning Group.');
            }
            currentStudent.Student_Course_End_Date__c = dummyStudent.Student_Course_End_Date__c;
            currentStudent.Remove_Reason__c = 'Move to another Group';
            update currentStudent;

            List<LG_Student_Attendance__c> attendance2del = [SELECT Id FROM LG_Student_Attendance__c WHERE LG_Student__c = :currentStudent.Id AND CreatedDate > :dummyStudent.Student_Course_End_Date__c];
            if(!attendance2del.isEmpty()){
                delete attendance2del;   
            }            

            LG__c newLesson = [SELECT Id, LG_Start_Date__c, LG_End_Date__c, LG_Start_Paying_Date__c, LG_End_Paying_Date__c, LG_Type__c, Base_Course__c FROM LG__c WHERE Id =: dummyStudent.LG__c];
            LG__c oldLesson = [SELECT Preceding_LG__r.Course_Sub_Type__r.Base_Course__c FROM LG__c WHERE Id =: currentStudent.LG__c];
            
            Date newStartDate = dummyStudent.Student_Course_End_Date__c.addDays(1);
            if(newLesson.LG_Start_Date__c > newStartDate){
                newStartDate = newLesson.LG_Start_Date__c;
            }

            Date newStartPayDate = dummyStudent.Student_Course_End_Date__c.addDays(1);
            if(newLesson.LG_Start_Paying_Date__c > newStartPayDate){
                newStartPayDate = newLesson.LG_Start_Date__c;
            }
            
            LG_Student__c newStudent = new LG_Student__c();
            newStudent.Student_Course_Start_Date__c = newStartDate;
            newStudent.Student_Course_End_Date__c = newLesson.LG_End_Date__c;
            newStudent.Student_Start_Paying_Date__c = newStartPayDate;
            newStudent.Student_End_Paying_Date__c = newLesson.LG_End_Paying_Date__c;
            newStudent.LG__c = dummyStudent.LG__c;
            newStudent.Student__c = currentStudent.Student__c;
            newStudent.Lesson_Type__c = newLesson.LG_Type__c;
            newStudent.Status_in_LG__c = currentStudent.Status_in_LG__c; 
            newStudent.Continue_from_LG__c = currentStudent.Continue_from_LG__c; 
            newStudent.Continue_from_Base_Course__c = oldLesson.Preceding_LG__r.Course_Sub_Type__r.Base_Course__c;
            newStudent.Status_in_LG_Comment__c = 'Move from ' + currentStudent.LG__r.Name;
            insert newStudent;

            resultJSON = string.format(resultJSON, new List<String>{'success', newStudent.id,''});
        }catch(Exception e){                  
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()));            
            resultJSON = string.format(resultJSON, new List<String>{'fail', null, e.getMessage()});
        }
        resultJSON = '{'+resultJSON+'}';
    }

    /***
    * doRemove - update the current student to removed
    ***/
    public void doRemove(){
        resultJSON = '"Result":"{0}","Id":"{1}","Message":"{2}"';
        try{
            if(dummyStudent.Student_Course_End_Date__c == null || dummyStudent.Student_End_Paying_Date__c == null || dummyStudent.Drop_Out_Reason__c == null || dummyStudent.Status_in_LG_Comment__c == null ){
                throw new MyException('Please fill End Dates and drop out reason.');
            }
            currentStudent.Student_Course_End_Date__c = dummyStudent.Student_Course_End_Date__c;
            currentStudent.Student_End_Paying_Date__c = dummyStudent.Student_End_Paying_Date__c;
            currentStudent.Remove_Reason__c = dummyStudent.Remove_Reason__c;
            currentStudent.Drop_Out_Reason__c = dummyStudent.Drop_Out_Reason__c;
            currentStudent.Status_in_LG_Comment__c = dummyStudent.Status_in_LG_Comment__c;
            update currentStudent;            
            resultJSON = string.format(resultJSON, new List<String>{'success', currentStudent.id,''});
        }catch(Exception e){            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()));
            resultJSON = string.format(resultJSON, new List<String>{'fail', null, e.getMessage()});
        }
        resultJSON = '{'+resultJSON+'}';
    }   

    public void ChangeForm(){
        formNro = stepParam;
        if(formNro == 2){
            dummyStudent.Remove_Reason__c = 'Request to Leave';
        }
    }

    public String getStep(){
        return String.valueOf(formNro);
    }
}