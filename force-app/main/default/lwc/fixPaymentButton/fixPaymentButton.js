import { LightningElement, api } from 'lwc';
import generate_LGPayments2LGStudent from '@salesforce/apex/LG_Student_Buttons.generate_LGPayments2LGStudent';

export default class FixPaymentButton extends LightningElement {
    @api recordId;

    handleClick() {
        generate_LGPayments2LGStudent({ lgSId: this.recordId })
            .then(result => {
                if (result != '') {
                    alert(result);
                } else {
                    location.reload();
                }
            })
            .catch(error => {
                console.error('Error', error);
            });
    }
}