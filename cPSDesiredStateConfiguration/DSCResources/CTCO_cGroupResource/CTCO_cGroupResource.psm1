#region Get-TargetResource 
# DSC uses the Get-TargetResource cmdlet to fetch the status of the resource instance specified in the parameters for the target machine
function Get-TargetResource 
{  
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([Hashtable])]  
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $GroupName,

        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [System.String[]]
        $Members,

        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $DomainAdministratorCredential
	)
    
    try
    {
        # Hash table for Get
        $getTargetResourceResult = @{}
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        Write-Verbose "Getting information for AD group $GroupName ..."
        $ADGroup = Get-ADGroup -Identity "$GroupName"  -ErrorAction Stop
        if($ADGroup -ne $null) 
        {
            Write-Verbose "Got information for AD group $GroupName."
            $getTargetResourceResult.GroupName = $ADGroup.Name
            $getTargetResourceResult.Members = (Get-ADGroupMember -Identity $ADGroup).name
        }
        else
        {
            Write-Verbose "Can't find AD group $GroupName"
        }
    }
    catch 
    {
        Write-Verbose "Error occured while getting AD group information. Error $($_.Message)"
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
    return $getTargetResourceResult;
}
#endregion Get-TargetResource 

#region Set-TargetResource
function Set-TargetResource
{

    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([Hashtable])]  
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $GroupName,

        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [System.String[]]
        $Members,

        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $DomainAdministratorCredential
	)
    
    try
    {
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        Write-Verbose "Getting information for AD group $GroupName ..."
        $ADGroup = Get-ADGroup -Identity "$GroupName" -ErrorAction Stop
        Write-Verbose "AD group $GroupName found"
        Write-Verbose "Checking for AD group $GroupName members ..."
        $ADGroupMembers=(Get-ADGroupMember -Identity $ADGroup).name
        Foreach($member in $members) {
              if($member -in $ADGroupMembers) 
              {
                  Write-Verbose "Member $memeber is alredy a part of AD group $GroupName."
                  continue
              }
              else
              {
                  Write-Verbose "Adding $member to AD group $GroupName ..."
                  Add-ADGroupMember -Identity $ADGroup -Members (Get-ADUser $member)
                  Write-Verbose "$member added to AD group $GroupName."
              }
        }
        Write-Verbose "Group members added to AD group $GroupName."
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
    {
            try 
            {
                Write-Verbose "Can't find AD group $GroupName"
                Write-Verbose "Creating new AD group $GroupName ..."
                $ADGroup = New-ADGroup -Name $GroupName -GroupCategory Security -GroupScope Global -ErrorAction Stop -PassThru
                Write-Verbose "AD group $GroupName created"
                Write-Verbose "Add members to AD group $GroupName ..."
                Foreach($member in $members) {
                    Add-ADGroupMember -Identity $ADGroup -Members (Get-ADUser $member)
                }
                Write-Verbose "Group members added to AD group $GroupName."
            }
            catch
            {
                Write-Verbose "Error occured while creating AD group $GroupName. Error $($_.Message)"
            }
    }
    catch 
    {
        Write-Verbose "Error occured while getting information for AD group $GroupName. Error $($_.Message)"
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

    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([Hashtable])]  
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $GroupName,

        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [System.String[]]
        $Members,

        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $DomainAdministratorCredential
	)
    
    $retValue=$false
    try
    {
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        Write-Verbose "Getting information for AD group $GroupName ..."
        $ADGroup = Get-ADGroup -Identity "$GroupName"  -ErrorAction Stop
        if($ADGroup -ne $null)
        {
            Write-Verbose "Got information for AD group $GroupName ..."
            $ADGroupMembers=(Get-ADGroupMember -Identity $ADGroup).name
            $i=0
            Foreach ($member in $members) {
                if($member -in $ADGroupMembers) {
                    $i++
                    continue
                } 
                else 
                {
                    $retValue=$false
                    break
                }
            }
            if($i -eq $members.Length)
            {
                $retValue=$true
            }
        }
        else
        {
            Write-Verbose "Can't find AD group $GroupName"
            $retValue=$false
        }
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
    {
        Write-Verbose "Can't find AD group $GroupName"
        $retValue=$false
    }
    catch 
    {
        Write-Verbose "Error occured while testing AD group $GroupName. Error $($_.Message)"
        $retValue=$false
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
#endregion Test-TargetResource

#region Additional functions
function Get-ImpersonatetLib
{
    if ($script:ImpersonateLib)
    {
        return $script:ImpersonateLib
    }

    $sig = @'
[DllImport("advapi32.dll", SetLastError = true)]
public static extern bool LogonUser(string lpszUsername, string lpszDomain, string lpszPassword, int dwLogonType, int dwLogonProvider, ref IntPtr phToken);

[DllImport("kernel32.dll")]
public static extern Boolean CloseHandle(IntPtr hObject);
'@ 
   $script:ImpersonateLib = Add-Type -PassThru -Namespace 'Lib.Impersonation' -Name ImpersonationLib -MemberDefinition $sig 

   return $script:ImpersonateLib
    
}

function ImpersonateAs([PSCredential] $cred)
{
    [IntPtr] $userToken = [Security.Principal.WindowsIdentity]::GetCurrent().Token
    $userToken
    $ImpersonateLib = Get-ImpersonatetLib

    $bLogin = $ImpersonateLib::LogonUser($cred.GetNetworkCredential().UserName, $cred.GetNetworkCredential().Domain, $cred.GetNetworkCredential().Password, 
    9, 0, [ref]$userToken)
    
    if ($bLogin)
    {
        $Identity = New-Object Security.Principal.WindowsIdentity $userToken
        $context = $Identity.Impersonate()
    }
    else
    {
        throw "Can't Logon as User $cred.GetNetworkCredential().UserName."
    }
    $context, $userToken
}

function CloseUserToken([IntPtr] $token)
{
    $ImpersonateLib = Get-ImpersonatetLib

    $bLogin = $ImpersonateLib::CloseHandle($token)
    if (!$bLogin)
    {
        throw "Can't close token"
    }
}
#endregion Additional functions

Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource
