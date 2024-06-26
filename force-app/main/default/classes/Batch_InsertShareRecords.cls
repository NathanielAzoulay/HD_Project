/******************************************************************************* 
    Name              : Batch_InsertShareRecords
    Description       : relegated from trigger to avoid 10.000 dml
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             06/03/2017              Yaara                 [SW-25148]
    *******************************************************************************/
global class Batch_InsertShareRecords implements Database.Batchable<sObject> {
    public List<sObject> newSharingRecords;
    public String objType;

    global Iterable<Sobject> start(Database.BatchableContext bc) {
        return newSharingRecords;
    }

    global void execute(Database.BatchableContext BC, list<Sobject> scope) {

        String listType = 'List<' + objType + '>';
        List<SObject> castRecords = (List<SObject>)Type.forName(listType).newInstance();
        castRecords.addAll(scope);

        insert castRecords;
        
    }

    global void finish(Database.BatchableContext BC) {

    }
}