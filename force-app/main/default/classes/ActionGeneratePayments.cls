global class ActionGeneratePayments {
    
    @InvocableMethod(label = 'Generate Payments' )
    global static void ExecuteGeneratePayments (List<String> ListLGSId ){ 
        System.debug('LIST - LGS Payments' + ListLGSId); 
        Integer i=0;
        if (ListLGSId != null && ListLGSId.size()>0){
            for ( String LGSId : ListLGSId){
                System.debug(i++ +'-LGS Payments: ' + LGSId); 
                try{
                    LG_Student_Buttons.generate_LGPayments2LGStudent(LGSId);        
                }
                catch(Exception e){
                    System.debug(i++ +'-Exception : LGS Payments: ' + LGSId);    
                }
            }
        }
    }
}