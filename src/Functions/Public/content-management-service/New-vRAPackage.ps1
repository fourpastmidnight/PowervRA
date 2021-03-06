﻿function New-vRAPackage {
<#
    .SYNOPSIS
    Create a vRA Content Package
    
    .DESCRIPTION
    Create a vRA Package
    
    .PARAMETER Name
    Content Package Name
    
    .PARAMETER Description
    Content Package Description

    .PARAMETER Id
    A list of content Ids to include in the Package

    .PARAMETER ContentName
    A list of content names to include in the Package

    .PARAMETER JSON
    Body text to send in JSON format

    .INPUTS
    System.String.

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    New-vRAPackage -Name Package01 -Description "This is Content Package 01" -Id "58e10956-172a-48f6-9373-932f99eab37a","0c74b085-dbc1-4fea-9cbf-a1601f668a1f"

    .EXAMPLE
    New-vRAPackage -Name Package01 -Description "This is Content Package 01" -ContentName "Blueprint01","Blueprint02"
    
    .EXAMPLE
    Get-vRAContent | New-vRAPackage -Name Package01 - Description "This is Content Package 01"

    .EXAMPLE
    $JSON = @"
    {
        "name":"Package01",
        "description":"This is Content Package 01",
        "contents":[ "58e10956-172a-48f6-9373-932f99eab37a","0c74b085-dbc1-4fea-9cbf-a1601f668a1f" ]
    }
    "@
    $JSON | New-vRAPackage
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low",DefaultParameterSetName="ById")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true,ParameterSetName="ById")]
        [parameter(Mandatory=$true,ParameterSetName="ByName")]
        [ValidateNotNullOrEmpty()]
        [String]$Name,
        
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$Description,

        [Parameter(Mandatory=$true,ParameterSetName="ById", ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias("ContentId")]
        [String[]]$Id,

        [Parameter(Mandatory=$true,ParameterSetName="ByName")]
        [ValidateNotNullOrEmpty()]
        [String[]]$ContentName,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="JSON")]
        [ValidateNotNullOrEmpty()]
        [String]$JSON

    )

    begin {

        xRequires -Version 7.0

        $Object = [PSCustomObject] @{

            name = $Name
            description = $Description
            contents = @()
        }

    }
    
    process {

        switch ($PsCmdlet.ParameterSetName) 
        { 
            "ById"  { 

                foreach ($CId in $Id) {

                    Write-Verbose -Message "Adding content with id $($CId) to package"
                    $Object.contents += $CId

                }

                break
            }

            "ByName"  {

                foreach ($CName in $ContentName) {

                    Write-Verbose -Message "Adding content with id $($CName) to package"
                    $Id = (Get-vRAContent -Name $CName).Id
                    $Object.contents += $Id

                }
                
                break
            }

            "JSON"  {

                $Data = ($JSON | ConvertFrom-Json)
        
                $Body = $JSON
                $Name = $Data.name  
                
                break
            }
        }
    }
    end {

        # --- Convert PSCustomObject to a string
        $Body = $Object | ConvertTo-Json                    

        if ($PSCmdlet.ShouldProcess($Name)){

            $URI = "/content-management-service/api/packages"

            # --- Run vRA REST Request
            Invoke-vRARestMethod -Method POST -URI $URI -Body $Body -Verbose:$VerbosePreference | Out-Null

            # --- Output the Successful Result
            Get-vRAPackage -Name $Name -Verbose:$VerbosePreference
        }   
    }
}