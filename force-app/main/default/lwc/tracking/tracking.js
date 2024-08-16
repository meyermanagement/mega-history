import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getTrackingRecords from '@salesforce/apex/TrackingController.getRecords'
import getObjectDetails from '@salesforce/apex/TrackingController.getObjectDetails'

export default class Tracking extends LightningElement {
   

    @track columns = [
        {
            label: 'Object', 
            initialWidth: 200,
            fieldName: 'objectName', 
            type: 'text'            
        },
        { 
            label: 'Parent Reference', 
            initialWidth: 200,
            fieldName: 'parentRef', 
            type: 'text' 
        },
        { 
            label: 'Events', 
            initialWidth: 250,
            fieldName: 'events', 
            type: 'text'
        },
        { 
            label: 'Tracked Fields', 
            fieldName: 'fields', 
            type: 'text'
        },
        {
            type: 'button',
            initialWidth: 100,
            typeAttributes: { 
                label: 'Edit', 
                iconName: 'utility:edit',
                name: 'edit_tracking', 
                variant: 'brand',
                title: 'Edit'
            }
        },
        {
            label: 'Deployment Status', 
            initialWidth: 180,
            fieldName: 'statusLabel',
            cellAttributes: { 
                class: {fieldName: 'statusClass'}
            }
        }
    ];

    _wiredData;
    loading;
    trackingData;
    @track editModal = false;
    showObjectLookup = false;
    @track selectedObject = {};
    @track selectedFields = [];

    get deploymentComplete(){
        var hasPending = false;
        if(this.trackingData){
            for(var obj of this.trackingData){
                if(obj.statusLabel == 'Not Deployed') hasPending = true;
            }
        }
        return !hasPending;
    }

    get hasParentRef(){
        return this.selectedObject.parentRef != undefined && this.selectedObject.parentRef != '';
    }

    get trackDelete(){
        return this.selectedObject.trackDelete == true;
    }

    connectedCallback(){
        if(this.trackingData == undefined) this.loading = true;
    }

    @wire(getTrackingRecords)
    getData(result) {
        this._wiredData = result;
        if(result.data){
            this.trackingData = result.data;
        } else if (result.error) {
            console.log(result.error.body.message);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "An error has occurred. Please contact the system administrator for further assistance.",
                    message: result.error.body.message,
                    variant: "error",
                }),
            );
        }
        this.loading = false;
    }

    newTracking() {
        this.showObjectLookup = true;
        this.editModal = true;
        this.selectedObject = {};
        
    }

    editTracking(event) {
        this.showObjectLookup = false;
        this.editModal = true;
        this.selectedObject = {...event.detail.row};
        getObjectDetails({ wrapperString : JSON.stringify(this.selectedObject) })
        .then((data) => {
            this.loading = false;
            this.selectedFields = data;
        })
        .catch(error => {
			console.error(error);
            this.loading = false;
		}); 
        
    }

    handleClose() {
        this.editModal = false;
        return refreshApex(this._wiredData);
    }

    handleSave(){
        console.log('handleSave>>'+JSON.stringify(this.selectedObject));
        this.loading = true;
        refreshApex(this._wiredData);
        this.selectedObject = {};
        this.editModal = false;
        this.loading = false;
    }

    deploy(){
        this.loading = true;
        refreshApex(this._wiredData);
        this.loading = false;
    }

    handleObjectChange(event) {
        this.selectedObject.objectName = event.detail.value;
    }

    handleParentChange(event) {
        this.selectedObject.parentRef = event.detail.value;
    }

    handleTrackCreate(event) {
        this.selectedObject.trackCreate = event.detail.checked;
    }

    handleTrackDelete(event) {
        this.selectedObject.trackDelete = event.detail.checked;
    }

    handleTrackUndelete(event) {
        this.selectedObject.trackUndelete = event.detail.checked;
    }

    handleAdditionalField1(event) {
        this.selectedObject.additionalField1 = event.detail.value;
    }

    handleAdditionalField2(event) {
        this.selectedObject.additionalField2 = event.detail.value;
    }

}