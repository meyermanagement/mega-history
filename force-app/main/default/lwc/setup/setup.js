import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import checkAPIConnection from "@salesforce/apex/SetupController.checkMetadataAPIConnection";
import checkPermissions from "@salesforce/apex/SetupController.checkPermissionAssignment";
import checkTracking from "@salesforce/apex/SetupController.checkRecordTracking";
import checkViews from "@salesforce/apex/SetupController.checkViews";
import getURL from "@salesforce/apex/SetupController.getOrgURL";
import MEGA_HISTORY_LOGO from "@salesforce/contentAssetUrl/MEGA_Main_Logo";

export default class Setup extends NavigationMixin(LightningElement) {

    @track showConnectionModal = false;
    @track showPermissionModal = false;
    @track showRemoteSiteConfiguration = false;
    @track showTrackingModal = false;
    @track showViewsModal = false;
    wiredConnection;
    wiredPermission;
    wiredTracking;
    wiredViews = true;
    orgURL;
    connectionLoading;
    permissionLoading;
    trackingLoading;
    viewsLoading;
    logoUrl = MEGA_HISTORY_LOGO;

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
        return this.wiredViews;
    }

    get viewsClass() {
        return this.wiredViews ? 'action-needed' : 'action-completed'
    }

    connectedCallback(){
        if(this.wiredTracking.data == undefined) {
            this.connectionLoading = true;
            this.permissionLoading = true;
            this.trackingLoading = true;
            this.viewsLoading = true;
        } else {
            refreshApex(this.wiredConnection);
            refreshApex(this.wiredPermission);
            refreshApex(this.wiredTracking);
            refreshApex(this.wiredViews);
        }
    }

    @wire(checkAPIConnection)
    getConnection(result) {
        console.log('getConnection');
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
        console.log('getPermissions');
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
        console.log('getTracking');
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
        console.log('getViewsresult>>'+JSON.stringify(result));
        this.wiredViews = result.data;
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
        this.showTrackingModal = false;
        this[NavigationMixin.Navigate]({
            type: "standard__navItemPage",
            attributes: {
            apiName: "megatools__Tracking",
            },
        });
    }

    navigateViews() {
        this.showViewsModal = false;
        this[NavigationMixin.Navigate]({
            type: "standard__navItemPage",
            attributes: {
            apiName: "megatools__Views",
            },
        });
    }
}
