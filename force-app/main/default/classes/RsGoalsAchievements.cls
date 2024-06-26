/*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name:            RsGoalsAchievements.cls
Description:     Goals And Achievements  Report
Date             Author          Summary of Changes 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
23-05-2017     Rashad Saeed  Initial Implementation 
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
public with sharing class RsGoalsAchievements {
    Public List <GA> GAChart {get;set;}
    Public List <GA> GAScoolYearChart {get;set;}
    Public Boolean displaychart {get;set;}
    Public Boolean displayTable {get;set;}
    Public String AccountType {get;set;}
    Public Account ChooseAccount {get;set;}
    public String rViewOption{get;set;}
    Public RsGoalsAchievements (ApexPages.StandardController controller)
    {
        rViewOption='CalendarYear';
        ChooseAccount = new Account();
        GAChart = new List <GA>();
        GAScoolYearChart = new List <GA>();
        GAScoolYearChart.add(new GA(550,'Start Point',0,0,0,0,0,0,0));
        displayTable = false;   
        displaychart =true;
        if (ApexPages.currentPage().getParameters().get('id')<>null) {
            ChooseAccount.ParentId = ApexPages.currentPage().getParameters().get('id');  
            CalcPram(ApexPages.currentPage().getParameters().get('id'));            
        }
    }
    Public PageReference ClacParam()
    {
        try{
            System.debug('@@@@@@@@@@ ClacParam Start');
            rViewOption='CalendarYear';
            GAScoolYearChart.clear();
            GAChart.clear();
            Account rAccount = new Account ();
            Id CalculatedStudentRT = Schema.SObjectType.Group_Income_Per_Month__c.getRecordTypeInfosByName().get('Calculated Student').getRecordTypeId();
            
            rAccount = [select Account_Type__c,Name,Id from Account where Id =: ChooseAccount.ParentId];
            AccountType=rAccount.Account_Type__c;
            String Goalsquery='select sUM (Goals__c)Goals,sum(Total_Calculated_students__c)CalculatedStudents,sum(Total_Actual_students__c)TActualStudents,CALENDAR_YEAR(Date__c)Year,CALENDAR_MONTH (Date__c)MONTH,sum(Actual_students_LKG__c)ActLKG,sum(Actual_students_Non_LKG__c)ActNonLKG,sum(Calculated_Students_LKG__c)CalculatedStudentsLKG,sum(Calculated_Students_NON_LKG__c)CalculatedStudentsNoNLKG,Sum(Drop_Out__c)DropOut from Analytics__c where ';
            Integer CurrentYear =  System.today().year();
            CurrentYear = CurrentYear - 4 ;
            // init wrraper 
            Map <Integer,Integer> FindMaxIndex = new Map <Integer,Integer>();
            for (integer i = CurrentYear;i<CurrentYear+5;i++)
            {
                GAChart.add(new GA(0,String.valueOf(i),0,0,0,0,0,0,0));  
                //FindMaxIndex.put (i,0); // year and index of max 
            }
            if (AccountType <>'MF'){
                Goalsquery += ' AccountId__c=\''+rAccount.Id+'\''; 
            }
            else
                Goalsquery += ' AccountId__c<>\''+rAccount.Id+'\''+'And MF_ID__c=\''+rAccount.Id+'\''; 
            Goalsquery+=' And Date__c >= LAST_N_YEARS:4  group by CALENDAR_YEAR(Date__c),CALENDAR_MONTH (Date__c) order by CALENDAR_YEAR(Date__c) Asc';
            System.debug(Goalsquery);
            AggregateResult[] rGoals = Database.query(Goalsquery); 
            Map <Integer,Integer> MFrGoalsIndexByYear = new Map <Integer,Integer>();
            AggregateResult[] MFrGoals = [SELECT Sum(Goal__c)Goals,CALENDAR_YEAR(Start_Date__c)Year  from Agreement_Goal__c where Agreement__r.From_Franchisee__c=:rAccount.Id and Start_Date__c >= LAST_N_YEARS:4  and Start_Date__c <=NEXT_N_YEARS:1 GROUP BY CALENDAR_YEAR(Start_Date__c) Order By CALENDAR_YEAR(Start_Date__c)];
            if (AccountType=='MF'){
                for(Integer i=0,j=0; i<MFrGoals.size();i++){
                    MFrGoalsIndexByYear.put ((Integer)MFrGoals[i].get('Year'),i);
                }
                
            }
            
            if (!rGoals.isEmpty()){
                decimal Max =(decimal)GlobalHelperMethods.ifnull((decimal)rGoals[0].get('TActualStudents'));
                for(Integer i=0,j=0; i<rGoals.size();i++){
                    if (i+1 <rGoals.size()) 
                        if ((Integer)rGoals[i].get('Year')==(Integer)rGoals[i+1].get('Year'))
                    {
                        if ((decimal)rGoals[i].get('TActualStudents') >=Max)
                        {
                            FindMaxIndex.PUT((Integer)rGoals[i].get('Year'),i);
                            Max = (decimal)rGoals[i].get('TActualStudents');
                            System.debug('Max '+Max+'  '+(decimal)rGoals[i].get('TActualStudents'));
                        }
                    }
                    else
                        Max=0;
                    
                    GAChart.get((integer)rGoals[i].get('Year')-CurrentYear).putDrop_Out((decimal)GlobalHelperMethods.ifnull((decimal)rGoals[i].get('DropOut'))); 
                }
                /*if ()
GAChart.get((integer)ar.get('Year')-CurrentYear).putActualStudents((decimal)ar.get('TActualStudents'),(Integer)ar.get('Year'));
GAChart.get((integer)ar.get('Year')-CurrentYear).putCalculatedStudents((decimal)ar.get('CalculatedStudents'));*/
                
            }           
            
            for (integer i :FindMaxIndex.KeySet())
            {
                
                System.debug(rGoals[FindMaxIndex.get(i)].get('TActualStudents')+' '+i);
                
                GAChart.get(i-CurrentYear).putActualStudents(GlobalHelperMethods.ifnull((decimal)rGoals[FindMaxIndex.get(i)].get('TActualStudents')) );// Calculate total Actual student 
                GAChart.get(i-CurrentYear).PutActual_StudentsLKG(GlobalHelperMethods.ifnull((decimal)rGoals[FindMaxIndex.get(i)].get('ActLKG')) );// Calculate  Actual student LKG 
                GAChart.get(i-CurrentYear).PutActual_StudentsNonLKG(GlobalHelperMethods.ifnull((decimal)rGoals[FindMaxIndex.get(i)].get('ActNonLKG')) );// Calculate  Actual student NON LKG 
                //GlobalHelperMethods.ifnull((decimal)rGoals[FindMaxIndex.get(i)].get('CalculatedStudents')) 
                GAChart.get(i-CurrentYear).putCalculatedStudents(GlobalHelperMethods.ifnull((decimal)rGoals[FindMaxIndex.get(i)].get('CalculatedStudents')) ); //Calculate total Calculated Students 
                GAChart.get(i-CurrentYear).putCalculated_StudentsLKG(GlobalHelperMethods.ifnull((decimal)rGoals[FindMaxIndex.get(i)].get('CalculatedStudentsLKG')) );// Calculate  Calculated Students   LKG 
                GAChart.get(i-CurrentYear).putCalculated_StudentsNonLKG(GlobalHelperMethods.ifnull((decimal)rGoals[FindMaxIndex.get(i)].get('CalculatedStudentsNoNLKG')) );// Calculate  Calculated Students   NON LKG  
                if (AccountType<>'MF')
                    GAChart.get(i-CurrentYear).putGoal(GlobalHelperMethods.ifnull((decimal)rGoals[FindMaxIndex.get(i)].get('Goals')) );
                else 
                    //MFrGoalsIndexByYear
                    try{
    GAChart.get(i-CurrentYear).putGoal(GlobalHelperMethods.ifnull((decimal)MFrGoals[MFrGoalsIndexByYear.get(i)].get('Goals')) );
    }catch(exception e){}
            }
        }catch(exception e){} 
        return null;
    } 
    
    Public PageReference CalcPram(id AccountId){
        System.debug('@@@@@@@@@@ ClacParam Start');
        rViewOption='CalendarYear';
        GAScoolYearChart.clear();
        GAChart.clear();
        Account rAccount = new Account ();
        Id CalculatedStudentRT = Schema.SObjectType.Group_Income_Per_Month__c.getRecordTypeInfosByName().get('Calculated Student').getRecordTypeId();
        
        rAccount = [select Account_Type__c,Name,Id from Account where Id =: ChooseAccount.ParentId];
        AccountType=rAccount.Account_Type__c;
        String Goalsquery='select sUM (Goals__c)Goals,sum(Total_Calculated_students__c)CalculatedStudents,sum(Total_Actual_students__c)TActualStudents,CALENDAR_YEAR(Date__c)Year,CALENDAR_MONTH (Date__c)MONTH,sum(Actual_students_LKG__c)ActLKG,sum(Actual_students_Non_LKG__c)ActNonLKG,sum(Calculated_Students_LKG__c)CalculatedStudentsLKG,sum(Calculated_Students_NON_LKG__c)CalculatedStudentsNoNLKG,Sum(Drop_Out__c)DropOut from Analytics__c where ';
        Integer CurrentYear =  System.today().year();
        CurrentYear = CurrentYear - 4 ;
        // init wrraper 
        Map <Integer,Integer> FindMaxIndex = new Map <Integer,Integer>();
        for (integer i = CurrentYear;i<CurrentYear+5;i++)
        {
            GAChart.add(new GA(0,String.valueOf(i),0,0,0,0,0,0,0));  
            //FindMaxIndex.put (i,0); // year and index of max 
        }
        if (AccountType <>'MF'){
            Goalsquery += ' AccountId__c=\''+rAccount.Id+'\''; 
        }
        else
            Goalsquery += ' AccountId__c<>\''+rAccount.Id+'\''+'And MF_ID__c=\''+rAccount.Id+'\''; 
        Goalsquery+=' And Date__c >= LAST_N_YEARS:4 group by CALENDAR_YEAR(Date__c),CALENDAR_MONTH (Date__c) order by CALENDAR_YEAR(Date__c) Asc';
        System.debug(Goalsquery);
        AggregateResult[] rGoals = Database.query(Goalsquery); 
        Map <Integer,Integer> MFrGoalsIndexByYear = new Map <Integer,Integer>();
        AggregateResult[] MFrGoals = [SELECT Sum(Goal__c)Goals,CALENDAR_YEAR(Start_Date__c)Year  from Agreement_Goal__c where Agreement__r.From_Franchisee__c=:rAccount.Id and Start_Date__c >= LAST_N_YEARS:4  and Start_Date__c <=NEXT_N_YEARS:1 GROUP BY CALENDAR_YEAR(Start_Date__c) Order By CALENDAR_YEAR(Start_Date__c)];
        if (AccountType=='MF'){
            for(Integer i=0,j=0; i<MFrGoals.size();i++){
                MFrGoalsIndexByYear.put ((Integer)MFrGoals[i].get('Year'),i);
            }
            
        }
        
        if (!rGoals.isEmpty()){
            decimal Max =(decimal)GlobalHelperMethods.ifnull((decimal)rGoals[0].get('TActualStudents'));
            for(Integer i=0,j=0; i<rGoals.size();i++){
                if (i+1 <rGoals.size()) 
                    if ((Integer)rGoals[i].get('Year')==(Integer)rGoals[i+1].get('Year'))
                {
                    if ((decimal)rGoals[i].get('TActualStudents') >=Max)
                    {
                        FindMaxIndex.PUT((Integer)rGoals[i].get('Year'),i);
                        Max = (decimal)rGoals[i].get('TActualStudents');
                        System.debug('Max '+Max+'  '+(decimal)rGoals[i].get('TActualStudents'));
                    }
                }
                else
                    Max=0;
                
                GAChart.get((integer)rGoals[i].get('Year')-CurrentYear).putDrop_Out((decimal)GlobalHelperMethods.ifnull((decimal)rGoals[i].get('DropOut'))); 
            }
            /*if ()
GAChart.get((integer)ar.get('Year')-CurrentYear).putActualStudents((decimal)ar.get('TActualStudents'),(Integer)ar.get('Year'));
GAChart.get((integer)ar.get('Year')-CurrentYear).putCalculatedStudents((decimal)ar.get('CalculatedStudents'));*/
            
        }           
        
        for (integer i :FindMaxIndex.KeySet())
        {
            
            System.debug(rGoals[FindMaxIndex.get(i)].get('TActualStudents')+' '+i);
            
            GAChart.get(i-CurrentYear).putActualStudents(GlobalHelperMethods.ifnull((decimal)rGoals[FindMaxIndex.get(i)].get('TActualStudents')) );// Calculate total Actual student 
            GAChart.get(i-CurrentYear).PutActual_StudentsLKG(GlobalHelperMethods.ifnull((decimal)rGoals[FindMaxIndex.get(i)].get('ActLKG')) );// Calculate  Actual student LKG 
            GAChart.get(i-CurrentYear).PutActual_StudentsNonLKG(GlobalHelperMethods.ifnull((decimal)rGoals[FindMaxIndex.get(i)].get('ActNonLKG')) );// Calculate  Actual student NON LKG 
            //GlobalHelperMethods.ifnull((decimal)rGoals[FindMaxIndex.get(i)].get('CalculatedStudents')) 
            GAChart.get(i-CurrentYear).putCalculatedStudents(GlobalHelperMethods.ifnull((decimal)rGoals[FindMaxIndex.get(i)].get('CalculatedStudents')) ); //Calculate total Calculated Students 
            GAChart.get(i-CurrentYear).putCalculated_StudentsLKG(GlobalHelperMethods.ifnull((decimal)rGoals[FindMaxIndex.get(i)].get('CalculatedStudentsLKG')) );// Calculate  Calculated Students   LKG 
            GAChart.get(i-CurrentYear).putCalculated_StudentsNonLKG(GlobalHelperMethods.ifnull((decimal)rGoals[FindMaxIndex.get(i)].get('CalculatedStudentsNoNLKG')) );// Calculate  Calculated Students   NON LKG  
            if (AccountType<>'MF')
                GAChart.get(i-CurrentYear).putGoal(GlobalHelperMethods.ifnull((decimal)rGoals[FindMaxIndex.get(i)].get('Goals')) );
            else 
                //MFrGoalsIndexByYear
               try{
                   GAChart.get(i-CurrentYear).putGoal(GlobalHelperMethods.ifnull((decimal)MFrGoals[MFrGoalsIndexByYear.get(i)].get('Goals')) );
                  }catch(exception e){}
        }
        return null;
        
    } 
    Public class GA 
    {
        Public String ryear {get;set;}
        Public decimal Goal {get;set;}
        Public decimal Actual_Students {get;set;}
        Public decimal Calculated_Students {get;set;}
        Public decimal Calculated_StudentsLKG {get;set;}
        Public decimal Calculated_StudentsNonLKG {get;set;}
        Public decimal Actual_StudentsLKG {get;set;}
        Public decimal Actual_StudentsNonLKG {get;set;}
        Public decimal Drop_Out {get;set;}
        
        Public GA(decimal Goal , string ryear,integer ActualStudents,decimal CalculatedStudents,integer Drop_Out,decimal Calculated_StudentsLKG
                  ,decimal Calculated_StudentsNonLKG,decimal Actual_StudentsLKG,decimal Actual_StudentsNonLKG)
        {
            this.Goal = Goal.setScale(2);  
            this.ryear = ryear; 
            this.Actual_Students = ActualStudents;
            this.Calculated_Students = CalculatedStudents;
            this.Drop_Out=Drop_Out; 
            this.Calculated_StudentsLKG=Calculated_StudentsLKG; 
            this.Calculated_StudentsNonLKG=Calculated_StudentsNonLKG; 
            this.Actual_StudentsLKG=Actual_StudentsLKG; 
            this.Actual_StudentsNonLKG=Actual_StudentsNonLKG; 
            
        }
        Public Void putGoal (decimal Goal){
            this.Goal =Goal;
        }
        Public Void putActualStudents (decimal ActualStudents,integer Year){
            if (this.ryear == String.valueOf(Year) && this.Actual_Students<ActualStudents)
                this.Actual_Students =ActualStudents.setScale(2);
        }
        Public Void putActualStudents (decimal ActualStudents){
            this.Actual_Students =ActualStudents.setScale(2);
        }
        Public Void putCalculatedStudents (decimal CalculatedStudents){
            this.Calculated_Students =(CalculatedStudents).setScale(2);
            // this.Gap = this.Goal-CalculatedStudents;
        }
        Public Void putDrop_Out (decimal Drop_Out){
            this.Drop_Out +=Drop_Out;
        }
        Public Void putCalculated_StudentsLKG (decimal Calculated_StudentsLKG){
            if (Calculated_StudentsLKG<>null)
                this.Calculated_StudentsLKG=(Calculated_StudentsLKG).setScale(2); 
        }
        Public Void putCalculated_StudentsNonLKG (decimal Calculated_StudentsNonLKG){
            this.Calculated_StudentsNonLKG=(Calculated_StudentsNonLKG).setScale(2); 
        }
        
        Public Void putActual_StudentsLKG (decimal Actual_StudentsLKG){
            this.Actual_StudentsLKG=Actual_StudentsLKG; 
        }
        Public Void putActual_StudentsNonLKG(decimal Actual_StudentsNonLKG){
            this.Actual_StudentsNonLKG=Actual_StudentsNonLKG; 
        }
        
        
        
    }
    public void displaychart()
    {
        System.debug('@@@@@@@@@@@@@@@@ ReporType '+rViewOption);
        system.debug('@@@@@@@@@@@@@@ GAChart '+GAChart);
        if (GAScoolYearChart.size()<=1&&ChooseAccount.ParentId<>null)
            ClacSchoolYearParam();
        
        //displayTable = true;
        //return null;
    }
    public List<SelectOption> getViewOption() {
        List<SelectOption> ReporType = new List<SelectOption>();
        ReporType.add(new SelectOption('CalendarYear','Calendar Year'));
        ReporType.add(new SelectOption('SchoolYear','School Year'));
        return ReporType;
    }
    Public void ClacSchoolYearParam()
    {
     System.debug('@@@@@@@@@@ ClacSchoolYearParam Start');
        
        GAScoolYearChart.clear();
        Account rAccount = new Account ();
        Id CalculatedStudentRT = Schema.SObjectType.Group_Income_Per_Month__c.getRecordTypeInfosByName().get('Calculated Student').getRecordTypeId();
        rAccount = [select Account_Type__c,Name,Id from Account where Id =: ChooseAccount.ParentId];
        AccountType=rAccount.Account_Type__c;
        String Goalsquery='select sUM (Goals__c)Goals,sum(Total_Calculated_students__c)CalculatedStudents,sum(Total_Actual_students__c)TActualStudents,School_Year__c,CALENDAR_MONTH (Date__c)MONTH,sum(Actual_students_LKG__c)ActLKG,sum(Actual_students_Non_LKG__c)ActNonLKG,sum(Calculated_Students_LKG__c)CalculatedStudentsLKG,sum(Calculated_Students_NON_LKG__c)CalculatedStudentsNoNLKG,Sum(Drop_Out__c)DropOut from Analytics__c where ';
        Integer CurrentYear =  System.today().year();
        CurrentYear = CurrentYear - 4 ;
        // init wrraper 
        Map <String,Integer> FindMaxIndex = new Map <String,Integer>();
       
        if (AccountType <>'MF'){
            Goalsquery += ' AccountId__c=\''+rAccount.Id+'\''; 
        }
        else
            Goalsquery += ' AccountId__c<>\''+rAccount.Id+'\''+'And MF_ID__c=\''+rAccount.Id+'\''; 
        Goalsquery+=' And Date__c >= LAST_N_YEARS:4   group by School_Year__c ,CALENDAR_MONTH (Date__c) order by School_Year__c  Asc';
        System.debug(Goalsquery);
        AggregateResult[] rGoals = Database.query(Goalsquery); 
        Map <String,decimal> MFrGoalsIndexByYear = new Map <String,decimal>();
        Map <String,Integer> Index_GAScoolYearChart = new Map <String,Integer> ();
        AggregateResult[] MFrGoals = [SELECT Sum(Goal__c)Goals,School_Year_Ag__c  from Agreement_Goal__c where Agreement__r.From_Franchisee__c=:rAccount.Id and Start_Date__c >= LAST_N_YEARS:4  and Start_Date__c <=NEXT_N_YEARS:1 GROUP BY School_Year_Ag__c  Order By School_Year_Ag__c ];
        
        if (AccountType=='MF'){
            for(Integer i=0,j=0; i<MFrGoals.size();i++){
                MFrGoalsIndexByYear.put ((String)MFrGoals[i].get('School_Year_Ag__c'),(decimal)MFrGoals[i].get('Goals'));
                 
                
            }
            
        }
        
        if (!rGoals.isEmpty()){
            decimal Max =(decimal)GlobalHelperMethods.ifnull((decimal)rGoals[0].get('TActualStudents'));
            
            for(Integer i=0,j=0; i<rGoals.size();i++){
                Index_GAScoolYearChart.put((String)rGoals[i].get('School_Year__c'),i);
                if (i+1 <rGoals.size()) 
                    if ((String)rGoals[i].get('School_Year__c')==(String)rGoals[i+1].get('School_Year__c'))
                {
                    if ((decimal)rGoals[i].get('TActualStudents') >=Max)
                    {
                        FindMaxIndex.PUT((String)rGoals[i].get('School_Year__c'),i);
                        Max = (decimal)rGoals[i].get('TActualStudents');
                        System.debug('Max '+Max+'  '+(decimal)rGoals[i].get('TActualStudents'));
                    }
                }
                else
                    Max=0;
               
                //GAScoolYearChart.get((String)rGoals[i].get('School_Year__c')).putDrop_Out((decimal)GlobalHelperMethods.ifnull((decimal)rGoals[i].get('DropOut'))); 
            }
         
        }           
        Integer Index = 0;
        for (String i :FindMaxIndex.KeySet())
        {
            GAScoolYearChart.add(new GA(0,i,0,0,0,0,0,0,0));     
            //GAScoolYearChart.get(Index).putActualStudents(GlobalHelperMethods.ifnull((decimal)rGoals[FindMaxIndex.get(i)].get('TActualStudents')) );
            GAScoolYearChart.get(Index).putActualStudents(GlobalHelperMethods.ifnull((decimal)rGoals[FindMaxIndex.get(i)].get('TActualStudents')) );// Calculate total Actual student 
            GAScoolYearChart.get(Index).PutActual_StudentsLKG(GlobalHelperMethods.ifnull((decimal)rGoals[FindMaxIndex.get(i)].get('ActLKG')) );// Calculate  Actual student LKG 
            GAScoolYearChart.get(Index).PutActual_StudentsNonLKG(GlobalHelperMethods.ifnull((decimal)rGoals[FindMaxIndex.get(i)].get('ActNonLKG')) );// Calculate  Actual student NON LKG 
            //GlobalHelperMethods.ifnull((decimal)rGoals[FindMaxIndex.get(i)].get('CalculatedStudents')) 
            GAScoolYearChart.get(Index).putCalculatedStudents(GlobalHelperMethods.ifnull((decimal)rGoals[FindMaxIndex.get(i)].get('CalculatedStudents')) ); //Calculate total Calculated Students 
            GAScoolYearChart.get(Index).putCalculated_StudentsLKG(GlobalHelperMethods.ifnull((decimal)rGoals[FindMaxIndex.get(i)].get('CalculatedStudentsLKG')) );// Calculate  Calculated Students   LKG 
            GAScoolYearChart.get(Index).putCalculated_StudentsNonLKG(GlobalHelperMethods.ifnull((decimal)rGoals[FindMaxIndex.get(i)].get('CalculatedStudentsNoNLKG')) );// Calculate  Calculated Students   NON LKG  
            if (AccountType<>'MF')
                GAScoolYearChart.get(Index).putGoal(GlobalHelperMethods.ifnull((decimal)rGoals[FindMaxIndex.get(i)].get('Goals')) );
            else 
                //MFrGoalsIndexByYear
                 //System.debug(MFrGoalsIndexByYear.get(i));
                 try{
                GAScoolYearChart.get(Index).putGoal(GlobalHelperMethods.ifnull(MFrGoalsIndexByYear.get(i)));
                }catch(exception e){}
            Index++;
        }
        
        
    } 
    public PageReference exportToExcel() {
        return Page.RsGoalsAchievementsExcel;
    }
}