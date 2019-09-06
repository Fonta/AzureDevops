function Get-AzDevopsOrgUrl {
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Organization URL E.G. 'https://dev.azure.com/{organization}'.")]
        [Alias('OrgName')]
        [string] $OrganizationName
    )

    # Build the URL for calling the org-level Resource Areas REST API for the RM APIs
    $areaId = [string]"79134C72-4A58-4B42-976C-04E7115F32BF"
    $resourceAreasApiUrl = [string]::Format("https://dev.azure.com/_apis/resourceAreas/{0}?accountName={1}&api-version=5.0-preview.1", $areaId, $OrganizationName)

    # Do a GET on this URL (this returns an object with a "locationUrl" field)
    $results = Invoke-RestMethod -Uri $resourceAreasApiUrl

    if ($results) {
        return $results.locationUrl
    }
    else {
        return $false
    }
}