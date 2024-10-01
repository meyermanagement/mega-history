import { LightningElement, api } from 'lwc';

export default class RecordTile extends LightningElement {

    @api record
    @api relatedRecord
    
    handleOnselect(event) {
        console.log(JSON.stringify(event.detail));
        console.log(JSON.stringify(event.detail.value));
        const selectedEvent = new CustomEvent('select', {
            detail: {
                action: {
                    name: event.detail.value,
                },
                row: this.record
            }
        });
        //dispatching the custom event
        this.dispatchEvent(selectedEvent);
    }
}