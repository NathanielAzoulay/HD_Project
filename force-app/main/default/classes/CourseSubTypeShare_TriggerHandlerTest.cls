/************************************************************************************
Name-: CourseSubTypeShare_TriggerHandlerTest
Description-: Test class for CourseSubTypeShare_TriggerHandler trigger on Course Sub Type.

Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue
========================================================================================
1.Shivram Saini        29-March-2018            Rashad Saeed           Task-000001430
*************************************************************************************/
@isTest
public class CourseSubTypeShare_TriggerHandlerTest {
    /*
		Auther: Shivram Saini
		Created Date-: 29-March-2018 
	*/
    static  testMethod void validateBeforeDeleteMethod(){
        //CREATE ACCOUNT
        Account acc = ObjectCreator.getNewAccount();
        insert acc;
        
        //CREATE AGREEMENT
        Agreement__c agreement = ObjectCreator.getNewAgreement( acc.Id);
        insert agreement;
        
        //CREATE BASE COURSE
        Base_Course__c bc = ObjectCreator.getNewBaseCourse();
        bc.Fixed_Number_of_Students__c = true;
        insert bc;
        
        //CREATE COURSE SUB TYPE
        Course_Sub_Type__c cSubType = ObjectCreator.getNewCourseSubType(acc.Id, bc.Id); 
        insert cSubType;
        
        //CREATE COURSE SUBTYPE SHARE
        Course_Sub_Type_Sharing__c share = new Course_Sub_Type_Sharing__c();
        share.Account__c = acc.Id;
        share.Course_Sub_Type__c = cSubType.Id;
        insert share;
        
        //DELETE COURSE SUBTYPE SHARE
        delete share;
    }
}