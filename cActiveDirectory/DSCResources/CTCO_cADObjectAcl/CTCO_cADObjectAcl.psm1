#Import DSC helper functions module
Import-Module -name DSCHelperFunctions

#region Get-TargetResource
function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[string] $Id,

		[parameter(Mandatory = $true)]
		[string] $ObjectDN,

		[parameter(Mandatory = $true)]
        [string] $IdentityReference,

		[parameter(Mandatory = $true)]
        [string[]] $ActiveDirectoryRights,

		[parameter()]
        [string] $InheritanceType="None",

        [parameter(Mandatory = $true)]
        [ValidateSet("Allow", "Deny")]
        [string] $AccessControlType,
        
        [parameter(Mandatory = $true)]
        [PSCredential] $DomainAdministratorCredential,

        [parameter()]
        [string[]] $ExtendedRightGuids="00000000-0000-0000-0000-000000000000"
	)

    $returnValue = @{}
    try
    {
        $ErrorActionPreference="Stop"
        Import-Module ActiveDirectory
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        Write-Verbose "Checking for $ObjectDN ACL..."
        if ((Get-PSDrive AD -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0)
        {
            New-PSDrive -Name AD -PSProvider ActiveDirectory -Root "//RootDSE/"
        }
        $acls=(Get-Acl "AD:\$ObjectDN").Access | Where-Object {$_.IdentityReference -eq [System.Security.Principal.NTAccount]"$IdentityReference" }
        if($acls -ne $null)
        {
            Write-Verbose -Message "Checking for requested rights out of existing ones ..."
            $commonrights=0
            $extendedrights=0
            Foreach($ActiveDirectoryRight in $ActiveDirectoryRights)
            {
                foreach($acl in $acls) 
                {
                    if(($acl.ActiveDirectoryRights.value__ -band ([System.DirectoryServices.ActiveDirectoryRights]"$ActiveDirectoryRight").value__) -eq ([System.DirectoryServices.ActiveDirectoryRights]"$ActiveDirectoryRight").value__)
                    {
                        if(($acl.InheritanceFlags -eq "$InheritanceType") -and ($acl.AccessControlType -eq [System.Security.AccessControl.AccessControlType]"$AccessControlType"))
                        {
                            $commonrights++
                            if($ActiveDirectoryRight -eq "ExtendedRight")
                            {
                                Foreach ($ExtendedRightGuid in $ExtendedRightGuids)
                                {
                                    if($acl.ObjectType -contains [System.Guid]"$ExtendedRightGuid")
                                    {
                                        Write-Verbose -Message "$ActiveDirectoryRight right (rightGuid: $ExtendedRightGuid) on AD Object $ObjectDN for $IdentityReference exists with InheritanceType $InheritanceType and AccessControlType $AccessControlType"
                                        $extendedrights++
                                    }
                                }
                                break
                            }
                            else
                            {
                                Write-Verbose -Message "$ActiveDirectoryRight right on AD Object $ObjectDN for $IdentityReference exists with InheritanceType $InheritanceType and AccessControlType $AccessControlType"
                                break
                            }
                        }
                    }
                }
            }
            if($ActiveDirectoryRights -notcontains "ExtendedRight")
            {
                $extendedrights=$ExtendedRightGuids.Count
            }
            if($commonrights -eq $ActiveDirectoryRights.Count -and $extendedrights -eq $ExtendedRightGuids.Count)
            {
                Write-Verbose -Message "All requested rights are in-place for $IdentityReference on AD Object $ObjectDN"
                $returnValue.Id = $Id
                $returnValue.ObjectDN = $ObjectDN
                $returnValue.IdentityReference = $IdentityReference
                $returnValue.ActiveDirectoryRight = $ActiveDirectoryRights
                $returnValue.InheritanceType = $InheritanceType
                $returnValue.AccessControlType = $AccessControlType
                $returnValue.DomainAdministratorCredential = $DomainAdministratorCredential
                $returnValue.ExtendedRightGuids = $ExtendedRightGuids              
            }
            else
            {
                Write-Verbose -Message "Some rights are missing for $IdentityReference on AD Object $ObjectDN"
            }
        }   
        else
        {
            Write-Verbose "$($ObjectDN) dont have ACL for $($IdentityReference)."
        }
    }
    catch 
    {
        Write-Verbose "Error occured. Error message $($Error[0].Message)"
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
    return $returnValue;
}
#endregion Get-TargetResource

#region Set-TargetResource
function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[string] $Id,

		[parameter(Mandatory = $true)]
		[string] $ObjectDN,

		[parameter(Mandatory = $true)]
        [string] $IdentityReference,

		[parameter(Mandatory = $true)]
        [string[]] $ActiveDirectoryRights,

		[parameter()]
        [string] $InheritanceType="None",

        [parameter(Mandatory = $true)]
        [ValidateSet("Allow", "Deny")]
        [string] $AccessControlType,
        
        [parameter(Mandatory = $true)]
        [PSCredential] $DomainAdministratorCredential,

        [parameter()]
        [string[]] $ExtendedRightGuids="00000000-0000-0000-0000-000000000000"
	)

    try
    {
        $ErrorActionPreference="Stop"
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        Write-Verbose "Adding new ACL entries to AD Object $ObjectDN  for $IdentityReference"
        $ADSI = [ADSI]"LDAP://$ObjectDN"
        $identity = [System.Security.Principal.IdentityReference] (New-Object System.Security.Principal.NTAccount($IdentityReference)).Translate([System.Security.Principal.SecurityIdentifier])
        $type = [System.Security.AccessControl.AccessControlType] "$AccessControlType"
        $inhType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "$InheritanceType"
        foreach($ActiveDirectoryRight in $ActiveDirectoryRights)
        {
            if($ActiveDirectoryRight -eq "ExtendedRight")
            {
                $adRights = [System.DirectoryServices.ActiveDirectoryRights] "$ActiveDirectoryRight"
                Foreach($ExtendedRightGuid in $ExtendedRightGuids)
                {
                    $ace = new-object System.DirectoryServices.ActiveDirectoryAccessRule $identity,$adRights,$type,$ExtendedRightGuid,$inhType
                    $ADSI.psbase.ObjectSecurity.AddAccessRule($ace)
                }
            }
            else
            {
                $adRights = [System.DirectoryServices.ActiveDirectoryRights] "$ActiveDirectoryRight"
                $ace = new-object System.DirectoryServices.ActiveDirectoryAccessRule $identity,$adRights,$type,$inhType
                $ADSI.psbase.ObjectSecurity.AddAccessRule($ace)
            }
        }
        $ADSI.psbase.commitchanges()
    }
    catch 
    {
        Write-Verbose "Error occured. Error message $($Error[0].Message)"
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
#endregion Set-TargetResource

#region Test-TargetResource
function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[string] $Id,

		[parameter(Mandatory = $true)]
		[string] $ObjectDN,

		[parameter(Mandatory = $true)]
        [string] $IdentityReference,

		[parameter(Mandatory = $true)]
        [string[]] $ActiveDirectoryRights,

		[parameter()]
        [string] $InheritanceType="None",

        [parameter(Mandatory = $true)]
        [ValidateSet("Allow", "Deny")]
        [string] $AccessControlType,
        
        [parameter(Mandatory = $true)]
        [PSCredential] $DomainAdministratorCredential,

        [parameter()]
        [string[]] $ExtendedRightGuids="00000000-0000-0000-0000-000000000000"
	)

    $returnValue=$false
    $params=@{
        Id=$Id
        ObjectDN=$ObjectDN
        IdentityReference=$IdentityReference
        ActiveDirectoryRights=$ActiveDirectoryRights
        InheritanceType=$InheritanceType
        AccessControlType=$AccessControlType
        DomainAdministratorCredential=$DomainAdministratorCredential
        ExtendedRightGuids=$ExtendedRightGuids
    }
    $ace = Get-TargetResource @params
    if($ace.Count -ne 0)
    {
        Write-Verbose "All requested ACL entries are in-place."
        $returnValue=$true
    }
    else
    {
        Write-Verbose "Some requested ACL entries should be created."
    }
    return $returnValue
}
#endregion Test-TargetResource

Export-ModuleMember -Function *-TargetResource

