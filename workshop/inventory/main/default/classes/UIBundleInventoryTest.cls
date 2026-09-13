@IsTest
private class UIBundleInventoryTest {

    @IsTest
    static void missingProductIdReturns400() {
        RestRequest req = new RestRequest();
        req.httpMethod = 'GET';
        req.requestURI = '/services/apexrest/inventory/availability';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        UIBundleInventory.AvailabilityResponse result = UIBundleInventory.getAvailability();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assert(result instanceof UIBundleInventory.ErrorAvailabilityResponse);
    }

    @IsTest
    static void unknownProductReturnsZeroOnHandAndAllLocations() {
        RestRequest req = new RestRequest();
        req.httpMethod = 'GET';
        req.requestURI = '/services/apexrest/inventory/availability';
        req.addParameter('productId', '01t000000000001AAA');
        RestContext.request = req;
        RestContext.response = new RestResponse();

        UIBundleInventory.AvailabilityResponse result = UIBundleInventory.getAvailability();

        System.assert(result instanceof UIBundleInventory.SuccessAvailabilityResponse);
        UIBundleInventory.SuccessAvailabilityResponse ok =
            (UIBundleInventory.SuccessAvailabilityResponse) result;
        System.assertEquals(true, ok.success);
        System.assertEquals(0, ok.quantityOnHand);
        System.assertEquals(6, ok.locations.size());
        for (UIBundleInventory.LocationAvailability loc : ok.locations) {
            System.assertNotEquals(null, loc.name);
            System.assertEquals(0, loc.quantityOnHand);
        }
    }
}
