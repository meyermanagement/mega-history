import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { loadStyle } from 'lightning/platformResourceLoader';
import iconColor from '@salesforce/resourceUrl/iconColor';
import {JSZip} from './jszip/jszip';
import getTrackingRecords from '@salesforce/apex/TrackingController.getRecords';
import getObjectDetails from '@salesforce/apex/TrackingController.getObjectDetails';
import getObjectSelectedDetails from '@salesforce/apex/TrackingController.getObjectSelectedDetails';
import getObjects from '@salesforce/apex/TrackingController.getObjects';
import submitMetaData from '@salesforce/apex/TrackingController.submitMetaData';
import generateMetadata from '@salesforce/apex/TrackingController.generateMetadata';
import handleCustomMetadata from '@salesforce/apex/TrackingController.handleCustomMetadata';
import deployTriggerFiles from '@salesforce/apex/TrackingController.deployTriggers';
import generateTriggerFiles from '@salesforce/apex/TrackingController.generateTriggerFiles';
import checkDeploymentStatus from '@salesforce/apex/TrackingController.checkAsyncRequest'; 
import MEGA_HISTORY_LOGO from "@salesforce/contentAssetUrl/MEGA_Main_Logo";
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
                title: 'Deploy',
                disabled: {fieldName: 'mdDisabled'}
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
    modalLoading;
    @track trackingData;
    @track mdData;
    @track editModal = false;
    showObjectLookup = false;
    @track selectedObject = {};
    @track parentOptions = [];
    @track parentValues = [];
    @track options = [];
    @track values = [];
    @track requiredOptions = [];
    objects = [];
    objectSelected = '';
    @track deleteConfirmModal = false;
    @track deployModal = false;
    @track trackingDeployment;
    asyncId;
    intervalId;
    logoUrl = MEGA_HISTORY_LOGO;
    

    get deploymentComplete(){
        var hasPending = false;
        if(this.trackingData){
            for(var obj of this.trackingData){
                if(obj.trigStatusLabel != 'Deployed' || obj.mdtStatusLabel != 'Deployed') hasPending = true;
            }
        }
        return !hasPending;
    }

    get disableDeployAll(){
        var hasDisabled = false;
        var hasRemove = false;
        var hasObjectOrTrigger = false;
        if(this.mdData){
            for(var obj of this.mdData){
                if(obj.mdDisabled == true) hasDisabled = true;
                if(obj.mdOperation == 'Remove') hasRemove = true;
                if(obj.mdType == 'Object' || obj.mdType == 'Trigger') hasObjectOrTrigger = true;
            }
        } else {
            hasDisabled = true;
        }
        return hasDisabled || hasRemove || hasObjectOrTrigger || this.modalLoading;
    }

    get hasParentRef(){
        return this.parentValues != undefined && this.parentValues.length > 0;
    }

    get trackDelete(){
        return this.selectedObject.trackDelete == true;
    }

    get hasSelectedObject(){
        return this.objectSelected != '' || JSON.stringify(this.selectedObject) != '{}' ;
    }

    get hasMetadata(){
        return this.trackingData != undefined && this.trackingData.length > 0;
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
        this.modalLoading = true;
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
            this.modalLoading = false;
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
            this.modalLoading = false;
		}); 
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
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
        this.deleteConfirmModal = true;
        this.selectedObject = {...row};
    }

    editTracking(row) {
        this.modalLoading = true;
        this.showObjectLookup = false;
        this.editModal = true;
        this.selectedObject = {...row};
        getObjectDetails({ wrapperString : JSON.stringify(this.selectedObject) })
        .then((data) => {
            this.selectedObject = data;
            if(this.selectedObject.parentRef == undefined) {
                let tempObj = {...this.selectedObject};
                tempObj.parentRef = '';
                this.selectedObject = {...tempObj};
            }
            if(this.selectedObject.additionalField1 == undefined) {
                let tempObj = {...this.selectedObject};
                tempObj.additionalField1 = '';
                this.selectedObject = {...tempObj};
            }
            if(this.selectedObject.additionalField2 == undefined) {
                let tempObj = {...this.selectedObject};
                tempObj.additionalField2 = '';
                this.selectedObject = {...tempObj};
            }
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
            for(var p in data.parentRefMap){
                parentItems.push({
                    label: data.parentRefMap[p]+'('+p+')',
                    value: p
                });
            }
            this.options.push(...items);
            this.values.push(...selected);
            this.requiredOptions.push(...required);
            this.parentOptions.push(...parentItems);
            if(data.parentRef != undefined){
                const parentSelected = data.parentRef.split(',');
                this.parentValues.push(...parentSelected);
            }
            this.modalLoading = false;
        })
        .catch(error => {
			console.error(JSON.stringify(error));
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "An error has occurred. Please contact the system administrator for further assistance.",
                    message: error.body.message,
                    variant: "error",
                }),
            );
            this.modalLoading = false;
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
        this.parentOptions = [];
        this.parentValues = [];
        this.objectSelected = '';
        this.mdData = [];
    }

    handleSave(){
        this.modalLoading = true;
        let tempObj = {...this.selectedObject};
        tempObj.parentRef = this.parentValues.toString();
        this.selectedObject = {...tempObj};
        submitMetaData({ wrapperString : JSON.stringify(this.selectedObject), trackingData : JSON.stringify(this.trackingData), fields : this.values })
        .then((data) => {
            this.trackingData = data;
            var objectList = [];
            for(var i of this.objects){
                if(i.value != this.selectedObject.objectName) objectList.push(i);
            }
            this.objects = objectList;
            refreshApex(this._wiredData);
            this.selectedObject = {};
            this.handleClose();
            this.modalLoading = false;
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
            this.modalLoading = false;
		}); 
    }

    handleDelete(){
        let trackingList = [];
        for(var tracking of this.trackingData){
            if(tracking.objectName != this.selectedObject.objectName) trackingList.push(tracking);
        }
        if(this.selectedObject.trigStatusLabel != 'Not Deployed' || this.selectedObject.mdtStatusLabel != 'Not Deployed') {
            this.selectedObject.mdtStatusLabel = 'Pending Removal';
            this.selectedObject.mdtStatusClass = 'slds-text-color_weak slds-text-title_caps';
            this.selectedObject.trigStatusLabel = 'Pending Removal';
            this.selectedObject.trigStatusClass = 'slds-text-color_weak slds-text-title_caps';
            trackingList.push(this.selectedObject);
        }
        this.trackingData = trackingList;
        this.handleClose();
    }

    openDeployModal(){
        this.modalLoading = true;
        generateMetadata({trackingData : JSON.stringify(this.trackingData)})
        .then((data) => {
            var mdList = data;
            var hasObjectOrTrigger = false;
            for(var md of mdList){
                if((md.mdType == 'Object' || md.mdType == 'Trigger')) hasObjectOrTrigger = true;
            }
            if(hasObjectOrTrigger){
                for(var mdt of mdList){
                    if((mdt.mdType == 'Object' || mdt.mdType == 'Trigger')) mdt.mdDisabled = false;
                    else mdt.mdDisabled = true;
                }
            } else {
                for(var mdts of mdList){
                    mdts.mdDisabled = false;
                }
            }
            this.mdData = mdList;
            this.deployModal = true;
            this.modalLoading = false;
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
            this.modalLoading = false;
		}); 
    }

    deployAllMetadata(){
        this.modalLoading = true;
        let wrappers = this.mdData;
        handleCustomMetadata({ wrappers : JSON.stringify(wrappers) })
        .then((data) => {
            if(data == 'Success'){
                this.handleSuccessfulDeployment(wrappers);
            } else {
                this.asyncId = data;
                this.interval = setInterval(() => {
                    this.pollDeploymentStatus(wrappers);
                }, 2000);
            }
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
            this.modalLoading = false;
        }); 
    }

    deployMetadata(row){
        this.modalLoading = true;
        let rowList = [];
        rowList.push(row);
        console.log('deployMetadata>>'+JSON.stringify(rowList));
        if(row.mdType != 'Trigger'){
            handleCustomMetadata({ wrappers : JSON.stringify(rowList) })
            .then((data) => {
                if(data == 'Success'){
                    this.handleSuccessfulDeployment(rowList);
                } else {
                    this.asyncId = data;
                    this.interval = setInterval(() => {
                        this.pollDeploymentStatus(rowList);
                    }, 2000);
                }
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
                this.modalLoading = false;
            }); 
        } else {
            generateTriggerFiles({ wrappers : JSON.stringify(rowList) })
            .then((data) => {
                var fileMap = data;
                var testName = data['testName'];
                delete fileMap['testName'];
                let zip = this.generateZIP(fileMap);
                this.deployFiles(zip, testName, rowList);
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
                this.modalLoading = false;
            }); 
        }
    }

    generateZIP(fileMap){
        var zip = new JSZip();
        for(var file in fileMap){
            zip.file(file, fileMap[file]);
        }
        return zip.generate();
    }

    async deployFiles(zip, testName, rowList){
        await deployTriggerFiles({zipFile : zip, testName : testName})
        .then((data) => {
            this.asyncId = data;
            this.interval = setInterval(() => {
                this.pollDeploymentStatus(rowList);
            }, 2000);
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
            this.modalLoading = false;
        }); 
    }

    pollDeploymentStatus(wrappers){
        if(this.asyncId){
            checkDeploymentStatus({asyncId: this.asyncId})
            .then((data) => {
                if(data){
                    clearInterval(this.interval);
                    this.handleSuccessfulDeployment([...wrappers]);
                }
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
                clearInterval(this.interval);
                this.modalLoading = false;
            }); 
        } else {
            this.modalLoading = false;
        }
    }

    handleSuccessfulDeployment(wrappers){
        this.asyncId = undefined;
        var mdList = [];
        var wrapperSize = wrappers.length;
        let operation = '';
        let displayedMessage = '';
        var hasNewObject = false;
        console.log('wrapperSize>>'+wrapperSize);
        if(wrapperSize > 1){
            for(var row of wrappers){
                if(row.mdType == 'Trigger') mdList.push(row);
            }
        } else {
            let row = wrappers[0];
            operation = row.mdOperation.endsWith('e') ? row.mdOperation.toLowerCase()+'d' : row.mdOperation.toLowerCase()+'ed';
            displayedMessage = `You have successfully ${operation} the ${row.mdName} ${row.mdType.toLowerCase()} configuration!`;
            for(var mdDate of this.mdData){
                if(row.mdName != mdDate.mdName) {
                    mdList.push(mdDate);
                    if(mdDate.mdType == 'Object' && mdDate.mdOperation == 'Add') hasNewObject = true;
                }
            }
        }
        console.log('displayedMessage1>>'+displayedMessage);
        if(hasNewObject){
            for(var md of mdList){
                if(md.mdType == 'Object' && md.mdOperation == 'Add') md.mdDisabled = false;
                else md.mdDisabled = true;
            }
        } else {
            for(var mds of mdList){
                mds.mdDisabled = false;
            }
        }
        this.mdData = mdList;
        refreshApex(this._wiredData);
        if(this.mdData.length == 0) this.handleClose();
        
        if(wrapperSize > 1){
            displayedMessage = `You have successfully deployed your field configuration!`;
        }
        console.log('displayedMessage2>>'+displayedMessage);
        this.dispatchEvent(
            new ShowToastEvent({
                title: "Success!",
                message: displayedMessage,
                variant: "success",
            }),
        );
        this.modalLoading = false;
    }

    handleObjectSelected(event) {
        this.objectSelected = event.detail.value;
        this.options = [];
        this.values = [];
        this.requiredOptions = [];
        this.parentOptions = [];
        this.parentValues = [];
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
            for(var p in data.parentRefMap){
                parentItems.push({
                    label: data.parentRefMap[p]+'('+p+')',
                    value: p
                });
            }
            this.options.push(...items);
            this.values.push(...selected);
            this.requiredOptions.push(...required);
            this.parentOptions.push(...parentItems);
            this.modalLoading = false;
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
            this.modalLoading = false;
		}); 
    }

    handleParentChange(event) {
        this.parentValues = event.detail.value;
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