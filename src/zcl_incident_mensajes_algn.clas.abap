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

*     Mensaje Error Estatus PE a CO o CL
      BEGIN OF error_status2,
        msgid TYPE symsgid VALUE 'ZMS_INCIDENTES_ALGN',
        msgno TYPE symsgno VALUE '002',
        attr1 TYPE scx_attrname VALUE 'gv_status',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF error_status2.

*   Metodo Constructor con los parametros necesarios para lanzar el mensaje
    METHODS constructor IMPORTING gcv_status   TYPE char10 OPTIONAL
                                  gcv_textid   LIKE if_t100_message=>t100key OPTIONAL
                                  gcv_severity TYPE if_abap_behv_message=>t_severity OPTIONAL
                                  gcv_attr1    TYPE string OPTIONAL
                                  gcv_attr2    TYPE string OPTIONAL
                                  gcv_attr3    TYPE string OPTIONAL
                                  gcv_attr4    TYPE string OPTIONAL                                  .

    DATA: gv_status TYPE char10,
          gv_attr1  TYPE string,
          gv_attr2  TYPE string,
          gv_attr3  TYPE string,
          gv_attr4  TYPE string.

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
