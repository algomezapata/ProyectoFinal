CLASS lhc_Incidentes DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PUBLIC SECTION.

    CONSTANTS: BEGIN OF mc_status,
                 open        TYPE  ZE_STATUS VALUE 'OP',
                 in_progress TYPE  ZE_STATUS VALUE 'IP',
                 pending     TYPE  ZE_STATUS VALUE 'PE',
                 completed   TYPE  ZE_STATUS VALUE 'CO',
                 closed      TYPE  ZE_STATUS VALUE 'CL',
                 canceled    TYPE  ZE_STATUS VALUE 'CN',
               END OF mc_status.

  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Incidentes RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Incidentes RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Incidentes RESULT result.

    METHODS changeStatus FOR MODIFY
      IMPORTING keys FOR ACTION Incidentes~changeStatus RESULT result.

    METHODS setHistory FOR MODIFY
      IMPORTING keys FOR ACTION Incidentes~setHistory.

    METHODS setDefaultValues FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Incidentes~setDefaultValues.

    METHODS setDefaultHistory FOR DETERMINE ON SAVE
      IMPORTING keys FOR Incidentes~setDefaultHistory.

ENDCLASS.

CLASS lhc_Incidentes IMPLEMENTATION.

  METHOD get_instance_features.

*    DATA lv_historia_ind TYPE sysuuid_x16.
        READ ENTITIES OF Z_R_INC_ALGN IN LOCAL MODE
           ENTITY Incidentes
             FIELDS ( Status )
             WITH CORRESPONDING #( keys )
           RESULT DATA(incidents)
           FAILED failed.

*     Disable changeStatus for Incidents Creation
        DATA(lv_create_action) = lines( incidents ).
        IF lv_create_action EQ 1.
            data(lv_incuuid) = incidents[ 1 ]-IncUUID.
            SELECT FROM zdt_inct_h_algn
              FIELDS MAX( his_id ) AS max_his_id
              WHERE  inc_uuid EQ @lv_incuuid
                AND  his_uuid IS NOT NULL
              INTO @DATA(lv_historia_ind).
*          lv_historia_ind = get_history_index( IMPORTING ev_incuuid = incidents[ 1 ]-IncUUID ).
        ELSE.
          lv_historia_ind = 1.
        ENDIF.

        result = VALUE #( FOR incident IN incidents
                              ( %tky                   = incident-%tky
                                %action-ChangeStatus   = COND #( WHEN incident-Status = mc_status-completed OR
                                                                      incident-Status = mc_status-closed    OR
                                                                      incident-Status = mc_status-canceled  OR
                                                                      lv_historia_ind = 0
                                                                 THEN if_abap_behv=>fc-o-disabled
                                                                 ELSE if_abap_behv=>fc-o-enabled )

                                %assoc-_Historia       = COND #( WHEN incident-Status = mc_status-completed OR
                                                                     incident-Status = mc_status-closed    OR
                                                                     incident-Status = mc_status-canceled  OR
                                                                     lv_historia_ind = 0
                                                                THEN if_abap_behv=>fc-o-disabled
                                                                ELSE if_abap_behv=>fc-o-enabled )
                              ) ).

  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD changeStatus.
  ENDMETHOD.

  METHOD setHistory.
  ENDMETHOD.

  METHOD setDefaultValues.

*     Read root entity entries
        READ ENTITIES OF Z_R_INC_ALGN IN LOCAL MODE
         ENTITY Incidentes
         FIELDS ( CreationDate
                  Status ) WITH CORRESPONDING #( keys )
         RESULT DATA(incidents).

*     This important for logic
        DELETE incidents WHERE CreationDate IS NOT INITIAL.

        CHECK incidents IS NOT INITIAL.

*     Se obtiene el ultimo ID
        SELECT FROM zdt_inct_algn
          FIELDS MAX( incident_id ) AS max_inct_id
          WHERE incident_id IS NOT NULL
          INTO @DATA(lv_last_id).

        IF lv_last_id IS INITIAL.
          lv_last_id = 1.
        ELSE.
          lv_last_id += 1.
        ENDIF.

*     Modify status in Root Entity
        MODIFY ENTITIES OF Z_R_INC_ALGN IN LOCAL MODE
          ENTITY Incidentes
          UPDATE
          FIELDS ( IncidentID
                   CreationDate
                   Status )
          WITH VALUE #(  FOR incident IN incidents ( %tky = incident-%tky
                                                     IncidentID = lv_last_id
                                                     CreationDate = cl_abap_context_info=>get_system_date( )
                                                     Status       = mc_status-open )  ).

  ENDMETHOD.

  METHOD setDefaultHistory.
  ENDMETHOD.

ENDCLASS.
