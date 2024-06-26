@isTest
public class Teacher_Qualification_TriggerHandlerTest {

    @isTest(seeAllData=false) 
    static void checkTeacherQualifications_Test(){
        Account acc = ObjectCreator.getNewAccount();
        insert acc;

        Contact teacher1 = ObjectCreator.getNewContact(acc.Id, Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Teacher').getRecordTypeId());              
        insert new List<Contact>{teacher1};

        Agreement__c agreement = ObjectCreator.getNewAgreement( acc.Id);
        insert agreement;
        
        Base_Course__c bc = ObjectCreator.getNewBaseCourse();
        insert bc;

        Course_Sub_Type__c cSubType = ObjectCreator.getNewCourseSubType(acc.Id, bc.Id); 
        insert cSubType;

        LG__c lg1 = ObjectCreator.getNewLG( acc.Id, cSubType.Id, agreement.Id );
        lg1.LG_Start_Date__c = system.today();
        lg1.LG_End_Date__c = system.today().addMonths(5);
        lg1.Teacher__c = teacher1.Id;
        lg1.Group_Status__c = 'Active';        

        insert lg1;

        lg1 = [SELECT Teacher_is_not_Qualified_for_Base_Course__c FROM LG__c WHERE Id = :lg1.Id];

        System.assert(lg1.Teacher_is_not_Qualified_for_Base_Course__c == true);

        Teacher_Qualification__c teacherQ = ObjectCreator.getNewTeacherQualification(teacher1.Id,bc.Id);
        insert teacherQ;        

        // lg1 = [SELECT Teacher_is_not_Qualified_for_Base_Course__c FROM LG__c WHERE Id = :lg1.Id];

        // System.assert(lg1.Teacher_is_not_Qualified_for_Base_Course__c == false);
    }
}