<#
Run Supabase SQL migrations locally.

This script is a convenience wrapper to apply the SQL file
`supabase/migrations/001_init.sql` to your Supabase project.

Important:
- You MUST run this locally. I cannot reach your Supabase project from here.
- To run DDL (create tables) you need either:
  * The Postgres connection string (DATABASE_URL) for your Supabase database, or
  * The Supabase CLI logged in and linked to your project (recommended).

Usage examples (PowerShell):

# 1) Using supabase CLI (recommended):
#    supabase login
#    supabase link --project-ref <your-project-ref>
#    .\scripts\run_migrations.ps1 -UseSupabaseCli

# 2) Using psql with DATABASE_URL (postgres://...):
#    $env:DATABASE_URL = 'postgres://user:password@host:5432/postgres'
#    .\scripts\run_migrations.ps1 -DatabaseUrl $env:DATABASE_URL
#>

param(
    [string] $SqlFile = "supabase/migrations/001_init.sql",
    [string] $DatabaseUrl,
    [switch] $UseSupabaseCli
)

if (-not (Test-Path $SqlFile)) {
    Write-Error "SQL file not found: $SqlFile"
    exit 2
}

if ($UseSupabaseCli) {
    Write-Host "Attempting to run migration via supabase CLI..."
    $cli = Get-Command supabase -ErrorAction SilentlyContinue
    if (-not $cli) {
        Write-Error "supabase CLI not found in PATH. Install it and re-run. https://supabase.com/docs/guides/cli"
        exit 3
    }

    # Requires supabase link to have been run previously in this repo.
    # supabase db push will apply all migrations under supabase/migrations.
    & supabase db push --workdir (Split-Path -Parent $SqlFile)
    $code = $LASTEXITCODE
    if ($code -ne 0) {
        Write-Error "supabase db push failed with exit code $code"
        exit $code
    }
    Write-Host "Migration applied via supabase CLI."
    exit 0
}

if (-not $DatabaseUrl) {
    Write-Host "No DatabaseUrl provided. Looking for environment variable DATABASE_URL..."
    $DatabaseUrl = $env:DATABASE_URL
}

if ($DatabaseUrl) {
    $psql = Get-Command psql -ErrorAction SilentlyContinue
    if (-not $psql) {
        Write-Error "psql not found in PATH. Install PostgreSQL client tools or use the supabase CLI."
        exit 4
    }

    Write-Host "Applying SQL file using psql and DATABASE_URL..."
    & psql $DatabaseUrl -f $SqlFile
    $code = $LASTEXITCODE
    if ($code -ne 0) {
        Write-Error "psql failed with exit code $code"
        exit $code
    }

    Write-Host "Migration applied via psql."
    exit 0
}

Write-Error "No valid method to apply migration. Provide -UseSupabaseCli or -DatabaseUrl (or set DATABASE_URL env var)."
exit 1
