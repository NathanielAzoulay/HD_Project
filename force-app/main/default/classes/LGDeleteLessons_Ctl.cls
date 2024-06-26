/**************************************************************************************** 
	Name              : LGDeleteLessons_Ctl
	Description 	  : Controller of the VF page that allows to Delete LG Leassons and its related objects...
	Revision History  :-
	Created/Modified by   		Created/Modified Date     Requested by      Related Task/Issue  
	----------------------------------------------------------------------------------------
	1. Hernan (Created)			25/02/2016                Yaara		           [SW-18002]
	----------------------------------------------------------------------------------------	
****************************************************************************************/
public class LGDeleteLessons_Ctl {

	public class MyException extends Exception {}

	public String showError {get; set;}
	public Boolean showForm {get; set;}
	public Boolean showDone {get; set;}
	public String showDoneMjs {get; set;}
	public LG__c currentLG 	{get; set;}
	public Date selectedDate{get; set;}
	
    public LGDeleteLessons_Ctl(ApexPages.StandardController controller) {
		
		currentLG = [SELECT Id, LG_Start_Date__c FROM LG__c WHERE Id =: controller.getId()]; 
		showForm = true;
		showDone = false;
		showDoneMjs = null;
	}
    
    public void doDelete(){
    	Savepoint sp  = Database.setSavepoint();
    	try{
    
    		system.debug('selectedDate: ' + selectedDate);
    		
    		List<LG_Lesson__c> lessons2Del = [SELECT Id, (Select Id, LG_Payment__c, LG_Student__c, LG_Student__r.LG__r.CurrencyIsoCode From LG_Students_Attendance__r) FROM LG_Lesson__c WHERE LG__c =: currentLG.Id AND Lesson_Status__c = null AND Lesson_Date_Hour__c >= : selectedDate]; 		
    		LGDeleteLessonBatch b = new LGDeleteLessonBatch();
    		b.lgId = currentLG.Id; 
    		b.processName = 'Batch - Delete LG Lessons';
    		b.rollback_key = system.now().getTime();
    		b.records2process = lessons2Del;
    		
    		if(!b.records2process.isEmpty()){
	    		Database.executeBatch(b);
	    	}else{
	    		showDoneMjs = 'No Lessons were found for deleting.';
	    	}
    		
    		showDone = true;
	    	showForm = false;
	    	
	    	if(Test.isRunningTest()){
	    		throw new MyException('Test Exception');
	    	}
    	}catch(Exception ex){
    		Database.rollback(sp);
    		showError = ex.getMessage();
    	}
    }
    
    public void doAgain(){
    	showDone = false;
	    showForm = true;
	    showDoneMjs = null;
    }   
}