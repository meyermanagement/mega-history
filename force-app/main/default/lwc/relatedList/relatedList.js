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
    @track fullView;
    @track state = {};
    @track columns;
    @track childColumns;
    @track consolidatedView = false;
    @track isSuperUser = false;
    @track isCustomOnly = false;
    @track isStandardDisabled = false;
    fields = [];
    fieldSelected = '';
    rendered = false;
    relatedRecord = false;
    showNewEditPopUp = false;
    showViewPopUp = false;
    showRelated = false;
    showOptions = false;
    optionsLabel = 'Show';
    optionsVariant = 'brand';
    historyRec;
    
    loading = false;
    helper = new RelatedListHelper();

    renderedCallback() {
        loadStyle(this, relatedListResource + '/relatedList.css');
        this.fullView = this.currentPageRef.state.megatools__fullView == 'true' ? true : false;
        if(this.recordId == undefined) this.recordId = this.currentPageRef.state.megatools__recordId;
        this.state.recordId = this.recordId;
        this.state.fullView = this.fullView;
        this.state.numberOfRecords = this.numberOfRecords;
        if(!this.rendered && this.recordId != undefined){
            
            this.rendered = true;
            this.init();
        }
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

    get standardDisabled() {
        return this.isStandardDisabled == 'true';
    }

    handleCustomOnly(event) {
        if(event.detail.checked) this.isCustomOnly = 'true';
        else this.isCustomOnly = 'false';
        this.init();
    }

    handleShowRelated(event) {
        this.showRelated = event.detail.checked;
    }

    handleShowOptions(){
        if(this.showOptions === false){
            this.optionsLabel = 'Hide';
            this.optionsVariant = 'neutral';
            this.showOptions = true;
        } else {
            this.optionsLabel = 'Show';
            this.optionsVariant = 'brand';
            this.showOptions = false;
        }
    }

    async init() {
        this.loading = true;
        if (! (this.recordId)) {
            this.state.records = [];
            return;
        }
        const data = await this.helper.fetchData(this.state, this.isCustomOnly);
        this.isSuperUser = data.superUser;
        this.isStandardDisabled = data.standardDisabled;
        if(this.standardDisabled) this.isCustomOnly = 'true';
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
            fieldName: 'recordName',
            type: 'text'
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
        if(this.isSuperUser == 'true'){
            columns.push({ 
                type: 'action', 
                typeAttributes: { rowActions: this.helper.initColumnsWithSuperActions } 
            });
            childColumns.push({ 
                type: 'action', 
                typeAttributes: { rowActions: this.helper.initRelatedColumnsWithSuperActions } 
            });
        } else {
            childColumns.push({ 
                type: 'action', 
                typeAttributes: { rowActions: this.helper.initRelatedColumnsWithActions } 
            });
        }
        this.columns = columns;
        this.childColumns = childColumns;
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
                        megatools__recordId: this.recordId
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
                            megatools__recordId: this.recordId
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
}
