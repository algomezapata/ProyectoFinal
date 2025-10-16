CLASS lhc_Incidentes DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PUBLIC SECTION.

    CONSTANTS: BEGIN OF lc_status,
                 open        TYPE  ze_status VALUE 'OP',
                 in_progress TYPE  ze_status VALUE 'IP',
                 pending     TYPE  ze_status VALUE 'PE',
                 completed   TYPE  ze_status VALUE 'CO',
                 closed      TYPE  ze_status VALUE 'CL',
                 canceled    TYPE  ze_status VALUE 'CN',
               END OF lc_status.

    INTERFACES: if_oo_adt_classrun.

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
*  -----------------------------------------------------------------------------------------------------------------------------------------
*  get_instance_features realizara la validación para deshabilitar el boton de  cambios de Estatus cuando es creación de incidente.
*  -----------------------------------------------------------------------------------------------------------------------------------------
** Lee las entidades
    READ ENTITIES OF z_r_inc_algn IN LOCAL MODE
       ENTITY Incidentes
         FIELDS ( Status )
         WITH CORRESPONDING #( keys )
       RESULT DATA(incidents)
       FAILED failed.

*     Disable changeStatus for Incidents Creation
    DATA(lv_create_action) = lines( incidents ).
    IF lv_create_action EQ 1.
      DATA(lv_incuuid) = incidents[ 1 ]-IncUUID.
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
                            %action-changeStatus   = COND #( WHEN incident-Status = lc_status-completed OR
                                                                  incident-Status = lc_status-closed    OR
                                                                  incident-Status = lc_status-canceled  OR
                                                                  lv_historia_ind = 0
                                                             THEN if_abap_behv=>fc-o-disabled
                                                             ELSE if_abap_behv=>fc-o-enabled )

                            %assoc-_Historia       = COND #( WHEN incident-Status = lc_status-completed OR
                                                                 incident-Status = lc_status-closed    OR
                                                                 incident-Status = lc_status-canceled  OR
                                                                 lv_historia_ind = 0
                                                            THEN if_abap_behv=>fc-o-disabled
                                                            ELSE if_abap_behv=>fc-o-enabled )
                          ) ).

  ENDMETHOD.

  METHOD get_instance_authorizations.

*  -----------------------------------------------------------------------------------------------------------------------------------------
*  get_instance_authorizations realizara las validaciones por instancia revisando que el usuario sea administrador para poder generar un cambio de estatus.
*  -----------------------------------------------------------------------------------------------------------------------------------------
    DATA: lv_update       TYPE abap_bool,
          lv_update_check TYPE abap_bool.

** Lee las entidades
    READ ENTITIES OF z_r_inc_algn IN LOCAL MODE
       ENTITY Incidentes
         FIELDS ( Status )
         WITH CORRESPONDING #( keys )
       RESULT DATA(incidents)
       FAILED failed.

*  Se valida si se realizara alguna actualización
    lv_update = COND #( WHEN  requested_authorizations-%update = if_abap_behv=>mk-on OR
                                           requested_authorizations-%action-Edit = if_abap_behv=>mk-on
                                      THEN abap_true
                                      ELSE abap_false ).

* Se obtiene el nombre del Usuario
    DATA(lv_tecnical_name) = cl_abap_context_info=>get_user_technical_name(  ).


    LOOP AT incidents INTO DATA(ls_incident).
      IF lv_update = abap_true.
        IF  lv_tecnical_name = 'CB9980000366' .
          lv_update_check = abap_true.
        ELSE.
          lv_update_check = abap_false.
*           Se envia mensaje con el estatus con error
          APPEND VALUE #( %tky = ls_incident-%tky
                          %msg = NEW zcl_incident_mensajes_algn( gcv_textid = zcl_incident_mensajes_algn=>error_status2
*                                                                   gcv_status = lv_status_text
                                                                 gcv_severity = if_abap_behv_message=>severity-error )
                          %element-status = if_abap_behv=>mk-on
                           ) TO reported-incidentes.
        ENDIF.
      ENDIF.



      APPEND VALUE #( LET lv_update_auth  = COND #( when lv_update_check eq abap_true
                                                     then if_abap_behv=>auth-allowed
                                                     ELSE if_abap_behv=>auth-unauthorized  )

                      in %tky     = ls_incident-%tky
                         %update  = lv_update_auth
*                         %action-edit = lv_update_auth
                         ) to result.



    ENDLOOP.

  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD changeStatus.
*  -----------------------------------------------------------------------------------------------------------------------------------------
*  changeStatus validara las reglas de negocio para realizar un cambio de estatus.
*  -----------------------------------------------------------------------------------------------------------------------------------------
    DATA: lt_updated_root_entity TYPE TABLE FOR UPDATE z_r_inc_algn,
          lt_association_entity  TYPE TABLE FOR CREATE z_r_inc_algn\_Historia,
          lv_status              TYPE ze_status,
          lv_text                TYPE ze_text,
*          lv_exception           TYPE string,
          lv_error               TYPE c,
          ls_incidente_hist      TYPE zdt_inct_h_algn,
          lv_status_text         TYPE char10.


*   Leer las entidades
    READ ENTITIES OF z_r_inc_algn IN LOCAL MODE
         ENTITY Incidentes
         ALL FIELDS WITH CORRESPONDING #( keys )
         RESULT DATA(incidentes)
         FAILED failed.


    LOOP AT incidentes ASSIGNING FIELD-SYMBOL(<incident>).

*     Se obtiene el estatus
      lv_status = keys[ KEY id %tky = <incident>-%tky ]-%param-status.

*     Validación que el estatus Pending (PE) no pase  Completed (CO) o Closed (CL)
      IF <incident>-Status EQ lc_status-pending AND lv_status EQ lc_status-closed OR
         <incident>-Status EQ lc_status-pending AND lv_status EQ lc_status-completed.


        APPEND VALUE #( %tky = <incident>-%tky ) TO failed-incidentes.


*       Se igualan los textos del estado para enviar en mensaje
        IF lv_status = lc_status-completed.
          lv_status_text = 'Completed'.
        ELSE.
          lv_status_text = 'Closed'.
        ENDIF.
*       Se envia mensaje con el estatus con error
        APPEND VALUE #( %tky = <incident>-%tky
                        %msg = NEW zcl_incident_mensajes_algn( gcv_textid = zcl_incident_mensajes_algn=>error_status1
                                                               gcv_status = lv_status_text
                                                               gcv_severity = if_abap_behv_message=>severity-error )
                        %element-status = if_abap_behv=>mk-on
*                            %state_area =  'VALIDATE_COMPONENT'
                         ) TO reported-incidentes.


        lv_error = abap_true.
        EXIT.
      ENDIF.

      APPEND VALUE #( %tky = <incident>-%tky
                      ChangedDate = cl_abap_context_info=>get_system_date( )
                      Status = lv_status ) TO lt_updated_root_entity.

*    Se obtiene texto para historial de incidente
      lv_text = keys[ KEY id %tky = <incident>-%tky ]-%param-text.

*    Se obtiene el ultimo Id del historial del incidente
      SELECT FROM zdt_inct_h_algn
        FIELDS MAX( his_id ) AS max_his_id
        WHERE  inc_uuid EQ @<incident>-IncUUID
          AND  his_uuid IS NOT NULL
        INTO @DATA(lv_historia_ind).



      IF lv_historia_ind IS INITIAL.
        ls_incidente_hist-his_id = 1. "Si el ID esta vacio se ingresa como el primero
      ELSE.
        ls_incidente_hist-his_id = lv_historia_ind + 1. "Si el ID no esta vacio se le suma uno para continuar con la numeración
      ENDIF.

      ls_incidente_hist-new_status = lv_status. "Se igual nuevo esttus
      ls_incidente_hist-text = lv_text.         "Se iguala el texto

*     Se obtiene el numero del UUID para el historial
      TRY.
          ls_incidente_hist-inc_uuid = cl_system_uuid=>create_uuid_x16_static( ).
        CATCH cx_uuid_error INTO DATA(lo_error).
          DATA(lv_exception) = lo_error->get_text(  ).
      ENDTRY.

*     Se valida que el campo Id no se encuentre vacio
      IF ls_incidente_hist-his_id IS NOT INITIAL.
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

*   Se interrumpe el proceso porque el estatus fue cambiado de Pending (PE) a Completed (CO) o Closed (CL) .
    CHECK lv_error IS INITIAL.

*   Se modifica el estatus en la tabla de Incidentes
    MODIFY ENTITIES OF z_r_inc_algn IN LOCAL MODE
    ENTITY Incidentes
    UPDATE  FIELDS ( ChangedDate
                     Status )
    WITH lt_updated_root_entity.

    FREE incidentes. " Free entries in incidents

*   Se modifica la tabla Historial del Incidente
    MODIFY ENTITIES OF z_r_inc_algn IN LOCAL MODE
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

*   Se recuperan los campos actualizados
    READ ENTITIES OF z_r_inc_algn IN LOCAL MODE
    ENTITY Incidentes
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT incidentes
    FAILED failed.

*   Se retorna los valores nuevos
    result = VALUE #( FOR incident IN incidentes ( %tky = incident-%tky
                                                  %param = incident ) ).



  ENDMETHOD.

  METHOD setHistory.
*  -----------------------------------------------------------------------------------------------------------------------------------------
*  seHistory es llamado desde el behavior definition como una acción interna para realizar el registro en el historial de cambios de Estatus
*  -----------------------------------------------------------------------------------------------------------------------------------------
    DATA: lt_updated_root_entity TYPE TABLE FOR UPDATE z_r_inc_algn,
          lt_association_entity  TYPE TABLE FOR CREATE z_r_inc_algn\_Historia,
          lv_exception           TYPE string,
          ls_incidente_hist      TYPE zdt_inct_h_algn.

** Lee las entidades
    READ ENTITIES OF z_r_inc_algn IN LOCAL MODE
         ENTITY Incidentes
         ALL FIELDS WITH CORRESPONDING #( keys )
         RESULT DATA(incidentes).

** Se iteran los incidentes
    LOOP AT incidentes ASSIGNING FIELD-SYMBOL(<incident>).
      SELECT FROM zdt_inct_h_algn
        FIELDS MAX( his_id ) AS max_his_id
        WHERE  inc_uuid EQ @<incident>-IncUUID
          AND  his_uuid IS NOT NULL
        INTO @DATA(lv_historia_ind).

* Valida si existe ya un registro previo en la tabla de Hstory
      IF lv_historia_ind IS INITIAL.
        ls_incidente_hist-his_id = 1.
      ELSE.
        ls_incidente_hist-his_id = lv_historia_ind + 1.
      ENDIF.

*Se obtiene el valor de UUDID
      TRY.
          ls_incidente_hist-inc_uuid = cl_system_uuid=>create_uuid_x16_static( ).
        CATCH cx_uuid_error INTO DATA(lo_error).
          lv_exception = lo_error->get_text(  ).
      ENDTRY.

*Se mapean parametros para tabla History
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
* Se realiza el Guardado de la información
    MODIFY ENTITIES OF z_r_inc_algn IN LOCAL MODE
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
*  -----------------------------------------------------------------------------------------------------------------------------------------
*  setDefaultValues mapea los valores iniciales para la creación del incidente.
*  -----------------------------------------------------------------------------------------------------------------------------------------
** Lee las entidades
    READ ENTITIES OF z_r_inc_algn IN LOCAL MODE
     ENTITY Incidentes
     FIELDS ( CreationDate
              Status ) WITH CORRESPONDING #( keys )
     RESULT DATA(incidents).

*   Borrar Incidentes con el campo CreationDate vacio
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

*     Set valores iniciales
    MODIFY ENTITIES OF z_r_inc_algn IN LOCAL MODE
      ENTITY Incidentes
      UPDATE
      FIELDS ( IncidentID
               CreationDate
               Status )
      WITH VALUE #(  FOR incident IN incidents ( %tky = incident-%tky
                                                 IncidentID = lv_last_id
                                                 CreationDate = cl_abap_context_info=>get_system_date( )
                                                 Status       = lc_status-open
                                                 Description = cl_abap_context_info=>get_user_technical_name(  )
                                                  )  ).

  ENDMETHOD.

  METHOD setDefaultHistory.
*  -----------------------------------------------------------------------------------------------------------------------------------------
*  seHistory es llamado desde el behavior definition como una acción interna para realizar el registro en el historial de cambios de Estatus
*  -----------------------------------------------------------------------------------------------------------------------------------------

    MODIFY ENTITIES OF z_r_inc_algn IN LOCAL MODE
    ENTITY Incidentes
    EXECUTE setHistory
       FROM CORRESPONDING #( keys ).

  ENDMETHOD.

  METHOD validateCreationDate.
*  -----------------------------------------------------------------------------------------------------------------------------------------
*  validateCreationDate realiza la validación del Campo Creación de Fecha
*  -----------------------------------------------------------------------------------------------------------------------------------------
*   Leer entidades
    READ ENTITIES OF z_r_inc_algn IN LOCAL MODE
     ENTITY Incidentes
     FIELDS ( CreationDate
              Status ) WITH CORRESPONDING #( keys )
     RESULT DATA(incidentes).

    LOOP AT incidentes ASSIGNING FIELD-SYMBOL(<incidente>).

        "Se valida el campo Creación de Fecha no se encuentre vacio
        IF <incidente>-CreationDate IS INITIAL.
            APPEND VALUE #( %tky = <incidente>-%tky ) to failed-incidentes.

              APPEND VALUE #( %tky = <incidente>-%tky
                              %msg = NEW zcl_incident_mensajes_algn( gcv_textid = zcl_incident_mensajes_algn=>error_fecha_creacion
*                                                                       gcv_status = lv_status_text
                                                                     gcv_severity = if_abap_behv_message=>severity-error )
                              %element-status = if_abap_behv=>mk-on
                              %state_area =  'VALIDATE_COMPONENT'
                               ) TO reported-incidentes.
        ENDIF.

       "Se valida el campo Creación de Fecha no sea una fecha futura
        IF <incidente>-CreationDate > cl_abap_context_info=>get_system_date( ).
            APPEND VALUE #( %tky = <incidente>-%tky ) to failed-incidentes.

              APPEND VALUE #( %tky = <incidente>-%tky
                              %msg = NEW zcl_incident_mensajes_algn( gcv_textid = zcl_incident_mensajes_algn=>error_fecha_creacion_fut
*                                                                       gcv_status = lv_status_text
                                                                     gcv_severity = if_abap_behv_message=>severity-error )
                              %element-status = if_abap_behv=>mk-on
                              %state_area =  'VALIDATE_COMPONENT'
                               ) TO reported-incidentes.
        ENDIF.


    ENDLOOP.

  ENDMETHOD.

  METHOD validateDescription.
*  -----------------------------------------------------------------------------------------------------------------------------------------
*  validateDescription realiza la validación del Campo Descripción
*  -----------------------------------------------------------------------------------------------------------------------------------------
*   Leer entidades
    READ ENTITIES OF z_r_inc_algn IN LOCAL MODE
     ENTITY Incidentes
     FIELDS ( CreationDate
              Status ) WITH CORRESPONDING #( keys )
     RESULT DATA(incidentes).

    LOOP AT incidentes ASSIGNING FIELD-SYMBOL(<incidente>).

        "Se valida el campo descripción no se encuentre vacio
        IF <incidente>-Description IS INITIAL.
            APPEND VALUE #( %tky = <incidente>-%tky ) to failed-incidentes.

              APPEND VALUE #( %tky = <incidente>-%tky
                              %msg = NEW zcl_incident_mensajes_algn( gcv_textid = zcl_incident_mensajes_algn=>error_desc
*                                                                       gcv_status = lv_status_text
                                                                     gcv_severity = if_abap_behv_message=>severity-error )
                              %element-status = if_abap_behv=>mk-on
                              %state_area =  'VALIDATE_COMPONENT'
                               ) TO reported-incidentes.
        ENDIF.

    ENDLOOP.


  ENDMETHOD.

  METHOD validatePriority.
*  -----------------------------------------------------------------------------------------------------------------------------------------
*  validatePriority realiza la validación del Campo Prioridad
*  -----------------------------------------------------------------------------------------------------------------------------------------
*   Leer entidades
    READ ENTITIES OF z_r_inc_algn IN LOCAL MODE
     ENTITY Incidentes
     FIELDS ( CreationDate
              Status ) WITH CORRESPONDING #( keys )
     RESULT DATA(incidentes).

    LOOP AT incidentes ASSIGNING FIELD-SYMBOL(<incidente>).

        "Se valida el campo prioridad no se encuentre  vacio
        IF <incidente>-Priority IS INITIAL.
            APPEND VALUE #( %tky = <incidente>-%tky ) to failed-incidentes.

              APPEND VALUE #( %tky = <incidente>-%tky
                              %msg = NEW zcl_incident_mensajes_algn( gcv_textid = zcl_incident_mensajes_algn=>error_prioridad
*                                                                       gcv_status = lv_status_text
                                                                     gcv_severity = if_abap_behv_message=>severity-error )
                              %element-status = if_abap_behv=>mk-on
                              %state_area =  'VALIDATE_COMPONENT'
                               ) TO reported-incidentes.
        ENDIF.

    ENDLOOP.


  ENDMETHOD.

  METHOD validateTitle.
*  -----------------------------------------------------------------------------------------------------------------------------------------
*  validateTitle realiza la validación del Campo Titulo
*  -----------------------------------------------------------------------------------------------------------------------------------------
*   Leer entidades
    READ ENTITIES OF z_r_inc_algn IN LOCAL MODE
     ENTITY Incidentes
     FIELDS ( CreationDate
              Status ) WITH CORRESPONDING #( keys )
     RESULT DATA(incidentes).

    LOOP AT incidentes ASSIGNING FIELD-SYMBOL(<incidente>).

        "Se valida el campo titulo no se encuentre vacio
        IF <incidente>-title IS INITIAL.
            APPEND VALUE #( %tky = <incidente>-%tky ) to failed-incidentes.

              APPEND VALUE #( %tky = <incidente>-%tky
                              %msg = NEW zcl_incident_mensajes_algn( gcv_textid = zcl_incident_mensajes_algn=>error_titulo
*                                                                       gcv_status = lv_status_text
                                                                     gcv_severity = if_abap_behv_message=>severity-error )
                              %element-status = if_abap_behv=>mk-on
                              %state_area =  'VALIDATE_COMPONENT'
                               ) TO reported-incidentes.
        ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateStatus.
*  -----------------------------------------------------------------------------------------------------------------------------------------
*  validateStatus realiza la validación del Campo Estatus
*  -----------------------------------------------------------------------------------------------------------------------------------------
*   Leer entidades
    READ ENTITIES OF z_r_inc_algn IN LOCAL MODE
     ENTITY Incidentes
     FIELDS ( CreationDate
              Status ) WITH CORRESPONDING #( keys )
     RESULT DATA(incidentes).

    LOOP AT incidentes ASSIGNING FIELD-SYMBOL(<incidente>).

        "Se valida el campo estatus no se se encuentre vacio
        IF <incidente>-Status IS INITIAL.
            APPEND VALUE #( %tky = <incidente>-%tky ) to failed-incidentes.

              APPEND VALUE #( %tky = <incidente>-%tky
                              %msg = NEW zcl_incident_mensajes_algn( gcv_textid = zcl_incident_mensajes_algn=>error_estatus2
*                                                                       gcv_status = lv_status_text
                                                                     gcv_severity = if_abap_behv_message=>severity-error )
                              %element-status = if_abap_behv=>mk-on
                              %state_area =  'VALIDATE_COMPONENT'
                               ) TO reported-incidentes.
        ENDIF.

    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
