#region Get-TargetResource
function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]$Id,

		[parameter(Mandatory = $true)]
		[System.String[]]$GatewayFarmServer,

		[parameter(Mandatory = $true)]
		[System.String]$SubjectName,

		[parameter(Mandatory = $true)]
		[System.String]$Issuer
	)

    $returnValue=@{}
    try
    {
        Import-Module -Name RemoteDesktopServices -Force -ErrorAction Stop
        $SSLCertificateThumbprint = Get-Item -Path "RDS:\gatewayserver\SSLCertificate\Thumbprint" -ErrorAction SilentlyContinue
        if($SSLCertificateThumbprint.CurrentValue -ne $null)
        {
            Write-Verbose -Message "Certificate for RD GW service found. Thumbprint $($SSLCertificateThumbprint.CurrentValue)"
            $Certificate = Get-ChildItem -Path Cert:\LocalMachine\My -Recurse | Where-Object {$_.Thumbprint -eq $SSLCertificateThumbprint.CurrentValue}
            Write-Verbose -Message "Certificate SubjectName is $($Certificate.SubjectName.Name.ToString())"
            Write-Verbose -Message "Certificate issuer is $($Certificate.Issuer.ToString())"
            $returnValue.Add('Id',$Id)
            $returnValue.Add('SubjectName',$Certificate.SubjectName.Name)
            $returnValue.Add('Issuer',$Certificate.Issuer)
            $CurrentGWFServers=(Get-ChildItem -Path "RDS:\gatewayserver\GatewayFarm\Servers" -ErrorAction Stop).Name
            if($CurrentGWFServers -ne $null)
            {
                $returnValue.Add('GatewayFarmServer',@($CurrentGWFServers))
            }
            else
            {
                $returnValue.Add('GatewayFarmServer',@())
            }
        }
        else
        {
            Write-Verbose -Message "SSL certificate for RD GW service not configured."
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
		[System.String]$Id,

		[parameter(Mandatory = $true)]
		[System.String[]]$GatewayFarmServer,

		[parameter(Mandatory = $true)]
		[System.String]$SubjectName,

		[parameter(Mandatory = $true)]
		[System.String]$Issuer
	)

    $returnValue=$true
    try
    {
        $CurrentRDGWConfiguration=Get-TargetResource -Id $Id -GatewayFarmServer $GatewayFarmServer -SubjectName $SubjectName -Issuer $Issuer
        if($CurrentRDGWConfiguration["Issuer"] -ne $Issuer)
        {
            Write-Verbose -Message "Looks like desired and actual certificate Issuers are different."
            $returnValue=$false
        }
        if($CurrentRDGWConfiguration["SubjectName"] -ne $SubjectName -and $returnValue)
        {
            Write-Verbose -Message "Looks like desired and actual certificate SubjectNames are different."
            $returnValue=$false
        }

        $diff = Compare-Object -ReferenceObject $GatewayFarmServer -DifferenceObject $CurrentRDGWConfiguration["GatewayFarmServer"]
        if(($diff | Where-Object{$_.SideIndicator -eq "<="}) -ne $null -and $returnValue)
        {
            Write-Verbose -Message "Looks like RD GW farm server list differs from currently deployed. $($diff.InputObject)"
            $returnValue=$false
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
		[System.String]$Id,

		[parameter(Mandatory = $true)]
		[System.String[]]$GatewayFarmServer,

		[parameter(Mandatory = $true)]
		[System.String]$SubjectName,

		[parameter(Mandatory = $true)]
		[System.String]$Issuer
	)

    try
    {

        $Id="sdfgsdf"
        $GatewayFarmServer="uk-office-gw-1.psipay.com"
        $SubjectName="CN=uk-office-gw-1.psipay.com"
        $Issuer="CN=PsipaySubordinateEnterpriseCA, DC=psipay, DC=com"


        Import-Module -Name RemoteDesktopServices -Force -ErrorAction Stop
        $RestartRDGWService=$false
        $CurrentRDGWConfiguration=Get-TargetResource -Id $Id -GatewayFarmServer $GatewayFarmServer -SubjectName $SubjectName -Issuer $Issuer
        if(($CurrentRDGWConfiguration["Issuer"] -ne $Issuer) -or ($CurrentRDGWConfiguration["SubjectName"] -ne $SubjectName -and $returnValue))
        {
            Write-Verbose -Message "Looks like desired and actual certificate Issuers/SubjectName are different."
            Write-Verbose -Message "Need to configure new certificate for RD GW service."
            $RDGWCertificate = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -eq $SubjectName -and $_.Issuer -eq $Issuer} | Sort-Object -Descending -Property NotAfter
            Set-Item -Path "RDS:\gatewayserver\SSLCertificate\Thumbprint" -Value "$($RDGWCertificate[0].Thumbprint)" -Force -ErrorAction Stop
            Write-Verbose -Message "Certificate for RD GW service has been configured. RD GW service will be restarted."
            $RestartRDGWService=$true
        }
        Write-Verbose -Message "Current GatewayServer farm list: $($CurrentRDGWConfiguration["GatewayFarmServer"])"
        $diff = Compare-Object -ReferenceObject $GatewayFarmServer -DifferenceObject $CurrentRDGWConfiguration["GatewayFarmServer"]
        if(($diff | Where-Object{$_.SideIndicator -eq "<="}) -ne $null)
        {
            Write-Verbose -Message "Looks like RD GW farm server list differs from currently deployed. Need to add $($diff.InputObject) servers to RD GW farm list."
            Foreach($RDGWServer in $diff.InputObject)
            {
                Write-Verbose -Message "Adding $RDGWServer to GatewayFarm server list."
                New-Item -Path "RDS:\gatewayserver\GatewayFarm\Servers" -Name $RDGWServer -ItemType String -ErrorAction Stop
                Write-Verbose -Message "$RDGWServer added to  GatewayFarm server list."
            }
        }
        if($RestartRDGWService)
        {
            Write-Verbose -Message "Restarting RD GW service TSGateway."
            Restart-Service -Name TSGateway -ErrorAction Stop
            Write-Verbose -Message "RD GW service TSGateway has been restarted."
        } 
    }
    catch
    {
        Write-Verbose -Message "Error occured. $_"
    }
}
#endregion Set-TargetResource

Export-ModuleMember -Function *-TargetResource