@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Incidentes Interface Entity'
@Metadata.ignorePropagatedAnnotations: true
define root view entity Z_I_INC_ALGN 
provider contract transactional_interface
as projection on Z_R_INC_ALGN
{
    key IncUuid,
    IncidentId,
    Title,
    Description,
    Status,
    Priority,
    CreationDate,
    ChangedDate,
    @Semantics.systemDateTime.localInstanceLastChangedAt: true
    LocalLastChangedAt,
    @Semantics.systemDateTime.lastChangedAt: true
    LastChangedAt,
    /* Associations */
    _Historia
}
