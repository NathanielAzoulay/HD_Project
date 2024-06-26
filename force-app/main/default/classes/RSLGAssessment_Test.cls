/**************************************************************************************** 
	Name              : RSLGAssessment_Test 
	Description 	  : Test Class for RSLGAssessment.
	Revision History  :-
	Created/Modified by   		Created/Modified Date     Requested by      
	------------------------------------------------------------------
	1. Rashad Saeed (Created)			29/4/17               HD		           
	-------------------------------------------------------------------
***********************************************************************/
@isTest
public class RSLGAssessment_Test {
    
    @isTest(seeAllData=false)
    static void LRSLGAssessment(){
    	ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        LG__c lg = new LG__c(Id = testEnv.lgId);
        lg.Group_Status__c = 'Planned';
        lg.LG_Start_Date__c = System.today();
        lg.LG_End_Date__c = System.today().addDays(30);
        update lg;
        Base_Course__c bc = new Base_Course__c(Id = testEnv.baseCurseId);
        BC_Assessment__c BCASS = new BC_Assessment__c (Base_Course__c =bc.Id,Test_Type__c='Write',Assessment_Name_Text__c='Test');
        insert BCASS;
        LG_Student__c student = new LG_Student__c(Id = testEnv.studentId);
        LG_Student_Assessment__c lgAss = new LG_Student_Assessment__c (LG_Student__c =student.id,Assessment_Date__c=System.today().addDays(30),BC_Assessment__c=BCASS.Id);
        Insert lgAss;
        ApexPages.currentPage().getParameters().put('LGID',lg.Id);
        RSLGAssessment RS = new RSLGAssessment ();
        Rs.LGS_AssList.add(lgAss);
        Rs.selectedBC_Ass = BCASS.Id;
        Rs.ChangeBCAss();
        Rs.rSave();
        Rs.rReturn();
        RSLGAssessment RS1 = new RSLGAssessment ();
        Rs1.selectedBC_Ass = 'None';
        Rs1.ChangeBCAss();
        Rs1.rSave();
       }
}