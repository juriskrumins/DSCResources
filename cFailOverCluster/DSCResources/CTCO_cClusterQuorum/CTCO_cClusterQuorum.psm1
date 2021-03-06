﻿#Import DSC helper functions module
Import-Module -name DSCHelperFunctions

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param
    (	
        [parameter(Mandatory)]
        [string] $ClusterName,

        [parameter(Mandatory)]
        [ValidateSet("DiskOnly", "NodeAndDiskMajority","NodeAndFileShareMajority","NodeMajority")]
        [string] $QuorumType,

        [parameter()]
        [string] $QuorumResource=$null,
        
        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential
    )


    $retValue=@{}  
    try
    {
        $ErrorActionPreference = "Stop"  
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        $cluster = Get-Cluster -Name $ClusterName
        if ($null -eq $cluster)
        {
            throw "Can't find the cluster $ClusterName"
        }

        $quorum = $cluster | Get-ClusterQuorum
        $retValue = @{
            ClusterName = $quorum.Cluster
            QuorumResource = $quorum.QuorumResource
            QuorumType = $quorum.QuorumType
            DomainAdministratorCredential = $DomainAdministratorCredential
        }
    }
    finally
    {
        if ($context)
        {
            $context.Undo()
            $context.Dispose()
            CloseUserToken($newToken)
        }
    }

    return $retValue
}

function Set-TargetResource
{
    param
    (	
        [parameter(Mandatory)]
        [string] $ClusterName,

        [parameter(Mandatory)]
        [ValidateSet("DiskOnly", "NodeAndDiskMajority","NodeAndFileShareMajority","NodeMajority")]
        [string] $QuorumType,

        [parameter()]
        [string] $QuorumResource=$null,
        
        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential
    )

 
    try
    {
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        Write-Verbose -Message "Getting cluster $ClusterName ..."
        $cluster = Get-Cluster -Name $ClusterName
        if ($null -eq $cluster)
        {
            throw "Can't find the cluster $ClusterName"
        }
        $parameters = @{}
        if($QuorumType -eq "NodeMajority")
        {
            Write-Verbose -Message "QuorumType  is $QuorumType"
            $parameters += @{NodeMajority=$null}
        }
        elseif(($QuorumType -ne "NodeMajority") -and ($QuorumResource -ne $null))
        {
            Write-Verbose -Message "QuorumType  is $QuorumType"
            Write-Verbose -Message "QuorumResource is $QuorumResource"
            $parameters += @{"$QuorumType"="$QuorumResource"}
        }
        elseif(($QuorumType -ne "NodeMajority") -and ($QuorumResource -eq $null))
        {
            Write-Verbose -Message "QuorumResource parameter should be specified for QuorumType other than NodeMajority"
            Write-Verbose -Message "Thus we'll skip Set function."
        }

        if($parameters.Count -ne 0){
            Write-Verbose -Message "Try to setup cluster quorum for cluster $ClusterName ..."
            $cluster | Set-ClusterQuorum @parameters
        }
        else
        {
            Write-Verbose -Message "Set-ClusterQuorum cmdlet parameter list is empty."
        }
    }
    finally
    {
        if ($context)
        {
            $context.Undo()
            $context.Dispose()
            CloseUserToken($newToken)
        }
    }
}


function Test-TargetResource  
{
    [OutputType([Boolean])]
    param
    (	
        [parameter(Mandatory)]
        [string] $ClusterName,

        [parameter(Mandatory)]
        [ValidateSet("DiskOnly", "NodeAndDiskMajority","NodeAndFileShareMajority","NodeMajority")]
        [string] $QuorumType,

        [parameter()]
        [string] $QuorumResource=$null,
        
        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential
    )

    $retValue = $false

    try
    {
        $ErrorActionPreference = "Stop"
	    ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        Write-Verbose -Message "Getting cluster $Name quorum info ..."
        $quorum = Get-TargetResource -ClusterName $ClusterName -QuorumType $QuorumType -QuorumResource $QuorumResource -DomainAdministratorCredential $DomainAdministratorCredential
        if($quorum.Count -eq 0)
        {
            Write-Verbose -Message "Can't get cluster quorum info."
        }
        elseif(($quorum.Count -ne 0) -and ($quorum["QuorumType"] -like $QuorumType) -and ($quorum["QuorumResource"] -like $QuorumResource))
        {
            Write-Verbose -Message "Cluster quorum configuration is good."
            $retValue = $true
        }
        elseif(($quorum.Count -ne 0) -and (($quorum["QuorumType"] -notlike $QuorumType) -or ($quorum["QuorumResource"] -notlike $QuorumResource)))
        {
            Write-Verbose -Message "Cluster quorum type and/or quorum resource is incorrect."
        }
        else
        {
            Write-Verbose -Message "Something strage happened."
        }
    }
    finally
    {    
	    if ($context)
	    {
		    $context.Undo()
		    $context.Dispose()

		    CloseUserToken($newToken)
	    }
    }
    return $retValue
}