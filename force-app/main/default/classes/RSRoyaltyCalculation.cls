/*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name:            RSRoyaltyCalculation.cls

Description:     Agreement Run , Create the tree , calculate GIPM Param         
Date             Author          Summary of Changes 
17-OCT-2017     Rashad Saeed  Initial Implementation 
21-JAN-2018     Rashad Saeed  Add ReGenerate function .
04-Feb-2018     Rashad Saeed  Improve query Performance
15-Feb-2022     Avraham Dasa  remark line 32
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
global class  RSRoyaltyCalculation implements Database.Batchable<sObject> , Database.Stateful {
    Private Set <Id> GPIMToUpdate  {get; set;}
    global  String FQuery;
    global  String MFID {get; set;} 
    global  Boolean ReGenerate {get; set;}
    public static Decimal DEFAULT_FROM_MF = 50;
    public static Decimal DEFAULT_FROM_OTHER = 14;
    global RSRoyaltyCalculation (String Q){
        this.FQuery= q;
        
    }
    global RSRoyaltyCalculation (){
        this.FQuery = 'SELECT Direct_Franchisee_Agreement__r.CurrencyIsoCode,Expiry_Date__c,Direct_Franchisee_Agreement__r.Direct_Franchisee__c,Direct_Franchisee_Agreement__c,Id,From_Franchisee__c,Direct_Franchisee__c,CurrencyIsoCode FROM Agreement__c WHERE Royalty_Type__c = \'1 - Standard\''; 
        if (ReGenerate == null)
            ReGenerate=false;
    } 
    global Database.QueryLocator start(Database.BatchableContext bc) {
        GPIMToUpdate = new Set <Id>();
        
        if (MFID<>null)
            this.FQuery+=' And MF_ID__c ='+'\''+MFID+'\'';
       // this.FQuery += ' And Expiry_Date__c >=LAST_YEAR';
        this.FQuery+=' Order By Level__c DESC';
        System.debug('@@@@@@@@@ Query '+ FQuery);  
        //String query = 'SELECT Id,From_Franchisee__c,Direct_Franchisee__c,CurrencyIsoCode FROM Agreement__c WHERE Royalty_Type__c = \'1 - Standard\''; 
        
        return Database.getQueryLocator(FQuery); 
    }

    global void execute(Database.BatchableContext BC, List<Agreement__c> scope){
       
        Map <Id,Agreement__c> AggsMap = new Map <Id,Agreement__c>();
        Map <String ,Royalties_Calculation__c> MapKeyRC = new Map <String ,Royalties_Calculation__c>();
        Map <String ,decimal> MapKeyIncome = new Map <String ,decimal>();
        Map <String ,Date> MapKeyDate = new Map <String ,Date>();
        Map <String ,Decimal> MapKeyActual_Student = new Map <String ,Decimal>();// Actual_Student
        Map <String ,Decimal> MapKeyCalculated_Student = new Map <String ,Decimal>();// Calculated_Student
        //Map <String ,Decimal> NewRC = new Map <String ,Decimal>();//  ALL new RC
         Set <String> NewRcLinkKey = new Set <String> ();//  ALL new RC
        Set <String> AggRCKeys = new Set <String>();
        //Set <Id>AggIds = new Set <Id>();
        List <Royalties_Calculation__c>NewRCList = new List <Royalties_Calculation__c>();
        List <Royalties_Calculation__c>UpdateRCList = new List <Royalties_Calculation__c>();
        set <Id> AggsIds = new Set <Id>();
        Set <Id>ParentAggIds = new Set <Id>();
        List <Royalties_Calculation__c>ParentNewRCList = new List <Royalties_Calculation__c>();
        for (Agreement__c Agg : Scope){
            AggsMap.Put(Agg.ID,agg);
            ParentAggIds.add((Id)Agg.Direct_Franchisee_Agreement__c);
        }
        AggsIds.addAll(AggsMap.keySet());
        Date StartDate = date.newinstance(System.today().AddYears(-1).Year(),1, 1);
        Set <String> RCParentKeys = new Set <String>(); //for Parent
        Set <String> RCCHKeys = new Set <String>(); // for children
        Set<String> RCExistingchildrenKeys = new Set <String>(); // for Existing children on DB 
        Set<String> RCExistingParentsKeys = new Set <String>(); // for Existing children on DB 
        for (Integer i = 0; i < 36; i++) {
            Date Temp = StartDate.addMonths(I);
            for (Id P : AggsMap.keySet())
            {
                RCParentKeys.add ((Id)AggsMap.get(p).Direct_Franchisee_Agreement__c+'_'+String.ValueOf(Temp.month())+'_'+String.ValueOf(Temp.year()));
                RCCHKeys.Add ((Id)p+'_'+String.ValueOf(Temp.month())+'_'+String.ValueOf(Temp.year()));
                
            }
        }
     List <Royalties_Calculation__c> ParentRcs = [select Id,RCUniqKey__c from Royalties_Calculation__c where RCUniqKey__c In : RCParentKeys order By Royalty_Month__c Asc];       
     List <Royalties_Calculation__c> childrenRcs = [select Id,RCUniqKey__c from Royalties_Calculation__c where RCUniqKey__c In : RCCHKeys order By Royalty_Month__c Asc];
        for (Royalties_Calculation__c rc: childrenRcs)
        {
            RCExistingchildrenKeys.add(rc.RCUniqKey__c);  
        }
        for (Royalties_Calculation__c rc: ParentRcs)
        {
            RCExistingParentsKeys.add(rc.RCUniqKey__c);  
        }
        
        for (Id AgId :AggsMap.keySet() ){
            Date Expiry = AggsMap.get (AgId).Expiry_Date__c.AddYears(1); 
             for (Integer i = 0; i < 36; i++){
                 Date rDate = StartDate.addMonths(I);  
                 String Key =(Id)AgId+'_'+String.ValueOf(rDate.month())+'_'+String.ValueOf(rDate.year());
                 String Pkey = (Id)AggsMap.get(AgId).Direct_Franchisee_Agreement__c+'_'+String.ValueOf(rDate.month())+'_'+String.ValueOf(rDate.year());
                 //System.debug(Key);
                 if (!RCExistingchildrenKeys.contains(Key) && !RCExistingParentsKeys.contains(Key) 
                     &&Expiry>=rDate
                    ){
                     RCExistingchildrenKeys.add(Key); 
                     NewRCList.add(new Royalties_Calculation__c (
                        Calculated_Income__c=0 ,
                        Actual_Students__c=0,
                        Calculated_Students__c=0,
                        Agreement__c=AggsMap.get(AgId).id,
                        From_Franchisee__c=AggsMap.get(AgId).From_Franchisee__c,
                        Direct_Franchisee__c=AggsMap.get(AgId).Direct_Franchisee__c,
                        CurrencyIsoCode = AggsMap.get(AgId).CurrencyIsoCode,
                        Royalty_Month__c = rDate,
                        Process_Key__c=system.now().getTime(),
                        GIPM_Income__c =0) 
                    ); 
                     
                 }
                 if (!RCExistingchildrenKeys.contains(Key) && RCExistingParentsKeys.contains(Key) &&Expiry>=rDate)  // when the Chiled Also is the Parent on Dif Aggs 
                 {
                     RCExistingchildrenKeys.add(Key); 
                 }
                 if ((!RCExistingParentsKeys.contains(Pkey)) && AggsMap.get(AgId).Direct_Franchisee_Agreement__c <> Null
                      &&Expiry>=rDate){
                        RCExistingParentsKeys.add(Pkey);
                        ParentNewRCList.add(new Royalties_Calculation__c (
                        Calculated_Income__c=0 ,
                        Actual_Students__c=0,
                        Calculated_Students__c=0,
                        Agreement__c=AggsMap.get(AgId).Direct_Franchisee_Agreement__c,
                        From_Franchisee__c=AggsMap.get(AgId).Direct_Franchisee__c,
                        Direct_Franchisee__c=AggsMap.get(AgId).Direct_Franchisee_Agreement__r.Direct_Franchisee__c,
                        CurrencyIsoCode = AggsMap.get(AgId).Direct_Franchisee_Agreement__r.CurrencyIsoCode,
                        Royalty_Month__c = rDate,
                        Process_Key__c=system.now().getTime(),
                        GIPM_Income__c =0) 
                    ); 
                   
                 }
             }
        
        }
       
        Insert NewRCList ;
        SYstem.debug(String.valueOf(Limits.getLimitDMLRows()-Limits.getDMLRows()));
        Insert ParentNewRCList;
        SYstem.debug(String.valueOf(Limits.getLimitDMLRows()-Limits.getDMLRows()));
        NewRCList.clear();
      
        childrenRcs = [select Name,Agreement__c,GIPM_Income__c, Direct_Royalties_Calculation__c,Id,
                       RCParentKey__c,RCUniqKey__c, Royalty_Month__c,eRate_Key__c
                       from Royalties_Calculation__c where RCUniqKey__c In : RCExistingchildrenKeys 
                       order By Royalty_Month__c Asc ];
      
        ParentRcs = [select Name,Id,RCUniqKey__c from Royalties_Calculation__c where RCUniqKey__c In : RCExistingParentsKeys
                     order By Royalty_Month__c Asc]; 
        
        for (Royalties_Calculation__c Ch : childrenRcs)
        {
             for (Royalties_Calculation__c P : ParentRcs)
             {
                 if (ch.RCParentKey__c==p.RCUniqKey__c &&(Id)ch.Direct_Royalties_Calculation__c <>  P.Id ) 
                 {
                     ch.Direct_Royalties_Calculation__c = P.Id;
                     NewRCList.add(ch); 
                     System.debug('@@@@ ch.Name'+ ch.Name +'\n' +'ParentRcs '+P.Name);
           Break; 

                 }
             }
        }
      Set <Royalties_Calculation__c> Un = new  Set <Royalties_Calculation__c>();
      un.addAll (NewRCList); 
      NewRCList.Clear();
      NewRCList.AddAll (un);  
      Update NewRCList; 
      
     Integer RemaningDmL =Limits.getLimitDMLRows()-Limits.getDMLRows(); 
     System.debug('Cpu*********** '+Limits.getCpuTime()+' Dml Rows '+Limits.getDmlRows()+' Queries '+Limits.getQueries()+'\n RemaningDmL '+RemaningDmL); // Max Dml Per Agrement 108 = 36*3
  
     // Claculate GIPM 
     for (AggregateResult ar :[select Count (Id) Records ,sum (Income__c) Income ,CALENDAR_MONTH(Royalty_Start_Date__c)MONTH,
                                         CALENDAR_Year(Royalty_Start_Date__c)YEAR,sum (Actual_Student_Number__c)Actual_Student
                                         ,sum (Calculated_Student__c)Calculated_Student,Agreement__c
                                         From Group_Income_Per_Month__c   
                                         Where Agreement__c in :AggsMap.keySet()   
                                         And GIPMRCKey__c in :RCCHKeys         
                                         And For_Royalty_Calculation__c = true
                                         And Royalty_Start_Date__c <=NEXT_YEAR
                                         And Royalty_Start_Date__c >=LAST_YEAR
                                         Group By CALENDAR_MONTH(Royalty_Start_Date__c),CALENDAR_Year(Royalty_Start_Date__c),Agreement__c
                                         Order By CALENDAR_MONTH(Royalty_Start_Date__c),Agreement__c]
        )
       
        {
            // Ag+_+Month+Year;
            String Key = (Id)Ar.get('Agreement__c')+'_'+String.ValueOf((Integer)Ar.get('MONTH'))+'_'+String.ValueOf((Integer)Ar.get('Year'));  
            AggRCKeys.add(Key);   
            MapKeyIncome.put (Key,(decimal)Ar.get('Income'));
            MapKeyDate.put(key, date.newinstance((Integer)Ar.get('YEAR'),(Integer)Ar.get('MONTH'), 1));
            MapKeyActual_Student.put(key,(Decimal)Ar.get('Actual_Student'));
            MapKeyCalculated_Student.put(key,(Decimal)Ar.get('Calculated_Student'));   
            
            //system.debug(MapKeyRC);                   
        }  
       NewRCList.clear();
      
        
            Map <String,Decimal> exchangeRate =  GetExchangeRate();
            for (Royalties_Calculation__c CH : childrenRcs)
            {
                if (GlobalHelperMethods.ifnull(MapKeyIncome.get (CH.RCUniqKey__c))<> CH.GIPM_Income__c||ReGenerate==true)  // if there Is Change
                {
                    String KeyRate = Ch.eRate_Key__c +'_'+Ch.Royalty_Month__c.Month()+'_'+Ch.Royalty_Month__c.Year();
                    if (exchangeRate.get (KeyRate)<>Null )
                        Ch.Exchange_Rate__c =exchangeRate.get (KeyRate);
                Ch.GIPM_Income__c = GlobalHelperMethods.ifnull(MapKeyIncome.get (CH.RCUniqKey__c));
                    Ch.GIPM_Actual_Students__c=GlobalHelperMethods.ifnull(MapKeyActual_Student.get(CH.RCUniqKey__c));
                    Ch.GIPM_Calculated_Students__c=GlobalHelperMethods.ifnull(MapKeyCalculated_Student.get(CH.RCUniqKey__c));
                    Ch.Calculated_Income__c =  GlobalHelperMethods.ifnull (Ch.GIPM_Income__c )+  GlobalHelperMethods.ifnull (Ch.RC_Income__c ) ; 
                    ch.Actual_Students__c=ch.GIPM_Actual_Students__c+GlobalHelperMethods.ifnull(ch.RC_Calculated_Students__c);
                    ch.Calculated_Students__c=ch.GIPM_Calculated_Students__c+GlobalHelperMethods.ifnull(ch.RC_Actual_Students__c);
                    NewRCList.add(CH);
                }
                
            } 
            //Update NewRCList; 
            SYstem.debug(String.valueOf(Limits.getLimitDMLRows()-Limits.getDMLRows()));
            Map<Id, Agreement__c> agreements = RoyaltyCalculationProcessStep2.getAgreementsInformation(AggsMap.keySet());
            Map<Id, Map<String, List<Agreement_Parameter__c>>> agreementParameterByType = getAgreementParameterByType(agreements.keySet());
            Map<Id, Map<Date, Royalties_Fixed_Student__c>> fixPercent = new Map<Id, Map<Date, Royalties_Fixed_Student__c>>();
            for(Id agId : agreements.keySet()){
                fixPercent.put((Id)agId, new Map<Date, Royalties_Fixed_Student__c>());
                for(Royalties_Fixed_Student__c fp : agreements.get(agId).Royalties_Fixed_Student_Number_in_del__r){
                    fixPercent.get((Id)agId).put(fp.Month__c.toStartOfMonth(), fp);
                }
            }
            for(Royalties_Calculation__c r : NewRCList){ // Iter for calculation...
                
                Agreement__c relatedAgreement = agreements.get((Id)r.Agreement__c);  
                
                // CALCULATE THE PERCENT
                
                // First Priority is by fixed percent if exist...
                if(fixPercent.containsKey((Id)r.Agreement__c) && fixPercent.get((Id)r.Agreement__c).containsKey(r.Royalty_Month__c)){ // We know that the date is check on the 1 day of the month
                    
                    r.Calculated_Percent__c = fixPercent.get(r.Agreement__c).get(r.Royalty_Month__c).Royalty_Percent__c;
                }else{
                    
                    // If not exist fixed percent, we need to identify which kind of percent calculation we should apply... 
                    if(!agreementParameterByType.get((Id)r.Agreement__c).get('By Student').isEmpty()){ 
                        // if we are on By Student (when the Student_Count_Revenue__c <> null on the parameter exist) - The % is decreasing when the number 
                        // of calculated students is rising.
                        
                        if(r.GIPM_Calculated_Students__c == null){
                            r.GIPM_Calculated_Students__c = 0;
                        }
                        
                        List<Agreement_Parameter__c> params = agreementParameterByType.get(r.Agreement__c).get('By Student');
                        Integer nroOfRows = 1;
                        List<Decimal> calculatedRows = new List<Decimal>();            
                        for(Integer i = 0; i < params.size(); i++){
                            
                            Decimal nroOfStudent = params[i].Student_Count_Revenue__c;
                            if(i+1 == params.size() /*we are on the last row*/ || params[i].Student_Count_Revenue__c > r.GIPM_Calculated_Students__c /*We reach the threshold*/){
                                // if we are on the last or the calculated student is less that the nro student (Student_Count_Revenue__c) defined on the parameter 
                                nroOfStudent = r.GIPM_Calculated_Students__c;
                            }
                            
                            if(i == 0){              
                                calculatedRows.add(params[0].Royalty_Percent__c * nroOfStudent);
                            }else{
                                calculatedRows.add(params[i].Royalty_Percent__c * (nroOfStudent - params[i-1].Student_Count_Revenue__c));
                            }
                            
                            if(params[i].Student_Count_Revenue__c > r.GIPM_Calculated_Students__c || i+1 == params.size()){
                                break; // We cut the iteration since we already calculate all possible percent (depending by the nro of GIPM_Calculated_Students__c)
                            }
                            nroOfRows++;
                        }
                        
                        Decimal percent = 0;
                        for(Integer i = 0; i < nroOfRows; i++){
                            percent += calculatedRows[i];
                        }  
                        
                        if(r.GIPM_Calculated_Students__c == 0){
                            r.Calculated_Percent__c = 0; 
                            if(r.GIPM_Income__c > 0){
                                r.Calculated_Percent__c = 14; // By Default 
                            }
                        }else{
                            r.Calculated_Percent__c = percent / r.GIPM_Calculated_Students__c;
                        }
                    } else {
                        
                        r.Calculated_Percent__c = getPercentByType(r.From_Franchisee_Account_Type__c, agreementParameterByType.get(r.Agreement__c));
                        
                        String espType;
                        if(!agreementParameterByType.get(r.Agreement__c).get('By Type').isEmpty()){
                            
                            List<Agreement_Parameter__c> params = agreementParameterByType.get(r.Agreement__c).get('By Type');          
                            for(Integer i = 0; i < params.size(); i++){
                                
                                if(params[i].Account_Type__c == r.From_Franchisee_Account_Type__c){
                                    espType = params[i].Account_Type__c;
                                }
                            }
                        }
                        r.Special_Parameter__c = espType;
                        
                        if((r.GIPM_Calculated_Students__c == null || r.GIPM_Calculated_Students__c == 0) && r.GIPM_Income__c > 0 && r.Calculated_Percent__c == 0){
                            r.Calculated_Percent__c = 14; // By Default 
                        }
                        
                    }                
                }  
                
                // CALCULATE THE ROYALTIES
                r.Calculated_Royalties__c = (r.Calculated_Percent__c / 100) * r.GIPM_Income__c;  
            }  
            
           
        
        
         update NewRCList;
        System.debug('Cpu*********** '+Limits.getCpuTime()+' Dml Rows '+Limits.getDmlRows()+' Queries '+Limits.getQueries()+'\n RemaningDmL ');

         SYstem.debug(String.valueOf(Limits.getLimitDMLRows()-Limits.getDMLRows()));
    }
    
    global void finish(Database.BatchableContext BC){
        if (!test.isRunningTest()){
            RSRoyaltyCalculation2 Rs = new RSRoyaltyCalculation2();
            RS.MFID =MFID;
            if (ReGenerate <>Null)
               RS.ReGenerate = ReGenerate;  
            Database.executeBatch(Rs,1);
        }
    }
      public static Map<Id, Map<String, List<Agreement_Parameter__c>>> getAgreementParameterByType(Set<Id> agreementIds){
      
      Map<Id, Map<String, List<Agreement_Parameter__c>>> agreementParameterByType = new Map<Id, Map<String, List<Agreement_Parameter__c>>>();
      for(Agreement__c ag : [SELECT Id, (Select Id, Agreement__c, CurrencyIsoCode, Royalty_Type__c, From_Franchisee__c, Royalty_Percent__c, Student_Count_Revenue__c, Max_Number_of_Students_per_month__c, Agreement_Parameter_Old_ID__c, Fixed_Level__c, Direct_Franchisee__c, Account_Type__c From Agreement_Parameters__r WHERE (Royalty_Type__c = '1 - Standard' OR Royalty_Type__c = null) ORDER BY Student_Count_Revenue__c NULLS LAST)  FROM Agreement__c WHERE Id IN: agreementIds]){  // 07/06/2016 yaara defined that if Royalty_Type__c == null then consier as 1- Standard
        
        agreementParameterByType.put(ag.Id, new Map<String, List<Agreement_Parameter__c>>{'By Student' => new List<Agreement_Parameter__c>(), 'By Type' => new List<Agreement_Parameter__c>(), 'By None' => new List<Agreement_Parameter__c>()});
        
        for(Agreement_Parameter__c ap : ag.Agreement_Parameters__r){
      
          // Get the possible Type of percents
        if(ap.Account_Type__c <> null){
          agreementParameterByType.get(ap.Agreement__c).get('By Type').add(ap);  
        }

        if( (ap.Student_Count_Revenue__c <> null || !agreementParameterByType.get(ap.Agreement__c).get('By Student').isEmpty()) || ag.Agreement_Parameters__r.size() == 1){ 
          // The last one could have null if the are more than one by studen row
          // If the is just one parameter, it like discount by student but with just 1 element...
          agreementParameterByType.get(ap.Agreement__c).get('By Student').add(ap);
        }
        if(ap.Account_Type__c == null){
          agreementParameterByType.get(ap.Agreement__c).get('By None').add(ap);
        }
        }
          
      }    
    return agreementParameterByType;
    }
    public static Decimal getPercentByType(String accType, Map<String, List<Agreement_Parameter__c>> parameters){
        
        Decimal percent;
        if(!parameters.get('By Type').isEmpty()){
            
            List<Agreement_Parameter__c> params = parameters.get('By Type');          
            for(Integer i = 0; i < params.size(); i++){
                
                if(params[i].Account_Type__c == accType){
                    percent = params[i].Royalty_Percent__c;
                    break;
                }
            }  
        }  
        
        if(percent == null && parameters.get('By None').size() == 1){ // When exist untagged row (by account type)
            // so, Empty will be : all the others except for the lines with Account Type
            system.debug('parameters.get(By None)[0]: ' + parameters.get('By None')[0]);
            percent = parameters.get('By None')[0].Royalty_Percent__c;
        }
        
        if(percent == null){ 
            // IF doesn't exist parameter records...
            
            //  If From Franchisee Type is not MF
            //    Take 14%
            //  Else 
            //    take 50%.  
            percent   = DEFAULT_FROM_OTHER;
            if(accType == 'MF'){
                percent   = DEFAULT_FROM_MF;
            }
        }        
        return percent;
    }
    Public Static  Map <String,Decimal> GetExchangeRate (){
        Map <String,Decimal> Rates = new  Map <String,Decimal>();
        AggregateResult[] groupedResults = [select CALENDAR_MONTH (Exchange_Rate_Start_Date__c) Month, AVG(Average_Rate__c)AVG,
                                            CALENDAR_Year(Exchange_Rate_Start_Date__c)YEAR ,CurrencyIsoCode,To_Currency__c
                                            from  Average_Exchange_Rate__c
                                            Where Exchange_Rate_Start_Date__c <=NEXT_YEAR
                                            And   Exchange_Rate_Start_Date__c >=LAST_YEAR
                                            Group By CALENDAR_Year(Exchange_Rate_Start_Date__c), CALENDAR_MONTH (Exchange_Rate_Start_Date__c),CurrencyIsoCode,To_Currency__c
                                           ];
        For (AggregateResult Ar : groupedResults)
        {
            String Key = Ar.get('CurrencyIsoCode')+'_'+Ar.get('To_Currency__c')+'_'+String.ValueOf((Integer)Ar.get('MONTH'))+'_'+String.ValueOf((Integer)Ar.get('Year'));
          
            Rates.put(key, (decimal)ar.get('AVG'));
        }
        return Rates;
    }
}