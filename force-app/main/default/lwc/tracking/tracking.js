import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import iconColor from '@salesforce/resourceUrl/iconColor';
import jszip from '@salesforce/resourceUrl/jszip';
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
    @track options = [];
    @track values = [];
    @track requiredOptions = [];
    @track parentRefs = [];
    objects = [];
    objectSelected = '';
    @track deleteConfirmModal = false;
    @track deployModal = false;
    @track trackingDeployment;
    asyncId;
    intervalId;
    

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

    get hasMetadata(){
        return this.trackingData.length > 0;
    }

    connectedCallback(){
        if(this.trackingData == undefined) this.loading = true;
        loadStyle(this, iconColor);
        loadScript(this, jszip + '/jszip.js');
        loadScript(this, jszip + '/jszip-load.js');
        loadScript(this, jszip + '/jszip-deflate.js');
        loadScript(this, jszip + '/jszip-inflate.js');
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
            console.log('this.selectedObject>>'+JSON.stringify(this.selectedObject));
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
        this.mdData = [];
    }

    handleSave(){
        this.modalLoading = true;
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
        this.modalLoading = true;
        generateMetadata({trackingData : JSON.stringify(this.trackingData)})
        .then((data) => {
            var mdList = data;
            var hasNewObject = false;
            for(var md of mdList){
                if(md.mdType == 'Object' && md.mdOperation == 'Add') hasNewObject = true;
            }
            if(hasNewObject){
                for(var md of mdList){
                    if(md.mdType == 'Object' && md.mdOperation == 'Add') md.mdDisabled = false;
                    else md.mdDisabled = true;
                }
            } else {
                for(var md of mdList){
                    md.mdDisabled = false;
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
        // this.loading = true;
        // generateFiles({ wrappers : JSON.stringify(this.mdData) })
        // .then((data) => {
        //     let zip = this.generateZIP(data);
        //     this.deployFiles(zip);
        //     refreshApex(this._wiredData);
        //     this.handleClose();
        //     this.dispatchEvent(
        //         new ShowToastEvent({
        //             title: "Success!",
        //             message: `You have successfully deployed all configurations!`,
        //             variant: "success",
        //         }),
        //     );
        //     this.loading = false;
        // })
        // .catch(error => {
		// 	console.error(error);
        //     this.dispatchEvent(
        //         new ShowToastEvent({
        //             title: "An error has occurred. Please contact the system administrator for further assistance.",
        //             message: error.body.message,
        //             variant: "error",
        //         }),
        //     );
        //     this.loading = false;
		// }); 
        
    }

    deployMetadata(row){
        this.modalLoading = true;
        let wrappers = [];
        wrappers.push(row);
        if(row.mdType != 'Trigger'){
            handleCustomMetadata({ wrappers : JSON.stringify(wrappers) })
            .then((data) => {
                if(data == 'Success'){
                    this.handleSuccessfulDeployment(row);
                } else {
                    this.asyncId = data;
                    this.interval = setInterval(() => {
                        this.pollDeploymentStatus(row);
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
            generateTriggerFiles({ wrappers : JSON.stringify(wrappers) })
            .then((data) => {
                var fileMap = data;
                var testName = data['testName'];
                delete fileMap['testName'];
                let zip = this.generateZIP(fileMap);
                this.deployFiles(zip, testName, row);
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
            console.log('file>>'+file);
            zip.file(file, fileMap[file]);
        }
        return zip.generate();
    }

    async deployFiles(zip, testName, row){
        await deployTriggerFiles({zipFile : zip, testName : testName})
        .then((data) => {
            this.asyncId = data;
            this.interval = setInterval(() => {
                this.pollDeploymentStatus(row);
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

    pollDeploymentStatus(row){
        if(this.asyncId){
            checkDeploymentStatus({asyncId: this.asyncId})
            .then((data) => {
                if(data){
                    clearInterval(this.interval);
                    this.handleSuccessfulDeployment(row);
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
            this.modalLoading = false;
        }
    }

    handleSuccessfulDeployment(row){
        this.asyncId = undefined;
        var mdList = [];
        var hasNewObject = false;
        for(var md of this.mdData){
            if(row.mdName != md.mdName) {
                mdList.push(md);
                if(md.mdType == 'Object' && md.mdOperation == 'Add') hasNewObject = true;
            }
        }
        if(hasNewObject){
            for(var md of mdList){
                if(md.mdType == 'Object' && md.mdOperation == 'Add') md.mdDisabled = false;
                else md.mdDisabled = true;
            }
        } else {
            for(var md of mdList){
                md.mdDisabled = false;
            }
        }
        this.mdData = mdList;
        refreshApex(this._wiredData);
        if(this.mdData.length == 0) this.handleClose();
        let operation = row.mdOperation.endsWith('e') ? row.mdOperation.toLowerCase()+'d' : row.mdOperation.toLowerCase()+'ed';
        this.dispatchEvent(
            new ShowToastEvent({
                title: "Success!",
                message: `You have successfully ${operation} the ${row.mdName} ${row.mdType.toLowerCase()} configuration!`,
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