Function Get-ConfigStrings {
    <#
        .SYNOPSIS
            Loads the configuration strings from txt files
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $False, Position = 0)]
        [ValidateNotNull()]
        [ValidateScript( { If (Test-Path -Path $_ -PathType 'Leaf') { $True } Else { Throw "Cannot find file $_" } })]
        [System.String] $Path = (Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase -ChildPath "private\ConfigurationStrings")
    )

    $configurations = @{}

    $ConfigFiles = Get-ChildItem -Path $Path | Where-Object {$_.Extension -match 'json|txt' }
    
    $ConfigFiles | ForEach-Object {
        [string] $Content = Get-Content -Path $_.FullName -Raw

        if ($_.Extension -match 'json') {
            $Content = $Content | ConvertFrom-Json
        }

        $configurations.$($_.BaseName) = $Content
    }

    return $configurations
}