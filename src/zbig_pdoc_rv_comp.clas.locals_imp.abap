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
* In the custom Action method for Approving a PurchaseDocument,
* current status is read first and branched upon before updating.
* Messages used: 009 (initial), 013 (already approved), 014 (already closed), 002 (approved)
    DATA lt_update TYPE TABLE FOR UPDATE zig_pdoc_rv_comp\\PurchaseDocument.
    CLEAR result.

    READ ENTITIES OF zig_pdoc_rv_comp IN LOCAL MODE
      ENTITY PurchaseDocument
      FIELDS ( Status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(pdoc_data)
      FAILED failed.

    LOOP AT keys INTO DATA(key_).

      IF key_-PurchaseDocument IS INITIAL.
        APPEND VALUE #( %tky                      = key_-%tky
                        %msg                      = new_message(
                                                         id       = 'ZMSG_E_PDOC'
                                                         number   = '009'
                                                         severity = if_abap_behv_message=>severity-error )
                        %element-PurchaseDocument = cl_abap_behv=>flag_changed )
          TO reported-PurchaseDocument.
        CONTINUE.
      ENDIF.

      READ TABLE pdoc_data ASSIGNING FIELD-SYMBOL(<pdoc>) WITH KEY %tky = key_-%tky.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      IF <pdoc>-Status = '2'.
        APPEND VALUE #( %tky                      = key_-%tky
                        %msg                      = new_message(
                                                         id       = 'ZMSG_E_PDOC'
                                                         number   = '013'
                                                         v1       = key_-PurchaseDocument
                                                         severity = if_abap_behv_message=>severity-error )
                        %element-PurchaseDocument = cl_abap_behv=>flag_changed )
          TO reported-PurchaseDocument.
        CONTINUE.
      ENDIF.

      IF <pdoc>-Status = '3'.
        APPEND VALUE #( %tky                      = key_-%tky
                        %msg                      = new_message(
                                                         id       = 'ZMSG_E_PDOC'
                                                         number   = '014'
                                                         v1       = key_-PurchaseDocument
                                                         severity = if_abap_behv_message=>severity-error )
                        %element-PurchaseDocument = cl_abap_behv=>flag_changed )
          TO reported-PurchaseDocument.
        CONTINUE.
      ENDIF.

      APPEND VALUE #( %tky   = key_-%tky
                      Status = '2' ) TO lt_update.

    ENDLOOP.

    CHECK lt_update IS NOT INITIAL.

    MODIFY ENTITIES OF zig_pdoc_rv_comp IN LOCAL MODE
      ENTITY PurchaseDocument
      UPDATE FIELDS ( Status )
      WITH lt_update
      FAILED failed
      REPORTED reported.

    LOOP AT keys INTO key_.
      CHECK line_exists( lt_update[ %tky = key_-%tky ] ).
      CHECK NOT line_exists( failed-PurchaseDocument[ %tky = key_-%tky ] ).

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
* current status is read first and branched upon before updating.
* Messages used: 009 (initial), 014 (already closed), 003 (closed)
    DATA lt_update TYPE TABLE FOR UPDATE zig_pdoc_rv_comp\\PurchaseDocument.
    CLEAR result.

    READ ENTITIES OF zig_pdoc_rv_comp IN LOCAL MODE
      ENTITY PurchaseDocument
      FIELDS ( Status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(pdoc_data)
      FAILED failed.

    LOOP AT keys INTO DATA(key_).

      IF key_-PurchaseDocument IS INITIAL.
        APPEND VALUE #( %tky                      = key_-%tky
                        %msg                      = new_message(
                                                         id       = 'ZMSG_E_PDOC'
                                                         number   = '009'
                                                         severity = if_abap_behv_message=>severity-error )
                        %element-PurchaseDocument = cl_abap_behv=>flag_changed )
          TO reported-PurchaseDocument.
        CONTINUE.
      ENDIF.

      READ TABLE pdoc_data ASSIGNING FIELD-SYMBOL(<pdoc>) WITH KEY %tky = key_-%tky.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      IF <pdoc>-Status = '3'.
        APPEND VALUE #( %tky                      = key_-%tky
                        %msg                      = new_message(
                                                         id       = 'ZMSG_E_PDOC'
                                                         number   = '014'
                                                         v1       = key_-PurchaseDocument
                                                         severity = if_abap_behv_message=>severity-error )
                        %element-PurchaseDocument = cl_abap_behv=>flag_changed )
          TO reported-PurchaseDocument.
        CONTINUE.
      ENDIF.

      " Approved (status '2') or any other status: collect for closing
      APPEND VALUE #( %tky   = key_-%tky
                      Status = '3' ) TO lt_update.

    ENDLOOP.

    CHECK lt_update IS NOT INITIAL.

    MODIFY ENTITIES OF zig_pdoc_rv_comp IN LOCAL MODE
      ENTITY PurchaseDocument
      UPDATE FIELDS ( Status )
      WITH lt_update
      FAILED failed
      REPORTED reported.

    LOOP AT keys INTO key_.
      CHECK line_exists( lt_update[ %tky = key_-%tky ] ).
      CHECK NOT line_exists( failed-PurchaseDocument[ %tky = key_-%tky ] ).

      APPEND VALUE #( %tky    = key_-%tky
                      %param  = CORRESPONDING #( key_ ) ) TO result.
      APPEND VALUE #( %tky                      = key_-%tky
                      %msg                      = new_message(
                                                       id       = 'ZMSG_E_PDOC'
                                                       number   = '003'
                                                       v1       = key_-PurchaseDocument
                                                       severity = if_abap_behv_message=>severity-success )
                      %element-PurchaseDocument = cl_abap_behv=>flag_changed )
        TO reported-PurchaseDocument.
    ENDLOOP.

  ENDMETHOD.



ENDCLASS.
