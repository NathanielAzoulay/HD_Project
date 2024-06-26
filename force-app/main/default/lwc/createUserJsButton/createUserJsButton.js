import { LightningElement, api } from 'lwc';
import validateConvertRequest from '@salesforce/apex/Batch_CreateUserFromContact.validateConvertRequest';

export default class CreateUserJsButton extends LightningElement {
    @api recordId;

    handleClick() {
        validateConvertRequest({ convertContactId: this.recordId })
            .then(result => {
                result = JSON.parse(result);
                console.log(result);
                if (result.error) {
                    alert(result.error);
                }
                if (result.status === 'Success') {
                    location.reload();
                }
            })
            .catch(error => {
                console.error('Error', error);
            });
    }
}