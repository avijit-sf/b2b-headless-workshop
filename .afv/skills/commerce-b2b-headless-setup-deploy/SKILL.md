---
name: commerce-b2b-headless-setup-deploy
description: "Sets up org-specific values and deploys this B2B Commerce headless storefront. TRIGGER when the user asks to set up, configure, adapt, or deploy this storefront to an org; mentions webstore id, buyer group, permission set group, Vite org alias, sf project deploy, or the new storefront URL. DO NOT TRIGGER for storefront feature work, Commerce Connect API changes, Agent Script, or Workshop PDP availability (inventory Apex, UIBundleApexAccess, workshop.config.json, PDP availability UI) — use commerce-b2b-workshop-inventory for inventory Apex and permset assign."
---

# B2B headless storefront setup and deploy

Walk the user through README **What you must change before deploying** items **1–4** and **Deploy to your org**, in that order. Do not invent a different procedure.

Skip README step 5 (org/site/network/profile production review). Do not edit `enableGuestChatter` or related flags as part of this skill.

## Hard stops

- Never deploy `workshop/inventory`.
- Never assign `UIBundleApexAccess`.
- Never run `scripts/workshop-step3.mjs` or `npm run workshop-step3`.
- Never run a bare `sf project deploy start` (it also deploys workshop/inventory). Always pass `--source-dir force-app` for a full storefront deploy.
- Do not continue into Workshop: PDP availability.

## Prerequisites

Node 22+, `sf` CLI 2.130+, an org with B2B Commerce + Multi-framework React enabled (262.6+). The user needs the org's My Domain login URL (e.g. `https://mycompany.my.salesforce.com`).

If already inside this repo, do **not** clone again.

## Required workflow

Follow these steps in order. After a step succeeds, announce the next step and start it. Stop only when a required record is missing or a command fails. Do not ask the user to pick among records.

### 0. Confirm target org

```bash
sf config get target-org --json
sf org display --json
```

If no target org is set, authenticate using the user's My Domain URL:

```bash
sf org login web --alias my-demo-org --set-default --instance-url https://<my-domain>.my.salesforce.com
```

Replace `<my-domain>` and the alias with the user's values. Do not guess the instance URL.

### 1. Webstore id

Use **SDO - B2B Commerce Enhanced**. Query the target org:

```bash
sf data query --target-org <alias> --query "SELECT Id, Name, Type FROM WebStore WHERE Type = 'B2B' AND Name = 'SDO - B2B Commerce Enhanced'"
```

Write the 18-character `Id` (starts with `0ZE`) into `WEBSTORE_ID` in `force-app/main/default/uiBundles/commerceb2bheadless/src/config/commerce.ts`:

```ts
export const COMMERCE = {
  WEBSTORE_ID: "<Webstore_Id_Placeholder>",
  API_VERSION: "v67.0",
} as const;
```

The file may already contain a demo org id — always replace it with this WebStore's id. Leave `API_VERSION` at `v67.0` unless the user says otherwise.

If zero rows, fail with the exact name `SDO - B2B Commerce Enhanced` and stop. If more than one row, use the first Id and continue. Do not ask the user to choose.

### 2. Default buyer group id

Use **Cirrus Silver Buyer Group**. `UIBundleRegistration.cls` enrolls every newly self-registered buyer into one BuyerGroup so the WebStore entitlement applies.

```bash
sf data query --target-org <alias> --query "SELECT Id, Name FROM BuyerGroup WHERE Name = 'Cirrus Silver Buyer Group'"
```

Write the 18-character `Id` (starts with `0ZI`) into `DEFAULT_BUYER_GROUP_ID` in `force-app/main/default/classes/UIBundleRegistration.cls`:

```apex
private static final String DEFAULT_BUYER_GROUP_ID = '<Buyer_Group_Id_Placeholder>';
```

If you don't replace this, registration succeeds but the new buyer is left without store access, and their first commerce API call returns `INSUFFICIENT_ACCESS`.

If zero rows, fail with the exact name `Cirrus Silver Buyer Group` and stop. If more than one row, use the first Id and continue. Do not ask the user to choose.

### 3. Buyer permission set group

Use **SDO_B2BCommerce_Base_Buyer**. `UIBundleRegistration.cls` grants every newly self-registered buyer a Permission Set Group so they inherit the store's commerce entitlement (cart, checkout, order placement).

Verify it exists (fail if missing; do not ask):

```bash
sf data query --target-org <alias> --query "SELECT Id, DeveloperName FROM PermissionSetGroup WHERE DeveloperName = 'SDO_B2BCommerce_Base_Buyer'"
```

Write this DeveloperName into `BUYER_PERMISSION_SET_GROUP` in `force-app/main/default/classes/UIBundleRegistration.cls`:

```apex
private static final String BUYER_PERMISSION_SET_GROUP = 'SDO_B2BCommerce_Base_Buyer';
```

If you don't replace this (or the named group doesn't exist), registration still succeeds, but the new buyer lacks full commerce entitlement: their cart may wedge in `Processing`, `compact-summary` can 500, and **order placement fails with `INSUFFICIENT_ACCESS`** ("We cannot complete this request due to an administration issue").

If zero rows, fail with the exact DeveloperName `SDO_B2BCommerce_Base_Buyer` and stop. Do not ask the user to choose.

### 4. Vite plugin org alias (optional)

The `@salesforce/vite-plugin-ui-bundle` reads the org's API version at build time to keep the SDK's CSRF endpoint in sync. By default it uses the `sf` default-org.

If more than one org is configured, set an explicit alias in `force-app/main/default/uiBundles/commerceb2bheadless/vite.config.ts`:

```ts
salesforce({ orgAlias: 'my-demo-org' }),
```

If a single default org is set, skip this step.

If you skip this and the plugin can't resolve an org, it falls back to `65.0`, which mismatches a 264 org and causes CSRF calls to hit `v65.0/ui-api/session/csrf`. Symptom: every authenticated request 401s.

### 5. Install dependencies

From the repo root:

```bash
npm install
cd force-app/main/default/uiBundles/commerceb2bheadless && npm install && cd -
```

### 6. Build the React app

Root `package.json` has no `build` script. Run build from the UI bundle so `dist/` is produced for deploy:

```bash
cd force-app/main/default/uiBundles/commerceb2bheadless && npm run build && cd -
```

### 7. Deploy the storefront

Deploys Apex auth + UIBundle + Site + Network + profile:

```bash
sf project deploy start --source-dir force-app --target-org <alias>
```

Always pass `--source-dir force-app`. A bare `sf project deploy start` would also deploy workshop/inventory.

For UI-bundle-only, Apex-only, or Experience-site-only deploys, see [deploy-commands.md](references/deploy-commands.md).

## After deploy

`UIBundleApexAccess` is **not** in `force-app`. Do not assign it.

Create the B2B Buyer in Setup or via Experience Cloud self-registration.

### Storefront URL

This deploy creates a **new** Experience Cloud Network/Site for the React UI Bundle. It is **not** the existing SDO LWR Commerce store. The public site prefix is `commerceb2bheadless` (do not rename).

Resolve the live URL from the org (do not invent a domain):

```bash
sf data query --target-org <alias> --query "SELECT Domain.Domain, PathPrefix FROM DomainSite WHERE PathPrefix = '/commerceb2bheadless'"
```

Build HTTPS URLs as `https://<Domain.Domain><PathPrefix>/` (PathPrefix already includes the leading slash). Tell the user:

- **Storefront:** `https://<Domain.Domain>/commerceb2bheadless/`
- **Login:** `https://<Domain.Domain>/commerceb2bheadless/login`

If that query returns zero rows, fall back to `sf org display --json`: take `instanceUrl`, replace `.my.salesforce.com` with `.my.site.com` (keep `.sandbox` if present), then append `/commerceb2bheadless/`. State that this is a constructed fallback, not a DomainSite result.

Always print both URLs after a successful deploy. This is a separate site from the SDO store (`SDO - B2B Commerce Enhanced` is the WebStore the app calls, not the URL path).

Stop here. Do not continue into Workshop: PDP availability.

## Do not change

- **API version** — `COMMERCE.API_VERSION` defaults to `v67.0` (works against `262.6+`).
- **Site URL prefix** (`commerceb2bheadlessvforcesite`) in `force-app/main/default/sites/commerceb2bheadless.site-meta.xml`.
- **Apex class names** — referenced by the React app; renaming requires updating both.
