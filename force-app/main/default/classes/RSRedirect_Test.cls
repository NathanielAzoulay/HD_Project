/**************************************************************
Name              : RSRedirect_Test.cls
Description       : test for RSRedirect 
Created/Modified by   Created/Modified Date                       
-------------------------------------------------------------
1. Rashad Saeed        10/01/2016                 
*************************************************************/
@isTest
private class RSRedirect_Test{
    static testMethod void RSRedirect(){
      
        Test.startTest();
           RSRedirect con = new RSRedirect();
           con.RedirectToViewMode();
            
        Test.stopTest();
        
    }
}