import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import relatedListResource from '@salesforce/resourceUrl/relatedListResource';


export default class RelatedListNewEditPopup extends LightningElement {
    @api sobjectLabel
    @api historyRec;

    get loading(){
        return this.historyRec == undefined;
    }

    get header(){
        return `View Related ${this.sobjectLabel} Record`
    }

    get updatedRecord(){
        return this.historyRec != undefined && this.historyRec.megatools__Event__c == 'Updated';
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent("close"));             
    }

    renderedCallback() {
        loadStyle(this, relatedListResource + '/relatedListNewEditPopup.css');
    }  
}