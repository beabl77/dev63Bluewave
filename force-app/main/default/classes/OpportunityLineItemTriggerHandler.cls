public  class OpportunityLineItemTriggerHandler {
    public static void beforeInsert(List<OpportunityLineItem > newList, Map<Id, OpportunityLineItem > newMap){
        Set<Id> productIdSet = new Set<Id>();
        for (OpportunityLineItem oppit : newList) {
            productIdSet.add(oppit.Product2Id);
        }
        Map<Id,Stock_Count__c> prodIdStockCountMap = new Map<Id,Stock_Count__c>();
        for(Product2 p : [SELECT Id, IsActive, (SELECT Id, StockCount__c FROM Stock_Counts__r LIMIT 1)
                           FROM Product2 WHERE (Id IN: productIdSet) AND (IsActive = true)]){ 
            prodIdStockCountMap.put(p.Id,p.Stock_Counts__r[0]);        
        }
        system.debug('***prodIdStockCountMap: '+ prodIdStockCountMap);

        List<OpportunityLineItem> oppitList = new List<OpportunityLineItem>();
        for(OpportunityLineItem oppit : newList) {
            if (prodIdStockCountMap.isEmpty() || !prodIdStockCountMap.containskey(oppit.Product2Id)) {//prevent insert, product does not exist or is inactive
                oppit.addError('You cannot insert this opportunity product because product does not exist or is inactive'); 
            } 
            else if (prodIdStockCountMap.get(oppit.Product2Id).StockCount__c  < oppit.Quantity) { //prevent insert, not enought products in stock
                oppit.addError('You cannot insert this opportunity product because there is not enought stock available'); 
            }
            else {
                Stock_Count__c sc = prodIdStockCountMap.get(oppit.Product2Id);
                sc.StockCount__c = sc.StockCount__c - oppit.Quantity;
                prodIdStockCountMap.put(oppit.Product2Id, sc); //update stock count in the map
                oppitList.add(oppit);
                system.debug('***sc.StockCount__c: '+ sc.StockCount__c);

            }
        }
       
    }

    public static void afterInsert(List<OpportunityLineItem > newList, Map<Id, OpportunityLineItem > newMap){
        Map<Id, Decimal> productIdOppQuantityMap = new Map<Id, Decimal>();
        for (OpportunityLineItem oppit : newMap.values()) {
            if (productIdOppQuantityMap.containsKey(oppit.Product2Id)) {
                Decimal count = productIdOppQuantityMap.get(oppit.Product2Id) + oppit.Quantity;
                productIdOppQuantityMap.put(oppit.Product2Id, count);
            }
            else {
                productIdOppQuantityMap.put(oppit.Product2Id, oppit.Quantity);
            }
            system.debug('*** productIdOppQuantityMap.get(oppit.Product2Id): '+ productIdOppQuantityMap.get(oppit.Product2Id));
        }
        List<Stock_Count__c> stockCountToUpdateList = new List<Stock_Count__c>();
        for (Stock_Count__c sc: [SELECT Id, Product__c, StockCount__c FROM Stock_Count__c
                                 WHERE Product__c IN: productIdOppQuantityMap.keySet()]){
            sc.StockCount__c =  sc.StockCount__c - productIdOppQuantityMap.get(sc.Product__c);
            stockCountToUpdateList.add(sc);
        }
        system.debug('*** stockCountToUpdateList: '+ stockCountToUpdateList);
        try {
            update stockCountToUpdateList;
        }
        catch (DmlException e){
            System.debug('***Exception: ' + e.getMessage());
        }
        
    }

}