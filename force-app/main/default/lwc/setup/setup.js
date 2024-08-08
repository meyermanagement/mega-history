import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import checkAPIConnection from "@salesforce/apex/SetupController.checkMetadataAPIConnection";
import getURL from "@salesforce/apex/SetupController.getOrgURL";

export default class Setup extends LightningElement {

    @track showConnectionModal = false;
    @track showRemoteSiteConfiguration = false;
    wiredConnection;
    orgURL;

    get connectionFailure() {
        return this.wiredConnection.data;
    }

    get connectionClass() {
        return this.wiredConnection.data ? 'action-needed' : 'action-completed'
    }

    connectedCallback(){
        //this.connectionFailure = true;
    }

    @wire(checkAPIConnection)
    getConnection(result) {
        this.wiredConnection = result;
        if (result.error) {
            console.log(result.error.body.message);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "An error has occurred. Please contact the system administrator for further assistance.",
                    message: result.error.body.message,
                    variant: "error",
                }),
            );
        }
    }

    @wire(getURL)
    getOrgURL(result) {
        const{data, error} = result;
        if (data) {
            this.orgURL = data;
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


    handleConnectionClick() {
        if(this.connectionFailure) this.showConnectionModal = true;
    }

    handleClose() {
        this.showRemoteSiteConfiguration = false;
        this.showConnectionModal = false;
        return refreshApex(this.wiredConnection);
    }

    addRSS() {
        this.showRemoteSiteConfiguration = true;
    }
}
