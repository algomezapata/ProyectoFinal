@EndUserText.label: 'Entidad Abstracta - Cambio Estatus'
define abstract entity ZAE_CAMBIOESTATUS_ALGN

{
    @EndUserText.label: 'Cambio de Estatus'
    @Consumption.valueHelpDefinition: [ {
        entity.name: 'zcds_vh_status_algn',
        entity.element: 'StatusCode',
        useForValidation: true
      } ]
        status : ze_status;    
    @EndUserText.label: 'Añadir una observación'
        text : ze_text;
    
}
