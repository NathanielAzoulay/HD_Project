public with sharing class LGCreateLessons {    
    
    @InvocableMethod(label='Create Lessons')
    public static void handleCreateLessons(List<Id> recordsIds) {
        for (Id recordId : recordsIds) {
            LGCreateLessonsNew_Ctl ctrl = new LGCreateLessonsNew_Ctl(recordId);
            ctrl.doCreateForEndDate();
        }
    }
}