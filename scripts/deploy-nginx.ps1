
param(
    [string]$CandidatePath = "nginx/candidates/baseline.conf",
    [string]$ExpectedMarker = "candidate-v1"
)

$ErrorActionPreference = "Stop"

$ActivePath = "nginx/active/nginx.conf"
$BackupDirectory = "nginx/backups"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupPath = "$BackupDirectory/nginx-$Timestamp.conf"

$DeploymentStarted = $false
$BackupCreated = $false


function Test-Endpoint {
    param(
        [string]$Url,
        [string]$ExpectedHeader
    )

    Write-Host "Testing $Url"

    $response = & curl.exe -sS -D - -o NUL `
        -w "`nHTTP_STATUS:%{http_code}" $Url

    if ($LASTEXITCODE -ne 0) {
        throw "Request failed: $Url"
    }

    $responseText = $response -join "`n"

    if ($responseText -notmatch 'HTTP_STATUS:200') {
        throw "Unexpected HTTP status: $Url`n$responseText"
    }

    if ($ExpectedHeader -and
        $responseText -notmatch "(?im)^X-CAP46-Config:\s*$([regex]::Escape($ExpectedHeader))\s*$") {
        throw "Expected configuration header was not found: $Url"
    }

    Write-Host "PASS: $Url"
}


function Restore-Configuration {
    Write-Host "`nROLLBACK STARTED"

    if (-not $BackupCreated) {
        Write-Host "No backup exists. Active configuration was not changed."
        return
    }

    Copy-Item $BackupPath $ActivePath -Force

    docker compose exec -T nginx nginx -t
    if ($LASTEXITCODE -ne 0) {
        throw "Restored configuration failed validation."
    }

    docker compose exec -T nginx nginx -s reload
    if ($LASTEXITCODE -ne 0) {
        throw "Nginx reload failed during rollback."
    }

    Write-Host "Rollback configuration restored."
}

try {
    Write-Host "STEP 1: Checking candidate"

    if (-not (Test-Path $CandidatePath)) {
        throw "Candidate does not exist: $CandidatePath"
    }

    if (-not (Test-Path $ActivePath)) {
        throw "Active configuration does not exist."
    }

    New-Item -ItemType Directory -Force -Path $BackupDirectory |
        Out-Null

    $CandidateFullPath = (Resolve-Path $CandidatePath).Path
    $CandidateDockerPath = $CandidateFullPath -replace '\\', '/'

    Write-Host "`nSTEP 2: Finding Docker network"

    $Network = (docker inspect cap46-nginx --format '{{range $name, $v := .NetworkSettings.Networks}}{{$name}}{{end}}').Trim()

    if ($LASTEXITCODE -ne 0 -or -not $Network) {
        throw "Could not identify the Nginx Docker network."
    }

    Write-Host "Network: $Network"

    Write-Host "`nSTEP 3: Validating candidate"

    docker run --rm `
        --network $Network `
        -v "${CandidateDockerPath}:/etc/nginx/nginx.conf:ro" `
        nginx:1.27-alpine nginx -t

    if ($LASTEXITCODE -ne 0) {
        throw "Candidate validation failed. Deployment rejected."
    }

    Write-Host "`nSTEP 4: Creating backup"

    Copy-Item $ActivePath $BackupPath -Force
    $BackupCreated = $true

    Write-Host "Backup: $BackupPath"

    Write-Host "`nSTEP 5: Promoting candidate"

    Copy-Item $CandidatePath $ActivePath -Force
    $DeploymentStarted = $true

    Write-Host "`nSTEP 6: Validating active configuration"

    docker compose exec -T nginx nginx -t

    if ($LASTEXITCODE -ne 0) {
        throw "Active configuration validation failed."
    }

    Write-Host "`nSTEP 7: Reloading Nginx"

    docker compose exec -T nginx nginx -s reload

    if ($LASTEXITCODE -ne 0) {
        throw "Nginx reload failed."
    }

    Start-Sleep -Seconds 2

    Write-Host "`nSTEP 8: Running smoke tests"

    Test-Endpoint "http://localhost/" $ExpectedMarker
    Test-Endpoint "http://localhost/api/health" $ExpectedMarker

    Write-Host "`nDEPLOYMENT SUCCESSFUL"
    Write-Host "Backup retained at: $BackupPath"
}
catch {
    Write-Host "`nDEPLOYMENT FAILED: $_" -ForegroundColor Red

    if ($DeploymentStarted) {
        Restore-Configuration
        Write-Host "Previous configuration restored."
    }
    else {
        Write-Host "Active configuration was not modified."
    }

    exit 1
}
