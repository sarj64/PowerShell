<# 
.SYNOPSIS 
Download and Parse Dell Downloads from CAB V1.1 - To be used in conjunction with other code for Dell Deployment Solutions
.DESCRIPTION 
Download and Parse Dell Downloads from CAB V1.1 - Created by Mark Godfrey @Geodesicz
.LINK
http://www.tekuits.com
#> 

# Format Cab DL Path
$CabPath = "$PSScriptRoot\dellsdpcatalogpc.cab"

# Download Dell Cab File
Invoke-WebRequest -Uri "http://ftp.dell.com/catalog/dellsdpcatalogpc.cab" -OutFile $CabPath -Verbose

# Extract XML from Cab File
If(Test-Path "$PSScriptRoot\DellSDPCatalogPC.xml"){Remove-Item -Path "$PSScriptRoot\DellSDPCatalogPC.xml" -Force -Verbose}
<#
$shell = New-Object -Comobject shell.application
$Items = $shell.Namespace($CabPath).items()
$Extract = $shell.Namespace($PSScriptRoot)
$Extract.CopyHere($Items)
#>
Expand $CabPath "$PSScriptRoot\DellSDPCatalogPC.xml"

# Import and Create XML Object
[xml]$XML = Get-Content $PSScriptRoot\DellSDPCatalogPC.xml -Verbose

# Create Array of Downloads
$Downloads = $xml.SystemsManagementCatalog.SoftwareDistributionPackage

# Display List of Available Downloads
# $Names = $Downloads | ForEach {$PSItem.LocalizedProperties.Title}

<# Find Target Download for Specific Desired Function (Example)
Ignore model names ending in 'AIO' or 'M'and deal with Latitude models where the XML 'Title' node doesn't match $Model 
e.g. 'Dell Latitude 7290/7390/7490'
#>
$Model = ((Get-WmiObject win32_computersystem).Model).TrimEnd()
If  (((($Model -match '7290') -or ($Model -match '7390') -or ($Model -match '7490')) -and (!($Model.EndsWith("AIO")) -or !($Model.EndsWith("M"))))){
         $Target = $Downloads | Where-Object -FilterScript {
         $PSitem.LocalizedProperties.Title -match '7290/7390/7490' -and $PSitem.LocalizedProperties.Title -notmatch $model + " AIO" -and $PSitem.LocalizedProperties.Title -notmatch $model + "M"
             }
}
ElseIf  (((($Model -match '7280') -or ($Model -match '7380') -or ($Model -match '7480')) -and (!($Model.EndsWith("AIO")) -or !($Model.EndsWith("M"))))){
         $Target = $Downloads | Where-Object -FilterScript {
         $PSitem.LocalizedProperties.Title -match '7280/7380/7480' -and $PSitem.LocalizedProperties.Title -notmatch $model + " AIO" -and $PSitem.LocalizedProperties.Title -notmatch $model + "M"
             }
}
Else{$Target = $Downloads | Where-Object -FilterScript {$PSitem.LocalizedProperties.Title -match $model -and $PSitem.Properties.PublicationState -match "Published"}}
$TargetLink = $Target.InstallableItem.OriginFile.OriginUri
$TargetFileName = $Target.InstallableItem.OriginFile.FileName
Invoke-WebRequest -Uri $TargetLink -OutFile $PSScriptRoot\$TargetFileName -UseBasicParsing -Verbose
$TargetDownload = "$PSScriptRoot\$TargetFileName"
