global class Batch_CreateLGStudentAssessments implements Database.Batchable<sObject>, Database.Stateful {
    
    public Map<String,Set<Id>> bcAssessMap = new Map<String,Set<Id>>();
    Map<Id,Set<Id>> existentStudentAssess = new Map<Id,Set<Id>>();
    public Set<String> bcIds =  new Set<String>();

    global Batch_CreateLGStudentAssessments() {
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        Set<Id> bcAssessIds = new Set<Id>();
        for (String bcId : bcAssessMap.keySet()) {
            bcIds.add(bcId);
            bcAssessIds.addAll(bcAssessMap.get(bcId));
        }

        //3.2.1.5 If already exists LG Student Assessment with the same LG Student and BC Assessment – Don't create the record.
        for (LG_Student_Assessment__c studentAssess : [SELECT Id, BC_Assessment__c, LG_Student__c FROM LG_Student_Assessment__c WHERE BC_Assessment__c IN :bcAssessIds AND BC_Assessment__r.Base_Course__r.Status__c = 'Active']) {
            if(!existentStudentAssess.containsKey(studentAssess.BC_Assessment__c)){
                existentStudentAssess.put(studentAssess.BC_Assessment__c, new Set<Id>());
            }
            existentStudentAssess.get(studentAssess.BC_Assessment__c).add(studentAssess.LG_Student__c);
        }

        String query = 'SELECT Id, Base_Course_Id__c FROM LG_Student__c WHERE Completed__c = false AND Status_in_LG__c = \'Registered\' AND LG__r.Course_Sub_Type__r.Base_Course__c IN :bcIds AND LG__r.Course_Sub_Type__r.Base_Course__r.Status__c = \'Active\'';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, list<Sobject> scope) {

        //3.2.1.4 Go over all LG Student where Base Course ID = BC Assessment.Base Course & LG Student.Completed is False & LG Student.Status in LG = Registered
        //create LG Student Assessment related to new BC Assessment
        List<LG_Student_Assessment__c> newStudentAssessments = new List<LG_Student_Assessment__c>();
        for (LG_Student__c lgStudent : (List<LG_Student__c>) scope) {   
            String id15 = String.valueOf(lgStudent.Base_Course_Id__c);
            if(bcAssessMap.containsKey(id15)){
                for (Id bcAssessId : bcAssessMap.get(id15)) {
                    Boolean cond = existentStudentAssess.isEmpty();
                    cond = cond || !existentStudentAssess.containsKey(bcAssessId);
                    cond = cond || !existentStudentAssess.get(bcAssessId).contains(lgStudent.Id);
                    if(cond){
                        LG_Student_Assessment__c newAssessment = new LG_Student_Assessment__c();
                        newAssessment.LG_Student__c = lgStudent.Id;
                        newAssessment.BC_Assessment__c = bcAssessId;
                        newStudentAssessments.add(newAssessment);
                    }
                }
            }
        }

        if(!newStudentAssessments.isEmpty()){
            insert newStudentAssessments;
        }
    }

    global void finish(Database.BatchableContext BC) {

    }
}