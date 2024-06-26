@isTest 
Private class SiteFileBrowserTest {
    public static testMethod void unitTestWithFolder() {

        //Creating Document
        Document document = new Document();
        //document.AuthorId = UserInfo.getUserId();
        document.FolderId = UserInfo.getUserId();
        document.Name = 'testDoc';
        document.body = Blob.valueOf('teste');
        document.DeveloperName = 'test2_test_jpg';
        document.Type = 'PDF';
        document.IsPublic =true;
        insert document;
        system.assert(document.Id != null);
        
        //Start test
        test.startTest();
        
        String fName = System.currentPageReference().getParameters().put('folder',document.FolderID);
        SiteFileBrowser sfb = new SiteFileBrowser();
        sfb.getSalesforceUrl();
        
        //Verifying FolderId is not null
        System.assertNotEquals(null,document.FolderID);
        //Stop Test
        test.stopTest();
    }
    
    public static testMethod void unitTestWithoutFolder() {

        //Creating Document
        Document document = new Document();
        //document.AuthorId = UserInfo.getUserId();
        document.Name = 'testDoc';
        document.body = Blob.valueOf('teste');
        document.DeveloperName = 'test2_test_jpg';
        document.Type = 'PDF';
        document.IsPublic =true;
        document.FolderId = UserInfo.getUserId();
        insert document;
        system.assert(document.Id != null);
        
        //Start test
        test.startTest();

        SiteFileBrowser sfb = new SiteFileBrowser();
        sfb.getSalesforceUrl();

        //Verifying inFolderId is equals '0'
        System.assertEquals('0',sfb.inFolderId );
        
        //Stop Test
        test.stopTest();
    }
}