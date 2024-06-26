@isTest
public class NewSupportCommentControllerTest {
    @isTest static void testGetCase() {
        // Créer un enregistrement Case pour le test
        Case c = new Case();
        insert c;

        // Appeler la méthode getCase et vérifier qu'elle retourne le bon Case
        Case result = NewSupportCommentController.getCase(c.Id);
        System.assertEquals(c.Id, result.Id);
    }

    @isTest static void testGetSupportComment() {
        // Créer un enregistrement Case pour le test
        Case c = new Case();
        insert c;

        // Créer un enregistrement Support_Comment__c pour le test
        Support_Comment__c sc = new Support_Comment__c(Case__c = c.Id);
        insert sc;

        // Appeler la méthode getSupportComment et vérifier qu'elle retourne le bon Support_Comment__c
        Support_Comment__c result = NewSupportCommentController.getSupportComment(c.Id);
        System.assertEquals(sc.Id, result.Id);
    }
}