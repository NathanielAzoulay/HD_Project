@isTest
private class Holiday_Vacation_TriggerHandler_Test {
	
	@isTest(seeAllData=false)
	static void updateLessonsWhenCreateHoliday_Test(){
		
		Account acc = ObjectCreator.getNewAccount();
		insert acc;

		Account lc = ObjectCreator.getNewAccount();
		lc.Name = 'lc test';
		insert lc;

		Contact teacher = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());				
		insert teacher;

		Agreement__c agree = ObjectCreator.getNewAgreement(acc.Id);				
		insert agree;

		Base_Course__c baseCurse = ObjectCreator.getNewBaseCourse();				
		insert baseCurse;

		Course_Sub_Type__c curseSubType = ObjectCreator.getNewCourseSubType(acc.Id, baseCurse.Id);				
		insert curseSubType;

		LG__c lg = ObjectCreator.getNewLG(acc.Id, curseSubType.Id, agree.Id);
		lg.Franchisee__c = lc.Id;		
        insert lg;

		LG_Days_Hours__c lgDH = ObjectCreator.getNewLG_Days_Hours(lg.Id);				
		insert lgDH;

		LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson(lg.Id, teacher.Id, lgDH.Id);		        		
		insert lesson;

		Test.startTest();

		Holiday_Vacation__c holiday = ObjectCreator.getNewHolidayVacation(Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('LC').getRecordTypeId());
		holiday.LC__c = lc.Id;
		insert holiday;
		//Comment out by Avihai 24/07/2018 Task-000001699
		//System.assert([SELECT Holiday__c FROM LG_Lesson__c WHERE Id = :lesson.Id].Holiday__c == holiday.Id);

		holiday.Start_Date__c = system.today().addDays(2); 
		update holiday;

		System.assert([SELECT Holiday__c FROM LG_Lesson__c WHERE Id = :lesson.Id].Holiday__c == null);

		Test.stopTest();

	}

	@isTest(seeAllData=false)
	static void updateLessonsWhenCreateHoliday2_Test(){
		Account mf = ObjectCreator.getNewAccount();
		mf.Name = 'mf test';
		insert mf;

		Account acc = ObjectCreator.getNewAccount();
		acc.ParentId = mf.Id;
		insert acc;

		Contact teacher = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());				
		insert teacher;

		Agreement__c agree = ObjectCreator.getNewAgreement(acc.Id);				
		insert agree;

		Base_Course__c baseCurse = ObjectCreator.getNewBaseCourse();				
		insert baseCurse;

		Course_Sub_Type__c curseSubType = ObjectCreator.getNewCourseSubType(acc.Id, baseCurse.Id);				
		insert curseSubType;

		LG__c lg = ObjectCreator.getNewLG(acc.Id, curseSubType.Id, agree.Id);
		lg.Franchisee__c = acc.Id;		
        insert lg;

		LG_Days_Hours__c lgDH = ObjectCreator.getNewLG_Days_Hours(lg.Id);				
		insert lgDH;

		LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson(lg.Id, teacher.Id, lgDH.Id);		        		
		insert lesson;
		
		Test.startTest();

		Holiday_Vacation__c holiday = ObjectCreator.getNewHolidayVacation(Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('MF').getRecordTypeId());
		holiday.MF__c = mf.Id;
		insert holiday;
		//Comment out by Avihai 24/07/2018 Task-000001699
		//System.assert([SELECT Holiday__c FROM LG_Lesson__c WHERE Id = :lesson.Id].Holiday__c == holiday.Id);

		holiday.Start_Date__c = system.today().addDays(2); 
		update holiday;

		System.assert([SELECT Holiday__c FROM LG_Lesson__c WHERE Id = :lesson.Id].Holiday__c == null);

		Test.stopTest();

	}

	@isTest(seeAllData=false)
	static void updateLessonsWhenCreateHoliday3_Test(){
		Account mf = ObjectCreator.getNewAccount();
		mf.Name = 'mf test';
		insert mf;

		Account acc = ObjectCreator.getNewAccount();
		acc.ParentId = mf.Id;
		acc.BillingCountry = 'Afghanistan';
		insert acc;

		Contact teacher = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());				
		insert teacher;

		Agreement__c agree = ObjectCreator.getNewAgreement(acc.Id);				
		insert agree;

		Base_Course__c baseCurse = ObjectCreator.getNewBaseCourse();				
        insert baseCurse;
        
		Course_Sub_Type__c curseSubType = ObjectCreator.getNewCourseSubType(acc.Id, baseCurse.Id);				
		insert curseSubType;

		LG__c lg = ObjectCreator.getNewLG(acc.Id, curseSubType.Id, agree.Id);
		lg.Franchisee__c = acc.Id;
        insert lg;

		LG_Days_Hours__c lgDH = ObjectCreator.getNewLG_Days_Hours(lg.Id);				
		insert lgDH;

		LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson(lg.Id, teacher.Id, lgDH.Id);		        		
		insert lesson;

		Test.startTest();

		Holiday_Vacation__c holiday = ObjectCreator.getNewHolidayVacation(Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('Country').getRecordTypeId());
		holiday.Country__c = 'Afghanistan';
		insert holiday;
		//Comment out by Avihai 24/07/2018 Task-000001699
		//System.assert([SELECT Holiday__c FROM LG_Lesson__c WHERE Id = :lesson.Id].Holiday__c == holiday.Id);

		holiday.Start_Date__c = system.today().addDays(2); 
		update holiday;

		System.assert([SELECT Holiday__c FROM LG_Lesson__c WHERE Id = :lesson.Id].Holiday__c == null);

		Test.stopTest();

	}

	@isTest(seeAllData=false)
	static void holidayslessons2up_Test(){
		
		Account acc = ObjectCreator.getNewAccount();
		insert acc;

		Account lc = ObjectCreator.getNewAccount();
		lc.Name = 'lc test';
		insert lc;

		Contact teacher = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());				
		insert teacher;

		Agreement__c agree = ObjectCreator.getNewAgreement(acc.Id);				
		insert agree;

		Base_Course__c baseCurse = ObjectCreator.getNewBaseCourse();				
		insert baseCurse;

		Course_Sub_Type__c curseSubType = ObjectCreator.getNewCourseSubType(acc.Id, baseCurse.Id);				
		insert curseSubType;

		LG__c lg = ObjectCreator.getNewLG(acc.Id, curseSubType.Id, agree.Id);
		lg.Franchisee__c = lc.Id;	
		lg.Teacher__c = teacher.Id;	
        insert lg;

		LG_Days_Hours__c lgDH = ObjectCreator.getNewLG_Days_Hours(lg.Id);				
		insert lgDH;

		Test.startTest();

		LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson(lg.Id, teacher.Id, lgDH.Id);		        		
		insert lesson;

		Holiday_Vacation__c holiday = ObjectCreator.getNewHolidayVacation(Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('LC').getRecordTypeId());
		holiday.LC__c = lc.Id;
        holiday.Start_Date__c = System.today();
        holiday.End_Date__c = System.today() + 120;
		insert holiday;
		//Comment out by Avihai 24/07/2018 Task-000001699
		//System.assert([SELECT Holiday__c FROM LG_Lesson__c WHERE Id = :lesson.Id].Holiday__c == holiday.Id);

		holiday.Change_Existing_Lessons_to_Day_Off__c = true; 
		holiday.Work_Day__c = false; 
		update holiday;

		Test.stopTest();

		//Comment out by Avihai 24/07/2018 Task-000001699
		//System.assert([SELECT Lesson_Status__c FROM LG_Lesson__c WHERE Id = :lesson.Id].Lesson_Status__c == 'Day Off');
	}
    
	@isTest(seeAllData=false)
	static void holydayVacationResetLesson_Test(){
		
		Account acc = ObjectCreator.getNewAccount();
		insert acc;

		Account lc = ObjectCreator.getNewAccount();
		lc.Name = 'lc test';
		insert lc;

		Contact teacher = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());				
		insert teacher;

		Agreement__c agree = ObjectCreator.getNewAgreement(acc.Id);				
		insert agree;

		Base_Course__c baseCurse = ObjectCreator.getNewBaseCourse();				
		insert baseCurse;

		Course_Sub_Type__c curseSubType = ObjectCreator.getNewCourseSubType(acc.Id, baseCurse.Id);				
		insert curseSubType;

		LG__c lg = ObjectCreator.getNewLG(acc.Id, curseSubType.Id, agree.Id);
		lg.Franchisee__c = lc.Id;		
        insert lg;

		LG_Days_Hours__c lgDH = ObjectCreator.getNewLG_Days_Hours(lg.Id);				
		insert lgDH;

		LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson(lg.Id, teacher.Id, lgDH.Id);		        		
		insert lesson;

		Test.startTest();

		Holiday_Vacation__c holiday = ObjectCreator.getNewHolidayVacation(Schema.SObjectType.Holiday_Vacation__c.getRecordTypeInfosByName().get('LC').getRecordTypeId());
		holiday.LC__c = lc.Id;
		holiday.Work_Day__c = false; 
		insert holiday;
		//Comment out by Avihai 24/07/2018 Task-000001699
		//System.assert([SELECT Holiday__c FROM LG_Lesson__c WHERE Id = :lesson.Id].Holiday__c == holiday.Id);

		holiday.Work_Day__c = true; 
		update holiday;

		System.assert([SELECT Lesson_Status__c FROM LG_Lesson__c WHERE Id = :lesson.Id].Lesson_Status__c == null);

		lesson.Lesson_Status__c = 'Day Off';
		update lesson;

		delete holiday;

		Test.stopTest();

        //Comment out by Avihai 24/07/2018 Task-000001699
		//System.assert([SELECT Lesson_Status__c FROM LG_Lesson__c WHERE Id = :lesson.Id].Lesson_Status__c == null);
	}
}