/*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name:            RS_VFC_TeachersTraining.cls
Description:     VFP for Teachers Training Site 
Date             Author          Summary of Changes 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
11-7-2017     Rashad Saeed  Initial Implementation 
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
public Without sharing class RS_VFC_TeachersTraining {
    Public List <Seminar__c> Seminars {set;get;}
    Public RS_VFC_TeachersTraining (){
        Seminars = new List <Seminar__c>();
        Seminars = [select Start_Date__c,Venue_City__c,Country__c from Seminar__c 
                    where Type__c='TTC'
                    And Start_Date__c >= TODAY
                    And Status__c='Confirmed'
                    Order by Start_Date__c
                   ];
    }
}