###################################################################################
# "Compliant" IPv4 & IPv6 Dynamic DNS Update Script for Mikrotik with Nsupdate.info Services
# In theory, fully compliant based on Nsupdate rules, but hey, its free, YMMV!
# Things to note: 
# Problem: If your domain has no IP set or is set "Abuse" status, this script will likely fail / not work.
# Solution: Fix your "Abuse status" in the web control panel, and/or set an initial IP.
# Problem: You only have IPv4 or IPv6, not both.
# Solution: The script will probably fail, Mikrotik likes to stop running scripts if ANYTHING goes wrong. Goodluck!
# Please enter only your full Dynamic DNS Hostname & Secret
:local DDNSHostname 
:local DDNSSecret 
:put "-----------------------------------------"
## IPv4 Update code begin.
:local DDNSHostnameIPv4 [:resolve $DDNSHostname];
{
:local IPV4CURRENT [/tool fetch url="https://ipv4.nsupdate.info/myip" as-value output=user];
 :delay 2s; 
 
 :put "IPv4 Hostname: $DDNSHostname " ;
 :put "DNS-IPv4: $DDNSHostnameIPv4 " ;
 :put "Current IPv4 address:" ;
 :put ($IPV4CURRENT->"data") ;
 # Compare DNS IPv4 to current IPv4
 :if ($IPV4CURRENT->"data" = $DDNSHostnameIPv4 ) do={
               :log info "IPv4 address matches for $DDNSHostname no update needed." ;
               :put "IPv4 address matches for $DDNSHostname no update needed." ;
        } else={
            :log info "IPv4 address doesn't match for $DDNSHostname , updating..." ;
            :put "IPv4 address doesn't match for $DDNSHostname , updating..." ;
            
            /tool fetch url="https://$DDNSHostname:$DDNSSecret@ipv4.nsupdate.info/nic/update" keep-result=no ;
        }
}
## IPv4 Update code end
:put "-----------------------------------------"
# IPv6 Update code start, IPv6 code is much more complicated vs IPv4 code.
# This is due to the around Mikrotik not implementing ping6 or resolve6 functionality

# Setup some variables to generate a unique-ish address-list name
:local AddressListName
:local date [/system clock get date]
:local newdate "";
  :for i from=0 to=([:len $date]-1) do={ :local tmp [:pick $date $i];
  :if ($tmp !="/") do={ :set newdate "$newdate$tmp" }
  :if ($tmp ="/") do={}
}

:set AddressListName ($"DDNSHostname" . "-" . $"newdate" )

# Create temporary address list to resolve IPv6 ip since Mikrotik resolve function sucks
# Use uniqueish name for address list to prevent clobbering.
/ipv6 firewall address-list add list=$AddressListName address=$DDNSHostname timeout=15s comment="Temp list for DDNS"
:delay 2s;

{
# Get IPV6 string from address list.
local DDNSHostnameIPv6 [/ipv6 firewall address-list get value-name=address [find comment=$DDNSHostname]] 
# Split IPv6 (address) string away from its subnet/cidr mask. 
local DDNSHostnameIPv6 [:pick $DDNSHostnameIPv6 0 [:find $DDNSHostnameIPv6 "/"]]
# Get local IPv6 address from nsupdate.info server.
:local IPV6CURRENT [/tool fetch url="https://ipv6.nsupdate.info/myip" as-value output=user];
 :delay 2s;
 :put "IPv6 Hostname: $DDNSHostname " ;
 :put "DNS-IPv6: $DDNSHostnameIPv6 " ;
 :put "Current IPv6 address:"
 :put ($IPV6CURRENT->"data");
# Compare DNS IPv6 to current IPv6
:if ( $IPV6CURRENT->"data" = $DDNSHostnameIPv6 ) do={
            :log info "IPv6 address matches for $DDNSHostname , no update needed." ;
            :put "IPv6 address matches for $DDNSHostname, no update needed." ;
        } else={
            :log info "IPv6 address doesn't match for $DDNSHostname , updating..." ;
            :put "IPv6 address doesn't match for $DDNSHostname, updating..." ;
            /tool fetch url="https://$DDNSHostname:$DDNSSecret@ipv6.nsupdate.info/nic/update" keep-result=no ;
        }

}
:put "-----------------------------------------"
########################################################################
