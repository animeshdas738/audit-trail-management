import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generatePackageXml from '@salesforce/apex/PackageGenerationController.generatePackageXml';
import createDeploymentPackage from '@salesforce/apex/PackageGenerationController.createDeploymentPackage';

export default class PackageGenerator extends LightningElement {
    @track packageName = '';
    @track targetOrg = '';
    @track description = '';
    @track version = '1.0';
    @track apiVersion = '65.0';
    @track packageXml = '';
    @track isLoading = false;

    handleInputChange(event) {
        const field = event.target.name;
        this[field] = event.target.value;
    }

    handleGenerate() {
        // For demo purposes, using empty component list
        // In real implementation, this would receive components from analysis
        this.isLoading = true;
        
        const components = [];
        
        generatePackageXml({ 
            componentsJson: JSON.stringify(components), 
            apiVersion: this.apiVersion 
        })
        .then(result => {
            this.packageXml = result;
            this.showToast('Success', 'Package XML generated', 'success');
        })
        .catch(error => {
            this.showToast('Error', 'Error generating package: ' + error.body.message, 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    handleSave() {
        if (!this.packageName || !this.packageXml) {
            this.showToast('Error', 'Please enter package name and generate package XML', 'error');
            return;
        }

        this.isLoading = true;
        
        createDeploymentPackage({
            packageName: this.packageName,
            packageXml: this.packageXml,
            targetOrg: this.targetOrg,
            description: this.description,
            version: this.version,
            componentsJson: JSON.stringify([])
        })
        .then(packageId => {
            this.showToast('Success', 'Deployment package created', 'success');
            this.resetForm();
        })
        .catch(error => {
            this.showToast('Error', 'Error creating package: ' + error.body.message, 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    resetForm() {
        this.packageName = '';
        this.targetOrg = '';
        this.description = '';
        this.version = '1.0';
        this.packageXml = '';
    }

    get hasPackageXml() {
        return this.packageXml && this.packageXml.length > 0;
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
