:global  oneInterface2DDNS
:global ddnsInterfacesParamsDef
:global ddnsInterfacesParamsTwo

#:local r [$oneInterface2DDNS iface="lte1" isDebug=true interfacesData=$ddnsInterfacesParamsTwo]
#if ( ($r->"results"->"r_oneInterface2DDNS") ) do={
#  :set ddnsInterfacesParamsTwo $r
#}

:local r [$oneInterface2DDNS iface="lte1" isDebug=true]
if ( ($r->"results"->"r_oneInterface2DDNS") ) do={
  :set ddnsInterfacesParamsDef $r
}