public class ContentDisplayOptionsController {
    
    public Display_Option__c displayOption{get;set;}
    public Integer size{get;set;}
    public String width{get;set;}
    public SelectOption[] leftOptions {get;set;}
    public SelectOption[] rightOptions {get;set;}
    public String parentPage{get;set;}
    public String leftOptionsHidden {
        get;
        set {
            leftOptionsHidden = value;
            setOptions(leftOptions, value);
        }
    }
    public String rightOptionsHidden {
        get;
        set {
            rightOptionsHidden = value;
            setOptions(rightOptions, value);
        }
    }
    
    //Constructor
    public ContentDisplayOptionsController() {
        List<Display_Option__c> displayOptions = [
            Select id,Available_Columns__c,Selected_Columns__c,
            Result_per_Page__c,Display_Tags__c,Display_Description__c,Display_Location__c 
            From Display_Option__c 
            LIMIT 1];
        width = '200px';
        size = 8;
        parentPage = '/apex/ContentSearch';
        leftOptions = new List<SelectOption>();
        rightOptions = new List<SelectOption>();
        leftOptionsHidden = '';
        rightOptionsHidden ='';
        if (displayOptions.size() > 0){
            displayOption = displayOptions[0];  
        } else {
            displayOption = new Display_Option__c();
            displayOption = initializeDisplayOptionToDefault(displayOption);
        }
        setLeftAndRightOptions();
    }
    
    //method to save dispaly option changes
    public void save() {
        try {
            if (rightOptionsHidden == Null || rightOptionsHidden == '') {
                resetToDefault();
            } else {
                displayOption.Available_Columns__c = getSelectOptionValue(leftOptionsHidden);
                displayOption.Selected_Columns__c = getSelectOptionValue(rightOptionsHidden);
                upsert displayOption;
            }
        } catch(Exception e) {
            system.debug(e.getMessage() + '' +e.getstacktracestring());
        }
        
    }
    
    //method to reset display option to default values
    public void resetToDefault() {
        try {
            displayOption = initializeDisplayOptionToDefault(displayOption);
            upsert displayOption;
            setLeftAndRightOptions();
        } catch(Exception e) {
            
        }
    }
    
    //method to initialize display option to default values
    private Display_Option__c initializeDisplayOptionToDefault(Display_Option__c displayOption){
        displayOption.Result_per_Page__c = '20';
        displayOption.Display_Tags__c = false ;
        displayOption.Display_Description__c = false;
        displayOption.Display_Location__c = false;
        displayOption.Available_Columns__c = 'Publication Date; Rating;';
        //'Comments; Subscribers; Relevence';
        displayOption.Selected_Columns__c = 
        //'Subscribe; '+
        'Title; Size; Author; Last Modified;';
        //'Downloads;'
        return displayOption;
    }
    
    //method to set left and right picklist 
    private void setLeftAndRightOptions() {
        leftOptions.clear();
        rightOptions.clear();
        //set available picklist values
        if(displayOption.Available_Columns__c != Null) {
            for (String availableColumn : displayOption.Available_Columns__c.split(';')) {
                SelectOption selectOp = new SelectOption(availableColumn, availableColumn);
                leftOptions.add(selectOp);
            }
        }
        //set selected picklist values
        if(displayOption.Selected_Columns__c != Null) {
            for (String availableColumn : displayOption.Selected_Columns__c.split(';')) {
                SelectOption selectOp = new SelectOption(availableColumn, availableColumn);
                rightOptions.add(selectOp);
            }
        }
    }
    
    //method to set option list for left and right column
    private void setOptions(SelectOption[] options, String value) {
        options.clear();
        if (value != Null && value != '') {
            String[] parts = value.split('&');
            for (Integer i = 0; i < parts.size() / 2; i++) {
                options.add(new SelectOption(EncodingUtil.urlDecode(parts[i * 2], 'UTF-8'), EncodingUtil.urlDecode(parts[(i * 2) + 1], 'UTF-8')));
            }
        }
    }
    
    //method to get selected value 
    private String getSelectOptionValue(String value) {
        String optionValue = ''; 
        if (value != Null && value != '') {
            String[] parts = value.split('&');
            for (Integer i = 0; i < parts.size() / 2; i++) {
                optionValue += EncodingUtil.urlDecode(parts[(i * 2) + 1], 'UTF-8')+';';
            }
            return optionValue.removeEnd(';');
        }
        return null;
    }
    
}