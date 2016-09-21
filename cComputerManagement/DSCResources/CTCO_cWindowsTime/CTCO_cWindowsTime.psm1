function Get-TargetResource
{
    [OutputType([Hashtable])]
    [CmdletBinding()]
    Param
    (
        [String]
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $NtpServer,
        [String]
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("NTP","NT5DS")]
        $Type="NTP",
        [Boolean]
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        $PDCEmulatorOnly=$false
    )

    $returnValue = @{}
    try 
    {
        Write-Verbose "Collecting W32Time service registry configuration"
        $RegItem=Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\W32Time\Parameters" -ErrorAction Stop
        $returnValue.NtpServer=$RegItem.NtpServer
        $returnValue.Type=$RegItem.Type
        $returnValue.PDCEmulatorOnly=$PDCEmulatorOnly
    }
    catch 
    {
        Write-Verbose "Error occured $_"
        "Error occured $_"
    }
	$returnValue
}

function Set-TargetResource
{
    [CmdletBinding()]
    Param
    (
        [String]
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $NtpServer,
        [String]
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("NTP","NT5DS")]
        $Type="NTP",
        [Boolean]
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        $PDCEmulatorOnly=$false
    )

    try 
    {
        Write-Verbose -Message "Adjusting Windows Time service configuration"
        $W32TimeRegPath="HKLM:\System\CurrentControlSet\Services\W32Time\Parameters"
        $null=New-ItemProperty -Path "$W32TimeRegPath" -Name NtpServer -Value "$NtpServer" -Force -Confirm:$false -PropertyType String -ErrorAction Stop
        $null=New-ItemProperty -Path "$W32TimeRegPath" -Name Type -Value "$Type" -Force -Confirm:$false -PropertyType String -ErrorAction Stop
        Write-Verbose -Message "Restarting Windows Time service"
        Restart-Service -Name W32Time -ErrorAction Stop
    }
    catch 
    {
        Write-Verbose "Error occured $_"
        "Error occured $_"
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    Param
    (
        [String]
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $NtpServer,
        [String]
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("NTP","NT5DS")]
        $Type="NTP",
        [Boolean]
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        $PDCEmulatorOnly=$false
    )

    $retValue = $true
    try 
    {
        $isPDCEmulator=$false
        if($PDCEmulatorOnly)
        {
            $ADDomain=Get-ADDomain -ErrorAction Stop
            $ComputerSystemObj = Get-WmiObject Win32_ComputerSystem -ErrorAction Stop
            if($ADDomain.PDCEmulator -eq "$($ComputerSystemObj.Name).$($ComputerSystemObj.Domain)")
            {
                $isPDCEmulator=$true
            }
        }
        if(($PDCEmulatorOnly -and $isPDCEmulator) -or (-not $PDCEmulatorOnly))
        {
            Write-Verbose -Message "Inspecting Windows Time service current configuration"
            $CurrentState = Get-TargetResource -NtpServer $NtpServer -Type $Type
            if($CurrentState.NtpServer -ne $NtpServer)
            {
                Write-Verbose -Message "Windows Time service NtpServer configuration property is not in desired state."
                $retValue = $false
            }
            if($CurrentState.Type -ne $Type)
            {
                Write-Verbose -Message "Windows Time service Type configuration property is not in desired state."
                $retValue = $false
            }
        }
        else
        {
            Write-Verbose -Message "Looks like PDCEmulatorOnly attribute has been set to $PDCEmulatorOnly and machine is not AD Domain PDCEmulator."
            Write-Verbose -Message "We'll skip Windows Time service configuration"
        }

    }
    catch 
    {
        Write-Verbose "Error occured $_"
        "Error occured $_"
    }
    return $retValue
}

Export-ModuleMember -Function *-TargetResource