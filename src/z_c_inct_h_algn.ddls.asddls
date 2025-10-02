@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Historia Consumption View'
@Metadata.allowExtensions: true
define view entity Z_C_INCT_H_ALGN as projection on  ZDD_inct_h_ALGN
{
    key HisUUID,
    key IncUUID,
    HisID,
    PreviousStatus,
    NewStatus,
    Text,
    LocalCreatedBy,
    LocalCreatedAt,
    LocalLastChangedBy,
    LocalLastChangedAt,
    LastChangedAt,
    /* Associations */
    _Incidente : redirected to parent Z_C_INC_ALGN
}
