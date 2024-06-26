/*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name:            RSAnalytics.cls
Description:     RSAnalytics :   Goals 
Date             Author          Summary of Changes 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
06-Feb-2017     Rashad Saeed  Initial Implementation 
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

global class RSAnalytics Implements Database.Batchable<sObject>{
   global  Id Calculated_Student = Schema.SObjectType.Group_Income_Per_Month__c.getRecordTypeInfosByName().get('Calculated Student').getRecordTypeId(); 
    global Database.QueryLocator start(Database.BatchableContext bc) {
       
        String SQuery = 'select Agreement__r.School_Year_Start_Month__c,RCParentKey__c,From_Franchisee_Account_Type__c,MF_ID__c,Royalty_Month__c,RCUniqKey__C,Id ,From_Franchisee__c,Agreement__c FROM Royalties_Calculation__c where Royalty_Month__c >=LAST_YEAR and Royalty_Month__c <=this_Year order By From_Franchisee__r.Level__C';
        
        return Database.getQueryLocator(SQuery); 
    } 
    global void execute(Database.BatchableContext BC, List<Royalties_Calculation__c> scope){
     	Schema.SObjectField f = Analytics__c.Fields.Key__c	;
        Map <String,Integer>ActualStudentLKG = new Map <String,Integer>();
        Map <String,Integer>ActualStudentNonLKG = new Map <String,Integer>();
        Set <String> rcKeys = new Set <String>();
        MAP <String,Analytics__c> AnList = new Map<String,Analytics__c>();
        Set <id> AggIds = new Set <Id>();
        Set <String> ParentKeys = new Set <String>();
        For (Royalties_Calculation__c Rc : Scope){
           rcKeys.add(RC.RCUniqKey__C);
           AggIds.add((id)rc.Agreement__c) ;
           ParentKeys.add(rc.RCParentKey__c+'_Goals') ;
            String SCYear ='';
            if (rc.Royalty_Month__c.month()<rc.Agreement__r.School_Year_Start_Month__c ){ // logic from School_Year__c formula on Agreement Goal .
                SCYear=String.ValueOf(rc.Royalty_Month__c.year()-1)+'-'+rc.Royalty_Month__c.year();
            } 
            else
               SCYear=rc.Royalty_Month__c.year()+'-'+String.ValueOf(rc.Royalty_Month__c.year()+1); 
            
           AnList.put(RC.RCUniqKey__C+'_Goals',new Analytics__c(Royalties_Calculation__c=Rc.Id,Key__c=rc.RCUniqKey__c+'_Goals',Type__c='1',Date__c=rc.Royalty_Month__c
                                                                ,MF_ID__c=(Id)rc.MF_ID__c,AccountId__c=(Id)rc.From_Franchisee__c,Agreement__c=rc.Agreement__c,
                                                                School_Year__c=SCYear
                                                            )); 
          
        }
        //Map <Id,Analytics__c> PrentAnalytics = new Map <Id,Analytics__c>([select Id,Name,Key__c from Analytics__c where Key__c in : ParentKeys]);
        
        for (AggregateResult ar :[select sum(Drop_Out__c)Drop_Out,SUM(Calculated_Student__c)Calculated_Student,LG__r.Large_Group__c , Agreement__c,COUNT_DISTINCT(Student__c)Students,CALENDAR_MONTH (Royalty_Start_Date__c)MONTH,CALENDAR_Year (Royalty_Start_Date__c)Year
                                  from Group_Income_Per_Month__c where GIPMRCKey__c in : rcKeys and Agreement__c in : AggIds and lG__r.Declared_Number_of_Students__c = null
                                  and recordtypeId=:Calculated_Student group by Agreement__c, CALENDAR_MONTH (Royalty_Start_Date__c),CALENDAR_Year (Royalty_Start_Date__c),LG__r.Large_Group__c
                             ])
        {
            System.debug(Ar);
            String Key = (Id)Ar.get('Agreement__c')+'_'+String.ValueOf((Integer)Ar.get('MONTH'))+'_'+String.ValueOf((Integer)Ar.get('Year'))+'_Goals';  
            AnList.Get(Key).Drop_Out__c =(decimal)Ar.get('Drop_Out');
            if (Ar.get('Large_Group__c')==false){
                //ActualStudentNonLKG.put(key, (Integer)Ar.get('Students'));
           		AnList.Get(Key).Actual_students_Non_LKG__c =(decimal)Ar.get('Students');
                AnList.Get(Key).Calculated_Students_NON_LKG__c =(DECIMAL)Ar.get('Calculated_Student');
            }
            else
            {
               AnList.Get(Key).Actual_students_LKG__c =(decimal)Ar.get('Students');
               AnList.Get(Key).Calculated_Students_LKG__c =(DECIMAL)Ar.get('Calculated_Student');
            }
        }
        for (AggregateResult ar :[select Agreement__c,SUM(Calculated_Student__c)Calculated_Student,Sum(Actual_Student_Number__c)Students,CALENDAR_MONTH (Royalty_Start_Date__c)MONTH,CALENDAR_Year (Royalty_Start_Date__c)Year
                                  from Group_Income_Per_Month__c where GIPMRCKey__c in : rcKeys and Agreement__c in : AggIds and lG__r.Declared_Number_of_Students__c >0  
                                  and recordtypeId=:Calculated_Student group by Agreement__c, CALENDAR_MONTH (Royalty_Start_Date__c),CALENDAR_Year (Royalty_Start_Date__c)
                             ])
        {
            System.debug(Ar);
            String Key = (Id)Ar.get('Agreement__c')+'_'+String.ValueOf((Integer)Ar.get('MONTH'))+'_'+String.ValueOf((Integer)Ar.get('Year'))+'_Goals'; 
            
            AnList.Get(Key).Actual_students_LKG__c =GlobalHelperMethods.ifnull(AnList.Get(Key).Actual_students_LKG__c )+GlobalHelperMethods.ifnull((decimal)Ar.get('Students'));
            AnList.Get(Key).Calculated_Students_LKG__c =GlobalHelperMethods.ifnull(AnList.Get(Key).Calculated_Students_LKG__c)+GlobalHelperMethods.ifnull((DECIMAL)Ar.get('Calculated_Student'));
        }
        for (AggregateResult ar : [SELECT Agreement__c,Sum(Goal__c)Goal,CALENDAR_YEAR(Start_Date__c)Year from Agreement_Goal__c
                                   where Agreement__c in : AggIds
                                   And Start_Date__c >=LAST_YEAR and Start_Date__c <=this_Year 
                                   GROUP BY Agreement__c,CALENDAR_YEAR(Start_Date__c)
                                   Order By CALENDAR_YEAR(Start_Date__c)]) 
        {
            
            for (Integer i=1,j=0;i<13;i++){
               String Key = (Id)Ar.get('Agreement__c')+'_'+String.ValueOf(i)+'_'+String.ValueOf((Integer)Ar.get('Year'))+'_Goals';
               if (AnList.Get(Key)<>Null&&Ar.get('Goal')<>null )
               	AnList.Get(Key).Goals__c =(decimal)Ar.get('Goal'); 
            }
            
        }      
        //for ()
       //Upsert  AnList.Values();
       Database.UpsertResult[] sr = Database.upsert(AnList.Values(),f,false);  
      
    }
    global void finish(Database.BatchableContext BC){
        
    } 
}