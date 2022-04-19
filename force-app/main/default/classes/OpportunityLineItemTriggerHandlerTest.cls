@isTest
public class OpportunityLineItemTriggerHandlerTest {

    @testSetUp
    static void setUpData(){

        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;
        List<Product2> prodList = new List<Product2>();
        Product2 prod = new Product2(Name = 'P1', ProductCode = 'P1', IsActive = true);
        prodList.add(prod);
        prod = new Product2(Name = 'P2', ProductCode = 'P2', IsActive = true);
        prodList.add(prod);
        insert prodList;
        List<Stock_Count__c> scList = new List<Stock_Count__c>();
        Stock_Count__c sc = new Stock_Count__c(Product__c = prodList[0].Id, StockCount__c = 10);//P1
        scList.add(sc);
        sc = new Stock_Count__c(Product__c = prodList[1].Id, StockCount__c = 250);//P2
        scList.add(sc);
        insert scList;
        List<PricebookEntry> pBookEntryList = new List<PricebookEntry>();
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = standardPricebook.Id, 
                                                Product2Id = prodList[0].Id, Unitprice = 10, isActive = true);//P1
        pBookEntryList.add(pbe);
        pbe = new PricebookEntry(Pricebook2Id = standardPricebook.Id, 
                                Product2Id = prodList[1].Id, Unitprice = 20, isActive = true); //P2
        pBookEntryList.add(pbe);
        insert pBookEntryList;
        Opportunity opp = new Opportunity(Name = 'Opp1', CloseDate = Date.newInstance(2025, 1, 8), 
                        Pricebook2Id = standardPricebook.Id, StageName = 'Prospecting' );
        insert opp;
        opp = new Opportunity(Name = 'Opp2', CloseDate = Date.newInstance(2024, 2, 3), 
              Pricebook2Id = standardPricebook.Id, StageName = 'Prospecting');
        insert opp;
    }

    @isTest
    public static void PositiveTest(){ 
        Opportunity opp= [SELECT Id, Name FROM Opportunity WHERE Name = 'Opp1' LIMIT 1];
        //Get Product P1
        Product2 prod1 = [SELECT Id, IsActive FROM Product2 WHERE Name = 'P1' LIMIT 1];
        Stock_Count__c sc = [SELECT Id, Product__c, StockCount__c FROM Stock_Count__c WHERE Product__c = :prod1.Id LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id, Pricebook2Id, Unitprice FROM PricebookEntry WHERE Product2Id = :prod1.Id LIMIT 1];
        List<OpportunityLineItem> oppitList = new List<OpportunityLineItem>();
        Decimal num = 0;
        for (Integer i = 1; i <= sc.StockCount__c; i++) {
            num +=1;
            OpportunityLineItem oppit = new OpportunityLineItem (
            OpportunityId = opp.Id, Product2Id = prod1.Id, Quantity = 1, TotalPrice=10);
            oppitList.add(oppit);
        }
        System.assertEquals((Decimal)sc.StockCount__c, num); //All stock will be saled
        Test.startTest();
        insert oppitList;
        Test.stopTest();
        sc = [SELECT Id, Product__c, StockCount__c FROM Stock_Count__c WHERE Product__c = :prod1.Id LIMIT 1 ];
        System.assertEquals((Decimal)sc.StockCount__c, 0); //No stock
        Decimal oppitCount = [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId =: opp.Id];
        System.assertEquals(oppitCount, oppitList.size()); //Each opp line item has a quantity = 1, so count(opp item) = number inserted 
        
    }

    @isTest
    public static void NegativeTest(){ 
         //Get Opp 1 and Product P1
        Opportunity opp1= [SELECT Id, Name FROM Opportunity WHERE Name = 'Opp1' LIMIT 1];
        Product2 prod1 = [SELECT Id, IsActive FROM Product2 WHERE Name = 'P1' LIMIT 1];
        prod1.IsActive = false; //now inactive
        update prod1;
        Stock_Count__c sc1 = [SELECT Id, Product__c, StockCount__c FROM Stock_Count__c WHERE Product__c = :prod1.Id LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id, Pricebook2Id, Unitprice FROM PricebookEntry WHERE Product2Id = :prod1.Id LIMIT 1];
        List<OpportunityLineItem> oppitList = new List<OpportunityLineItem>();
        OpportunityLineItem oppitOpp1 = new OpportunityLineItem(
            OpportunityId = opp1.Id, 
            Product2Id = prod1.Id, 
            Quantity = sc1.StockCount__c - 1 
        );
        oppitList.add(oppitOpp1);
       
        //Get Opp2 and Product P2
        Opportunity opp2= [SELECT Id, Name FROM Opportunity WHERE Name = 'Opp2' LIMIT 1];
        Product2 prod2 = [SELECT Id, IsActive FROM Product2 WHERE Name = 'P2' LIMIT 1];
        Stock_Count__c sc2 = [SELECT Id, Product__c, StockCount__c FROM Stock_Count__c WHERE Product__c = :prod2.Id LIMIT 1];
        pbe = [SELECT Id, Product2Id, Pricebook2Id, Unitprice FROM PricebookEntry WHERE Product2Id = :prod2.Id LIMIT 1];
        OpportunityLineItem oppitOpp2 = new OpportunityLineItem (
            OpportunityId = opp2.Id, 
            Product2Id = prod2.Id, 
            Quantity = sc2.StockCount__c + 5
        ); 
        oppitList.add(oppitOpp2);
        
        System.assert((Decimal)sc2.StockCount__c > oppitList.size()); //There is not enough stock
        
        Test.startTest();

        Boolean IsException = false;
        List<String> exceptionsMessagesList = new List<String>();
        try{
            insert oppitList;
        }
        catch (System.DmlException e) {
            IsException = true;
            for (Integer i = 0; i < e.getNumDml(); i++) {
                System.debug('Exception: ' + e.getDmlMessage(i));
                exceptionsMessagesList.add( e.getDmlMessage(i));
            }
        }
        Test.stopTest();
        System.assert(exceptionsMessagesList.size() == 2);
        System.assertEquals('You cannot insert this opportunity product because product does not exist or is inactive', exceptionsMessagesList[0]); 
        System.assertEquals('You cannot insert this opportunity product because there is not enought stock available', exceptionsMessagesList[1]);
        
    }

    @isTest
    public static void BulkyTest(){ 
        //Get Opp2 and Product P2
        Opportunity opp2= [SELECT Id, Name FROM Opportunity WHERE Name = 'Opp2' LIMIT 1];
        Product2 prod2 = [SELECT Id, IsActive FROM Product2 WHERE Name = 'P2' LIMIT 1];
        Stock_Count__c sc2 = [SELECT Id, Product__c, StockCount__c FROM Stock_Count__c WHERE Product__c = :prod2.Id LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id, Pricebook2Id, Unitprice FROM PricebookEntry WHERE Product2Id = :prod2.Id LIMIT 1];
        List<OpportunityLineItem> oppitList = new List<OpportunityLineItem>();
        for (Integer i = 1; i < sc2.StockCount__c; i++) {
            OpportunityLineItem oppitOpp2 = new OpportunityLineItem (
                OpportunityId = opp2.Id, 
                Product2Id = prod2.Id, 
                Quantity = 1,
                TotalPrice = pbe.Unitprice
            ); 
            oppitList.add(oppitOpp2);
        }
        Decimal stockCount = sc2.StockCount__c;
        Test.startTest();
        insert oppitList;
        Test.stopTest();
        sc2 = [SELECT Id, Product__c, StockCount__c FROM Stock_Count__c WHERE Product__c = :prod2.Id LIMIT 1 ];
        Decimal oppitCount = [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId =: opp2.Id];
        System.assertEquals(oppitCount, oppitList.size()); //Each opp line item has a quantity = 1, so count(opp item) = number inserted 
    }

    @isTest
    public static void testRunAs() {
        String uniqueUserName = 'user' + DateTime.now().getTime() + '@test.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='user@test.com',
                    EmailEncodingKey='UTF-8', LastName='TestUser', LanguageLocaleKey='en_US',
                    LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles',
                    UserName = uniqueUserName
        );

        System.runAs(u) {
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Current Profile: ' + UserInfo.getProfileId());
            //Get Opp2 and Product P2
            Opportunity opp2= [SELECT Id, Name FROM Opportunity WHERE Name = 'Opp2' LIMIT 1];
            Product2 prod2 = [SELECT Id, IsActive FROM Product2 WHERE Name = 'P2' LIMIT 1];
            Stock_Count__c sc2 = [SELECT Id, Product__c, StockCount__c FROM Stock_Count__c WHERE Product__c = :prod2.Id LIMIT 1];
            PricebookEntry pbe = [SELECT Id, Product2Id, Pricebook2Id, Unitprice FROM PricebookEntry WHERE Product2Id = :prod2.Id LIMIT 1];
            OpportunityLineItem oppitOpp2 = new OpportunityLineItem (
                OpportunityId = opp2.Id, 
                Product2Id = prod2.Id, 
                Quantity = sc2.StockCount__c - 1,
                TotalPrice = (sc2.StockCount__c - 1) * pbe.Unitprice
            ); 
            Decimal oldStockCount = sc2.StockCount__c;
            Test.startTest();
            insert oppitOpp2;
            Test.stopTest();

            sc2 = [SELECT Id, Product__c, StockCount__c FROM Stock_Count__c WHERE Product__c = :prod2.Id LIMIT 1 ];
            oppitOpp2 = [SELECT Id,  Quantity FROM OpportunityLineItem WHERE OpportunityId =: opp2.Id];
            System.assertEquals(oldStockCount - oppitOpp2.Quantity , sc2.StockCount__c); 

        }
    }

}