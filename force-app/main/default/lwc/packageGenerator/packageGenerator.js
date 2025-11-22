import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generatePackageXml from '@salesforce/apex/PackageGenerationController.generatePackageXml';
import createDeploymentPackage from '@salesforce/apex/PackageGenerationController.createDeploymentPackage';
import getAuditTrail from '@salesforce/apex/OrgConnectionController.getAuditTrail';
import analyzeComponents from '@salesforce/apex/ComponentAnalysisController.analyzeComponents';

export default class PackageGenerator extends LightningElement {
    @track packageName = '';
    @track targetOrg = '';
    @track description = '';
    @track version = '1.0';
    @track apiVersion = '65.0';
    @track packageXml = '';
    @track isLoading = false;
    @track startDate;
    @track endDate;
    @track components = [];

    handleInputChange(event) {
        const field = event.target.name;
        this[field] = event.target.value;
    }

    handleGenerate() {
        if (!this.targetOrg) {
            this.showToast('Error', 'Please enter target org name', 'error');
            return;
        }

        if (!this.startDate || !this.endDate) {
            this.showToast('Error', 'Please select start and end dates', 'error');
            return;
        }

        this.isLoading = true;
        
        // Fetch audit trail from target org
        getAuditTrail({ 
            orgDeveloperName: this.targetOrg, 
            startDate: new Date(this.startDate), 
            endDate: new Date(this.endDate) 
        })
        .then(auditTrailEntries => {
            if (!auditTrailEntries || auditTrailEntries.length === 0) {
                this.showToast('Warning', 'No audit trail entries found for the specified date range', 'warning');
                this.components = [];
                return [];
            }
            
            this.showToast('Info', `Retrieved ${auditTrailEntries.length} audit trail entries`, 'info');
            
            // Analyze components from audit trail
            return analyzeComponents({ entriesJson: JSON.stringify(auditTrailEntries) });
        })
        .then(analyzedComponents => {
            if (!analyzedComponents || analyzedComponents.length === 0) {
                this.showToast('Warning', 'No components found to package', 'warning');
                this.components = [];
                return '';
            }
            
            this.components = analyzedComponents;
            this.showToast('Info', `Analyzed ${analyzedComponents.length} components`, 'info');
            
            // Generate package XML from analyzed components
            return generatePackageXml({ 
                componentsJson: JSON.stringify(analyzedComponents), 
                apiVersion: this.apiVersion 
            });
        })
        .then(result => {
            if (result) {
                this.packageXml = result;
                this.showToast('Success', 'Package XML generated successfully', 'success');
            }
        })
        .catch(error => {
            this.showToast('Error', 'Error generating package: ' + (error.body?.message || error.message), 'error');
            console.error('Package generation error:', error);
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
            componentsJson: JSON.stringify(this.components)
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
        this.components = [];
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
