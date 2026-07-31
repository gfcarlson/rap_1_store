CLASS lhc_PurchaseDocument DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR PurchaseDocument RESULT result.


    METHODS approve_order FOR MODIFY
      IMPORTING keys FOR ACTION PurchaseDocument~approve_order RESULT result.


    METHODS reject_order FOR MODIFY
      IMPORTING keys FOR ACTION PurchaseDocument~reject_order RESULT result.

ENDCLASS.

CLASS lhc_PurchaseDocument IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.


  method approve_order.
  endmethod.

  method reject_order.
  endmethod.

ENDCLASS.
