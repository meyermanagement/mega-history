import { LightningElement, api } from 'lwc';

export default class RecordTile extends LightningElement {

    @api record
    @api relatedRecord
    @api isSuperUser

    get showMenu(){
        return this.record.isCustom && (this.relatedRecord || this.superUser)
    }

    get isNotRelatedUpdate(){
        return !this.relatedRecord || (this.relatedRecord && this.record.event != 'Updated');
    }

    get superUser() {
        return this.isSuperUser == 'true';
    }
    
    handleOnSelect(event) {
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