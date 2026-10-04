# Builds the Android app (APK) on a Windows computer.
#
#   powershell -ExecutionPolicy Bypass -File app\tool\build_android.ps1
#
# Needs Flutter (3.47.6) and Android Studio installed. The first run writes
# app\config.json and creates the family signing key (it asks for a password);
# later runs reuse them, so every build updates the app already on phones.
# The finished APK is copied to the top of the project folder.

# For Google Play, add -Play: it builds the app bundle (.aab) to upload in
# Play Console instead of the APK.
#
#   powershell -ExecutionPolicy Bypass -File app\tool\build_android.ps1 -Play

param([switch]$Play)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$app = Join-Path $repo 'app'
Set-Location $app

function Step($text) { Write-Host ''; Write-Host "== $text" -ForegroundColor Green }
function Check($what) { if ($LASTEXITCODE -ne 0) { throw "$what failed (exit code $LASTEXITCODE)" } }

# 1. App settings: the same public values the website uses.
$config = Join-Path $app 'config.json'
if (-not (Test-Path $config)) {
  Step 'Writing app settings (config.json)'
  @'
{
  "SUPABASE_URL": "https://dhvbhnmtiecejmgwhnac.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_QTeiajwPCnJnt7ud-mGr_Q_ruyUHySp"
}
'@ | Set-Content -Encoding ascii $config
}

# 2. The family signing key (kept outside the project, in your user folder).
$keyProps = Join-Path $app 'android\key.properties'
$keystore = Join-Path $env:USERPROFILE 'bua-family.jks'
if (-not (Test-Path $keyProps)) {
  $keytool = @(
    (Join-Path $env:ProgramFiles 'Android\Android Studio\jbr\bin\keytool.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\Android Studio\jbr\bin\keytool.exe'),
    $(if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME 'bin\keytool.exe' }),
    $((Get-Command keytool -ErrorAction SilentlyContinue).Source)
  ) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
  if (-not $keytool) { throw 'keytool not found: install Android Studio (it includes Java), then run this again.' }

  function Read-Password($prompt) {
    $secure = Read-Host -AsSecureString $prompt
    [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
  }

  if (Test-Path $keystore) {
    Step "Using the existing signing key $keystore"
    $password = Read-Password 'Password of bua-family.jks'
  } else {
    Step 'Creating the family signing key'
    Write-Host 'Choose a password (at least 6 characters). Keep it, and a copy of bua-family.jks, somewhere safe:'
    Write-Host 'without them you can never publish updates to the installed app.'
    do {
      $password = Read-Password 'New password'
      $again = Read-Password 'Type it again'
      if ($password.Length -lt 6) { Write-Host 'Too short.' -ForegroundColor Yellow }
      elseif ($password -ne $again) { Write-Host 'They do not match.' -ForegroundColor Yellow }
    } until ($password.Length -ge 6 -and $password -eq $again)
    & $keytool -genkeypair -keystore $keystore -alias bua -keyalg RSA -keysize 2048 -validity 36500 `
      -storepass $password -keypass $password -dname 'CN=Bua Family, O=Bua Family, C=NG'
    Check 'Creating the signing key'
  }
  $storeFile = $keystore -replace '\\', '/'
  @"
storeFile=$storeFile
storePassword=$password
keyAlias=bua
keyPassword=$password
"@ | Set-Content -Encoding ascii $keyProps
}

# 3. Build. The build number grows with every change, so phones accept updates.
$build = (git -C $repo rev-list --count HEAD).Trim()
Check 'Reading the version from git'
Step "Building Bua Family 1.0.$build"
flutter pub get
Check 'flutter pub get'
if ($Play) {
  flutter build appbundle --release --dart-define-from-file=config.json --dart-define=PLAY_STORE=true `
    --build-number=$build --build-name="1.0.$build"
  Check 'flutter build appbundle'
  $aab = Join-Path $repo "bua-family-play-1.0.$build.aab"
  Copy-Item (Join-Path $app 'build\app\outputs\bundle\release\app-release.aab') $aab -Force
  Step "Done: $aab"
  Write-Host 'Upload it in Play Console: your app > Test and release > (a track) > Create new release.'
  Start-Process explorer.exe "/select,`"$aab`""
  exit 0
}

flutter build apk --release --dart-define-from-file=config.json --build-number=$build --build-name="1.0.$build"
Check 'flutter build apk'

$apk = Join-Path $repo "bua-family-1.0.$build.apk"
Copy-Item (Join-Path $app 'build\app\outputs\flutter-apk\app-release.apk') $apk -Force
Step "Done: $apk"
Write-Host 'Publish it for the family in the app: Admin > Settings > Android app > Publish a new version.'
Write-Host 'Phones with the app then offer the update, and the download link is'
Write-Host '  https://buafamily.vercel.app/#/get-app'
Start-Process explorer.exe "/select,`"$apk`""
