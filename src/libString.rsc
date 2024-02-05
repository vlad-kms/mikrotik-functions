### libString

### List functions ###
#-- findAndCount
#-- findPosix
#################

:global findAndCount do={
##############################
#  Searching in the string "valueStr" of a substring "charSearch"
#  Input:
#        isDebug
#        valueStr - string to search
#        charSearch - char to match
#        searchAll - search for all matches or only first
#  Output:
#        array,
#           first element - count matches
#           the following elements contain char positions
#           examples: [3;3;8;9] - three matches in positions 3, 8, 9
#  Use:
#  $findAndCount valueStr="wqewq.1wewq.ewe.1" charSearch="." searchAll=true
#     [3;5;11;15]
##############################

  :global my2bool;
  :global islogFunc;

  :local str [:tostr $valueStr]
  :local charS [:tostr $charSearch]
  :local ret [:toarray "0"]
  :local sAll [:tobool 1]

  :local isDeb [$my2bool value=$isDebug];
  :set $isDeb ([:tobool $islogFunc] || [:tobool $isDeb]);
  :if ( [:typeof ($searchAll)]!="nothing") do={
    :set sAll [$my2bool value=$searchAll]
  }
  :if ($isDeb) do={
    :log info "function: $0 BEGIN ==========================================================="
    :log info "str=$str"
    :log info "charS=$charS"
    :log info "sAll=$sAll"
  }

  ### return array [0], if an empty string is passed ###
  :if ([:len $str]=0) do={ :return $ret; }
  ### return array [0], if no search character is passed ###
  :if ([:len $charS]=0) do={ :return $ret; }
  :local s;
  :do {
    :for y from=0 to=([:len $str]-1) step=1 do={
      :if ([:pick $str $y ($y+1)]=$charS) do={
        :set ($ret->0) (($ret->0)+1)
        :set ret [:put ($ret, y)]
        :if (!$sAll) do={ /break; }
      }
    }
  } on-error={
    :log info "Search first include"
  }

  :if ($isDeb) do={
    :log info "ret=$ret"
    :log info "function: $0 END ============================================================="
  }
  :return $ret
}

:global findPosix do={
#use:  [$findPosix  String Regex startPosition]
#return array:  {FoundSubString ; FoundPositionStart; FoundPositionEnd}
  :local string [:tostr $1];
  :local posix $2;
  :local posix0 $posix;
  :local fstart [:tonum $3];
  :local fend 0;
  :if ($fstart < 0) do={ :set fstart 0 };
  :local  substr [:pick $string $fstart [:len $string]];
  :if ([:len $string] > 0 && [:len $posix] > 0 && $fstart <[:len $string] && ($substr ~ $posix)) do={
    :while ($fstart < [:len $string]) do={
      :set posix $posix0;
      :if ([:pick $posix 0] != "^") do={
        :set posix ("^".$posix);
        :local continue true;
        :while ($continue && $fstart < [:len $string]) do={
          :if ([:pick $string $fstart [:len $string]] ~ $posix) do={
            :set continue false;
          } else={:set fstart ($fstart + 1);};
        }
      }
      :if ($fstart < [:len $string]) do={
        :if ([:pick $posix ([:len $posix] -1)] != "\$") do={
          :set posix ($posix."\$");
          :local continue true;
          :set fend [:len $string];
          :while ($fend > $fstart && $continue) do={
            :if ([:pick $string $fstart $fend] ~ $posix) do={:set continue false} else={:set fend ($fend - 1)};
          }
        } else={:set fend [:len $string];}
      }
      :if ($fend > $fstart) do={:return {[:pick $string $fstart $fend] ; $fstart ;$fend};};
      :set fstart ($fstart +1);
      :set fend 0;
      :put "Unidentified error";
    }
  }
  :return {[]; []; []};
};

##########################
### IPv4 to arpa
### use: [$ipv42arpa ip=192.168.1.1]
### return: "1.1.168.192.in-addr.arpa."
##########################
:global ipv42arpa do={

:global islogFunc

  :local res "in-addr.arpa."
  :local ar [:toarray ""]
  :set ($ar->0) "."
  :set ($ar->1) 0
  :set ($ar->2) 0
  :local o1 0

  :set ar [$findPosix $ip [:tostr "\\."] ($ar->2)];
  :if ([:typeof ($ar->2)]="nil") do={
    :set ($ar->2) 0
  }

  while (($ar->2)!=0) do={
    :set res ([:pick $ip $o1 ($ar->1)].".".$res)
    :set o1 [:tonum ($ar->2)]
    :set ar [$findPosix $ip [:tostr "\\."] ($ar->2)];
    :if ([:typeof ($ar->2)]="nil") do={
      :set res ([:pick $ip $o1 [:len $ip]].".".$res)
      :set ($ar->2) 0
    }
  }
}