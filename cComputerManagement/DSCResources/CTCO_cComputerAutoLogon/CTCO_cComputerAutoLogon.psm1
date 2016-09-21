function Get-TargetResource
{
    [OutputType([Hashtable])]
    param (
      [Parameter(Mandatory=$true)]
      [String]$DefaultUserName,
      [Parameter(Mandatory=$true)]
      [String]$DefaultDomainName,
      [Parameter(Mandatory=$true)]
      [String]$DefaultPassword,
      [Parameter(Mandatory=$false)]
      [Int]$AutoLogonCount = 1,
      [Parameter(Mandatory=$false)]
      [Boolean]$Reboot=$false
     )

    $returnValue = @{}
    try
    {
        $ErrorActionPreference = "Stop"
        Write-Verbose "Getting required registry values"
        Set-Location "HKLM:\Software\Microsoft\Windows NT\Currentversion\WinLogon"
        $returnValue = @{
            AutoAdminLogon = Get-ItemProperty -Path $pwd.Path -Name "AutoAdminLogon" -ErrorAction SilentlyContinue
            DefaultUserName = Get-ItemProperty -Path $pwd.Path -Name "DefaultUserName" -ErrorAction SilentlyContinue
            DefaultPassword = Get-ItemProperty -Path $pwd.Path -Name "DefaultPassword" -ErrorAction SilentlyContinue
            DefaultDomainName = Get-ItemProperty -Path $pwd.Path -Name "DefaultDomainName" -ErrorAction SilentlyContinue
            AutoLogonCount = Get-ItemProperty -Path $pwd.Path -Name "AutoLogonCount" -ErrorAction SilentlyContinue
            Reboot = $Reboot
        }
    }
    catch 
    {
        Write-Verbose -Message "Error occured. Error $($_)"
    }
	$returnValue
}


function Set-TargetResource
{
    param (
      [Parameter(Mandatory=$true)]
      [String]$DefaultUserName,
      [Parameter(Mandatory=$true)]
      [String]$DefaultDomainName,
      [Parameter(Mandatory=$true)]
      [String]$DefaultPassword,
      [Parameter(Mandatory=$false)]
      [Int]$AutoLogonCount = 1,
      [Parameter(Mandatory=$false)]
      [Boolean]$Reboot=$false
     )

    try
    {
        $ErrorActionPreference = "Stop"
        Write-Verbose "Adding required registry values."
        Set-Location "HKLM:\Software\Microsoft\Windows NT\Currentversion\WinLogon"
        New-ItemProperty -Path $pwd.Path -Name "AutoAdminLogon" -Value 1 -PropertyType "String" -Force
        New-ItemProperty -Path $pwd.Path -Name "DefaultUserName" -Value $DefaultUserName -PropertyType "String" -Force
        New-ItemProperty -Path $pwd.Path -Name "DefaultPassword" -Value $DefaultPassword -PropertyType "String" -Force
        New-ItemProperty -Path $pwd.Path -Name "DefaultDomainName" -Value $DefaultDomainName -PropertyType "String" -Force
        New-ItemProperty -Path $pwd.Path -Name "AutoLogonCount" -Value $AutoLogonCount -PropertyType "Dword" -Force
        New-ItemProperty -Path $pwd.Path -Name "AutoLogonSetByDSC" -Value 1 -PropertyType "String" -Force
        if($Reboot)
        {
            Write-Verbose -Message "AutoLogon registry values have been set."
            Write-Verbose -Message "Indicating to LCM that system needs reboot."
            $global:DSCMachineStatus = 1
        }
    }
    catch 
    {
        Write-Verbose -Message "Error occured. Error $($_)"
    }

}


function Test-TargetResource
{
    [OutputType([Boolean])]
    param (
      [Parameter(Mandatory=$true)]
      [String]$DefaultUserName,
      [Parameter(Mandatory=$true)]
      [String]$DefaultDomainName,
      [Parameter(Mandatory=$true)]
      [String]$DefaultPassword,
      [Parameter(Mandatory=$false)]
      [Int]$AutoLogonCount = 1,
      [Parameter(Mandatory=$false)]
      [Boolean]$Reboot=$false
     )
    $retValue = $false
    Write-Verbose "Getting required registry values"
    Set-Location "HKLM:\Software\Microsoft\Windows NT\Currentversion\WinLogon"
    $AutoLogonSetByDSC = Get-ItemProperty -Path $pwd.Path -Name "AutoLogonSetByDSC" -ErrorAction SilentlyContinue
    $AutoLogonStatus = Get-TargetResource  -DefaultUserName $DefaultUserName -DefaultDomainName $DefaultDomainName -DefaultPassword $DefaultPassword -AutoLogonCount $AutoLogonCount -Reboot $Reboot
    if($AutoLogonSetByDSC.AutoLogonSetByDSC -eq "1")
    {
        if(($AutoLogonStatus["DefaultUserName"].DefaultUserName -eq $DefaultUserName) -and ($AutoLogonStatus["DefaultDomainName"].DefaultDomainName -eq $DefaultDomainName))
        {
            Write-Verbose "AutoLogon registry values have been set by DSC and looks correct."
            $retValue = $true
        }
        elseif(($AutoLogonStatus["DefaultUserName"].DefaultUserName -ne $DefaultUserName) -or ($AutoLogonStatus["DefaultDomainName"].DefaultDomainName -ne $DefaultDomainName))
        {
            Write-Verbose "AutoLogon registry values have been set by DSC, but current values are incorrect. Going to set them up once again."
        }
    }
    else
    {
        Write-Verbose "AutoLogon registry values have not been set by DSC. Going to setup proper registry values."
    }
    return $retValue
}


Export-ModuleMember -Function *-TargetResource