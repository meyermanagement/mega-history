import { LightningElement, track, api, wire } from "lwc";
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import RelatedListHelper from "./relatedListHelper";
import {loadStyle} from 'lightning/platformResourceLoader';
import relatedListResource from '@salesforce/resourceUrl/relatedListResource';
import { IsConsoleNavigation, EnclosingTabId, openSubtab  } from "lightning/platformWorkspaceApi";

export default class RelatedList extends NavigationMixin(LightningElement) {
    @wire(IsConsoleNavigation) isConsoleNavigation;
    @wire(EnclosingTabId) tabId;
    @wire(CurrentPageReference)
    currentPageRef;

    @api recordId;
    @api numberOfRecords = 5;
    @track fullView;
    @track state = {};
    @track columns;
    @track sortBy = 'createdDate';
    @track sortDirection = 'desc';
    @track consolidatedView = false;
    @track hasChildren = false;
    @track isSuperUser = false;
    rendered = false;
    
    loading = false;
    helper = new RelatedListHelper();

    renderedCallback() {
        loadStyle(this, relatedListResource + '/relatedList.css');
        this.fullView = this.currentPageRef.state.megahistory__fullView == 'true' ? true : false;
        if(this.recordId == undefined) this.recordId = this.currentPageRef.state.megahistory__recordId;
        this.state.recordId = this.recordId;
        this.state.fullView = this.fullView;
        this.state.numberOfRecords = this.numberOfRecords;
        if(!this.rendered && this.recordId != undefined){
            
            this.rendered = true;
            this.init();
        }
    }

    get hasRecords() {
        return this.state.records != undefined && this.state.records.length;
    }

    get showRelatedList() {
        return this.recordId != undefined;
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
        for(var rec of data.records){
            if(rec.parentId == this.recordId) {
                this.hasChildren = true;
                rec.eventrec = rec.recordName;
                rec.origAdd1 = rec.additionalField1;
                rec.newAdd2 = rec.additionalField2;
            } else {
                rec.eventrec = rec.field;
                rec.origAdd1 = rec.oldValue;
                rec.newAdd2 = rec.newValue;
            }
        }
        this.state.records = data.records;
        this.sortData('createdDate','desc');
        this.sortBy = 'createdDate';
        this.sortDirection = 'desc';
        this.state.iconName = data.iconName;
        this.state.sobjectLabel = data.sobjectLabel;
        this.state.sobjectLabelPlural = data.sobjectLabelPlural;
        this.state.title = data.title;
        this.state.parentRelationshipApiName = data.parentRelationshipApiName;
        
        this.createColumns();
        this.loading = false;
    }

    createColumns() {
        let columns = [];
        columns.push({
            label: 'Date',
            fieldName: 'createdDate',
            type: 'date',
            typeAttributes: {
                day: 'numeric',
                month: 'numeric',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
                timeZoneName: 'short'
            }
        });
        if(this.hasChildren){
            columns.push({
                label: 'Event',
                fieldName: 'event',
                type: 'text'
            });
            columns.push({
                label: 'Record/Field',
                fieldName: 'eventrec',
                type: 'text'
            });
        } else {
            columns.push({
                label: 'Field',
                fieldName: 'field',
                type: 'text'
            });
        }
        if(this.hasChildren){
            columns.push({
                label: 'Original Value/2nd Id',
                fieldName: 'origAdd1',
                type: 'text'
            });
            columns.push({
                label: 'New Value/3rd Id',
                fieldName: 'newAdd2',
                type: 'text'
            });
        } else {
            columns.push({
                label: 'Original Value',
                fieldName: 'origAdd1',
                type: 'text'
            });
            columns.push({
                label: 'New Value',
                fieldName: 'newAdd2',
                type: 'text'
            });
        }
        columns.push({
            label: 'User',
            fieldName: 'createdByName',
            type: 'text'
        });
        if(this.isSuperUser == 'true'){
            columns.push({ 
                type: 'action', 
                typeAttributes: { rowActions: this.helper.initColumnsWithActions } 
            });
        }
        this.columns = columns;
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case "delete":
                this.handleDeleteRecord(row);
                break;
            case "edit":
                this.handleEditRecord(row);
                break;
            default:
        }
    }

    handleGotoRelatedList() {
        console.log(this.isConsoleNavigation);
        console.log(this.tabId);
        if(!this.isConsoleNavigation || !this.tabId){
            this[NavigationMixin.Navigate]({
                type: "standard__component",
                attributes: {
                    componentName: 'megahistory__relatedList'
                },
                state: {
                    megahistory__fullView: 'true',
                    megahistory__recordId: this.recordId
                    
                }
            });
        } else {
            openSubtab(this.tabId, {
                pageReference: {
                  type: "standard__component",
                  attributes: {
                    componentName: "megahistory__relatedList",
                  },
                  state: {
                    megahistory__fullView: 'true',
                    megahistory__recordId: this.recordId
                  },
                },
                icon: this.state.iconName,
                label: this.state.title
            });
        }
        
    }

    handleCreateRecord() {
        const newEditPopup = this.template.querySelector("c-related-list-new-edit-popup");
        newEditPopup.recordId = null
        newEditPopup.recordName = null        
        newEditPopup.sobjectApiName = this.sobjectApiName;
        newEditPopup.sobjectLabel = this.state.sobjectLabel;
        newEditPopup.show();
    }

    handleEditRecord(row) {
        console.log('row>>'+JSON.stringify(row));
        const newEditPopup = this.template.querySelector("c-related-list-new-edit-popup");
        newEditPopup.recordId = row.historyId;
        newEditPopup.recordName = row.event;
        newEditPopup.sobjectApiName = this.sobjectApiName;
        newEditPopup.sobjectLabel = this.state.sobjectLabel;
        newEditPopup.show();
    }

    handleDeleteRecord(row) {
        const newEditPopup = this.template.querySelector("c-related-list-delete-popup");
        newEditPopup.recordId = row.historyId;
        newEditPopup.recordName = row.recordName;
        newEditPopup.sobjectLabel = this.state.sobjectLabel;
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
}
