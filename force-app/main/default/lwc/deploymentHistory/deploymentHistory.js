import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import getDeploymentPackages from '@salesforce/apex/DeploymentHistoryController.getDeploymentPackages';

const COLUMNS = [
    { label: 'Package Number', fieldName: 'Name', type: 'text' },
    { label: 'Package Name', fieldName: 'Package_Name__c', type: 'text' },
    { label: 'Status', fieldName: 'Status__c', type: 'text' },
    { label: 'Version', fieldName: 'Version__c', type: 'text' },
    { label: 'Target Org', fieldName: 'Target_Org__c', type: 'text' },
    { label: 'Component Count', fieldName: 'Component_Count__c', type: 'number' },
    { label: 'Created Date', fieldName: 'CreatedDate', type: 'date' },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: 'View Details', name: 'view' },
                { label: 'Download XML', name: 'download' }
            ]
        }
    }
];

export default class DeploymentHistory extends NavigationMixin(LightningElement) {
    @track deploymentPackages = [];
    columns = COLUMNS;
    wiredPackagesResult;

    @wire(getDeploymentPackages)
    wiredPackages(result) {
        this.wiredPackagesResult = result;
        if (result.data) {
            this.deploymentPackages = result.data;
        }
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        switch (action.name) {
            case 'view':
                this.handleViewDetails(row);
                break;
            case 'download':
                this.handleDownloadXml(row);
                break;
            default:
                break;
        }
    }

    handleViewDetails(row) {
        // Navigate to record detail page
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: row.Id,
                objectApiName: 'Deployment_Package__c',
                actionName: 'view'
            }
        });
    }

    handleDownloadXml(row) {
        // Download package XML using base64 encoding for Locker Service compatibility
        const xmlContent = row.Package_XML__c || '';
        const base64Data = btoa(unescape(encodeURIComponent(xmlContent)));
        const dataUri = 'data:text/xml;base64,' + base64Data;
        
        const element = document.createElement('a');
        element.href = dataUri;
        element.download = row.Name + '_package.xml';
        document.body.appendChild(element);
        element.click();
        document.body.removeChild(element);
    }

    handleRefresh() {
        return refreshApex(this.wiredPackagesResult);
    }
}
