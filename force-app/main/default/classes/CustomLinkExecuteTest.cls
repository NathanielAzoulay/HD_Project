/******************************************************************************* 
Name              : CustomLinkExecuteTest
Description       : Test method of class "CustomLinkExecute" called from javascript in custom links to run batch
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. G. Fernandez         28/04/2016              Yaara Nadir              [SW-19188]
*******************************************************************************/
@isTest
private class CustomLinkExecuteTest {

    static testMethod void myUnitTest_LG_ChangeCompleteBatch() {
        CustomLinkExecute.LG_ChangeCompleteBatch();
	} 

	static testMethod void myUnitTest_Contact_ChangeToPostStudentBatch() {
        CustomLinkExecute.Contact_ChangeToPostStudentBatch();
	}

	static testMethod void myUnitTest_Run_RoyaltyCalculationProcess() {
        CustomLinkExecute.Run_RoyaltyCalculationProcess();
	}
	
	static testMethod void myUnitTest_Batch_CFM_Contacts() {
        CustomLinkExecute.Batch_CFM_Contacts();
	}
	
	static testMethod void myUnitTest_Batch_CFM_Membership() {
        HD_Settings_List__c cs1 = new HD_Settings_List__c( Name = 'CFM Batch Iteration Limit', Value__c = '1' );
        HD_Settings_List__c cs2 = new HD_Settings_List__c( Name = 'CFM Batch Record Limit', Value__c = '1' );
        insert new List<HD_Settings_List__c>{cs1, cs2};
		
        CustomLinkExecute.Batch_CFM_Membership();
	}
	
	static testMethod void myUnitTest_Batch_CFM_Users() {
        CustomLinkExecute.Batch_CFM_Users();
	}
	
	static testMethod void myUnitTest_Batch_SharingForAccountContactRelated() {
        CustomLinkExecute.Batch_SharingForAccountContactRelated();
	}
	
    static testMethod void myUnitTest_Batch_CreateUserFromContactBulk() {
        CustomLinkExecute.Batch_CreateUserFromContactBulk();
	}
	
	static testMethod void myUnitTest_Batch_CreateAutomaticLGLessonsByBatch_Initial() {
        CustomLinkExecute.Batch_CreateAutomaticLGLessonsByBatch_Initial();
	}
}