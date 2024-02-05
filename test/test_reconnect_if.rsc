:local scriptname "reconnect_if"

:global islog;
:global alwaysEnableInterfaces;
:global statusIF
:global ipIsGray

:local ifaces $alwaysEnableInterfaces;

:local isdeb (false)

:local changeStatus false;
:local isBogon false;

:if ($islog=true or $isdeb=true) do={
  :log info "scriptname: $scriptname BEGIN =========================================================="
}
  :log info ("Interfaces are always on: ")
  :log info ($ifaces)

:if ($islog=true or $isdeb=true) do={
  :log info ("Interfaces are always on: ")
  :log info ($ifaces)
}

foreach iface in=$ifaces do={
  :local stat [$statusIF ifname=$iface];
  :set isBogon [$ipIsGray ipfull=($stat->"ipm")]
  :local isEnb [:tobool ($stat->"running")]
  :if ($isdeb=true) do={
    :log info [:typeof $iface]
    :log info "Interface: $iface"
    :log info "This is a private address: $isBogon"
    :log info ($stat)
    :log info ($stat->"ipm")
    :log info ($stat->"ipm" in 10.0.0.0/8)
    :log info $isEnb
  }
  :if ($isEnb = true) do={
    :if ($isBogon=true) do={
      :if ($isdeb=true) do={
        :log info "Turned on, but the address is BOGON, reconnect."
        /interface disable $iface
        :set changeStatus true
        :delay 3000ms
        /interface enable $iface
      }
    }
  } else={
    :if ($isdeb=true) do={
      :log info "Turned off, enable"
    }
    :set changeStatus true
    /interface enable $iface
  }
  :if ($islog=true) do={
    :if (!$changeStatus) do={
      :log info ("interface $iface NOT change status")
    } else={
      :log info ("interface $iface change status")
    }
  }
}

:if ($islog=true or $isdeb=true) do={
  :log info "scriptname: $scriptname END ============================================================="
}
