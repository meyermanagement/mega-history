/* eslint-disable guard-for-in */
/* eslint-disable no-console */
import initDataMethod from "@salesforce/apex/RelatedListController.initData";

export default class RelatedListHelper {

    fetchData(state) {
        let jsonData = Object.assign({}, state);
        
        jsonData.numberOfRecords = state.numberOfRecords + 1;
        jsonData = JSON.stringify(jsonData);
        return initDataMethod({ jsonData })
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
        const records = data.records;
        const childRecords = data.childRecords;
        console.log('numberOfRecords>>'+state.numberOfRecords);
        //this.generateLinks(records);
        if(state.fullView){
               data.title = `${data.sobjectLabelPlural} (${records.length})`
               data.childtitle = `Related ${data.sobjectLabelPlural} (${childRecords.length})`
        } else {
            console.log('records.length>>'+records.length);
            if (records.length > state.numberOfRecords) {
                data.records = records.slice(0, state.numberOfRecords);
                data.title = `${data.sobjectLabelPlural} (${state.numberOfRecords}+)`;
            } else {
                data.title = `${data.sobjectLabelPlural} (${Math.min(state.numberOfRecords, records.length)})`;
            }  
            if (childRecords.length > state.numberOfRecords) {
                data.childRecords = childRecords.slice(0, state.numberOfRecords);
                data.childtitle = `Related ${data.sobjectLabelPlural} (${state.numberOfRecords}+)`;
            } else {
                data.childtitle = `Related ${data.sobjectLabelPlural} (${Math.min(state.numberOfRecords, childRecords.length)})`;
            }  
        }
        return data;
    }


    initColumnsWithActions(row, doneCallback) {
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