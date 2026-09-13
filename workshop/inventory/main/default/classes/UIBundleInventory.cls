/**
 * REST endpoint for consolidated ProductItem on-hand quantity.
 *
 * Endpoint: GET /services/apexrest/inventory/availability?productId={product2Id}
 *
 * Workshop backend — customers do not edit this class. They vibe-code a React
 * component that calls this URL after UIBundleApexAccess is assigned to their buyer.
 *
 * SUM(QuantityOnHand) across the pre-configured Location set, plus a per-location
 * breakdown. This is physical on-hand, not Omnichannel Inventory ATP.
 */
@RestResource(urlMapping='/inventory/availability')
global without sharing class UIBundleInventory {

    // Locations included in the PDP availability rollup, matched by Name so
    // the list is portable across orgs. Confirm yours with:
    //   sf data query --query "SELECT Id, Name FROM Location WHERE Name IN ('East Coast Cirrus Warehouse')"
    private static final List<String> LOCATION_NAMES = new List<String>{
        'East Coast Cirrus Warehouse',
        'South East Cirrus Warehouse',
        'Mountain Cirrus Warehouse',
        'Midwest Cirrus Warehouse',
        'West Coast Cirrus Warehouse',
        'North East Cirrus Warehouse'
    };

    @HttpGet
    global static AvailabilityResponse getAvailability() {
        try {
            String productId = RestContext.request.params.get('productId');
            if (String.isBlank(productId)) {
                RestContext.response.statusCode = 400;
                return new ErrorAvailabilityResponse('productId is required.');
            }
            productId = productId.trim();

            Map<String, Decimal> qtyByName = new Map<String, Decimal>();
            for (String locName : LOCATION_NAMES) {
                qtyByName.put(locName, 0);
            }

            if (!LOCATION_NAMES.isEmpty()) {
                List<AggregateResult> rows = [
                    SELECT Location.Name locName, SUM(QuantityOnHand) qty
                    FROM ProductItem
                    WHERE Product2Id = :productId
                    AND Location.Name IN :LOCATION_NAMES
                    GROUP BY Location.Name
                ];
                for (AggregateResult row : rows) {
                    String locName = (String) row.get('locName');
                    Decimal qty = (Decimal) row.get('qty');
                    if (locName != null) {
                        qtyByName.put(locName, qty == null ? 0 : qty);
                    }
                }
            }

            Decimal onHand = 0;
            List<LocationAvailability> locations = new List<LocationAvailability>();
            for (String locName : LOCATION_NAMES) {
                Decimal qty = qtyByName.get(locName);
                if (qty == null) {
                    qty = 0;
                }
                onHand += qty;
                locations.add(new LocationAvailability(locName, qty));
            }

            return new SuccessAvailabilityResponse(onHand, locations);
        } catch (Exception ex) {
            RestContext.response.statusCode = 500;
            return new ErrorAvailabilityResponse('Failed to load availability.');
        }
    }

    global abstract class AvailabilityResponse {}

    global class LocationAvailability {
        global String name;
        global Decimal quantityOnHand;
        global LocationAvailability(String name, Decimal quantityOnHand) {
            this.name = name;
            this.quantityOnHand = quantityOnHand;
        }
    }

    global class SuccessAvailabilityResponse extends AvailabilityResponse {
        global Boolean success = true;
        global Decimal quantityOnHand;
        global List<LocationAvailability> locations;
        global SuccessAvailabilityResponse(Decimal quantityOnHand, List<LocationAvailability> locations) {
            this.quantityOnHand = quantityOnHand;
            this.locations = locations;
        }
    }

    global class ErrorAvailabilityResponse extends AvailabilityResponse {
        global Boolean success = false;
        global List<String> errors;
        global ErrorAvailabilityResponse(String error) {
            this.errors = new List<String>{ error };
        }
    }
}
