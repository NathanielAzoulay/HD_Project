/******************************************************************************* 
Name              : Create_Seminar_Session_Invoice_Ctl 
Description       : 
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sergio                 07/06/2016              Yaara Nadir            [SW-20167]
*******************************************************************************/

public class Create_Seminar_Session_Invoice_Ctl {
    
    public class MyException extends Exception {}
    
    public String showError {get; set;}
    public String showException {get; set;}
    public Boolean showForm {get; set;}
    public Boolean showDone {get; set;}
    
    public Seminar__c dummySeminar {get;set;}
    public Seminar_Session__c dummySession {get;set;}
    
    private Set<String> seminarIds {get;set;}
    private String newSession {get;set;}
    
    public Create_Seminar_Session_Invoice_Ctl(ApexPages.StandardController controller) {
        try{
            
            showForm = true;
            
            seminarIds = new Set<String>();
            String idsParam = Apexpages.currentPage().getParameters().get('ids');
            
            seminarIds.addAll( idsParam.split(',') );
            
            Id franchiseeId;
            Date earliestStartDate;
            for( Seminar__c seminar : [SELECT Id, Start_Date__c, Status__c, Seminar_Session__c, Hosting_Franchisee__c FROM Seminar__c WHERE Id IN :seminarIds ] ){
                if( seminar.Status__c != 'Confirmed' ){
                    showError = 'Please choose TTC/Seminars with status "Confirmed"';
                    showForm = false;
                    break;
                }
                
                if( seminar.Seminar_Session__c != null ){
                    showError = 'Please choose only TTC/Seminars that are not already a part of a Seminar Session invoice';
                    showForm = false;
                    break;
                }
                
                if( franchiseeId == null ){
                    franchiseeId = seminar.Hosting_Franchisee__c;
                }else if( franchiseeId != seminar.Hosting_Franchisee__c ){
                    showError = 'Please choose only TTC/Seminars from the same franchisee';
                    showForm = false;
                    break;
                }
                
                if( earliestStartDate == null || (earliestStartDate != null && earliestStartDate > seminar.Start_Date__c ) ){
                    earliestStartDate = seminar.Start_Date__c;
                }
                
            }
            
            if(earliestStartDate == null){
                earliestStartDate = system.today();
            }
            
            //We setup this dummy Seminar with the following values as to use the lookup with the Filter on it.
            dummySeminar = new Seminar__c();
            dummySession = new Seminar_Session__c( Name = 'SO-', Due_By_Date__c = earliestStartDate.addDays(-28), Hosting_Franchisee__c = franchiseeId );
            
        }catch(Exception e){
            showException = e.getMessage();
            showForm = false;
            showError = '';
        }
    }
    
    public void RetrieveSeminarSession(){
        if( dummySeminar.Hidden_Seminar_Session_Filtered__c != null ){
            for( Seminar_Session__c ss : [SELECT Id, Name, Due_By_Date__c , Order_Number_Priority__c, Invoice_Amount__c FROM Seminar_Session__c WHERE Id = :dummySeminar.Hidden_Seminar_Session_Filtered__c LIMIT 1] ){
                dummySession = ss;
            }
        }
    }
    
    public void setNewSession( String value ){
        newSession= value;
    }
    
    public String getNewSession( ){
        return newSession;
    }
    
    public Boolean Validate(){
        Boolean isError = false;
        
        if( String.isBlank(dummySession.Name) || ( dummySession.Name != null && dummySession.Name.trim().equalsIgnoreCase('SO-') ) ){
            //Field wasn't populated
            showException = null;
            showForm = true;
            showError = Label.Seminar_Session_required;
            
            isError = true;
        }
        
        return isError;
    }
    
    public PageReference doContinue(){
        showException = null;
        showError = null;
        
        Savepoint sp = Database.setSavepoint();
        
        try{
            if( !Validate() ){
                Date startDate = null;
                Date lastStartDate = null;
                
                List<Seminar__c> seminars2Upd = new List<Seminar__c>();
                
                for( Seminar__c seminar : [SELECT Id, Start_Date__c FROM Seminar__c WHERE Id IN :seminarIds] ){
                    if( startDate == null || seminar.Start_Date__c < startDate ){
                        startDate = seminar.Start_Date__c;
                    }
                    if( lastStartDate == null || seminar.Start_Date__c > lastStartDate ){
                        lastStartDate = seminar.Start_Date__c;
                    }
                    
                    seminars2Upd.add(seminar);
                }
                
                Seminar_Session__c session = new Seminar_Session__c();
                
                if( newSession.equalsIgnoreCase('false') ){
                    //Add to existing Session
                    
                    session = [SELECT Id, First_Seminar_Start_Date__c, Last_Seminar_Start_Date__c FROM Seminar_Session__c WHERE Id = :dummySession.Id LIMIT 1][0];
                    
                }else{
                    //Create new Session
                    session = dummySession.clone(false, true);
                    
                    session.OwnerId = Userinfo.getUserId();
                    session.Payment_Status__c = 'Pro-Forma Sent';
                    session.Order_Number_Priority__c = dummySession.Order_Number_Priority__c;
                    
                    session.Name = dummySession.Name;
                    session.Due_By_Date__c = dummySession.Due_By_Date__c;
                }
                
                session.Invoice_Amount__c = dummySession.Invoice_Amount__c;
                
                if( session.First_Seminar_Start_Date__c == null || session.First_Seminar_Start_Date__c > startDate ){
                    session.First_Seminar_Start_Date__c = startDate;
                }
                if( session.Last_Seminar_Start_Date__c == null || session.Last_Seminar_Start_Date__c < lastStartDate ){
                    session.Last_Seminar_Start_Date__c = lastStartDate;
                }
                
                upsert session;
                
                
                for( Seminar__c seminar : seminars2Upd ){
                    seminar.Seminar_Session__c = session.Id;
                }
                
                update seminars2Upd;
                
                showDone = true;
                showForm = false;
            }
        }catch(Exception e){
            Database.rollback(sp);
            showException = e.getMessage();
            showForm = false;
            showError = '';
        }
        
        return null;
    }
}