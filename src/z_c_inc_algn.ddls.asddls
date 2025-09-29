@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Incidentes Consumption Entity'
@Metadata.ignorePropagatedAnnotations: true
define root view entity Z_C_INC_ALGN 
provider contract transactional_query
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
    LocalCreatedBy,
    LocalCreatedAt,
    LocalLastChangedBy,
    LocalLastChangedAt,
    LastChangedAt,
    /* Associations */
    _Historia
}
