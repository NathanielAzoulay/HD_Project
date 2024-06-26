/**************************************************************
Description : This class supports the following 
operations, related to  Document upload to AWS s3:
1. Policy generate for AWS .
2. Generate The HMAC-SHA256 hash of the security policy. 
---------------------------------------------------------------------------------------------------------------------------
Created/Modified by    | Created/Modified Date  |   Requested by      | Related Task/Issue |	Description
---------------------------------------------------------------------------------------------------------------------------
1. Rashad Saeed        | 28/11/2016             |    				  | 				   | 
2. Avihai Shindelman   | 01/07/2018 			|	Gidi Abramovich   |	Task-000001913	   |	Adding CreatedDate field
****************************************************************************************************************************/
public with sharing class AWSstdContr {
    Public Sobject robj {set;get;}
	Public List <Document__c> docs {set;get;}
    
    public AWSstdContr(ApexPages.StandardController stdController) {
        this.robj = (Sobject)stdController.getRecord();
        docs = new List <Document__c> ();
        docs = [select Document_URL__c,Document_Name__c,Created_By__c,CreatedDate from Document__c where Application__c =:robj.id ORDER BY CreatedDate desc];
    }
}