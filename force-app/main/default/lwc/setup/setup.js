import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import checkAPIConnection from "@salesforce/apex/SetupController.checkMetadataAPIConnection";
import checkPermissions from "@salesforce/apex/SetupController.checkPermissionAssignment";
import checkTracking from "@salesforce/apex/SetupController.checkRecordTracking";
import checkViews from "@salesforce/apex/SetupController.checkViews";
import getURL from "@salesforce/apex/SetupController.getOrgURL";

export default class Setup extends NavigationMixin(LightningElement) {

    @track showConnectionModal = false;
    @track showPermissionModal = false;
    @track showRemoteSiteConfiguration = false;
    @track showTrackingModal = false;
    @track showViewsModal = false;
    wiredConnection;
    wiredPermission;
    wiredTracking;
    wiredViews;
    orgURL;
    connectionLoading = true;
    permissionLoading = true;
    trackingLoading = true;
    viewsLoading = true;

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

    get trackingFailure() {
        return this.wiredTracking.data;
    }

    get trackingClass() {
        return this.wiredTracking.data ? 'action-needed' : 'action-completed'
    }

    get viewsFailure() {
        return this.wiredViews.data;
    }

    get viewsClass() {
        return this.wiredViews.data ? 'action-needed' : 'action-completed'
    }

    connectedCallback(){
        this.connectionLoading = true;
        this.permissionLoading = true;
        this.trackingLoading = true;
        this.viewsLoading = true;
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

    @wire(checkTracking)
    getTracking(result) {
        this.wiredTracking = result;
        this.trackingLoading = false;
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

    @wire(checkViews)
    getViews(result) {
        this.wiredViews = result;
        this.viewsLoading = false;
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

    handleTrackingClick() {
        if(this.trackingFailure) this.showTrackingModal = true;
    }

    handleViewsClick() {
        if(this.viewsFailure) this.showViewsModal = true;
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

    handleCloseTracking() {
        this.showTrackingModal = false;
        return refreshApex(this.wiredTracking);
    }

    handleCloseViews() {
        this.showViewsModal = false;
        return refreshApex(this.wiredViews);
    }

    addRSS() {
        this.showRemoteSiteConfiguration = true;
    }

    navigateTracking() {
        this[NavigationMixin.Navigate]({
            type: "standard__navItemPage",
            attributes: {
            apiName: "megahistory__Tracking",
            },
        });
    }

    navigateViews() {
        this[NavigationMixin.Navigate]({
            type: "standard__navItemPage",
            attributes: {
            apiName: "megahistory__Views",
            },
        });
    }
}
