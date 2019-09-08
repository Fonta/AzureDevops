function Get-ResponseObject {
    param (
        [PSObject] $InputObject
    )

    $content = ($InputObject.Content | ConvertFrom-Json)

    if ($content.decoratedAuditLogEntries) {
        return $content.decoratedAuditLogEntries
    }

    if ($content.value) {
        return $content.value
    }
    
    if ($content.id) {
        return $content
    }

    # if ($content.count) {
    #     return $content.value
    # }

    # return $content
}