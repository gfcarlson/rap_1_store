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

    MODIFY ENTITIES OF zig_pdoc_rv_comp IN LOCAL MODE
      ENTITY PurchaseDocument
      UPDATE FIELDS ( Status )
      WITH VALUE #( FOR key IN keys
                    ( %tky   = key-%tky
                      Status = '2' ) )
      FAILED failed
      REPORTED reported.

    LOOP AT keys INTO DATA(key).
      IF line_exists( failed-PurchaseDocument[ %tky = key-%tky ] ).
        CONTINUE.
      ENDIF.

      APPEND VALUE #( %tky    = key-%tky
                      %param  = CORRESPONDING #( key ) ) TO result.
      APPEND VALUE #( %tky                      = key-%tky
                      %msg                      = new_message(
                                                       id       = 'ZPURCHDOC_EXCEPTIONS'
                                                       number   = '002'
                                                       v1       = key-PurchaseDocument
                                                       severity = if_abap_behv_message=>severity-success )
                      %element-PurchaseDocument = cl_abap_behv=>flag_changed )
        TO reported-PurchaseDocument.
    ENDLOOP.
  ENDMETHOD.

  METHOD Reject_Order.
    CLEAR result.

    MODIFY ENTITIES OF zig_pdoc_rv_comp IN LOCAL MODE
      ENTITY PurchaseDocument
      UPDATE FIELDS ( Status )
      WITH VALUE #( FOR key IN keys
                    ( %tky   = key-%tky
                      Status = '3' ) )
      FAILED failed
      REPORTED reported.

    LOOP AT keys INTO DATA(key).
      IF line_exists( failed-PurchaseDocument[ %tky = key-%tky ] ).
        CONTINUE.
      ENDIF.

      APPEND VALUE #( %tky    = key-%tky
                      %param  = CORRESPONDING #( key ) ) TO result.
      APPEND VALUE #( %tky                      = key-%tky
                      %msg                      = new_message(
                                                       id       = 'ZPURCHDOC_EXCEPTIONS'
                                                       number   = '003'
                                                       v1       = key-PurchaseDocument
                                                       severity = if_abap_behv_message=>severity-success )
                      %element-PurchaseDocument = cl_abap_behv=>flag_changed )
        TO reported-PurchaseDocument.
    ENDLOOP.

  endmethod.



ENDCLASS.
