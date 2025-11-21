import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAuditTrailFromAllOrgs from '@salesforce/apex/OrgConnectionController.getAuditTrailFromAllOrgs';
import analyzeComponents from '@salesforce/apex/ComponentAnalysisController.analyzeComponents';
import categorizeComponents from '@salesforce/apex/ComponentAnalysisController.categorizeComponents';

export default class ComponentAnalysis extends LightningElement {
    @track startDate;
    @track endDate;
    @track auditTrailData = [];
    @track components = [];
    @track categorizedComponents = {};
    @track isLoading = false;

    connectedCallback() {
        // Set default dates (last 7 days)
        const today = new Date();
        const lastWeek = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
        this.endDate = today.toISOString();
        this.startDate = lastWeek.toISOString();
    }

    handleStartDateChange(event) {
        this.startDate = event.target.value;
    }

    handleEndDateChange(event) {
        this.endDate = event.target.value;
    }

    handleAnalyze() {
        this.isLoading = true;
        
        getAuditTrailFromAllOrgs({ 
            startDate: new Date(this.startDate), 
            endDate: new Date(this.endDate) 
        })
        .then(result => {
            // Flatten audit trail data
            let allEntries = [];
            Object.keys(result).forEach(orgName => {
                allEntries = allEntries.concat(result[orgName]);
            });
            
            this.auditTrailData = allEntries;
            
            // Analyze components
            return analyzeComponents({ entriesJson: JSON.stringify(allEntries) });
        })
        .then(components => {
            this.components = components;
            
            // Categorize components
            return categorizeComponents({ componentsJson: JSON.stringify(components) });
        })
        .then(categorized => {
            this.categorizedComponents = categorized;
            this.showToast('Success', 'Analysis completed', 'success');
        })
        .catch(error => {
            this.showToast('Error', 'Error analyzing components: ' + error.body.message, 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    get hasComponents() {
        return this.components && this.components.length > 0;
    }

    get componentTypes() {
        return Object.keys(this.categorizedComponents).map(type => ({
            type: type,
            count: this.categorizedComponents[type].length
        }));
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
