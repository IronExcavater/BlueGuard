#Requires -Version 7.0
param(
    [string] $Manifest = "BlueGuard/Package.appxmanifest",
    [string] $OutputDirectory = ".signing",
    [int] $ValidityYears = 5,
    [switch] $Force,
    [switch] $SkipGitHubSecrets
)

$ErrorActionPreference = "Stop"

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

$secretsSet = $false
if (-not $SkipGitHubSecrets -and (Get-Command gh -ErrorAction SilentlyContinue)) {
    $plainPassword = ConvertFrom-SecureString $password -AsPlainText
    $base64     | gh secret set WINDOWS_SIGNING_PFX_BASE64   --env release 2>$null
    $plainPword = $LASTEXITCODE -eq 0
    $plainPassword | gh secret set WINDOWS_SIGNING_PFX_PASSWORD --env release 2>$null
    $secretsSet = $plainPword -and $LASTEXITCODE -eq 0
}

if (-not $secretsSet) {
    $base64 | Set-Clipboard
}

Write-Host ""
Write-Host "$pfxPath (private, gitignored) and $cerPath (public), valid until $($certificate.NotAfter.ToShortDateString())."
if ($secretsSet) {
    Write-Host "WINDOWS_SIGNING_PFX_BASE64 and WINDOWS_SIGNING_PFX_PASSWORD set on the 'release' environment via gh."
} else {
    Write-Host "Base64 PFX copied to clipboard. Set WINDOWS_SIGNING_PFX_BASE64 (clipboard) and WINDOWS_SIGNING_PFX_PASSWORD manually on the 'release' environment,"
    Write-Host "or install/authenticate the GitHub CLI (gh auth login) and re-run to have this script set both for you."
}
