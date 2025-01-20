CLASS zcl_http_work_order DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_http_service_extension.
  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS: get_html RETURNING VALUE(html) TYPE string.
    METHODS: post_html
      IMPORTING
                salesorderno TYPE string
      RETURNING VALUE(html)  TYPE string.

    CLASS-DATA url TYPE string.
ENDCLASS.



CLASS ZCL_HTTP_WORK_ORDER IMPLEMENTATION.


  METHOD get_html.    "Response HTML for GET request

    html = |<html> \n| &&
  |<body> \n| &&
  |<title>Works Order </title> \n| &&
  |<form action="{ url }" method="POST">\n| &&
  |<H2>GTZ Works Order Print</H2> \n| &&
  |<label for="fname">Works Order:  </label> \n| &&
  |<input type="text" id="salesorderno" name="salesorderno" required ><br><br> \n| &&
  |<input type="submit" value="Submit"> \n| &&
  |</form> | &&
  |</body> \n| &&
  |</html> | .





  ENDMETHOD.


  METHOD if_http_service_extension~handle_request.

*    DATA(req) = request->get_form_fields(  ).
*    response->set_header_field( i_name = 'Access-Control-Allow-Origin' i_value = '*' ).
*    response->set_header_field( i_name = 'Access-Control-Allow-Credentials' i_value = 'true' ).
*
*    DATA json TYPE string .
*    DATA salesorderno TYPE string.
*    DATA salesorder TYPE n LENGTH 10.
*
*    salesorderno = VALUE #( req[ name = 'salesorderno' ]-value OPTIONAL ) .
*
*    json =  VALUE #( req[ name = 'json' ]-value OPTIONAL ) .
*    salesorder = salesorderno .
*
*    SELECT SINGLE * FROM i_salesdocumentitem WITH PRIVILEGED ACCESS WHERE salesdocument = @salesorder
*    INTO @DATA(check).
*    IF check IS NOT INITIAL .
*      DATA(pdf2) = ywk_or_print_class=>read_posts( salesorderno = salesorderno ) .
*    ELSE .
*      pdf2 = 'Error Please Check Plant'.
*    ENDIF.
    DATA(req) = request->get_form_fields(  ).
    response->set_header_field( i_name = 'Access-Control-Allow-Origin' i_value = '*' ).
    response->set_header_field( i_name = 'Access-Control-Allow-Credentials' i_value = 'true' ).
    DATA(cookies)  = request->get_cookies(  ) .

    DATA req_host TYPE string.
    DATA req_proto TYPE string.
    DATA req_uri TYPE string.
    DATA json TYPE string .

    req_host = request->get_header_field( i_name = 'Host' ).
    req_proto = request->get_header_field( i_name = 'X-Forwarded-Proto' ).
    IF req_proto IS INITIAL.
      req_proto = 'https'.
    ENDIF.
*     req_uri = request->get_request_uri( ).
    DATA(symandt) = sy-mandt.
    req_uri = '/sap/bc/http/sap/ZHTTP_WORKSORDER_PRINT?sap-client=080'.
    url = |{ req_proto }://{ req_host }{ req_uri }client={ symandt }|.


    CASE request->get_method( ).

      WHEN CONV string( if_web_http_client=>get ).

        response->set_text( get_html( ) ).

      WHEN CONV string( if_web_http_client=>post ).

        DATA(vbeln) = request->get_form_field( `salesorderno` ).

        SELECT SINGLE FROM I_salesdocument
        FIELDS SalesDocument WHERE SalesDocument = @vbeln
        INTO @DATA(lv_so).

        IF lv_so IS NOT INITIAL.

          TRY.
              DATA(pdf) = ywk_or_print_class=>read_posts( salesorderno = vbeln ) .

*            response->set_text( pdf ).

              DATA(html) = |<html> | &&
                             |<body> | &&
                               | <iframe src="data:application/pdf;base64,{ pdf }" width="100%" height="100%"></iframe>| &&
                             | </body> | &&
                           | </html>|.



              response->set_header_field( i_name = 'Content-Type' i_value = 'text/html' ).
              response->set_text( html ).
            CATCH cx_static_check INTO DATA(er).
              response->set_text( er->get_longtext(  ) ).
          ENDTRY.
        ELSE.
          response->set_text( 'Works Order does not exist.' ).
        ENDIF.

    ENDCASE.

  ENDMETHOD.


  METHOD post_html.

    html = |<html> \n| &&
   |<body> \n| &&
   |<title>Works Order</title> \n| &&
   |<form action="{ url }" method="Get">\n| &&
   |<H2>Works Order Print Success </H2> \n| &&
   |<input type="submit" value="Go Back"> \n| &&
   |</form> | &&
   |</body> \n| &&
   |</html> | .
  ENDMETHOD.
ENDCLASS.
