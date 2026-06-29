# Downloads Gemma 3 1B Instruct (4-bit .litertlm) for flutter_gemma_litertlm.
# Requires: Hugging Face account + accepted Gemma license.
# Usage:
#   $env:HUGGINGFACE_TOKEN = "hf_..."
#   .\scripts\download_model.ps1

$ErrorActionPreference = "Stop"

$ModelFile = "Gemma3-1B-IT_multi-prefill-seq_q4_ekv4096.litertlm"
$ModelUrl = "https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/$ModelFile"
$OutDir = Join-Path $PSScriptRoot "..\assets\models"
$OutPath = Join-Path $OutDir $ModelFile

if (-not $env:HUGGINGFACE_TOKEN) {
  Write-Host "Set HUGGINGFACE_TOKEN before running (gated model)." -ForegroundColor Yellow
  Write-Host "Accept the license at: https://huggingface.co/litert-community/Gemma3-1B-IT"
  exit 1
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

Write-Host "Downloading $ModelFile (~500 MB)..."
Invoke-WebRequest `
  -Uri $ModelUrl `
  -OutFile $OutPath `
  -Headers @{ Authorization = "Bearer $env:HUGGINGFACE_TOKEN" }

Write-Host "Saved to $OutPath"
Write-Host "Rebuild the app after download (flutter run)."
