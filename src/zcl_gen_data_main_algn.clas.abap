CLASS zcl_gen_data_main_algn DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    interfaces: if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gen_data_main_algn IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
     DELETE FROM zdt_status_algn.
     DELETE FROM zdt_priorit_algn.

*     Insertar datos a Tabla de Estatus
        INSERT zdt_status_algn FROM TABLE @( VALUE #( ( status_code = 'OP'
                                                       status_description = 'Open' )
                                                     ( status_code = 'IP'
                                                       status_description = 'In Progress' )
                                                     ( status_code = 'PE'
                                                       status_description = 'Pending' )
                                                     ( status_code = 'CO'
                                                       status_description = 'Completed' )
                                                     ( status_code = 'CL'
                                                       status_description = 'Closed' )
                                                     ( status_code = 'CN'
                                                       status_description = 'Canceled' ) ) ).
        IF sy-subrc EQ 0.
          out->write( |{ sy-dbcnt } Registros de Estatus Agregados| ).
        ENDIF.

*     Insertar Datos a tabla Prioridad
        INSERT zdt_priorit_algn FROM TABLE @( VALUE #( ( priority_code = 'H'
                                                         priority_description = 'High' )
                                                       ( priority_code = 'M'
                                                         priority_description = 'Medium' )
                                                       ( priority_code = 'L'
                                                         priority_description = 'Low' ) ) ).
        IF sy-subrc EQ 0.
          out->write( |{ sy-dbcnt } Registros de Prioridad Agregados | ).
        ENDIF.
  ENDMETHOD.

ENDCLASS.
