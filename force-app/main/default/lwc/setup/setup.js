import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import checkAPIConnection from "@salesforce/apex/SetupController.checkMetadataAPIConnection";

export default class Setup extends LightningElement {

    @track showConnectionModal = false;
    @track connectionFailure;
    connectionClass = 'action-completed';

    connectedCallback(){
        //this.connectionFailure = true;
    }

    @wire(checkAPIConnection)
    getConnection(result) {
        const{data, error} = result;
        if (data) {
            this.connectionFailure = data;
            if(this.connectionFailure) this.connectionClass = 'action-needed';
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

    refresh(){
        refreshApex(this.wiredDocuments);
    }

    handleConnectionClick() {
        this.showConnectionModal = true;
    }

    handleClose() {
        this.showConnectionModal = false;
    }
}
