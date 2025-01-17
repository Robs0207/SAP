CLASS LHC_BOOKING DEFINITION INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    METHODS:
      CALCULATEBOOKINGID FOR DETERMINE ON SAVE
        IMPORTING
          KEYS FOR  Booking~CalculateBookingID ,
      calculateTotalPrice FOR DETERMINE ON MODIFY
            IMPORTING keys FOR Booking~calculateTotalPrice.
ENDCLASS.

CLASS LHC_BOOKING IMPLEMENTATION.
  METHOD CALCULATEBOOKINGID.
  ENDMETHOD.
  METHOD calculateTotalPrice.

    " Read all parent UUIDs
    READ ENTITIES OF ZI_FE_Travel_001587 IN LOCAL MODE
    ENTITY Booking BY \_Travel
        FIELDS ( TravelUUID  )
        WITH CORRESPONDING #(  keys  )
    RESULT DATA(travels).

    " Trigger Re-Calculation on Root Node
    MODIFY ENTITIES OF ZI_FE_Travel_001587 IN LOCAL MODE
    ENTITY Travel
        EXECUTE reCalcTotalPrice
        FROM CORRESPONDING  #( travels ).

  ENDMETHOD.

ENDCLASS.
