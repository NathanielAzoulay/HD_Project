/**************************************************************************************** 
    Name              : RoyaltyCalculationProcessStep3
    Description       : Step 4 - For each Direct Franchisee – Calculate the Income as sum of all its Sub Franchisee Royalties.
                                 If the Direct Franchisee has different calculation for its Direct franchisee according to Account Type  - in its Agreement Parameters (for example from LC/SET income the royalty percent for HQ is 50% and from FP – the royalty percent is 43%) – calculate each agreement to different royalty calculation with different "From Account Type".
                                    5.  Calculate the Royalties that Direct Franchisee should pay to the next Level. (for example: if the Direct Franchisee as FP that pay to MF – It will calculate the royalties the FP should pay to MF. If the Direct Franchisee is MF – It will calculate the royalties that MF should pay to HQ.
                                    6.  Continue with 5+6 until all Direct Franchisee are HQ or NC.

    Revision History  :-
    Created/Modified by         Created/Modified Date     Requested by      Related Task/Issue  
    ----------------------------------------------------------------------------------------
    1. Hernan (Created)         06/20/2016                Yaara                [SW-18002]
    ----------------------------------------------------------------------------------------    
****************************************************************************************/
global class RoyaltyCalculationProcessStep4 implements Database.Batchable<sObject>, Database.Stateful{

    // CONSTANTS
    global Integer iterationCount = 0;  
    global Decimal DEFAULT_FROM_FP = 43;
    global Decimal DEFAULT_FROM_OTHER = 50;         

    global Boolean hasPropagateRecords          {get; set;}
    global String processName                   {get; set;}
    global Decimal rollback_key                 {get; set;}
    global List<HD_Log__c> errorLogs            {get; set;}
    public Boolean restrictByNews               {get; set;}
    global Boolean runJustThisBatchFromTest     {get; set;}
    global Datetime startProcess                {get; set;}
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        hasPropagateRecords = false;
        errorLogs = new List<HD_Log__c>();
        
        String query = 'SELECT Id, Agreement__c, ' +
                                 ' From_Franchisee_Account_Type__c, ' +
                                 ' Direct_Royalties_Calculation__c, ' +
                                 ' Agreement__r.Direct_Franchisee_Agreement__c, ' +
                                 ' Agreement__r.From_Franchisee_Type__c, ' +    
                                 ' Agreement__r.Direct_Franchisee__c, ' + 
                                 ' Agreement__r.Direct_Franchisee_Type__c, ' + 
                                 ' Royalty_Month__c, ' +
                                 ' Calculated_Students__c, ' + 
                                 ' Actual_Students__c, ' +
                                 ' Calculated_Income__c, ' +
                                 ' Calculated_Royalties__c ' +                               
                        'FROM Royalties_Calculation__c WHERE (Royalty_Type__c = \'1 - Standard\' OR Royalty_Type__c = null) AND Allow_to_Delete__c = true AND Don_t_Propagate__c = false '; // 07/06/2016 yaara defined that if Royalty_Type__c == null then consier as 1- Standard
        
        if(restrictByNews == true){ // When the batch was called from the RoyaltyCalculationProcessStep3
            query += ' AND Needs_transfer_to_Direct__c = true';
        }
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Royalties_Calculation__c> scope){
        
        try{
            
            // Unckeching.... 
            for(Royalties_Calculation__c s : scope){
                s.Needs_transfer_to_Direct__c = false;
            }
            update scope;
            
            // <<<First step>>> - GET THE PARENT AGREEMENT (Direct Agreement).
            Set<Id> relatedAgreementIds = new Set<Id>();
            Set<Id> relatedDirectFranchiseeIds = new Set<Id>();
            Set<Date> filterMonth = new Set<Date>();
            for(Royalties_Calculation__c r : scope){
                
                filterMonth.add(r.Royalty_Month__c); // Just for reducing the amount of retrieving records...
                
                if(r.Agreement__r.Direct_Franchisee_Agreement__c <> null){
                    relatedAgreementIds.add(r.Agreement__r.Direct_Franchisee_Agreement__c);
                }else if(r.Agreement__r.Direct_Franchisee_Type__c != 'HQ'){ // since in case that be HQ, then for sure we will have Direct_Franchisee_Agreement__c = null 
                    // About the propagation of the Royalties to the top level. The propagation should be done using the related field 
                    // "Direct Franchisee Agreement" (just HQ agreements will have this field empty), but Yaara say also if this field is not exists 
                    // and the Direct Franchisee is not HQ and the Direct Franchise has only one Agreement with its Direct Franchise, we can take this 
                    // agreement.
                    relatedDirectFranchiseeIds.add(r.Agreement__r.Direct_Franchisee__c);
                }
            }
            
            
            Map<Id, List<Agreement__c>> mapAgreements =new Map<Id, List<Agreement__c>>();
            if(!relatedDirectFranchiseeIds.isEmpty()){
                
                for(Agreement__c ag : [SELECT Id, From_Franchisee__c, Direct_Franchisee__c, Direct_Franchisee_Type__c FROM Agreement__c WHERE (Royalty_Type__c = '1 - Standard' OR Royalty_Type__c = null) AND  From_Franchisee__c IN: relatedDirectFranchiseeIds]){ // 07/06/2016 yaara defined that if Royalty_Type__c == null then consier as 1- Standard
                    if(!mapAgreements.containsKey(ag.From_Franchisee__c)){
                        mapAgreements.put(ag.From_Franchisee__c, new List<Agreement__c>());
                    }
                    mapAgreements.get(ag.From_Franchisee__c).add(ag);
                }
                
                for(Id k : mapAgreements.keySet()){
                    if(mapAgreements.get(k).size() == 1){ // Just if has one agreement, we could use this as parent agreetment...
                        relatedAgreementIds.add(mapAgreements.get(k)[0].Id);
                    }
                }
            }
            
            
            if(!relatedAgreementIds.isEmpty()){
            
                /*******/
                
                for(Royalties_Calculation__c r : scope){
                     
                    // Get the related direct agreement.
                    Id directAgreementId;
                    if(r.Agreement__r.Direct_Franchisee_Agreement__c <> null){
                        directAgreementId = r.Agreement__r.Direct_Franchisee_Agreement__c;
                    }else if(r.Agreement__r.Direct_Franchisee_Type__c != 'HQ' && mapAgreements.containsKey(r.Agreement__r.Direct_Franchisee__c) && mapAgreements.get(r.Agreement__r.Direct_Franchisee__c).size()==1){
                        // if the direct franchisse just have 1 agreement we could use this as parent agreement (yaara defined this)
                        directAgreementId = mapAgreements.get(r.Agreement__r.Direct_Franchisee__c)[0].Id;
                    }
                    
                    if(directAgreementId <> null){ // We could propagate the values...
                        relatedAgreementIds.add(directAgreementId);
                    }
                }
                
                /*******/
            
            
                // Get the parent Agreetment information
                Map<Id, Agreement__c> rAgreements = RoyaltyCalculationProcessStep2.getAgreementsInformation(relatedAgreementIds);
                
                // Get helper map for existing agreetments
                Map<String, Royalties_Calculation__c> existingParentRoyalies = new Map<String, Royalties_Calculation__c>(); 
                for(Agreement__c ag : rAgreements.values()){
                    
                    for(List<Royalties_Calculation__c> rs : ag.Royalties_Calculation__r){
                        
                        for(Royalties_Calculation__c r : rs){
                            //String key = (Id)r.Agreement__c + '-' + r.Royalty_Month__c + '-' + r.Calculated_Percent__c; /* We agree with Yaara add the % to identify the records, so we will have diff record by percent*/
                            String key = ag.Id + '_' + r.Royalty_Month__c + '-'; /* We agree with Yaara add the % to identify the records, so we will have diff record by percent*/                 
                            if(r.Calculated_Percent__c <> null){
                                 key += '-' + r.Calculated_Percent__c.setScale(4);
                            }else{
                                 key += '-' + r.Calculated_Percent__c;
                            }
                            existingParentRoyalies.put(key, r);
                        }
                    }               
                }           
            
                // Get the agreetmet parameter information of each parent aggreetment.
                Map<Id, Map<String, List<Agreement_Parameter__c>>> agreementParameterByType = RoyaltyCalculationProcessStep3.getAgreementParameterByType(rAgreements.keySet());
                
                // Get the AverageExchangeRate for populate on the new RC records.
                Map<String, Map<Date, Average_Exchange_Rate__c>> eRates = RoyaltyCalculationProcessStep1.getAverageExchangeRates(null);
                
                
                /***********************/
                Set<String> additionalKeys = new Set<String>();
                for(Royalties_Calculation__c r : scope){
                     
                    // Get the related direct agreement.
                    Id directAgreementId;
                    if(r.Agreement__r.Direct_Franchisee_Agreement__c <> null){
                        directAgreementId = r.Agreement__r.Direct_Franchisee_Agreement__c;
                    }else if(r.Agreement__r.Direct_Franchisee_Type__c != 'HQ' && mapAgreements.containsKey(r.Agreement__r.Direct_Franchisee__c) && mapAgreements.get(r.Agreement__r.Direct_Franchisee__c).size()==1){
                        // if the direct franchisse just have 1 agreement we could use this as parent agreement (yaara defined this)
                        directAgreementId = mapAgreements.get(r.Agreement__r.Direct_Franchisee__c)[0].Id;
                    }
                    
                    if(directAgreementId <> null){ // We could propagate the values...
                        
                        // Keep in mind that the agreement that we are working now it the direct parent agreement.
                        Agreement__c ag = rAgreements.get(directAgreementId);
                        
                        Decimal percent = RoyaltyCalculationProcessStep3.getPercentByType(r.From_Franchisee_Account_Type__c, agreementParameterByType.get(ag.Id));
                        
                        String key = (Id)ag.Id + '_' + r.Royalty_Month__c + '-';
                        if(percent <> null){
                             key += '-' + percent.setScale(4);
                        }else{
                             key += '-' + percent;
                        }
                        additionalKeys.add(key);
                    }
                }
                
                for(Royalties_Calculation__c rc : [SELECT Id, Agreement__r.Direct_Franchisee__c, Agreement__r.Direct_Franchisee__r.Account_Type__c, Agreement__c, Royalty_Month__c, Calculated_Royalties__c, Calculated_Students__c, Calculated_Income__c, Calculated_Percent__c, Actual_Students__c, Hidden_RoyaltyKey__c FROM Royalties_Calculation__c WHERE Hidden_RoyaltyKey__c IN: additionalKeys AND Don_t_Propagate__c = false /*AND (Royalty_Type__c = '1 - Standard' OR Royalty_Type__c = null) AND Allow_to_Delete__c = true*/]){
                    existingParentRoyalies.put(rc.Hidden_RoyaltyKey__c, rc);
                }
                /**********************/
                
                
                // - <<<Second Step>>> - FOR EACH CHILD ROYALTIES, TRANSFER THE AMOUNT TO THE PARENT ROYALTIES
                Map<String, List<Royalties_Calculation__c>> key2Propagate = new Map<String,List<Royalties_Calculation__c>>();
                for(Royalties_Calculation__c r : scope){
                     
                    // Get the related direct agreement.
                    Id directAgreementId;
                    if(r.Agreement__r.Direct_Franchisee_Agreement__c <> null){
                        directAgreementId = r.Agreement__r.Direct_Franchisee_Agreement__c;
                    }else if(r.Agreement__r.Direct_Franchisee_Type__c != 'HQ' && mapAgreements.containsKey(r.Agreement__r.Direct_Franchisee__c) && mapAgreements.get(r.Agreement__r.Direct_Franchisee__c).size()==1){
                        // if the direct franchisse just have 1 agreement we could use this as parent agreement (yaara defined this)
                        directAgreementId = mapAgreements.get(r.Agreement__r.Direct_Franchisee__c)[0].Id;
                    }
                    
                    if(directAgreementId <> null && r.Direct_Royalties_Calculation__c == null){ // We could propagate the values...
                        
                        // Keep in mind that the agreement that we are working now it the direct parent agreement.
                        Agreement__c ag = rAgreements.get(directAgreementId);
                        
                        Decimal percent = RoyaltyCalculationProcessStep3.getPercentByType(r.From_Franchisee_Account_Type__c, agreementParameterByType.get(ag.Id));
                        
                        String key = (Id)ag.Id + '_' + r.Royalty_Month__c + '-';
                        if(percent <> null){
                             key += '-' + percent.setScale(4);
                        }else{
                             key += '-' + percent;
                        }
                        
                        if(!existingParentRoyalies.containsKey(key)){       
                            // Create new Royalties_Calculation__c record.              
                            
                            String espType;
                            if(!agreementParameterByType.get(ag.Id).get('By Type').isEmpty()){
                                List<Agreement_Parameter__c> params = agreementParameterByType.get(ag.Id).get('By Type');                   
                                for(Integer i = 0; i < params.size(); i++){
                                    
                                    if(params[i].Account_Type__c == r.From_Franchisee_Account_Type__c){
                                        espType = params[i].Account_Type__c;
                                    }
                                }
                            }                       
                            
                            Royalties_Calculation__c r2 = RoyaltyCalculationProcessStep2.createRoyaltiesCalculation(ag, r.Royalty_Month__c, eRates);
                            r2.Hidden_RoyaltyKey__c = key; 
                            r2.Special_Parameter__c = espType;
                            existingParentRoyalies.put(key, r2);
                        }
                        
                        Royalties_Calculation__c parentRoyaltiesCalculation     = existingParentRoyalies.get(key);
                        parentRoyaltiesCalculation.Calculated_Percent__c        = percent;                  
                        parentRoyaltiesCalculation.Calculated_Royalties__c      =  GlobalHelperMethods.ifnull(parentRoyaltiesCalculation.Calculated_Royalties__c)  + ((percent / 100) * GlobalHelperMethods.ifnull(r.Calculated_Royalties__c));
                        parentRoyaltiesCalculation.Calculated_Students__c       =  GlobalHelperMethods.ifnull(parentRoyaltiesCalculation.Calculated_Students__c) + GlobalHelperMethods.ifnull(r.Calculated_Students__c);
                        parentRoyaltiesCalculation.Actual_Students__c           =  GlobalHelperMethods.ifnull(parentRoyaltiesCalculation.Actual_Students__c) + GlobalHelperMethods.ifnull(r.Actual_Students__c);
                        parentRoyaltiesCalculation.Calculated_Income__c         =  GlobalHelperMethods.ifnull(parentRoyaltiesCalculation.Calculated_Income__c) + GlobalHelperMethods.ifnull(r.Calculated_Royalties__c);
                        parentRoyaltiesCalculation.Needs_transfer_to_Direct__c   = true; // For continue iterate the propagation...
                        
                        if(!key2Propagate.containsKey(key)){
                            key2Propagate.put(key, new List<Royalties_Calculation__c>());
                        }                       
                        key2Propagate.get(key).add(r);                      
                    }
                }
                
                List<Royalties_Calculation__c> rc2Insert = new List<Royalties_Calculation__c>();
                List<Royalties_Calculation__c> rc2Update = new List<Royalties_Calculation__c>();
                for(String key : key2Propagate.keySet()){
                    hasPropagateRecords = true;
                    if(existingParentRoyalies.get(key).Id == null){
                        existingParentRoyalies.get(key).IterationHelp__c = iterationCount;
                        rc2Insert.add(existingParentRoyalies.get(key));
                    }else{
                        rc2Update.add(existingParentRoyalies.get(key));
                    }
                }
                
                if(!rc2Insert.isEmpty()){
                    insert rc2Insert;
                }
                
                if(!rc2Update.isEmpty()){ 
                    update rc2Update;
                }   
                
                List<Royalties_Calculation__c> childrenRCs = new List<Royalties_Calculation__c>();
                for(String key : key2Propagate.keySet()){
                    Royalties_Calculation__c newRecord = existingParentRoyalies.get(key);
                    for(Royalties_Calculation__c childrenRC : key2Propagate.get(key)){
                        childrenRC.Direct_Royalties_Calculation__c = newRecord.Id;
                        childrenRCs.add(childrenRC);
                    }
                }
                update childrenRCs;
            }       
        }catch(Exception ex){
            system.debug('Ex: ' + Ex);
            errorLogs.add(new HD_Log__c(Process_Key__c = rollback_key, Process_Name__c = processName, Error_Description__c = GlobalHelperMethods.IncludeAllErrorMessage(ex), Status__c = 'Fail'));
        }
    }
    
    global void finish(Database.BatchableContext BC){
        
        if(hasPropagateRecords && errorLogs.isEmpty()){
            RoyaltyCalculationProcessStep4 b = new RoyaltyCalculationProcessStep4();
            b.rollback_key              = rollback_key;
            b.processName               = processName;
            b.restrictByNews            = true;  
            b.iterationCount            = iterationCount + 1;  
            b.startProcess              = startProcess;
            Database.executeBatch(b); 
        }else{                      
            if(errorLogs.isEmpty()){                
                insert new HD_Log__c(Send_Result__c = true, Process_Key__c = rollback_key, Process_Name__c = processName, Status__c = 'Success', Error_Description__c = '');
                /*
                RoyaltyCalculationProcessStep5 b = new RoyaltyCalculationProcessStep5();
                b.rollback_key              = rollback_key;
                b.processName               = processName;
                b.nroIteration              = 0;  
                b.startProcess              = startProcess;
                if(runJustThisBatchFromTest != true){
                    Database.executeBatch(b,50);   
                      
                } */              
            }else{          
                RoyaltyCalculationProcessStep1.insertErrors(errorLogs, 'Error on Step 4', rollback_key, processName);
            }
        }
    }
}