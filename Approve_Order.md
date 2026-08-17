# Approve_Order — Technical RAP Flow

This document captures everything covered about what happens when a user clicks **Approve_Order** in the RAP purchase document application, including the technical RAP flow, all diagrams, flowcharts, [...]

## End-to-end technical overview

When the user clicks **Approve_Order**, the request travels through the RAP stack:

- **Fiori Elements UI** triggers an OData V4 action call
- **Service Binding** `ZSBG_PDOC_V1` receives the request
- **Service Definition** `ZSDG_PDOC_V_1` exposes the transactional entity
- **Projection View** `ZCG_PDoc_RV` maps the request into the consumption model
- **Projection Behavior** `zcg_pdoc_rv.bdef` re-exposes the action
- **Root Behavior** `zig_pdoc_rv_comp.bdef` owns the business object action
- **Behavior Handler** `zbig_pdoc_rv_comp.approve_order()` performs the state transition
- **Persistence** is updated in `ZTG_PDOC` or `ZTG_PDOC_D` depending on draft state

## Sequence diagram — business-level flow

```text
User
  │
  │ clicks Approve_Order
  ▼
Fiori UI
  │
  │ sends OData V4 action request
  ▼
Service Binding (ZSBG_PDOC_V1)
  │
  ▼
Service Definition (ZSDG_PDOC_V_1)
  │
  ▼
Projection View / Behavior
ZCG_PDoc_RV
  │
  │ use action approve_order
  ▼
Composition Root Behavior
ZIG_PDoc_RV_COMP
  │
  ▼
Behavior Handler
zbig_pdoc_rv_comp.approve_order( )
  │
  ├─ Read current PurchaseDocument status
  ├─ Check key is not initial
  ├─ If status = '2' → error 013 (already approved)
  ├─ If status = '3' → error 014 (already closed)
  └─ Otherwise set Status = '2'
  │
  ▼
MODIFY ENTITIES
  │
  ├─ persist updated Status
  └─ return result + success message 002
  │
  ▼
UI refreshes
  │
  └─ shows Status = Approved status 2
```

## Sequence diagram — technical RAP flow

```mermaid
%%{init: {"theme": "base", "themeVariables": {"background": "transparent", "fontFamily": "ui-sans-serif, system-ui, -apple-system, Segoe UI, sans-serif", "primaryColor": "#ffffff", "primaryTextColor": "#000000", "primaryBorderColor": "#ffd400", "lineColor": "#ffd400", "signalColor": "#ffd400", "secondaryColor": "#ffffff", "secondaryTextColor": "#000000", "secondaryBorderColor": "#ffd400", "actorBkg": "#ffffff", "actorTextColor": "#000000", "actorBorderColor": "#ffd400", "noteBkgColor": "#ffffff", "noteTextColor": "#ffffff", "noteBorderColor": "#ffd400", "clusterBkg": "#ffffff", "clusterBorderColor": "#ffd400", "textColor": "#ffffff", "labelTextColor": "#ffffff", "messageTextColor": "#ffffff", "messageFontColor": "#ffffff", "altTextColor": "#ffffff", "loopTextColor": "#ffffff", "activationTextColor": "#ffffff"}}}%%
sequenceDiagram
    actor User
    participant Fiori as Fiori Elements / UI
    participant OData as OData V4 Service Binding<br/>ZSBG_PDOC_V1
    participant SRVD as Service Definition<br/>ZSDG_PDOC_V_1
    participant PROJ as Projection Behavior<br/>ZCG_PDoc_RV.bdef
    participant ROOT as Root Behavior<br/>zig_pdoc_rv_comp.bdef
    participant HANDLER as ABAP Behavior Handler

    User->>Fiori: Click Approve_Order
    Fiori->>OData: POST .../PurchaseDocuments('{key}')/Approve_Order
    OData->>SRVD: Resolve exposed entity/action
    SRVD->>PROJ: Map action to projection
    PROJ->>ROOT: use action approve_order
    ROOT->>HANDLER: FOR MODIFY approve_order( keys )

    HANDLER->>HANDLER: READ ENTITIES IN LOCAL MODE<br/>Fetch Status for target PurchaseDocument
    HANDLER->>HANDLER: Validate key is not initial
    HANDLER->>HANDLER: IF Status = '2' → error 013
    HANDLER->>HANDLER: IF Status = '3' → error 014
    HANDLER->>HANDLER: Else set Status = '2'
    HANDLER->>HANDLER: MODIFY ENTITIES IN LOCAL MODE<br/>UPDATE FIELDS ( Status )

    alt valid transition
        HANDLER-->>PROJ: result + reported message 002
        PROJ-->>Fiori: Return updated entity
        Fiori-->>User: Show Approved status 2
    else invalid transition
        HANDLER-->>PROJ: failed/reported message 013 or 014
        PROJ-->>Fiori: Return error response
        Fiori-->>User: Show error message
    end
```

## Flowchart — technical RAP internals

```mermaid
%%{init: {"theme": "base", "themeVariables": {"background": "transparent", "fontFamily": "ui-sans-serif, system-ui, -apple-system, Segoe UI, sans-serif", "primaryColor": "#ffffff", "primaryTextColor": "#000000", "primaryBorderColor": "#ffd400", "lineColor": "#ffd400", "signalColor": "#ffd400", "secondaryColor": "#ffffff", "secondaryTextColor": "#000000", "secondaryBorderColor": "#ffd400", "actorBkg": "#ffffff", "actorTextColor": "#000000", "actorBorderColor": "#ffd400", "noteBkgColor": "#ffffff", "noteTextColor": "#000000", "noteBorderColor": "#ffd400", "clusterBkg": "#ffffff", "clusterBorderColor": "#ffd400"}}}%%
flowchart TD
    A[UI Action: Approve_Order] --> B[OData V4 POST action request]
    B --> C[Service Binding routes request]
    C --> D[Service Definition exposes ZCG_PDoc_RV]
    D --> E[Projection behavior receives action]
    E --> F[Root behavior declares action approve_order]
    F --> G[ABAP handler method approve_order]
    G --> H[READ ENTITIES IN LOCAL MODE]
    H --> I{PurchaseDocument key initial?}
    I -- Yes --> J[Raise msg 009: Initial]
    I -- No --> K{Status = '2'?}
    K -- Yes --> L[Raise msg 013: Already approved]
    K -- No --> M{Status = '3'?}
    M -- Yes --> N[Raise msg 014: Already closed]
    M -- No --> O[Set Status = '2']
    O --> P[MODIFY ENTITIES update Status]
    P --> Q[Return success msg 002]
    Q --> R[UI refreshes with Approved]
```

## Flowchart — exact status transition rules

```mermaid
%%{init: {"theme": "base", "themeVariables": {"background": "transparent", "fontFamily": "ui-sans-serif, system-ui, -apple-system, Segoe UI, sans-serif", "primaryColor": "#ffffff", "primaryTextColor": "#000000", "primaryBorderColor": "#ffd400", "lineColor": "#ffd400", "signalColor": "#ffd400", "secondaryColor": "#ffffff", "secondaryTextColor": "#000000", "secondaryBorderColor": "#ffd400", "actorBkg": "#ffffff", "actorTextColor": "#000000", "actorBorderColor": "#ffd400", "noteBkgColor": "#ffffff", "noteTextColor": "#000000", "noteBorderColor": "#ffd400", "clusterBkg": "#ffffff", "clusterBorderColor": "#ffd400", "textColor": "#000000", "labelTextColor": "#000000"}}}%%
flowchart TD
    A[User clicks Approve_Order in Fiori Elements]
    --> B[OData V4 POST action request<br/>PurchaseDocuments key action Approve_Order]

    B --> C[Projection Entity<br/>ZCG_PDoc_RV]

    C --> D[Projection Behavior<br/>zcg_pdoc_rv.bdef<br/>use action approve_order]

    D --> E[Root Behavior<br/>zig_pdoc_rv_comp.bdef<br/>action approve_order result self]

    E --> F["ABAP Handler Method<br/>zbig_pdoc_rv_comp.approve_order()<br/>FOR MODIFY"]

    F --> G["READ ENTITIES OF zig_pdoc_rv_comp IN LOCAL MODE<br/>ENTITY PurchaseDocument<br/>FIELDS ( Status )<br/>WITH CORRESPONDING #( keys )"]

    G --> H{PurchaseDocument key initial?}

    H -- Yes --> I[REPORTED: ZMSG_E_PDOC 009<br/>Purchase Document is Initial]

    H -- No --> J{Current Status?}

    J -- '2' --> K[REPORTED: ZMSG_E_PDOC 013<br/>Already Approved]

    J -- '3' --> L[REPORTED: ZMSG_E_PDOC 014<br/>Already Closed]

    J -- '1' --> M[Set Status = '2'<br/>Approved]

    M --> N["MODIFY ENTITIES OF zig_pdoc_rv_comp IN LOCAL MODE<br/>ENTITY PurchaseDocument<br/>UPDATE FIELDS ( Status )<br/>WITH lt_update"]

    N --> O{Draft? %is_draft}

    O -- true --> P[Persist draft change<br/>ZTG_PDOC_D.STATUS = '2']
    O -- false --> Q[Persist active change<br/>ZTG_PDOC.STATUS = '2']

    P --> R[Build RESULT<br/>%tky / %param]
    Q --> R[Build RESULT<br/>%tky / %param]

    R --> S[REPORTED success message<br/>ZMSG_E_PDOC 002<br/>Document approved]

    S --> T[UI refreshes entity<br/>Status = Approved status 2]
```

## Draft vs active path

```mermaid
%%{init: {"theme": "base", "themeVariables": {"background": "transparent", "fontFamily": "ui-sans-serif, system-ui, -apple-system, Segoe UI, sans-serif", "primaryColor": "#ffffff", "primaryTextColor": "#000000", "primaryBorderColor": "#ffd400", "lineColor": "#ffd400", "secondaryColor": "#ffffff", "secondaryTextColor": "#000000", "secondaryBorderColor": "#ffd400", "tertiaryColor": "#ffffff", "tertiaryTextColor": "#000000", "tertiaryBorderColor": "#ffd400", "actorBkg": "#ffffff", "actorTextColor": "#000000", "actorBorderColor": "#ffd400", "signalColor": "#ffd400", "noteBkgColor": "#ffffff", "noteTextColor": "#ffffff", "noteBorderColor": "#ffd400", "clusterBkg": "#ffffff", "clusterBorderColor": "#ffd400", "textColor": "#ffffff", "labelTextColor": "#ffffff", "altTextColor": "#ffffff", "loopTextColor": "#ffffff", "activationTextColor": "#ffffff"}}}%%
flowchart TD
    A[User clicks Approve_Order] --> B[OData V4 action request]
    B --> C[ZCG_PDoc_RV projection entity]
    C --> D[zcg_pdoc_rv.bdef]
    D --> E[zig_pdoc_rv_comp.bdef<br/>approve_order action]
    E --> F["zbig_pdoc_rv_comp.approve_order()"]

    F --> G["READ ENTITIES OF zig_pdoc_rv_comp IN LOCAL MODE"]
    G --> H{key initial?}
    H -- Yes --> I[Error 009<br/>Initial]
    H -- No --> J{Status = '2'?}
    J -- Yes --> K[Error 013<br/>Already approved]
    J -- No --> L{Status = '3'?}
    L -- Yes --> M[Error 014<br/>Already closed]
    L -- No --> N[Set Status = '2']

    N --> O{Is draft instance? %is_draft = true}
    O -- Yes --> P[Update ZTG_PDOC_D<br/>draft table]
    O -- No --> Q[Update ZTG_PDOC<br/>active table]

    P --> R[MODIFY ENTITIES]
    Q --> R
    R --> S[Return reported success msg 002]
    S --> T[UI refreshes entity]
```

```mermaid
%%{init: {"theme": "base", "themeVariables": {"background": "transparent", "fontFamily": "ui-sans-serif, system-ui, -apple-system, Segoe UI, sans-serif", "primaryColor": "#ffffff", "primaryTextColor": "#000000", "primaryBorderColor": "#ffd400", "lineColor": "#ffd400", "secondaryColor": "#ffffff", "secondaryTextColor": "#000000", "secondaryBorderColor": "#ffd400", "tertiaryColor": "#ffffff", "tertiaryTextColor": "#000000", "tertiaryBorderColor": "#ffd400", "actorBkg": "#ffffff", "actorTextColor": "#000000", "actorBorderColor": "#ffd400", "signalColor": "#ffd400", "noteBkgColor": "#ffffff", "noteTextColor": "#ffffff", "noteBorderColor": "#ffd400", "clusterBkg": "#ffffff", "clusterBorderColor": "#ffd400", "textColor": "#ffffff", "labelTextColor": "#ffffff", "messageTextColor": "#ffffff", "messageFontColor": "#ffffff"}}}%%
sequenceDiagram
    actor User
    participant FE as Fiori Elements
    participant PROJ as ZCG_PDoc_RV
    participant BDEF as zcg_pdoc_rv.bdef
    participant ROOT as zig_pdoc_rv_comp.bdef
    participant H as ABAP Behavior Handler
    participant ACT as ZTG_PDOC
    participant DFT as ZTG_PDOC_D

    User->>FE: Click Approve_Order
    FE->>PROJ: POST action request
    PROJ->>BDEF: Use action approve_order
    BDEF->>ROOT: Forward action
    ROOT->>H: FOR MODIFY approve_order(keys)

    H->>H: READ ENTITIES IN LOCAL MODE
    H->>H: Validate key and status
    H->>H: Set Status = '2'

    alt draft instance
        H->>DFT: Persist Status = '2'
        H-->>FE: Success msg 002
    else active instance
        H->>ACT: Persist Status = '2'
        H-->>FE: Success msg 002
    end

    FE-->>User: Refresh shows Approved
```

## Annotated single-page RAP diagram

```mermaid
%%{init: {"theme": "base", "themeVariables": {"background": "transparent", "fontFamily": "ui-sans-serif, system-ui, -apple-system, Segoe UI, sans-serif", "primaryColor": "#ffffff", "primaryTextColor": "#000000", "primaryBorderColor": "#ffd400", "lineColor": "#ffd400", "secondaryColor": "#ffffff", "secondaryTextColor": "#000000", "secondaryBorderColor": "#ffd400", "tertiaryColor": "#ffffff", "tertiaryTextColor": "#000000", "tertiaryBorderColor": "#ffd400", "actorBkg": "#ffffff", "actorTextColor": "#000000", "actorBorderColor": "#ffd400", "signalColor": "#ffd400", "noteBkgColor": "#ffffff", "noteTextColor": "#000000", "noteBorderColor": "#ffd400", "clusterBkg": "#ffffff", "clusterBorderColor": "#ffd400"}}}%%
flowchart TD
    A[User clicks Approve_Order in Fiori Elements]
    --> B[OData V4 POST action request<br/>PurchaseDocuments key action Approve_Order]

    B --> C[Projection Entity<br/>ZCG_PDoc_RV]

    F --> G["READ ENTITIES OF zig_pdoc_rv_comp IN LOCAL MODE<br/>ENTITY PurchaseDocument<br/>FIELDS ( Status )<br/>WITH CORRESPONDING #( keys )"]

    G --> H{Validate RAP key / state}
    H -- Status = '2' --> J[REPORTED: ZMSG_E_PDOC 013<br/>Already Approved]

    H -- Status = '3' --> K[REPORTED: ZMSG_E_PDOC 014<br/>Already Closed]
    M --> N{Draft? %is_draft}

    N -- true --> O[Persist draft change<br/>ZTG_PDOC_D.STATUS = '2']
    N -- false --> P[Persist active change<br/>ZTG_PDOC.STATUS = '2']

    O --> Q[Build RESULT<br/>%tky / %param]
    P --> Q[Build RESULT<br/>%tky / %param]

    Q --> R[REPORTED success message<br/>ZMSG_E_PDOC 002<br/>Document approved]

    R --> S[UI refreshes entity<br/>Status = Approved status 2]
```

## Runtime callouts

- **`keys`**: RAP transactional keys passed into the action
- **`%tky`**: internal transactional key used to correlate result rows
- **`%is_draft`**: indicates whether the action targets draft or active data
- **`READ ENTITIES`**: retrieves current BO state through RAP, not direct SQL
- **`MODIFY ENTITIES`**: performs the state transition through the behavior layer
- **`result` / `failed` / `reported`**: RAP response channels for success and errors

## Status transition summary

- `'1'` → `'2'` : allowed
- `'2'` → `'2'` : blocked, error 013
- `'3'` → `'2'` : blocked, error 014

## Related architecture components

- UI entity: `ZCG_PDoc_RV`
- Projection behavior: `zcg_pdoc_rv.bdef`
- Root behavior: `zig_pdoc_rv_comp.bdef`
- Behavior handler: `zbig_pdoc_rv_comp.approve_order()`
- Persistence: `ZTG_PDOC` and `ZTG_PDOC_D`
