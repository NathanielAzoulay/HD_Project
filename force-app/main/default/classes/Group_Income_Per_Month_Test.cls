@isTest (seealldata=false) 
public class Group_Income_Per_Month_Test {
    @isTest (seealldata=false) 
    static void updateActualStudentFieldOnDelete_Test(){
        ObjectCreator.TestEnviroment te = new ObjectCreator.TestEnviroment();
        
        Id recordTypeId = Schema.SObjectType.Group_Income_Per_Month__c.getRecordTypeInfosByName().get('Calculated Student').getRecordTypeId();
		
        Group_Income_Per_Month__c gipm1 = ObjectCreator.getNewGroupIncomePerMonth(te.agreeId, te.lgId);
        gipm1.RecordTypeId = recordTypeId;
        gipm1.Student__c = te.studentContactId;
        gipm1.Actual_Student__c = 1;
        Group_Income_Per_Month__c gipm2 = gipm1.clone(false, true, false, false);
        gipm2.Actual_Student__c = 0;
        
        insert new List<Group_Income_Per_Month__c>{gipm1, gipm2};
        
        system.debug( 'Actual_Student__c: ' + [SELECT Actual_Student__c FROM Group_Income_Per_Month__c WHERE Id = :gipm2.Id LIMIT 1][0].Actual_Student__c );
        
        delete gipm1;
        
        
    }
    
    static testMethod void updateDuration_Test(){
    	ObjectCreator.TestEnviroment te = new ObjectCreator.TestEnviroment();
        Id recordTypeId = Schema.SObjectType.Group_Income_Per_Month__c.getRecordTypeInfosByName().get('Calculated Student').getRecordTypeId();
		Group_Income_Per_Month__c gipm1 = ObjectCreator.getNewGroupIncomePerMonth(te.agreeId, te.lgId);
        gipm1.RecordTypeId = recordTypeId;
       	gipm1.LG__c = te.lgId;
        gipm1.Agreement__c = te.agreeId;
        gipm1.Royalty_Start_Date__c = Date.newInstance(2017, 12, 1);
        gipm1.Royalty_End_Date__c = null;
        
        insert gipm1;
        gipm1.Royalty_End_Date__c = Date.newInstance(2017, 12, 22);
        update gipm1;
        Group_Income_Per_Month__c gipm2 = gipm1.clone(false, true, false, false);
        gipm2.Royalty_Start_Date__c = Date.newInstance(2018, 1, 8);
        insert gipm2;
	}
}