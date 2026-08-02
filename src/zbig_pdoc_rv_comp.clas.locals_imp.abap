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

     DATA ls_purchdocument TYPE ztg_pdoc.
    CLEAR result.
* In the custom Action method for Approving a PurchaseDocument,
* The incoming parameter is looped and the relevant PurchaseDocument status is set as approved and details of the Action is store in the RESULT parameter of the method
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_PurchaseDocument>).
      UPDATE ztg_pdoc SET status = 2 WHERE purchasedocument = @<fs_PurchaseDocument>-PurchaseDocument.
      if sy-subrc eq 0.
      APPEND VALUE #(   purchasedocument        = <fs_PurchaseDocument>-PurchaseDocument
                        %param-purchasedocument = <fs_PurchaseDocument>-PurchaseDocument
                        %param-status           = '2' )
               TO result.
      endif.
    ENDLOOP.
* The relevant Success Message is mapped to the REPORTED parameter of the method
    APPEND VALUE #(  purchasedocument = ls_purchdocument-purchasedocument
                         %msg = new_message( id = 'ZPURCHDOC_EXCEPTIONS' number = '002' v1 = <fs_PurchaseDocument>-PurchaseDocument    severity = if_abap_behv_message=>severity-success )
                        %element-purchasedocument = cl_abap_behv=>flag_changed ) TO reported-PurchaseDocument.
  ENDMETHOD.

  METHOD Reject_Order.
    DATA ls_purchdocument TYPE ztg_pdoc.
* In the custom Action method for Rejecting a PurchaseDocument,
* The incoming parameter is looped and the relevant PurchaseDocument status is set as rejected and details of the Action is store in the RESULT parameter of the method
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_PurchaseDocument>).
      UPDATE ztg_pdoc SET status = 3 WHERE purchasedocument = @<fs_PurchaseDocument>-PurchaseDocument.
    ENDLOOP.
* The relevant Success Message is mapped to the REPORTED parameter of the method
    APPEND VALUE #(  purchasedocument = ls_purchdocument-purchasedocument
                         %msg = new_message( id = 'ZPURCHDOC_EXCEPTIONS' number = '003' v1 = <fs_PurchaseDocument>-PurchaseDocument    severity = if_abap_behv_message=>severity-success )
                        %element-purchasedocument = cl_abap_behv=>flag_changed ) TO reported-PurchaseDocument.

  endmethod.



ENDCLASS.
