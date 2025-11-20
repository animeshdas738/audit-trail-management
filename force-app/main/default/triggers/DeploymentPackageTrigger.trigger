/**
 * @description Trigger for Deployment_Package__c
 */
trigger DeploymentPackageTrigger on Deployment_Package__c (before insert, before update, after insert, after update) {
    DeploymentPackageTriggerHandler handler = new DeploymentPackageTriggerHandler();
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
