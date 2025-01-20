CLASS ywk_or_print_class DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .
    CLASS-DATA : access_token TYPE string .
    CLASS-DATA : xml_file TYPE string .
    CLASS-DATA : var1 TYPE vbeln.
    TYPES :
      BEGIN OF struct,
        xdp_template TYPE string,
        xml_data     TYPE string,
        form_type    TYPE string,
        form_locale  TYPE string,
        tagged_pdf   TYPE string,
        embed_font   TYPE string,
      END OF struct."


    CLASS-METHODS :
      create_client
        IMPORTING url           TYPE string
        RETURNING VALUE(result) TYPE REF TO if_web_http_client
        RAISING   cx_static_check ,

      read_posts
        IMPORTING VALUE(salesorderno) TYPE string
        RETURNING VALUE(result12)     TYPE string
        RAISING   cx_static_check .
  PROTECTED SECTION.

  PRIVATE SECTION.
    CONSTANTS lc_ads_render TYPE string VALUE '/ads.restapi/v1/adsRender/pdf'.
    CONSTANTS  lv1_url    TYPE string VALUE 'https://adsrestapi-formsprocessing.cfapps.jp10.hana.ondemand.com/v1/adsRender/pdf?templateSource=storageName&TraceLevel=2'  .
    CONSTANTS  lv2_url    TYPE string VALUE 'https://dev-tcul4uw9.authentication.jp10.hana.ondemand.com/oauth/token'  .
    CONSTANTS lc_storage_name TYPE string VALUE 'templateSource=storageName'.
    CONSTANTS lc_template_name TYPE string VALUE 'zsd_worksorder/zsd_worksorder'."'zpo/zpo_v2'."
ENDCLASS.



CLASS YWK_OR_PRINT_CLASS IMPLEMENTATION.


  METHOD create_client .
    DATA(dest) = cl_http_destination_provider=>create_by_url( url ).
    result = cl_web_http_client_manager=>create_by_http_destination( dest ).

  ENDMETHOD .


  METHOD read_posts.
*  METHOD if_oo_adt_classrun~main.
    var1 = salesorderno.
    var1 =   |{ |{ var1 ALPHA = OUT }| ALPHA = IN }| .
    salesorderno = var1.
****************************************  header data ******************************************************
    SELECT SINGLE
    a~purchaseorderbycustomer,
        a~customerpurchaseorderdate,
        a~yy1_poamendmentno_sdh,
            a~yy1_poamendmentdate_sdh,
                a~yy1_dono_sdh,
                    a~yy1_dodate_sdh,
                    b~customerName,
                    b~streetName,
                    b~BPAddrCityName,
                    b~BPAddrStreetName,
                    b~DistrictName,
                    b~postalcode,
                    b~TaxNumber3,
                    b~Region,
                    b~CustomerAccountGroup,
                    b~country,
                    a~soldtoparty,
                    a~soldtoparty AS gtz_cust_code,
                    a~salesdocument,
                    a~creationdate,
                    a~RequestedDeliveryDate,
*                    a~YY1_TCSAmount_SDH,
                    a~transactioncurrency,
                    a~YY1_Remarks_SO_sdh,
                    c~customerPaymentTermsName,
                    d~supplierName,
                    e~countryName
     FROM i_salesdocument AS a LEFT JOIN
     i_customer AS b ON a~soldtoparty = b~Customer LEFT JOIN
     I_CustomerPaymentTermsText AS c ON a~customerPaymentTerms = c~customerPaymentTerms LEFT JOIN
     i_supplier AS d ON a~yy1_TransportName_SDH = d~supplier LEFT JOIN
      i_countrytext AS e ON b~country = e~Country
    WHERE a~salesdocument EQ @salesorderno
    INTO @DATA(wa_header1).

    SELECT SINGLE
    b~customerName,
    b~streetName,
    b~BPAddrStreetName,
    b~BPAddrCityName,
    b~DistrictName,
    b~postalcode,
    b~TaxNumber3,
    b~Region,
    b~CustomerAccountGroup,
    b~country,
    c~plantname,
    c~plant,
    d~countryName
     FROM i_salesdocumentitem AS a LEFT JOIN
     i_customer AS b ON a~shiptoparty = b~Customer LEFT JOIN
     i_plant AS c ON a~plant = c~plant LEFT JOIN
     i_countrytext AS d ON b~country = d~Country
    WHERE a~salesdocument EQ  @salesorderno
    INTO @DATA(wa_header2).

*    out->write( wa_header1 ).
*    out->write( wa_header2 ).


*******************************************************    line item data  ******************************
    SELECT
    a~salesdocument,
    a~salesdocumentitem,
    a~Salesdocumentitemtext,
    a~OrderQuantity,
    a~netpricequantityunit,
    a~product,
    a~yy1_packsize_sd_sdi,
    b~consumptiontaxctrlcode
    FROM i_salesdocumentitem AS a LEFT JOIN
    i_productplantbasic AS b ON a~product = b~Product
    WHERE a~salesdocument =  @salesorderno AND consumptiontaxctrlcode IS NOT INITIAL
    INTO TABLE @DATA(it_line).

    SELECT
    c~salesdocument,
    c~salesdocumentitem,
    c~conditionratevalue,
       c~conditionamount,
       c~conditionbasevalue,
       c~conditiontype
       FROM i_salesdocitempricingelement AS c FOR ALL ENTRIES IN @it_line WHERE
       salesdocument =  @it_line-salesdocument AND salesdocumentitem =  @it_line-salesdocumentitem
       INTO TABLE @DATA(it_line2).

*    DELETE it_line where CONSUMPTIONTAXCTRLCODE is INITIAL.

*    out->write( it_line ).
*    out->write( '  ' ).
*    out->write( it_line2 ).

*************************************************    header xml ***********************************************

    DATA(lv_xml) =
    |<Form>| &&
    |<header>| &&
    |<po_no>{ wa_header1-purchaseorderbycustomer }</po_no>| &&
    |<dated1>{ wa_header1-customerpurchaseorderdate }</dated1>| &&
    |<amd_po_no>{ wa_header1-yy1_poamendmentno_sdh }</amd_po_no>| &&
    |<dated2>{ wa_header1-yy1_poamendmentdate_sdh }</dated2>| &&
    |<do_no>{ wa_header1-YY1_DONo_SDH }</do_no>| &&
    |<date>{ wa_header1-YY1_DODate_SDH }</date>| &&
    |<buyer>{ wa_header1-customerName }</buyer>| &&
    |<buyer_address1>{ wa_header1-streetName }</buyer_address1>| &&
    |<buyer_address2>{ wa_header1-BPAddrStreetName }</buyer_address2>| &&
    |<buyer_address3>{ wa_header1-DistrictName }</buyer_address3>| &&
    |<buyer_address4>{ wa_header1-postalcode }</buyer_address4>| &&
    |<buyer_address5>{ wa_header1-BPAddrCityName }</buyer_address5>| &&
    |<buyer_gstin>{ wa_header1-TaxNumber3 }</buyer_gstin>| &&
    |<buyer_state>{ wa_header1-Region }</buyer_state>| &&
    |<party_code>{ wa_header1-soldtoparty }</party_code>| &&
    |<consignee_name>{ wa_header2-customerName }</consignee_name>| &&
    |<consignee_address1>{ wa_header2-StreetName }</consignee_address1>| &&
    |<consignee_address2>{ wa_header2-BPAddrStreetName }</consignee_address2>| &&
    |<consignee_address3>{ wa_header2-DistrictName }</consignee_address3>| &&
    |<consignee_address4>{ wa_header2-PostalCode }</consignee_address4>| &&
    |<consignee_address5>{ wa_header2-BPAddrCityName }</consignee_address5>| &&
    |<consignee_gstin>{ wa_header2-TaxNumber3 }</consignee_gstin>| &&
    |<consignee_state>{ wa_header2-Region }</consignee_state>| &&
    |<gtz_customer_code>{ wa_header1-gtz_cust_code }</gtz_customer_code>| &&
    |<work_order_no>{ wa_header1-salesdocument }</work_order_no>| &&
    |<work_order_date>{ wa_header1-CreationDate }</work_order_date>| &&
    |<c_c>{ wa_header2-PlantName }</c_c>| &&
    |<plant>{ wa_header2-Plant }</plant>| &&
    |<tr_currency>{ wa_header1-TransactionCurrency }</tr_currency>| &&
    |<remarks>{ wa_header1-YY1_Remarks_SO_sdh }</remarks>|.

    IF wa_header1-CustomerAccountGroup = 'ZEXP'.
      DATA(lv_xml_cn_buyer) =
      |<buyer_country>{ wa_header1-countryName }</buyer_country>|.
    ELSE.
      lv_xml_cn_buyer = |<buyer_country></buyer_country>|.
    ENDIF.

    IF wa_header2-CustomerAccountGroup = 'ZEXP'.
      DATA(lv_xml_cn_consignee) =
      |<consignee_country>{ wa_header2-countryName }</consignee_country>|.
    ELSE.
      lv_xml_cn_consignee = |<consignee_country></consignee_country>|.
    ENDIF.
    DATA(lv_header_last) =
    |</header>| &&
    |<lineItem>|.

    CONCATENATE lv_xml lv_xml_cn_buyer lv_xml_cn_consignee lv_header_last INTO lv_xml.

***********************************************    line item xml   ***************************************************

    DATA r_flag TYPE i VALUE 0.
    DATA d_flag TYPE i VALUE 0.
    DATA i_flag TYPE i VALUE 0.
    DATA c_s_flag TYPE i VALUE 0.
    DATA value_of_sup TYPE i_salesdocumentitem-OrderQuantity.
    DATA taxable_value TYPE i_salesdocumentitem-OrderQuantity.
    DATA discount TYPE i_salesdocitempricingelement-conditionratevalue.
    DATA rounding_off TYPE i_salesdocitempricingelement-ConditionAmount.
    DATA freight_amt TYPE i_salesdocitempricingelement-ConditionAmount.
    DATA Insurance_amt TYPE i_salesdocitempricingelement-ConditionAmount.
    DATA tcs_amount TYPE i_salesdocitempricingelement-ConditionAmount.

    LOOP AT it_line INTO DATA(wa_line).
      data(reverse_string) = reverse( wa_line-Salesdocumentitemtext ).
      DATA(lv_pos) = FIND( val = reverse_string sub = '-' ).
      data(length) = STRLEN( reverse_string ) - ( lv_pos + 1 ).
      lv_pos = lv_pos + 1.
      data(temp_data) = reverse_string+lv_pos(length).
      temp_data = reverse( temp_data ).

      DATA(lv_xml1) =
      |<item>| &&
      |<Description>{ temp_data }</Description>| &&
      |<HSN>{ wa_line-consumptiontaxctrlcode }</HSN>| &&
      |<quantity>{ wa_line-OrderQuantity }</quantity>| &&
      |<uom>{ wa_line-netpricequantityunit }</uom>| &&
      |<pack_size>{ wa_line-yy1_packsize_sd_sdi }</pack_size>|.


      LOOP AT it_line2 INTO DATA(wa_line2) WHERE salesdocument = wa_line-salesdocument AND salesdocumentitem = wa_line-salesdocumentitem.
        IF wa_line2-ConditionType = 'ZBSP' OR wa_line2-ConditionType = 'ZEXP'.
          DATA(lv_xml1_rate) =
          |<rate>{ wa_line2-conditionratevalue }</rate>|.
          value_of_sup = wa_line-OrderQuantity * wa_line2-conditionratevalue.
          r_flag = 1.
        ELSEIF wa_line2-ConditionType = 'ZDIS'.
          IF wa_line2-conditionratevalue < 0.
            discount = wa_line2-conditionratevalue * -1.
          ELSE.
            discount = wa_line2-conditionratevalue.
          ENDIF.
          DATA(lv_xml1_dis) =
         |<discount>{ discount }</discount>|.
          d_flag = 1.
        ELSEIF wa_line2-ConditionType = 'JOIG'.
          DATA(lv_xml1_igst) =
           |<igst_rate>{ wa_line2-conditionratevalue }</igst_rate>| &&
           |<igst_amount>{ wa_line2-conditionamount }</igst_amount>|.
          i_flag = 1.
        ELSEIF wa_line2-ConditionType = 'JOCG' OR wa_line2-ConditionType = 'JOSG'.
          DATA(lv_xml1_cgst_sgst) =
           |<cgst_rate>{ wa_line2-conditionratevalue }</cgst_rate>| &&
           |<cgst_amount>{ wa_line2-conditionamount }</cgst_amount>| &&
           |<sgst_rate>{ wa_line2-conditionratevalue }</sgst_rate>| &&
           |<sgst_amount>{ wa_line2-conditionamount }</sgst_amount>|.
          c_s_flag = 1.
        ENDIF.
        IF wa_line2-ConditionType = 'ZDIF'.
          rounding_off = rounding_off + wa_line2-ConditionAmount.
        ENDIF.
        IF wa_line2-ConditionType = 'ZFRT' OR wa_line2-ConditionType = 'ZEFC'.
          Freight_amt = Freight_amt + wa_line2-ConditionAmount.
        ENDIF.
        IF wa_line2-ConditionType = 'ZINC' OR wa_line2-ConditionType = 'ZINP' OR wa_line2-ConditionType = 'ZINS' OR  wa_line2-ConditionType = 'ZENS'.
          Insurance_amt = Insurance_amt + wa_line2-ConditionAmount.
        ENDIF.
        IF wa_line2-ConditionType = 'JTC1'.
          tcs_amount += wa_line2-ConditionAmount.
        ENDIF.
      ENDLOOP.

      IF value_of_sup IS NOT INITIAL.
        taxable_value = value_of_sup - ( value_of_sup * discount ) / 100.
      ENDIF.
      IF r_flag = 0.
        lv_xml1_rate = |<rate></rate>|.
      ENDIF.
      IF d_flag = 0.
        lv_xml1_dis =
            |<discount></discount>|.
      ENDIF.
      IF i_flag = 0.
        lv_xml1_igst =
             |<igst_rate></igst_rate>| &&
             |<igst_amount></igst_amount>|.
      ENDIF.
      IF c_s_flag = 0.
        lv_xml1_cgst_sgst =
             |<cgst_rate></cgst_rate>| &&
             |<cgst_amount></cgst_amount>| &&
             |<sgst_rate></sgst_rate>| &&
             |<sgst_amount></sgst_amount>|.
      ENDIF.

      DATA(lv_xml_gross) =
      |<value_of_sup>{ value_of_sup }</value_of_sup>| &&
      |<taxable_value>{ taxable_value }</taxable_value>| &&
      |</item>|.

      CONCATENATE lv_xml lv_xml1 lv_xml1_rate lv_xml1_dis lv_xml1_igst lv_xml1_cgst_sgst lv_xml_gross INTO lv_xml.
      r_flag = 0.
      d_flag = 0.
      i_flag = 0.
      c_s_flag = 0.
      CLEAR value_of_sup.
      CLEAR taxable_value.
    ENDLOOP.
    DATA(lv_xml2) =
    |</lineItem>| &&
    |<footer>| &&
    |<freight_amt>{ Freight_amt }</freight_amt>| &&
    |<insurance_amt>{ Insurance_amt }</insurance_amt>| &&
    |<rounding_off>{ rounding_off }</rounding_off>| &&
    |<tcs_amount>{ tcs_amount }</tcs_amount>| &&
    |<expected_despatch></expected_despatch>| &&
    |<expected_del>{ wa_header1-RequestedDeliveryDate }</expected_del>| &&
    |<payment_terms>{ wa_header1-customerPaymentTermsName }</payment_terms>| &&
    |<despatch_terms></despatch_terms>| &&
    |<transport_name>{ wa_header1-supplierName }</transport_name>|.
    CONCATENATE lv_xml lv_xml2 INTO lv_xml.

*************************************************    footer xml  *************************************************
    DATA(lv_xml_last) =
    |</footer>| &&
    |</Form>|.
    CONCATENATE lv_xml lv_xml_last INTO lv_xml.
*    out->write( lv_xml ).

*
    CALL METHOD ycl_test_adobe2=>getpdf(
      EXPORTING
        xmldata  = lv_xml
        template = lc_template_name
      RECEIVING
        result   = result12 ).

  ENDMETHOD.
ENDCLASS.
