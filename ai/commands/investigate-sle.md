Investigate Shop or Shop Legal Entity: $ARGUMENTS

# Your Task: Shop / Shop Legal Entity Investigation

**Your Goal:** Given either a Shop Legal Entity ID or a Shop ID, retrieve comprehensive information about the shop, its legal entity linkages, all SLEs for the shop, and associated financial products.

**Important:** Use the `data-portal-mcp` tools to query BigQuery tables.

---

## Input Format

This command accepts two input formats:

- `--sle-id <id>` - Investigate a specific Shop Legal Entity
- `--shop-id <id>` - Investigate a Shop and all its SLEs

Examples:

```
/investigate-sle --sle-id 123456
/investigate-sle --shop-id 789012
```

---

## Performance Optimization

**IMPORTANT:** Run independent queries IN PARALLEL by making multiple `query_bigquery` tool calls in a SINGLE message.

Instead of:

```
Message 1: Run query A → wait for result
Message 2: Run query B → wait for result
Message 3: Run query C → wait for result
```

Do this:

```
Message 1: Run query A, query B, query C (all execute in parallel)
```

See the parallelization strategy in each branch below for which queries can run together.

---

## Important: Partition Filters Required

Many tables are partitioned and REQUIRE a partition filter in the WHERE clause:

| Table                                              | Partition Column                  | Filter to Add                                                    |
| -------------------------------------------------- | --------------------------------- | ---------------------------------------------------------------- |
| `shopify.shop_legal_entities`                      | `created_at`                      | `AND created_at >= '2015-01-01'`                                 |
| `shopify.shops`                                    | `created_at`                      | `AND created_at >= '2015-01-01'`                                 |
| `banking_balance_businesses`                       | `balance_cohort`                  | `AND balance_cohort >= '2015-01-01'`                             |
| `profile_assessment_verification_requests_summary` | `verification_request_created_at` | `AND verification_request_created_at >= '2015-01-01'`            |
| `payment_gateway_daily_snapshot`                   | `snapshot_date`                   | `AND snapshot_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)` |
| `capital_financings`                               | `bank_transfer_date`              | `AND bank_transfer_date >= '2015-01-01'`                         |
| `business_platform.property_transfer_requests`     | `created_at`                      | `AND created_at >= '2015-01-01'`                                 |
| `business_platform.store_addition_requests`        | `created_at`                      | `AND created_at >= '2015-01-01'`                                 |

---

## Provider ID Reference

Common payment provider IDs:

- **87** = Shopify Payments
- **1057629** = PayPal
- **46, 75** = PayPal (legacy)

---

## Investigation Workflow

### Step 0: Parse Input and Determine Investigation Type

1. Parse `$ARGUMENTS` to extract the flag and ID:
   - If `--sle-id <number>` is present → **SLE Investigation Mode**
   - If `--shop-id <number>` is present → **Shop Investigation Mode**
   - If just a number with no flag → Use AskUserQuestion to clarify:

```
Use AskUserQuestion with:
- Question: "Is this ID a Shop Legal Entity ID or a Shop ID?"
- Options:
  - "Shop Legal Entity ID" (investigate specific SLE)
  - "Shop ID" (investigate shop and all its SLEs)
```

2. Once you know the investigation type, follow the appropriate branch below.

---

## Branch A: SLE Investigation Mode (--sle-id)

Use this flow when investigating a specific Shop Legal Entity.

### Parallelization Strategy (Branch A)

1. **First:** Run Step A1 alone to get SLE details and extract `SHOP_ID`
2. **Then:** Run Steps A2, A3, A4, A5a, A5b, A5c, A5d, A5e, A5f **ALL IN PARALLEL** (9 queries in one message)

### Step A1: Get Shop Legal Entity Basic Info

```sql
SELECT
  sle.id AS shop_legal_entity_id,
  sle.shop_id,
  sle.legal_entity_id,
  sle.`primary` AS is_primary,
  sle.archived,
  sle.archived_at,
  sle.longboat_is_deleted,
  sle.created_at,
  sle.updated_at
FROM `sdp-prd-interim-data-loaders.shopify.shop_legal_entities` AS sle
WHERE sle.id = {SLE_ID}
  AND sle.created_at >= '2015-01-01'
```

**STOP** if the SLE doesn't exist or is not found.

### Step A2: Get Shop Information

Using the `shop_id` from Step A1:

```sql
SELECT
  s.id AS shop_id,
  s.name AS shop_name,
  s.domain,
  s.permanent_domain,
  s.country,
  s.province,
  s.city,
  s.primary_shop_legal_entity_id,
  s.organization_id,
  s.created_at AS shop_created_at,
  s.company_name,
  sbi.subscription_plan_name,
  sbi.subscription_type,
  sbi.is_active,
  sbi.active_category,
  sbi.is_plus,
  sbi.is_frozen,
  sbi.is_fraudulent,
  sbi.billing_business_company_name,
  sbi.billing_business_city,
  sbi.billing_business_country_code
FROM `sdp-prd-interim-data-loaders.shopify.shops` AS s
LEFT JOIN `shopify-dw.accounts_and_administration.shop_billing_info_current` AS sbi
  ON s.id = sbi.shop_id
WHERE s.id = {SHOP_ID}
  AND s.created_at >= '2015-01-01'
```

### Step A3: Get All SLEs for the Shop

```sql
SELECT
  sle.id AS shop_legal_entity_id,
  sle.shop_id,
  sle.legal_entity_id,
  sle.`primary` AS is_primary,
  sle.archived,
  sle.archived_at,
  sle.longboat_is_deleted,
  sle.created_at,
  sle.updated_at,
  cgle.id AS core_legal_entity_id,
  cgle.external_id AS business_platform_legal_entity_id,
  cgle.legal_name AS core_legal_entity_name,
  cgle.legal_entity_type,
  cgle.country_code,
  cgle.organization_id AS core_organization_id,
  cgle.is_not_deleted AS core_le_is_not_deleted,
  cgle.external_id AS bp_legal_entity_id
FROM `sdp-prd-interim-data-loaders.shopify.shop_legal_entities` AS sle
LEFT JOIN `sdp-prd-interim-data-loaders.core_general2.legal_entities` AS cgle
  ON sle.legal_entity_id = cgle.id
WHERE sle.shop_id = {SHOP_ID}
  AND sle.created_at >= '2015-01-01'
ORDER BY sle.`primary` DESC, sle.created_at ASC
```

### Step A4: Get Business Platform Shop Info (for issue detection)

```sql
SELECT
  bps.id AS bp_shop_id,
  bps.shopify_shop_id,
  bps.organization_id AS bp_organization_id,
  bps.is_not_deleted AS bp_shop_is_not_deleted,
  bps.created_at AS bp_shop_created_at
FROM `sdp-prd-interim-data-loaders.business_platform.shops` AS bps
WHERE bps.shopify_shop_id = {SHOP_ID}
  AND bps.created_at >= '2015-01-01'
```

### Step A5: Get Financial Products for Target SLE

#### 5a. Payment Gateways (uses SLE_ID)

```sql
SELECT
  pg.shop_id,
  pg.shop_legal_entity_id,
  pg.payment_gateway_id,
  pg.provider_id,
  pg.is_enabled,
  pg.is_sandbox,
  pg.snapshot_date,
  CASE
    WHEN pg.provider_id = 87 THEN 'Shopify Payments'
    WHEN pg.provider_id IN (46, 75, 1057629) THEN 'PayPal'
    ELSE CAST(pg.provider_id AS STRING)
  END AS gateway_type
FROM `shopify-dw.money_products.payment_gateway_daily_snapshot` AS pg
WHERE pg.shop_legal_entity_id = {SLE_ID}
  AND pg.snapshot_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
ORDER BY pg.is_enabled DESC, pg.provider_id
```

#### 5b. Balance Status (uses SLE_ID)

```sql
SELECT
  bb.banking_business_id,
  bb.shop_legal_entity_id,
  bb.shop_id,
  bb.onboarding_status,
  bb.has_active_bank_account,
  bb.initialized_at,
  bb.onboarded_at,
  bb.balance_cohort,
  bb.bank,
  bb.ending_balance_usd,
  bb.is_banking_active_user,
  bb.subscription_plan_name
FROM `shopify-dw.money_products.banking_balance_businesses` AS bb
WHERE bb.shop_legal_entity_id = {SLE_ID}
  AND bb.balance_cohort >= '2015-01-01'
```

#### 5c. KYC/Verification Status (uses SLE_ID)

```sql
SELECT
  pav.shop_legal_entity_id,
  pav.inquirer,
  pav.status AS verification_status,
  pav.policy_name,
  pav.policy_variant_country_code,
  pav.policy_variant_assessor,
  pav.legal_entity_legal_name,
  pav.legal_entity_type,
  pav.verification_request_created_at,
  pav.verification_request_updated_at,
  pav.verification_request_first_success_at
FROM `shopify-dw.money_products.profile_assessment_verification_requests_summary` AS pav
WHERE pav.shop_legal_entity_id = {SLE_ID}
  AND pav.verification_request_created_at >= '2015-01-01'
ORDER BY pav.verification_request_updated_at DESC
```

#### 5d. Capital/Lending (uses SHOP_ID)

Note: Capital uses `capital_financings` table, linked via `shop_id`.

```sql
SELECT
  cf.financing_id,
  cf.shop_id,
  cf.financing_type,
  cf.current_status,
  cf.amount_local,
  cf.amount_usd,
  cf.currency_code,
  cf.bank_transfer_date,
  cf.created_at
FROM `shopify-dw.money_products.capital_financings` AS cf
WHERE cf.shop_id = {SHOP_ID}
  AND cf.bank_transfer_date >= '2015-01-01'
ORDER BY cf.created_at DESC
LIMIT 10
```

#### 5e. Property Transfer Requests (uses SHOP_ID)

Note: Detects if the shop was transferred between organizations.

```sql
SELECT
  ptr.id AS transfer_request_id,
  ptr.property_id AS bp_shop_id,
  ptr.original_organization_id,
  ptr.target_organization_id,
  ptr.status,
  ptr.transfer_type,
  ptr.created_at,
  ptr.updated_at,
  ptr.is_not_deleted
FROM `sdp-prd-interim-data-loaders.business_platform.property_transfer_requests` AS ptr
INNER JOIN `sdp-prd-interim-data-loaders.business_platform.shops` AS bps
  ON ptr.property_id = bps.id
WHERE bps.shopify_shop_id = {SHOP_ID}
  AND ptr.created_at >= '2015-01-01'
  AND bps.created_at >= '2015-01-01'
ORDER BY ptr.created_at DESC
LIMIT 10
```

#### 5f. Store Addition Requests (uses SHOP_ID)

Note: Shows when the store was added to an organization.

```sql
SELECT
  sar.id AS store_addition_request_id,
  sar.shopify_shop_id,
  sar.shop_id,
  sar.business_id AS organization_id,
  sar.legal_entity_id,
  sar.processing_state,
  sar.store_name,
  sar.store_domain,
  sar.created_at,
  sar.updated_at,
  sar.is_not_deleted
FROM `sdp-prd-interim-data-loaders.business_platform.store_addition_requests` AS sar
WHERE sar.shopify_shop_id = {SHOP_ID}
  AND sar.created_at >= '2015-01-01'
ORDER BY sar.created_at DESC
LIMIT 10
```

### Step A6: Format Results (SLE Mode)

**IMPORTANT: Put Status Summary at the TOP, then Issues Detected, then details.**

```markdown
# Shop Legal Entity Investigation Results

## Target SLE: {SLE_ID}

### Status Summary (Quick View)

| Category           | Status                                                 |
| ------------------ | ------------------------------------------------------ |
| SLE Status         | Active / Archived / Deleted                            |
| Is Current Primary | Yes / No (Current primary is SLE #{PRIMARY_ID})        |
| Shop Active Status | Active / Inactive (plan, subscription type)            |
| Shopify Payments   | Enabled / Disabled / Not Found                         |
| KYC Verification   | Passed / Pending / Failed (assessor)                   |
| Balance Account    | Onboarded / None                                       |
| Capital/Lending    | Active / None                                          |
| Org Transfers      | X found (last: DATE, status: COMPLETED/PENDING) / None |
| Store Additions    | X found (last: DATE, state: completed/pending) / None  |

---

### Issues Detected

Check for these data integrity issues and display any that are found:

| Code | Issue                                             | How to Detect                                     |
| ---- | ------------------------------------------------- | ------------------------------------------------- |
| E    | Shop does not exist in Business Platform          | BP shop query returns 0 rows                      |
| F    | Shop does not belong to an organization in BP     | `bp_organization_id` is NULL                      |
| G    | Shop does not belong to an organization in Core   | `shop.organization_id` is NULL                    |
| H    | Organization ID mismatch between Core and BP      | `shop.organization_id != bp_organization_id`      |
| K    | Shop does not have a shop legal entity            | `primary_shop_legal_entity_id` is NULL            |
| L    | Shop legal entity is not mapped to a legal entity | `sle.legal_entity_id` is NULL                     |
| M    | Core legal entity not mapped to BP legal entity   | `core_legal_entity.external_id` is NULL           |
| N    | Core legal entity has been deleted                | `core_legal_entity.is_not_deleted` is NULL/FALSE  |
| O    | Shop points to legal entity in different org      | `shop.organization_id != core_le.organization_id` |
| P    | Shop and legal entity country codes don't match   | `shop.country != core_le.country_code`            |

**Display format:**

- If NO issues found: ✅ No data integrity issues detected
- If issues found, list each with severity indicator:
```

⚠️ Issues Detected:
• [H] Organization ID mismatch: Core=123 vs BP=456
• [P] Country mismatch: Shop=US vs Legal Entity=CA

```

---

### Organization Movement History

#### Property Transfers
| Transfer ID | From Org | To Org | Status | Type | Date |
|-------------|----------|--------|--------|------|------|
| ... | ... | ... | ... | ... | ... |

(Display "No property transfers found" if empty)

#### Store Addition Requests
| Request ID | Org ID | Legal Entity ID | State | Created |
|------------|--------|-----------------|-------|---------|
| ... | ... | ... | ... | ... |

(Display "No store addition requests found" if empty)

---

### Basic SLE Information
| Field | Value |
|-------|-------|
| SLE ID | ... |
| Shop ID | ... |
| Legal Entity ID | ... |
| Is Primary | Yes/No |
| Archived | Yes/No |
| Soft Deleted | Yes/No |
| Created At | ... |

### Shop Information
| Field | Value |
|-------|-------|
| Shop Name | ... |
| Domain | ... |
| Permanent Domain | ... |
| Plan | ... |
| Subscription Type | ... |
| Is Active | Yes/No |
| Country | ... |
| Primary SLE ID | ... |
| Organization ID | ... |
| Billing Company | ... |

### Legal Entity Hierarchy (Target SLE)
| Level | ID | Name/Type |
|-------|-----|-----------|
| Shop Legal Entity | ... | N/A |
| Core Legal Entity | ... | (legal_name, type) |
| BP Legal Entity ID | ... | ... |
| Organization ID | ... | ... |

### All SLEs for Shop {SHOP_ID}
| SLE ID | Primary | Archived | Deleted | Core LE ID | BP LE ID | Country | Created |
|--------|---------|----------|---------|------------|----------|---------|---------|
| ... | Yes/No | Yes/No | Yes/No | ... | ... | ... | ... |

### Financial Products Status (Target SLE)

#### Payment Gateways
| Provider ID | Type | Enabled | Sandbox | Snapshot Date |
|-------------|------|---------|---------|---------------|
| ... | ... | Yes/No | Yes/No | ... |

#### Balance
| Status | Has Active Account | Bank | Balance USD | Initialized |
|--------|-------------------|------|-------------|-------------|
| ... | Yes/No | ... | ... | ... |

#### KYC/Verification
| Inquirer | Status | Assessor | Legal Name | Last Updated |
|----------|--------|----------|------------|--------------|
| ... | ... | ... | ... | ... |

#### Capital/Lending (Shop-wide)
| Financing Type | Status | Amount USD | Currency | Transfer Date |
|----------------|--------|------------|----------|---------------|
| ... | ... | ... | ... | ... |
```

---

## Branch B: Shop Investigation Mode (--shop-id)

Use this flow when investigating a Shop and all its SLEs.

### Parallelization Strategy (Branch B)

Run **ALL** queries (B1, B2, B3, B4a, B4b, B4c, B4d, B4e, B4f) **IN PARALLEL** in a single message (9 queries at once).
You already have `SHOP_ID` from the input, so no sequential dependency exists.

### Step B1: Get Shop Information

```sql
SELECT
  s.id AS shop_id,
  s.name AS shop_name,
  s.domain,
  s.permanent_domain,
  s.country,
  s.province,
  s.city,
  s.primary_shop_legal_entity_id,
  s.organization_id,
  s.created_at AS shop_created_at,
  s.company_name,
  sbi.subscription_plan_name,
  sbi.subscription_type,
  sbi.is_active,
  sbi.active_category,
  sbi.is_plus,
  sbi.is_frozen,
  sbi.is_fraudulent,
  sbi.billing_business_company_name,
  sbi.billing_business_city,
  sbi.billing_business_country_code
FROM `sdp-prd-interim-data-loaders.shopify.shops` AS s
LEFT JOIN `shopify-dw.accounts_and_administration.shop_billing_info_current` AS sbi
  ON s.id = sbi.shop_id
WHERE s.id = {SHOP_ID}
  AND s.created_at >= '2015-01-01'
```

**STOP** if the shop doesn't exist or is not found.

### Step B2: Get All SLEs for the Shop

```sql
SELECT
  sle.id AS shop_legal_entity_id,
  sle.shop_id,
  sle.legal_entity_id,
  sle.`primary` AS is_primary,
  sle.archived,
  sle.archived_at,
  sle.longboat_is_deleted,
  sle.created_at,
  sle.updated_at,
  cgle.id AS core_legal_entity_id,
  cgle.external_id AS business_platform_legal_entity_id,
  cgle.legal_name AS core_legal_entity_name,
  cgle.legal_entity_type,
  cgle.country_code,
  cgle.organization_id AS core_organization_id,
  cgle.is_not_deleted AS core_le_is_not_deleted,
  cgle.external_id AS bp_legal_entity_id
FROM `sdp-prd-interim-data-loaders.shopify.shop_legal_entities` AS sle
LEFT JOIN `sdp-prd-interim-data-loaders.core_general2.legal_entities` AS cgle
  ON sle.legal_entity_id = cgle.id
WHERE sle.shop_id = {SHOP_ID}
  AND sle.created_at >= '2015-01-01'
ORDER BY sle.`primary` DESC, sle.created_at ASC
```

### Step B3: Get Business Platform Shop Info (for issue detection)

```sql
SELECT
  bps.id AS bp_shop_id,
  bps.shopify_shop_id,
  bps.organization_id AS bp_organization_id,
  bps.is_not_deleted AS bp_shop_is_not_deleted,
  bps.created_at AS bp_shop_created_at
FROM `sdp-prd-interim-data-loaders.business_platform.shops` AS bps
WHERE bps.shopify_shop_id = {SHOP_ID}
  AND bps.created_at >= '2015-01-01'
```

### Step B4: Get Financial Products for ALL SLEs

#### 4a. Payment Gateways (All SLEs)

```sql
SELECT
  pg.shop_id,
  pg.shop_legal_entity_id,
  pg.payment_gateway_id,
  pg.provider_id,
  pg.is_enabled,
  pg.is_sandbox,
  pg.snapshot_date,
  CASE
    WHEN pg.provider_id = 87 THEN 'Shopify Payments'
    WHEN pg.provider_id IN (46, 75, 1057629) THEN 'PayPal'
    ELSE CAST(pg.provider_id AS STRING)
  END AS gateway_type
FROM `shopify-dw.money_products.payment_gateway_daily_snapshot` AS pg
WHERE pg.shop_id = {SHOP_ID}
  AND pg.snapshot_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
ORDER BY pg.shop_legal_entity_id, pg.is_enabled DESC, pg.provider_id
```

#### 4b. Balance Status (All SLEs)

```sql
SELECT
  bb.banking_business_id,
  bb.shop_legal_entity_id,
  bb.shop_id,
  bb.onboarding_status,
  bb.has_active_bank_account,
  bb.initialized_at,
  bb.onboarded_at,
  bb.balance_cohort,
  bb.bank,
  bb.ending_balance_usd,
  bb.is_banking_active_user,
  bb.subscription_plan_name
FROM `shopify-dw.money_products.banking_balance_businesses` AS bb
WHERE bb.shop_id = {SHOP_ID}
  AND bb.balance_cohort >= '2015-01-01'
```

#### 4c. KYC/Verification Status (All SLEs)

```sql
SELECT
  pav.shop_legal_entity_id,
  pav.inquirer,
  pav.status AS verification_status,
  pav.policy_name,
  pav.policy_variant_country_code,
  pav.policy_variant_assessor,
  pav.legal_entity_legal_name,
  pav.legal_entity_type,
  pav.verification_request_created_at,
  pav.verification_request_updated_at,
  pav.verification_request_first_success_at
FROM `shopify-dw.money_products.profile_assessment_verification_requests_summary` AS pav
WHERE pav.shop_id = {SHOP_ID}
  AND pav.verification_request_created_at >= '2015-01-01'
ORDER BY pav.shop_legal_entity_id, pav.verification_request_updated_at DESC
```

#### 4d. Capital/Lending

```sql
SELECT
  cf.financing_id,
  cf.shop_id,
  cf.financing_type,
  cf.current_status,
  cf.amount_local,
  cf.amount_usd,
  cf.currency_code,
  cf.bank_transfer_date,
  cf.created_at
FROM `shopify-dw.money_products.capital_financings` AS cf
WHERE cf.shop_id = {SHOP_ID}
  AND cf.bank_transfer_date >= '2015-01-01'
ORDER BY cf.created_at DESC
LIMIT 10
```

#### 4e. Property Transfer Requests

Note: Detects if the shop was transferred between organizations.

```sql
SELECT
  ptr.id AS transfer_request_id,
  ptr.property_id AS bp_shop_id,
  ptr.original_organization_id,
  ptr.target_organization_id,
  ptr.status,
  ptr.transfer_type,
  ptr.created_at,
  ptr.updated_at,
  ptr.is_not_deleted
FROM `sdp-prd-interim-data-loaders.business_platform.property_transfer_requests` AS ptr
INNER JOIN `sdp-prd-interim-data-loaders.business_platform.shops` AS bps
  ON ptr.property_id = bps.id
WHERE bps.shopify_shop_id = {SHOP_ID}
  AND ptr.created_at >= '2015-01-01'
  AND bps.created_at >= '2015-01-01'
ORDER BY ptr.created_at DESC
LIMIT 10
```

#### 4f. Store Addition Requests

Note: Shows when the store was added to an organization.

```sql
SELECT
  sar.id AS store_addition_request_id,
  sar.shopify_shop_id,
  sar.shop_id,
  sar.business_id AS organization_id,
  sar.legal_entity_id,
  sar.processing_state,
  sar.store_name,
  sar.store_domain,
  sar.created_at,
  sar.updated_at,
  sar.is_not_deleted
FROM `sdp-prd-interim-data-loaders.business_platform.store_addition_requests` AS sar
WHERE sar.shopify_shop_id = {SHOP_ID}
  AND sar.created_at >= '2015-01-01'
ORDER BY sar.created_at DESC
LIMIT 10
```

### Step B5: Format Results (Shop Mode)

**IMPORTANT: Put Status Summary at the TOP, then Issues Detected, then details.**

```markdown
# Shop Investigation Results

## Shop: {SHOP_ID}

### Status Summary (Quick View)

| Category         | Status                                                 |
| ---------------- | ------------------------------------------------------ |
| Shop Status      | Active / Inactive (plan, category)                     |
| Is Plus          | Yes / No                                               |
| Is Frozen        | Yes / No                                               |
| Primary SLE      | #{PRIMARY_SLE_ID}                                      |
| Total SLEs       | X (Y active, Z archived)                               |
| Shopify Payments | Enabled on SLE #{X} / Disabled / Not Found             |
| Balance Accounts | X active                                               |
| Capital/Lending  | X active financings                                    |
| Org Transfers    | X found (last: DATE, status: COMPLETED/PENDING) / None |
| Store Additions  | X found (last: DATE, state: completed/pending) / None  |

---

### Issues Detected

Check for these data integrity issues and display any that are found:

| Code | Issue                                             | How to Detect                                     |
| ---- | ------------------------------------------------- | ------------------------------------------------- |
| E    | Shop does not exist in Business Platform          | BP shop query returns 0 rows                      |
| F    | Shop does not belong to an organization in BP     | `bp_organization_id` is NULL                      |
| G    | Shop does not belong to an organization in Core   | `shop.organization_id` is NULL                    |
| H    | Organization ID mismatch between Core and BP      | `shop.organization_id != bp_organization_id`      |
| K    | Shop does not have a shop legal entity            | `primary_shop_legal_entity_id` is NULL            |
| L    | Shop legal entity is not mapped to a legal entity | `sle.legal_entity_id` is NULL                     |
| M    | Core legal entity not mapped to BP legal entity   | `core_legal_entity.external_id` is NULL           |
| N    | Core legal entity has been deleted                | `core_legal_entity.is_not_deleted` is NULL/FALSE  |
| O    | Shop points to legal entity in different org      | `shop.organization_id != core_le.organization_id` |
| P    | Shop and legal entity country codes don't match   | `shop.country != core_le.country_code`            |

**Display format:**

- If NO issues found: ✅ No data integrity issues detected
- If issues found, list each with severity indicator:
```

⚠️ Issues Detected:
• [H] Organization ID mismatch: Core=123 vs BP=456
• [P] Country mismatch: Shop=US vs Legal Entity=CA

```

---

### Organization Movement History

#### Property Transfers
| Transfer ID | From Org | To Org | Status | Type | Date |
|-------------|----------|--------|--------|------|------|
| ... | ... | ... | ... | ... | ... |

(Display "No property transfers found" if empty)

#### Store Addition Requests
| Request ID | Org ID | Legal Entity ID | State | Created |
|------------|--------|-----------------|-------|---------|
| ... | ... | ... | ... | ... |

(Display "No store addition requests found" if empty)

---

### Shop Information
| Field | Value |
|-------|-------|
| Shop ID | ... |
| Shop Name | ... |
| Domain | ... |
| Permanent Domain | ... |
| Plan | ... |
| Subscription Type | ... |
| Is Active | Yes/No |
| Active Category | ... |
| Country | ... |
| Province | ... |
| Primary SLE ID | ... |
| Organization ID | ... |
| Created At | ... |
| Billing Company | ... |

### All Shop Legal Entities
| SLE ID | Primary | Archived | Deleted | Core LE ID | Legal Name | Type | Country | Created |
|--------|---------|----------|---------|------------|------------|------|---------|---------|
| ... | Yes/No | Yes/No | Yes/No | ... | ... | ... | ... | ... |

### Financial Products by SLE

#### Payment Gateways
| SLE ID | Provider ID | Type | Enabled | Sandbox |
|--------|-------------|------|---------|---------|
| ... | ... | ... | Yes/No | Yes/No |

#### Balance Accounts
| SLE ID | Status | Has Active Account | Bank | Balance USD |
|--------|--------|-------------------|------|-------------|
| ... | ... | Yes/No | ... | ... |

#### KYC/Verification
| SLE ID | Inquirer | Status | Assessor | Legal Name | Last Updated |
|--------|----------|--------|----------|------------|--------------|
| ... | ... | ... | ... | ... | ... |

#### Capital/Lending (Shop-wide)
| Financing Type | Status | Amount USD | Currency | Transfer Date |
|----------------|--------|------------|----------|---------------|
| ... | ... | ... | ... | ... |
```

---

## Key Indicators to Watch For

1. **Archived SLE with Active Products:** If an SLE is archived but has active payment gateways or Balance accounts, flag this as a potential issue.

2. **Non-Primary SLE with Shopify Payments:** Shopify Payments supports multi-entity, so a non-primary SLE can have SP. However, third-party gateways should follow the primary.

3. **Soft Delete Indicators:** Check `longboat_is_deleted`, `archived` flags across tables.

4. **Legal Entity Chain Breaks:** If core_legal_entity_id or business_platform_legal_entity_id is NULL, the linkage chain is incomplete.

5. **Multiple Primary SLEs:** There should only be one primary SLE per shop. Flag if multiple exist.

6. **Orphaned Products:** Financial products pointing to SLEs that don't exist in the shop_legal_entities table.

7. **Frozen/Fraudulent Shop:** Check `is_frozen` and `is_fraudulent` flags from billing info.
