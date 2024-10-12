import { LightningElement, track, api, wire } from "lwc";
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import RelatedListHelper from "./relatedListHelper";
import {loadStyle} from 'lightning/platformResourceLoader';
import relatedListResource from '@salesforce/resourceUrl/relatedListResource';
import getHistoryRecord from '@salesforce/apex/RelatedListController.getHistoryRecord'; 
import getAvailableFields from "@salesforce/apex/RelatedListController.getFields";
import { IsConsoleNavigation, EnclosingTabId, openTab  } from "lightning/platformWorkspaceApi";

export default class RelatedList extends NavigationMixin(LightningElement) {
    @wire(IsConsoleNavigation) isConsoleNavigation;
    @wire(EnclosingTabId) tabId;
    @wire(CurrentPageReference) currentPageRef;

    @api recordId;
    @api numberOfRecords = 5;
    @api mode;
    @api showOptions = false;
    @track fullViewOptions = false;
    @track fullView;
    @track state = {};
    @track columns;
    @track childColumns;
    @track gridColumns;
    gridExpandedRows = [];
    @track consolidatedView = false;
    @track isSuperUser = false;
    @track isCustomOnly = false;
    fields = [];
    fieldSelected = '';
    rendered = false;
    relatedRecord = false;
    showNewEditPopUp = false;
    showViewPopUp = false;
    showRelated = false;
    groupRelated = false;
    displayOptions = false;
    optionsLabel = 'Show';
    optionsVariant = 'brand';
    historyRec;
    objectSelected = 'All';
    
    loading = false;
    helper = new RelatedListHelper();

    renderedCallback() {
        loadStyle(this, relatedListResource + '/relatedList.css');
        this.fullView = this.currentPageRef.state.megatools__fullView == 'true' ? true : false;
        this.fullViewOptions = this.currentPageRef.state.megatools__showOptions;
        if(this.recordId == undefined) this.recordId = this.currentPageRef.state.megatools__recordId;
        this.state.recordId = this.recordId;
        this.state.fullView = this.fullView;
        this.state.numberOfRecords = this.numberOfRecords;
        if(!this.rendered && this.recordId != undefined){
            
            this.rendered = true;
            this.init();
        }
    }

    get optionsAvailable(){
        return this.showOptions == true || this.fullViewOptions == true || this.showOptions == 'true' || this.fullViewOptions == 'true';
    }

    get isRelated(){
        return true;
    }

    get isNotRelated(){
        return false;
    }

    get hasRecords() {
        return this.hasAdults || this.hasChildren;
    }

    get hasAdults() {
        return this.state.records != undefined && this.state.records.length > 0;
    }

    get hasChildren() {
        return this.state.childRecords != undefined && this.state.childRecords.length > 0;
    }

    get hasNoChildren() {
        return this.state.childRecords == undefined || this.state.childRecords.length == 0;
    }

    get hasParentNotAllowed(){
        return this.parentNotAllowed != undefined;
    }

    get parentNotAllowed() {
        let notAllowedMessage;
        if(this.state.disabledRecords != undefined && this.state.disabledRecords.length > 0){
            let includesParentDisabled = false;
            for(let rec of this.state.disabledRecords){
                if(rec.parentId != 'NOTALLOWED') includesParentDisabled = true;
            }
            if(includesParentDisabled) notAllowedMessage = 'NOTE: This object does not support displaying standard history combined with custom history.';
        }
        return notAllowedMessage;
    }

    get hasChildrenNotAllowed(){
        return this.childrenNotAllowed != undefined;
    }

    get childrenNotAllowed() {
        let notAllowedMessage;
        if(this.state.disabledRecords != undefined && this.state.disabledRecords.length > 0){
            let objectsNotAllowed = [];
            for(let rec of this.state.disabledRecords){
                if(rec.parentId == 'NOTALLOWED' && !objectsNotAllowed.includes(rec.objectLabel+'('+rec.objectAPIName+')')) objectsNotAllowed.push(rec.objectLabel+'('+rec.objectAPIName+')');
            }
            if(objectsNotAllowed.length > 0) {
                notAllowedMessage = 'NOTE: The following objects do not support displaying standard history combined with custom history: ';
                for(let obj of objectsNotAllowed){
                    notAllowedMessage += obj+'/';
                }
                notAllowedMessage = notAllowedMessage.slice(0, -1)
            }
        }
        return notAllowedMessage;
    }

    get childrenObjects() {
        let uniqueList = [];
        let labelList = [];
        let objectList = [];
        objectList.push({
            label: 'All',
            value: 'All'
        });
        if(this.state.childRecords != undefined && this.state.childRecords.length > 0){
            for(let rec of this.state.childRecords){
                if(!uniqueList.includes(rec.objectAPIName)) {
                    objectList.push({
                        label: rec.objectLabel+'('+rec.objectAPIName+')',
                        value: rec.objectAPIName
                    });
                    uniqueList.push(rec.objectAPIName);
                    labelList.push(rec.objectLabel);
                }
                labelList.push(rec.objectLabel+rec.recordId);
            }
        }
        this.gridExpandedRows = labelList;
        return objectList;
    }

    get showRelatedList() {
        return this.recordId != undefined;
    }

    get showTile() {
        return this.mode == 'Tile';
    }

    get superUser() {
        return this.isSuperUser == 'true';
    }

    get customOnly() {
        return this.isCustomOnly == 'true';
    }
    

    handleCustomOnly(event) {
        if(event.detail.checked) this.isCustomOnly = 'true';
        else this.isCustomOnly = 'false';
        this.init();
    }

    handleShowRelated(event) {
        this.showRelated = event.detail.checked;
    }

    handleGroupRelated(event) {
        this.groupRelated = event.detail.checked;
        if(this.groupRelated){
            this.state.childtitle = `Related ${this.state.sobjectLabelPlural} (${this.state.childRecords.length})`
        } else {
            if (this.state.filteredChildRecords.length > this.numberOfRecords) {
                this.state.childtitle = `Related ${this.state.sobjectLabelPlural} (${this.state.numberOfRecords}+)`;
            } else {
                this.state.childtitle = `Related ${this.state.sobjectLabelPlural} (${Math.min(this.state.numberOfRecords, this.state.filteredChildRecords.length)})`;
            }  
        }
        this.filterRelatedList();
    }

    handleShowOptions(){
        if(this.displayOptions === false){
            this.optionsLabel = 'Hide';
            this.optionsVariant = 'neutral';
            this.displayOptions = true;
        } else {
            this.optionsLabel = 'Show';
            this.optionsVariant = 'brand';
            this.displayOptions = false;
        }
    }

    handleObjectSelected(event) {
        this.objectSelected = event.detail.value;
        this.filterRelatedList();
    }

    async init() {
        this.loading = true;
        if (! (this.recordId)) {
            this.state.records = [];
            return;
        }
        const data = await this.helper.fetchData(this.state, this.isCustomOnly);
        this.isSuperUser = data.superUser;
        if(data.body != undefined){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "An error has occurred. Please contact the system administrator for further assistance.",
                    message: data.body.message,
                    variant: "error",
                }),
            );
        }
        this.state.records = data.records;
        this.state.childRecords = data.childRecords; 
        this.state.filteredChildRecords = data.filteredChildRecords;
        this.state.filteredGroupedRecords = this.helper.groupRecords(this.state.childRecords);
        this.objectSelected = 'All';
        this.state.disabledRecords = data.disabledRecords;           
        this.state.iconName = data.iconName;
        this.state.sobjectLabel = data.sobjectLabel;
        this.state.sobjectLabelPlural = data.sobjectLabelPlural;
        this.state.title = data.title;
        this.state.childtitle = data.childtitle;
        this.state.parentRelationshipApiName = data.parentRelationshipApiName;
        
        this.createColumns();
        this.loading = false;
    }

    createColumns() {
        let columns = [];
        let childColumns = [];
        let gridColumns = [];
        columns.push({
            label: 'Date',
            title: 'createdDate',
            fieldName: 'createdDate',
            type: 'date',
            initialWidth: 150,
            typeAttributes: {
                day: 'numeric',
                month: 'numeric',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
                timeZoneName: 'short'
            }
        });
        columns.push({
            label: 'Field',
            fieldName: 'fieldLabel',
            type: 'text'
        });
        columns.push({
            label: 'User',
            fieldName: 'createdByURL',
            type: 'url',
            typeAttributes: {label: { fieldName: 'createdByName' }, 
            target: '_self'}
        });
        columns.push({
            label: 'Original Value',
            fieldName: 'oldValue',
            type: 'text'
        });
        columns.push({
            label: 'New Value',
            fieldName: 'newValue',
            type: 'text'
        });
        childColumns.push({
            label: 'Date',
            title: 'createdDate',
            fieldName: 'createdDate',
            type: 'date',
            initialWidth: 150,
            typeAttributes: {
                day: 'numeric',
                month: 'numeric',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
                timeZoneName: 'short'
            }
        });
        childColumns.push({
            label: 'Object',
            fieldName: 'objectLabel',
            type: 'text'
        });
        childColumns.push({
            label: 'Event',
            fieldName: 'event',
            type: 'text'
        });
        childColumns.push({
            label: 'User',
            fieldName: 'createdByURL',
            type: 'url',
            typeAttributes: {label: { fieldName: 'createdByName' }, 
            target: '_self'}
        });
        childColumns.push({
            label: 'Record',
            fieldName: 'recordURL',
            type: 'url',
            typeAttributes: {label: { fieldName: 'recordName' }, 
            target: '_self'}
        });
        childColumns.push({
            label: 'Field',
            fieldName: 'fieldLabel',
            type: 'text'
        });
        childColumns.push({
            label: 'New Value',
            fieldName: 'newValue',
            type: 'text'
        });
        gridColumns.push({
            label: 'Object',
            fieldName: 'objectLabel',
            type: 'text'
        });
        gridColumns.push({
            label: 'Record',
            fieldName: 'recordURL',
            type: 'url',
            typeAttributes: {label: { fieldName: 'recordName' }, 
            target: '_self'}
        });
        gridColumns.push({
            label: 'Event',
            fieldName: 'event',
            type: 'text'
        });
        gridColumns.push({
            label: 'Date',
            title: 'createdDate',
            fieldName: 'createdDate',
            type: 'date',
            initialWidth: 150,
            typeAttributes: {
                day: 'numeric',
                month: 'numeric',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
                timeZoneName: 'short'
            }
        });
        gridColumns.push({
            label: 'User',
            fieldName: 'createdByURL',
            type: 'url',
            typeAttributes: {label: { fieldName: 'createdByName' }, 
            target: '_self'}
        });
        gridColumns.push({
            label: 'Field',
            fieldName: 'fieldLabel',
            type: 'text'
        });
        gridColumns.push({
            label: 'New Value',
            fieldName: 'newValue',
            type: 'text'
        });
        if(this.isSuperUser == 'true'){
            columns.push({ 
                type: 'action', 
                typeAttributes: { rowActions: this.helper.initColumnsWithSuperActions } 
            });
            childColumns.push({ 
                type: 'action', 
                typeAttributes: { rowActions: this.helper.initRelatedColumnsWithSuperActions } 
            });
            gridColumns.push({
                type: 'action', 
                typeAttributes: { rowActions: this.helper.initRelatedColumnsWithSuperActions } 
            });
        } else {
            childColumns.push({ 
                type: 'action', 
                typeAttributes: { rowActions: this.helper.initRelatedColumnsWithActions } 
            });
            gridColumns.push({
                type: 'action', 
                typeAttributes: { rowActions: this.helper.initRelatedColumnsWithActions } 
            });
        }
        this.columns = columns;
        this.childColumns = childColumns;
        this.gridColumns = gridColumns;
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case "delete":
                if(row.parentId.includes(this.recordId)) this.handleDeleteRelatedRecord(row);
                else this.handleDeleteRecord(row);
                break;
            case "edit":
                if(row.parentId.includes(this.recordId)) this.handleEditRelatedRecord(row);
                else this.handleEditRecord(row);
                break;
            case "view":
                this.handleViewRelatedRecord(row);
                break;
            default:
        }
    }

    handleGotoRelatedList() {
        try{
            if(!this.isConsoleNavigation || !this.tabId){
                this[NavigationMixin.Navigate]({
                    type: "standard__component",
                    attributes: {
                        componentName: 'megatools__relatedList'
                    },
                    state: {
                        megatools__fullView: 'true',
                        megatools__recordId: this.recordId,
                        megatools__showOptions: this.showOptions
                    }
                });
            } else {
                openTab({
                    pageReference: {
                        type: "standard__component",
                        attributes: {
                            componentName: "megatools__relatedList",
                        },
                        state: {
                            megatools__fullView: 'true',
                            megatools__recordId: this.recordId,
                            megatools__showOptions: this.showOptions
                        },
                    },
                    icon: this.state.iconName,
                    label: this.state.title
                });
            }
        } catch(error){
            console.log(JSON.stringify(error));
        }
    }

    handleCreateRecord() {
        this.relatedRecord = false;
        this.fieldSelected = '';
        this.getData();
        this.showNewEditPopUp = true;
    }

    handleEditRecord(row) {
        this.relatedRecord = false;
        this.fieldSelected = row.field;
        this.getData(row.historyId);
        this.showNewEditPopUp = true;
    }

    handleCreateRelatedRecord() {
        this.relatedRecord = true;
        this.fieldSelected = '';
        this.getData();
        this.showNewEditPopUp = true;
    }

    handleEditRelatedRecord(row) {
        this.relatedRecord = true;
        this.fieldSelected = row.field;
        this.getData(row.historyId);
        this.showNewEditPopUp = true;
    }

    handleViewRelatedRecord(row) {
        this.relatedRecord = true;
        this.getData(row.historyId);
        this.showViewPopUp = true;
    }

    getData(historyId) {
        getHistoryRecord({ recordId: this.recordId, historyId: historyId, isRelated: this.relatedRecord})
        .then(response => {
            this.historyRec = response;
            if(response.megatools__Record__c != undefined) this.getFields(response.megatools__Record__c);
        })
        .catch(error => {
            console.log('getHistoryRecord'+JSON.stringify(error));
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "An error has occurred. Please contact the system administrator for further assistance.",
                    message: error.body.message,
                    variant: "error",
                }),
            );
        });
    }

    handleDeleteRecord(row) {
        const newEditPopup = this.template.querySelector("c-related-list-delete-popup");
        newEditPopup.recordId = row.historyId;
        newEditPopup.recordName = row.recordName;
        newEditPopup.sobjectLabel = this.state.sobjectLabel;
        newEditPopup.relatedRecord = false;
        newEditPopup.show();
    }

    handleDeleteRelatedRecord(row) {
        const newEditPopup = this.template.querySelector("c-related-list-delete-popup");
        newEditPopup.recordId = row.historyId;
        newEditPopup.recordName = row.recordName;
        newEditPopup.sobjectLabel = this.state.sobjectLabel;
        newEditPopup.relatedRecord = true;
        newEditPopup.show();
    }

    handleRefreshData() {
        this.init();
    }

    

    handleCloseModal(){
        this.showNewEditPopUp = false;
        this.showViewPopUp = false;
        this.historyRec = undefined;
    }

    getFields(recordId) {
        getAvailableFields({ recordId: recordId})
        .then(response => {
            let fieldList = [];
            for(let f in response){
                fieldList.push({
                    label: response[f], 
                    value: f
                })
            }
            this.fields = fieldList;
        })
        .catch(error => {
            console.log('getFieildsError'+JSON.stringify(error));
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "An error has occurred. Please contact the system administrator for further assistance.",
                    message: error.body.message,
                    variant: "error",
                }),
            );
        });
    }

    filterRelatedList(){
        this.loading = true;
        let filteredList = [];
        if(this.state.childRecords != undefined && this.state.childRecords.length > 0){
            if(this.objectSelected == 'All'){
                filteredList = this.state.childRecords;
            } else {
                for(let rec of this.state.childRecords){
                    if(rec.objectAPIName == this.objectSelected) {
                        filteredList.push(rec);
                    }
                }
            }
        }
        if(this.fullView || this.groupRelated){
            this.state.childtitle = `Related ${this.state.sobjectLabelPlural} (${filteredList.length})`
        } else {
            if (filteredList.length > this.state.numberOfRecords) {
                filteredList = filteredList.slice(0, this.state.numberOfRecords);
                this.state.childtitle = `Related ${this.state.sobjectLabelPlural} (${this.state.numberOfRecords}+)`;
            } else {
                this.state.childtitle = `Related ${this.state.sobjectLabelPlural} (${Math.min(this.state.numberOfRecords, filteredList.length)})`;
            }  
        }
        this.state.filteredChildRecords = this.helper.sortData('createdDate','desc', filteredList);
        this.state.filteredGroupedRecords = this.helper.groupRecords(this.state.filteredChildRecords);
        this.loading = false;
    }

    exportHistoryData(){
        // Prepare a html table
        let doc = '';
        this.columns.forEach(element => {            
            if(element.label != undefined) doc +=  element.label +','           
        });
        doc += '\n';
        // Add the data rows
        this.state.records.forEach(record => {
            doc += record.createdDate+','; 
            doc += record.fieldLabel+','; 
            doc += record.createdByName+','; 
            doc += record.oldValue != undefined ? record.oldValue+',' : ',';
            doc += record.newValue != undefined ? record.newValue+',' : ',';
            doc += '\n';
        });
        doc += '\n\n';

        this.childColumns.forEach(element => {            
            if(element.label != undefined) doc +=  element.label +','           
        });
        doc += '\n';
        this.state.childRecords.forEach(record => {
            doc += record.createdDate+','; 
            doc += record.objectLabel+','; 
            doc += record.event+','; 
            doc += record.createdByName+','; 
            doc += record.recordName+','; 
            doc += record.fieldLabel != undefined ? record.fieldLabel+',' : ',';
            doc += record.newValue != undefined ? record.newValue+',' : ',';
            doc += '\n';
        });
        var element = 'data:application/csv,' + encodeURIComponent(doc);
        let downloadElement = document.createElement('a');
        downloadElement.href = element;
        downloadElement.target = '_self';
        // use .csv as extension on below line if you want to export data as csv
        downloadElement.download = this.state.sobjectLabelPlural+'.csv';
        document.body.appendChild(downloadElement);
        downloadElement.click();
    }
}
