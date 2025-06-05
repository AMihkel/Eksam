# Defineeri domeeni DN
$baseDN = "OU=Kasutajad,DC=oige,DC=local"

# Lae CSV (pane siia õige tee)
$users = Import-Csv -Path "C:\csv\nimekiri_V2.csv" -Delimiter ";"

foreach ($user in $users) {
$fullName = $user.Nimi.Trim()
$department = $user.Osakond.Trim().Replace('ä','a').Replace('ö','o').Replace('ü','u').Replace('õ','o')

# Tekita OU, kui see ei eksisteeri
$ouPath = "OU=$department,$baseDN"
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$department'" -ErrorAction SilentlyContinue)) {
Write-Host "Loon OU: $department"
New-ADOrganizationalUnit -Name $department -Path $baseDN
}
# Töötle nime: kõik peale viimase sõna -> GivenName, viimane sõna -> Surname
$nameParts = $fullName -split " "
$givenName = ($nameParts[0..($nameParts.Count - 2)] -join " ")
$surname = $nameParts[-1]

# Genereeri kasutajanimi: eesnimed + perenimi, punktidega, väikeste tähtedega
$samAccountName0 = ($givenName.Substring(0,1) + "." + $surname).Replace(" ", ".").ToLower().Replace('ä','a').Replace('ö','o').Replace('ü','u').Replace('õ','o')
#eemaldan täpitähed kasutajanimest
$samAccountName = ($givenName.Substring(0,2) + "." + $surname).Replace(" ", ".").ToLower().Replace('ä','a').Replace('ö','o').Replace('ü','u').Replace('õ','o')
# Kontrolli, kas kasutaja juba olemas, tegelikult kasutaks kontrolliks isikukoodi või midagi sarnast, aga kuna CSV failis seda ei ole siis ei saa seda teha ning sama nimega inimesi ei saa olla

if ((-not (Get-ADUser -Filter "Name -eq '$fullName'" -ErrorAction SilentlyContinue)) -and (-not (Get-ADUser -Filter "SamAccountName -eq '$samAccountName0'" -ErrorAction SilentlyContinue))) {
Write-Host "Lisan kasutaja: $fullName ($samAccountName0)"
New-ADUser `
-Name $fullName `
-SamAccountName $samAccountName0 `
-UserPrincipalName "$samAccountName0@oige.local" `
-Path $ouPath `
-AccountPassword (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force) `
-Enabled $true `
-PasswordNeverExpires $false `
-ChangePasswordAtLogon $true `
-GivenName $givenName `
-Surname $surname
}
else {
if(-not (Get-ADUser -Filter "Name -eq '$fullName'" -ErrorAction SilentlyContinue)) {
Write-Host "$samAccountName0 võetud, teen kasutajanime eesnime kahe tähega ($samAccountName)!!!!!!!!!!!!!!!!!!!!!!!"
Write-Host "Lisan kasutaja: $fullName ($samAccountName)"
New-ADUser `
-Name $fullName `
-SamAccountName $samAccountName `
-UserPrincipalName "$samAccountName@oige.local" `
-Path $ouPath `
-AccountPassword (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force) `
-Enabled $true `
-PasswordNeverExpires $false `
-ChangePasswordAtLogon $true `
-GivenName $givenName `
-Surname $surname
}
Write-Host "$fullName on kasutaja juba olemas, jätame vahele."
}
}