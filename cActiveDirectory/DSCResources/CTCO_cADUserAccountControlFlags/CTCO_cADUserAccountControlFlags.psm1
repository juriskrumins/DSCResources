function Get-UserAccountControlFlag
{ 
    param
    (
        [Parameter(Mandatory)]
        [string]$flag
    )
    $flags=@{
        ADS_UF_TRUSTED_FOR_DELEGATION=0x00080000
    }

    $retValue=[pscustomobject]@{
        Name="$flag"
        Value=$flags["$flag"]
    }

    return $retValue

}

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory)]
        [string]$ADObjectName,

        [Parameter(Mandatory)]
        [ValidateSet("User", "Computer")]
        [string]$ADObjectType,

        [Parameter(Mandatory)]
        [string[]]$ADUserAccountControlFlags,

        [Parameter(Mandatory)]
        [PSCredential]$DomainAdministratorCredential
    )

    $retValue=@{}
    try
    {
        $ErrorActionPreference="Stop"
        Write-Verbose -Message "Looking for AD Object $ADObjectName of type $ADObjectType ..."
        $ADObject=Get-ADObject -Filter "Name -like '$ADObjectName'" -Properties * | Where-Object {$_.ObjectClass -eq "$ADObjectType"}
        if($ADObject -ne $null)
        {
            Write-Verbose -Message "AD Object $ADObjectName of type $ADObjectType found."
            Write-Verbose -Message "Collecting UserAccountControl flags for AD Object $ADObjectName of type $ADObjectType ."
            $AlreadySetFlags=@()
            ForEach ($ADUserAccountControlFlag in $ADUserAccountControlFlags)
            {
                $flag=Get-UserAccountControlFlag -Flag $ADUserAccountControlFlag
                if($flag.Value -eq $null)
                {
                    Write-Verbose -Message "DSC resource don't support $ADUserAccountControlFlag flag for AD Object $ADObjectName of type $ADObjectType ."
                }
                else
                {
                    if($flag.Value -eq ($ADObject.UserAccountControl -band $flag.Value))
                    {
                        $AlreadySetFlags+="$ADUserAccountControlFlag"
                        Write-Verbose -Message "UserAccountControl flag $ADUserAccountControlFlag for AD Object $ADObjectName of type $ADObjectType is set."
                    }
                    else
                    {
                        Write-Verbose -Message "UserAccountControl flag $ADUserAccountControlFlag for AD Object $ADObjectName of type $ADObjectType is not set."
                    }
                }
            }
            $retValue.Add("ADObjectName",$ADObject.Name)
            $retValue.Add("ADObjectType",$ADObject.ObjectClass)
            $retValue.Add("DomainAdministratorCredential",$DomainAdministratorCredential)
            $retValue.Add("ADUserAccountControlFlags",$AlreadySetFlags)
        }
        else
        {
            Write-Verbose -Message "AD Object $ADObjectName of type $ADObjectType not found."
        }
    }
    catch
    {
        Write-Error -Message "Error occured."
        throw $_
    }
    return $retValue
}

function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory)]
        [string]$ADObjectName,

        [Parameter(Mandatory)]
        [ValidateSet("User", "Computer")]
        [string]$ADObjectType,

        [Parameter(Mandatory)]
        [string[]]$ADUserAccountControlFlags,

        [Parameter(Mandatory)]
        [PSCredential]$DomainAdministratorCredential
    )
    try
    {
        $ErrorActionPreference="Stop"
        Write-Verbose -Message "Looking for AD Object $ADObjectName of type $ADObjectType ..."
        $ADObject=Get-ADObject -Filter "Name -like '$ADObjectName'" -Properties * | Where-Object {$_.ObjectClass -eq "$ADObjectType"}
        if($ADObject -ne $null)
        {
            Write-Verbose -Message "AD Object $ADObjectName of type $ADObjectType found."
            Write-Verbose -Message "Setting UserAccountControl flags for AD Object $ADObjectName of type $ADObjectType ."
            $uac = $ADObject.UserAccountControl
            ForEach ($ADUserAccountControlFlag in $ADUserAccountControlFlags)
            {
                $flag=Get-UserAccountControlFlag -Flag $ADUserAccountControlFlag
                if($flag.Value -eq $null)
                {
                    Write-Verbose -Message "DSC resource don't support $ADUserAccountControlFlag flag for AD Object $ADObjectName of type $ADObjectType . We'll skip it."
                }
                else
                {
                    $uac = $uac -bor $flag.Value
                }
            }
            Set-ADObject -Identity $ADObject -Replace @{UserAccountControl=$uac} -Credential $DomainAdministratorCredential
            Write-Verbose -Message "UserAccountControl flags for AD Object $ADObjectName of type $ADObjectType have been set."
        }
        else
        {
            Write-Verbose -Message "AD Object $ADObjectName of type $ADObjectType not found."
        }
    }
    catch
    {
        Write-Error -Message "Error occured."
        throw $_
    }
}

function Test-TargetResource
{
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory)]
        [string]$ADObjectName,

        [Parameter(Mandatory)]
        [ValidateSet("User", "Computer")]
        [string]$ADObjectType,

        [Parameter(Mandatory)]
        [string[]]$ADUserAccountControlFlags,

        [Parameter(Mandatory)]
        [PSCredential]$DomainAdministratorCredential
    )

    $retValue=$false
    try
    {
        $ADObject=Get-TargetResource -ADObjectName $ADObjectName -ADObjectType $ADObjectType -ADUserAccountControlFlags $ADUserAccountControlFlags -DomainAdministratorCredential $DomainAdministratorCredential
        if($ADObject.Count -eq 0)
        {
            Write-Verbose -Message "AD Object $ADObjectName of type $ADObjectType not found. Nothing to test/set."
            $retValue=$true
        }
        else
        {
            Write-Verbose -Message "Check requested flags agains already set flags for AD Object $ADObjectName of type $ADObjectType"
            $i=0
            Foreach($ADUserAccountControlFlag in $ADUserAccountControlFlags)
            {
                $flag=Get-UserAccountControlFlag -Flag $ADUserAccountControlFlag
			    if($flag.Value -eq $null)
			    {
				    Write-Verbose -Message "DSC resource don't support $ADUserAccountControlFlag flag for AD Object $ADObjectName of type $ADObjectType ."
                    $i++
			    }
                else
                {
                    if($ADObject.ADUserAccountControlFlags -contains $ADUserAccountControlFlag)
                    {
                        Write-Verbose -Message "$ADUserAccountControlFlag flag for AD Object $ADObjectName of type $ADObjectType is already set."
                        $i++
                    }
                }
            }
            if($ADUserAccountControlFlags.Count -eq $i)
            {
                Write-Verbose -Message "All requested flags are set for AD Object $ADObjectName of type $ADObjectType"
                $retValue=$true
            }
            else
            {
                Write-Verbose -Message "Some requested flags are not set for AD Object $ADObjectName of type $ADObjectType"
            }
        }
    }
    catch
    {
        Write-Error -Message "Error testing AD User $UserName in domain $DomainName. $_"
        throw $_
    }
    return $retValue
}

Export-ModuleMember -Function *-TargetResource