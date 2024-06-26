@isTest
Private class DocumentUtilTest {
    public static testMethod void unitTest() {
    
        //Getting OrganizationId
        Id org = UserInfo.getOrganizationId();
        
        //Creating Document
        Document document = new Document();
        //document.AuthorId = UserInfo.getUserId();
        document.FolderId = UserInfo.getUserId();
        document.Name = 'testDoc';
        document.body = Blob.valueOf('teste');
        document.DeveloperName = 'test2_test_jpg';
        insert document;
        system.assert(document.Id != null);
        
        //Start Test
        test.startTest();
        DocumentUtil du = new DocumentUtil();
        du.getUrl(document);
        DocumentUtil.getInstance();
        //Stop Test
        test.stopTest();
    }
}