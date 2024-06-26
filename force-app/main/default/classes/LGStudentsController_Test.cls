@isTest
private class LGStudentsController_Test {
    
    @isTest(seeAllData=false)
    static void LGStudentsController_Test() {
        ObjectCreator.initializeCustomSetting();
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();

        test.startTest();

        PageReference pageRef = ApexPages.currentPage();
        pageRef.getParameters().put('StatusInLG', 'All'); 
        pageRef.getParameters().put('LessonType', 'All');
        
        LG__c lg = new LG__c(Id = testEnv.lgId);
        ApexPages.StandardController sc = new ApexPages.StandardController( lg );

        
        
       Contact studentContact 	= ObjectCreator.getNewContact(testEnv.accId, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId());              
	    insert studentContact;
       	Id studentContactId 	= studentContact.Id;     
		        
        LG_Student__c st = ObjectCreator.getNewLGStudent(studentContactId, lg.Id);
        insert st;
        LG_Discount__c lgDisc = new LG_Discount__c();
		lgDisc.LG__c = lg.Id;
		lgDisc.Discount_Reason__c = 'test';
		lgDisc.Discount_Type__c = 'One Time (Month)';
		lgDisc.Month__c = 'February';
		lgDisc.Year__c = '2017';
		lgDisc.Requested_Course_Price__c = 1;
		lgDisc.Approved_Course_Price__c = 1;
		lgDisc.LG_Student__c = st.Id;
        
        /* 
        LG_Discount__c specialPrice = ObjectCreator.getNewLGDiscount(studentContactId, lg.Id);
        specialPrice.Requested_Course_Price__c = 1;
        insert specialPrice;
        specialPrice.Discount_Status__c = 'Cancelled';//Added by Avihai according to LG Special Price Validation Rule
        update specialPrice;*/
        
        //LG_Student__c st = new LG_Student__c(Id = testEnv.studentId);
        st.Billing_Type__c= 'Course Price';
        update st; 
 		
        //LG_Discount__c disc1 = ObjectCreator.getNewLGDiscount( testEnv.studentId, lg.Id );
       //  disc1.Discount_Status__c = 'Requested';//Comment out by Avihai according to LG Special Price Validation Rule
       // disc1.Discount_Type__c = 'Entire Course';//Added by Avihai according to LG Special Price Validation Rule
      //insert disc1;
        
        LGStudentsController lgctrl =  new LGStudentsController(sc);
        System.debug(LoggingLevel.ERROR, '*** : ' + lgctrl.statusInLG);
        System.debug(LoggingLevel.ERROR, '*** : ' + lgctrl.lessonTypes);
        
        lgctrl.DefaultValueMap.put('Status_in_LG__c', 'Potential');
        
        //lgctrl.ActionId = testEnv.studentContactId;//Comment out by Avihai, replaced with studentContactId; line #59
        lgctrl.ActionId = studentContactId;
        lgctrl.ActionRowNumber = '0';
        lgctrl.doStudentRowCheckDiscount();
        lgctrl.DoAddFromNewStudent();
        lgctrl.ActionRowNumber = '0';
        lgctrl.doChangeLessonType();
        lgctrl.runSearch();
        lgctrl.doReloadData();
        lgctrl.DoEdit();
        lgctrl.DoCancel();
        lgctrl.DoSave();
        
        lgctrl.ActionRowNumber = '1';
        lgctrl.DoRemove();

        lgctrl.ActionId = testEnv.lgId;
        lgctrl.DoDelete();
        
        lgctrl.ActionId = null;
        lgctrl.DoDelete();
        lgctrl.DoRemove();
        lgctrl.DoEdit();
        
        lgctrl.ActionRowNumber = null;
        lgctrl.doStudentRowCheckDiscount();
        
        lgctrl.doChangeStatus();
        System.Savepoint sp = Database.setSavepoint();
        try{
            database.delete(testEnv.lgId);
        }catch( System.DmlException e ){
            lgctrl.Error(e, sp);
        }
        sp = Database.setSavepoint();
        try{
            Integer i = 1/0;
        }catch( Exception e ){
            lgctrl.Error(e, sp);
        }
        test.stopTest();
        
    }


    @isTest(seeAllData=false)
    static void LGNewStudentController_Test() {
        LGNewStudentController ctrl = new LGNewStudentController();
        ctrl.doSave();
    }
}