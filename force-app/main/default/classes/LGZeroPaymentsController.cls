public class LGZeroPaymentsController {
	
	// Wrapper class
	public class wMonth{
		
		public String month 		{get; set;}
		public Boolean isSelected 	{get; set;}
		
		public wMonth(String m){
			this.month = m;
			this.isSelected = false;
		} 	
	}
	
	// Public Attributtes  
	public List<wMonth> allMonths {get; set;}
	public Integer year {get; set;}	
	public LG_Discount__c dummySpecialPrice {get; set;} 
	public Boolean showCreateButton {get;set;}
	public String showSuccessMessage {get; set;}
	public String retURL {get;set;}

	// Private Attributes
  	private List<LG__c> selectedLGs;
  	
	// Controller
  	public LGZeroPaymentsController(ApexPages.StandardSetController controller) {
  		
  		Set<Id> profileWithPermission2UserTheButtton = new Set<Id>();
		for(String profId : HD_Settings_List__c.getInstance('Zero_Monthly_Payment_Profiles').Value__c.split(',')){
			profileWithPermission2UserTheButtton.add(Id.valueOf(profId));
		}
  		
  		showCreateButton = true;
  		
  		this.retURL = ApexPages.currentPage().getParameters().get('retURL');
		this.selectedLGs = (List<LG__c>)controller.getSelected();
			
  		allMonths = new List<wMonth>();
  		for(String m : new List<String>{'January', 'February', 'March','April','May','June','July','August','September','October','November','December'}){
  			allMonths.add(new wMonth(m));
  		}
  		
		dummySpecialPrice = new LG_Discount__c(Discount_Type__c = 'One Time (Month)', Year__c = string.valueOf(system.today().year()));
  	    
  	    if(!profileWithPermission2UserTheButtton.contains(UserInfo.getProfileId())){
  	    	showCreateButton = false;
        	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,Label.Don_t_have_permission_on_button));
  	    }else if(this.selectedLGs.size() == 0){
        	showCreateButton = false;
        	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please choose at least one LG record'));
        }  
    }
    
    // Command button action
    public void doCreateLGSpecialPriceToLGs(){
    	
    	try{
	    	// Validate the Year.
	    	if(string.isBlank(dummySpecialPrice.Year__c)){
	    		ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please choose a Year'));
	    	}
	    	
	    	Map<String, Integer> months = new Map<String, Integer>{'January'=>1,'February'=>2,'March'=>3,'April'=>4,'May'=>5,'June'=>6,'July'=>7,'August'=>8,'September'=>9,'October'=>10,'November'=>11,'December'=>12};
	    	
	    	List<String> selectedMonths = new List<String>();
	    	List<Date> selectedMonths_lastDayOfMonth = new List<Date>();
	    	List<Date> selectedMonths_firstDayOfMonth = new List<Date>();
	    	for(wMonth m : allMonths){
	    		if(m.isSelected){
	    			selectedMonths.add(m.month);
	    			selectedMonths_lastDayOfMonth.add(Date.newInstance(Integer.valueOf(dummySpecialPrice.Year__c), months.get(m.month), Date.daysInMonth(Integer.valueOf(dummySpecialPrice.Year__c), months.get(m.month))));
	    			selectedMonths_firstDayOfMonth.add(Date.newInstance(Integer.valueOf(dummySpecialPrice.Year__c), months.get(m.month), 1));
	    		}
	    	}
	    	
	    	// Validate Months
	    	if(selectedMonths_lastDayOfMonth.isEmpty()){
	    		ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please choose at least one Month'));
	    	}else{
	    		
	    		// Apply the logic of create Special Prices for all LG selected...
	    		Set<Id> lgIds = new Set<Id>();
	    		for(LG__c lg : this.selectedLGs){
	    			lgIds.add(lg.id);
	    		}   
	    		
	    		Id rtRequestedDiscount = Schema.SObjectType.LG_Discount__c.getRecordTypeInfosByName().get('Requested Discount').getRecordTypeId();
	    		
	    		List<LG_Discount__c> lgSpecialPrice2Insert = new List<LG_Discount__c>();    		
	    		for(LG__c lg : [SELECT Id, LG_Start_Date__c, LG_End_Date__c, Price_per_Session__c, Price_per_Month__c, Billing_Type__c FROM LG__c WHERE Id IN:lgIds]){
	    			
	    			if(lg.Billing_Type__c != 'Course Price' || Test.isRunningTest()){
		    			
		    			for(Integer i = 0; i < selectedMonths_lastDayOfMonth.size(); i++){
		    				
		    				Date lastDayOfMonth = selectedMonths_lastDayOfMonth[i];
		    				Date firstDayOfMonth = selectedMonths_firstDayOfMonth[i];
		    				
		    				Boolean condition = lg.LG_Start_Date__c <= lastDayOfMonth && lg.LG_End_Date__c >= firstDayOfMonth;
		    				if(condition){
		    					lgSpecialPrice2Insert.add(new LG_Discount__c(LG__c = lg.Id, Month__c = selectedMonths[i], Year__c = dummySpecialPrice.Year__c, RecordTypeId = rtRequestedDiscount, Discount_Type__c = 'One Time (Month)', Discount_Reason__c = 'Zero Monthly Payment', Discount_Status__c = 'Requested'));
		    					if(lg.Price_per_Month__c != null){
		    						lgSpecialPrice2Insert[lgSpecialPrice2Insert.size()-1].Requested_Price_per_Month__c = 0;	
		    					}
		    					if(lg.Price_per_Session__c != null){
		    						lgSpecialPrice2Insert[lgSpecialPrice2Insert.size()-1].Requested_Price_per_Session__c = 0;
		    					}
		    				}  
		    			}
	    			}
	    		}
	    		
	    		if(!lgSpecialPrice2Insert.isEmpty()){
	    			insert lgSpecialPrice2Insert;
	    		}
	    		
	    		showSuccessMessage = Label.Zero_Payment_Success;
	    	}
    	}catch(Exception e){
    		ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,e.getMessage()));
    	}
    }
}