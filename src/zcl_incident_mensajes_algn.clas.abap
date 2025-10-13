CLASS zcl_incident_mensajes_algn DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_t100_dyn_msg .
    INTERFACES if_t100_message .
    INTERFACES if_abap_behv_message .

    CONSTANTS:
*     Mensaje Error Estatus PE a CO o CL
      BEGIN OF error_status1,
        msgid TYPE symsgid VALUE 'ZMS_INCIDENTES_ALGN',
        msgno TYPE symsgno VALUE '001',
        attr1 TYPE scx_attrname VALUE 'gv_status',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF error_status1,

*     Mensaje Error Estatus Administrador permisos
      BEGIN OF error_status2,
        msgid TYPE symsgid VALUE 'ZMS_INCIDENTES_ALGN',
        msgno TYPE symsgno VALUE '002',
        attr1 TYPE scx_attrname VALUE 'gv_status',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF error_status2,


*     Mensaje Descripcion Vacia
      BEGIN OF error_desc,
        msgid TYPE symsgid VALUE 'ZMS_INCIDENTES_ALGN',
        msgno TYPE symsgno VALUE '003',
        attr1 TYPE scx_attrname VALUE 'gv_description',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF error_desc,


*     Mensaje Prioridad Vacia
      BEGIN OF error_prioridad,
        msgid TYPE symsgid VALUE 'ZMS_INCIDENTES_ALGN',
        msgno TYPE symsgno VALUE '004',
        attr1 TYPE scx_attrname VALUE 'gv_priority',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF error_prioridad,

*     Mensaje Titulo Vacia
      BEGIN OF error_titulo,
        msgid TYPE symsgid VALUE 'ZMS_INCIDENTES_ALGN',
        msgno TYPE symsgno VALUE '005',
        attr1 TYPE scx_attrname VALUE 'gv_title',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF error_titulo,

*     Mensaje Estatus Vacia
      BEGIN OF error_estatus2,
        msgid TYPE symsgid VALUE 'ZMS_INCIDENTES_ALGN',
        msgno TYPE symsgno VALUE '006',
        attr1 TYPE scx_attrname VALUE 'gv_status',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF error_estatus2,

*     Mensaje Fecha Creacion Vacia
      BEGIN OF error_fecha_creacion,
        msgid TYPE symsgid VALUE 'ZMS_INCIDENTES_ALGN',
        msgno TYPE symsgno VALUE '007',
        attr1 TYPE scx_attrname VALUE 'gv_create_date',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF error_fecha_creacion.

*   Metodo Constructor con los parametros necesarios para lanzar el mensaje
    METHODS constructor IMPORTING gcv_status     TYPE char10 OPTIONAL
                                  gcv_textid     LIKE if_t100_message=>t100key OPTIONAL
                                  gcv_severity   TYPE if_abap_behv_message=>t_severity OPTIONAL
                                  gcv_attr1      TYPE string OPTIONAL
                                  gcv_attr2      TYPE string OPTIONAL
                                  gcv_attr3      TYPE string OPTIONAL
                                  gcv_attr4      TYPE string OPTIONAL
                                  gcv_description TYPE string OPTIONAL
                                  gcv_priority    TYPE string OPTIONAL
                                  gcv_title       TYPE string OPTIONAL
                                  gcv_create_date TYPE string OPTIONAL .

    DATA: gv_status      TYPE char10,
          gv_attr1       TYPE string,
          gv_attr2       TYPE string,
          gv_attr3       TYPE string,
          gv_attr4       TYPE string,
          gv_description TYPE string,
          gv_priority    TYPE string,
          gv_title       TYPE string,
          gv_create_date TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_incident_mensajes_algn IMPLEMENTATION.


  METHOD constructor ##ADT_SUPPRESS_GENERATION.

    super->constructor( previous = previous ).

*   Se igualan parametros del metodo Constructor a las variables de Clase
    me->gv_status = gcv_status.
    me->gv_attr1  = gcv_attr1.
    me->gv_attr2  = gcv_attr2.
    me->gv_attr3  = gcv_attr3.
    me->gv_attr4  = gcv_attr4.
    me->gv_description = gcv_description.
    me->gv_priority = gcv_priority.
    me->gv_title = gcv_title.
    me->gv_create_date = gcv_create_date.

*   Se iguala la severdidad del mensaje
    if_abap_behv_message~m_severity = gcv_severity.

*    CLEAR me->gv_textid.
*   Se valida que la estructura no venga vacia y si es el caso, se envia una estandar
    IF gcv_textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = gcv_textid.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
