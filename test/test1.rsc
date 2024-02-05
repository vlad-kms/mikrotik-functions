:global ddnsInterfacesParamsTwo


:global testFunc1 do={
  #p1: array
:log warning "start ========================="
:log warning [:typeof $p1]
:log warning [:len $p1]

  if (  ([:typeof $p1]!="array") || ( ([:typeof $p1]="array") && ([:len $p1]=0) ) ) do={
    :set $p1 $ddnsInterfacesParamsTwo
    :log warning $p1
  }
  :log warning $p1
  :set ($p1->"el3") "v3"
  :log warning $p1
:log warning "end ========================="
 :return (true)
}

:local ar1 [:toarray ""]
:set ($ar1->"e1"->"e1_1") "v1_1"
:set ($ar1->"e2") "v2"
:log warning "rrrrr"
:log warning [:typeof $ar1]
:log warning $ar1


#$testFunc1
:log warning $ar1
:log warning $ddnsInterfacesParamsTwo

#:local ar2 [:toarray ""]
:log warning [:len $ar2]
$testFunc1 p1=$ar2
:log warning $ar1
:log warning $ar2
:log warning $ddnsInterfacesParamsTwo


$testFunc1 p1=$ar1
:log warning $ar1
:log warning $ddnsInterfacesParamsTwo
