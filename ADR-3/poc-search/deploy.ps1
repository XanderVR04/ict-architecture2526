Write-Host "Laden van .env variabelen..." -ForegroundColor Cyan
Get-Content .env | Foreach-Object {
    if ($_ -match "=" -and $_ -notmatch "^#") {
        $name, $value = $_.Split('=', 2)
        [System.Environment]::SetEnvironmentVariable($name.Trim(), $value.Trim(), "Process")
    }
}


Write-Host "Stack aan het uitrollen naar Docker Swarm..." -ForegroundColor Green
docker stack deploy -c poc.yaml poc

Write-Host "Done! Gebruik 'docker service ls' om de status te checken." -ForegroundColor Yellow