@AbapCatalog.sqlViewName: 'ZIG__PDOC'
@EndUserText.label: 'Purchase Document'
@AccessControl.authorizationCheck: #NOT_REQUIRED
//@AbapCatalog.preserveKey: true
@VDM.viewType: #BASIC

//@Analytics.dataCategory: #DIMENSION
@ObjectModel.representativeKey: 'PurchaseDocument'
@ObjectModel.semanticKey: ['PurchaseDocument']


define view ZIG_PDoc
  as select from ztg_pdoc
  association [0..*] to ZIG_PItem     as _PurchaseDocumentItem   on $projection.PurchaseDocument = _PurchaseDocumentItem.PurchaseDocument
  association [0..1] to ZIG_Pdoc_Priority as _Priority               on $projection.Priority = _Priority.Priority
  association [0..1] to ZIG_PDoc_Status   as _Status                 on $projection.Status = _Status.Status
  association [0..1] to ZIG_Purch_Org   as _PurchasingOrganization on $projection.PurchasingOrganization = _PurchasingOrganization.PurchasingOrganization
{
      @ObjectModel.text.element: ['Description']
  key purchasedocument         as PurchaseDocument,
      @Semantics.text: true
      description              as Description,

     @ObjectModel.foreignKey.association: '_Status'
      status                   as Status,
      @ObjectModel.foreignKey.association: '_Priority'
      priority               as Priority,
      @ObjectModel.foreignKey.association: '_PurchasingOrganization'
      purchasingorganization   as PurchasingOrganization,

      @Semantics.imageUrl: true
      purchasedocumentimageurl as PurchaseDocumentImageURL,

      // BOPF Admin Data
      crea_date_time,
      crea_uname,
      lchg_date_time,
      lchg_uname,

      // Associations
      _PurchaseDocumentItem,
      _Priority,
      _Status,
      _PurchasingOrganization
}
