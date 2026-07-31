@AbapCatalog.sqlViewName: 'ZIG__PDoc_Prior'
@AccessControl.authorizationCheck: #NOT_ALLOWED
@EndUserText.label: 'Purchase Document Priority'
@ObjectModel.representativeKey: 'Priority'
@ObjectModel.semanticKey: ['Priority']
@Analytics.dataCategory: #DIMENSION
@VDM.viewType: #BASIC
@ObjectModel.resultSet.sizeCategory: #XS

define view ZIG_Pdoc_Priority
  as select from ztg_priority
{

      @ObjectModel.text.element: ['PriorityText']
      @EndUserText.label: 'Priority'
  key priority     as Priority,

      @Semantics.text: true
      @EndUserText.label: 'Priority Text'
      prioritytext as PriorityText
}
