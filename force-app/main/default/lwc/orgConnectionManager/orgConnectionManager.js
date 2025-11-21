import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOrgConnections from '@salesforce/apex/OrgConnectionController.getOrgConnections';
import testConnection from '@salesforce/apex/OrgConnectionController.testConnection';

const COLUMNS = [
    { label: 'Org Name', fieldName: 'Org_Name__c', type: 'text' },
    { label: 'Environment Type', fieldName: 'Environment_Type__c', type: 'text' },
    { label: 'Instance URL', fieldName: 'Instance_URL__c', type: 'url' },
    { label: 'Active', fieldName: 'Is_Active__c', type: 'boolean' },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: 'Test Connection', name: 'test' },
                { label: 'View Audit Trail', name: 'view_audit' }
            ]
        }
    }
];

export default class OrgConnectionManager extends LightningElement {
    @track orgConnections = [];
    @track isLoading = false;
    @track error;
    columns = COLUMNS;

    @wire(getOrgConnections)
    wiredOrgs({ error, data }) {
        if (data) {
            this.orgConnections = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.orgConnections = [];
            this.showToast('Error', 'Failed to load org connections', 'error');
        }
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        switch (action.name) {
            case 'test':
                this.handleTestConnection(row);
                break;
            case 'view_audit':
                this.handleViewAudit(row);
                break;
            default:
                break;
        }
    }

    handleTestConnection(row) {
        this.isLoading = true;
        testConnection({ orgDeveloperName: row.DeveloperName })
            .then(result => {
                if (result) {
                    this.showToast('Success', 'Connection successful to ' + row.Org_Name__c, 'success');
                } else {
                    this.showToast('Error', 'Connection failed to ' + row.Org_Name__c, 'error');
                }
            })
            .catch(error => {
                this.showToast('Error', 'Error testing connection: ' + error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleViewAudit(row) {
        // Dispatch event to parent to show audit trail
        const event = new CustomEvent('viewaudit', {
            detail: { orgName: row.DeveloperName }
        });
        this.dispatchEvent(event);
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
