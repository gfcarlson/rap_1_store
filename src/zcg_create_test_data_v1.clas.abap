CLASS zcg_create_test_data_v1 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PROTECTED SECTION.
  PRIVATE SECTION.

    METHODS clean.
    METHODS create_purchase_documents.
    METHODS create_purchase_document_items.
    METHODS create_purch_doc_vendors.
    METHODS create_purch_doc_priorities.
    METHODS create_purch_doc_status.
    METHODS create_purch_organization.

ENDCLASS.



CLASS zcg_create_test_data_v1 IMPLEMENTATION.

  METHOD create_purchase_documents.
    DATA: lt_purch_docs TYPE STANDARD TABLE OF ztg_pdoc.
    DATA: lv_doc_1 TYPE sysuuid_x16,
          lv_doc_2 TYPE sysuuid_x16,
          lv_doc_3 TYPE sysuuid_x16.

    DATA lv_time_stamp_utc TYPE timestampl.
    GET TIME STAMP FIELD lv_time_stamp_utc.

    lv_doc_1 = CONV sysuuid_x16( '00112233445566778899AABBCCDDEE01' ).
    lv_doc_2 = CONV sysuuid_x16( '00112233445566778899AABBCCDDEE02' ).
    lv_doc_3 = CONV sysuuid_x16( '00112233445566778899AABBCCDDEE03' ).

    lt_purch_docs = VALUE #(
    ( purchasedocument = lv_doc_1 crea_uname = 'John Doe' crea_date_time = lv_time_stamp_utc description = 'Company Car Purchase' status = '1' priority = '1'
    lchg_date_time = lv_time_stamp_utc lchg_uname = 'John Doe' purchasingorganization = 'ORG1' purchasedocumentimageurl = './images/car.jpg'  )
    ( purchasedocument = lv_doc_2 crea_uname = 'Marissa May' crea_date_time = lv_time_stamp_utc description = 'Hardware Purchase' status = '1' priority = '2'
    lchg_date_time = lv_time_stamp_utc lchg_uname = 'Marissa May' purchasingorganization = 'ORG2' purchasedocumentimageurl = './images/laptop.jpg'   )
    ( purchasedocument = lv_doc_3 crea_uname = 'Mike Smith' crea_date_time = lv_time_stamp_utc description = 'Book Purchase' status = '1'  priority = '3'
    lchg_date_time = lv_time_stamp_utc lchg_uname = 'Mike Smith' purchasingorganization = 'ORG3' purchasedocumentimageurl = './images/book.jpg'  ) ).

    INSERT ztg_pdoc FROM TABLE @lt_purch_docs.
  ENDMETHOD.


  METHOD create_purchase_document_items.
    DATA: lt_purch_doc_items TYPE STANDARD TABLE OF ztg_pitem.
    DATA: lv_doc_1 TYPE sysuuid_x16,
          lv_doc_2 TYPE sysuuid_x16,
          lv_doc_3 TYPE sysuuid_x16.

    DATA lv_time_stamp_utc TYPE timestampl.
    GET TIME STAMP FIELD lv_time_stamp_utc.

    lv_doc_1 = CONV sysuuid_x16( '00112233445566778899AABBCCDDEE01' ).
    lv_doc_2 = CONV sysuuid_x16( '00112233445566778899AABBCCDDEE02' ).
    lv_doc_3 = CONV sysuuid_x16( '00112233445566778899AABBCCDDEE03' ).

    lt_purch_doc_items = VALUE #(
      ( purchasedocument             = lv_doc_1
        purchasedocumentitem         = CONV sysuuid_x16( '10112233445566778899AABBCCDDEE01' )
        crea_uname                   = 'John Doe'
        crea_date_time               = lv_time_stamp_utc
        description                  = 'Tires'
        price                        = '300.00'
        currency                     = 'EUR'
        quantity                     = '4'
        quantityunit                 = 'EA'
        vendor                       = 'Miller Cars'
        vendortype                   = 'E'
        lchg_date_time               = lv_time_stamp_utc
        lchg_uname                   = 'John Doe'
        pdoc_item_image_url = './images/car.jpg' )
      ( purchasedocument             = lv_doc_1
        purchasedocumentitem         = CONV sysuuid_x16( '10112233445566778899AABBCCDDEE02' )
        crea_uname                   = 'John Doe'
        crea_date_time               = lv_time_stamp_utc
        description                  = 'Company Car'
        price                        = '40000'
        currency                     = 'EUR'
        quantity                     = '1'
        quantityunit                 = 'EA'
        vendor                       = 'Miller Cars'
        vendortype                   = 'E'
        lchg_date_time               = lv_time_stamp_utc
        lchg_uname                   = 'John Doe'
        pdoc_item_image_url = './images/car.jpg' )
      ( purchasedocument             = lv_doc_2
        purchasedocumentitem         = CONV sysuuid_x16( '10112233445566778899AABBCCDDEE03' )
        crea_uname                   = 'Marissa May'
        crea_date_time               = lv_time_stamp_utc
        description                  = 'Screen'
        price                        = '200.00'
        currency                     = 'EUR'
        quantity                     = '2'
        quantityunit                 = 'EA'
        vendor                       = 'Doe Computers'
        vendortype                   = 'Q'
        lchg_date_time               = lv_time_stamp_utc
        lchg_uname                   = 'Marissa May'
        pdoc_item_image_url = './images/screen.jpg' )
      ( purchasedocument             = lv_doc_2
        purchasedocumentitem         = CONV sysuuid_x16( '10112233445566778899AABBCCDDEE04' )
        crea_uname                   = 'Marissa May'
        crea_date_time               = lv_time_stamp_utc
        description                  = 'Keyboard'
        price                        = '100.00'
        currency                     = 'EUR'
        quantity                     = '1'
        quantityunit                 = 'EA'
        vendor                       = 'Doe Computers'
        vendortype                   = 'I'
        lchg_date_time               = lv_time_stamp_utc
        lchg_uname                   = 'Marissa May'
        pdoc_item_image_url = './images/keyboard.jpg' )
      ( purchasedocument             = lv_doc_2
        purchasedocumentitem         = CONV sysuuid_x16( '10112233445566778899AABBCCDDEE05' )
        crea_uname                   = 'Marissa May'
        crea_date_time               = lv_time_stamp_utc
        description                  = 'Mouse'
        price                        = '50.00'
        currency                     = 'EUR'
        quantity                     = '1'
        quantityunit                 = 'EA'
        vendor                       = 'Doe Computers'
        vendortype                   = 'I'
        lchg_date_time               = lv_time_stamp_utc
        lchg_uname                   = 'Marissa May'
        pdoc_item_image_url = '../images/mouse.jpg' )
      ( purchasedocument             = lv_doc_2
        purchasedocumentitem         = CONV sysuuid_x16( '10112233445566778899AABBCCDDEE06' )
        crea_uname                   = 'Marissa May'
        crea_date_time               = lv_time_stamp_utc
        description                  = 'Computer'
        price                        = '500.00'
        currency                     = 'EUR'
        quantity                     = '1'
        quantityunit                 = 'EA'
        vendor                       = 'Doe Computers'
        vendortype                   = 'P'
        lchg_date_time               = lv_time_stamp_utc
        lchg_uname                   = 'Marissa May'
        pdoc_item_image_url = './images/laptop.jpg' )
      ( purchasedocument             = lv_doc_3
        purchasedocumentitem         = CONV sysuuid_x16( '10112233445566778899AABBCCDDEE07' )
        crea_uname                   = 'Mike Smith'
        crea_date_time               = lv_time_stamp_utc
        description                  = 'SAP Press - Fiori'
        price                        = '50.00'
        currency                     = 'EUR'
        quantity                     = '1'
        quantityunit                 = 'EA'
        vendor                       = 'SAP Press'
        vendortype                   = 'E'
        lchg_date_time               = lv_time_stamp_utc
        lchg_uname                   = 'Mike Smith'
        pdoc_item_image_url = './images/book.jpg' )
      ( purchasedocument             = lv_doc_3
        purchasedocumentitem         = CONV sysuuid_x16( '10112233445566778899AABBCCDDEE08' )
        crea_uname                   = 'Mike Smith'
        crea_date_time               = lv_time_stamp_utc
        description                  = 'SAP Press - HANA'
        price                        = '50.00'
        currency                     = 'EUR'
        quantity                     = '1'
        quantityunit                 = 'EA'
        vendor                       = 'SAP Press'
        vendortype                   = 'I'
        lchg_date_time               = lv_time_stamp_utc
        lchg_uname                   = 'Mike Smith'
        pdoc_item_image_url = './images/book.jpg' ) ).

    INSERT ztg_pitem FROM TABLE @lt_purch_doc_items.
  ENDMETHOD.


  METHOD create_purch_doc_priorities.
    DATA: lt_purch_doc_prios TYPE STANDARD TABLE OF ztg_priority.

    lt_purch_doc_prios = VALUE #(
      ( priority = '1' prioritytext = 'High' )
      ( priority = '2' prioritytext = 'Medium' )
      ( priority = '3' prioritytext = 'Low' )
     ).

    INSERT ztg_priority FROM TABLE @lt_purch_doc_prios.
  ENDMETHOD.

  METHOD create_purch_doc_vendors.
    DATA: lt_purch_doc_vendor TYPE STANDARD TABLE OF ztg_vendor_type.

    lt_purch_doc_vendor = VALUE #(
      ( vendortype = 'E' vendortypetext = 'External' )
      ( vendortype = 'I' vendortypetext = 'Internal' )
      ( vendortype = 'Q' vendortypetext = 'Quota' )
      ( vendortype = 'P' vendortypetext = 'Preffered' )
     ).

    INSERT ztg_vendor_type FROM TABLE @lt_purch_doc_vendor.
  ENDMETHOD.

  METHOD create_purch_doc_status.
    DATA: lt_purch_doc_status TYPE STANDARD TABLE OF ztg_pdoc_status.

    lt_purch_doc_status = VALUE #(
      ( status = '1' statustext = 'Created' )
      ( status = '2' statustext = 'Approved' )
      ( status = '3' statustext = 'Closed' )
     ).

    INSERT ztg_pdoc_status FROM TABLE @lt_purch_doc_status.
  ENDMETHOD.

  METHOD create_purch_organization.
    DATA: lt_purch_org TYPE STANDARD TABLE OF ztg_purch_org.

    lt_purch_org = VALUE #(
      ( purchasingorganization = 'ORG1' description = 'Purchasing Organization 1' emailaddress = 'purchorg1@org.com' phonenumber = '0035235-2364646' faxnumber = '342623-2575472' )
      ( purchasingorganization = 'ORG2' description = 'Purchasing Organization 2' emailaddress = 'purchorg2@org.com'  phonenumber = '0035235-3461347' faxnumber = '342623-43634' )
      ( purchasingorganization = 'ORG3' description = 'Purchasing Organization 3' emailaddress = 'purchorg3@org.com' phonenumber = '0035235-575347' faxnumber = '342623-327545427' )
     ).

    INSERT ztg_purch_org FROM TABLE @lt_purch_org.
  ENDMETHOD.


  METHOD clean.
    DELETE FROM ztg_pdoc.
    DELETE FROM ztg_pitem.
    DELETE FROM ztg_vendor_type.
    DELETE FROM ztg_priority.
    DELETE FROM ztg_pdoc_status.
    DELETE FROM ztg_purch_org.
    DELETE FROM ztg_pitem_d.
    DELETE FROM ztg_pdoc_d.
  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.
    clean( ).
    create_purchase_documents( ).
   create_purchase_document_items( ).
    create_purch_doc_vendors( ).
    create_purch_doc_priorities( ).
    create_purch_doc_status( ).
    create_purch_organization( ).


    out->write(
      EXPORTING
        data   = 'Test data creation done.'
    ).

  ENDMETHOD.





ENDCLASS.

