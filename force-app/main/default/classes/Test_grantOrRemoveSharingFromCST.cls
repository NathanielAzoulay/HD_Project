@isTest
public class Test_grantOrRemoveSharingFromCST {
    @isTest
    static void  validateSharingMethod(){
        //INSERT BASE COURSE
        Base_Course__c baseCourse = ObjectCreator.getNewBaseCourse();
        insert baseCourse;
        
        //INSERT ACCOUNT
        Account acc = ObjectCreator.getNewAccount();
        acc.Account_Type__c = 'MF';
        insert acc;
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MF/FP').getRecordTypeId();
        
        update acc;
        
        //INSERT CST
        Course_Sub_Type__c cst = ObjectCreator.getNewCourseSubType(acc.Id, baseCourse.Id);
        insert cst;
        
        //INSERT CST SHARING RECORD
        Course_Sub_Type_Sharing__c sharing = new Course_Sub_Type_Sharing__c();
        sharing.Account__c = acc.Id;
        sharing.Course_Sub_Type__c = cst.Id;
        insert sharing;
        
        PageReference pageRef = Page.grantOrRemoveSharingFromCSTPage;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('Id', cst.Id);
        GrantOrRemoveSharingFromCST controller = new GrantOrRemoveSharingFromCST();
        
        if(controller.WrapperClassList.size() > 0){
            controller.WrapperClassList[0].isChecked = false;
        }
        controller.sortTableByDirection();
        controller.grantOrRemoveSharing();
        controller.returnMethod();
    }
    
    
}