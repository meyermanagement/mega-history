import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import MEGA_HISTORY_LOGO from "@salesforce/contentAssetUrl/MEGA_Main_Logo";
import { loadStyle } from 'lightning/platformResourceLoader';
import iconColor from '@salesforce/resourceUrl/iconColor';
import getTrackingRecords from '@salesforce/apex/ImportController.getRecords';
import getObjectDetails from '@salesforce/apex/ImportController.getObjectDetails';
import getRecordCount from '@salesforce/apex/ImportController.getRecordCount';
import getSelectedObjectRecords from '@salesforce/apex/ImportController.getSelectedObjectRecords';
import generateHistoryRecords from '@salesforce/apex/ImportController.generateHistoryRecords';

export default class Views extends LightningElement {

    logoUrl = MEGA_HISTORY_LOGO;
    loading;
    _wiredData;
    objects = [];
    objectSelected = '';
    objectLabel = '';
    objectIcon = 'standard:entity';
    objectNameField = 'Name';
    objectSecondaryField = '';
    recordSelectionValue = '';
    objectSelectedCount = 0;
    loadingCount = false;
    @track selectedRecords = [];
    @track selectedRecordIds = [];
    columns = [
        {
            label: 'Name', 
            fieldName: 'mainField', 
            type: 'text'            
        },
        { 
            label: 'Additional Identifier', 
            fieldName: 'subField', 
            type: 'text' 
        },
        { 
            type: 'button',
            initialWidth: 150, 
            typeAttributes: {
                label: 'Remove',
                name: 'delete',
                title: 'Remove',
                variant: 'destructive'
            },
            cellAttributes: { alignment: 'center' }
        }
    ];
    

    get recordSelectionOptions() {
        return [
            { label: 'All (limit 50,000)', value: 'all' },
            { label: 'Search and Build List', value: 'search' }
        ];
    }

    get hasMetadata(){
        return this.objects !== undefined && this.objects.length > 0;
    }

    get hasSelectedObject(){
        return this.objectSelected !== '' && this.objectSelected !== undefined;
    }

    get allRecords(){
        return this.recordSelectionValue === 'all';
    }

    get searchRecords(){
        return this.recordSelectionValue === 'search';
    }

    get hasRecordsSelected(){
        return this.selectedRecords.length > 0;
    }

    get noRecordCount(){
        return this.objectSelectedCount === 0;
    }

    connectedCallback(){
        if(this.trackingData === undefined) this.loading = true;
        loadStyle(this, iconColor);
    }

    @wire(getTrackingRecords)
    getData(result) {
        this._wiredData = result;
        if(result.data){
            const items = [];
            for(let o of result.data){
                items.push({
                    label: o.objectLabel+'('+o.objectName+')',
                    value: o.objectName
                });
            }
            this.objects.push(...items);
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

    handleObjectSelected(event) {
        this.objectSelectedCount = 0;
        this.objectSelected = event.detail.value;
        getObjectDetails({ objectApiName: this.objectSelected})
        .then(response => {
            this.objectLabel = response.objectLabel;
            this.objectIcon = response.objectIcon;
            this.objectNameField = response.objectNameField;
            this.objectSecondaryField = response.objectSecondaryField;
            this.recordSelectionValue = '';
            this.selectedRecords = [];
            this.selectedRecordIds = [];
        })
        .catch(error => {
            console.log('getObjectDetailsError'+JSON.stringify(error));
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "An error has occurred. Please contact the system administrator for further assistance.",
                    message: error.body.message,
                    variant: "error",
                }),
            );
        });
    }

    handleRecordSelectionChange(event) {
        this.objectSelectedCount = 0;
        this.selectedRecords = [];
        this.selectedRecordIds = [];
        const selectedOption = event.detail.value;
        this.recordSelectionValue = selectedOption;
        if(selectedOption === 'all'){
            this.loadingCount = true;
            getRecordCount({ objectApiName: this.objectSelected})
            .then(response => {
                this.objectSelectedCount = response;
                this.loadingCount = false;
            })
            .catch(error => {
                console.log('getRecordCount'+JSON.stringify(error));
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "An error has occurred. Please contact the system administrator for further assistance.",
                        message: error.body.message,
                        variant: "error",
                    }),
                );
                this.loadingCount = false;
            });
        }
    }

    handleValueSelectedOnSearch(event){
        let selectedRecords = [...this.selectedRecords];
        let selectedRecordIds = [...this.selectedRecordIds];
        if(!selectedRecordIds.includes(event.detail.id)) {
            selectedRecords.push(event.detail);
            selectedRecordIds.push(event.detail.id);
        }
        this.selectedRecords = selectedRecords;
        this.selectedRecordIds = selectedRecordIds;
        this.objectSelectedCount = selectedRecordIds.length;
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case "delete":
                this.handleDeleteRecord(row);
                break;
            default:
        }
    }

    handleDeleteRecord(row) {
        this.selectedRecords = this.selectedRecords.filter((rec) => rec.id != row.id);
        this.selectedRecordIds = this.selectedRecordIds.filter((recId) => recId != row.id);
        this.objectSelectedCount = this.selectedRecordIds.length;
    }

    generateTemplate() {
        if(this.recordSelectionValue == 'all'){
            this.getAllRecords();
        } else if(this.recordSelectionValue == 'search'){
            this.downloadCSVFile(this.selectedRecords);
        }
    }

    getAllRecords() {
        getSelectedObjectRecords({ objectApiName: this.objectSelected})
        .then(response => {
            this.downloadCSVFile(response);
        })
        .catch(error => {
            console.log('getSelectedObjectRecords'+JSON.stringify(error));
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "An error has occurred. Please contact the system administrator for further assistance.",
                    message: error.body.message,
                    variant: "error",
                }),
            );
            this.loadingCount = false;
        });
    }

    downloadCSVFile(csvData) {   
        let rowEnd = '\n';
        let csvString = 'megatools__Record__c, megatools__Record_Name__c, megatools__ParentId__c, megatools__Event__c, megatools__Created_By_DL__c, megatools__Created_Date_DL__c, megatools__Additional_Field_1__c, megatools__Additional_Field_2__c, megatools__Field__c, megatools__New_Value__c, megatools__New_Value_Extended__c, megatools__Old_Value__c, megatools__Old_Value_Extended__c';
        let queryKeys = ['id','mainField','parentIds'];
        
        // splitting using ','
        csvString += rowEnd;

        // main for loop to get the data based on key value
        for(let i=0; i < csvData.length; i++){
            let colValue = 0;
            for(let key of queryKeys){
                let value = csvData[i][key] === undefined ? '' : csvData[i][key];
                if(colValue > 0){
                    csvString += ',';
                }
                csvString += '"'+ value +'"';
                colValue++;
            }
            

            csvString += rowEnd;
        }

        // Creating anchor element to download
        let downloadElement = document.createElement('a');

        // This  encodeURI encodes special characters, except: , / ? : @ & = + $ # (Use encodeURIComponent() to encode these characters).
        downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvString);
        downloadElement.target = '_self';
        // CSV File Name
        downloadElement.download = 'Account Data.csv';
        // below statement is required if you are using firefox browser
        document.body.appendChild(downloadElement);
        // click() Javascript function to download CSV file
        downloadElement.click(); 
    }

    handleFileUpload(event) {
        const file = event.target.files[0];
        this.read(file);
    }

    async read(file) {
        try {
            const result = await this.load(file);
            //console.log("#### result = "+JSON.stringify(result));
            // execute the logic for parsing the uploaded csv file
            this.parseCSV(result);
        } catch (e) {
            this.error = e;
        }
    }

    async load(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();

            reader.onload = () => {
                //console.log("#### reader.result = "+JSON.stringify(reader.result));
                resolve(reader.result);
            };
            reader.onerror = () => {
                //console.log("#### reader.error = "+JSON.stringify(reader.error));
                reject(reader.error);
            };
            //console.log("#### file = "+JSON.stringify(file));
            reader.readAsText(file);
        });
    }

    parseCSV(csv) {
        // parse the csv file and treat each line as one item of an array
        const lines = csv.split(/\r\n|\n/);
        //console.log("#### lines = "+JSON.stringify(lines));
        // parse the first line containing the csv column headers
        const headers = lines[0].split(',');
        // iterate through csv headers and transform them to column format supported by the datatable
        const data = [];
        
        // iterate through csv file rows and transform them to format supported by the datatable
        lines.forEach((line, i) => {
            if (i === 0) return;
        
            let parentIds = '';
            //console.log("#### line1 = "+JSON.stringify(line));
            if(line.includes('\"')){
                const index = line.indexOf('\"');
                const lastIndex = line.lastIndexOf('\"');
                parentIds = line.substring(index, lastIndex);
                line = line.substring(0, index) + '' + line.substring(lastIndex+1, line.length);
                //line = line.replace('\"'+parentIds+'\"', '');
            }
            if(line !== ''){
                const obj = {};
                const currentline = line.split(',');
            
                for (let j = 0; j < headers.length; j++) {
                    let value = currentline[j];
                    if(j === 2 && parentIds !== '') {
                        value = parentIds.substring(1, parentIds.length);
                    }
                    obj[headers[j]] = value;
                }
                data.push(obj);
            }
            
        });
        // assign the converted csv data for the lightning datatable
        this.createRecords(data);
    }

    createRecords(data) {
        generateHistoryRecords({ records: JSON.stringify(data)})
        .then(response => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success!",
                    message: `You have successfully created ${response} records!`,
                    variant: "success",
                })
            );
        })
        .catch(error => {
            console.log('generateHistoryRecords'+JSON.stringify(error));
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "An error has occurred. Please contact the system administrator for further assistance.",
                    message: error.body.message,
                    variant: "error",
                }),
            );
            this.loadingCount = false;
        });
    }
}