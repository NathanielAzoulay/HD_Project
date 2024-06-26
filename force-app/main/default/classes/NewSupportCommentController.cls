public with sharing class NewSupportCommentController {
    @AuraEnabled(cacheable=true)
    public static Case getCase(Id caseId) {
        return [SELECT Id, CaseNumber FROM Case WHERE Id = :caseId];
    }

    @AuraEnabled(cacheable=true)
    public static Support_Comment__c getSupportComment(Id caseId) {
        return [SELECT Id, Name FROM Support_Comment__c WHERE Case__c = :caseId LIMIT 1];
    }
}