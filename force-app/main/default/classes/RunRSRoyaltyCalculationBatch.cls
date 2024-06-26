public class RunRSRoyaltyCalculationBatch {
    public Contact con{get;set;}
    public Boolean reGenerate {get;set;}
    String MFID;
    
    public RunRSRoyaltyCalculationBatch(){
        con = new Contact();
        reGenerate = false;
    }
    
    public pagereference runBatch(){
        try{
            if(con.accountId==null){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select account'));
                return null;
            }
                
            MFID = [Select Name, MF_ID__c  from Account where Id=: con.accountId].MF_ID__c;
            if(String.isNotBlank(MFID)){
                RSRoyaltyCalculation rs = new RSRoyaltyCalculation();
                rs.mfid = MFID;
                rs.ReGenerate = reGenerate;
                Database.executeBatch(rs,1);
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Job has been submitted successfully.'));
            }else{
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Selected Account Record has no value for MFID'));
            }
            
        }catch(exception ex){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,ex.getMessage()));
        } 
        return null;        
    }
}