/******************************************************************************* 
Name              : LG_ButtonsTest
Description       : Test method of class "LG_Buttons" that contains general Methods for buttons on LG object 
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan         			06/07/2016          	
*******************************************************************************/
@isTest
private class LG_ButtonsTest {

    @isTest(seeAllData=false)
    static void generate_LGPayments2LG_Test() {
        
        insert new HD_Settings_List__c(Name = 'Generate Payment Profiles', Value__c = Userinfo.getProfileId());
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        LG_Buttons.generate_LGPayments2LG('test'); // check the error
        
        // check conditions
        update new Base_Course__c(Id = testEnv.baseCurseId, Fixed_Number_of_Students__c = true);
        update new LG__c(Id = testEnv.lgId, Declared_Number_of_Students__c = 0);
        System.assertEquals( LG_Buttons.generate_LGPayments2LG(testEnv.lgId), 'Error: ' + Label.PriceType_Per_Student_on_LG_Payments);
        
        // check success 
        update new Course_Sub_Type__c(Id = testEnv.curseSubTypeId, Price_Type__c = 'Per Group');
        update new LG__c(Id = testEnv.lgId, Gap_between_Price_Payments__c = 1, LG_Start_Paying_Date__c = system.Today());
        System.assertEquals( LG_Buttons.generate_LGPayments2LG(testEnv.lgId), '');
    }

    @isTest(seeAllData=false)
    static void generate_LGPayments2LGStudent_Test() {
        
        insert new HD_Settings_List__c(Name = 'Generate Payment Profiles', Value__c = Userinfo.getProfileId());
        
        ObjectCreator.TestEnviroment testEnv = new ObjectCreator.TestEnviroment();
        LG_Student_Buttons.generate_LGPayments2LGStudent('test'); // check the error
        
        // check success
        System.assertEquals( LG_Student_Buttons.generate_LGPayments2LGStudent(testEnv.studentId), '');
        
        // check conditions
        update new Course_Sub_Type__c(Id = testEnv.curseSubTypeId, Price_Type__c = 'Per Group');
        System.assertEquals( LG_Student_Buttons.generate_LGPayments2LGStudent(testEnv.studentId), 'Error: ' + Label.Generate_payments_to_LG_Student_PriceType_Per_Group_on_LG_Payments);
        
    }
}