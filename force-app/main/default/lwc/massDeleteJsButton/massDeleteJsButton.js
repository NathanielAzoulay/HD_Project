import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class MassDeleteJsButton extends NavigationMixin(LightningElement) {
    @api recordIds;

    handleClick() {
        if (!this.recordIds || this.recordIds.length === 0) {
            alert('Please select a record');
            return;
        }

        if (confirm('TEST')) {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: '/apex/MassManager__MassDelete?deleteIds=' + this.recordIds.join(',') + '&selectedObject=lead'
                }
            });
        }
    }
}