import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AuditTrailManager extends LightningElement {
    @track activeTab = 'orgs';
    @track isLoading = false;

    tabs = [
        { value: 'orgs', label: 'Org Connections' },
        { value: 'analysis', label: 'Component Analysis' },
        { value: 'packages', label: 'Package Generation' },
        { value: 'deployments', label: 'Deployment History' }
    ];

    handleTabChange(event) {
        this.activeTab = event.target.value;
    }

    get isOrgsTab() {
        return this.activeTab === 'orgs';
    }

    get isAnalysisTab() {
        return this.activeTab === 'analysis';
    }

    get isPackagesTab() {
        return this.activeTab === 'packages';
    }

    get isDeploymentsTab() {
        return this.activeTab === 'deployments';
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}
