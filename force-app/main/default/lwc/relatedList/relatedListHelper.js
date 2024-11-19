/* eslint-disable guard-for-in */
/* eslint-disable no-console */
import initDataMethod from "@salesforce/apex/RelatedListController.initData";

export default class RelatedListHelper {

    fetchData(state, isCustomOnly) {
        let jsonData = Object.assign({}, state);
        
        jsonData.numberOfRecords = state.numberOfRecords + 1;
        jsonData = JSON.stringify(jsonData);
        return initDataMethod({ jsonData, isCustomOnly})
            .then(response => {
                const data = JSON.parse(response);
                return this.processData(data, state);
            })
            .catch(error => {
                console.log(error);
                return error;
            });
    }

    processData(data, state){
        const records = this.sortData('createdDate','desc', data.records);
        const childRecords = this.sortData('createdDate','desc', data.childRecords);
        data.records = records;
        data.childRecords = childRecords;
        data.filteredChildRecords = childRecords;
        //this.generateLinks(records);
        if(state.fullView){
               data.title = `${data.sobjectLabelPlural} (${records.length})`
               data.childtitle = `Related ${data.sobjectLabelPlural} (${childRecords.length})`
               
        } else {
            if (records.length > state.numberOfRecords) {
                data.records = records.slice(0, state.numberOfRecords);
                data.title = `${data.sobjectLabelPlural} (${state.numberOfRecords}+)`;
            } else {
                data.title = `${data.sobjectLabelPlural} (${Math.min(state.numberOfRecords, records.length)})`;
            }  
            if (childRecords.length > state.numberOfRecords) {
                data.filteredChildRecords = childRecords.slice(0, state.numberOfRecords);
                data.childtitle = `Related ${data.sobjectLabelPlural} (${state.numberOfRecords}+)`;
            } else {
                data.childtitle = `Related ${data.sobjectLabelPlural} (${Math.min(state.numberOfRecords, childRecords.length)})`;
            }  
        }
        return data;
    }

    sortData(fieldname, direction, records) {
        let parseData = JSON.parse(JSON.stringify(records));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        let secondaryKey = 'event'
        let secondaryKeyValue = (a) => {
            return a[secondaryKey];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => {
            let z = secondaryKeyValue(x) ? secondaryKeyValue(x) : '';
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            if(x == y) {
                if(z == 'Created') return 1;
                return -1;
            }
            return isReverse * ((x > y) - (y > x));
        });
        return parseData;
    }    

    groupRecords(records) {
        let results = [];
        if(records != undefined){
            let parseData = JSON.parse(JSON.stringify(records));
            let mapping = Object.fromEntries(
                parseData.map( row => [
                    row.objectLabel, undefined
                ]
            ));
            for(let objectLabel in mapping){
                let recordIds = mapping[objectLabel] == undefined ? {} : mapping[objectLabel];
                for(let rec of parseData){
                    if(rec.objectLabel == objectLabel){
                        if(recordIds[rec.recordId] == undefined){
                            recordIds[rec.recordId] = [];
                            recordIds[rec.recordId].push(rec);
                        } else {
                            recordIds[rec.recordId].push(rec);
                        }
                    }
                }
                mapping[objectLabel] = recordIds;
            }

            for(let objectLabel in mapping){
                let topLevel = {
                    historyId: objectLabel,
                    objectLabel: objectLabel,
                    recordName: null,
                    recordURL: null,
                    event: null,
                    createdDate: null,
                    createdByURL: null,
                    createdByName: null,
                    fieldLabel: null,
                    newValue: null
                }
                let midMap = mapping[objectLabel];
                let midChildren = [];
                for(let recordId in midMap){
                    midChildren.push({
                        historyId: objectLabel+recordId,
                        objectLabel: objectLabel,
                        recordName: null,
                        recordURL: null,
                        event: null,
                        createdDate: null,
                        createdByURL: null,
                        createdByName: null,
                        fieldLabel: null,
                        newValue: null,
                        _children: midMap[recordId]
                    });
                }
                topLevel._children = midChildren;
                results.push(topLevel);
            }
        }
        return results;
    }   

    initRelatedColumnsWithActions(row, doneCallback) {
        const actions = [];
        if (row.isCustom) {
            actions.push({
                'label': 'View Details',
                'name': 'view'
            });
        }
        doneCallback(actions);
    }

    initColumnsWithSuperActions(row, doneCallback) {
        const actions = [];
        if (row.isCustom) {
            actions.push({
                'label': 'Edit',
                'name': 'edit'
            });
            actions.push({
                'label': 'Delete',
                'name': 'delete'
            });
        }
        doneCallback(actions);
    }

    initRelatedColumnsWithSuperActions(row, doneCallback) {
        const actions = [];
        if (row.isCustom) {
            actions.push({
                'label': 'View Details',
                'name': 'view'
            });
            if(row.event != 'Updated'){
                actions.push({
                    'label': 'Edit',
                    'name': 'edit'
                });
            }
            actions.push({
                'label': 'Delete',
                'name': 'delete'
            });
        }
        doneCallback(actions);
    }

    generateLinks(records) {
        records.forEach(record => {
            record.LinkName = '/' + record.Id
            for (const propertyName in record) {
                const propertyValue = record[propertyName];
                if (typeof propertyValue === 'object') {
                    const newValue = propertyValue.Id ? ('/' + propertyValue.Id) : null;
                    this.flattenStructure(record, propertyName + '_', propertyValue);
                    if (newValue !== null) {
                        record[propertyName + '_LinkName'] = newValue;
                    }
                }
            }
        });

    }

    flattenStructure(topObject, prefix, toBeFlattened) {
        for (const propertyName in toBeFlattened) {
            const propertyValue = toBeFlattened[propertyName];
            if (typeof propertyValue === 'object') {
                this.flattenStructure(topObject, prefix + propertyName + '_', propertyValue);
            } else {
                topObject[prefix + propertyName] = propertyValue;
            }
        }
    }
}