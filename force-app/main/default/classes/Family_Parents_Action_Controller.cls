public class Family_Parents_Action_Controller{
   	public Id conId{get;set;}
   	public Contact con{get;set;}
    public Family_Parents_Action_Controller(ApexPages.StandardController stdController) {
    	conId = System.currentPagereference().getParameters().get('contactID');
    	con = (Contact) stdController.getRecord();
    }


    public PageReference getCloseWindow(){
        return new PageReference('/apex/closeFlow?contactID='+con.Id);
    }
}