/*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name:            RSStudentsStatistics_Batch.cls
Description:     Demo success Statistics
Date             Author          Summary of Changes 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
06-Feb-2017     Rashad Saeed  Initial Implementation 
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
global class RSStudentsStatistics_Batch Implements Database.Batchable<sObject>{
    Global Boolean RunAll {get; set;}
    global Id StudentRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId(); 
    global Database.QueryLocator start(Database.BatchableContext bc) {
            //StudentRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId(); 
            String SQuery = 'select Id from Contact where RecordTypeId ='+'\''+StudentRecordTypeId+'\''; 
            System.debug('@@@@@@@@@ Batch Query \n'+ SQuery);
            return Database.getQueryLocator(SQuery); 
    }
    global void execute(Database.BatchableContext BC, List<Contact> scope){
        Schema.SObjectField f = Student_Statistics__c.Fields.DemoKey__c; 
        //Id StudentRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId(); 
        List <Student_Statistics__c> SSToUpsert = new List <Student_Statistics__c>();
        Map <Integer,Student_Statistics__c> Demoss = new Map <Integer,Student_Statistics__c>();
        Set <Id>ContactsIds = new Set <Id>();
        for (Contact ConList : Scope)
        {
           ContactsIds.add (ConList.Id); 
        }
        String rQuery = 'select Id ,Name,';
            rquery+='(select LG__r.Franchisee__r.MF_ID__c,LG__r.Franchisee__r.MF_Name__c,LG__r.Franchisee__r.Name,LG__r.Teacher__r.Name,LG__r.Name,Student_Course_Start_Date__c,Student_Course_End_Date__c,LG__r.Large_Group__c,Base_Course__c,Id,Status_in_LG__c from LG_Students__r Order By Student_Course_Start_Date__c ASC)';   
            rquery+=' from contact where RecordTypeId ='+'\''+StudentRecordTypeId+'\''+' And Id In:ContactsIds';  
            if (RunAll == null){
                RunAll = false;
                rQuery+=' and LG_for_New_Student__r.LG_Start_Date__c>=LAST_YEAR'; 
            }
        System.debug('@@@@@@@@@@@@@@ rQuery'+rQuery);
        List <Contact>ConScope = new List <Contact>();
        ConScope = DataBase.query(rQuery);
        
        for (Contact Con : ConScope)
        {
            System.debug('@@@@@@@@@@@@ Contact ID ' +Con.Id);
            System.debug('@@@@@@@@@@@@@@ LGS SIZe '+string.valueOf (Con.LG_Students__r.size()));
            Integer Index =0;
            for (LG_Student__c LGS: Con.LG_Students__r)
            {
               Boolean SCond = false;
               Boolean DemoCond = LGS.Status_in_LG__c=='Signed for Demo' ||LGS.Status_in_LG__c=='Done Demo';
               System.debug('@@@@@@@@@@@@ DemoCond ' +String.valueOf(DemoCond)); 
               if  (Con.LG_Students__r.size()>Index+1) 
                 SCond = Con.LG_Students__r[Index+1].Status_in_LG__c=='Registered'||Con.LG_Students__r[Index+1].Status_in_LG__c=='Completed'
                   ||Con.LG_Students__r[Index+1].Status_in_LG__c=='Drop-Out'; 
                if (DemoCond)
                {
                    Student_Statistics__c ss = new Student_Statistics__c (
                        Demo_BC__c =  LGS.Base_Course__c,
                        Demo_Base_Course_LKG__c =LGS.LG__r.Large_Group__c,
                        Demo_Date__c = LGS.Student_Course_End_Date__c,
                        Demo_LG__c=LGS.LG__r.Name,
                        Demo_LGS__c=LGS.Id,
                        DemoKey__c = (Id)LGS.Id,
                        Demo_Teacher__c = LGS.LG__r.Teacher__r.Name,
                        Student__c = Con.Id,
                        Franchisee__c=LGS.LG__r.Franchisee__r.Name,
                        MF_Name__c=LGS.LG__r.Franchisee__r.MF_Name__c,
                        MFID18__c= (Id)LGS.LG__r.Franchisee__r.MF_ID__c,
                        BC__c ='#Not Registered',  
                        Date__c=null,
                        Standard_Course_LG__c = null,
                        Standard_LGS__c =null,
                        Teacher__c=null,
                        Success_Batch__c=0
                        
                    );
                    System.debug('@@@@@@@@@@@@@ Find Demo  ');
                        if (SCond){
                            ss.BC__c =  Con.LG_Students__r[Index+1].Base_Course__c;
                            ss.Date__c =  Con.LG_Students__r[Index+1].Student_Course_Start_Date__c; 
                            ss.Standard_Course_LG__c =  Con.LG_Students__r[Index+1].LG__r.Name;   
                            ss.Standard_LGS__c =   Con.LG_Students__r[Index+1].Id; 
                            ss.Teacher__c = Con.LG_Students__r[Index+1].LG__r.Teacher__r.Name;
                            ss.Success_Batch__c = 1; 
                        }
                    SSToUpsert.add(ss);                     
                }
                
                Index++;  
            }
            
        }
        Database.UpsertResult[] sr = Database.upsert(SSToUpsert,f,false);   
        //Insert SSToUpsert ;
    }
    global void finish(Database.BatchableContext BC){
        Database.executeBatch(new RSAnalytics(), 2000);
    } 
}