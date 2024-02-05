######################################
### :global sendEmail
### :global my2bool
### :global upper
### :global ipIsGray
### :global isBogon
### :global statusIF
### :global oneInterface2DDNS
### :global putItem2localDNS - update record DNS leasing address ocer DHCP
### :global reconnectIF
### :global pluginUpdDNSselectel
### :global nameDomainFromFullname
######################################

### initialize global variable ###
/system script run initVars

### add library parser JSON JParseFunctions ###
/system script run "JParseFunctions";global JSONLoad; global JSONLoads; global JSONUnload
### add library with functions work with string ###
/system script run "libString"
### add library plugins for working DNS hostingers ###
/system script run pluginDNS

/system script run script_WOL


#########################################################
# DEFINE functions ###########################################
#########################################################

:global sendEmail do={
##############################
#   Send e-mail
#   Input:
#      server -- smtp server
#      from ---- email account on whose behalf the letter is to be sent
#      pwd ----- password of account
#      pTO ----- to whom to send a letter
#      pCC ----- to whom to send a copy of the letter
#      subj ------ subj letter
#      pBODY - body letter
#      pPORT  - port smtp on server
#      pFILE --- file to send
#      pTLS ---- use tls or no
#   Output: Not
##############################

  :global my2bool
  :global upper
  :global islogFunc
  :global smtpserv
  :global Eaccount
  :global pass
  :global port
  :global tls

  :local isDeb [$my2bool value=$isDebug];
  :set $isDeb ([:tobool $isDeb] || [:tobool $islogFunc])

  :local serv $smtpserv;
  :local acct $Eaccount;
  :local passwd $pass;
  :local portL $port;
  :local lTLS  $tls;
  :local cc ""
  :local to ""

  :if ($isDeb) do={
    :log info "function: $0 START ============================================================="
  }

  :if ([:typeof $server]="str" && $server!="") do={ :set $serv $server }
  :if ([:typeof $from]="str" && $from!="") do={ :set $acct $from }
  :if ([:typeof $pwd]="str" && $pwd!="") do={ :set $passwd $pwd }
  :if ([:typeof $pCC]="str" && $pCC!="") do={ :set $cc $pCC }
  :if ([:typeof $pTO]="str" && $pTO!="") do={ :set $to $pTO }
  :if ([:typeof $pPORT]="num" && $pPORT>0) do={ :set $portL $pPORT }
  :if ([:typeof $pTLS]="str" && $pPORT!="") do={ :set $lTLS $pTLS }

  :if ($to="") do={ :set $to $cc }
  :if ($to="") do={ :set $to $Eaccount }

  :if ($isDeb) do={
    :log info "Input params:"
    :log info "IsDeb: $isDeb"
    :log info "islogFunc: $islogFunc"
    :log info "body: $body"
    :log info "subj: $subj"
    :log info "server: $server"
    :log info "from: $from"
    :log info "pwd: $pwd"
    :log info "pCC: $pCC"
    :log info "pTO: $pTO"
    :log info "pPORT: $pPORT"
    :log info "pTLS: $pTLS"
    :log info "Prepared params:"
    :log info "serv: $serv"
    :log info "acct: $acct"
    :log info "passwd: $passwd"
    :log info "cc: $cc"
    :log info "to: $to"
    :log info "portL: $portL"
    :log info "lTLS: $lTLS"
    :local typetls [:typeof lTLS]
    :log info "typeof lTLS: $typetls"
  }
  # check the required parameters and exit without sending an email if they are inaccurate.
  :if ( $serv="" || $acct="" || $to="" ) do={
    :log error "Invalid parameters: smtp server, from, to. Letter not sent"
    :return false
  }

  #/tool e-mail send to=$to server=[:resolve ] subject="192.168.1.1 is Down!"
  #log $Eaccount
  #/tool e-mail send from=<$Eaccount> to=<$Eaccount> server=$smtpserv  tls=yes port=587 user=$Eaccount password=$pass subject="RosTeleCom is Down!"
  do {
    #:local res [/tool e-mail send from=$acct to=$to server=[:resolve "$serv"]  tls=$lTLS user=$acct password=$passwd subject=$subj body=$body cc=$cc as-value]
    #/tool e-mail send from=$acct to=$to server=[:resolve $serv]  tls=$lTLS port=$portL user=$acct password=$passwd subject=$subj body=$body cc=$cc
    :local isTLS [:tobool false]
    if ([$upper value=$lTLS]="YES") do={
      :set isTLS [:tobool true]
      :local res [/tool e-mail send from=$acct to=$to server=[:resolve "$serv"]  tls=yes port=$portL user=$acct password=$passwd subject=$subj body=$body cc=$cc as-value]
    }
    if ([$upper value=$lTLS]="STARTTLS") do={
      :set isTLS [:tobool true]
      :local res [/tool e-mail send from=$acct to=$to server=[:resolve "$serv"]  tls=starttls user=$acct password=$passwd subject=$subj body=$body cc=$cc as-value]
    }
    if ( ! $isTLS ) do={
      :log error "Invalid parameters: tls: $lTLS. Letter not sent"
      :return false
    }
  } on-error={
    :log error "Error send letter:"
  }
  :if ($isDeb) do={
    :log info "function: $0 END ============================================================="
  }
}

:global my2bool do={
##############################
#   Converting to bool
#   Input:
#      value - value to convert
#   Output: Bool (TRUE or FALSE).
#      false -
#           1) If nothing is transmitted;
#           2) If the transferred number is 0;
#           3) If the string "false", "f", "0", "", "no", "n" is passed. Strings is case insensitive ;
#           4) If [:tobool false] is passed, boolean false
#      true - in all other cases
##############################
  :global upper
  :local res [:tobool (false)]
  :if ([:typeof $value]!="nothing") do={
    :if ([:typeof $value]="str") do={
      :if ([:len $value]=0) do={
        :set $res (false)
      } else={
        : local val [$upper value=$value]
        :if ( $val="FALSE" || $val="F" || $val="0" || $val="NO" || $val="N") do={ :set $res (false) } else={ :set $res (true) }
      }
    } else={
      :set $res [:tobool $value]
      :if ([:typeof $res]=nil) do={ :set $res (false) }
    }
  }
  return $res
}

:global upper do={
##############################
#   Converting a string to upper or lower case. Only ASCII ENG is converted
#   Input:
#      value - string to convert
#      dir      - Indicates which register to convert, UPPER or LOWER.
#                  If the string "l", "L", "0", "" or the number 0 is passed, then LOWER.
#                  If nothing is transmitted and in other cases UPPER.
#   Output:
#      String in the required register, UPPER or LOWER
##############################
  :local lower [:toarray "a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z"]
  :local upper [:toarray "A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z"]
  :local direction 1

  :if ([:typeof $dir]!="nothing") do={
    :local d [:tostr $dir]
    if ( $d="l" || $d="L" || $d="0" || $d="" ) do={ :set $direction 0 }
  }
  :local result ""
  :for idx from=0 to=([:len $value] - 1) do={
    :local char [:pick $value $idx]
    :local match
    :if ($direction!=0) do={
      # UPPER
      :for i from=0 to=[:len $lower] do={
        :set $match ($lower->$i)
        :if ($char = $match) do={:set $char ($upper->$i)}
      }
    } else={
      # LOWER
      :for i from=0 to=[:len $upper] do={
        :set $match ($upper->$i)
        :if ($char = $match) do={:set $char ($lower->$i)}
      }
    }
    :set $result ($result.$char)
  }
  :return $result
}

:global ipIsGray do={
##############################
#   Check if the ipv4 address is "gray" or public.
#   Input:
#      ipfull - ipv4 address
#   Output:
#      true   - the address is "gray", is not public
#      false - the address is public
#224.0.0.0/4    Multicast
#240.0.0.0/4    Reserved for future use
#255.255.255.255/32 Limited broadcast
##############################
  :local isBogon false;
  :local isDeb (false)
  :set isBogon [:tobool ( ($ipfull in 192.168.0.0/16) or ( $ipfull in 10.0.0.0/8) or ( $ipfull in 172.16.0.0/12) )]
  :set isBogon [:tobool ( $isBogon or ($ipfull in 0.0.0.0/8) or ( $ipfull in 100.64.0.0/10) or ( $ipfull in 127.0.0.0/8) )]
  :set isBogon [:tobool ( $isBogon or ($ipfull in 169.254.0.0/16) or ( $ipfull in 192.0.0.0/24) or ( $ipfull in 192.0.2.0/24) )]
  :set isBogon [:tobool ( $isBogon or ($ipfull in 198.18.0.0/15) or ( $ipfull in 198.51.100.0/24) or ( $ipfull in 203.0.113.0/24) )]
  :set isBogon [:tobool ( $isBogon or ($ipfull in 224.0.0.0/4) or ( $ipfull in 240.0.0.0/4) or ( $ipfull in 255.255.255.255/32) )]
  :if ($isDeb) do={
    :log info "ipIsGray"
    :log info $isBogon
  }
  :return $isBogon
}

:global isBogon do={
##############################
#   Is ALIAS function ipisGray
#   Check if the ipv4 address is "gray" or public.
#   Input:
#      ipfull - ipv4 address
#   Output:
#      true   - the address is "gray", is not public
#      false - the address is public
##############################
  :global ipIsGray

  :return [$ipIsGray ipfull=$ipfull]
}

:global statusIF do={
##############################
#   Get status interface (disabled or enabled, ipv4, ipv4 full, isBogon, active or not)
#      Input:
#         ifname - name interface (pppoe-rtc, ethernet5 etc)
#         ifData   - data for interface
##############################

  :global islogFunc;
  :global isBogon;
  :global my2bool;

  :local isData [:tobool false]
  :local useAPI [:tobool false];

  :if ( $islogFunc ) do={
    :log info ("function $0 (".$ifname.") START ===========================");
  }

  :if ([:typeof $ifData]="nothing") do={
    :set isData [:tobool false]
  } else={
    :set isData [:tobool true]
  }
  :if ( $islogFunc ) do={
    :log info ("isData: ".$isData);
  }

  :if ( $isData ) do={
    :if ( $islogFunc) do={
      :log info ("ifData");
      :log info ($ifData);
    }
    :if ([:typeof ($ifData->"isExternalDevice")]="nothing") do={
      :set useAPI [tobool false];
    } else={
      :set useAPI [$my2bool value=($ifData->"isExternalDevice")];
    }
  }
  :if ( $islogFunc ) do={
    :log info ("useAPI: ".$useAPI);
  }

  :local result [:toarray ""]
  :local r [/interface get $ifname ]
  :set ($result->"disabled") ($r->"disabled")
  :set ($result->"running") ($r->"running")
  :local ipad ""
  :if ($result->"running") do={
    :if ($useAPI) do={
      ### disable all address list "list_getip_"
      :foreach li in=[/ip firewall address-list find list~"list_getip_"] do={/ip firewall address-list disable $li;}
      ### enable address list "list_getip_".$ifname
      :foreach li in=[/ip firewall address-list find list="list_getip_".$ifname] do={/ip firewall address-list enable $li;}
      ### run http query to https://ipv4-internet.yandex.net/api/v0/ip
      :delay 3;
      :local res [/tool fetch url="https://ipv4-internet.yandex.net/api/v0/ip" mode=https http-method=get as-value output=user];

      :local lip ($res->"data");
      :local fch [:pick $lip 0 1]
      :if ($fch="\"") do={
        :set ($res->"data") [:toip [:pick $lip 1 ([:len $lip]-1)]]
      }

      :if ( $islogFunc ) do={
        :log info "res!!!:"
        :log info ($res)
      }
      :set ipad ($res->"data"."/32")
    } else={
      :set ipad [/ip address get [/ip address find interface=$ifname] address]
    }
  }
  :set ($result->"ipm") $ipad
  :set ($result->"isBogon") [$isBogon ipfull=$ipad]
  ### From the IP address received on the interface by excluding the mask ###
  :for i from=( [:len $ipad] - 1) to=0 do={
    :if ( [:pick $ipad $i] = "/") do={
      :set ipad [:pick $ipad 0 $i];
      #:break;
    }
  }
  :set ($result->"ip") $ipad

  :if ( $islogFunc ) do={
    :log info ("Status: ");
    :log info ($result);
    :log info ("function $0 (".$ifname.") END ===========================");
  }

  :return ($result)
}

:global oneInterface2DDNS do={
##############################
#   Update a DNS record for one interface
#   Input:
#      iface       -- str Name interface
#      isDebug -- enable logging or not
#      interfacesData - data on the interface on the DNS hoster for DNS record,
#                                    :global $ddnsInterfacesParamsDef in this array, all settings for DDNS apidns are default, unless interfacesData is passed
##############################

  :global islogFunc;
  :global ddnsInterfacesParamsDef;
  :global statusIF;
  :global my2bool;
  :global sendEmail;
  :global upper;
  :global nameDomainFromFullname;
  :global updateRecordSelectel;

  ### initialize logging flag ###
  :local isDeb [$my2bool value=$isDebug];
  :set $isDeb ([:tobool $isDeb] || [:tobool $islogFunc])
  :if ($isDeb) do={
    :log info "START function $0 ===============================================";
  }

  ### find out what data on the interfaces to use ###
  :local ddnsInterfacesParams [:toarray ""];
  :if ([:typeof $interfacesData]="nothing") do={
     ### array with interface data not sent ###
    :set ddnsInterfacesParams $ddnsInterfacesParamsDef
  } else={
    :set ddnsInterfacesParams $interfacesData
  }
  :set ($ddnsInterfacesParams->"results"->"r_oneInterface2DDNS") [:tobool false]

  :if ($isDeb) do={
    :log info $iface
    :log info ($ddnsInterfacesParams->"default")
    #:log info [:typeof ($ddnsInterfacesParams->"default")]
    #:log info [:typeof ($ddnsInterfacesParams->"$iface")]
    :if ([:typeof ($ddnsInterfacesParams->"$iface")]!=nil && [:typeof ($ddnsInterfacesParams->"$iface")]!="nothing" && [:len ($ddnsInterfacesParams->"$iface")]!=0) do={
      :log info ($ddnsInterfacesParams->"$iface")
    }
  }

  ### no transferred interface in settings for DNS ###
  :if ([:typeof ($ddnsInterfacesParams->"$iface")]="nil" || [:typeof ($ddnsInterfacesParams->"$iface")]="nothing" || [:len ($ddnsInterfacesParams->"$iface")]=0) do={
    :log warning ("No transferred interface in settings for DNS")
    #:return (false)
    :return $ddnsInterfacesParams;
  }
  ### check if URL exists in parameters DNS API
  :local url ""
  ### There is a server API url in the parameters default ###
  :if ( [:typeof ($ddnsInterfacesParams->"default"->"url")]="str") do={
    :set $url ($ddnsInterfacesParams->"default"->"url")
  }
  ### Server API url in adapter parameters ###
  :if ( [:typeof ($ddnsInterfacesParams->"$iface"->"url")]="str" && [:len ($ddnsInterfacesParams->"$iface"->"url")]!=0 ) do={
    :set $url ($ddnsInterfacesParams->"$iface"->"url")
  }
  :if ( $url="" ) do={
    :log warning ("No API server for this interface to DNS")
    #:return (false);
    :return $ddnsInterfacesParams;
  }
  :if ($isDeb) do={
    :log info "url: $url"
  }
  ### check the existence login in parameters ###
  :local user ""
  :if ([:typeof ($ddnsInterfacesParams->"default"->"user")]!="nothing") do={
    :set user ($ddnsInterfacesParams->"default"->"user");
  }
  :if ([:typeof ($ddnsInterfacesParams->"$iface"->"user")]!="nothing") do={
    :set user ($ddnsInterfacesParams->"$iface"->"user");
  }
  :if ($islogFunc=true || $isDeb) do={
    :log info "user: $user"
  }
  ### check the existence password ###
  :local pass ""
  :if ([:typeof ($ddnsInterfacesParams->"default"->"password")]!="nothing") do={
    :set pass ($ddnsInterfacesParams->"default"->"password");
  }
  :if ([:typeof ($ddnsInterfacesParams->"$iface"->"password")]!="nothing") do={
    :set pass ($ddnsInterfacesParams->"$iface"->"password");
  }
  :if ($isDeb) do={
    :log info "pwd: $pass"
  }
  ### check the existence hostname ###
  :if ( [:typeof ($ddnsInterfacesParams->"$iface"->"hostname")]="nothing" || [:len ($ddnsInterfacesParams->"$iface"->"hostname")]=0) do={
    :log warning "Hostname not defined"
    #:return (false)
    :return $ddnsInterfacesParams;
  }
  :local hostname ($ddnsInterfacesParams->"$iface"->"hostname")
  :if ($isDeb) do={
    :log info "hostname: $hostname"
  }
  ### check the existence ip address ###
  :local ip ""
  :if ( [:typeof ($ddnsInterfacesParams->"$iface"->"ip")]!="nothing" && [:len ($ddnsInterfacesParams->"$iface"->"ip")]!=0) do={
    :set ip ($ddnsInterfacesParams->"$iface"->"ip")
  }
  ### is exists in data ip OLD address ###
  :local oldIP ""
  :if ( [:typeof ($ddnsInterfacesParams->"$iface"->"oldIP")]!="nothing" && [:len ($ddnsInterfacesParams->"$iface"->"oldIP")]!=0) do={
    :set oldIP ($ddnsInterfacesParams->"$iface"->"oldIP");
  }
  :if ($isDeb) do={
    :log info "ip address OLD: $oldIP"
  }
  ### check the existence typeDNS ###
  :local typeDNS "avv"
  :if ([:typeof ($ddnsInterfacesParams->"$iface"->"typeDNS")]!="nothing") do={
    :set typeDNS ($ddnsInterfacesParams->"$iface"->"typeDNS");
  }
  :set typeDNS [$upper value=$typeDNS]
  :if ($isDeb) do={
    :log info "typeDNS: $typeDNS"
  }
  ### check the existence domain ###
  :local domain ""
  :if ([:typeof ($ddnsInterfacesParams->"$iface"->"domain")]!="nothing" ) do={
    :set domain ($ddnsInterfacesParams->"$iface"->"domain");
  }
  :if ($domain="") do={
    ### try to get the domain name out of the hostname, if domain not passed in the parameters ###
    :set domain [$nameDomainFromFullname nameFQDN=$hostname isDebug=$isDeb]
  }
  :if ($isDeb) do={
    :log info "domain: $domain"
  }
  ### Analyze checkBogon ###
  :local chBg true;
  :if ([:typeof ($ddnsInterfacesParams->"$iface"->"checkBogon")]!="nothing" ) do={
    :set chBg [$my2bool value=($ddnsInterfacesParams->"$iface"->"checkBogon")]
  }
  :if ($isDeb) do={
    :log info "checkBogon: $chBg"
  }
  ### Analyze checkActive   #
  :local chAct true;
  :if ([:typeof ($ddnsInterfacesParams->"$iface"->"checkActive")]!="nothing" ) do={
    :set chAct [$my2bool value=($ddnsInterfacesParams->"$iface"->"checkActive")]
  }
  :if ($isDeb) do={
    :log info "checkActive: $chAct"
  }
  ### analyze maxReadRecordsDNS ###
  :local maxRR [:tonum 200];
  :do {
    :if ([:typeof ($ddnsInterfacesParams->"default"->"maxReadRecordsDNS")]!="nothing" ) do={
      :set maxRR [:tonum ($ddnsInterfacesParams->"default"->"maxReadRecordsDNS")]
    }
    :if ([:typeof ($ddnsInterfacesParams->"$iface"->"maxReadRecordsDNS")]!="nothing" ) do={
      :set maxRR [:tonum ($ddnsInterfacesParams->"$iface"->"maxReadRecordsDNS")]
    }
  } on-error={
    :set maxRR [:tonum 100]
  }
  :if ($isDeb) do={
    :log info "maxReadRecordDNS: $maxRR"
  }

  ### if interface is external device, then true ###
  :local isExternalDevice [:tobool false]
  :if ([:typeof ($ddnsInterfacesParams->"default"->"isExternalDevice")]!="nothing") do={
    :set isExternalDevice ($ddnsInterfacesParams->"default"->"isExternalDevice");
  }
  :if ([:typeof ($ddnsInterfacesParams->"$iface"->"isExternalDevice")]!="nothing") do={
    :set isExternalDevice ($ddnsInterfacesParams->"$iface"->"isExternalDevice");
  }
  :if ($islogFunc=true || $isDeb) do={
    :log info "isExternalDevice: $isExternalDevice"
  }

  ### status interface ###
  :local st [$statusIF ifname=$iface ifData=($ddnsInterfacesParams->"$iface")];
  :if ($isDeb) do={
    :log info "status $iface:"
    :log info $st
  }
  ### If the interface is not active and checkActive, exit ###
  :if ($st->"running"!=true && $chAct) do={
    :log warning "The interface $iface is not active and checkActive"
    #:return (false)
    :return $ddnsInterfacesParams;
  }

  :local isGray [:tobool false]
  :if ($ip="") do={
    :set ip ($st->"ip")
    :set isGray [:tobool ($st->"isBogon")]
  } else={
    :set isGray [:tobool ($isBogon ipfull=$ip)]
  }
  :if ($isDeb) do={
    :log info "ip address: $ip"
    :log info ("isGray: ".[:tostr $isGray])
  }
  ### If the address is "grey" (not public) and checkBogon, then exit ###
  :if ($isGray && $chBg) do={
    :log warning "The address is 'grey' (not public) and checkBogon"
    #:return (false)
    :return $ddnsInterfacesParams;
  }

  ### check if the address does not match with the old one, and if it does not match, change to DNS record ###
  :if ($oldIP!=$ip) do={
    ### set the flag for sending emails ###
    :local sm ([$my2bool value=($ddnsInterfacesParams->"default"->"sendEmail")] || [$my2bool value=($ddnsInterfacesParams->"$iface"->"sendEmail")]);
    :if ($isDeb) do={
      :log info "sendEmail: $sm"
    }
    ### change the address for hostname on the server ###
    :do {
      :local notFindPlugin [:tobool 1]
      :if ($typeDNS="AVV") do={
        :set notFindPlugin [:tobool 0]
        :local result [/tool fetch url="$url/$hostname/$ip/$user/$pass" as-value output=user http-method=post mode=https]
      }
      :if ($typeDNS="SELECTEL" && $notFindPlugin) do={
        :set notFindPlugin [:tobool 0]
        :local result [$updateRecordSelectel url=$url hostname=$hostname ip=$ip pass=$pass domain=$domain maxReadRecords=$maxRR isDebug=$isDeb plugin=$typeDNS iface=$iface data=$ddnsInterfacesParams]
      }
    } on-error={
      :log error "Error change host on valexeev DynDNS - $url/$hostname/$ip/$user/$pass"
      ### Send mail about unsuccessful host change in DNS ###
      :if ( $sm ) do={
        $sendEmail body=("Error change host on valexeev DynDNS - $url/$hostname/$ip/user/pass") subj="valexeev DynDNS" isDebug=$isDeb
      }
      #:return (false)
      :return $ddnsInterfacesParams;
    }
    :if ($isDeb) do={
      :log info "Change APIDNS record A for $hostname ip $ip on valexeev DynDNS - $url/$hostname/$ip/$user/$pass"
    }
    ### Send mail about successful host change in DNS ###
    :if ( $sm ) do={
      $sendEmail body=("Change APIDNS record A for $hostname ip $ip on valexeev DynDNS - $url/$hostname/$ip/user/pass") subj="valexeev DynDNS" isDebug=$isDeb
    }
  } else={
    :if ($isDeb) do={
      :log info "NOT change APIDNS record A for $hostname ip $ip:"
    }
  }
  :set ($ddnsInterfacesParams->$iface->"oldIP") $ip
  #:set $ddnsInterfacesParamsDef $ddnsInterfacesParams
  #:set $interfacesData $ddnsInterfacesParams
  #:log info ($ddnsInterfacesParams->"lte1");
  :if ($isDeb) do={
    :log info "END function $0 ===============================================";
  }
  :set ($ddnsInterfacesParams->"results"->"r_oneInterface2DDNS") [:tobool true]
  #:return (true);
  :return $ddnsInterfacesParams;
}

:global putItem2localDNS do={
##################################
#   Working with DNS in the local network. DNS must be Bind.
#   Called from the DHCP server when leasing address
#   DNS server settings in an array input parameter paramsDNS.
#   If the parameters is not passed, then the global array $homeDNS is used.
#   Change host ip in DNS. Used by RFC 2136
#    Input:
#      hostname: - hostname
#      ip:-------------- ip host
#      par_ttl: ------ ttl
#      isDebug: --- enable log or not
#   Output: none
##################################
  :global my2bool;
  :global islogFunc;
  :global homeDNS;

  :local ttl [:tonum ($homeDNS->"ttl")]
  :if ( [:typeof $pttl]!="nothing" && [:len $pttl]!=0) do={ :set ttl [:tonum $pttl]; }
  :local isDeb [$my2bool value=$isDebug];
  :set $isDeb ([:tobool $isDeb] || [:tobool $islogFunc])

  :if ($hostname!="" && $ip!="") do={
    :if ($isDeb) do={
      :log info "Input parameters:"
      :log info "  - hostname: $hostname"
      :log info "  - ip: $(ip)"
      :log info "  - isDebug: $isDebug"
      #:log info ($homeDNS)
      :log info ($homeDNS->"server")
      :log info ($homeDNS->"zone")
      :log info "ttl: $ttl"
    }
    /tool dns-update name=$hostname zone=[:tostr ($homeDNS->"zone")] key-name=($homeDNS->"keyName") key=($homeDNS->"tsig") address=$ip dns-server=($homeDNS->"server") ttl=$ttl
  }
}

:global reconnectIF do={
###############################
#   Rreconnect the interface if the ip is gray and it is active
#   Input:
#      ifaces: - a list of interfaces to check that the address is not grayed out and enabled
#      isDebug: ---- enable logging or disabled
###############################
  :global my2bool;
  :global islogFunc;

  :global alwaysEnableInterfaces;
  :global statusIF;
  :global ipIsGray;

  :local ifs;

  :local isDeb [$my2bool value=$isDebug];
  :set $isDeb ([:tobool $islogFunc] || [:tobool $isDeb]);

  :if ($isDeb) do={
    :log info "function: $0 BEGIN ==========================================================="
    :log info "ifaces=$ifaces"
    :log info "isDeb=$isDeb"
  }
  ### prepare a list of interfaces that check for enabled and gray address ###
  ### If the iface parameter is passed and it is an array or a string,
  ### then this is the list or interface name to check.
  ### For now, the string type is not considered. ###
  ### Very bad work of a microtic with types of variables. News ###
  :set $ifs $alwaysEnableInterfaces;
  :if ( [:typeof $ifaces]="array") do={
    :set $ifs ($ifaces);
  }
  :if ([:typeof $ifaces] = "str") do={
    :set $ifs [:toarray "$ifaces"];
  }
  :if ($isDeb) do={
    :log info "ifs:"
    :log info $ifs
  }
  foreach iface in=$ifs do={
    :local stat [$statusIF ifname=$iface];
    :local isBogon [$ipIsGray ipfull=($stat->"ipm")]
    :local isEnb [:tobool ($stat->"running")]
    :local changeStatus false;
    :if ($isDeb) do={
      :log info [:typeof $iface]
      :log info "Interface: $iface"
      :log info "Is private address: $isBogon"
      :log info ($stat)
      :log info ($stat->"ipm")
      :log info "isEnb: $isEnb"
      :log info [:typeof $isEnb]
      :log info "isBogon: $isBogon"
      :log info [:typeof $isBogon]
    }
    :if ($isEnb) do={
      :if ($isBogon) do={
        :if ($isDeb=true) do={
          :log info "Active, but ip address is \"GRAY\" (not public). Reconnecting"
        }
        /interface disable $iface
        :set changeStatus true
        :delay 3000ms
        /interface enable $iface
      }
    } else={
      :if ($isDeb=true) do={
        :log info "Disbaled. Enabling"
      }
      :set changeStatus true
      /interface enable $iface
    }
    :if ($isDeb) do={
      :if (!$changeStatus) do={
        :log info ("interface $iface NOT change status")
      } else={
        :log info ("interface $iface change status")
      }
    }
  }
  :if ($isDeb) do={
    :log info "function: $0 END ============================================================="
  }
#:log info "============================================================="
}

:global nameDomainFromFullname do={
###############################
#   Get domain name from full FQDN hostname
#   Input:
#      nameFQDN: - full FQDN hostname, example sstp.alt.av-kms.ru
#      isDebug: ---- enable or disable logging
#   Output:
#      name domain, example alt.av-kms.ru
###############################
  :global my2bool;
  :global islogFunc;

  #:global findPosix;
  :global findAndCount;

  :local isDeb [$my2bool value=$isDebug];
  :set $isDeb ([:tobool $islogFunc] || [:tobool $isDeb]);

  :if ($isDeb) do={
    :log info "function: $0 BEGIN ==========================================================="
    :log info "nameFQDN=$nameFQDN"
    :log info "ret=$ret"
  }
  :local ret ""
  :local searchArray [$findAndCount valueStr=$nameFQDN charSearch="." searchAll=true]
  :if ($isDeb) do={
    :log info "searchArray=$searchArray"
    :log info ("typeof searchArray=".[:typeof $searchArray])
    :log info ($searchArray->0)
    :log info ($searchArray->1)
  }
  :local sCount ($searchArray->0)
  :if ($isDeb) do={
    :log info "sCount=$sCount"
  }
  :if  ($sCount>1) do={
    ### Is there a domain in the hostname, i.e. above the level of the 2nd domain (3rd, 4th, etc.) ###
    :set ret [:pick $nameFQDN (($searchArray->1)+1) [:len $nameFQDN]]
  } else={
    :set ret $nameFQDN
  }

  :if ($isDeb) do={
    :log info "ret=$ret"
    :log info "function: $0 END ============================================================="
  }
  :return [:tostr $ret]
}

global versionFirmware do={
###############################
#   Get version for upgrade firmware
#   Input:
#      isDebug: ---- enable or disable logging
#   Output:
#      name domain, example alt.av-kms.ru
###############################
  :global my2bool;
  :global islogFunc;
  :global findAndCount;

  :local isDeb [$my2bool value=$isDebug];
  :set $isDeb ([:tobool $islogFunc] || [:tobool $isDeb]);

  :if ($isDeb) do={
    :log info "function: $0 BEGIN ==========================================================="
    :log info "isDebug=$isDebug"
    :log info "isDeb=$isDeb"
  }

  :local ret [:toarray ""]
  :local strVer [/system routerboard print as-value]
  :set ($ret->"ver") ($strVer->"upgrade-firmware")
#  :set ($ret->"ver") "78.1"

  :local findMV [$findAndCount valueStr=($ret->"ver") charSearch="."]

  :if ($isDeb) do={
    :log info "strVer=$strVer"
    :log info "findMV:::"
    :log info $findMV
  }

  :if ( ($findMV->0)>0 ) do={
    :set ($ret->"strMajor") [:pick ($ret->"ver") begin=0 end=($findMV->1)]
    :set ($ret->"intMajor") [:tonum ($ret->"strMajor")]
  } else={
    :set ($ret->"strMajor") "6"
  }

  :if ($isDeb) do={
    :log info "ret:::"
    :log info $ret
    :log info "function: $0 END ============================================================="
  }
  :return $ret
}
######################################################################