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

interfaces: if_oo_adt_classrun.

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
    METHODS validateCreationDate FOR VALIDATE ON SAVE
      IMPORTING keys FOR Incidentes~validateCreationDate.

    METHODS validateDescription FOR VALIDATE ON SAVE
      IMPORTING keys FOR Incidentes~validateDescription.

    METHODS validatePriority FOR VALIDATE ON SAVE
      IMPORTING keys FOR Incidentes~validatePriority.

    METHODS validateTitle FOR VALIDATE ON SAVE
      IMPORTING keys FOR Incidentes~validateTitle.
    METHODS validateStatus FOR VALIDATE ON SAVE
      IMPORTING keys FOR Incidentes~validateStatus.

ENDCLASS.

CLASS lhc_Incidentes IMPLEMENTATION.

  METHOD get_instance_features.


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

*        result = VALUE #( FOR incident IN incidents
*                              ( %tky                   = incident-%tky
*                                %action-ChangeStatus   = COND #( WHEN incident-Status = mc_status-completed OR
*                                                                      incident-Status = mc_status-closed    OR
*                                                                      incident-Status = mc_status-canceled  OR
*                                                                      lv_historia_ind = 0
*                                                                 THEN if_abap_behv=>fc-o-disabled
*                                                                 ELSE if_abap_behv=>fc-o-enabled )
*
*                                %assoc-_Historia       = COND #( WHEN incident-Status = mc_status-completed OR
*                                                                     incident-Status = mc_status-closed    OR
*                                                                     incident-Status = mc_status-canceled  OR
*                                                                     lv_historia_ind = 0
*                                                                THEN if_abap_behv=>fc-o-disabled
*                                                                ELSE if_abap_behv=>fc-o-enabled )
*                              ) ).

  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD changeStatus.

*     Declaration of necessary variables
        DATA: lt_updated_root_entity TYPE TABLE FOR UPDATE Z_R_INC_ALGN,
              lt_association_entity  TYPE TABLE FOR CREATE Z_R_INC_ALGN\_Historia,
              lv_status              TYPE ze_status,
              lv_text                TYPE ze_text,
              lv_exception           TYPE string,
              lv_error               TYPE c,
              ls_incidente_hist      TYPE zdt_inct_h_algn,
              lv_max_his_id          TYPE ZE_HIS_ID,
              lv_wrong_status        TYPE ze_status.

*    * Iterate through the keys records to get parameters for validations
        READ ENTITIES OF Z_R_INC_ALGN IN LOCAL MODE
             ENTITY Incidentes
             ALL FIELDS WITH CORRESPONDING #( keys )
             RESULT DATA(incidentes)
             FAILED failed.

*    * Get parameters
        LOOP AT incidentes ASSIGNING FIELD-SYMBOL(<incident>).
*    * Get Status
          lv_status = keys[ KEY id %tky = <incident>-%tky ]-%param-status.

*    *  It is not possible to change the pending (PE) to Completed (CO) or Closed (CL) status
          IF <incident>-Status EQ mc_status-pending AND lv_status EQ mc_status-closed OR
             <incident>-Status EQ mc_status-pending AND lv_status EQ mc_status-completed.
*    * Set authorizations
            APPEND VALUE #( %tky = <incident>-%tky ) TO failed-incidentes.

            lv_wrong_status = lv_status.
*     Customize error messages
*            APPEND VALUE #( %tky = <incident>-%tky
*                            %msg = NEW zcl_incident_messages_lgl( textid = zcl_incident_messages_lgl=>status_invalid
*                                                                status = lv_wrong_status
*                                                                severity = if_abap_behv_message=>severity-error )
*                            %state_area = 'VALIDATE_COMPONENT'
*                             ) TO reported-incidentes.


            lv_error = abap_true.
            EXIT.
          ENDIF.

          APPEND VALUE #( %tky = <incident>-%tky
                          ChangedDate = cl_abap_context_info=>get_system_date( )
                          Status = lv_status ) TO lt_updated_root_entity.

*    * Get Text
          lv_text = keys[ KEY id %tky = <incident>-%tky ]-%param-text.

            SELECT FROM zdt_inct_h_algn
              FIELDS MAX( his_id ) AS max_his_id
              WHERE  inc_uuid EQ @<incident>-IncUUID
                AND  his_uuid IS NOT NULL
              INTO @DATA(lv_historia_ind).

*          lv_max_his_id = get_history_index(
*                      IMPORTING
*                        ev_incuuid = <incident>-IncUUID ).

          IF lv_historia_ind IS INITIAL.
            ls_incidente_hist-his_id = 1.
          ELSE.
            ls_incidente_hist-his_id = lv_historia_ind + 1.
          ENDIF.

          ls_incidente_hist-new_status = lv_status.
          ls_incidente_hist-text = lv_text.

          TRY.
              ls_incidente_hist-inc_uuid = cl_system_uuid=>create_uuid_x16_static( ).
            CATCH cx_uuid_error INTO DATA(lo_error).
              lv_exception = lo_error->get_text(  ).
          ENDTRY.

          IF ls_incidente_hist-his_id IS NOT INITIAL.
*
            APPEND VALUE #( %tky = <incident>-%tky
                            %target = VALUE #( (  HisUUID = ls_incidente_hist-inc_uuid
                                                  IncUUID = <incident>-IncUUID
                                                  HisID = ls_incidente_hist-his_id
                                                  PreviousStatus = <incident>-Status
                                                  NewStatus = ls_incidente_hist-new_status
                                                  Text = ls_incidente_hist-text ) )
                                                   ) TO lt_association_entity.
          ENDIF.
        ENDLOOP.
        UNASSIGN <incident>.

*    * The process is interrupted because a change of status from pending (PE) to Completed (CO) or Closed (CL) is not permitted.
        CHECK lv_error IS INITIAL.

*    * Modify status in Root Entity
        MODIFY ENTITIES OF Z_R_INC_ALGN IN LOCAL MODE
        ENTITY Incidentes
        UPDATE  FIELDS ( ChangedDate
                         Status )
        WITH lt_updated_root_entity.

        FREE incidentes. " Free entries in incidents

        MODIFY ENTITIES OF Z_R_INC_ALGN IN LOCAL MODE
         ENTITY Incidentes
         CREATE BY \_Historia FIELDS ( HisUUID
                                      IncUUID
                                      HisID
                                      PreviousStatus
                                      NewStatus
                                      Text )
            AUTO FILL CID
            WITH lt_association_entity
         MAPPED mapped
         FAILED failed
         REPORTED reported.

*    * Read root entity entries updated
        READ ENTITIES OF Z_R_INC_ALGN IN LOCAL MODE
        ENTITY Incidentes
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT incidentes
        FAILED failed.

*    * Update User Interface
        result = VALUE #( FOR incident IN incidentes ( %tky = incident-%tky
                                                      %param = incident ) ).


  ENDMETHOD.

  METHOD setHistory.

** Declaration of necessary variables
    DATA: lt_updated_root_entity TYPE TABLE FOR UPDATE Z_R_INC_ALGN,
          lt_association_entity  TYPE TABLE FOR CREATE Z_R_INC_ALGN\_Historia,
          lv_exception           TYPE string,
          ls_incidente_hist    TYPE zdt_inct_h_algn.

** Iterate through the keys records to get parameters for validations
    READ ENTITIES OF Z_R_INC_ALGN IN LOCAL MODE
         ENTITY Incidentes
         ALL FIELDS WITH CORRESPONDING #( keys )
         RESULT DATA(incidentes).

** Get parameters
    LOOP AT incidentes ASSIGNING FIELD-SYMBOL(<incident>).
            SELECT FROM zdt_inct_h_algn
              FIELDS MAX( his_id ) AS max_his_id
              WHERE  inc_uuid EQ @<incident>-IncUUID
                AND  his_uuid IS NOT NULL
              INTO @DATA(lv_historia_ind).


      IF lv_historia_ind IS INITIAL.
        ls_incidente_hist-his_id = 1.
      ELSE.
        ls_incidente_hist-his_id = lv_historia_ind + 1.
      ENDIF.

      TRY.
          ls_incidente_hist-inc_uuid = cl_system_uuid=>create_uuid_x16_static( ).
        CATCH cx_uuid_error INTO DATA(lo_error).
          lv_exception = lo_error->get_text(  ).
      ENDTRY.

      IF ls_incidente_hist-his_id IS NOT INITIAL.
        APPEND VALUE #( %tky = <incident>-%tky
                        %target = VALUE #( (  HisUUID = ls_incidente_hist-inc_uuid
                                              IncUUID = <incident>-IncUUID
                                              HisID = ls_incidente_hist-his_id
                                              NewStatus = <incident>-Status
                                              Text = 'First Incident' ) )
                                               ) TO lt_association_entity.
      ENDIF.
    ENDLOOP.
    UNASSIGN <incident>.

    FREE incidentes. " Free entries in incidents

    MODIFY ENTITIES OF Z_R_INC_ALGN IN LOCAL MODE
     ENTITY Incidentes
     CREATE BY \_Historia FIELDS ( HisUUID
                                  IncUUID
                                  HisID
                                  PreviousStatus
                                  NewStatus
                                  Text )
        AUTO FILL CID
        WITH lt_association_entity.

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

** Execute internal action to update Flight Date
    MODIFY ENTITIES OF Z_R_INC_ALGN IN LOCAL MODE
    ENTITY Incidentes
    EXECUTE setHistory
       FROM CORRESPONDING #( keys ).

  ENDMETHOD.

  METHOD validateCreationDate.
  ENDMETHOD.

  METHOD validateDescription.
  ENDMETHOD.

  METHOD validatePriority.
  ENDMETHOD.

  METHOD validateTitle.
  ENDMETHOD.

  METHOD validateStatus.
  ENDMETHOD.

ENDCLASS.
