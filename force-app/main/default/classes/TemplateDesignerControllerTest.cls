@isTest
Private class TemplateDesignerControllerTest {
    @testSetup
    static void dataSetup() {
        Account acc = new Account(Name = 'TestAcc', BillingCountry = 'France');
        insert acc;
        system.assert(acc.Id != null);
        
        Contact cntct = new Contact(FirstName = 'Test', LastName = 'TestContact', AccountId = acc.Id);
        insert cntct;
        system.assert(cntct.Id != null);
        
        //'AdvoDoc_Template__c' record to be inserted
        Email_Template__c emailRec = new Email_Template__c (Name ='TestRecord', Body__c ='Hello! This is for testing',Html_Value__c = 'Test', Related_To_Base_Object__c = 'Contact');
        insert emailRec;
        //Email template with Related to object type LG
        Email_Template__c emailRecLG = new Email_Template__c (Name ='TestRecord', Body__c ='Hello! This is for testing',Html_Value__c = 'Test', Related_To_Base_Object__c = 'LG__c');
        insert emailRecLG;
        system.assert(emailRec.Id != null);
    }
    
    static testMethod void testController() {
        Email_Template__c emailRec = [select Id, Name, Body__c, Related_To_Base_Object__c FROM Email_Template__c where Related_To_Base_Object__c = 'LG__c' LIMIT 1];
        PageReference pageRef = Page.TemplateDesigner;
		Test.setCurrentPage(pageRef);
		
        ApexPages.StandardController sc = new ApexPages.StandardController(emailRec);         
        TemplateDesignerController tdc = new TemplateDesignerController(sc);
        tdc.selectedObject = 'LG__c';
        tdc.selectedField  = 'Agreement__r';
        tdc.leftselected = 'leftvalue';
        tdc.rightselected = 'rightvalue';
        tdc.relatedObject = 'Agreement__c';
        tdc.selectedField2 = 'Country_Name__c';
        tdc.refselectedField = '';
        
        tdc.fetchsobjectFields();    // explicitly calling this method
        tdc.createMergeField(); 
        tdc.createTemplateRecord();
        tdc.Cancel();
        tdc.getAllRelatedObjects();
        tdc.RObjectFields();
        tdc.createMergeField2();         
    }  
    
    static testMethod void testMethod1() {
        Email_Template__c emailRec = [select Id, Name, Body__c,Html_Value__c, Related_To_Base_Object__c FROM Email_Template__c LIMIT 1];
        
        ApexPages.StandardController sc = new ApexPages.StandardController(emailRec);        
        TemplateDesignerController tdc = new TemplateDesignerController(sc);
        tdc.selectedObject = '$System';
        tdc.fetchsobjectFields();
        
        tdc.selectedObject = '$Contact';
        tdc.refselectedField = '';
        tdc.selectedField  = 'firstname';
        tdc.createMergeField();
        
        tdc.rightselected = 'Id#@#Name';
        tdc.unselectclick();
        
        tdc.rightselected = 'Name';
        tdc.moveUpward();
        tdc.moveDownward();
    }
    
    static testMethod void testMethod2() {
        Email_Template__c emailRec = [select Id, Name, Body__c,Html_Value__c, Related_To_Base_Object__c FROM Email_Template__c LIMIT 1];
        
        ApexPages.StandardController sc = new ApexPages.StandardController(emailRec);        
        TemplateDesignerController tdc = new TemplateDesignerController(sc);
        
        tdc.selectedObject = '$Contact';
        tdc.selectedField  = 'LastName';
        tdc.leftselected = 'leftvalue';
        tdc.rightselected = 'rightvalue';
        tdc.relatedObject = 'Account';
        tdc.selectedField2 = 'LastName';

        tdc.selectclick();
        tdc.rightselected = 'Id#@#First Name';
        tdc.unselectclick();
        
        tdc.rightselected = 'First Name';
        tdc.moveUpward();
        tdc.moveDownward();
        
        tdc.getunSelectedValues();
        tdc.getSelectedValues();   
        tdc.InitializeRelatedFields();
        tdc.InitializeInsertFields();
    }
}