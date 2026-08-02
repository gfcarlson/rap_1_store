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
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_PurchaseDocument>).
      " Message 009: report error if Purchase Document number is initial
      IF <fs_PurchaseDocument>-PurchaseDocument IS INITIAL.
        APPEND VALUE #( purchasedocument = <fs_PurchaseDocument>-PurchaseDocument
                       %msg = new_message( id       = 'ZMSG_E_PDOC'
                                           number   = '009'
                                           severity = if_abap_behv_message=>severity-error )
                       %element-purchasedocument = cl_abap_behv=>flag_changed )
               TO reported-PurchaseDocument.
        CONTINUE.
      ENDIF.
      UPDATE ztg_pdoc SET status = 2 WHERE purchasedocument = @<fs_PurchaseDocument>-PurchaseDocument.
      IF sy-subrc EQ 0.
        APPEND VALUE #( purchasedocument        = <fs_PurchaseDocument>-PurchaseDocument
                       %param-purchasedocument = <fs_PurchaseDocument>-PurchaseDocument
                       %param-status           = '2' )
               TO result.
        " Message 002: Purchase Document & Approved
        APPEND VALUE #( purchasedocument = <fs_PurchaseDocument>-PurchaseDocument
                       %msg = new_message( id       = 'ZMSG_E_PDOC'
                                           number   = '002'
                                           v1       = <fs_PurchaseDocument>-PurchaseDocument
                                           severity = if_abap_behv_message=>severity-success )
                       %element-purchasedocument = cl_abap_behv=>flag_changed )
               TO reported-PurchaseDocument.
      ELSE.
        " Message 013: Purchase Document & Is already Approved (update failed)
        APPEND VALUE #( purchasedocument = <fs_PurchaseDocument>-PurchaseDocument
                       %msg = new_message( id       = 'ZMSG_E_PDOC'
                                           number   = '013'
                                           v1       = <fs_PurchaseDocument>-PurchaseDocument
                                           severity = if_abap_behv_message=>severity-error )
                       %element-purchasedocument = cl_abap_behv=>flag_changed )
               TO reported-PurchaseDocument.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD Reject_Order.
* In the custom Action method for Rejecting/Closing a PurchaseDocument,
* The incoming parameter is looped and the relevant PurchaseDocument status is set as closed (3)
* and details of the Action are stored in the RESULT parameter of the method
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_PurchaseDocument>).
      " Message 009: report error if Purchase Document number is initial
      IF <fs_PurchaseDocument>-PurchaseDocument IS INITIAL.
        APPEND VALUE #( purchasedocument = <fs_PurchaseDocument>-PurchaseDocument
                       %msg = new_message( id       = 'ZMSG_E_PDOC'
                                           number   = '009'
                                           severity = if_abap_behv_message=>severity-error )
                       %element-purchasedocument = cl_abap_behv=>flag_changed )
               TO reported-PurchaseDocument.
        CONTINUE.
      ENDIF.
      UPDATE ztg_pdoc SET status = 3 WHERE purchasedocument = @<fs_PurchaseDocument>-PurchaseDocument.
      IF sy-subrc EQ 0.
        APPEND VALUE #( purchasedocument        = <fs_PurchaseDocument>-PurchaseDocument
                       %param-purchasedocument = <fs_PurchaseDocument>-PurchaseDocument
                       %param-status           = '3' )
               TO result.
        " Message 003: Purchase Document & Closed
        APPEND VALUE #( purchasedocument = <fs_PurchaseDocument>-PurchaseDocument
                       %msg = new_message( id       = 'ZMSG_E_PDOC'
                                           number   = '003'
                                           v1       = <fs_PurchaseDocument>-PurchaseDocument
                                           severity = if_abap_behv_message=>severity-success )
                       %element-purchasedocument = cl_abap_behv=>flag_changed )
               TO reported-PurchaseDocument.
      ELSE.
        " Message 014: Purchase Document & Is already Closed (update failed)
        APPEND VALUE #( purchasedocument = <fs_PurchaseDocument>-PurchaseDocument
                       %msg = new_message( id       = 'ZMSG_E_PDOC'
                                           number   = '014'
                                           v1       = <fs_PurchaseDocument>-PurchaseDocument
                                           severity = if_abap_behv_message=>severity-error )
                       %element-purchasedocument = cl_abap_behv=>flag_changed )
               TO reported-PurchaseDocument.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.



ENDCLASS.
