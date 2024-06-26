@isTest
private class CreateAutomaticLGLessonsByBatchTest {
    
    /**************************************************************************************** 
	Name              : CreateAutomaticLGLessonsByBatch
	Description 	  : Create LG Leassons and its related objects regarding logic of issue SW-26135.
	Revision History  :-
	Created/Modified by   		Created/Modified Date     Requested by      Related Task/Issue  
	----------------------------------------------------------------------------------------
	1. Hernan (Created)			08/11/2016                Yaara		           [SW-26135]
	----------------------------------------------------------------------------------------	
	****************************************************************************************/
	
    @isTest(seeAllData=false)
    static void CreateAutomaticLGLessonsByBatchTest_Test(){
        
        test.startTest();
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
		
		Course_Sub_Type__c cst1 = new Course_Sub_Type__c(Id = testEnv.curseSubTypeId);
		cst1.Price_per_Session__c = 1;
		update cst1;
		
		LG__c lg  = new LG__c(Id = testEnv.lgId);
		lg.Billing_Type__c = 'Price per Session';
		lg.Price_per_Session__c = 1;
		lg.LG_Start_Date__c = system.today();
		lg.Group_Status__c = 'Completed';
		lg.Create_Automatic_LG_Lessons__c = True;
		update lg;

        LG_Days_Hours__c lgDH = new LG_Days_Hours__c(Id = testEnv.lgDHId);
        lgDH.End_Hour__c = '21:30';             
        update lgDH;

		delete [SELECT id FROM LG_Lesson__c WHERE LG__c =: lg.Id];

		test.stopTest();

        CreateAutomaticLGLessonsByBatch b = new CreateAutomaticLGLessonsByBatch();
		b.processName = 'Batch - Create Automatic LG Lessons (Initial)';
		database.executebatch(b);
    }
    
    @isTest(seeAllData=false)
    static void CreateAutomaticLGLessonsByBatchTest_Test2(){
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        
        test.startTest();
		
		Course_Sub_Type__c cst1 = new Course_Sub_Type__c(Id = testEnv.curseSubTypeId, Recommended_Lessons__c = 20);
		cst1.Price_per_Session__c = 1;
		update cst1;
		
		LG__c lg  = new LG__c(Id = testEnv.lgId);
		lg.Billing_Type__c = 'Price per Session';
		lg.Price_per_Session__c = 1;
		lg.LG_Start_Date__c = system.today();
		lg.Group_Status__c = 'Completed';
		lg.Create_Automatic_LG_Lessons__c = True;
		update lg;

        LG_Days_Hours__c lgDH = new LG_Days_Hours__c(Id = testEnv.lgDHId);
        lgDH.End_Hour__c = '21:30';             
        update lgDH;

		delete [SELECT id FROM LG_Lesson__c WHERE LG__c =: lg.Id];

		//update new Account(id = testEnv.lcId, Create_LG_Lessons_By__c = 'Number of Lessons');

		LG_Student__c student = new LG_Student__c(Id = testEnv.studentId );
        student.Status_in_LG__c = 'Registered';
        student.Billing_Type__c = 'Price per Session';
        student.Approved_Price__c = 1;
        student.Lesson_Type__c = 'Standard';
        //Comment out  by Avihai 17/07/2018 Task_000001922 regarding this field -> student.Discount_for_LG__c = 0;//FIELD_CUSTOM_VALIDATION_EXCEPTION, Discount in LG cannot be edited when the LG status is 'Completed': [Discount_for_LG__c] 
        //According to VR 	Cannot_Change_Student_Discount_in_LG https://eu1.salesforce.com/03dD00000002h2O?setupid=CustomObjects
        student.Gap_Between_Payments__c = null;
        student.Number_of_Payments__c = null;
        update student;


        CreateAutomaticLGLessonsByBatch b = new CreateAutomaticLGLessonsByBatch();
		b.processName = 'Batch - Create Automatic LG Lessons (Initial)';
		database.executebatch(b);

		test.stopTest();

    }
    
    @isTest(seeAllData=false)
    static void CreateAutomaticLGLessonsByBatchTest_Test3(){
        
        test.startTest();
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
		
		Course_Sub_Type__c cst1 = new Course_Sub_Type__c(Id = testEnv.curseSubTypeId);
		cst1.Price_per_Session__c = 1;
		update cst1;
		
		LG__c lg  = new LG__c(Id = testEnv.lgId);
		lg.Billing_Type__c = 'Price per Session';
		lg.Price_per_Session__c = 1;
		lg.LG_Start_Date__c = system.today();
		lg.Group_Status__c = 'Completed';
		lg.Create_Automatic_LG_Lessons__c = True;
		update lg;

        LG_Days_Hours__c lgDH = new LG_Days_Hours__c(Id = testEnv.lgDHId);
        lgDH.End_Hour__c = '21:30';             
        update lgDH;

		delete [SELECT id FROM LG_Lesson__c WHERE LG__c =: lg.Id];

		test.stopTest();

        CreateAutomaticLGLessonsByBatch b = new CreateAutomaticLGLessonsByBatch();
		b.processName = 'Batch - Create Automatic LG Lessons (Initial)';
		CreateAutomaticLGLessonsByBatch.testErroONStart = true;
		database.executebatch(b);
    }

    @isTest(seeAllData=false)
    static void CreateAutomaticLGLessonsByBatchTest_Test4(){
        
        test.startTest();
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
		
		Course_Sub_Type__c cst1 = new Course_Sub_Type__c(Id = testEnv.curseSubTypeId);
		cst1.Price_per_Session__c = 1;
		update cst1;
		
		LG__c lg  = new LG__c(Id = testEnv.lgId);
		lg.Billing_Type__c = 'Price per Session';
		lg.Price_per_Session__c = 1;
		lg.LG_Start_Date__c = system.today();
		lg.Group_Status__c = 'Completed';
		lg.Create_Automatic_LG_Lessons__c = True;
		update lg;

        LG_Days_Hours__c lgDH = new LG_Days_Hours__c(Id = testEnv.lgDHId);
        lgDH.End_Hour__c = '21:30';             
        update lgDH;

		delete [SELECT id FROM LG_Lesson__c WHERE LG__c =: lg.Id];

		test.stopTest();

        CreateAutomaticLGLessonsByBatch b = new CreateAutomaticLGLessonsByBatch();
		b.processName = 'Batch - Create Automatic LG Lessons (Initial)';
		CreateAutomaticLGLessonsByBatch.testErroONExcecution = true;
		database.executebatch(b);
    }
}