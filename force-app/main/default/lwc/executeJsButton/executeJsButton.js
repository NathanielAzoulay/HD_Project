import { LightningElement, api } from 'lwc';

export default class ExecuteJsButton extends LightningElement {
    @api recordId;

    handleClick() {
        if (window.location.href.includes('/HDC')) {
            window.location.href = `/HDC/apex/Document_AWSUpload?parentIdForRedirect=${this.recordId}&Name=${this.recordId}`;
        } else {
            window.location.href = `/apex/Document_AWSUpload?parentIdForRedirect=${this.recordId}&Name=${this.recordId}`;
        }
    }
}