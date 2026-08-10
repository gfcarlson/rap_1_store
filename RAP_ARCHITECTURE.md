# RAP Purchase Document Application — Complete Architecture Documentation

## Table of Contents
1. [High-Level Overview](#high-level-overview)
2. [Purchase Document Approval Workflow](#purchase-document-approval-workflow)
3. [CDS Data Model & Associations](#cds-data-model--associations)
4. [Fiori UI Annotations](#fiori-ui-annotations)
5. [Technical Deep-Dive for Developers](#technical-deep-dive-for-developers)

---

# High-Level Overview

This repository implements a **RAP (ABAP RESTful Application Programming Model) application** for managing purchase documents and their line items in SAP. It builds a REST API and UI for purchase order workflows with approval/rejection actions, draft persistence, and calculated fields like overall pricing.

## Stack
- **Language(s):** ABAP (55.1%), ABAP CDS (43.9%)
- **Framework / runtime:** SAP BTP/S/4HANA with RAP (Fiori/OData stack)
- **Notable libraries/patterns:** CDS (Core Data Services), draft persistence, behavior definitions (BDEF), OData services via service bindings

## How it's organized

```
src/
  ztg_*.tabl.xml              Database tables (purchase doc, items, status, priority, org)
  zig_*.ddls.asddls           CDS views (Basic: PurchaseDocument, Item, related lookups)
  zcg_*.ddls.asddls           CDS views (Consumption: filtered/formatted for UI)
  zig_pdoc_rv_comp.bdef       Behavior definition for entity composition
  zcg_pdoc_rv.bdef.asbdef     Projection behavior (draft, create/update/delete, actions)
  zbig_pdoc_rv_comp.clas.*    Behavior handler (approve_order, reject_order logic)
  zmd_*.ddlx.asddlxs          UI metadata (annotations for Fiori UI)
  zsbg_*.srvb.xml             Service bindings (OData services)
  zsdg_pdoc_v_1.srvd.srvdsrv  Service definition
  zmsg_e_pdoc.msag.xml        Message class (error/success messages)
  zcg_create_test_data_v1      Test data generation utility
  .abapgit.xml                abapGit configuration
  CHANGELOG.md                Version history
```

## How it fits together

Requests flow through OData service bindings (srvb) → projection behavior (zcg) with draft actions → behavior handler (zbig) for state transitions. Raw data comes from database tables, transformed via CDS views (zig/zcg) with foreign key associations. UI layers consume metadata (ddlx) and invoke custom actions like `approve_order` to change purchase document status from initial → approved → closed, with validation and messaging throughout.

---

# Purchase Document Approval Workflow

## State Machine Overview

The workflow enforces a **three-state transition system** with explicit validation at each step:

```
┌─────────────┐
│   '1'       │
│  Created    │
└──────┬──────┘
       │ approve_order
       │ (msg 002 ✓)       ┌──────────────────────────┐
       └────────────────────→│        '2'               │
                            │      Approved           │
                            └─────────┬────────────────┘
                                      │
                                      │ reject_order
                                      │ (msg 003 ✓)
                                      ↓
                            ┌──────────────────────────┐
              reject_order   │        '3'               │
              (msg 003 ✓)    │       Closed            │
           ┌─────────────────→│                         │
           │                 └──────────────────────────┘
           │
      ┌────┴──────┐
      │   '1'      │
      │  Created   │
      └────────────┘
```

## Status Codes

| Code | Name | Description |
|------|------|-------------|
| `'1'` | Created | Initial state after document creation |
| `'2'` | Approved | Document approved via `approve_order` action |
| `'3'` | Closed | Document closed/rejected via `reject_order` action |

## Validation Logic (zbig_pdoc_rv_comp.clas.locals_imp.abap)

### `approve_order` Action

**Flow:**
1. **Initial validation** (lines 39–47): If `PurchaseDocument` is empty → error **ZMSG_E_PDOC:009** ("Initial")
2. **Already approved check** (lines 61–71): If status = `'2'` → error **013** ("already Approved")
3. **Already closed check** (lines 73–83): If status = `'3'` → error **014** ("already Closed")
4. **State transition** (lines 85–125): Set status = `'2'` and raise success **002** ("Approved")

**Allowed transitions:**
- `'1'` → `'2'` ✓
- `'2'` → `'2'` ✗ (Error 013)
- `'3'` → `'2'` ✗ (Error 014)

### `reject_order` Action

**Flow:**
1. **Initial validation** (lines 144–153): If `PurchaseDocument` is empty → error **009**
2. **Already closed check** (lines 163–173): If status = `'3'` → error **014** ("already Closed")
3. **State transition** (lines 175–216): Set status = `'3'` and raise success **003** ("Closed")

**Allowed transitions:**
- `'1'` → `'3'` ✓
- `'2'` → `'3'` ✓
- `'3'` → `'3'` ✗ (Error 014)

## Error Messages

| Code | Message | Context |
|------|---------|---------|
| 009 | Purchase Document is Initial | Key field empty |
| 013 | Document is already approved | Trying to approve approved doc |
| 014 | Document is already closed | Trying to transition closed doc |
| 002 | Document approved | Success (approve_order) |
| 003 | Document closed | Success (reject_order) |

---

# CDS Data Model & Associations

## Association Network

```
ZIG_PDoc_RV_COMP (Root Entity)
├─ 0..* composition → ZIG_PItem_COMP (Line Items)
├─ 0..1 → ZIG_PDoc_Status (Status Lookup)
├─ 0..1 → ZIG_Pdoc_Priority (Priority Lookup)
└─ 0..1 → ZIG_Purch_Org (Purchasing Org Lookup)

ZIG_PItem_COMP (Child Entity)
├─ 1..1 → ZIG_PDoc_RV_COMP (Parent PO)
├─ 0..1 → ZIG_Vendor_type (Vendor Classification)
├─ 0..1 → I_UnitOfMeasure (UOM)
└─ 0..1 → I_Currency (Currency Master)
```

## Purchase Document Root Entity

**CDS View:** `zig_pdoc_rv_comp.ddls.asddls`

| Field | Type | Purpose | Calculated |
|-------|------|---------|-----------|
| PurchaseDocument | UUID | Key, auto-generated | No |
| Description | CHAR 128 | PO description | No |
| Status | CHAR 1 | '1'=Created, '2'=Approved, '3'=Closed | No |
| Priority | CHAR 1 | '1'=High, '2'=Medium, '3'=Low | No |
| PurchasingOrganization | CHAR 4 | Organization code | No |
| IsApprovalRequired | CHAR 1 | 'X' if OverallPrice > €1000 | **Yes** |
| OverallPrice | DEC 13.2 | Sum of item prices | **Yes** |
| OverallPriceCriticality | INT 4 | 3=Green, 2=Yellow, 1=Red | **Yes** |
| Currency | CUKY | Currency code | No |
| PurchaseDocumentImageURL | CHAR 250 | Image URL | No |
| crea_date_time | TIMESTAMPL | Creation timestamp | No |
| crea_uname | SYUNAME | Created by user | No |
| lchg_date_time | TIMESTAMPL | Last changed timestamp | No |
| lchg_uname | SYUNAME | Last changed by user | No |

### Calculated Field Rules

**IsApprovalRequired:**
```abap
cast( case when OverallPrice > 1000 then 'X' else '' end as abap.char(1) )
```
Business rule: Documents over €1000 require approval.

**OverallPriceCriticality:**
```abap
cast( case when OverallPrice >= 0 and OverallPrice < 1000 then 3      -- GREEN
           when OverallPrice >= 1000 and OverallPrice <= 10000 then 2 -- YELLOW
           when OverallPrice > 10000 then 1                           -- RED
           else 0
      end as abap.int4 )
```
Used for UI color coding in lists and object pages.

## Purchase Document Item Entity

**CDS View:** `zig_pitem.ddls.asddls`

| Field | Type | Semantics |
|-------|------|-----------|
| PurchaseDocumentItem | UUID | Item key |
| PurchaseDocument | UUID | Parent PO (foreign key) |
| Description | CHAR 128 | Item text |
| Vendor | CHAR | Supplier name |
| VendorType | CHAR 1 | E/I/Q/P classification |
| Price | DEC 13.2 | @Semantics.amount.currencyCode |
| Quantity | NUMERIC | @Semantics.quantity.unitOfMeasure |
| Currency | CUKY | Currency key |
| QuantityUnit | UNIT | UOM |
| OverallItemPrice | DEC 13.2 | `quantity * price` (calculated) |
| PurchaseDocumentItemImageURL | CHAR 250 | Item image |

## Reference Lookup Entities

### ZIG_PDoc_Status
Maps status code to text:
- `'1'` → "Created"
- `'2'` → "Approved"
- `'3'` → "Closed"

### ZIG_Pdoc_Priority
Maps priority code to text:
- `'1'` → "High"
- `'2'` → "Medium"
- `'3'` → "Low"

### ZIG_Purch_Org
Purchasing organization master with contact details (email, phone, fax).

### ZIG_Vendor_type
Vendor classifications:
- E = External
- I = Internal
- Q = Quota
- P = Preferred

---

# Fiori UI Annotations

## Purchase Document UI (zmd_pdoc_rv.ddlx.asddlxs)

### Header Section
```
Title: PurchaseDocument ID
Description: Description field
TypeName: Purchase Document
Image: PurchaseDocumentImageURL
```

### Header Data Points

| Data Point | Field | Purpose |
|-----------|-------|---------|
| Status | Status | Shows status with text |
| Overall Price | OverallPrice | Shows total with criticality coloring |
| Is Approval Required | IsApprovalRequired | Flag for docs >€1000 |
| Priority | Priority | High/Medium/Low |

### Action Buttons

| Action | Position | Importance |
|--------|----------|-----------|
| Approve_Order | 10 | HIGH |
| Reject_Order | 20 | HIGH |

### List Columns (lineItem)

| Position | Field | Importance | Notes |
|----------|-------|-----------|-------|
| 10 | PurchaseDocumentImageURL | HIGH | Image preview |
| 30 | Description | HIGH | Title, searchable |
| 40 | Priority | HIGH | Dropdown, text only |
| 50 | OverallPrice | HIGH | Red/yellow/green per criticality |
| 60 | Status | MEDIUM | Dropdown, text only |
| 70 | PurchasingOrganization | MEDIUM | Contact field |
| 80 | IsApprovalRequired | HIGH | Flag with icon & criticality |

### Field Groups

**BasicDataFieldGroup:** `crea_date_time`, `lchg_date_time`, `lchg_uname`

**PurchasingDocumentFieldGroup:** `Description`, `Priority`, `PurchasingOrganization`

### Value Help (Dropdowns)
- Status → entity `Z_C_StatusVH`
- Priority → entity `Z_C_PriorityVH`
- PurchasingOrganization → entity `Z_I_PurchasingOrganization`

## Purchase Document Item UI (zmd_pitem.ddlx.asddlxs)

### Header Data Points
- Price (DATAPOINT)
- Quantity (DATAPOINT)
- OverallItemPrice (DATAPOINT)

### List Columns

| Position | Field | Importance |
|----------|-------|-----------|
| 20 | PurchaseDocumentItem | HIGH |
| 30 | Description | HIGH |
| 30 | Price | HIGH |
| 40 | Quantity | HIGH |
| 50 | OverallItemPrice | HIGH |
| 60 | Vendor | HIGH |
| 70 | VendorType | HIGH |

---

# Technical Deep-Dive for Developers

## Part I: Database Layer (Persistence)

### Active Tables

#### ZTG_PDOC (Purchase Document Master)
```
Table: ZTG_PDOC (TRANSP, client-dependent)
Key Fields:
  - MANDT (CLNT)                  [Client, system-managed]
  - PURCHASEDOCUMENT (ZKG_PDOC)   [UUID, numbering: managed]

Data Fields:
  - DESCRIPTION (CHAR 128)
  - STATUS (CHAR 1)               [Values: '1'=Created, '2'=Approved, '3'=Closed]
  - PRIORITY (CHAR 1)             [Values: '1'=High, '2'=Medium, '3'=Low]
  - PURCHASINGORGANIZATION (CHAR 4)
  - PURCHASEDOCUMENTIMAGEURL (CHAR 250)

Audit Fields:
  - CREA_DATE_TIME (TIMESTAMPL)
  - CREA_UNAME (SYUNAME)
  - LCHG_DATE_TIME (TIMESTAMPL)
  - LCHG_UNAME (SYUNAME)
```

#### ZTG_PITEM (Purchase Document Items)
```
Table: ZTG_PITEM
Composite Key:
  - MANDT (CLNT)
  - PURCHASEDOCUMENTITEM (UUID, numbering: managed)
  - PURCHASEDOCUMENT (UUID, foreign key to ZTG_PDOC)

Data Fields:
  - DESCRIPTION (CHAR 128)
  - VENDOR (CHAR)
  - VENDORTYPE (CHAR 1)           [E=External, I=Internal, Q=Quota, P=Preferred]
  - PRICE (DEC 13.2)
  - CURRENCY (CUKY)
  - QUANTITY (NUMERIC)
  - QUANTITYUNIT (UNIT)
  - PDOC_ITEM_IMAGE_URL (CHAR 250)

Calculated (CDS only):
  - OverallItemPrice = quantity * price [DEC 13.2]
```

#### ZTG_PDOC_STATUS (Status Master)
```
Table: ZTG_PDOC_STATUS
Key: MANDT, STATUS (CHAR 1)

Fields:
  - STATUSTEXT (CHAR 50)          [Created, Approved, Closed]
  - ISACTIVE (CHAR 1)             [Active flag, optional]
```

#### Reference Master Tables
- **ZTG_PRIORITY**: Priority codes (1=High, 2=Medium, 3=Low)
- **ZTG_PURCH_ORG**: Purchasing Organization master
- **ZTG_VENDOR_TYPE**: Vendor classifications

### Draft Tables

#### ZTG_PDOC_D (Draft Purchase Document)
```
Table: ZTG_PDOC_D (Draft of ZTG_PDOC)
Includes all fields from ZTG_PDOC plus:
  - Standard draft admin fields (@AbapCatalog.include 'SYCH_BDL_DRAFT_ADMIN_INC'):
    - DRAFT_ADMINISTRATIVE_DATA (DraftUUID, DraftCreatedBy, DraftLastModifiedBy, etc.)
    - DRAFT_DOCUMENT_ID (link to active version)
```

#### ZTG_PITEM_D (Draft Purchase Document Items)
```
Table: ZTG_PITEM_D (Draft of ZTG_PITEM)
Same structure as ZTG_PITEM + draft admin fields
```

**Draft Model Behavior:**
- User edits → saved to `ZTG_PDOC_D` / `ZTG_PITEM_D`
- Activate action → data copied to active tables, draft deleted
- Discard action → draft deleted, no change to active
- Resume action → re-open draft for editing

---

## Part II: CDS Data Layer (3-Layer Model)

### Layer 1: Basic (I-Views) — `ZIG_*`

#### ZIG_PDOC (Basic Purchase Document View)
```abap cds
@VDM.viewType: #BASIC
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view ZIG_PDoc
  as select from ztg_pdoc
  association [0..*] to ZIG_PItem        as _PurchaseDocumentItem
  association [0..1] to ZIG_Pdoc_Priority as _Priority
  association [0..1] to ZIG_PDoc_Status    as _Status
  association [0..1] to ZIG_Purch_Org     as _PurchasingOrganization
{
  key purchasedocument       as PurchaseDocument,
      description            as Description,
      status                 as Status,
      priority               as Priority,
      purchasingorganization as PurchasingOrganization,
      purchasedocumentimageurl as PurchaseDocumentImageURL,
      
      crea_date_time, crea_uname,
      lchg_date_time, lchg_uname,
      
      _PurchaseDocumentItem,
      _Priority,
      _Status,
      _PurchasingOrganization
}
```

**Key Points:**
- Passes through table fields with CDS naming (camelCase)
- Defines 1:N composition and 0..1 associations to reference views
- No authorization checks (simple read layer)

#### ZIG_Pdoc_Overall_Price (Composite Aggregation View)
```abap cds
@VDM.viewType: #COMPOSITE
@ObjectModel.semanticKey: ['PurchaseDocument']
define view ZIG_Pdoc_Overall_Price
  as select from ZIG_PDoc
  association [0..1] to I_Currency as _Currency
{
  key PurchaseDocument,
  
      @Semantics.amount.currencyCode: 'Currency'
      @DefaultAggregation: #NONE
      cast( sum( _PurchaseDocumentItem.OverallItemPrice ) as abap.dec(13,2) ) 
        as OverallPrice,
        
      @Semantics.currencyCode: true
      _PurchaseDocumentItem.Currency,
      
      PurchasingOrganization,
      Description,
      Status,
      Priority,
      PurchaseDocumentImageURL,
      crea_date_time, crea_uname, lchg_date_time, lchg_uname,
      
      _PurchaseDocumentItem, _Currency, _Priority, _Status, _PurchasingOrganization
}
group by
  PurchaseDocument,
  _PurchaseDocumentItem.Currency,
  PurchasingOrganization,
  Description,
  Status,
  Priority,
  PurchaseDocumentImageURL,
  crea_date_time, crea_uname, lchg_date_time, lchg_uname
```

**Purpose:**
- **Aggregates item prices** to PO level using `sum()`
- **GROUP BY mandatory** for all non-aggregated fields
- Feeds the composition root (ZIG_PDOC_RV_COMP)
- `@DefaultAggregation: #NONE` prevents re-aggregation in client-side queries

### Layer 2: Composition Root (Business Object) — `ZIG_*_RV_COMP`

#### ZIG_PDoc_RV_COMP (Composition Root Entity)
```abap cds
@VDM.viewType: #COMPOSITE
@Metadata.allowExtensions: true
define root view entity ZIG_PDoc_RV_COMP
  as select from ZIG_Pdoc_Overall_Price
  
  composition [0..*] of ZIG_PItem_COMP as _PurchaseDocumentItem
{
  key PurchaseDocument,
      Description,
      Status,
      Priority,
      
      cast( case when OverallPrice > 1000 then 'X' else '' end 
            as abap.char(1) ) as IsApprovalRequired,
      
      cast( case when OverallPrice >= 0 and OverallPrice < 1000 then 3
                 when OverallPrice >= 1000 and OverallPrice <= 10000 then 2
                 when OverallPrice > 10000 then 1
                 else 0
            end as abap.int4 ) as OverallPriceCriticality,
      
      OverallPrice,
      Currency,
      PurchasingOrganization,
      PurchaseDocumentImageURL,
      crea_date_time, crea_uname, lchg_date_time, lchg_uname,
      
      _PurchaseDocumentItem,
      _Priority, _Status, _PurchasingOrganization
}
```

**Key RAP Concepts:**
- **Root entity**: Can be created/updated/deleted independently
- **Composition**: `_PurchaseDocumentItem` is a 0..* composition child (cascade delete, draft sync)
- **Calculated fields**: `IsApprovalRequired` and `OverallPriceCriticality`
- **@Metadata.allowExtensions: true**: Permits projection layer to add UI annotations

### Layer 3: Consumption (Projection) — `ZCG_*`

#### ZCG_PDoc_RV (Consumption/Projection View)
```abap cds
@VDM.viewType: #CONSUMPTION
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZCG_PDoc_RV
  provider contract transactional_query
  as projection on ZIG_PDoc_RV_COMP
{
  key PurchaseDocument,
      OverallPrice,
      IsApprovalRequired,
      OverallPriceCriticality,
      
      @Consumption.valueHelpDefinition: [{entity:{name:'Z_C_StatusVH', element: 'Status'}}]
      Status,
      
      @Consumption.valueHelpDefinition: [{entity:{name:'Z_C_PriorityVH', element: 'Priority'}}]
      Priority,
      
      @Search.defaultSearchElement: true
      Description,
      
      @Consumption.valueHelpDefinition: [{entity:{name:'Z_I_PurchasingOrganization', element: 'PurchasingOrganization'}}]
      PurchasingOrganization,
      
      Currency,
      crea_date_time, crea_uname, lchg_date_time, lchg_uname,
      PurchaseDocumentImageURL,
      
      _PurchaseDocumentItem: redirected to composition child ZCG_PItem,
      
      _Priority, _Status, _PurchasingOrganization
}
```

**Projection Techniques:**
- `provider contract transactional_query`: Declares read/write capability
- `redirected to composition child ZCG_PItem`: Routes child requests to projection
- `@Consumption.valueHelpDefinition`: Binds dropdown value helps
- `@Search.searchable: true`: Enables full-text search

---

## Part III: Behavior Layer (Business Logic)

### Composition Root Behavior Definition — `zig_pdoc_rv_comp.bdef`

```abap
managed implementation in class zbig_pdoc_rv_comp unique;
strict(2);
with draft;

define behavior for ZIG_PDoc_RV_COMP alias PurchaseDocument
persistent table ztg_pdoc
draft table ztg_pdoc_d

etag master lchg_date_time
lock master total etag lchg_date_time
authorization master( global )
{
  create;
  update;
  delete;
  
  draft action Edit;
  draft action Activate optimized;
  draft action Discard;
  draft action Resume;
  draft determine action Prepare;
  
  association _PurchaseDocumentItem { create; with draft; }
  
  action approve_order result [1] $self;
  action reject_order result [1] $self;
  
  field ( numbering : managed, readonly ) PurchaseDocument;
  
  field ( readonly ) Currency, IsApprovalRequired, OverallPrice, OverallPriceCriticality,
                     crea_date_time, crea_uname, lchg_date_time, lchg_uname;
  
  mapping for ztg_pdoc
  {
    PurchaseDocument         = purchasedocument;
    Description              = description;
    Status                   = status;
    Priority                 = priority;
    PurchasingOrganization   = purchasingorganization;
    PurchaseDocumentImageURL = purchasedocumentimageurl;
    crea_date_time           = crea_date_time;
    crea_uname               = crea_uname;
    lchg_date_time           = lchg_date_time;
    lchg_uname               = lchg_uname;
  }
}
```

**BDEF Deep-Dive:**

1. **Concurrency Control:**
   - `etag master lchg_date_time`: ETag based on last-change timestamp
   - `lock master total etag lchg_date_time`: Pessimistic lock on PO

2. **Authorization:**
   - `authorization master( global )`: Global auth checks
   - `authorization dependent by _PurchaseDocument`: Child auth delegated to parent

3. **Numbering:**
   - `field ( numbering : managed, readonly ) PurchaseDocument`: RAP generates UUIDs automatically

4. **Readonly Fields:**
   - Calculated fields (`OverallPrice`, `IsApprovalRequired`, `OverallPriceCriticality`)
   - Audit fields (`crea_*`, `lchg_*`)

5. **Draft Semantics:**
   - `with draft`: Enables draft versioning
   - `draft action Activate optimized`: Delta-based update
   - Child actions: `with draft` propagates child drafts

6. **Action Definitions:**
   ```abap
   action approve_order result [1] $self;
   ```
   - `result [1] $self`: Returns 1 entity of PurchaseDocument type
   - Calls `zbig_pdoc_rv_comp→approve_order()` handler

### Behavior Handler — `zbig_pdoc_rv_comp.clas.locals_imp.abap`

**Key Handler Pattern:**
- `FOR MODIFY`: Handles POST/PATCH/DELETE and custom actions
- `IMPORTING keys`: Input parameters (keys of affected entities)
- `RESULT result`: Output (response entity + messages)
- `FAILED failed`: Collection of failed entities
- `REPORTED reported`: Messages to return to client

**approve_order Handler:**
```abap
METHOD approve_order.
  DATA lt_update TYPE TABLE FOR UPDATE zig_pdoc_rv_comp\\PurchaseDocument.
  CLEAR result.
  
  /* Read current status */
  READ ENTITIES OF zig_pdoc_rv_comp IN LOCAL MODE
    ENTITY PurchaseDocument
    FIELDS ( Status )
    WITH CORRESPONDING #( keys )
    RESULT DATA(pdoc_data)
    FAILED failed.
  
  /* Validate and transition */
  LOOP AT keys INTO DATA(key_).
    IF key_-PurchaseDocument IS INITIAL.
      APPEND VALUE #( %tky = key_-%tky
                      %msg = new_message( id = 'ZMSG_E_PDOC' number = '009' ... ) )
        TO reported-PurchaseDocument.
      CONTINUE.
    ENDIF.
    
    READ TABLE pdoc_data ASSIGNING FIELD-SYMBOL(<pdoc>)
      WITH TABLE KEY id COMPONENTS %is_draft = key_-%is_draft
                                   PurchaseDocument = key_-PurchaseDocument.
    
    /* State machine validation */
    IF <pdoc>-Status = '2'.
      /* Error 013: already approved */
      CONTINUE.
    ENDIF.
    
    IF <pdoc>-Status = '3'.
      /* Error 014: already closed */
      CONTINUE.
    ENDIF.
    
    /* Transition to approved */
    APPEND VALUE #( %tky = key_-%tky Status = '2' ) TO lt_update.
  ENDLOOP.
  
  /* Persist changes */
  CHECK lt_update IS NOT INITIAL.
  MODIFY ENTITIES OF zig_pdoc_rv_comp IN LOCAL MODE
    ENTITY PurchaseDocument
    UPDATE FIELDS ( Status )
    WITH lt_update
    FAILED failed
    REPORTED reported.
  
  /* Build success result */
  LOOP AT keys INTO key_.
    CHECK line_exists( lt_update[ KEY id %tky = key_-%tky ] ).
    APPEND VALUE #( %tky = key_-%tky %param = CORRESPONDING #( key_ ) ) TO result.
    APPEND VALUE #( %tky = key_-%tky
                    %msg = new_message( id = 'ZMSG_E_PDOC' number = '002' ... ) )
      TO reported-PurchaseDocument.
  ENDLOOP.
ENDMETHOD.
```

**RAP Internals:**
- `READ ENTITIES OF zig_pdoc_rv_comp IN LOCAL MODE`: Read from behavior entity
- `%tky`, `%is_draft`: Internal keys managed by RAP (transactional key, draft flag)
- `MODIFY ENTITIES`: Updates via behavior (triggers validations)

### Projection Behavior Definition — `zcg_pdoc_rv.bdef`

```abap
projection;
strict(2);
use draft;

define behavior for ZCG_PDoc_RV alias PurchaseDocument
use etag
{
  use create;
  use update;
  use delete;
  
  use action Edit;
  use action Activate;
  use action Discard;
  use action Resume;
  use action Prepare;
  
  use action approve_order;
  use action reject_order;
  
  use association _PurchaseDocumentItem { create; with draft; }
}
```

**Projection Layer Purpose:**
- **Re-exposes** composition root behavior via projection
- Acts as **API contract** (what's exposed to clients)
- Enables **custom behavior implementation**
- `use action`: Explicitly re-exposes action to OData

---

## Part IV: OData Service Binding

### Service Definition — `zsdg_pdoc_v_1.srvd`

```abap
@EndUserText.label: 'Service Definition V1'
define service ZSDG_PDOC_V_1 {
  expose ZCG_PDoc_RV;
  expose ZCG_PItem;
  expose ZIG_PDoc;
  expose ZIG_Pdoc_Overall_Price;
  expose ZIG_Pdoc_Priority;
  expose ZIG_PDoc_RV_COMP;
  expose ZIG_PDoc_Status;
  expose ZIG_PItem;
  expose ZIG_PItem_COMP;
  expose ZIG_Purch_Org;
  expose ZIG_Vendor_type;
}
```

**Service Semantics:**
- `expose`: Makes entity available in OData service
- **Primary entity**: `ZCG_PDoc_RV` (used by UI)
- **Reference entities**: Status, Priority, PurchOrg, VendorType (lookups)
- **Optional exposures**: Composition root and basic views for direct consumption

### Service Binding — `zsbg_pdoc_v1.srvb` (OData V4)

```xml
<SRVB>
  <METADATA>
    <NAME>ZSBG_PDOC_V1</NAME>
    <TYPE>SRVB/SVB</TYPE>
    <DESCRIPTION>Service Binding V1</DESCRIPTION>
  </METADATA>
  
  <CONTENT>
    <BIND_TYPE>ODATA</BIND_TYPE>
    <BIND_TYPE_VERSION>V4</BIND_TYPE_VERSION>
    
    <SERVICES>
      <item>
        <SERVICE_NAME>ZSDG_PDOC_V_1</SERVICE_NAME>
        <SERVICE_VERSION>0001</SERVICE_VERSION>
        <SRVD_REF>
          <NAME>ZSDG_PDOC_V_1</NAME>
        </SRVD_REF>
      </item>
    </SERVICES>
    
    <CONTRACT>C1</CONTRACT>
    <PUBLISHED>true</PUBLISHED>
  </CONTENT>
</SRVB>
```

**Runtime Endpoint:**
```
GET    /sap/opu/odata4/sap/zsbg_pdoc_v1/0001/$metadata
GET    /sap/opu/odata4/sap/zsbg_pdoc_v1/0001/PurchaseDocuments
POST   /sap/opu/odata4/sap/zsbg_pdoc_v1/0001/PurchaseDocuments
POST   /sap/opu/odata4/sap/zsbg_pdoc_v1/0001/PurchaseDocuments('{key}')/Approve_Order
```

---

## Part V: Request Flow (Example: Approve Order)

### HTTP Request (OData V4)
```http
POST /sap/opu/odata4/sap/zsbg_pdoc_v1/0001/PurchaseDocuments('{PurchaseDocumentKey}')/Approve_Order
Content-Type: application/json

{
  "PurchaseDocument": "uuid-value"
}
```

### Processing Pipeline

```
1. OData Request Parser
   ├─ Parse URL → Entity: ZCG_PDoc_RV, Action: Approve_Order
   ├─ Extract payload
   └─ Validate ETag

2. Service Binding Resolver
   ├─ Route to ZSBG_PDOC_V1 (OData V4)
   ├─ Resolve ZCG_PDoc_RV.Approve_Order → ZIG_PDoc_RV_COMP.Approve_Order
   └─ Load projection BDEF

3. RAP Action Dispatcher
   ├─ Load composition BDEF (zig_pdoc_rv_comp.bdef)
   ├─ Find handler: zbig_pdoc_rv_comp→approve_order()
   └─ Prepare input: keys (with %tky, %is_draft)

4. Action Handler Execution
   ├─ READ ENTITIES → Fetch current PO
   ├─ Validate state machine
   ├─ MODIFY ENTITIES → Update Status = '2'
   └─ Build result + messages

5. Draft Handling (if %is_draft = true)
   ├─ Update ZTG_PDOC_D.STATUS
   └─ Return draft state to client

6. OData Response Builder
   ├─ Serialize updated entity as JSON
   ├─ Include messages
   └─ Set HTTP status: 200 (success) or 400 (error)

7. HTTP Response
   Status: 200 OK
   Body: Updated PurchaseDocument entity with success message
```

---

## Part VI: Key Architectural Decisions

| Layer | Component | Rationale |
|-------|-----------|-----------|
| **DB** | ZTG_PDOC (active) + ZTG_PDOC_D (draft) | Dual versioning for draft capability |
| **CDS** | 3-layer model (Basic → Composite → Consumption) | Separation of concerns; reusability |
| **Aggregation** | ZIG_Pdoc_Overall_Price (GROUP BY sum) | Calculated field not persisted; ensures consistency |
| **Business Logic** | Handler in composition layer (zbig_pdoc_rv_comp) | Single source of truth for state machine |
| **Projection** | ZCG_PDoc_RV re-exposes composition behavior | Decouples OData contract from BO logic |
| **Authorization** | Global auth checks in BDEF | Customizable per request |
| **Concurrency** | ETag + pessimistic lock on master | Prevents lost updates |
| **Actions** | approve_order, reject_order as custom actions | State transitions outside CRUD |
| **Draft Semantics** | with draft on composition + child | Users can draft/save/activate workflows |

---

## Part VII: Data Flow Architecture

```
Client (Fiori/REST)
    ↓
OData V4 Gateway (ZSBG_PDOC_V1)
    ↓
Service Definition (ZSDG_PDOC_V_1)
    ↓
Projection Behavior (ZCG_PDoc_RV.bdef)
├─ Composition Behavior (ZIG_PDoc_RV_COMP.bdef)
│  ├─ Handler (zbig_pdoc_rv_comp)
│  └─ Persistent Tables (ZTG_PDOC, ZTG_PDOC_D)
│
├─ Composition Root CDS (ZIG_PDoc_RV_COMP)
│  └─ Aggregation View (ZIG_Pdoc_Overall_Price)
│     └─ Basic Views (ZIG_PDoc, ZIG_PItem)
│        └─ Database Tables
│
└─ Reference Lookups
   └─ Master Tables
```

---

## Summary

This RAP application demonstrates enterprise-grade ABAP development with:
- **Separation of Concerns**: DB ← CDS ← Behavior ← Projection ← OData
- **Reusability**: CDS views consumed by multiple BDEFs
- **Consistency**: Single handler logic enforces all business rules
- **Scalability**: Draft model supports high-volume concurrent edits
- **Extensibility**: Projection layer allows customizations without touching BO logic
