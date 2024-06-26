/******************************************************************************* 
Name              : Contact_ChangeToPostStudentScheduler
Description       : 
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez         26/04/2016              Yaara Nadir              [SW-19189]
*******************************************************************************/


global class Contact_ChangeToPostStudentScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
		Contact_ChangeToPostStudentBatch batch = new Contact_ChangeToPostStudentBatch();
		Database.executeBatch(batch); 
    }
}
/*
static testMethod void Contact_ChangeToPostStudentScheduler_Test() {     
           
    System.schedule('Contact_ChangeToPostStudentScheduler', '0 0 01 * * ?', new Contact_ChangeToPostStudentScheduler());
}*/