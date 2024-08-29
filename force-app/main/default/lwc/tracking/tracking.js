import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { loadStyle } from 'lightning/platformResourceLoader';
import iconColor from '@salesforce/resourceUrl/iconColor';
import getTrackingRecords from '@salesforce/apex/TrackingController.getRecords';
import getObjectDetails from '@salesforce/apex/TrackingController.getObjectDetails';
import getObjectSelectedDetails from '@salesforce/apex/TrackingController.getObjectSelectedDetails';
import getObjects from '@salesforce/apex/TrackingController.getObjects';
import submitMetaData from '@salesforce/apex/TrackingController.submitMetaData';
import generateMetadata from '@salesforce/apex/TrackingController.generateMetadata';
import deployMetadataFiles from '@salesforce/apex/TrackingController.deployMetaData';
export default class Tracking extends LightningElement {
   
    @track mdColumns = [
        {
            label: 'Name', 
            fieldName: 'mdName', 
            type: 'text'            
        },
        { 
            label: 'Type', 
            initialWidth: 150,
            fieldName: 'mdType', 
            type: 'text' 
        },
        { 
            label: 'Object', 
            initialWidth: 150,
            fieldName: 'mdObject', 
            type: 'text'
        },
        { 
            label: 'Operation', 
            initialWidth: 150,
            fieldName: 'mdOperation', 
            type: 'text'
        },
        {
            type: 'button',
            initialWidth: 120,
            typeAttributes: { 
                label: 'Deploy', 
                iconName: 'utility:target_mode',
                name: 'deploy_md', 
                variant: 'brand',
                title: 'Deploy'
            }
        }
    ];

    @track columns = [
        {
            label: 'Object', 
            initialWidth: 180,
            fieldName: 'objectName', 
            type: 'text'            
        },
        { 
            label: 'Parent Reference', 
            initialWidth: 180,
            fieldName: 'parentRef', 
            type: 'text' 
        },
        { 
            label: 'Events', 
            initialWidth: 200,
            fieldName: 'events', 
            type: 'text'
        },
        { 
            label: 'Custom Tracked Fields', 
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
            label: 'Metadata Status', 
            initialWidth: 160,
            fieldName: 'mdtStatusLabel',
            cellAttributes: { 
                class: {fieldName: 'mdtStatusClass'}
            }
        },
        {
            label: 'Trigger Status', 
            initialWidth: 160,
            fieldName: 'trigStatusLabel',
            cellAttributes: { 
                class: {fieldName: 'trigStatusClass'}
            }
        },
        {
            type: 'button-icon',
            initialWidth: 60,
            typeAttributes: { 
                label: 'Edit', 
                iconName: 'utility:delete',
                name: 'delete_tracking', 
                variant: 'border-filled',
                title: 'Delete',
                iconClass: 'myCustomDatatableIconColor'
            }
        }
    ];

    _wiredData;
    loading;
    @track trackingData;
    @track mdData;
    @track editModal = false;
    showObjectLookup = false;
    @track selectedObject = {};
    @track options = [];
    @track values = [];
    @track requiredOptions = [];
    @track parentRefs = [];
    objects = [];
    objectSelected = '';
    @track deleteConfirmModal = false;
    @track deployModal = false;
    @track trackingDeployment;
    

    get deploymentComplete(){
        var hasPending = false;
        if(this.trackingData){
            for(var obj of this.trackingData){
                if(obj.trigStatusLabel != 'Deployed' || obj.mdtStatusLabel != 'Deployed') hasPending = true;
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

    get hasSelectedObject(){
        return this.objectSelected != '' || JSON.stringify(this.selectedObject) != '{}';
    }

    connectedCallback(){
        if(this.trackingData == undefined) this.loading = true;
        loadStyle(this, iconColor);
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
        this.loading = true;
        this.showObjectLookup = true;
        this.editModal = true;
        this.selectedObject = {};
        getObjects()
        .then((data) => {
            const items = [];
            for(var o of data){
                items.push({
                    label: o.objectLabel+'('+o.objectName+')',
                    value: o.objectName
                });
            }
            this.objects.push(...items);
            this.loading = false;
        })
        .catch(error => {
			console.error(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "An error has occurred. Please contact the system administrator for further assistance.",
                    message: error.body.message,
                    variant: "error",
                }),
            );
            this.loading = false;
		}); 
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        console.log(actionName);
        const row = event.detail.row;
        console.log(row);
        switch (actionName) {
            case 'delete_tracking':
                this.deleteTracking(row);
                break;
            case 'edit_tracking':
                this.editTracking(row);
                break;
            case 'deploy_md':
                this.deployMetadata(row);
                break;
            default:
        }
    }

    deleteTracking(row){
        console.log(JSON.stringify(row));
        this.deleteConfirmModal = true;
        this.selectedObject = {...row};
    }

    editTracking(row) {
        this.loading = true;
        this.showObjectLookup = false;
        this.editModal = true;
        this.selectedObject = {...row};
        getObjectDetails({ wrapperString : JSON.stringify(this.selectedObject) })
        .then((data) => {
            this.selectedObject = data;
            const items = [];
            const selected = [];
            const required = [];
            const parentItems = [];
            for(var f of data.fieldList){
                items.push({
                    label: f.fieldLabel+'('+f.fieldAPIName+')',
                    value: f.fieldAPIName
                });
                if(f.standardTracked){
                    selected.push(f.fieldAPIName);
                    required.push(f.fieldAPIName);
                } else if(f.customTracked){
                    selected.push(f.fieldAPIName);
                }
            }
            for(var f in data.parentRefMap){
                parentItems.push({
                    label: data.parentRefMap[f]+'('+f+')',
                    value: f
                });
            }
            this.options.push(...items);
            this.values.push(...selected);
            this.requiredOptions.push(...required);
            this.parentRefs.push(...parentItems);
            this.loading = false;
        })
        .catch(error => {
			console.error(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "An error has occurred. Please contact the system administrator for further assistance.",
                    message: error.body.message,
                    variant: "error",
                }),
            );
            this.loading = false;
		}); 
        
    }

    handleClose() {
        this.editModal = false;
        this.deleteConfirmModal = false;
        this.deployModal = false;
        refreshApex(this._wiredData);
        this.options = [];
        this.values = [];
        this.requiredOptions = [];
        this.parentRefs = [];
        this.objectSelected = '';
    }

    handleSave(){
        this.loading = true;
        submitMetaData({ wrapperString : JSON.stringify(this.selectedObject), trackingData : JSON.stringify(this.trackingData), fields : this.values })
        .then((data) => {
            this.trackingData = data;
        })
        .catch(error => {
			console.error(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "An error has occurred. Please contact the system administrator for further assistance.",
                    message: error.body.message,
                    variant: "error",
                }),
            );
            this.loading = false;
		}); 
        refreshApex(this._wiredData);
        this.selectedObject = {};
        this.handleClose();
        this.loading = false;
    }

    handleDelete(){
        if(this.selectedObject.trigStatusLabel == 'Not Deployed' && this.selectedObject.mdtStatusLabel == 'Not Deployed') {
            let trackingList = [];
            for(var tracking of this.trackingData){
                if(tracking.objectName != this.selectedObject.objectName) trackingList.push(tracking);
            }
            this.trackingData = trackingList;
        } else {
            let trackingList = [];
            for(var tracking of this.trackingData){
                if(tracking.objectName != this.selectedObject.objectName) trackingList.push(tracking);
            }
            this.selectedObject.mdtStatusLabel = 'Pending Removal';
            this.selectedObject.mdtStatusClass = 'slds-text-color_weak slds-text-title_caps';
            this.selectedObject.trigStatusLabel = 'Pending Removal';
            this.selectedObject.trigStatusClass = 'slds-text-color_weak slds-text-title_caps';
            trackingList.push(this.selectedObject);
            this.trackingData = trackingList;
        }
        this.handleClose();
    }

    openDeployModal(){
        this.loading = true;
        generateMetadata({trackingData : JSON.stringify(this.trackingData)})
        .then((data) => {
            this.mdData = data;
            this.deployModal = true;
            this.loading = false;
        })
        .catch(error => {
			console.error(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "An error has occurred. Please contact the system administrator for further assistance.",
                    message: error.body.message,
                    variant: "error",
                }),
            );
            this.loading = false;
		}); 
    }

    deployMetadata(row){
        this.loading = true;
        deployMetadataFiles({ mdRow : JSON.stringify(row) })
        .then(() => {
            let mdList = [];
            for(var md of this.mdData){
                if(row.mdName != md.mdName) mdList.push(md);
            }
            this.mdData = mdList;
            refreshApex(this._wiredData);
            this.loading = false;
        })
        .catch(error => {
			console.error(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "An error has occurred. Please contact the system administrator for further assistance.",
                    message: error.body.message,
                    variant: "error",
                }),
            );
            this.loading = false;
		}); 
        
    }

    handleObjectSelected(event) {
        this.objectSelected = event.detail.value;
        this.options = [];
        this.values = [];
        this.requiredOptions = [];
        this.parentRefs = [];
        getObjectSelectedDetails({ objectName : this.objectSelected })
        .then((data) => {
            this.selectedObject = {...data};
            const items = [];
            const selected = [];
            const required = [];
            const parentItems = [];
            for(var f of data.fieldList){
                items.push({
                    label: f.fieldLabel+'('+f.fieldAPIName+')',
                    value: f.fieldAPIName,
                });
                if(f.standardTracked){
                    selected.push(f.fieldAPIName);
                    required.push(f.fieldAPIName);
                } else if(f.customTracked){
                    selected.push(f.fieldAPIName);
                }
            }
            for(var f in data.parentRefMap){
                parentItems.push({
                    label: data.parentRefMap[f]+'('+f+')',
                    value: f
                });
            }
            this.options.push(...items);
            this.values.push(...selected);
            this.requiredOptions.push(...required);
            this.parentRefs.push(...parentItems);
            this.loading = false;
        })
        .catch(error => {
			console.error(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "An error has occurred. Please contact the system administrator for further assistance.",
                    message: error.body.message,
                    variant: "error",
                }),
            );
            this.loading = false;
		}); 
    }

    handleParentChange(event) {
        let tempObj = {...this.selectedObject};
        tempObj.parentRef = event.detail.value;
        this.selectedObject = {...tempObj};
    }

    handleTrackCreate(event) {
        let tempObj = {...this.selectedObject};
        tempObj.trackCreate = event.detail.checked;
        this.selectedObject = {...tempObj};
    }

    handleTrackDelete(event) {
        let tempObj = {...this.selectedObject};
        tempObj.trackDelete = event.detail.checked;
        this.selectedObject = {...tempObj};
    }

    handleTrackUndelete(event) {
        let tempObj = {...this.selectedObject};
        tempObj.trackUndelete = event.detail.checked;
        this.selectedObject = {...tempObj};
    }

    handleAdditionalField1(event) {
        let tempObj = {...this.selectedObject};
        tempObj.additionalField1 = event.detail.value;
        this.selectedObject = {...tempObj};
    }

    handleAdditionalField2(event) {
        let tempObj = {...this.selectedObject};
        tempObj.additionalField2 = event.detail.value;
        this.selectedObject = {...tempObj};
    }

    handleFieldChange(event) {
        this.values = event.detail.value;
    }

}