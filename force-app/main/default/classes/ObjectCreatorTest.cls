@isTest
private class ObjectCreatorTest {
    
    @isTest(seeAllData=false) 
    static void TestEnviroment_Test(){
        
        ObjectCreator.EnableSharingMethods(); 
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment(); 
        ObjectCreator.getNewSeminarType();
        ObjectCreator.getNewSeminar();        
        ObjectCreator.getNewOrder(null, null);
        ObjectCreator.getNewOrderProduct(null, null, null);
        //ObjectCreator.getNewOrderProduct(testEnv.orderId, testEnv.productPriceId, testEnv.orderProductRecordTypeId);
        ObjectCreator.getNewPriceListTitleFranchisee(null);
        ObjectCreator.getNewProductPrice(null);
        ObjectCreator.getNewHDProduct();
        ObjectCreator.getNewSetProduct(null);
        ObjectCreator.getNewSeminarTeacher(null,null);
        ObjectCreator.getNewAgreementParametersByStudents(null);
        
        
        ObjectCreator.getNewAgreementParametersByType(null, 'test');
        ObjectCreator.getNewFamily();
        ObjectCreator.getNewCampaign();
        ObjectCreator.getNewFranchiseeVat(null,null);//Added by Avihai 17/07/2018 Task-000001930	
        ObjectCreator.getNewHolidayVacation(null);//Added by Avihai 17/07/2018
        ObjectCreator.getNewTeacherAgreement(null);//Added by Avihai 17/07/2018
        ObjectCreator.getNewLGPayment(null,null,null);//Added by Avihai 17/07/2018
        ObjectCreator.getNewGroupIncomePerMonth(null,null);//Added by Avihai 17/07/2018 Task-000001930	
        ObjectCreator.getNewTeacherQualification(null,null);//Added by Avihai 17/07/2018 Task-000001930	
        ObjectCreator.getNewStudentAttendance(null, null);
        ObjectCreator.getNewLGDiscount(null, null);
        ObjectCreator.getNewUser(null);   
        ObjectCreator.getNewAgreement(null);
        ObjectCreator.getNewBaseCourse();
        ObjectCreator.getNewCourseSubType(null, null);
        LG__c lg = ObjectCreator.getNewLG(null, null, null);
        Id lgId = lg.id;
        ObjectCreator.getNewLG_Lesson(null, null, null);
        ObjectCreator.getNewLG_Days_Hours(null);       
        Account acc = ObjectCreator.getNewAccount();
        Contact studentContact = ObjectCreator.getNewContact(acc.Id, null);
        ObjectCreator.getNewAdditionalHoliday(acc.Id);
        Id studentContactId = studentContact.Id;
        ObjectCreator.getNewLGStudent(studentContactId, lgId);
        ObjectCreator.getNewLCClassRoom(acc.Id);
        ObjectCreator.initializeCustomSetting();
        
       /*  ObjectCreator.getNewSetProduct(testEnv.hdProductId);
        ObjectCreator.getNewAgreementParametersByType(null, 'test');
        ObjectCreator.getNewFamily();
        ObjectCreator.getNewCampaign();
        ObjectCreator.getNewFranchiseeVat(null,null);//Added by Avihai 17/07/2018 Task-000001930	
        ObjectCreator.getNewHolidayVacation(null);//Added by Avihai 17/07/2018
        ObjectCreator.getNewTeacherAgreement(null);//Added by Avihai 17/07/2018
        ObjectCreator.getNewLGPayment(null,null,null);//Added by Avihai 17/07/2018
        ObjectCreator.getNewGroupIncomePerMonth(null,null);//Added by Avihai 17/07/2018 Task-000001930	
        ObjectCreator.getNewTeacherQualification(null,null);//Added by Avihai 17/07/2018 Task-000001930	
        ObjectCreator.getNewStudentAttendance(testEnv.lgLessonId, testEnv.studentId);
        ObjectCreator.getNewLGDiscount(testEnv.studentId, testEnv.lgId);
        ObjectCreator.getNewUser(testEnv.teacherContactId);*/
        ObjectCreator.DisableSharingMethods();
    }
}