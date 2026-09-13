---
name: commerce-b2b-workshop-inventory
description: "Deploys workshop inventory Apex and assigns UIBundleApexAccess so a B2B Buyer can call inventory availability. TRIGGER when the user asks to set up workshop inventory, PDP availability Apex, UIBundleInventory, UIBundleApexAccess, or assign the inventory permset. DO NOT TRIGGER for storefront setup/deploy, Commerce Connect API work, Agent Script, or vibe-coding the PDP React availability UI."
---

# Workshop inventory Apex setup

Make it easy for workshop attendees to deploy inventory availability classes and assign `UIBundleApexAccess`. Follow [workshop/inventory-package-README.md](../../../workshop/inventory-package-README.md) (same process as `commerce-b2b-inventory-workshop/README.md`).

Local source is **`workshop/inventory` in the open project**, not the zip. Do not unzip, copy, or invent files. Auth Apex (`UIBundleLogin`, etc.) must already be in the org from the storefront deploy; this skill does not copy those classes.

Do not vibe-code React (`ProductAvailability.tsx`, `inventory.ts`, `useProductAvailability.ts`). Do not add `UIBundleInventory` to B2B Buyer Profile. Do not change Location names in Apex. Do not run `scripts/workshop-step3.mjs` or `npm run workshop-step3`.

## Hard stops

- Never run a bare `sf project deploy start`.
- Never deploy `force-app` from this skill.
- Never assign `UIBundleApexAccess` to a guessed username.
- Site-guest permset assign is **optional** and only if the user asks (unauthenticated `/login` 403). Do not run it by default.

## Required workflow

Follow these steps in order. After a step succeeds, announce the next step and start it.

### 1. Confirm target org

```bash
sf config get target-org --json
sf org display --json
```

If no target org is set, authenticate:

```bash
sf org login web --alias my-demo-org --set-default --instance-url https://<my-domain>.my.salesforce.com
```

Replace `<my-domain>` and the alias with the user's values. Do not guess the instance URL.

### 2. Confirm local files

These must exist under `workshop/inventory/main/default/`:

- `classes/UIBundleInventory.cls`
- `classes/UIBundleInventory.cls-meta.xml`
- `classes/UIBundleInventoryTest.cls`
- `classes/UIBundleInventoryTest.cls-meta.xml`
- `permissionsets/UIBundleApexAccess.permissionset-meta.xml`

If any are missing, stop. Do not unzip or invent files.

### 3. Deploy inventory metadata

Repo equivalent of README `--source-dir .`:

```bash
sf project deploy start --source-dir workshop/inventory --target-org <alias>
```

Deploys `UIBundleInventory` (+ test) and `UIBundleApexAccess`.

### 4. Resolve buyer username

Default buyer: **buyer@b2bheadless.com**. Query; do not guess:

```bash
sf data query --target-org <alias> --query "SELECT Id, Username FROM User WHERE Username = 'buyer@b2bheadless.com'"
```

- If a row is returned, use `buyer@b2bheadless.com`.
- If zero rows, **ask** the attendee for the Salesforce Username of the B2B Buyer they just created. Do not invent a username.

### 5. Assign UIBundleApexAccess

```bash
sf org assign permset --name UIBundleApexAccess --on-behalf-of <buyerUsername> --target-org <alias>
```

If the output includes Duplicate and PermissionSet, the permset is already assigned — treat as success and continue.

### 6. Done

Tell the user the contract:

```
GET /services/apexrest/inventory/availability?productId={productId}
{ "success": true, "quantityOnHand": 47 }
```

Stop. Do not start the PDP availability UI lab unless the user asks separately.

## Optional: site guest (only if the user asks)

So unauthenticated React `/login` is not 403:

```bash
sf data query --target-org <alias> \
  --query "SELECT Id, Name, GuestUserId FROM Site WHERE Name = 'commerceb2bheadless'"

sf org assign permset --name UIBundleApexAccess --on-behalf-of <GuestUsername> --target-org <alias>
```
