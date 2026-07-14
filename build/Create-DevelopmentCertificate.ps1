#Requires -Version 7.0
param(
    [string] $Manifest = "BlueGuard/Package.appxmanifest",
    [string] $OutputDirectory = ".signing",
    [int] $ValidityYears = 5,
    [switch] $Force
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "GitHub CLI (gh) is required. Install it and run 'gh auth login'."
}

if (-not (Test-Path $Manifest)) {
    throw "Could not find $Manifest. Run this script from the repository root."
}

[xml] $manifestXml = Get-Content $Manifest
$publisher = $manifestXml.Package.Identity.Publisher
if (-not $publisher) {
    throw "The package manifest has no Publisher value."
}

$pfxPath = Join-Path $OutputDirectory "BlueGuard.pfx"
$cerPath = Join-Path $OutputDirectory "BlueGuard.cer"

if ((Test-Path $pfxPath) -and -not $Force) {
    throw "$pfxPath already exists. Pass -Force to replace it (existing testers will need the new .cer)."
}

$password = Read-Host "Choose a password for the PFX" -AsSecureString

New-Item $OutputDirectory -ItemType Directory -Force | Out-Null

$certificate = New-SelfSignedCertificate `
    -Type Custom `
    -Subject $publisher `
    -FriendlyName "BlueGuard Development Signing" `
    -KeyAlgorithm RSA `
    -KeyLength 2048 `
    -KeyExportPolicy Exportable `
    -KeyUsage DigitalSignature `
    -NotAfter (Get-Date).AddYears($ValidityYears) `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -TextExtension @(
        "2.5.29.37={text}1.3.6.1.5.5.7.3.3", # code-signing EKU
        "2.5.29.19={text}"                   # not a CA
    )

Export-PfxCertificate -Cert $certificate -FilePath $pfxPath -Password $password | Out-Null
Export-Certificate -Cert $certificate -FilePath $cerPath | Out-Null

$base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($pfxPath))
$plainPassword = ConvertFrom-SecureString $password -AsPlainText

gh secret set WINDOWS_SIGNING_PFX_BASE64 --env release --body $base64
if ($LASTEXITCODE -ne 0) { throw "gh secret set WINDOWS_SIGNING_PFX_BASE64 failed" }

gh secret set WINDOWS_SIGNING_PFX_PASSWORD --env release --body $plainPassword
if ($LASTEXITCODE -ne 0) { throw "gh secret set WINDOWS_SIGNING_PFX_PASSWORD failed" }

Write-Host "$pfxPath / $cerPath created (valid until $($certificate.NotAfter.ToShortDateString())); release environment secrets updated."
