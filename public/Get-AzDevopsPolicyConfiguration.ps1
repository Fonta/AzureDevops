function Get-AzDevopsPolicyConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Personal Access Token created in Azure Devops.")]
        [Alias('PAT')]
        [string] $PersonalAccessToken,

        [Parameter(Mandatory = $true, HelpMessage = "Name of the organization.")]
        [Alias('OrgName')]
        [string] $OrganizationName,

        [Parameter(Mandatory = $true, HelpMessage = "Name or ID of the project in Azure Devops.")]
        [string] $Project,

        [Parameter(Mandatory = $false, ValueFromPipeline, HelpMessage = "ID of the policy in Azure Devops.")]
        [string[]] $Id,

        [Parameter(Mandatory = $false, HelpMessage = "Name or ID of a repository.")]
        [string] $RepositoryId,

        [Parameter(Mandatory = $false, HelpMessage = "[Provided for legacy reasons] The scope on which a subset of policies is defined.")]
        [string] $Scope,

        [Parameter(Mandatory = $false, HelpMessage = "Filter returned policies to only this type.")]
        [string] $PolicyType
    )

    begin {
        $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PersonalAccessToken)"))
        $header = @{
            authorization = "Basic $token"
        }
    
        $areaParams = @{
            OrganizationName    = $OrganizationName
            PersonalAccessToken = $PersonalAccessToken
            AreaId              = "fb13a388-40dd-4a04-b530-013a739c72ef"
        }
        $areaUrl = Get-AzDevopsAreaUrl @areaParams
    
        $results = New-Object -TypeName System.Collections.ArrayList
    
        if ($PSBoundParameters.ContainsKey('RepositoryId')) {
            $repo = Get-AzDevopsRepository -PersonalAccessToken $PersonalAccessToken -OrganizationName $OrganizationName -Project $Project -RepositoryId $RepositoryId
        }
    }

    process {
        $Id | ForEach-Object {
            $urlPart = $response = $null
            if ($_) {
                $urlPart = "/$_"
                if ($Scope) { 
                    Write-Warning -Message "Can't use Scope in combination with ID. Ignoring Scope value"
                }
                if ($policyType) {
                    Write-Warning -Message "Can't use PolicyType in combination with ID. Ignoring PolicyType value"
                }
            }
            else {
                if ($Scope) { $ScopeUrl = [string]::Format("scope={0}&", $Scope) }
                if ($policyType) { $policyTypeUrl = [string]::Format("startTime={0}&", $PolicyType) }
            }

            $url = [string]::Format("{0}{1}/_apis/policy/configurations{2}?{3}{4}api-version=5.1", $areaUrl, $Project, $urlPart, $scope, $policyType)
            Write-Verbose "Contructed url $url"

            $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/json" -Headers $header

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
            if ($PSBoundParameters.ContainsKey('RepositoryId')) {
                $results = $results | where-object { $_.settings.scope.repositoryId -like $repo.id }
            }
            return $results
        }
    }
}