@AbapCatalog.sqlViewName: 'ZIG__PURCH_ORG'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Purchasing Organization'
@Analytics.dataCategory: #DIMENSION
@VDM.viewType: #BASIC

@ObjectModel.semanticKey: ['PurchasingOrganization']
@ObjectModel.representativeKey: 'PurchasingOrganization'

define view ZIG_Purch_Org
  as select from ztg_purch_org
{

      @ObjectModel.text.element: [ 'Description' ]
  key purchasingorganization as PurchasingOrganization,

      @Semantics.text: true
      @Semantics.name.fullName: true
      description            as Description,

      @Semantics: {
      eMail.address: true,
      eMail.type:  [ #WORK ]
      }
      emailaddress           as Email,
      @Semantics.telephone.type:  [ #WORK ]
      phonenumber            as Phone,
      @Semantics.telephone.type:  [ #FAX ]
      faxnumber              as Fax



}
