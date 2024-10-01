/* eslint-disable no-console */
import { LightningElement , api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { deleteRecord } from 'lightning/uiRecordApi';
 
export default class RelatedListDeletePopup extends LightningElement {
    showModal = false
    @api sobjectLabel
    @api recordId
    @api recordName
    @api relatedRecord

    @api show() {
        this.showModal = true;
    }

    @api hide() {
        this.showModal = false;
    }

    handleClose() {
        this.showModal = false;     
    }
    handleDialogClose(){
        this.handleClose()
    }

    get body(){
        return `Are you sure you want to delete this ${this.sobjectLabel} Record?`
    }

    get relatedBody(){
        return `Are you sure you want to delete this Related ${this.sobjectLabel} Record?`
    }

    get header(){
        return `Confirm Delete`
    }    

    handleDelete(){
        console.log('this.recordId>>'+this.recordId);
        deleteRecord(this.recordId)
            .then(() => {    
                this.hide()
                let message = this.relatedRecord ? `Related ${this.sobjectLabel} was deleted.` : `${this.sobjectLabel} was deleted.`;
                const evt = new ShowToastEvent({
                    title: message,
                    variant: "success"
                });
                this.dispatchEvent(evt);
                this.dispatchEvent(new CustomEvent("refreshdata"));  
            }).catch(error => {
                const evt = new ShowToastEvent({
                    title: 'Error deleting record',
                    message: error.body.message,
                    variant: 'error'
                })
                this.dispatchEvent(evt)
            });
    }
    
}