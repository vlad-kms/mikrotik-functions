
:global islog;

### Variables for wol data computers
:global wolComps [:toarray ""]
:local l [:len $wolComps]
:set ($wolComps->$l) [:toarray ""]
:set ($wolComps->$l->"mac")  "00:E0:4C:68:03:DC"
:set ($wolComps->$l->"ip")  "192.168.15.202"
:set ($wolComps->$l->"iface")  "vlan15"
:set ($wolComps->$l->"name")  "root.home.lan"

:set l [:len $wolComps]
:set ($wolComps->$l) [:toarray ""]
:set ($wolComps->$l->"mac")  "D4:0D:AB:14:13:AB"
#:set ($wolComps->$l->"ip")  "192.168.16.201"
:set ($wolComps->$l->"iface")  "vlan16"
:set ($wolComps->$l->"name")  "pmx.home.lan"

:set l [:len $wolComps]
:set ($wolComps->$l) [:toarray ""]
:set ($wolComps->$l->"mac")  "00:E0:4C:68:06:E2"
:set ($wolComps->$l->"ip")  "192.168.15.90"
:set ($wolComps->$l->"iface")  "vlan15"
:set ($wolComps->$l->"name")  "tn.home.lan"

:local l [:len $wolComps]
:set ($wolComps->$l) [:toarray ""]
:set ($wolComps->$l->"mac")  "00:E0:4C:68:03:D0"
:set ($wolComps->$l->"ip")  "192.168.15.202"
:set ($wolComps->$l->"iface")  "vlan15"
:set ($wolComps->$l->"name")  "root.home.lan"

:if ($islog) do={
  :log info "INIT script_WOL"
  :log info $wolComps
}

###########################################################################################################
###########################################################################################################
# Найти по ip, имени хоста данные для WoL (mac-адрес и имя интерфейса)
# Parameters:
#   ip      - ip address
#   host    - hostname
#   isDebug - логировать или нет. Логируется если глобальная islogFunc=True || isDebug=True
# Use:
#   $findMAC host=hostname ip=ip_addr
# Ищет в глобальном массиве wolComps, затем в DHCP lease's и затем в Cashe ARP,
# объединяя полученные результаты и убирая дубли по интерфейсу и mac-адресу
###########################################################################################################
###########################################################################################################
:global findMAC do={

  :global islogFunc
  :global my2bool;
  :global logFunc
  :global wolComps
  :global upper

  #:local isDeb [$my2bool value=$isDebug];
  #:set isDeb ([:tobool $islogFunc] || [:tobool $isDeb]);
  :local isDeb ([$my2bool value=$islogFunc] || [$my2bool value=$isDebug])
  :local fname "findMAC"

  $logFunc topic="info" text=(">>> $0 START: ip: $ip; host: $host; isDebug: $isDebug") isDebug=$isDeb

  :local targetIp "$ip"
  :local targetHost "$host"
  # короткое имя хоста без домена
  :local shortHost "$targetHost"
  :if ([:find $targetHost "."] >= 0) do={
    :set shortHost [:pick $targetHost 0 [:find $targetHost "."]]
  }

  # Вспомогательная функция: добавляет запись в $result, если такой пары mac+iface еще нет
  :local addResult do={
    :local list $arr
    :local newMac ($entry->"mac")
    :local newIface ($entry->"iface")
    :local exists false

    :foreach k,v in=$list do={
      :if ((($v->"mac") = $newMac) && (($v->"iface") = $newIface)) do={
        :set exists true
      }
    }

    :if (!$exists) do={
      :set ($list->[:len $list]) $entry
    }
    :return $list
  }

  :local result [:toarray ""]
  # 1. ПОИСК В МАССИВЕ $wolComps
  :foreach k,v in=$wolComps do={
    :local match false
    :if (([:len $targetIp] > 0) && (($v->"ip") = $targetIp)) do={ :set match true }
    :if (([:len $targetHost] > 0) && ((($v->"name") = $targetHost) || (($v->"name") = $shortHost))) do={ :set match true }

    :if ($match) do={
      $logFunc isDebug=$isDeb prefix=("$fname added element: ") text=$v
      :set result  [$addResult arr=$result entry=$v]
    }
  }
  $logFunc isDebug=$isDeb prefix=("$fname: found in result $([:len $result]) after find in wolComps: ") text=$result

  # ----------------------------------------------------------------------------
  # 2. ПОИСК В DHCP LEASES (/ip/dhcp-server/lease)
  # Объединяем результаты по IP, host-name и тегу [dns:...] в comment
  # ----------------------------------------------------------------------------
  :local leaseIds [:toarray ""]

  #>>>> Вспомогательная локальная функция для добавления ID в $leaseIds без дубликатов
  :local addUniqueId do={
    :local list $arr
    :if ([:typeof [:find $list $item]] = "nil") do={
      :set list ($list , $item)
    }
    :return $list
  }
  #<<<< Вспомогательная локальная функция для добавления ID в $leaseIds без дубликатов

  # 2.1. Поиск по IP
  :if ([:len $targetIp] > 0) do={
    :foreach id in=[/ip/dhcp-server/lease/find address="$targetIp"] do={
      :set leaseIds [$addUniqueId arr=$leaseIds item=$id]
    }
  }
  # 2.2. Поиск по системному host-name
  :if (([:len $leaseIds] = 0) && ([:len $targetHost] > 0)) do={
    :foreach id in=[/ip/dhcp-server/lease/find host-name="$targetHost"] do={
      :set leaseIds [$addUniqueId arr=$leaseIds item=$id]
    }
    :foreach id in=[/ip/dhcp-server/lease/find host-name="$shortHost"] do={
      :set leaseIds [$addUniqueId arr=$leaseIds item=$id]
    }
  }
  # 2.3. Поиск по тегу [dns:...] в comment (без учета регистра)
  :if ([:len $targetHost] > 0) do={
    :local taggedIds [/ip/dhcp-server/lease/find comment~"\\[dns:"]
    :foreach tId in=$taggedIds do={
      :local cmt [/ip/dhcp-server/lease/get $tId comment]
      :local startPos [:find $cmt "[dns:"]
      :if ([:typeof $startPos] = "num") do={
        :local valStart ($startPos + 5)
        :local endPos [:find $cmt "]" $valStart]
        :if ([:typeof $endPos] = "num") do={
          :local tagDns [:pick $cmt $valStart $endPos]
          :local tagShort "$tagDns"
          :if ([:find $tagDns "."] >= 0) do={
            :set tagShort [:pick $tagDns 0 [:find $tagDns "."]]
          }

          :local tagDnsUp [$upper value=$tagDns]
          :local tagShortUp [$upper value=$tagShort]

          :if (($tagDnsUp = $targetHostUp) || ($tagDnsUp = $shortHostUp) || ($tagShortUp = $shortHostUp)) do={
            :set leaseIds [$addUniqueId arr=$leaseIds item=$tId]
          }
        }
      }
    }
  }
  $logFunc isDebug=$isDeb text=$leaseIds prefix=("$fname: leaseIds")

  # Сбор всех найденных записей DHCP (включая disabled) в общий массив $result
  :foreach lId in=$leaseIds do={
    :local lData [/ip/dhcp-server/lease/get $lId]
    :local macAddr ($lData->"mac-address")
    :local srvName ($lData->"server")
    :local hName ($lData->"host-name")
    :local cmt ($lData->"comment")
    :local ifaceName ""

    # Если системный host-name пустой, берем имя из тега [dns:...]
    :if ([:len $hName] = 0) do={
      :local startPos [:find $cmt "[dns:"]
      :if ([:typeof $startPos] = "num") do={
        :local valStart ($startPos + 5)
        :local endPos [:find $cmt "]" $valStart]
        :if ([:typeof $endPos] = "num") do={
          :set hName [:pick $cmt $valStart $endPos]
        }
      }
    }
    :if ([:len $hName] = 0) do={ :set hName $targetHost }

    # Определяем интерфейс по имени DHCP-сервера
    :if ([:len $srvName] > 0) do={
      :local srvIds [/ip/dhcp-server/find name="$srvName"]
      :if ([:len $srvIds] > 0) do={
        :set ifaceName [/ip/dhcp-server/get ($srvIds->0) interface]
      }
    }

    :if ([:len $macAddr] > 0) do={
      :local candidate {
        "mac"=$macAddr;
        "ip"=($lData->"address");
        "iface"=$ifaceName;
        "name"=$hName
      }
      $logFunc isDebug=$isDeb prefix=("$fname added element: ") text=$candidate
      :set result [$addResult arr=$result entry=$candidate]
    }
  }
  $logFunc isDebug=$isDeb prefix=("$0: found in result $([:len $result]) after find in DHCP leases: ") text=$result

  # ----------------------------------------------------------------------------
  # 3. ПОИСК В КЭШЕ ARP (/ip/arp) — выполняется если задан IP
  # ----------------------------------------------------------------------------
  :if ([:len $targetIp] > 0) do={
    :local arpIds [/ip/arp/find address="$targetIp"]
    :foreach aId in=$arpIds do={
      :local aData [/ip/arp/get $aId]
      :local candidate {
        "mac"=($aData->"mac-address");
        "ip"=($aData->"address");
        "iface"=($aData->"interface");
        "name"="arp" . ($aData->"mac-address")
      }
      $logFunc isDebug=$isDeb prefix=("$fname added element: ") text=$candidate
      :set result [$addResult arr=$result entry=$candidate]
    }
  }
  $logFunc isDebug=$isDeb prefix=("$fname: found in result $([:len $result]) after find in CASHE ARP: ") text=$result
  $logFunc topic="info" prefix=("<<< $0 END $([:len $result]) in result: ") text=$result isDebug=$isDeb

  :return $result
}

# ==============================================================================
# ФУНКЦИЯ ПРОБУЖДЕНИЯ ПО МАССИВУ ДАННЫХ
# Input:
#   data    - массив с ключами {"mac"=...; "ip"=...; "iface"=...; "name"=...}
#   isDebug - принудительное включение/отключение логов (опционально)
# Output:
#   num  - количество отправленных пакетов
# ==============================================================================
:global wolOneCompArray do={
  :global my2bool
  :global islogFunc
  :global logFunc
  :global findMAC

  :local isDeb ([$my2bool value=$islogFunc] || [$my2bool value=$isDebug])
  #:local fname "wolOneCompArray"
  :local d $data

  $logFunc isDebug=$isDeb prefix=(">>> $0 START: isDebug=$isDebug; data=") text=$d

  :if ([:typeof $d] != "array") do={
    $logFunc isDebug=true text=("!! $0: parameter 'data' is missing or not an array") topic="error"
    :return false
  }

  :local targets [:toarray ""]

  # Вспомогательная функция: добавляет цель в список отправки без дублей по mac+iface
  :local addTarget do={
    :local list $arr
    :local newMac ($entry->"mac")
    :local newIface ($entry->"iface")
    :local exists false

    :foreach k,v in=$list do={
      :if ((($v->"mac") = $newMac) && (($v->"iface") = $newIface)) do={
        :set exists true
      }
    }

    :if (!$exists) do={
      :set ($list->[:len $list]) $entry
    }
    :return $list
  }

  # 1. Если mac и iface уже заданы явно — добавляем сразу
  :if (([:len ($d->"mac")] > 0) && ([:len ($d->"iface")] > 0)) do={
    :set targets [$addTarget arr=$targets entry=$d]
  } else={
    # 2. Иначе ищем все подходящие записи через сквозной $findMAC
    :local foundList [$findMAC ip=($d->"ip") host=($d->"name") isDebug=$isDeb]
    :foreach k,item in=$foundList do={
      :local entry $item
      :if ([:len ($entry->"mac")] = 0) do={ :set ($entry->"mac") ($d->"mac") }
      :if ([:len ($entry->"iface")] = 0) do={ :set ($entry->"iface") ($d->"iface") }
      :if ([:len ($entry->"ip")] = 0) do={ :set ($entry->"ip") ($d->"ip") }
      :if ([:len ($entry->"name")] = 0) do={ :set ($entry->"name") ($d->"name") }

      :set targets [$addTarget arr=$targets entry=$entry]
    }
  }

  # 3. Отправка WOL-пакетов по всем собранным целям
  :local sentCount 0
  :foreach k,t in=$targets do={
    :if (([:len ($t->"mac")] > 0) && ([:len ($t->"iface")] > 0)) do={
      $logFunc isDebug=$isDeb text=("$0: sending WOL to " . ($t->"name") . " (" . ($t->"mac") . ") via " . ($t->"iface"))
      #/tool wol mac=($t->"mac") interface=($t->"iface")
      :set sentCount ($sentCount + 1)
    } else={
      $logFunc isDebug=true prefix=("!! $0: incomplete target (missing MAC or iface): ") text=$t topic="warning"
    }
  }

  $logFunc isDebug=$isDeb text=("<<< $0 END: successfully sent " . $sentCount . " WOL packet(s)")
  :return [:tonum $sentCount]
}

# ==============================================================================
# ФУНКЦИЯ-ОБЕРТКА ДЛЯ БЫСТРОГО ПРОБУЖДЕНИЯ ПО IP ИЛИ ИМЕНИ ХОСТА
# Input:
#   ip      - IP-адрес устройства (опционально)
#   host    - имя хоста или FQDN (опционально)
# может быть позиционный параметр
#   $1      - позиционный параметр: автоматически распознается как IP или host
#   isDebug - принудительное включение/отключение логов (опционально)
# Output:
#   true / false (результат работы $wolOneCompArray)
# ==============================================================================
:global wolOneComp do={
  :global my2bool
  :global islogFunc
  :global logFunc
  :global wolOneCompArray

  :local isDeb ([$my2bool value=$islogFunc] || [$my2bool value=$isDebug])
  #:local fname "wolOneComp"

  :local targetIp "$ip"
  :local targetHost "$host"

  $logFunc topic="info" text=(">>> $0 START : ip=$ip; host=$host isDebug=$isDebug") isDebug=$isDeb

  # Поддержка позиционного вызова: [$wolOneComp "pmx.home.lan"] или [$wolOneComp "192.168.15.202"]
  :if (([:len $targetIp] = 0) && ([:len $targetHost] = 0) && ([:typeof $1] != "nothing")) do={
    :local arg [:tostr $1]
    :if ([:typeof [:toip $arg]] = "ip") do={
      :set targetIp $arg
    } else={
      :set targetHost $arg
    }
  }

  $logFunc isDebug=$isDeb text=("$0: targetIp=$targetIp targetHost=$targetHost")

  :if (([:len $targetIp] = 0) && ([:len $targetHost] = 0)) do={
    $logFunc isDebug=true text=("!! $0: neither 'ip' nor 'host' provided") topic="error"
    :return false
  }

  :local data {
    "mac"="";
    "ip"=$targetIp;
    "iface"="";
    "name"=$targetHost
  }

  :local res [$wolOneCompArray data=$data isDebug=$isDeb]
  $logFunc isDebug=$isDeb text=("<<< $0 END: result=" . [:tostr $res])
  :return $res
}
