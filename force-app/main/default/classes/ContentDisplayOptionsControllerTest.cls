@isTest
public class ContentDisplayOptionsControllerTest {
    
    /*
    * Method to test display option insertion scenario
    */
    testMethod static void testSaveShouldInsertDisplayOption() {
        ContentDisplayOptionsController displayCon = new ContentDisplayOptionsController();
        
        Test.startTest();
            displayCon.save();
        Test.stopTest();
        
        List<Display_Option__c> defaultDisplayOptions = [
                Select id,Available_Columns__c,Selected_Columns__c,
                Result_per_Page__c,Display_Tags__c,Display_Description__c,Display_Location__c 
                From Display_Option__c];
        
        System.assertEquals(1, defaultDisplayOptions.size(), 
            'Should insert record of display option.');
    }
    /*
    * Method to test display option updation scenario
    */
    testMethod static void testSaveShouldSaveDisplayOption() {
        ContentDisplayOptionsController displayCon = new ContentDisplayOptionsController();
        displayCon.save();
        displayCon = new ContentDisplayOptionsController();
        displayCon.rightOptionsHidden = 'Author&Author&';
        
        Test.startTest();
            displayCon.displayOption.Display_Tags__c = true;
            displayCon.save();
        Test.stopTest();
        
        List<Display_Option__c> defaultDisplayOptions = [
                Select id,Available_Columns__c,Selected_Columns__c,
                Result_per_Page__c,Display_Tags__c,Display_Description__c,Display_Location__c 
                From Display_Option__c LIMIT 1];
        
        System.assertEquals(true, defaultDisplayOptions[0].Display_Tags__c, 
            'Should update display option display tag to true.');
    }
    
    /*
    * Method to test display option updation scenario to default
    */
    testMethod static void testResetToDefaultShouldResetToDefaultDisplayOption() {
        ContentDisplayOptionsController displayCon = new ContentDisplayOptionsController();
        displayCon.displayOption.Display_Tags__c = true;
        displayCon.save();
        displayCon = new ContentDisplayOptionsController();
        
        
        Test.startTest();
            displayCon.resetToDefault();
        Test.stopTest();
        
        List<Display_Option__c> defaultDisplayOptions = [
                Select id,Available_Columns__c,Selected_Columns__c,
                Result_per_Page__c,Display_Tags__c,Display_Description__c,Display_Location__c 
                From Display_Option__c LIMIT 1];
        
        System.assertEquals(false, defaultDisplayOptions[0].Display_Tags__c, 
            'Should update display option to default');
    }
    

}