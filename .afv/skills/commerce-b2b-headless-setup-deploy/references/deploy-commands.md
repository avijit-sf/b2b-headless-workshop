# Deploy a subset

Use these when the user does not want a full `force-app` deploy. Always pass `--target-org <alias>`. Never use a bare `sf project deploy start`.

Do **not** deploy `workshop/inventory`.

```bash
# UI bundle only (after a code change)
sf project deploy start --source-dir force-app/main/default/uiBundles --target-org <alias>

# Apex auth classes only (not inventory)
sf project deploy start --source-dir force-app/main/default/classes --target-org <alias>

# Experience site only
sf project deploy start \
  --source-dir force-app/main/default/digitalExperienceConfigs \
  --source-dir force-app/main/default/digitalExperiences \
  --source-dir force-app/main/default/networks \
  --source-dir force-app/main/default/sites \
  --target-org <alias>
```

Full storefront deploy (Apex auth + UIBundle + Site + Network + profile):

```bash
sf project deploy start --source-dir force-app --target-org <alias>
```
