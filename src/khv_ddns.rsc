:local scriptname "khv_ddns === DynDNS apidns av-kms.ru"

:global ddnsInterfaces;
:global ddnsInterfacesParamsDef;
:global ddnsInterfacesParamsTwo;

:global islog;
:global oneInterface2DDNS;

:local isDeb (false)
#:set isDeb (true)

:if ($islog || $isDeb) do={:log info ("Service $scriptname: START===============================")}

#foreach i in=$ddnsInterfaces do={:put [$oneInterface2DDNS iface=$i isDebug=$isDeb];}
foreach i in=$ddnsInterfaces do={ $oneInterface2DDNS iface=$i isDebug=$isDeb; }

:local oneIface "pppoe-rtc"
#$oneInterface2DDNS iface=$oneIface isDebug=$isDeb interfacesData=$ddnsInterfacesParamsTwo

:if ($islog || $isDeb) do={:log info ("Service $scriptname: END===============================")}