import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
import relatedListResource from '@salesforce/resourceUrl/relatedListResource';
import saveHistory from '@salesforce/apex/RelatedListController.saveHistory';


export default class RelatedListNewEditPopup extends LightningElement {
    @api sobjectLabel
    @api relatedRecord
    @api historyRec;

    eventValue = '';
    @api fieldValue = '';
    loading = true;

    get clearDisabled(){
        return this.historyRec.megatools__Created_Date_DL__c == undefined;
    }

    get updatedRecord(){
        return (this.historyRec != undefined && this.historyRec.megatools__Event__c == 'Updated') || !this.relatedRecord;
    }

    get eventOptions() {
        return [
            { label: 'Created', value: 'Created' },
            { label: 'Deleted', value: 'Deleted' },
            { label: 'Undeleted', value: 'Undeleted' }
        ];
    }

    @api fieldOptions;

    handleEventChange(event){
        this.eventValue = event.detail.value;
        let historyRecord = {...this.historyRec};
        historyRecord.megatools__Event__c = event.detail.value;
        this.historyRec = historyRecord;
    }

    handleFieldChange(event){
        this.eventValue = event.detail.value;
        let historyRecord = {...this.historyRec};
        historyRecord.megatools__Field__c = event.detail.value;
        this.historyRec = historyRecord;
    }

    handleRecordIdChange(event){
        let historyRecord = {...this.historyRec};
        historyRecord.megatools__Record__c = event.detail.value;
        this.historyRec = historyRecord;
    }

    handleRecordNameChange(event){
        let historyRecord = {...this.historyRec};
        historyRecord.megatools__Record_Name__c = event.detail.value;
        this.historyRec = historyRecord;
    }

    handleAddId1Change(event){
        let historyRecord = {...this.historyRec};
        historyRecord.megatools__Additional_Field_1__c = event.detail.value;
        this.historyRec = historyRecord;
    }

    handleAddId2Change(event){
        let historyRecord = {...this.historyRec};
        historyRecord.megatools__Additional_Field_2__c = event.detail.value;
        this.historyRec = historyRecord;
    }

    handleOldValueChange(event){
        let historyRecord = {...this.historyRec};
        historyRecord.megatools__Old_Value__c = event.detail.value;
        this.historyRec = historyRecord;
    }

    handleOldValueExtndedChange(event){
        let historyRecord = {...this.historyRec};
        historyRecord.megatools__Old_Value_Extended__c = event.detail.value;
        this.historyRec = historyRecord;
    }

    handleNewValueChange(event){
        let historyRecord = {...this.historyRec};
        historyRecord.megatools__New_Value__c = event.detail.value;
        this.historyRec = historyRecord;
    }

    handleNewValueExtndedChange(event){
        let historyRecord = {...this.historyRec};
        historyRecord.megatools__New_Value_Extended__c = event.detail.value;
        this.historyRec = historyRecord;
    }

    handleCreatedDateChange(event){
        let historyRecord = {...this.historyRec};
        historyRecord.megatools__Created_Date_DL__c = event.detail.value;
        this.historyRec = historyRecord;
    }

    handleClearCreatedDate(){
        let historyRecord = {...this.historyRec};
        historyRecord.megatools__Created_Date_DL__c = undefined;
        this.historyRec = historyRecord;
    }

    handleValueSelectedOnUser(event){
        let historyRecord = {...this.historyRec};
        if(event.detail.id) historyRecord.megatools__Created_By_DL__c = event.detail.id;
        else historyRecord.megatools__Created_By_DL__c = undefined;
        this.historyRec = historyRecord;
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent("close"));             
    }

    get isNew(){
        return this.historyRec == undefined ? true : this.historyRec.Id == undefined;
    }

    get header(){
        return this.isNew ? `New ${this.sobjectLabel} Record` : `Edit ${this.sobjectLabel} Record`
    }

    get relatedHeader(){
        return this.isNew ? `New Related ${this.sobjectLabel} Record` : `Edit Related ${this.sobjectLabel} Record`
    }

    handleSave(){

        let histRecId = this.template.querySelector('.historyRecName');
        let historyField = this.template.querySelector('.historyField');
        console.log('this.historyRec.megatools__Record_Name__c>>'+this.historyRec.megatools__Record_Name__c);
        if(this.relatedRecord == true && this.historyRec.megatools__Record_Name__c == undefined){
            console.log('test1>>');
            histRecId.setCustomValidity("Field is required.");
        } else if(this.updatedRecord && this.historyRec.megatools__Field__c == undefined){
            console.log('test12>>');
            historyField.setCustomValidity("Field is required.");
            historyField.reportValidity();
        } else {
            if(histRecId) histRecId.setCustomValidity("");
            if(historyField) historyField.setCustomValidity("");
            saveHistory({ historyString : JSON.stringify(this.historyRec) })
            .then(() => {
                let message = `${(this.relatedRecord ? "Related "+this.sobjectLabel : this.sobjectLabel)} was ${(this.isNew ? "created" : "saved")}.`
                const evt = new ShowToastEvent({
                    title: message,
                    variant: "success"
                });
                this.dispatchEvent(evt);
                this.dispatchEvent(new CustomEvent("refreshdata"));    
                this.handleClose();     
            })
            .catch(error => {
                console.error(error);
                let title = "An error has occurred. Please contact the system administrator for further assistance.";
                if(error.body.message.startsWith('Invalid id:')) {
                    let histRecId = this.template.querySelector('.historyRecId');
                    histRecId.setCustomValidity('Record Id is an invalid Id, please try again.');
                    histRecId.reportValidity();
                } else {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: title,
                            message: error.body.message,
                            variant: "error",
                        }),
                    );
                }
            }); 
        }
        histRecId.reportValidity();
    }    

    renderedCallback() {
        loadStyle(this, relatedListResource + '/relatedListNewEditPopup.css');
        if(this.historyRec != undefined) {
            this.eventValue = this.historyRec.megatools__Event__c;
            this.loading = false;
        }
    }  
    
    
    
}