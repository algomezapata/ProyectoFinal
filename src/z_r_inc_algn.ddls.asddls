@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS Root Incidentes'
@Metadata.ignorePropagatedAnnotations: true
define root view entity Z_R_INC_ALGN as select from zdt_inct_algn
composition [0..*] of ZDD_inct_h_ALGN as _Historia

{
    key inc_uuid as IncUuid,
    incident_id as IncidentId,
    title as Title,
    description as Description,
    status as Status,
    priority as Priority,
    creation_date as CreationDate,
    changed_date as ChangedDate,
    @Semantics.user.createdBy: true
    local_created_by as LocalCreatedBy,
    @Semantics.systemDateTime.createdAt: true
    local_created_at as LocalCreatedAt,
    @Semantics.user.localInstanceLastChangedBy: true
    local_last_changed_by as LocalLastChangedBy,
    @Semantics.systemDateTime.localInstanceLastChangedAt: true
    local_last_changed_at as LocalLastChangedAt,
    @Semantics.systemDateTime.lastChangedAt: true
    last_changed_at as LastChangedAt,
    _Historia // 
}
