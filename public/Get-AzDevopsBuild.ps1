function Get-AzDevopsBuild {
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
        [int[]] $BuildId,

        [Parameter(Mandatory = $false, HelpMessage = 'Property Filters.')]
        [string] $PropertyFilters,

        [Parameter(Mandatory = $false, HelpMessage = 'If specified, filters to builds that built from this repository.')]
        [string] $RepositoryId,

        [Parameter(Mandatory = $false, HelpMessage = 'If specified, filters to builds that built from repositories of this type.')]
        [string] $RepositoryType,

        [Parameter(Mandatory = $false, HelpMessage = 'A comma-delimited list that specifies the IDs of builds to retrieve.')]
        [int[]] $BuildIds,

        [Parameter(Mandatory = $false, HelpMessage = 'If specified, filters to builds that built branches that built this branch.')]
        [string] $BranchName,

        [Parameter(Mandatory = $false, HelpMessage = 'The order in which builds should be returned.')]
        [ValidateSet('finishTimeAscending', 'finishTimeDescending', 'queueTimeAscending', 'queueTimeDescending', 'startTimeAscending', 'startTimeDescending')]
        [string] $QueryOrder,

        [Parameter(Mandatory = $false, HelpMessage = 'Indicates whether to exclude, include, or only return deleted builds.')]
        [ValidateSet('excludeDeleted', 'includeDeleted', 'onlyDeleted')]
        [string] $DeletedFilter,

        [Parameter(Mandatory = $false, HelpMessage = 'The maximum number of builds to return per definition.')]
        [int] $MaxBuildsPerDefinition,

        [Parameter(Mandatory = $false, HelpMessage = 'A continuation token, returned by a previous call to this method, that can be used to return the next set of builds.')]
        [string] $ContinuationToken,

        [Parameter(Mandatory = $false, HelpMessage = 'The maximum number of builds to return.')]
        [int] $Top,

        [Parameter(Mandatory = $false, HelpMessage = 'A comma-delimited list of properties to retrieve.')]
        [string[]] $Properties,

        [Parameter(Mandatory = $false, HelpMessage = 'A comma-delimited list of tags. If specified, filters to builds that have the specified tags.')]
        [string[]] $TagFilters,

        [Parameter(Mandatory = $false, HelpMessage = 'If specified, filters to builds that match this result.')]
        [ValidateSet('canceled', 'failed', 'none', 'partiallySucceeded', 'succeeded')]
        [string] $ResultFilter,

        [Parameter(Mandatory = $false, HelpMessage = 'If specified, filters to builds that match this status.')]
        [ValidateSet('all', 'cancelling', 'completed', 'inProgress', 'none', 'notStarted', 'postponed')]
        [string] $StatusFilter,

        [Parameter(Mandatory = $false, HelpMessage = 'If specified, filters to builds that match this reason.')]
        [ValidateSet('all', 'batchedCI', 'buildCompletion', 'checkInShelveset', 'individualCI', 'manual', 'none', 'pullRequest', 'schedule', 'scheduleForced', 'triggered', 'userCreated', 'validateShelveset')]
        [string] $ReasonFilter,

        [Parameter(Mandatory = $false, HelpMessage = 'If specified, filters to builds requested for the specified user.')]
        [string] $RequestedFor,

        [Parameter(Mandatory = $false, HelpMessage = 'If specified, filters to builds that finished/started/queued before this date based on the queryOrder specified.')]
        [string] $MaxTime,

        [Parameter(Mandatory = $false, HelpMessage = 'If specified, filters to builds that finished/started/queued after this date based on the queryOrder specified.')]
        [string] $MinTime,

        [Parameter(Mandatory = $false, HelpMessage = 'If specified, filters to builds that match this build number. Append * to do a prefix search.')]
        [string] $BuildNumber,

        [Parameter(Mandatory = $false, HelpMessage = 'A comma-delimited list of queue IDs. If specified, filters to builds that ran against these queues.')]
        [string[]] $Queues,

        [Parameter(Mandatory = $false, HelpMessage = 'A comma-delimited list of definition IDs. If specified, filters to builds for these definitions.')]
        [string[]] $Definitions
    )

    begin {
        $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PersonalAccessToken)"))
        $header = @{
            authorization = [string]::Format('Basic {0}', $token)
        }
    
        $areaParams = @{
            OrganizationName    = $OrganizationName
            PersonalAccessToken = $PersonalAccessToken
            AreaId              = '5d6898bb-45ec-463f-95f9-54d49c71752e'
        }
        $areaUrl = Get-AzDevopsAreaUrl @areaParams
    
        $results = New-Object -TypeName System.Collections.ArrayList
    }

    process {
        $BuildId | ForEach-Object {
            $idUrl = $queryUrl = $WRResponse = $null

            if ($_) { 
                $idUrl = [string]::Format('/{0}', $_)

                # Allowed
                if ($PropertyFilters) { $queryUrl += [string]::Format('PropertyFilters={0}&', $PropertyFilters) }

                # Not allowed
                if ($RepositoryId) { Write-Warning -Message 'Unable to use RepositoryId in combination with ID. Ignoring.' }
                if ($BuildIds) { Write-Warning -Message 'Unable to use BuildIds in combination with ID. Ignoring.' }
                if ($BranchName) { Write-Warning -Message 'Unable to use BranchName in combination with ID. Ignoring.' }
                if ($QueryOrder) { Write-Warning -Message 'Unable to use QueryOrder in combination with ID. Ignoring.' }
                if ($DeletedFilter) { Write-Warning -Message 'Unable to use DeletedFilter in combination with ID. Ignoring.' }
                if ($MaxBuildsPerDefinition) { Write-Warning -Message 'Unable to use MaxBuildsPerDefinition in combination with ID. Ignoring.' }
                if ($ContinuationToken) { Write-Warning -Message 'Unable to use ContinuationToken in combination with ID. Ignoring.' }
                if ($Top) { Write-Warning -Message 'Unable to use Top in combination with ID. Ignoring.' }
                if ($Properties) { Write-Warning -Message 'Unable to use Properties in combination with ID. Ignoring.' }
                if ($TagFilters) { Write-Warning -Message 'Unable to use TagFilters in combination with ID. Ignoring.' }
                if ($ResultFilter) { Write-Warning -Message 'Unable to use ResultFilter in combination with ID. Ignoring.' }
                if ($StatusFilter) { Write-Warning -Message 'Unable to use StatusFilter in combination with ID. Ignoring.' }
                if ($ReasonFilter) { Write-Warning -Message 'Unable to use ReasonFilter in combination with ID. Ignoring.' }
                if ($RequestedFor) { Write-Warning -Message 'Unable to use RequestedFor in combination with ID. Ignoring.' }
                if ($MaxTime) { Write-Warning -Message 'Unable to use MaxTime in combination with ID. Ignoring.' }
                if ($MinTime) { Write-Warning -Message 'Unable to use MinTime in combination with ID. Ignoring.' }
                if ($BuildNumber) { Write-Warning -Message 'Unable to use BuildNumber in combination with ID. Ignoring.' }
                if ($Queues) { Write-Warning -Message 'Unable to use Queues in combination with ID. Ignoring.' }
                if ($Definitions) { Write-Warning -Message 'Unable to use Definitions in combination with ID. Ignoring.' }
                if ($RepositoryType) { Write-Warning -Message 'Unable to use RepositoryType in combination with ID. Ignoring.' }
            }
            else {
                # Allowed
                if ($RepositoryId) { $queryUrl += [string]::Format('repositoryId={0}&', $RepositoryId) }
                if ($RepositoryType) { $queryUrl += [string]::Format('repositoryType={0}&', $RepositoryType) }
                if ($BuildIds) { $queryUrl += [string]::Format('buildIds={0}&', $BuildIds -join ',') }
                if ($BranchName) { $queryUrl += [string]::Format('branchName={0}&', $BranchName) }
                if ($QueryOrder) { $queryUrl += [string]::Format('queryOrder={0}&', $QueryOrder) }
                if ($DeletedFilter) { $queryUrl += [string]::Format('deletedFilter={0}&', $DeletedFilter) }
                if ($MaxBuildsPerDefinition) { $queryUrl += [string]::Format('maxBuildsPerDefinition={0}&', $MaxBuildsPerDefinition) }
                if ($ContinuationToken) { $queryUrl += [string]::Format('continuationToken={0}&', $ContinuationToken) }
                if ($Top) { $queryUrl += [string]::Format('$top={0}&', $Top) }
                if ($Properties) { $queryUrl += [string]::Format('properties={0}&', $Properties -join ',') }
                if ($TagFilters) { $queryUrl += [string]::Format('tagFilters={0}&', $TagFilters -join ',') }
                if ($ResultFilter) { $queryUrl += [string]::Format('resultFilter={0}&', $ResultFilter) }
                if ($StatusFilter) { $queryUrl += [string]::Format('statusFilter={0}&', $StatusFilter) }
                if ($ReasonFilter) { $queryUrl += [string]::Format('reasonFilter={0}&', $ReasonFilter) }
                if ($RequestedFor) { $queryUrl += [string]::Format('requestedFor={0}&', $RequestedFor) }
                if ($MaxTime) { $queryUrl += [string]::Format('maxTime={0}&', $MaxTime) }
                if ($MinTime) { $queryUrl += [string]::Format('minTime={0}&', $MinTime) }
                if ($BuildNumber) { $queryUrl += [string]::Format('buildNumber={0}&', $BuildNumber) }
                if ($Queues) { $queryUrl += [string]::Format('queues={0}&', $Queues -join ',') }
                if ($Definitions) { $queryUrl += [string]::Format('definitions={0}&', $Definitions -join ',') }

                # Not allowed
                if ($PropertyFilters) { Write-Warning -Message 'Unable to use PropertyFilters without an ID. Ignoring.' }
            }

            # Contruct url
            $url = [string]::Format('{0}{1}/_apis/build/builds{2}?{3}api-version=5.1', $areaUrl, $Project, $idUrl, $queryUrl)
            Write-Verbose "Contructed url $url"

            $WRParams = @{
                Uri         = $url
                Method      = 'Get'
                Headers     = $header
                ContentType = 'application/json'
            }
            $WRResponse = Invoke-WebRequest @WRParams

            $WRResponse | Get-ResponseObject | ForEach-Object {
                $results.Add($_) | Out-Null
            }
        }
    }

    end {
        return $results 
    }
}