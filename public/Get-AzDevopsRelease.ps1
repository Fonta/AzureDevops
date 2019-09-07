function Get-AzDevopsRelease {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, HelpMessage = 'Personal Access Token created in Azure Devops.')]
        [Alias('PAT')]
        [string] $PersonalAccessToken,

        [Parameter(Mandatory = $true, HelpMessage = 'Name of the organization.')]
        [Alias('OrgName')]
        [string] $OrganizationName,

        [Parameter(Mandatory = $true, HelpMessage = 'Name or ID of the project in Azure Devops.')]
        [string] $Project,

        [Parameter(Mandatory = $false, ValueFromPipeline, HelpMessage = 'ID of the build.')]
        [int[]] $ReleaseId,

        [Parameter(Mandatory = $false, HelpMessage = 'A filter which would allow fetching approval steps selectively based on whether it is automated, or manual. This would also decide whether we should fetch pre and post approval snapshots. Assumes All by default.')]
        [ValidateSet('all', 'approvalSnapshots', 'automatedApprovals', 'manualApprovals', 'none')]
        [string] $ApprovalFilter,

        [Parameter(Mandatory = $false, HelpMessage = 'A comma-delimited list of extended properties to be retrieved. If set, the returned Release will contain values for the specified property Ids (if they exist). If not set, properties will not be included.')]
        [string[]]$PropertyFilter,

        [Parameter(Mandatory = $false, HelpMessage = 'A property that should be expanded in the release.')]
        [ValidateSet('none', 'tasks')]
        [string] $Expand,

        [Parameter(Mandatory = $false, HelpMessage = 'Number of release gate records to get. Default is 5.')]
        [int] $TopGateRecords,

        [Parameter(Mandatory = $false, HelpMessage = 'A comma-delimited list of releases Ids. Only releases with these Ids will be returned.')]
        [string[]] $ReleaseIdFilter,

        [Parameter(Mandatory = $false, HelpMessage = 'A comma-delimited list of tags. Only releases with these tags will be returned.')]
        [string[]] $TagFilter,

        [Parameter(Mandatory = $false, HelpMessage = 'Gets the soft deleted releases, if true.')]
        [switch] $IsDeleted,
        
        [Parameter(Mandatory = $false, HelpMessage = 'Releases with given sourceBranchFilter will be returned.')]
        [string] $SourceBranchFilter,

        [Parameter(Mandatory = $false, HelpMessage = 'Releases with given artifactVersionId will be returned. E.g. in case of Build artifactType, it is buildId.')]
        [string] $ArtifactVersionId,

        [Parameter(Mandatory = $false, HelpMessage = 'Unique identifier of the artifact used. e.g. For build it would be {projectGuid}:{BuildDefinitionId} etc.')]
        [string] $SourceId,

        [Parameter(Mandatory = $false, HelpMessage = 'Releases with given artifactTypeId will be returned. Values can be Build, Jenkins, GitHub, Nuget, Team Build (external), ExternalTFSBuild, Git, TFVC, ExternalTfsXamlBuild.')]
        [string] $ArtifactTypeId,

        [Parameter(Mandatory = $false, HelpMessage = 'The property that should be expanded in the list of releases.')]
        [ValidateSet('approvals', 'artifacts', 'environments', 'manualInterventions', 'none', 'tags', 'variables')]
        [string] $ReleaseExpand,

        [Parameter(Mandatory = $false, HelpMessage = 'Gets the releases after the continuation token provided.')]
        [int] $ContinuationToken,

        [Parameter(Mandatory = $false, HelpMessage = 'Number of releases to get. Default is 50.')]
        [int] $Top,

        [Parameter(Mandatory = $false, HelpMessage = 'Gets the results in the defined order of created date for releases. Default is descending.')]
        [ValidateSet('ascending', 'descending')]
        [string] $QueryOrder,

        [Parameter(Mandatory = $false, HelpMessage = 'Releases that were created before this time.')]
        [string] $MaxCreatedTime,

        [Parameter(Mandatory = $false, HelpMessage = 'Releases that were created after this time.')]
        [string] $MinCreatedTime,

        [Parameter(Mandatory = $false)]
        [int] $EnvironmentStatusFilter,

        [Parameter(Mandatory = $false, HelpMessage = 'Releases that have this status.')]
        [ValidateSet('abandoned', 'active', 'draft', 'undefined')]
        [string] $StatusFilter,

        [Parameter(Mandatory = $false, HelpMessage = 'Releases created by this user.')]
        [string] $CreatedBy,

        [Parameter(Mandatory = $false, HelpMessage = 'Releases with names containing searchText.')]
        [string] $SearchText,

        [Parameter(Mandatory = $false)]
        [int] $DefinitionEnvironmentId,

        [Parameter(Mandatory = $false, HelpMessage = 'Releases from this release definition Id.')]
        [int] $DefinitionId,

        [Parameter(Mandatory = $false, HelpMessage = 'Releases under this folder path will be returned')]
        [string] $Path
    )
    

    begin {
        $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PersonalAccessToken)"))
        $header = @{
            authorization = [string]::Format('Basic {0}', $token)
        }
    
        $areaParams = @{
            OrganizationName    = $OrganizationName
            PersonalAccessToken = $PersonalAccessToken
            AreaId              = 'efc2f575-36ef-48e9-b672-0c6fb4a48ac5'
        }
        $areaUrl = Get-AzDevopsAreaUrl @areaParams
    
        $results = New-Object -TypeName System.Collections.ArrayList
    }

    process {
        $ReleaseId | ForEach-Object {
            $idUrl = $queryUrl = $response = $null

            if ($_) {
                $idUrl = [string]::Format('/{0}', $_)
            
                # Allowed
                if ($approvalFilters) { $queryUrl += [string]::Format('approvalFilters={0}&', $approvalFilters) }
                if ($PropertyFilters) { $queryUrl += [string]::Format('PropertyFilters={0}&', $PropertyFilters -join ',') }
                if ($Expand) { $queryUrl += [string]::Format('$expand={0}&', $Expand) }
                if ($TopGateRecords) { $queryUrl += [string]::Format('topGateRecords={0}&', $TopGateRecords) }

                # Not allowed
                if ($ReleaseIdFilter) { Write-Warning -Message 'Unable to use ReleaseIdFilter in combination with ID. Ignoring.' }
                if ($TagFilter) { Write-Warning -Message 'Unable to use TagFilter in combination with ID. Ignoring.' }
                if ($IsDeleted.IsPresent) { Write-Warning -Message 'Unable to use IsDeleted in combination with ID. Ignoring.' }
                if ($SourceBranchFilter) { Write-Warning -Message 'Unable to use SourceBranchFilter in combination with ID. Ignoring.' }
                if ($ArtifactVersionId) { Write-Warning -Message 'Unable to use ArtifactVersionId in combination with ID. Ignoring.' }
                if ($SourceId) { Write-Warning -Message 'Unable to use SourceId in combination with ID. Ignoring.' }
                if ($ArtifactTypeId) { Write-Warning -Message 'Unable to use ArtifactTypeId in combination with ID. Ignoring.' }
                if ($ReleaseExpand) { Write-Warning -Message 'Unable to use ReleaseExpand in combination with ID use Expand instead! Ignoring.' }
                if ($ContinuationToken) { Write-Warning -Message 'Unable to use ContinuationToken in combination with ID. Ignoring.' }
                if ($Top) { Write-Warning -Message 'Unable to use Top in combination with ID. Ignoring.' }
                if ($QueryOrder) { Write-Warning -Message 'Unable to use QueryOrder in combination with ID. Ignoring.' }
                if ($MaxCreatedTime) { Write-Warning -Message 'Unable to use MaxCreatedTime in combination with ID. Ignoring.' }
                if ($MinCreatedTime) { Write-Warning -Message 'Unable to use MinCreatedTime in combination with ID. Ignoring.' }
                if ($EnvironmentStatusFilter) { Write-Warning -Message 'Unable to use EnvironmentStatusFilter in combination with ID. Ignoring.' }
                if ($StatusFilter) { Write-Warning -Message 'Unable to use StatusFilter in combination with ID. Ignoring.' }
                if ($CreatedBy) { Write-Warning -Message 'Unable to use CreatedBy in combination with ID. Ignoring.' }
                if ($SearchText) { Write-Warning -Message 'Unable to use SearchText in combination with ID. Ignoring.' }
                if ($DefinitionEnvironmentId) { Write-Warning -Message 'Unable to use DefinitionEnvironmentId in combination with ID. Ignoring.' }
                if ($DefinitionId) { Write-Warning -Message 'Unable to use DefinitionId in combination with ID. Ignoring.' }
                if ($Path) { Write-Warning -Message 'Unable to use Path in combination with ID. Ignoring.' }
            }
            else {
                # Allowed                
                if ($ReleaseIdFilter) { $queryUrl += [string]::Format('releaseIdFilter={0}&', $ReleaseIdFilter -join ',') }
                if ($PropertyFilters) { $queryUrl += [string]::Format('PropertyFilters={0}&', $PropertyFilters -join ',') }
                if ($TagFilter) { $queryUrl += [string]::Format('tagFilter={0}&', $TagFilter -join ',') }
                if ($IsDeleted.IsPresent) { $queryUrl += 'isDeleted=true&' }
                if ($SourceBranchFilter) { $queryUrl += [string]::Format('sourceBranchFilter={0}&', $SourceBranchFilter) }
                if ($ArtifactVersionId) { $queryUrl += [string]::Format('artifactVersionId={0}&', $ArtifactVersionId) }
                if ($SourceId) { $queryUrl += [string]::Format('sourceId={0}&', $SourceId) }
                if ($ArtifactTypeId) { $queryUrl += [string]::Format('artifactTypeId={0}&', $ArtifactTypeId) }
                if ($ReleaseExpand) { $queryUrl += [string]::Format('$expand={0}&', $ReleaseExpand) }
                if ($ContinuationToken) { $queryUrl += [string]::Format('continuationToken={0}&', $ContinuationToken) }
                if ($Top) { $queryUrl += [string]::Format('$top={0}&', $Top) }
                if ($QueryOrder) { $queryUrl += [string]::Format('queryOrder={0}&', $QueryOrder) }
                if ($MaxCreatedTime) { $queryUrl += [string]::Format('maxCreatedTime={0}&', $MaxCreatedTime) }
                if ($MinCreatedTime) { $queryUrl += [string]::Format('minCreatedTime={0}&', $MinCreatedTime) }
                if ($EnvironmentStatusFilter) { $queryUrl += [string]::Format('environmentStatusFilter={0}&', $EnvironmentStatusFilter) }
                if ($StatusFilter) { $queryUrl += [string]::Format('statusFilter={0}&', $StatusFilter) }
                if ($CreatedBy) { $queryUrl += [string]::Format('createdBy={0}&', $CreatedBy) }
                if ($SearchText) { $queryUrl += [string]::Format('searchText={0}&', $SearchText) }
                if ($DefinitionEnvironmentId) { $queryUrl += [string]::Format('definitionEnvironmentId={0}&', $DefinitionEnvironmentId) }
                if ($DefinitionId) { $queryUrl += [string]::Format('topGateRecords={0}&', $TopGateRecords) }
                if ($Path) { $queryUrl += [string]::Format('path={0}&', $Path) }

                # Not allowed
                if ($approvalFilters) { Write-Warning -Message 'Unable to use approvalFilters without an ID. Ignoring.' }
                if ($Expand) { Write-Warning -Message 'Unable to use Expand without an ID use ReleaseExpand instead! Ignoring.' }
                if ($TopGateRecords) { Write-Warning -Message 'Unable to use TopGateRecords without an ID. Ignoring.' }
            }
            
            $url = [string]::Format('{0}{1}/_apis/release/releases{2}?{3}api-version=5.1', $areaUrl, $Project, $idUrl, $queryUrl)
            Write-Verbose "Contructed url $url"

            $response = Invoke-RestMethod -Uri $url -Method Get -ContentType 'application/json' -Headers $header

            if ($response.value) {
                $response.value | ForEach-Object {
                    $results.Add($_) | Out-Null
                }
            }
            elseif ($response.id) {
                $results.Add($response) | Out-Null
            }
        }
    }

    end {
        if ($results) {
            return $results 
        }
    }
}
        
