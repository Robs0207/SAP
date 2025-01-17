CLASS lhc_travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      calculatetravelid FOR DETERMINE ON SAVE
        IMPORTING
          keys FOR  Travel~CalculateTravelID ,
      reCalcTotalPrice FOR MODIFY
        IMPORTING keys FOR ACTION Travel~reCalcTotalPrice,
      calculateTotalPrice FOR DETERMINE ON MODIFY
            IMPORTING keys FOR Travel~calculateTotalPrice.
ENDCLASS.

CLASS lhc_travel IMPLEMENTATION.

  METHOD calculatetravelid.
  ENDMETHOD.

  METHOD reCalcTotalPrice.

    TYPES: BEGIN OF ty_amount_per_currencycode,
             amount        TYPE /dmo/total_price,
             currency_code TYPE /dmo/currency_code,
           END OF ty_amount_per_currencycode.

    DATA: amount_per_currencycode TYPE STANDARD TABLE OF ty_amount_per_currencycode.

    " Read all relevant travel instances.
    READ ENTITIES OF ZI_FE_Travel_001587 IN LOCAL MODE
        ENTITY Travel
            FIELDS ( BookingFee CurrencyCode )
            WITH CORRESPONDING #( keys )
        RESULT DATA(travels).

    DELETE travels WHERE CurrencyCode IS INITIAL.

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      " Set the start for the calculation by adding the booking fee.
      amount_per_currencycode = VALUE #( ( amount        = <travel>-BookingFee
                                          currency_code = <travel>-CurrencyCode ) ).

      " Read all associated bookings and add them to the total price.
      READ ENTITIES OF ZI_FE_Travel_001587 IN LOCAL MODE
          ENTITY Travel BY \_Booking
          FIELDS ( FlightPrice CurrencyCode )
          WITH VALUE #( ( %tky = <travel>-%tky ) )
          RESULT DATA(bookings).

      LOOP AT bookings INTO DATA(booking) WHERE CurrencyCode IS NOT INITIAL.
        COLLECT VALUE ty_amount_per_currencycode( amount        = booking-FlightPrice
                currency_code = booking-CurrencyCode ) INTO amount_per_currencycode.
      ENDLOOP.


      CLEAR <travel>-TotalPrice.
      LOOP AT amount_per_currencycode INTO DATA(single_amount_per_currencycode).
        " If needed do a Currency Conversion
        IF single_amount_per_currencycode-currency_code = <travel>-CurrencyCode.
          <travel>-TotalPrice += single_amount_per_currencycode-amount.
        ELSE.
          /dmo/cl_flight_amdp=>convert_currency(
              EXPORTING
              iv_amount                   =  single_amount_per_currencycode-amount
              iv_currency_code_source     =  single_amount_per_currencycode-currency_code
              iv_currency_code_target     =  <travel>-CurrencyCode
              iv_exchange_rate_date       =  cl_abap_context_info=>get_system_date( )
          IMPORTING
              ev_amount                   = DATA(total_booking_price_per_curr)
          ).
          <travel>-TotalPrice += total_booking_price_per_curr.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    " write back the modified total_price of travels
    MODIFY ENTITIES OF ZI_FE_Travel_001587 IN LOCAL MODE
    ENTITY travel
        UPDATE FIELDS ( TotalPrice )
        WITH CORRESPONDING #( travels ).

  ENDMETHOD.

  METHOD calculateTotalPrice.

    MODIFY ENTITIES OF ZI_FE_Travel_001587 IN LOCAL MODE
        ENTITY Travel
        EXECUTE reCalcTotalPrice
        FROM CORRESPONDING #( keys ).

  ENDMETHOD.

ENDCLASS.
