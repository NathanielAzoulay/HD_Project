@isTest(seeAllData=false) 
public class Script_FixLessonDateTimeTest {
    @isTest(seeAllData=false) 
    public static void Test01(){
        
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
        lesson.Lesson_Date_Hour__c = system.now();
		insert lesson;
        
        lesson.Lesson_Date_Time__c = 'Test';
        update lesson;
        
        Script_FixLessonDateTime b = new Script_FixLessonDateTime();
        b.queryLimit = 1;
        b.restrictIds.add( lesson.Id );
        database.executeBatch(b);
    }
}