import { LightningElement, track, api } from 'lwc';
import getDuplicateContacts from '@salesforce/apex/ContactController.getDuplicateContacts';
import getContactData from '@salesforce/apex/ContactController.getContactData';
import uniteContact from '@salesforce/apex/ContactController.uniteContact';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class DedupeContacts extends LightningElement {
    @track contacts;
    @track selectedRows = [];
    @api recordId;
    duplicateContacts =[];
    showNoContacts= false;
    columns = [
        { label: 'Name', fieldName: 'Name', type: 'text' },
        { label: 'Email', fieldName: 'Email', type: 'email' },
        { label: 'Phone', fieldName: 'Phone', type: 'phone' },
        { label: 'Mobile', fieldName: 'MobilePhone', type: 'phone' },
        { label: 'Mailing country', fieldName: ' Mailing_Address_Country__c', type: 'text' },
        { label: 'Entity type', fieldName: 'Entity_Type__c', type: 'text' },
        { label: 'Record type', fieldName: 'Contact_Record_Type_Name_R__c', type: 'text' },
        { label: 'MF Name', fieldName: 'MF_Name__c', type: 'text' }
    ];

    connectedCallback(){
        console.log('this.contactId '+ this.recordId);
        this.getDuplicateContact();
    }

    getDuplicateContact(){
        getContactData({contactId: this.recordId})
            .then(result => { 
                console.log(JSON.stringify(result));
                this.email = result.Email;
                this.mobile = result.MobilePhone;
                this.phone = result.Phone;
                console.log(' this.email '+ this.email);
                console.log(' this.phone '+ this.phone);
                console.log(' this.mobile '+ this.mobile);
            })
            .catch(error => {
                this.error = error;
            });
            getDuplicateContacts({ email: this.email, phone: this.phone , mobile: this.mobile})
                .then(result => {
                    this.duplicateContacts = result;
                    if(this.duplicateContacts == null){
                        this.showNoContacts = true;
                    }
                    console.log(' this.duplicateContacts '+ this.duplicateContacts);

                })
                .catch(error => {
                    this.error = error;
                });
    }

    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows;
        this.parentId = this.selectedRows[0].Id;
        console.log('selected rows '+ JSON.stringify( this.selectedRows));
        console.log('parentId  '+ JSON.stringify( this.parentId));

        this.contacts = this.duplicateContacts.map((selectionnedContact) => ({
                ...selectionnedContact,
                selected: selectionnedContact.Id === this.parentId,
                // console.log('selcted '+this.selected );
            }));

        console.log('contacts '+JSON.stringify(this.contacts));

    }

    unite(event){
        console.log('label '+event.target.label);
        if(event.target.label === "yes"){
            this.dedupeTrigger = "2";
        }
        if(event.target.label === "no"){
            this.dedupeTrigger = "1";
        }
        uniteContact({dedupTrigger:this.dedupeTrigger, conId: this.recordId, parentId: this.parentId})
            .then(result => { 
                this.message = result.Message;
                // this.showToastError( 'Message',result.Message);  
                console.log(JSON.stringify(result));
            })
            .catch(error => {
                this.error = error;
            });
    }

    showToastError(title, message){
        const event = new ShowToastEvent({
            title: title,
            message: message,
        });
        this.dispatchEvent(event);
    }
}