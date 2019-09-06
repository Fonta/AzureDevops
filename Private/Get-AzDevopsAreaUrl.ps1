function Get-AzDevopsAreaUrl {
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Organization Name.")]
        [Alias('OrgName')]
        [string] $OrganizationName,

        [Parameter(Mandatory = $true, HelpMessage = "Personal Access Token created in Azure Devops.")]
        [Alias('PAT')]
        [string] $PersonalAccessToken,

        [Parameter(Mandatory = $true, HelpMessage = "Id of the area.")]
        [string]$AreaId
    )

    $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PersonalAccessToken)"))
    $header = @{
        authorization = "Basic $token"
    }

    $orgUrl = Get-AzDevopsOrgUrl -OrganizationName $OrganizationName

    # Build the URL for calling the org-level Resource Areas REST API for the RM APIs
    $resourceAreasApiUrl = [string]::Format("{0}/_apis/resourceAreas/{1}?api-preview=5.0-preview.1", $orgUrl, $AreaId)

    # Do a GET on this URL (this returns an object with a "locationUrl" field)
    $results = Invoke-RestMethod -Uri $resourceAreasApiUrl -Headers $header

    if ($results) {
        return $results.locationUrl
    }
    else {
        return $orgUrl
    }
}