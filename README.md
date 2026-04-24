# I.lost.my.virginity.to.Medusa
Este foi o meu primeiro uso da Medusa, onde esplorei algumas possibilidades de BruteForce.

**Simulação de Ataque de Força Bruta Usando Medusa**

Este projeto prático foi desenvolvido como meu primeiro exercício em segurança ofensiva, simulando ataques de força bruta em um ambiente controlado. Utilizei a ferramenta Medusa para testar vulnerabilidades de autenticação em diferentes serviços, sempre com foco em entender na prática como esses ataques funcionam e quais medidas podem impedi-los.

**O Que Foi Proposto**

Montei um laboratório completo com duas máquinas virtuais:

- Kali Linux: para simular o atacante
- Metasploitable 2: como alvo vulnerável

As VMs foram conectadas através de rede interna no VirtualBox, garantindo isolamento total do ambiente externo.

**Objetivos do Teste**

- Configurar toda a infraestrutura do zero, desde a instalação das VMs até a comunicação entre elas
- Executar ataques de força bruta em três fronts diferentes: FTP, formulário web (DVWA) e SMB
- Documentar cada etapa detalhadamente, incluindo comandos, resultados e métricas de performance
- Identificar credenciais fracas e propor contramedidas realistas

**Como Fiz Passo a Passo**

**Preparação do Ambiente**
Comecei configurando as duas máquinas virtuais no VirtualBox. A parte mais trabalhosa foi ajustar as configurações de rede para que as VMs se comunicassem apenas entre si, usando o modo "Host-Only". Testei a conectividade com ping básico antes de prosseguir.

**Reconhecimento Inicial**
Usei o Nmap para escanear as portas abertas no alvo (Metasploitable 2). Identifiquei vários serviços vulneráveis:

- FTP na porta 21
- SSH na 22
- HTTP na 80 (com DVWA)
- SMB nas portas 139 e 445

**Preparação das Wordlists**
Criei listas simples de usuários e senhas para os testes. As wordlists incluíam combinações óbvias como admin/admin, root/123456, e outras variações comuns.

**Ataques Realizados**

**1. Força Bruta no FTP**
Comando usado:

```
medusa -h 192.168.56.101 -U users.txt -P passwords.txt -M ftp -t 4

```

Resultado: O Medusa rapidamente encontrou credenciais válidas. O serviço FTP do Metasploitable aceitou múltiplas tentativas sem bloquear o IP atacante.

**2. Ataque ao Formulário Web (DVWA)**
Para o HTTP, precisei ajustar o comando para lidar com o comportamento do formulário de login:

```
medusa -h 192.168.56.101 -U users.txt -P passwords.txt -M http -m FORM:login.php -m DENY-SIGNAL:error -t 3

```

A opção -f foi essencial aqui para parar nas primeiras tentativas bem-sucedidas.

**3. Password Spraying no SMB**
Primeiro usei enum4linux para enumerar usuários:

```
enum4linux -U 192.168.56.101

```

Depois executei o ataque com Medusa:

```
medusa -h 192.168.56.101 -U smb_users.txt -P common_passwords.txt -M smbnt -t 2 -T 3

```

Configurei menos threads e tempo entre tentativas para evitar detecção.

**O Que Aprendi com os Resultados**

- Serviços mal configurados permitem milhares de tentativas sem qualquer limitação
- Credenciais padrão e senhas fracas são surpreendentemente comuns
- Diferentes protocolos exigem abordagens específicas no Medusa
- O timing entre tentativas pode fazer diferença na detecção

**Medidas de Proteção que Testei Posteriormente**

- Implementei rate limiting no FTP vsftpd
- Configurei bloqueio de IP após falhas consecutivas no SSH
- Ajustei políticas de senha no Samba
- Testei o fail2ban para proteção geral

**Ferramentas que Utilizei**

- **Medusa**: Extremamente versátil para força bruta em múltiplos protocolos
- **VirtualBox**: Estável para virtualização do laboratório
- **Metasploitable 2**: Excelente para aprendizado, com vulnerabilidades realistas
- **Kali Linux**: Todas as ferramentas necessárias já inclusas
- **Nmap**: Essencial para reconhecimento inicial
- **enum4linux**: Muito eficiente para enumerar usuários do SMB

**Por Que Isso Importa para Segurança**

Este exercício me mostrou na prática como ataques aparentemente simples podem ser eficazes contra sistemas mal configurados. A experiência foi valiosa para entender:

- A importância de políticas de senha robustas
- Como mecanismos de bloqueio podem prevenir ataques automatizados
- A necessidade de monitoramento contínuo de tentativas de autenticação
- Que diferentes serviços exigem configurações específicas de segurança

**Reflexão Final**

Como primeiro projeto em segurança ofensiva, esta simulação me deu uma boa base sobre como avaliar resistência a ataques de autenticação.