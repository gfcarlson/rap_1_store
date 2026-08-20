@AbapCatalog.sqlViewName: 'ZGI__VENDOR_TYPE'
@VDM.viewType: #BASIC
@AccessControl.authorizationCheck: #NOT_ALLOWED
@EndUserText.label: 'Vendor Type'
@ObjectModel.representativeKey: 'VendorType'
@ObjectModel.semanticKey: ['VendorType']
@Analytics.dataCategory: #DIMENSION
@ObjectModel.resultSet.sizeCategory: #XS
define view ZIG_Vendor_type   as select from ztg_vendor_type
{

      @ObjectModel.text.element: ['VendorTypeText']
      @EndUserText.label: 'Vendor Type'
  key vendortype     as VendorType,

      @Semantics.text: true
      @EndUserText.label: 'Vendor Type Text'
      vendortypetext as VendorTypeText
}
