@AbapCatalog.sqlViewName: 'ZIG__PDOC_STATUS'
@VDM.viewType: #BASIC
@AccessControl.authorizationCheck: #NOT_ALLOWED
@EndUserText.label: 'Purchase Document Status'
@ObjectModel.representativeKey: 'Status'
@ObjectModel.semanticKey: ['Status']
@Analytics.dataCategory: #DIMENSION
@ObjectModel.resultSet.sizeCategory: #XS

define view ZIG_PDoc_Status
  as select from ztg_pdoc_status
{

      @ObjectModel.text.element: ['StatusText']
      @EndUserText.label: 'Status'
  key status     as Status,

      @Semantics.text: true
      @EndUserText.label: 'Status Text'
      statustext as StatusText
}
