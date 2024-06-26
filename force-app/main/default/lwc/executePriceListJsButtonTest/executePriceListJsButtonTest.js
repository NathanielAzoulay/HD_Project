import { LightningElement, api } from 'lwc';

export default class ExecutePriceListJsButton extends LightningElement {
    @api recordId; 

    connectedCallback() {
        const url = `${window.location.origin}/apex/manageProductPrices?id=${this.recordId}&retURL=${window.location.origin}/${this.recordId}`;

        window.location.href = url;
    }
}