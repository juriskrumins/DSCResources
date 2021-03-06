Import-Module -Name RemoteDesktop -Force
#region Get-TargetResource
function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$ConnectionBroker,

		[parameter(Mandatory = $true)]
		[System.String]
		$CollectionName,

		[parameter(Mandatory = $false)]
		[System.Boolean]
		$EnableUserProfileDisk=$false,

		[parameter(Mandatory = $false)]
		[System.Int32]
		$MaxUserProfileDiskSizeGB=20,

		[parameter(Mandatory = $false)]
		[System.String]
		$DiskPath,

		[parameter(Mandatory = $false)]
		[System.Int32]
		$IdleSessionLimitMin=0,

		[parameter(Mandatory = $false)]
		[System.Int32]
		$ActiveSessionLimitMin=0,

		[parameter(Mandatory = $false)]
		[System.Int32]
		$DisconnectedSessionLimitMin=0
	)

    $returnValue=@{}
    try
    {
        Write-Verbose -Message "Collecting RD Session Collection configuration for collection $CollectionName on RD broker $ConnectionBroker"
        $RDSessionCollectionConfigurationUPD = Get-RDSessionCollectionConfiguration -ConnectionBroker $ConnectionBroker -CollectionName $CollectionName -UserProfileDisk -ErrorAction Stop
        $RDSessionCollectionConfigurationCONN = Get-RDSessionCollectionConfiguration -ConnectionBroker $ConnectionBroker -CollectionName $CollectionName -Connection -ErrorAction Stop
        if($RDSessionCollectionConfigurationUPD -ne $null)
        {
            Write-Verbose -Message "Got RD session configuration."
            $returnValue.Add("ConnectionBroker",$ConnectionBroker)
            $returnValue.Add("CollectionName",$RDSessionCollectionConfigurationUPD.CollectionName)
            $returnValue.Add("EnableUserProfileDisk",$RDSessionCollectionConfigurationUPD.EnableUserProfileDisk)
            $returnValue.Add("MaxUserProfileDiskSizeGB",$RDSessionCollectionConfigurationUPD.MaxUserProfileDiskSizeGB)
            $returnValue.Add("DiskPath",$RDSessionCollectionConfigurationUPD.DiskPath)
            $returnValue.Add("IdleSessionLimitMin",$RDSessionCollectionConfigurationCONN.IdleSessionLimitMin)
            $returnValue.Add("ActiveSessionLimitMin",$RDSessionCollectionConfigurationCONN.ActiveSessionLimitMin)
            $returnValue.Add("DisconnectedSessionLimitMin",$RDSessionCollectionConfigurationCONN.DisconnectedSessionLimitMin)
        }
        else
        {
            Write-Verbose -Message "Can't get RD session configuration."
        }
    }
    catch 
    {
        Write-Verbose -Message "Error occured.$_"
    }
    return $returnValue;


}
#endregion Get-TargetResource

#region Test-TargetResource
function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$ConnectionBroker,

		[parameter(Mandatory = $true)]
		[System.String]
		$CollectionName,

		[parameter(Mandatory = $false)]
		[System.Boolean]
		$EnableUserProfileDisk=$false,

		[parameter(Mandatory = $false)]
		[System.Int32]
		$MaxUserProfileDiskSizeGB=20,

		[parameter(Mandatory = $false)]
		[System.String]
		$DiskPath,

		[parameter(Mandatory = $false)]
		[System.Int32]
		$IdleSessionLimitMin=0,

		[parameter(Mandatory = $false)]
		[System.Int32]
		$ActiveSessionLimitMin=0,

		[parameter(Mandatory = $false)]
		[System.Int32]
		$DisconnectedSessionLimitMin=0
	)

    $returnValue=$true
    try
    {
        $GetTargetResourceParams=@{}
        $GetTargetResourceParams.Add('ConnectionBroker',$ConnectionBroker)
        $GetTargetResourceParams.Add('CollectionName', $CollectionName)
        $GetTargetResourceParams.Add('EnableUserProfileDisk', $EnableUserProfileDisk)
        $GetTargetResourceParams.Add('MaxUserProfileDiskSizeGB', $MaxUserProfileDiskSizeGB)
        $GetTargetResourceParams.Add('DiskPath', $DiskPath)
        $GetTargetResourceParams.Add('IdleSessionLimitMin', $IdleSessionLimitMin)
        $GetTargetResourceParams.Add('ActiveSessionLimitMin', $ActiveSessionLimitMin)
        $GetTargetResourceParams.Add('DisconnectedSessionLimitMin', $DisconnectedSessionLimitMin)
        $CurrentRDSessionConfiguration = Get-TargetResource @GetTargetResourceParams
        if($CurrentRDSessionConfiguration["EnableUserProfileDisk"] -eq $EnableUserProfileDisk -and $returnValue)
        {
            Write-Verbose -Message "RD session collection configuration parameter EnableUserProfileDisk is in desired state"
            if($EnableUserProfileDisk)
            {
                Write-Verbose -Message "Checking additinal user profile disk parameters since EnableUserProfileDisk is $EnableUserProfileDisk"
                if($CurrentRDSessionConfiguration["MaxUserProfileDiskSizeGB"] -eq $MaxUserProfileDiskSizeGB -and $returnValue)
                {
                    Write-Verbose -Message "User profile disk parameter MaxUserProfileDiskSizeGB is in desired state"
                }
                else
                {
                    Write-Verbose -Message "User profile disk parameter MaxUserProfileDiskSizeGB is not in desired state"
                    $returnValue=$false
                }
                if($CurrentRDSessionConfiguration["DiskPath"] -eq $DiskPath -and $returnValue)
                {
                    Write-Verbose -Message "User profile disk parameter DiskPath is in desired state"
                }
                else
                {
                    Write-Verbose -Message "User profile disk parameter DiskPath is not in desired state"
                    $returnValue=$false
                }
            }
            else
            {
                Write-Verbose -Message "Ignore all user profile  disk parameters since EnableUserProfileDisk is $EnableUserProfileDisk"                
            }
        }
        else
        {
            Write-Verbose -Message "RD session collection configuration parameter EnableUserProfileDisk is not in desired state"
            $returnValue=$false
        }
        if($CurrentRDSessionConfiguration["IdleSessionLimitMin"] -ne $IdleSessionLimitMin)
        {
            Write-Verbose -Message "Remote Desktop Session Collection Connection's IdleSessionLimitMin parameter is not in desired state"
            $returnValue=$false
        }
        else
        {
            Write-Verbose -Message "Remote Desktop Session Collection Connection's IdleSessionLimitMin parameter is in desired state"
        }
        if($CurrentRDSessionConfiguration["ActiveSessionLimitMin"] -ne $ActiveSessionLimitMin)
        {
            Write-Verbose -Message "Remote Desktop Session Collection Connection's ActiveSessionLimitMin parameter is not in desired state"
            $returnValue=$false
        }
        else
        {
            Write-Verbose -Message "Remote Desktop Session Collection Connection's ActiveSessionLimitMin parameter is in desired state"
        }
        if($CurrentRDSessionConfiguration["DisconnectedSessionLimitMin"] -ne $DisconnectedSessionLimitMin)
        {
            Write-Verbose -Message "Remote Desktop Session Collection Connection's DisconnectedSessionLimitMin parameter is not in desired state"
            $returnValue=$false
        }
        else
        {
            Write-Verbose -Message "Remote Desktop Session Collection Connection's DisconnectedSessionLimitMin parameter is in desired state"
        }
    }
    catch
    {
        Write-Verbose -Message "Error occured. $_"
    }
    return $returnValue
}
#endregion Test-TargetResource

#region Set-TargetResource
function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$ConnectionBroker,

		[parameter(Mandatory = $true)]
		[System.String]
		$CollectionName,

		[parameter(Mandatory = $false)]
		[System.Boolean]
		$EnableUserProfileDisk=$false,

		[parameter(Mandatory = $false)]
		[System.Int32]
		$MaxUserProfileDiskSizeGB=20,

		[parameter(Mandatory = $false)]
		[System.String]
		$DiskPath,

		[parameter(Mandatory = $false)]
		[System.Int32]
		$IdleSessionLimitMin=0,

		[parameter(Mandatory = $false)]
		[System.Int32]
		$ActiveSessionLimitMin=0,

		[parameter(Mandatory = $false)]
		[System.Int32]
		$DisconnectedSessionLimitMin=0
	)

    try
    {
        $GetTargetResourceParams=@{}
        $GetTargetResourceParams.Add('ConnectionBroker',$ConnectionBroker)
        $GetTargetResourceParams.Add('CollectionName', $CollectionName)
        $GetTargetResourceParams.Add('EnableUserProfileDisk', $EnableUserProfileDisk)
        $GetTargetResourceParams.Add('MaxUserProfileDiskSizeGB', $MaxUserProfileDiskSizeGB)
        $GetTargetResourceParams.Add('DiskPath', $DiskPath)
        $GetTargetResourceParams.Add('IdleSessionLimitMin', $IdleSessionLimitMin)
        $GetTargetResourceParams.Add('ActiveSessionLimitMin', $ActiveSessionLimitMin)
        $GetTargetResourceParams.Add('DisconnectedSessionLimitMin', $DisconnectedSessionLimitMin)
        $CurrentRDSessionConfiguration = Get-TargetResource @GetTargetResourceParams

        $SetRDSessionConfigurationCommonParams=@{}
        Write-Verbose -Message "Going to set RD session configuration"
        Write-Verbose -Message "Packing common RD deployment gateway  parameters."
        $SetRDSessionConfigurationCommonParams.Add("ConnectionBroker",$ConnectionBroker)
        $SetRDSessionConfigurationCommonParams.Add("CollectionName",$CollectionName)
        $SetRDSessionConfigurationCommonParams.Add("ErrorAction","Stop")
        if($EnableUserProfileDisk)
        {
            $SetRDSessionConfigurationParamsUDP=@{}
            Write-Verbose -Message "EnableUserProfileDisk is $EnableUserProfileDisk. Adding EnableUserProfileDisk parameter to SetRDSessionConfigurationParamsUDP set."
            $SetRDSessionConfigurationParamsUDP.Add("EnableUserProfileDisk",$true)
            Write-Verbose -Message "EnableUserProfileDisk is $EnableUserProfileDisk. Adding additional user profile disk parameters to SetRDSessionConfigurationParamsUDP set."
            $SetRDSessionConfigurationParamsUDP.Add("MaxUserProfileDiskSizeGB",$MaxUserProfileDiskSizeGB)
            $SetRDSessionConfigurationParamsUDP.Add("DiskPath",$DiskPath)
            Write-Verbose -Message "Apply RD Session Configuration UserProfileDisk settings."
            if($CurrentRDSessionConfiguration["MaxUserProfileDiskSizeGB"] -ne $MaxUserProfileDiskSizeGB -and $CurrentRDSessionConfiguration["EnableUserProfileDisk"])
            {
                Write-Verbose -Message "Since MaxUserProfileDiskSizeGB User disk profile parameter is not in desired state it's necessary to turn off UserProfileDisk and turn it on again."
                Set-RDSessionCollectionConfiguration -CollectionName $CollectionName -ConnectionBroker $ConnectionBroker -DisableUserProfileDisk -ErrorAction Stop
            }
            Set-RDSessionCollectionConfiguration @SetRDSessionConfigurationCommonParams @SetRDSessionConfigurationParamsUDP
            Write-Verbose -Message "RD Session Configuration UserProfileDisk settings applied."
        }
        else
        {
            $SetRDSessionConfigurationParamsUDP=@{}
            Write-Verbose -Message "EnableUserProfileDisk is $EnableUserProfileDisk. Adding DisableUserProfileDisk parameter to SetRDSessionConfigurationParamsUDP set."
            $SetRDSessionConfigurationParamsUDP.Add("DisableUserProfileDisk",$true)
            Write-Verbose -Message "Apply RD Session Configuration UserProfileDisk settings."
            Set-RDSessionCollectionConfiguration @SetRDSessionConfigurationCommonParams @SetRDSessionConfigurationParamsUDP
            Write-Verbose -Message "RD Session Configuration UserProfileDisk settings applied."
        }
        $SetRDSessionConfigurationParamsCONN=@{}
        if($CurrentRDSessionConfiguration["IdleSessionLimitMin"] -ne $IdleSessionLimitMin)
        {
            Write-Verbose -Message "Going to set Remote Desktop Session Collection Connection's IdleSessionLimitMin parameter"
            $SetRDSessionConfigurationParamsCONN.Add('IdleSessionLimitMin',$IdleSessionLimitMin)
        }
        if($CurrentRDSessionConfiguration["ActiveSessionLimitMin"] -ne $ActiveSessionLimitMin)
        {
            Write-Verbose -Message "Going to set Remote Desktop Session Collection Connection's ActiveSessionLimitMin parameter"
            $SetRDSessionConfigurationParamsCONN.Add('ActiveSessionLimitMin',$ActiveSessionLimitMin)
        }
        if($CurrentRDSessionConfiguration["DisconnectedSessionLimitMin"] -ne $DisconnectedSessionLimitMin)
        {
            Write-Verbose -Message "Going to set Remote Desktop Session Collection Connection's DisconnectedSessionLimitMin parameter"
            $SetRDSessionConfigurationParamsCONN.Add('DisconnectedSessionLimitMin',$DisconnectedSessionLimitMin)
        }
        if($SetRDSessionConfigurationParamsCONN.Keys.Count -ne 0)
        {
            Write-Verbose -Message "Applying Remote Desktop Session Collection Connection configuration"
            Set-RDSessionCollectionConfiguration @SetRDSessionConfigurationCommonParams @SetRDSessionConfigurationParamsCONN
        }
    }
    catch
    {
        Write-Verbose -Message "Error occured. $_"
        throw
    }
}
#endregion Set-TargetResource
Export-ModuleMember -Function *-TargetResource