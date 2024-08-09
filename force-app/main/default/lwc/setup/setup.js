import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import checkAPIConnection from "@salesforce/apex/SetupController.checkMetadataAPIConnection";
import checkPermissions from "@salesforce/apex/SetupController.checkPermissionAssignment";
import getURL from "@salesforce/apex/SetupController.getOrgURL";

export default class Setup extends LightningElement {

    @track showConnectionModal = false;
    @track showPermissionModal = false;
    @track showRemoteSiteConfiguration = false;
    wiredConnection;
    wiredPermission;
    orgURL;
    connectionLoading = true;
    permissionLoading = true;

    get connectionFailure() {
        return this.wiredConnection.data;
    }

    get connectionClass() {
        return this.wiredConnection.data ? 'action-needed' : 'action-completed'
    }

    get permissionFailure() {
        return this.wiredPermission.data;
    }

    get permissionClass() {
        return this.wiredPermission.data ? 'action-needed' : 'action-completed'
    }

    connectedCallback(){
        this.connectionLoading = true;
        this.permissionLoading = true;
    }

    @wire(checkAPIConnection)
    getConnection(result) {
        this.wiredConnection = result;
        this.connectionLoading = false;
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

    @wire(checkPermissions)
    getPermissions(result) {
        this.wiredPermission = result;
        this.permissionLoading = false;
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

    handlePermissionClick() {
        if(this.permissionFailure) this.showPermissionModal = true;
    }

    handleClose() {
        this.showRemoteSiteConfiguration = false;
        this.showConnectionModal = false;
        return refreshApex(this.wiredConnection);
    }

    handleClosePermission() {
        this.showPermissionModal = false;
        return refreshApex(this.wiredPermission);
    }

    addRSS() {
        this.showRemoteSiteConfiguration = true;
    }
}
