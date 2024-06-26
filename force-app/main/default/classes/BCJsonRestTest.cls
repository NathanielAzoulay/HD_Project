/******************************************************************************* 
Name              : BCJsonRestTest 
Description       : Test class for BCJsonRest.
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Aparna             05/10/2017                Rashad Saeed          [Task-000000923]
*******************************************************************************/
@isTest
public class BCJsonRestTest
{
  static testMethod void Unit1()
  {
  
    List<Base_Course__c> lstBCs = new List<Base_Course__c>();
    for(Integer i=0;i<7;i++){
        Base_Course__c bcRec = new Base_Course__c();
        bcRec.Name = 'HD course';
        bcRec.BC_Old_ID__c = 'HD00'+i;
        bcRec.BC_Short_Name__c= 'HDC';
        lstBCs.add(bcRec);
    }
    insert lstBCs;
    
    // Create Required data here    
    
        Test.startTest();
            
          BCJsonRest.doGet();
            
        Test.stopTest();   
  }

  
}