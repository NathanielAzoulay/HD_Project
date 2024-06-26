/******************************************************************************* 
    Name              : Batch_CreateManagerContactSharing
    Description       : relegated from trigger to avoid limit 50.000 rows
    Revision History  :-
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
    ----------------------------------------------------------------------------------------
    1. G. Fernandez             06/03/2017              Yaara                 [SW-25148]
    *******************************************************************************/
global class Batch_CreateManagerContactSharing implements Database.Batchable<Id>, Database.Stateful {

    public Map<Id,Id> accManagerIds;
    public Map<Id,Id> accChilds;
    List<SObject> obj2ins;

    global Iterable<Id> start(Database.BatchableContext bc) {
        List<ContactShare> contactsh2ins = new List<ContactShare>();
        obj2ins = new List<SObject>();
        for(Contact contact: [SELECT AccountId, Id FROM Contact WHERE AccountId IN :accManagerIds.keySet()]){
            //1.2.3.1 R/W Permissions on all the Contact related to the Account where Account. Partner Account Manager is updated
            if(accManagerIds.containsKey(contact.AccountId)){
                Id uId = accManagerIds.get(contact.AccountId);
                contactsh2ins.add(new ContactShare(ContactId = contact.Id, UserOrGroupId = uId, ContactAccessLevel = 'Edit'));
            }                
        }

        if(!contactsh2ins.isEmpty()){
            Database.SaveResult[] newSharingData = database.insert(contactsh2ins, false);
            system.debug('newSharingData: ' + newSharingData);
        }

        List<Id> childIds = new List<Id>();
        childIds.addAll(accChilds.keySet());

        return childIds;
    }

    global void execute(Database.BatchableContext BC, list<Id> childIds) {
        system.debug('childIds: ' + childIds);
                
        Map<Id,Set<Id>> contactIds = new Map<Id,Set<Id>>();
        Id parentId = accChilds.get(childIds[0]);
        Id managerId = accManagerIds.get(parentId);

        Map<Id,Contact> contacts2share = new Map<Id,Contact>([SELECT AccountId, Id FROM Contact WHERE AccountId IN :childIds]);
        for(Contact contact: contacts2share.values()){
            //1.2.3.2 R/W permission on all the contact of the children accounts of that account
            if(accChilds.containsKey(contact.AccountId)){
                contactIds.put(contact.Id, new Set<Id>());
            }                 
        }

        for (ContactShare cs : [SELECT Id, ContactId, UserOrGroupId FROM ContactShare WHERE ContactId IN :contactIds.keySet() AND ContactAccessLevel = 'Edit' AND UserOrGroupId = :managerId]) {
            contactIds.get(cs.ContactId).add(cs.UserOrGroupId);
        }

        List<ContactShare> contactsh2ins = new List<ContactShare>();
        for(Contact contact: contacts2share.values()){
            //1.2.3.2 R/W permission on all the contact of the children accounts of that account
            if(accChilds.containsKey(contact.AccountId)){
                Set<Id> existentPermission = contactIds.get(contact.Id);
                if(!existentPermission.contains(managerId)){
                    contactsh2ins.add(new ContactShare(ContactId = contact.Id, UserOrGroupId = managerId, ContactAccessLevel = 'Edit'));
                } 
            }                 
        }

        if(!contactsh2ins.isEmpty() && contactsh2ins.size() < 10000){
            Database.SaveResult[] newSharingData = database.insert(contactsh2ins, false);
            system.debug('newSharingData: ' + newSharingData);
        }else if(!contactsh2ins.isEmpty()){
            obj2ins.addAll((List<SObject>) contactsh2ins);
        }
    }

    global void finish(Database.BatchableContext BC) {
        Batch_InsertShareRecords b = new Batch_InsertShareRecords();
        b.newSharingRecords = obj2ins;
        b.objType = 'ContactShare';
        
        if(!obj2ins.isEmpty() && !Test.isRunningTest()){
            Database.executeBatch(b,100);
            //Database.SaveResult[] newSharingData = database.insert(lg2sh, false);
            //system.debug('newSharingData: ' + newSharingData);
        }
    }
}