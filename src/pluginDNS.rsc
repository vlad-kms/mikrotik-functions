### pluginDNS

### List functions ##################
#-- updateRecordSelectel
################################

:global pluginsDNS {
  "selectel"="updateRecordSelectel";
  "onecloud"="updateRecordOneCloud"
}

:global dispatch do={

  :global pluginsDNS;

  :local arrPlug [:toarray $pluginsDNS]
#:log info ("type pluginsDNS: ".[:typeof $pluginsDNS])
#:log info "pluginsDNS:"
#:log info $pluginsDNS
#:log info "typeDNS: $typeDNS"
#:log info ($pluginsDNS->"$typeDNS")
  :local funcUpd ($pluginsDNS->"$typeDNS")
#:log info "funcUpd: $funcUpd"
#:log info "arguments: $arguments"
#:log info "args: $args"
#:log info "args: $@"
  :return $funcUpd
}

:global updateRecordSelectel do={

####################################
###  Update (add) record into DNS hostinger SELECTEL
###  Input:
###     url - url api
###     hostname - name host for record DNS
###     ip - ip address for record DNS
###     pass - pass( api key) for access to API SELECTEL
###     domain - domain for record DNS
###     maxReadRecords - number of records to read at one time
###     isDebug - log or no
###     plugin - name DNS hostingera (SELECTEL)
###     iface - interface for which we execute
###     data - array with additional data for interface
###  Output: [int]
###     >=0 - no error
###     -1    - error read information of domain
###     -2    - error read records of domain
###     -3    - error update record for hostname of domain
###     -4    - error add record for hostname of domain
###  Using:
###         $UpdateRecord url=$url hostname=$hostname ip=$ip pass=$pass domain=$domain maxReadRecords=$maxRR isDebug=$isDeb plugin=$typeDNS iface=$iface data=$ddnsInterfacesParams
####################################

  :global my2bool;
  :global JSONLoads;

  :local idError [:tonum 0]
  
  :local isDeb [$my2bool value=$isDebug];
  :set $isDeb ([:tobool $islogFunc] || [:tobool $isDeb]);
  
  :if ($isDeb) do={
    :log info "url: $url"
    :log info "hostname: $hostname"
    :log info "ip: $ip"
    :log info "pass: $pass"
    :log info "domain: $domain"
    :log info "maxReadRecords: $maxReadRecords"
    :log info "plugin: $plugin"
    :log info "iface: $iface"
    :log info "data: "
    :log info $data
  }
  
  :local urlDomainInfo "$url/$domain/"
  :local urlListRecords "$url/$domain/records?limit=$maxReadRecords"
  :local headers "Content-Type:application/json, X-Token: $pass"
  :if ($isDeb) do={
    :log info "urlDomainInfo: $urlDomainInfo"
    :log info "urlListRecords: $urlListRecords"
    :log info "headers: $headers"
  }
  ### get id domain ###
  :local idDomain [:tonum 0]
  :do {
    :local infoDomain [/tool fetch url="$urlDomainInfo" as-value output=user http-method=get mode=https http-header-field="$headers"];
    :local infoDomainData [$JSONLoads ($infoDomain->"data")]
    :set idDomain [:tonum ($infoDomainData->"id")]
    :if ($isDeb) do={
      :log info "infoDomain:"
      :log info $infoDomain
      #:log info ("typeof infoDomain: ".[:typeof $infoDomain])
      :log info ("typeof infoDomain.data: ".[:typeof ($infoDomain->"data")])
      :log info ("typeof infoDomainData: ".[:typeof $infoDomainData])
      :log info "idDomain: $idDomain"
    }
  } on-error={
    :set idDomain [:tonum 0]
    :log info "Error read info of domain $domain in function $0"
  }
  :if ($idDomain=0) do={
    :return -1; ### no domain, error read info of domain
  }
  ### read DNS records, find required record id ###
  :local records;
  :do {
    :set records [/tool fetch url="$urlListRecords" as-value output=user http-method=get mode=https http-header-field="$headers"];
  } on-error={
    :set idError [:tonum -2]
    :log info "Error read records DNS of domain $domain ($idDomain) in function $0"
  }
  :if ($idError<0) do { :return $idError; }
  
  ### find the id of the required entry ###
  :local recData [$JSONLoads ($records->"data")]
  :if ($isDeb) do={
    #:log info ("typeof recData: ".[:typeof $recData])
    :log info "recData:"
    :log info $recData
  }
  :local idRec [:tonum 0]
  :do {
    :foreach el in=$recData do={
      :if ( ($el->"name")=$hostname ) do={
        :set idRec [:tonum ($el->"id")]
        /break;
      }
    }
  } on-error={
    #:log info "ERROR DNS: break"
    :if ($isDeb) do={
      :log info "Found id record $idRec for $hostname"
    }
  }
  :local body "{ \"content\": \"$ip\", \"name\": \"$hostname\", \"ttl\": 600, \"type\": \"A\" }"
    :if ($isDeb) do={
      :log info "body: $body"
    }
  :local urlNewRecord "$url/$idDomain/records"
  :local urlEditRecord "$url/$idDomain/records/$idRec"
  :if ($isDeb) do={
    :log info "urlNewRecord: $urlNewRecord"
    :log info "urlEditRecord: $urlEditRecord"
  }
  :if ($idRec=0) do={
    ### add new record for hostname ###
    :if ($isDeb) do={
      :log info "New record: $hostname ::: $ip"
    }
    :do {
      :local res [/tool fetch url="$urlNewRecord" as-value output=user http-method=post mode=https http-header-field=$headers http-data=$body];
    } on-error={
      :set idError [:tonum -4]
      :log info "Error update record DNS ($idRec) of domain $domain ($idDomain) in function $0"
    }
  } else={
    ### update record for hostname ###
    :if ($isDeb) do={
      #:log info "Edit record: $hostname ::: $ip"
    }
    :do {
      :local res [/tool fetch url="$urlEditRecord" as-value output=user http-method=put mode=https http-header-field=$headers http-data=$body];
    } on-error={
      :set idError [:tonum -3]
      :log info "Error update record DNS ($idRec) of domain $domain ($idDomain) in function $0"
    }
  }
  :if ($isDeb) do={
    :if ($idError=>0) do={
       ### no error ###
       :log info "DNS record added (updated) without errors"
    } else={
       ### errors ###
       :log info "DNS record not added (updated). Erros."
    }
  }
  :return $idError
}
