@isTest 
class ContentSearchControllerTest {

    // data setup method
    @testSetup static void setupData() {
        
        // insert HD Setting data to handle the production issue.
        HD_Settings_List__c cs1 = new HD_Settings_List__c(Name = 'HD Community ID', Value__c = '0DBe00000008OiN');
        insert cs1; 
    
        ContentVersion content = new ContentVersion();
        content.versionData = Blob.valueOf('aabbcc');
        content.title = 'test title';
        content.Description = 'test';
        //content.Language = 'English';
        content.pathOnClient = 'test file';
        content.HDC_File__c = false;
        insert content;
    }
    // test method for get all library
    testMethod static void testFetchAllLibrary() {
        
        Test.startTest();
            Map<String, String> libraries = ContentSearchController.fetchAllLibrary();
        Test.stopTest();
        
        System.assertNotEquals(null, libraries, 'Libraries should not be null');
    }
    // test method for get all language
    testMethod static void testFetchAllLanguage() {
        
        Test.startTest();
            Map<String, String> languageMap = ContentSearchController.fetchAllLanguage();
        Test.stopTest();
        
        System.assertNotEquals(Null, languageMap, 'LanguageMap should not be Null.');
    }
    // test method for get contents
    testMethod static void testContents() {
        
        ContentVersion content = [Select Id,ContentDocument.ParentId from ContentVersion ];
        
        Test.startTest();
            ContentSearchController.ContainerWrapper contentWrappers = ContentSearchController.contents('', '', '', 0);
            contentWrappers = ContentSearchController.contents('PERSONAL_WORKSPACE', '', 'test', 0);
        Test.stopTest();
        
        System.assertNotEquals(Null, contentWrappers, 'LanguageMap should not be Null.');
    }
    // test method for get display option
    testMethod static void testDisplayOption() {
        
        Test.startTest();
            ContentSearchController.DisplayOptionWrapper  displayOptionWrapper = ContentSearchController.displayOption();
        Test.stopTest();
        
        System.assertNotEquals(Null, displayOptionWrapper, 'LanguageMap should not be Null.');
    }

}