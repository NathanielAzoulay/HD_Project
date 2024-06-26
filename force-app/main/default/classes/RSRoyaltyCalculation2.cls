/*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name:            RSRoyaltyCalculation2.cls
Description:     Role Up Sammary the RC, Claculate the RC Params.    
Date             Author          Summary of Changes 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
17-OCT-2017     Rashad Saeed  Initial Implementation 
21-JAN-2018     Rashad Saeed  Add ReGenerate function .
15-Feb-2022     Avraham Dasa  remark line 19.
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
global class  RSRoyaltyCalculation2 implements Database.Batchable<sObject>  , Database.Stateful {
    global String MFID {get; set;} 
    global  Boolean ReGenerate {get; set;}
    global String Query;
    global List<HD_Log__c> errorLogs  {get; set;}
    global RSRoyaltyCalculation2 (){ 
        String GlobalQuery = 'SELECT Expiry_Date__c,Direct_Franchisee_Agreement__r.From_Franchisee_Type__c,Direct_Franchisee_Agreement__c,Id,From_Franchisee__c,Direct_Franchisee__c,CurrencyIsoCode ';
        GlobalQuery+=' FROM Agreement__c WHERE Royalty_Type__c = \'1 - Standard\'';
        //GlobalQuery +=' And Direct_Franchisee_Agreement__c <> Null';  
        //GlobalQuery += ' And Expiry_Date__c >=LAST_YEAR';
        this.Query = GlobalQuery; 
       
    }
    global RSRoyaltyCalculation2 (String Q){
        this.Query= q;
       
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
         errorLogs = new List<HD_Log__c>();
        if (MFID<>null)
           Query+=' And MF_ID__c ='+'\''+MFID+'\'';
        Query+=' Order By Level__c DESC';
        System.debug('@@@@@@@@@ Query '+ Query);  
        /*String query = 'select Id from Royalties_Calculation__c'; 
        query+=' Where Royalty_Month__c <=NEXT_YEAR And Royalty_Month__c >=LAST_YEAR';*/
        /*String Query = 'SELECT Direct_Franchisee_Agreement__r.From_Franchisee_Type__c,Direct_Franchisee_Agreement__c,Id,From_Franchisee__c,Direct_Franchisee__c,CurrencyIsoCode FROM Agreement__c WHERE Royalty_Type__c = \'1 - Standard\''; 
        Query+=' And MF_ID__c =\'001D000000tPE9J\'';*/
        return Database.getQueryLocator(query); 
    }
    global void execute(Database.BatchableContext BC, List<Agreement__c> scope){
        String RCquery = GlobalHelperMethods.getQueryString(new Royalties_Calculation__c()) + ' Where Agreement__c In :AggIDs And RCUniqKey__c in :RCKeys '; 
        //RCquery+= ' Order By CALENDAR_MONTH(Royalty_Month__c),CALENDAR_Year(Royalty_Month__c)';
        Set <Id> AggIDs = new Set <Id>();     
        Set <String> RCKeys = new Set <String>();
        Map <String ,decimal> MapKeyIncome = new Map <String ,decimal>();
        Map <String ,Decimal> MapKeyActual_Student = new Map <String ,Decimal>();// Actual_Student
        Map <String ,Decimal> MapKeyCalculated_Student = new Map <String ,Decimal>();// Calculated_Student
        Map <String ,Date> MapKeyDate = new Map <String ,Date>();
        Map <String ,decimal> MapKeyGrossIncome= new Map <String ,decimal>();// Gross Income
        List <Royalties_Calculation__c>UpdateRCList = new List <Royalties_Calculation__c>();
        for (Agreement__c Agg :scope )
        {
            AggIDs.add((Id)Agg.id);
        }
        AggregateResult[] groupedResults = [select Sum(Income_Formula_Number__c)GrossIncome ,sum (Royalty_Formula_Number__c) Income ,CALENDAR_MONTH(Royalty_Month__c)MONTH,
                                            CALENDAR_Year(Royalty_Month__c)YEAR,sum (Actual_Students__c)Actual_Student,Agreement__r.Direct_Franchisee_Agreement__c
                                            ,sum (Calculated_Students__c)Calculated_Student
                                            From Royalties_Calculation__c   
                                            where Royalty_Month__c <=NEXT_YEAR
                                            And Royalty_Month__c >=LAST_YEAR
                                            and Relevant_RC__c = true
                                            and InActive__c = false
                                            and Agreement__r.Direct_Franchisee_Agreement__c In : AggIDs
                                            Group By CALENDAR_MONTH(Royalty_Month__c),CALENDAR_Year(Royalty_Month__c),Agreement__r.Direct_Franchisee_Agreement__c
                                            Order By CALENDAR_Year(Royalty_Month__c),CALENDAR_MONTH(Royalty_Month__c) ];
        
    If (groupedResults.Size()>0){
        for (AggregateResult ar : groupedResults){
            String Key = (Id)Ar.get('Direct_Franchisee_Agreement__c')+'_'+String.ValueOf((Integer)Ar.get('MONTH'))+'_'+String.ValueOf((Integer)Ar.get('Year'));
            RCKeys.add(Key); 
            MapKeyIncome.put (Key,(decimal)Ar.get('Income'));
            MapKeyGrossIncome.put (Key,(decimal)Ar.get('GrossIncome'));
            MapKeyDate.put(key, date.newinstance((Integer)Ar.get('YEAR'),(Integer)Ar.get('MONTH'), 1));
            MapKeyActual_Student.put(key,(Decimal)Ar.get('Actual_Student'));
            MapKeyCalculated_Student.put(key,(Decimal)Ar.get('Calculated_Student'));  
        }
        //Map<Id, Map<String, List<Agreement_Parameter__c>>> agreementParameterByType = RoyaltyCalculationProcessStep3.getAgreementParameterByType(AggIDs);
        //
        //
        Map<Id, Agreement__c> agreements = RoyaltyCalculationProcessStep2.getAgreementsInformation(AggIDs);
            Map<Id, Map<String, List<Agreement_Parameter__c>>> agreementParameterByType = RSRoyaltyCalculation.getAgreementParameterByType(AggIDs);
            Map<Id, Map<Date, Royalties_Fixed_Student__c>> fixPercent = new Map<Id, Map<Date, Royalties_Fixed_Student__c>>();
            for(Id agId : agreements.keySet()){
                fixPercent.put((Id)agId, new Map<Date, Royalties_Fixed_Student__c>());
                for(Royalties_Fixed_Student__c fp : agreements.get(agId).Royalties_Fixed_Student_Number_in_del__r){
                    fixPercent.get((Id)agId).put(fp.Month__c.toStartOfMonth(), fp);
                }
            }
        
        
        Map <Id,Royalties_Calculation__c> RCCalc = new Map <Id,Royalties_Calculation__c>((List<Royalties_Calculation__c>)Database.query(RCquery));
        Map <String,Decimal> exchangeRate =  RSRoyaltyCalculation.GetExchangeRate();
        for (Royalties_Calculation__c Rc : RCCalc.Values()) 
        {
            // Decimal percent = RoyaltyCalculationProcessStep3.getPercentByType(Rc.From_Franchisee_Account_Type__c, agreementParameterByType.get((ID)rc.Agreement__c));
            if (GlobalHelperMethods.ifnull(MapKeyIncome.get (RC.RCUniqKey__c))<>  Rc.RC_Income__c ||ReGenerate == true) {
                String KeyRate = Rc.eRate_Key__c +'_'+Rc.Royalty_Month__c.Month()+'_'+Rc.Royalty_Month__c.Year();
                if (exchangeRate.get (KeyRate)<>Null )
                    Rc.Exchange_Rate__c =exchangeRate.get (KeyRate);
                Rc.Gross_Income__c = GlobalHelperMethods.ifnull(MapKeyGrossIncome.get (Rc.RCUniqKey__c));
                Rc.RC_Income__c = GlobalHelperMethods.ifnull(MapKeyIncome.get (Rc.RCUniqKey__c));
                Rc.Calculated_Income__c = GlobalHelperMethods.ifnull (Rc.GIPM_Income__c )+  GlobalHelperMethods.ifnull (Rc.RC_Income__c ) ; 
                //Rc.Calculated_Percent__c = percent;  
                RC.RC_Calculated_Students__c = GlobalHelperMethods.ifnull(MapKeyCalculated_Student.get(RC.RCUniqKey__c));
                RC.RC_Actual_Students__c = GlobalHelperMethods.ifnull(MapKeyActual_Student.get(RC.RCUniqKey__c));
                //RC.Calculated_Royalties__c  = (percent / 100) * GlobalHelperMethods.ifnull(RC.RC_Income__c)+(percent / 100) * GlobalHelperMethods.ifnull(RC.GIPM_Income__c);
                RC.Actual_Students__c=GlobalHelperMethods.ifnull(RC.GIPM_Actual_Students__c)+rc.RC_Actual_Students__c;
                RC.Calculated_Students__c=GlobalHelperMethods.ifnull(RC.GIPM_Calculated_Students__c)+rc.RC_Calculated_Students__c;
                  Agreement__c relatedAgreement = agreements.get((Id)rc.Agreement__c);  
                
                // CALCULATE THE PERCENT
                
                // First Priority is by fixed percent if exist...
                if(fixPercent.containsKey((Id)rc.Agreement__c) && fixPercent.get((Id)rc.Agreement__c).containsKey(rc.Royalty_Month__c)){ // We know that the date is check on the 1 day of the month
                    
                    rc.Calculated_Percent__c = fixPercent.get(rc.Agreement__c).get(rc.Royalty_Month__c).Royalty_Percent__c;
                }else{
                    
                    // If not exist fixed percent, we need to identify which kind of percent calculation we should apply... 
                    if(!agreementParameterByType.get((Id)rc.Agreement__c).get('By Student').isEmpty()){ 
                        // if we are on By Student (when the Student_Count_Revenue__c <> null on the parameter exist) - The % is decreasing when the number 
                        // of calculated students is rising.
                        
                        if(rc.Calculated_Students__c == null){
                            rc.Calculated_Students__c = 0;
                        }
                        
                        List<Agreement_Parameter__c> params = agreementParameterByType.get(rc.Agreement__c).get('By Student');
                        Integer nroOfRows = 1;
                        List<Decimal> calculatedRows = new List<Decimal>();            
                        for(Integer i = 0; i < params.size(); i++){
                            
                            Decimal nroOfStudent = params[i].Student_Count_Revenue__c;
                            if(i+1 == params.size() /*we are on the last row*/ || params[i].Student_Count_Revenue__c > rc.Calculated_Students__c /*We reach the threshold*/){
                                // if we are on the last or the calculated student is less that the nro student (Student_Count_Revenue__c) defined on the parameter 
                                nroOfStudent = rc.Calculated_Students__c;
                            }
                            
                            if(i == 0){              
                                calculatedRows.add(params[0].Royalty_Percent__c * nroOfStudent);
                            }else{
                                calculatedRows.add(params[i].Royalty_Percent__c * (nroOfStudent - params[i-1].Student_Count_Revenue__c));
                            }
                            
                            if(params[i].Student_Count_Revenue__c > rc.Calculated_Students__c || i+1 == params.size()){
                                break; // We cut the iteration since we already calculate all possible percent (depending by the nro of GIPM_Calculated_Students__c)
                            }
                            nroOfRows++;
                        }
                        
                        Decimal percent = 0;
                        for(Integer i = 0; i < nroOfRows; i++){
                            percent += calculatedRows[i];
                        }  
                        
                        if(rc.Calculated_Students__c == 0){
                            rc.Calculated_Percent__c = 0; 
                            if(rc.Calculated_Income__c > 0){
                                rc.Calculated_Percent__c = 14; // By Default 
                            }
                        }else{
                            rc.Calculated_Percent__c = percent / rc.Calculated_Students__c;
                        }
                    } else {
                        
                        rc.Calculated_Percent__c = RSRoyaltyCalculation.getPercentByType(rc.From_Franchisee_Account_Type__c,agreementParameterByType.get(rc.Agreement__c));
                        
                        String espType;
                        if(!agreementParameterByType.get(rc.Agreement__c).get('By Type').isEmpty()){
                            
                            List<Agreement_Parameter__c> params = agreementParameterByType.get(rc.Agreement__c).get('By Type');          
                            for(Integer i = 0; i < params.size(); i++){
                                
                                if(params[i].Account_Type__c == rc.From_Franchisee_Account_Type__c){
                                    espType = params[i].Account_Type__c;
                                }
                            }
                        }
                        rc.Special_Parameter__c = espType;
                        
                        if((rc.calculated_Students__c == null || rc.Calculated_Students__c == 0) && rc.Calculated_Income__c > 0 && rc.Calculated_Percent__c == 0){
                            rc.Calculated_Percent__c = 14; // By Default 
                        }
                        
                    }                
                }  
                
                // CALCULATE THE ROYALTIES
                If (rc.Combined__c)
                    rc.Calculated_Royalties__c = (rc.Calculated_Percent__c / 100) * rc.Gross_Income__c;  
                else
                    rc.Calculated_Royalties__c = (rc.Calculated_Percent__c / 100) * rc.Calculated_Income__c;  
         
                UpdateRCList.add(RC); 
            }
        }
        
        try{
            Update UpdateRCList;
           }catch(Exception ex){
               errorLogs.add(new HD_Log__c(Process_Key__c = 0, Process_Name__c = 'Batch - Create Royalty Calculation', Error_Description__c = ex.getMessage() + ' Trace: ' + ex.getStackTraceString(), Status__c = 'Fail')); 
           } 
    }
        System.debug('Cpu*********** '+Limits.getCpuTime()+' Dml Rows '+Limits.getDmlRows()+' Queries '+Limits.getQueries()+'\n RemaningDmL ');

         SYstem.debug(String.valueOf(Limits.getLimitDMLRows()-Limits.getDMLRows()));
    }
    global void finish(Database.BatchableContext BC){
        if (!test.isRunningTest()){
            RSRoyaltyCalculation3 Rs = new RSRoyaltyCalculation3();
            RS.MFID =MFID;
            Database.executeBatch(Rs,2000);
        }
    } 
}