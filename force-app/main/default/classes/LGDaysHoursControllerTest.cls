@isTest
private class LGDaysHoursControllerTest {

    @isTest(seeAllData=false) 
    static void LGDaysHoursControllerTest(){

    	Account acc = ObjectCreator.getNewAccount();
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
		lg.LG_Start_Date__c = System.today();
		lg.LG_End_Date__c = System.today().addDays(10);
        insert lg;

        LG_Days_Hours__c lgDH = ObjectCreator.getNewLG_Days_Hours(lg.Id);				
		insert lgDH;

        LG_Lesson__c lesson = ObjectCreator.getNewLG_Lesson(lg.Id, teacher.Id, lgDH.Id);
        insert lesson;		

    	ApexPages.StandardController sc = new ApexPages.StandardController(lg);
    	LGDaysHoursController controller = new LGDaysHoursController(sc);

    	controller.getFields();

    	controller.DoAdd();
    	controller.DoCancel();  


    	String aId = controller.ActionId;
    	controller.ActionId = aId;  
		controller.ActionRowNumber = '1';
		controller.ObjectList[0].AddedRowNumber ='1';

    	controller.doUpdateEndHour();
    	controller.ObjectList[0].IsEditMode = true;
    	controller.dummyLG.LG_Start_Date__c = System.today();
    	controller.DoSave();
    	controller.DoEdit();


    	controller.ActionId = aId;  
		controller.ActionRowNumber = '1';
		controller.ObjectList[0].AddedRowNumber ='1';

    	controller.DoRemove();

    	controller = new LGDaysHoursController(sc);
    	controller.ActionId = aId;
    	controller.dummyLG.LG_Start_Date__c = System.today();
    	System.debug('dummyLG.LG_Start_Date__c' + controller.dummyLG.LG_Start_Date__c);
    	controller.DoDelete();

		controller.closeModalDialog();
		controller.closeModalDialogDone();
		controller.closeModalDelDialog();
		controller.closeModalDelDialogDone();

		controller.getHourAndMinutes('20:00','01:30');
    	controller.getHourAndMinutesDiff('20:00','01:30');
	}

}