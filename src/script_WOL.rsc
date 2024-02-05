
:global islog;

### Variables for wol data computers
:global wolComps [:toarray ""]
:set ($wolComps->"0") [:toarray ""]
:set ($wolComps->"0"->"mac")  "24:4B:FE:07:4D:62"
:set ($wolComps->"0"->"ip")  "192.168.15.202"
:set ($wolComps->"0"->"iface")  "vlan15"
:set ($wolComps->"0"->"name")  "root.home.lan"

:set ($wolComps->"1") [:toarray ""]
:set ($wolComps->"1"->"mac")  "C8:60:00:C6:76:13"
#:set ($wolComps->"1"->"ip")  "192.168.15.202"
:set ($wolComps->"1"->"iface")  "vlan16"
:set ($wolComps->"1"->"name")  "stkh.home.lan"

:if ($islog) do={
  :log info "INIT script_WOL"
  :log info $wolComps
}

###########################################################################################################
###########################################################################################################
# Search in table ARP MAC-address of hostname or ip-address
# Parameters:
#   ip      - ip address
#   host    - hostname
#   isDebug - flag for outpur logging message
# Use:
#   $findMAC host=hostname ip=ip_addr
# The ip parameter takes precedence over hostname, i.e. if two parameters are specified, then ip will be used
###########################################################################################################
###########################################################################################################
:global findMAC do={

  :global islogFunc;
  :global my2bool;

  :local isDeb [$my2bool value=$isDebug];
  :set $isDeb ([:tobool $islogFunc] || [:tobool $isDeb]);

  :if ($isDeb) do={
    :log info "START function: $0 ==============="
  }

  # on what basis are we looking for an ARP record
  # 0 - by ip address
  # 1 - by hostname
  :local whatFind 0

  :if ([:typeof $host]="str" && $host!="") do={ :set $whatFind 1 }
  :if ([:typeof $ip]="str" && $ip!="") do={ :set $whatFind 0 }
  :if ($whatFind=1) do={
    # resolve hostname to ip address
    do {
      :set $ip [:resolve $host]
    } on-error={
      : local msg "ERROR findMAC ::: not ip address for finding ARP record"
      :log info "$msg"
      :error "$msg"
    }
  }
  # find record in ARP list
  :local res ([/ip/arp/get [/ip/arp/find address="$ip"]])
  :if ($isDeb) do={
    :log info $res
  }

  :if ($isDeb) do={
    :log info "END function: $0 ==============="
  }

  return $res
}

###########################################################################################################
###########################################################################################################
# Turn on the computer using WOL (wake-on-lan)
# Parameters:
#   data    - array (mac, ip, iface, name)
#   isDebug - flag for outpur logging message
# Use:
#   $wolOneCompArray host=hostname ip=ip_addr
# If '$data->mac' or '$data->iface' are not defined, then first calculate them in function 'findMAC'
###########################################################################################################
###########################################################################################################
:global wolOneCompArray do={

  :global findMAC
  :global islogFunc;
  :global my2bool;

  :local isDeb [$my2bool value=$isDebug];
  :set $isDeb ([:tobool $islogFunc] || [:tobool $isDeb]);

  :if ($isDeb) do={
    :log info "START function: $0 ==============="
    :log info "data before processing"
    :log info $data
  }

  # If '$data->mac' or '$data->iface' are not defined, then first calculate them in function 'findMAC'
  :if ( [:typeof ($data->"mac")]="nothing" || ($data->"mac")="" || [:typeof ($data->"iface")]="nothing" || ($data->"iface")="" ) do={
    :if ($isDeb) do={
      :log info "Are not defined mac"
    }
    :local tempData [$findMAC ip=($data->"ip") host=($data->"name")]
    :set ($data->"iface") ($tempData->"interface")
    :set ($data->"mac") ($tempData->"mac-address")
  }
  :if ($isDeb) do={
    :log info "data after processing"
    :log info $data
  }

  # wol computers
  :if ($isDeb) do={
    :local mac ($data->"mac")
    :local iface ($data->"iface")
    :log info "run ::: /tool/wol mac=$mac interface=$iface"
  }

  /tool wol mac=($data->"mac") interface=($data->"iface")

  :if ($isDeb) do={
    :log info "END function: $0 ================="
  }
}

#####################################################
#####################################################
#####################################################
:global wolOneComp do={
  # Parameters:
  #   ip      - ip address
  #   host - hostname
  # If '$data->mac' or '$data->iface' are not defined, then first calculate them in function 'findMAC'

  :global wolOneCompArray
  :global my2bool;

  :global islogFunc;
  :local isDeb [$my2bool value=$isDebug];
  :set $isDeb ([:tobool $islogFunc] || [:tobool $isDeb]);

  :if ($isDeb) do={
    :log info "START function: $0 ==============="
  }

  #
  :local data [:toarray ""]
  :set ($data->"ip") $ip
  :set ($data->"name") $host

  $wolOneCompArray data=$data

  :if ($isDeb) do={
    :log info "END function: $0 ================="
  }
}
###################################################################################