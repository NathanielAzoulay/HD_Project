import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getCase from '@salesforce/apex/NewSupportCommentController.getCase';
import getSupportComment from '@salesforce/apex/NewSupportCommentController.getSupportComment';

export default class SupportCommentButton extends NavigationMixin(LightningElement) {
    @api recordId;

    @wire(getCase, { caseId: '$recordId' })
    case;

    @wire(getSupportComment, { caseId: '$recordId' })
    supportComment;

    handleClick() {
        if (this.supportComment.data && this.case.data) {
            const supportCommentName = this.supportComment.data.Name;
            const supportCommentId = this.supportComment.data.Id;
            const caseNumber = this.case.data.CaseNumber;
            const caseId = this.recordId;
    
            let url;
            if (window.location.href.includes('/HDC')) {
                url = `/HDC/a2G/e?CF00NF0000008S0Qj=${supportCommentName}&CF00NF0000008S0Qj_lkid=${supportCommentId}&CF00ND0000006gtdO=${caseNumber}&retURL=%2F${caseId}&saveURL=%2F${caseId}`;
            } else {
                url = `/a2G/e?CF00NF0000008S0Qj=${supportCommentName}&CF00NF0000008S0Qj_lkid=${supportCommentId}&CF00ND0000006gtdO=${caseNumber}&retURL=%2F${caseId}&saveURL=%2F${caseId}`;
            }
    
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: url
                }
            });
        }
    }
}