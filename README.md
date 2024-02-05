# Функции для работы в Mikrotik

## Использование.
Создать скрипты в /system/scripts с именами по именам файлов без расширений.
Например:
    /system script add name=initOnStart source="...source text..."
    или через Winbox
После запуска скрипта IniOnStart появятся все функции из всей библиотеки. Этот скрипт подгрузит функции и из остальных скриптов. Можно использовать другие скрипты и отдельно.

Для ознакомления с используемыми переменными смотрите репозиторий

`vlad-kms/mikrotik-initVars` https://github.com/vlad-kms/mikrotik-initVars
файл `source/initVars.lst`

---
### Используемые переменные:
Смотрите репозиторий `vlad-kms/mikrotik-initVars` https://github.com/vlad-kms/mikrotik-initVars 

файл `source/initVars.lst`

Или ниже
```powershell
    ########################################
    #   BOOL переменная.
    #   В моих скриптах используется для определения логировать или нет действия в скриптах
    #   Т.е. все вызовы :log обрамлены
    #       if ($log) do={:log ...}
    #   Т.е. играет роль значения по-умолчанию для переключателя логировать или нет
    ########################################
:global islog; :set islog false;
    ########################################
    #   BOOL переменная.
    #   В моих функциях используется для определения логировать или нет действия в функциях
    #   Т.е. все вызовы :log обрамлены
    #       :local isDeb [$my2bool value=$isDebug];
    #       :set $isDeb ([:tobool $isDeb] || [:tobool $islogFunc])
    #       if ($isDeb) do={ :log ...}
    #   где isDebug - переданный параметр в функцию
    #   Т.е. играет роль значения по-умолчанию для переключателя логировать или нет
    ########################################
:global islogFunc; :set islogFunc false;
    ########################################
    #   ARRAY переменная.
    #   Массив интерфейсов, которые всегда должны быть включены.
    #   Используется в функции initOnStart::reconnectIF, которая запускается
    #   в /system sheduler с определенным интервалом
    ########################################
:global alwaysEnableInterfaces [:toarray "pppoe-rtc"];
    ########################################
    #   ARRAY переменная.
    #   Массив имен интерфейсов, которые используют DynDNS при изменениии своего IP адреса
    #   в /system sheduler с определенным интервалом
    ########################################
#:global ddnsInterfaces [:toarray "pppoe-rtc,l2tp-beeline"]
:global ddnsInterfaces [:toarray "pppoe-rtc"]

    ########################################
    #   ARRAY переменная.
    #   [
    #       'default'=[]
    #       'nameinterface1'=[]
    #       'nameinterface2'=[]
    #       .................
    #   ]
    #   HASHTABLE с данными по интерфейсам для DynDNS.
    #   Словарь с данными по интерфейсам для DynDNS.
    #   Используется в функции initOnStart::oneInterface2DDNS,
    #   которая запускает всевозможные проверки и менят записи в DNS.
    #   у различных DNS провайдеров.
    #   В массиве есть секция 'Default', в которой хранятся параметры по-умолчанию.
    #   Т.е. в ней можно хранить параметры общие для всех, и переопределять их
    #   только там где нужно, в секциях для отдельных интерфейсов
    ########################################
:global ddnsInterfacesParamsDef [:toarray ""]
    # секция Default
:set ($ddnsInterfacesParamsDef->"default") [:toarray ""]
    # URL сервера API для всех интерфейсов
:set ($ddnsInterfacesParamsDef->"default"->"url") "<URL API REST SERVER>"
    # имя пользователя подключающегося к серверу API
:set ($ddnsInterfacesParamsDef->"default"->"user") "<USERNAME>"
# URL сервера API
    # пароль, токен и т.д. и т.п. для всех интерфейсов
:set ($ddnsInterfacesParamsDef->"default"->"password") "<YOUR PASSWORD(TOKEN)>"
    # max количество записей за один запрос при запросе списка хостов в домене
    # поддерживается у некоторых провайдеров
:set ($ddnsInterfacesParamsDef->"default"->"maxReadRecordsDNS") [:tonum 1000]
    # секция для конкретного интерфейса
:set ($ddnsInterfacesParamsDef->"pppoe-rtc") [:toarray ""]
    # имя хоста
:set ($ddnsInterfacesParamsDef->"pppoe-rtc"->"hostname") "hk.av-kms.ru"
    # имя домена, используется многими провайдерами. Поэтому не стал вычленять из имени хоста
:set ($ddnsInterfacesParamsDef->"pppoe-rtc"->"domain") "av-kms.ru"
    # отсылать E-Mail при изменении адреса или нет
:set ($ddnsInterfacesParamsDef->"pppoe-rtc"->"sendEmail") Yes
    # провайдер DNS, от нее зависит какой плугин вызывать
:set ($ddnsInterfacesParamsDef->"pppoe-rtc"->"typeDNS") "SELeCTeL"
    # Флаг проверять разрешенный ("белый") или нет IP адрес у интерфейса
    # Используется в функции. Если TRUE и IP "серый", тогда не менять записи в DynDNS.
:set ($ddnsInterfacesParamsDef->"pppoe-rtc"->"checkBogon") false
    # Флаг проверять активный (включенный) или нет интерфейс
    # Используется в функции. Если TRUE и инетефейс не включен, тогда не менять записи в DynDNS.
:set ($ddnsInterfacesParamsDef->"pppoe-rtc"->"checkActive") true
    # пароль, токен и т.д. и т.п. для конкретного интерфейса
:set ($ddnsInterfacesParamsDef->"pppoe-rtc"->"password") "<YOUR PASSWORD(TOKEN)>"
    # URL сервера API для конкретного интерфейса
:set ($ddnsInterfacesParamsDef->"pppoe-rtc"->"url") "https://api.selectel.ru/domains/v1"
    # max количество записей за один запрос при запросе списка хостов в домене для конкретного интерфейса
    # поддерживается у некоторых провайдеров
#:set ($ddnsInterfacesParamsDef->"pppoe-rtc"->"maxReadRecordsDNS") [:tonum 150]
    # следующий интерфейс
:set ($ddnsInterfacesParamsDef->"l2tp-kms") [:toarray ""]
:set ($ddnsInterfacesParamsDef->"l2tp-kms"->"hostname") "test-hk.mrovo.ru"
:set ($ddnsInterfacesParamsDef->"l2tp-kms"->"domain") "mrovo.ru"
:set ($ddnsInterfacesParamsDef->"l2tp-kms"->"sendEmail") Yes
:set ($ddnsInterfacesParamsDef->"l2tp-kms"->"typeDNS") "SELeCTeL"
:set ($ddnsInterfacesParamsDef->"l2tp-kms"->"checkBogon") false
:set ($ddnsInterfacesParamsDef->"l2tp-kms"->"checkActive") true
:set ($ddnsInterfacesParamsDef->"l2tp-kms"->"password") "<YOUR PASSWORD(TOKEN)>"
:set ($ddnsInterfacesParamsDef->"l2tp-kms"->"url") "https://api.selectel.ru/domains/v1"
#:set ($ddnsInterfacesParamsDef->"l2tp-kms"->"maxReadRecordsDNS") [:tonum 150]
:set ($ddnsInterfacesParamsDef->"ether8-test") [:toarray ""]
:set ($ddnsInterfacesParamsDef->"ether8-test"->"hostname") "test-hk.mrovo.ru"
:set ($ddnsInterfacesParamsDef->"ether8-test"->"domain") "mrovo.ru"
:set ($ddnsInterfacesParamsDef->"ether8-test"->"sendEmail") Yes
:set ($ddnsInterfacesParamsDef->"ether8-test"->"typeDNS") "SELeCTeL"
:set ($ddnsInterfacesParamsDef->"ether8-test"->"checkBogon") false
:set ($ddnsInterfacesParamsDef->"ether8-test"->"checkActive") false

:global ddnsInterfacesParamsTwo [:toarray ""]
:set ($ddnsInterfacesParamsTwo->"default") [:toarray ""]
:set ($ddnsInterfacesParamsTwo->"default"->"url") "https://apidns.mrovo.ru/dns"
:set ($ddnsInterfacesParamsTwo->"default"->"user") "avv"
:set ($ddnsInterfacesParamsTwo->"default"->"password") "YOUR PASSWORD(TOKEN)"
:set ($ddnsInterfacesParamsTwo->"default"->"maxReadRecordsDNS") [:tonum 1000]
:set ($ddnsInterfacesParamsTwo->"pppoe-rtc") [:toarray ""]
:set ($ddnsInterfacesParamsTwo->"pppoe-rtc"->"hostname") "hk.mrovo.ru"
:set ($ddnsInterfacesParamsTwo->"pppoe-rtc"->"domain") "mrovo.ru"
:set ($ddnsInterfacesParamsTwo->"pppoe-rtc"->"sendEmail") Yes
    # провайдер DNS, от нее зависит какой плугин вызывать
:set ($ddnsInterfacesParamsTwo->"pppoe-rtc"->"typeDNS") "SELeCTeL"
:set ($ddnsInterfacesParamsTwo->"pppoe-rtc"->"checkBogon") false
:set ($ddnsInterfacesParamsTwo->"pppoe-rtc"->"checkActive") true
:set ($ddnsInterfacesParamsTwo->"pppoe-rtc"->"password") "YOUR PASSWORD(TOKEN)"
:set ($ddnsInterfacesParamsTwo->"pppoe-rtc"->"url") "https://api.selectel.ru/domains/v1"
#:set ($ddnsInterfacesParamsTwo->"pppoe-rtc"->"maxReadRecordsDNS") [:tonum 150]

    ########################################
    ### global parameteres for mail ###########################
    #   Переменные для отправки почты
    #   Используется в функции initOnStart::sendEmail
    ########################################
    # SMTP сервер
:global smtpserv "SMTP SEREVR";
    # Учетка на SMTP сервере
:global Eaccount "EMAIL";
    # Пароль от учетки на SMTP сервере
:global pass "PASSWORD";
    # Порт на SMTP сервере
:global port 465;
    # Использовать ли TLS на SMTP сервере
:global tls tls-only;
#:global smtpserv "SMTP SERVER";
#:global Eaccount "EMAIL";
#:global pass "PASSWORD";
#:global port 587;
#:global smtpserv "SMTP SERVER";
#:global Eaccount "EMAIL";
#:global pass "PASSWORD";
#:global port 465;

    ########################################
    #   HASHTABLE переменная.
    #   [
    #       'server'=[]
    #       'keyname'=[]
    #       'tsig'=[]
    #       'zone'=[]
    #       'ttl' - ttl
    #   ]
    #   HASHTABLE с данными для обновления записей в локальном DNS сервере.
    #   Используется в локальном DHCP сервере для обновления записей DNS локального
    ########################################
:global homeDNS [:toarray ""]
    # IP адрес локального DNS сервера
:set ($homeDNS->"server") 192.168.115.97
    # имя TSIG ключа, авторизованного для данного сервера
:set ($homeDNS->"keyName") "home-lan-key"
    # TSIG ключ
:set ($homeDNS->"tsig") "<TSIG KEY>"
    # локальная зона (домен)
:set ($homeDNS->"zone") "home.lan"
    # ttl для записи
:set ($homeDNS->"ttl") 300
```

### Функции в модуле

---
#### oneInterface2DDNS
    Обновить запись на DNS для интерфейса
    Input:
        iface   -- имя интерфейса
        isDebug -- логировать или нет
        interfacesData -- data on the interface on the DNS hoster for DNS record,
                          :global $ddnsInterfacesParamsDef in this array, all settings for DDNS apidns are default, unless interfacesData is passed

#### statusIF
    Get status interface (disabled or enabled, ipv4, ipv4 full, isBogon, active or not)
    Input:
        ifname  -- имя интерфейса
    
    Если интерфейс 

---
## JParseFunctions
Не моя библиотека, выловленна на просторах Inet'а. Спасибо автору.

Работа с JSON текстом (файлами). Перевод в массив.


---
# Пока лень описывать далее. ПОТОМ. TODO.

