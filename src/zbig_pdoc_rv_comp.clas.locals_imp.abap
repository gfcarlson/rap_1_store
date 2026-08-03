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


  METHOD approve_order.
    CLEAR result.
* In the custom Action method for Approving a PurchaseDocument,
* The incoming parameter is looped and the relevant PurchaseDocument status is set as approved
* and details of the Action are stored in the RESULT parameter of the method
clear result.

    MODIFY ENTITIES OF zig_pdoc_rv_comp IN LOCAL MODE
      ENTITY PurchaseDocument
      UPDATE FIELDS ( Status )
      WITH VALUE #( FOR key IN keys
                    ( %tky   = key-%tky
                      Status = '2' ) )
      FAILED failed
      REPORTED reported.

    LOOP AT keys INTO DATA(key_).
      IF line_exists( failed-PurchaseDocument[ %tky = key_-%tky ] ).
        CONTINUE.
      ENDIF.

      APPEND VALUE #( %tky    = key_-%tky
                      %param  = CORRESPONDING #( key_ ) ) TO result.
      APPEND VALUE #( %tky                      = key_-%tky
                      %msg                      = new_message(
                                                       id       = 'ZMSG_E_PDOC'
                                                       number   = '002'
                                                       v1       = key_-PurchaseDocument
                                                       severity = if_abap_behv_message=>severity-success )
                      %element-PurchaseDocument = cl_abap_behv=>flag_changed )
        TO reported-PurchaseDocument.
        ENDLOOP.
  ENDMETHOD.

  METHOD Reject_Order.
* In the custom Action method for Rejecting/Closing a PurchaseDocument,
* The incoming parameter is looped and the relevant PurchaseDocument status is set as closed (3)
* and details of the Action are stored in the RESULT parameter of the method
 CLEAR result.

    MODIFY ENTITIES OF zig_pdoc_rv_comp IN LOCAL MODE
      ENTITY PurchaseDocument
      UPDATE FIELDS ( Status )
      WITH VALUE #( FOR key IN keys
                    ( %tky   = key-%tky
                      Status = '3' ) )
      FAILED failed
      REPORTED reported.

    LOOP AT keys INTO DATA(key_).
      IF line_exists( failed-PurchaseDocument[ %tky = key_-%tky ] ).
        CONTINUE.
      ENDIF.

      APPEND VALUE #( %tky    = key_-%tky
                      %param  = CORRESPONDING #( key_ ) ) TO result.
      APPEND VALUE #( %tky                      = key_-%tky
                      %msg                      = new_message(
                                                       id       = 'ZZMSG_E_PDOC'
                                                       number   = '003'
                                                       v1       = key_-PurchaseDocument
                                                       severity = if_abap_behv_message=>severity-success )
                      %element-PurchaseDocument = cl_abap_behv=>flag_changed )
        TO reported-PurchaseDocument.
        ENDLOOP.

  ENDMETHOD.



ENDCLASS.
