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
		[string]
		$Id,

		[parameter(Mandatory = $true)]
		[string]
		$Path,

		[parameter(Mandatory = $true)]
        [string] $IdentityReference,

		[parameter(Mandatory = $true)]
        [string] $RegistryRights,

		[parameter()]
        [string] $InheritanceFlags="None",

        [parameter()]
        [string] $PropagationFlags="None",

        [parameter(Mandatory = $true)]
        [ValidateSet("Allow", "Deny")]
        [string] $AccessControlType,
        
        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential   
	)

    $returnValue = @{}
    try
    {
        $ErrorActionPreference="Stop"
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        Write-Verbose "Checking for $Path ACL..."
        $acls=Get-Acl $Path -ErrorAction SilentlyContinue -ErrorVariable getaclerror
        if($acls -ne $null)
        {
                Write-Verbose "Collection acl info for Identity $IdentityReference ..."
                $acl=$acls.Access | Where-Object {($_.IdentityReference -eq "$IdentityReference") -and ($_.RegistryRights -like "*$RegistryRights*") -and ($_.InheritanceFlags -eq "$InheritanceFlags") -and ($_.PropagationFlags -eq "$PropagationFlags") -and ($_.AccessControlType -eq $AccessControlType)}
                if($acl -ne $null)
                {
                    $returnValue.Id = $Id
                    $returnValue.Path = $Path
                    $returnValue.IdentityReference = $IdentityReference
                    $returnValue.RegistryRights = $acl.RegistryRights
                    $returnValue.InheritanceFlags = $acl.InheritanceFlags
                    $returnValue.PropagationFlags = $acl.PropagationFlags
                    $returnValue.AccessControlType = $acl.AccessControlType
                    $returnValue.DomainAdministratorCredential = $DomainAdministratorCredential
                    Write-Verbose "Acl info collected for Identity $IdentityReference."
                }
                else
                {
                    Write-Verbose "ACE is not defined for $Path for identity $IdentityReference."
                }
        }   
        else
        {
            Write-Verbose "Can't get ACLs for $($Path)."
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
		[string]
		$Id,

		[parameter(Mandatory = $true)]
		[string]
		$Path,

		[parameter(Mandatory = $true)]
        [string] $IdentityReference,

		[parameter(Mandatory = $true)]
        [string] $RegistryRights,

		[parameter()]
        [string] $InheritanceFlags="None",

        [parameter()]
        [string] $PropagationFlags="None",

        [parameter(Mandatory = $true)]
        [ValidateSet("Allow", "Deny")]
        [string] $AccessControlType,
        
        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential   
	)

    try
    {
        $ErrorActionPreference="Stop"
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        Write-Verbose "Adding new ACE to $Path ACL list."
        $acl=Get-Acl $Path -ErrorAction SilentlyContinue -ErrorVariable getaclerror
        if($acl -ne $null)
        {
            $ace = New-Object Security.AccessControl.RegistryAccessRule "$IdentityReference","$RegistryRights","$InheritanceFlags","$PropagationFlags","$AccessControlType"
            $acl.SetAccessRule($ace)
            $acl | Set-ACL $Path
        }
        Write-Verbose "New ACE to $Path ACL list added."
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
		[string]
		$Id,

		[parameter(Mandatory = $true)]
		[string]
		$Path,

		[parameter(Mandatory = $true)]
        [string] $IdentityReference,

		[parameter(Mandatory = $true)]
        [string] $RegistryRights,

		[parameter()]
        [string] $InheritanceFlags="None",

        [parameter()]
        [string] $PropagationFlags="None",

        [parameter(Mandatory = $true)]
        [ValidateSet("Allow", "Deny")]
        [string] $AccessControlType,
        
        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential   
	)

    $returnValue=$false
    $ace = Get-TargetResource -Id $Id -Path $Path -IdentityReference $IdentityReference -RegistryRights $RegistryRights -InheritanceFlags $InheritanceFlags -PropagationFlags $PropagationFlags -AccessControlType $AccessControlType -DomainAdministratorCredential $DomainAdministratorCredential
    if($ace.Count -ne 0)
    {
        Write-Verbose "ACE entry alredy exist."
        $returnValue=$true
    }
    else
    {
        Write-Verbose "New ACE should be created."
    }
    return $returnValue
}
#endregion Test-TargetResource

Export-ModuleMember -Function *-TargetResource

