$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$outputDir = Join-Path $repoRoot "docker/postgres-seed/initdb"
$outputFile = Join-Path $outputDir "00-local-meow-dev.sql"

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$databaseUrl = $env:LOCAL_DATABASE_URL
if (-not $databaseUrl) {
  $apiEnv = Join-Path $repoRoot "apps/api/.env"
  if (Test-Path $apiEnv) {
    $databaseUrl = Select-String -Path $apiEnv -Pattern "^DATABASE_URL=" |
      Select-Object -First 1 |
      ForEach-Object { $_.Line.Substring("DATABASE_URL=".Length).Trim() }
  }
}

if (-not $databaseUrl) {
  throw "DATABASE_URL not found. Set LOCAL_DATABASE_URL or apps/api/.env DATABASE_URL."
}

$pgDump = Get-Command pg_dump -ErrorAction SilentlyContinue
if (-not $pgDump) {
  throw "pg_dump not found in PATH. Install PostgreSQL client tools or add pg_dump to PATH."
}

Write-Host "Exporting local PostgreSQL data to $outputFile"
& $pgDump.Source `
  --dbname $databaseUrl `
  --format plain `
  --no-owner `
  --no-privileges `
  --clean `
  --if-exists `
  --file $outputFile

Write-Host "Done. Build with:"
Write-Host "  docker compose -f docker-compose.yml -f docker-compose.seeded.yml up --build"
