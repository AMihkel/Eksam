# Defineeri domeeni DN
$baseDN = "OU=Kasutajad,DC=oige,DC=local"

# Lae CSV (pane siia �ige tee)
$users = Import-Csv -Path "C:\csv\nimekiri_V2.csv" -Delimiter ";"

foreach ($user in $users) {
$fullName = $user.Nimi.Trim()
$department = $user.Osakond.Trim().Replace('�','a').Replace('�','o').Replace('�','u').Replace('�','o')

# Tekita OU, kui see ei eksisteeri
$ouPath = "OU=$department,$baseDN"
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$department'" -ErrorAction SilentlyContinue)) {
Write-Host "Loon OU: $department"
New-ADOrganizationalUnit -Name $department -Path $baseDN
}
# T��tle nime: k�ik peale viimase s�na -> GivenName, viimane s�na -> Surname
$nameParts = $fullName -split " "
$givenName = ($nameParts[0..($nameParts.Count - 2)] -join " ")
$surname = $nameParts[-1]

# Genereeri kasutajanimi: eesnimed + perenimi, punktidega, v�ikeste t�htedega
$samAccountName0 = ($givenName.Substring(0,1) + "." + $surname).Replace(" ", ".").ToLower().Replace('�','a').Replace('�','o').Replace('�','u').Replace('�','o')
#eemaldan t�pit�hed kasutajanimest
$samAccountName = ($givenName.Substring(0,2) + "." + $surname).Replace(" ", ".").ToLower().Replace('�','a').Replace('�','o').Replace('�','u').Replace('�','o')
# Kontrolli, kas kasutaja juba olemas, tegelikult kasutaks kontrolliks isikukoodi v�i midagi sarnast, aga kuna CSV failis seda ei ole siis ei saa seda teha ning sama nimega inimesi ei saa olla

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
Write-Host "$samAccountName0 v�etud, teen kasutajanime eesnime kahe t�hega ($samAccountName)!!!!!!!!!!!!!!!!!!!!!!!"
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
Write-Host "$fullName on kasutaja juba olemas, j�tame vahele."
}
}