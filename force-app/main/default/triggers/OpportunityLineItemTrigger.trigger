trigger OpportunityLineItemTrigger on OpportunityLineItem (before insert, after insert) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            OpportunityLineItemTriggerHandler.beforeInsert(Trigger.New, Trigger.NewMap);
        }
    }
    else {
        if (Trigger.isInsert) {
            OpportunityLineItemTriggerHandler.afterInsert(Trigger.New, Trigger.NewMap);
        }
        
    }

}