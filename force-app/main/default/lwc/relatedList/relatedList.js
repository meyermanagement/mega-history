import { LightningElement, track, api, wire } from "lwc";
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import RelatedListHelper from "./relatedListHelper";
import {loadStyle} from 'lightning/platformResourceLoader';
import relatedListResource from '@salesforce/resourceUrl/relatedListResource';
import getHistoryRecord from '@salesforce/apex/RelatedListController.getHistoryRecord'; 
import getFields from "@salesforce/apex/RelatedListController.getFields";
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
    @track sortBy = 'createdDate';
    @track sortDirection = 'desc';
    @track consolidatedView = false;
    @track isSuperUser = false;
    fields = [];
    fieldSelected = '';
    rendered = false;
    relatedRecord = false;
    showNewEditPopUp = false;
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

    get showRelatedList() {
        return this.recordId != undefined;
    }

    get showTile() {
        return this.mode == 'Tile';
    }

    get superUser() {
        return this.isSuperUser == 'true';
    }

    async init() {
        this.loading = true;
        if (! (this.recordId)) {
            this.state.records = [];
            return;
        }
        const data = await this.helper.fetchData(this.state);
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
        this.sortData('createdDate','desc');
        this.sortChildData('createdDate','desc');
        this.sortBy = 'createdDate';
        this.sortDirection = 'desc';
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
            label: 'Field 1',
            fieldName: 'additionalField1',
            type: 'text'
        });
        childColumns.push({
            label: 'Field 2',
            fieldName: 'additionalField2',
            type: 'text'
        });
        if(this.isSuperUser == 'true'){
            columns.push({ 
                type: 'action', 
                typeAttributes: { rowActions: this.helper.initColumnsWithActions } 
            });
            childColumns.push({ 
                type: 'action', 
                typeAttributes: { rowActions: this.helper.initColumnsWithActions } 
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
                if(row.parentId == this.recordId) this.handleDeleteRelatedRecord(row);
                else this.handleDeleteRecord(row);
                break;
            case "edit":
                if(row.parentId == this.recordId) this.handleEditRelatedRecord(row);
                else this.handleEditRecord(row);
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
        this.getData();
        this.showNewEditPopUp = true;
    }

    handleEditRelatedRecord(row) {
        this.relatedRecord = true;
        this.getData(row.historyId);
        this.showNewEditPopUp = true;
    }

    async getData(historyId) {
        await getHistoryRecord({ recordId: this.recordId, historyId: historyId, isRelated: this.relatedRecord})
        .then(response => {
            this.historyRec = response;
        })
        .catch(error => {
            console.log(JSON.stringify(error));
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

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.state.records));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.state.records = parseData;
    }    

    sortChildData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.state.childRecords));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.state.childRecords = parseData;
    }    

    handleCloseModal(){
        this.showNewEditPopUp = false;
    }

    @wire(getFields, { recordId : '$recordId' })
    getFields(result) {
        const {data, error} = result;
        if(data){
            let fieldList = [];
            for(let f in data){
                fieldList.push({
                    label: data[f], 
                    value: f
                })
            }
            this.fields = fieldList;
        } else if (error) {
            console.log(error.body.message);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "An error has occurred. Please contact the system administrator for further assistance.",
                    message: error.body.message,
                    variant: "error",
                }),
            );
        }
    }
}
