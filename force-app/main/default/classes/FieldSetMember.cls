/*
    Name        :       FieldSetMember
    Author      :       Aparna Yadav
    Description :       Wrapper class for field detials used to display columns dynamically on the basis of field set in Visualforce page.
*/
public class FieldSetMember {
    // Store field API name
    @AuraEnabled
    public String fieldPath { get;set; }
    
  // Store field label
    @AuraEnabled
    public String label { get;set; }

    @AuraEnabled
    public Boolean required { get;set; }
  
    // Store field type
    @AuraEnabled
    public String type { get; set; }
    
    public FieldSetMember(Schema.FieldSetMember f) {
        this.fieldPath = f.fieldPath;
        this.label = f.label;
        this.required = f.required;
        this.type = '' + f.getType();
    }
}