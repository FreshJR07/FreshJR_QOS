#!/bin/sh
##FreshJR_QOS  
version=8.8
release=03/07/2019
#Copyright (C) 2017-2019 FreshJR - All Rights Reserved 
#Tested with ASUS AC-68U, FW384.9, using Adaptive QOS with Manual Bandwidth Settings
# Script Changes Unidentified traffic destination away from "Defaults" into "Others"
# Script Changes HTTPS traffic destination away from "Net Control" into "Web Surfing" 
# Script Changes Guaranteed Bandwidth per QOS category into logical percentages of upload and download.
# Script Repurposes "Defaults" to contain "Game Downloads" 
#  "Game Downloads" moved into 6th position
#  "Lowest Defined" moved into 7th position
#Script includes misc hardcoded rules 
#   (Wifi Calling)  -  UDP traffic on remote ports 500 & 4500 moved into VOIP
#   (Facetime)      -  UDP traffic on local  ports 16384 - 16415 moved into VOIP 
#   (Usenet)        -  TCP traffic on remote ports 119 & 563 moved into Downloads 
#   (Gaming)        -  Gaming TCP traffic from remote ports 80 & 443 moved into Game Downloads.
#   (Snapchat)      -  Moved into Others
#   (Speedtest.net) -  Moved into Downloads
#   (Google Play)   -  Moved into Downloads
#   (Apple AppStore)-  Moved into Downloads
#   (Advertisement) -  Moved into Downloads
#   (VPN Fix)       -  Router VPN Client upload traffic moved into Downloads instead of whitelisted
#   (VPN Fix)       -  Router VPN Client download traffic moved into Downloads instead of showing up in Uploads
#   (Gaming Manual) -  Unidentified traffic for specified devices, not originating from ports 80/443, moved into "Gaming"
# 
#  Gaming traffic originating from ports 80 & 443 is primarily downloads & patches (some lobby/login protocols mixed within)
#  Manually configurable rule will take untracked traffic, not originating from 80/443, for specified devices and place it into Gaming
#  Use of this gaming rule REQUIRES devices to have a continuous static ip assignment && this range needs to be defined in the script
#
#  Custom rules can be created within the WebUI OR by running the -rules command:
#      (custom rules):  /jffs/scripts/FreshJR_QOS -rules
#
#  Default bandwidth allocation per category can be adjusted via WebUI OR -rates command:
#      (custom rates):  /jffs/scripts/FreshJR_QOS -rates
#
##For discussion visit this thread:
##  https://www.snbforums.com/threads/release-freshjr-adaptive-qos-improvements-custom-rules-and-inner-workings.36836/
##  https://github.com/FreshJR07/FreshJR_QOS (Source Code + Backup Link)
#
##License
##  FreshJR_QOS is free to use under the GNU General Public License, version 3 (GPL-3.0).
##  https://opensource.org/licenses/GPL-3.0

####################  MODIFY BELOW WITH CAUTION   #####################
####################  MODIFY BELOW WITH CAUTION   #####################
#
### IF YOU MANUALLY ADD RULES TO AREA BELOW THEN KEEP IN MIND THAT YOUR CHANGES WILL TAKE EFFECT BUT WILL NOT BE REFLECTED UNDER THE TRACKED CONNECTIONS SECTION OF THE WEBUI. 
### FOR HARDCODED CHANGES TO BE REFLECTED IN TRACKED CONNECTIONS SECTION OF THE WEBUI THEN YOU ALSO HAVE TO MODIFY THE CORRESPONDING JAVASCRIPT CODE IN /jffs/scripts/FreshJR_QoS_Stats.asp
### INSTEAD OF HARDCODED CHANGES (legacy method) YOU CAN USE THE SCRIPTS -RULES COMMAND OR ENTER THE WEBUI PAGE FOR CREATING RULES AND THOSE CHANGES WILL BE REFLECTED IN THE TRACKED CONNECTIONS TABLE.
#
####################  MODIFY BELOW WITH CAUTION   #####################
####################  MODIFY BELOW WITH CAUTION   #####################

	iptable_down_rules() {
		echo "Applying - Iptable Down Rules"
		##DOWNLOAD (INCOMMING TRAFFIC) CUSTOM RULES START HERE  -- legacy method
			
			iptables -D POSTROUTING -t mangle -o br0 -p udp -m multiport --sports 500,4500 -j MARK --set-mark ${VOIP_mark_down} &> /dev/null				#Wifi Calling - (All incoming traffic from WAN source ports 500 & 4500 --> VOIP ) 								
			iptables -A POSTROUTING -t mangle -o br0 -p udp -m multiport --sports 500,4500 -j MARK --set-mark ${VOIP_mark_down}
			
			iptables -D POSTROUTING -t mangle -o br0 -p udp --dport 16384:16415 -j MARK --set-mark ${VOIP_mark_down} &> /dev/null							#Facetime - 	(All incoming traffic to LAN destination ports 16384-16415 --> VOIP )
			iptables -A POSTROUTING -t mangle -o br0 -p udp --dport 16384:16415 -j MARK --set-mark ${VOIP_mark_down} 

			iptables -D POSTROUTING -t mangle -o br0 -p tcp -m multiport --sports 119,563 -j MARK --set-mark ${Downloads_mark_down} &> /dev/null			#Usenet - 		(All incoming traffic from WAN source ports 119 & 563 --> Downloads ) 								
			iptables -A POSTROUTING -t mangle -o br0 -p tcp -m multiport --sports 119,563 -j MARK --set-mark ${Downloads_mark_down}
			
			iptables -D POSTROUTING -t mangle -o br0 -m mark --mark 0x40000000/0xc0000000 -j MARK --set-xmark 0x80000000/0xC0000000 &> /dev/null			#VPN Fix -		(Fixes download traffic showing up in upload section when router is acting as a VPN Client)
			iptables -A POSTROUTING -t mangle -o br0 -m mark --mark 0x40000000/0xc0000000 -j MARK --set-xmark 0x80000000/0xC0000000
			
			iptables -D POSTROUTING -t mangle -o br0 -m mark --mark 0x80080000/0xc03f0000 -p tcp -m multiport --sports 80,443 -j MARK --set-mark ${Default_mark_down} &> /dev/null		#Gaming - (Incoming "Gaming" traffic from WAN source ports 80 & 443 -->  Defaults//GameDownloads)
			iptables -A POSTROUTING -t mangle -o br0 -m mark --mark 0x80080000/0xc03f0000 -p tcp -m multiport --sports 80,443 -j MARK --set-mark ${Default_mark_down}
			
		##DOWNLOAD (INCOMMING TRAFFIC) CUSTOM RULES END HERE  -- legacy method
		
		if [ "$( echo $gameCIDR | tr -cd '.' | wc -c )" -eq "3" ] ; then
			iptables -D POSTROUTING -t mangle -o br0 -d $gameCIDR -m mark --mark 0x80000000/0x8000ffff -p tcp -m multiport ! --sports 80,443  -j MARK --set-mark ${Gaming_mark_down} &> /dev/null    	#Gaming - (Incoming "Unidentified" TCP traffic, for devices specified, not from WAN source ports 80 & 443 -->  Gaming)
			iptables -A POSTROUTING -t mangle -o br0 -d $gameCIDR -m mark --mark 0x80000000/0x8000ffff -p tcp -m multiport ! --sports 80,433  -j MARK --set-mark ${Gaming_mark_down}

			iptables -D POSTROUTING -t mangle -o br0 -d $gameCIDR -m mark --mark 0x80000000/0x8000ffff -p udp -m multiport ! --sports 80,443  -j MARK --set-mark ${Gaming_mark_down} &> /dev/null    	#Gaming - (Incoming "Unidentified" UDP traffic, for devices specified, not from WAN source ports 80 & 443 -->  Gaming)
			iptables -A POSTROUTING -t mangle -o br0 -d $gameCIDR -m mark --mark 0x80000000/0x8000ffff -p udp -m multiport ! --sports 80,443  -j MARK --set-mark ${Gaming_mark_down}
		fi
		
		if ! [ -z "$ip1_down" ] ; then													#Script Interactively Defined Rule 1
			if [ "$(echo ${ip1_down} | grep -c "both")" -ge "1" ] ; then
				iptables -D POSTROUTING -t mangle -o br0 ${ip1_down//both/tcp} &> /dev/null    																				
				iptables -A POSTROUTING -t mangle -o br0 ${ip1_down//both/tcp}
				iptables -D POSTROUTING -t mangle -o br0 ${ip1_down//both/udp} &> /dev/null    																				
				iptables -A POSTROUTING -t mangle -o br0 ${ip1_down//both/udp}
			else
				iptables -D POSTROUTING -t mangle -o br0 ${ip1_down} &> /dev/null    																				
				iptables -A POSTROUTING -t mangle -o br0 ${ip1_down}
			fi
		fi

		if ! [ -z "$ip2_down" ] ; then													#Script Interactively Defined Rule 2
			if [ "$(echo ${ip2_down} | grep -c "both")" -ge "1" ] ; then
				iptables -D POSTROUTING -t mangle -o br0 ${ip2_down//both/tcp} &> /dev/null    																				
				iptables -A POSTROUTING -t mangle -o br0 ${ip2_down//both/tcp}
				iptables -D POSTROUTING -t mangle -o br0 ${ip2_down//both/udp} &> /dev/null    																				
				iptables -A POSTROUTING -t mangle -o br0 ${ip2_down//both/udp}
			else
				iptables -D POSTROUTING -t mangle -o br0 ${ip2_down} &> /dev/null    																				
				iptables -A POSTROUTING -t mangle -o br0 ${ip2_down}
			fi
		fi

		if ! [ -z "$ip3_down" ] ; then													#Script Interactively Defined Rule 3
			if [ "$(echo ${ip3_down} | grep -c "both")" -ge "1" ] ; then
				iptables -D POSTROUTING -t mangle -o br0 ${ip3_down//both/tcp} &> /dev/null    																				
				iptables -A POSTROUTING -t mangle -o br0 ${ip3_down//both/tcp}
				iptables -D POSTROUTING -t mangle -o br0 ${ip3_down//both/udp} &> /dev/null    																				
				iptables -A POSTROUTING -t mangle -o br0 ${ip3_down//both/udp}
			else
				iptables -D POSTROUTING -t mangle -o br0 ${ip3_down} &> /dev/null    																				
				iptables -A POSTROUTING -t mangle -o br0 ${ip3_down}
			fi
		fi

		if ! [ -z "$ip4_down" ] ; then													#Script Interactively Defined Rule 4
			if [ "$(echo ${ip4_down} | grep -c "both")" -ge "1" ] ; then
				iptables -D POSTROUTING -t mangle -o br0 ${ip4_down//both/tcp} &> /dev/null    																				
				iptables -A POSTROUTING -t mangle -o br0 ${ip4_down//both/tcp}
				iptables -D POSTROUTING -t mangle -o br0 ${ip4_down//both/udp} &> /dev/null    																				
				iptables -A POSTROUTING -t mangle -o br0 ${ip4_down//both/udp}
			else
				iptables -D POSTROUTING -t mangle -o br0 ${ip4_down} &> /dev/null    																				
				iptables -A POSTROUTING -t mangle -o br0 ${ip4_down}
			fi
		fi		
	}

	iptable_up_rules(){
		
		#wan="ppp0"				## WAN interface over-ride for upload traffic if automatic detection is not working properly
								
		echo "Applying - Iptable Up   Rules ($wan)"

		##UPLOAD (OUTGOING TRAFFIC) CUSTOM RULES START HERE  -- legacy method
		
			iptables -D POSTROUTING -t mangle -o $wan -p udp -m multiport --dports 500,4500 -j MARK --set-mark ${VOIP_mark_up} &> /dev/null					#Wifi Calling - (All outgoing  traffic to WAN destination ports 500 & 4500 --> VOIP ) 	  										
			iptables -A POSTROUTING -t mangle -o $wan -p udp -m multiport --dports 500,4500 -j MARK --set-mark ${VOIP_mark_up}
			
			iptables -D POSTROUTING -t mangle -o $wan -p udp --sport 16384:16415 -j MARK --set-mark ${VOIP_mark_up} &> /dev/null							#Facetime - 	(All outgoing traffic from LAN source ports 16384-16415 --> VOIP )
			iptables -A POSTROUTING -t mangle -o $wan -p udp --sport 16384:16415 -j MARK --set-mark ${VOIP_mark_up} 

			iptables -D POSTROUTING -t mangle -o $wan -p tcp -m multiport --dports 119,563 -j MARK --set-mark ${Downloads_mark_up} &> /dev/null				#Usenet - 		(All outgoing traffic to WAN destination ports 119 & 563 --> Downloads ) 										
			iptables -A POSTROUTING -t mangle -o $wan -p tcp -m multiport --dports 119,563 -j MARK --set-mark ${Downloads_mark_up}
			
			iptables -D OUTPUT -t mangle -o $wan -p udp -m multiport ! --dports 53,123 -j MARK --set-mark ${Downloads_mark_up} &> /dev/null					#VPN Fix -		(Fixes upload traffic not detected when the router is acting as a VPN Client)
			iptables -A OUTPUT -t mangle -o $wan -p udp -m multiport ! --dports 53,123 -j MARK --set-mark ${Downloads_mark_up}

			iptables -D OUTPUT -t mangle -o $wan -p tcp -m multiport ! --dports 53,123 -j MARK --set-mark ${Downloads_mark_up} &> /dev/null					#VPN Fix -		(Fixes upload traffic not detected when the router is acting as a VPN Client)
			iptables -A OUTPUT -t mangle -o $wan -p tcp -m multiport ! --dports 53,123 -j MARK --set-mark ${Downloads_mark_up}
			
			iptables -D POSTROUTING -t mangle -o $wan -m mark --mark 0x40080000/0xc03f0000 -p tcp -m multiport --sports 80,443 -j MARK --set-mark ${Default_mark_up} &> /dev/null   #Gaming - (Outgoing "Gaming" traffic to WAN destinations ports 80 & 443 -->  Defaults//GameDownloads)
			iptables -A POSTROUTING -t mangle -o $wan -m mark --mark 0x40080000/0xc03f0000 -p tcp -m multiport --sports 80,443 -j MARK --set-mark ${Default_mark_up}
	
		##UPLOAD (OUTGOING TRAFFIC) CUSTOM RULES END HERE  -- legacy method
		
		if [ "$( echo $gameCIDR | tr -cd '.' | wc -c )" -eq "3" ] ; then
			iptables -D POSTROUTING -t mangle -o $wan -s $gameCIDR -m mark --mark 0x40000000/0x4000ffff -p tcp -m multiport ! --dports 80,443 -j MARK --set-mark ${Gaming_mark_up} &> /dev/null 	#Gaming - (Outgoing "Unidentified" TCP traffic, for devices specified, not to WAN destination ports 80 & 443 -->  Gaming)
			iptables -A POSTROUTING -t mangle -o $wan -s $gameCIDR -m mark --mark 0x40000000/0x4000ffff -p tcp -m multiport ! --dports 80,443 -j MARK --set-mark ${Gaming_mark_up}
			
			iptables -D POSTROUTING -t mangle -o $wan -s $gameCIDR -m mark --mark 0x40000000/0x4000ffff -p udp -m multiport ! --dports 80,443 -j MARK --set-mark ${Gaming_mark_up} &> /dev/null 	#Gaming - (Outgoing "Unidentified" UDP traffic, for devices specified, not to WAN destination ports 80 & 443 -->  Gaming)
			iptables -A POSTROUTING -t mangle -o $wan -s $gameCIDR -m mark --mark 0x40000000/0x4000ffff -p udp -m multiport ! --dports 80,443 -j MARK --set-mark ${Gaming_mark_up}
		fi

		if ! [ -z "$ip1_up" ] ; then													#Script Interactively Defined Rule 1
			if [ "$(echo ${ip1_up} | grep -c "both")" -ge "1" ] ; then
				iptables -D POSTROUTING -t mangle -o $wan ${ip1_up//both/tcp} &> /dev/null    																				
				iptables -A POSTROUTING -t mangle -o $wan ${ip1_up//both/tcp}
				iptables -D POSTROUTING -t mangle -o $wan ${ip1_up//both/udp} &> /dev/null    																				
				iptables -A POSTROUTING -t mangle -o $wan ${ip1_up//both/udp}
			else
				iptables -D POSTROUTING -t mangle -o $wan ${ip1_up} &> /dev/null    																				
				iptables -A POSTROUTING -t mangle -o $wan ${ip1_up}
			fi
		fi
		
		if ! [ -z "$ip2_up" ] ; then													#Script Interactively Defined Rule 2
			if [ "$(echo ${ip2_up} | grep -c "both")" -ge "1" ] ; then
				iptables -D POSTROUTING -t mangle -o $wan ${ip2_up//both/tcp} &> /dev/null    																				
				iptables -A POSTROUTING -t mangle -o $wan ${ip2_up//both/tcp}
				iptables -D POSTROUTING -t mangle -o $wan ${ip2_up//both/udp} &> /dev/null    																				
				iptables -A POSTROUTING -t mangle -o $wan ${ip2_up//both/udp}
			else
				iptables -D POSTROUTING -t mangle -o $wan ${ip2_up} &> /dev/null    																				
				iptables -A POSTROUTING -t mangle -o $wan ${ip2_up}
			fi
		fi
		
		if ! [ -z "$ip3_up" ] ; then													#Script Interactively Defined Rule 3
			if [ "$(echo ${ip3_up} | grep -c "both")" -ge "1" ] ; then
				iptables -D POSTROUTING -t mangle -o $wan ${ip3_up//both/tcp} &> /dev/null    																				
				iptables -A POSTROUTING -t mangle -o $wan ${ip3_up//both/tcp}
				iptables -D POSTROUTING -t mangle -o $wan ${ip3_up//both/udp} &> /dev/null    																				
				iptables -A POSTROUTING -t mangle -o $wan ${ip3_up//both/udp}
			else
				iptables -D POSTROUTING -t mangle -o $wan ${ip3_up} &> /dev/null    																				
				iptables -A POSTROUTING -t mangle -o $wan ${ip3_up}
			fi
		fi
		
		if ! [ -z "$ip4_up" ] ; then													#Script Interactively Defined Rule 4
			if [ "$(echo ${ip4_up} | grep -c "both")" -ge "1" ] ; then
				iptables -D POSTROUTING -t mangle -o $wan ${ip4_up//both/tcp} &> /dev/null    																				
				iptables -A POSTROUTING -t mangle -o $wan ${ip4_up//both/tcp}
				iptables -D POSTROUTING -t mangle -o $wan ${ip4_up//both/udp} &> /dev/null    																				
				iptables -A POSTROUTING -t mangle -o $wan ${ip4_up//both/udp}
			else
				iptables -D POSTROUTING -t mangle -o $wan ${ip4_up} &> /dev/null    																				
				iptables -A POSTROUTING -t mangle -o $wan ${ip4_up}
			fi
		fi
	}
	
	tc_redirection_down_rules() {
		echo "Applying  TC Down Rules"
		${tc} filter del dev br0 parent 1: prio $1																					#remove original unidentified traffic rule
		${tc} filter del dev br0 parent 1: prio 22 &> /dev/null																		#remove original HTTPS rule
		${tc} filter del dev br0 parent 1: prio 23 &> /dev/null																		#remove original HTTPS rule
		! [ -z "$tc4_down" ] && ${tc} filter add dev br0 protocol all ${tc4_down}													#Script Interactively Defined Rule 4
		! [ -z "$tc3_down" ] && ${tc} filter add dev br0 protocol all ${tc3_down}													#Script Interactively Defined Rule 3
		! [ -z "$tc2_down" ] && ${tc} filter add dev br0 protocol all ${tc2_down}													#Script Interactively Defined Rule 2
		! [ -z "$tc1_down" ] && ${tc} filter add dev br0 protocol all ${tc1_down}													#Script Interactively Defined Rule 1
		${tc} filter add dev br0 protocol all prio 20 u32 match mark 0x8012003F 0xc03fffff flowid ${Web}							#         HTTP  rule with different destination
		${tc} filter add dev br0 protocol all prio 22 u32 match mark 0x80130000 0xc03f0000 flowid ${Web}							#recreate HTTPS rule with different destination
		${tc} filter add dev br0 protocol all prio 23 u32 match mark 0x80140000 0xc03f0000 flowid ${Web}							#recreate HTTPS rule with different destination
		##DOWNLOAD APP_DB TRAFFIC REDIRECTION RULES START HERE  -- legacy method
			
			${tc} filter add dev br0 protocol all prio 2 u32 match mark 0x8000006B 0xc03fffff flowid ${Others}							#Snapchat
			${tc} filter add dev br0 protocol all prio 15 u32 match mark 0x800D0007 0xc03fffff flowid ${Downloads}						#Speedtest.net
			${tc} filter add dev br0 protocol all prio 15 u32 match mark 0x800D0086 0xc03fffff flowid ${Downloads}						#Google Play 
			${tc} filter add dev br0 protocol all prio 15 u32 match mark 0x800D00A0 0xc03fffff flowid ${Downloads}						#Apple AppStore
			${tc} filter add dev br0 protocol all prio 50 u32 match mark 0x801A0000 0xc03f0000 flowid ${Downloads}						#Advertisement			
	
		##DOWNLOAD APP_DB TRAFFIC REDIRECTION RULES END HERE  -- legacy method

		${tc} filter add dev br0 protocol all prio $1 u32 match mark 0x80000000 0x8000ffff flowid ${Others}							#recreate unidentified traffic rule with different destination - Routes Unidentified Traffic into webUI adjustable "Others" traffic container instead of "Defaults"
		${tc} filter add dev br0 protocol all prio 10 u32 match mark 0x803f0001 0xc03fffff flowid ${Defaults}						#Used for iptables Default_mark_down functionality
	}

	tc_redirection_up_rules() {
		echo "Applying  TC Up   Rules"
		${tc} filter del dev eth0 parent 1: prio $1																					#remove original unidentified traffic rule
		${tc} filter del dev eth0 parent 1: prio 22 &> /dev/null																	#remove original HTTPS rule
		${tc} filter del dev eth0 parent 1: prio 23 &> /dev/null																	#remove original HTTPS rule
		! [ -z "$tc4_up" ] && ${tc} filter add dev eth0 protocol all ${tc4_up}														#Script Interactively Defined Rule 4
		! [ -z "$tc3_up" ] && ${tc} filter add dev eth0 protocol all ${tc3_up}														#Script Interactively Defined Rule 3
		! [ -z "$tc2_up" ] && ${tc} filter add dev eth0 protocol all ${tc2_up}														#Script Interactively Defined Rule 2
		! [ -z "$tc1_up" ] && ${tc} filter add dev eth0 protocol all ${tc1_up}														#Script Interactively Defined Rule 1
		${tc} filter add dev eth0 protocol all prio 20 u32 match mark 0x4012003F 0xc03fffff flowid ${Web}							#         HTTP  rule with different destination
		${tc} filter add dev eth0 protocol all prio 22 u32 match mark 0x40130000 0xc03f0000 flowid ${Web}							#recreate HTTPS rule with different destination
		${tc} filter add dev eth0 protocol all prio 23 u32 match mark 0x40140000 0xc03f0000 flowid ${Web}							#recreate HTTPS rule with different destination
		##UPLOAD APP_DB TRAFFIC REDIRECTION RULES START HERE  -- legacy method
			
			${tc} filter add dev eth0 protocol all prio 2 u32 match mark 0x4000006B 0xc03fffff flowid ${Others}							#Snapchat
			${tc} filter add dev eth0 protocol all prio 15 u32 match mark 0x400D0007 0xc03fffff flowid ${Downloads}						#Speedtest.net
			${tc} filter add dev eth0 protocol all prio 15 u32 match mark 0x400D0086 0xc03fffff flowid ${Downloads}						#Google Play 
			${tc} filter add dev eth0 protocol all prio 15 u32 match mark 0x400D00A0 0xc03fffff flowid ${Downloads}						#Apple AppStore
			${tc} filter add dev eth0 protocol all prio 50 u32 match mark 0x401A0000 0xc03f0000 flowid ${Downloads}						#Advertisement
			
		##UPLOAD APP_DB TRAFFIC REDIRECTION RULES END HERE  -- legacy method
		${tc} filter add dev eth0 protocol all prio $1 u32 match mark 0x40000000 0x4000ffff flowid ${Others}						#recreate unidentified traffic rule with different destination - Routes Unidentified Traffic into webUI adjustable "Others" traffic container, instead of "Default" traffic container		
		${tc} filter add dev eth0 protocol all prio 10 u32 match mark 0x403f0001 0xc03fffff flowid ${Defaults}						#Used for iptables Default_mark_up functionality
	}

	custom_rates() {
		echo "Modifying TC Class Rates"
		${tc} class change dev br0 parent 1:1 classid 1:10 htb ${PARMS}prio 0 rate ${DownRate0}Kbit ceil ${DownCeil0}Kbit burst ${DownBurst0} cburst ${DownCburst0}
		${tc} class change dev br0 parent 1:1 classid 1:11 htb ${PARMS}prio 1 rate ${DownRate1}Kbit ceil ${DownCeil1}Kbit burst ${DownBurst1} cburst ${DownCburst1} 
		${tc} class change dev br0 parent 1:1 classid 1:12 htb ${PARMS}prio 2 rate ${DownRate2}Kbit ceil ${DownCeil2}Kbit burst ${DownBurst2} cburst ${DownCburst2} 
		${tc} class change dev br0 parent 1:1 classid 1:13 htb ${PARMS}prio 3 rate ${DownRate3}Kbit ceil ${DownCeil3}Kbit burst ${DownBurst3} cburst ${DownCburst3} 
		${tc} class change dev br0 parent 1:1 classid 1:14 htb ${PARMS}prio 4 rate ${DownRate4}Kbit ceil ${DownCeil4}Kbit burst ${DownBurst4} cburst ${DownCburst4} 
		${tc} class change dev br0 parent 1:1 classid 1:15 htb ${PARMS}prio 5 rate ${DownRate5}Kbit ceil ${DownCeil5}Kbit burst ${DownBurst5} cburst ${DownCburst5} 
		${tc} class change dev br0 parent 1:1 classid 1:16 htb ${PARMS}prio 7 rate ${DownRate6}Kbit ceil ${DownCeil6}Kbit burst ${DownBurst6} cburst ${DownCburst6} 
		${tc} class change dev br0 parent 1:1 classid 1:17 htb ${PARMS}prio 6 rate ${DownRate7}Kbit ceil ${DownCeil7}Kbit burst ${DownBurst7} cburst ${DownCburst7}
		
		${tc} class change dev eth0 parent 1:1 classid 1:10 htb ${PARMS}prio 0 rate ${UpRate0}Kbit ceil ${UpCeil0}Kbit burst ${UpBurst0} cburst ${UpCburst0}
		${tc} class change dev eth0 parent 1:1 classid 1:11 htb ${PARMS}prio 1 rate ${UpRate1}Kbit ceil ${UpCeil1}Kbit burst ${UpBurst1} cburst ${UpCburst1}
		${tc} class change dev eth0 parent 1:1 classid 1:12 htb ${PARMS}prio 2 rate ${UpRate2}Kbit ceil ${UpCeil2}Kbit burst ${UpBurst2} cburst ${UpCburst2}
		${tc} class change dev eth0 parent 1:1 classid 1:13 htb ${PARMS}prio 3 rate ${UpRate3}Kbit ceil ${UpCeil3}Kbit burst ${UpBurst3} cburst ${UpCburst3}
		${tc} class change dev eth0 parent 1:1 classid 1:14 htb ${PARMS}prio 4 rate ${UpRate4}Kbit ceil ${UpCeil4}Kbit burst ${UpBurst4} cburst ${UpCburst4}
		${tc} class change dev eth0 parent 1:1 classid 1:15 htb ${PARMS}prio 5 rate ${UpRate5}Kbit ceil ${UpCeil5}Kbit burst ${UpBurst5} cburst ${UpCburst5}
		${tc} class change dev eth0 parent 1:1 classid 1:16 htb ${PARMS}prio 7 rate ${UpRate6}Kbit ceil ${UpCeil6}Kbit burst ${UpBurst6} cburst ${UpCburst6}
		${tc} class change dev eth0 parent 1:1 classid 1:17 htb ${PARMS}prio 6 rate ${UpRate7}Kbit ceil ${UpCeil7}Kbit burst ${UpBurst7} cburst ${UpCburst7}
	}

####################  DO NOT MODIFY BELOW  #####################	
####################  DO NOT MODIFY BELOW  #####################	
####################  DO NOT MODIFY BELOW  #####################	
####################  DO NOT MODIFY BELOW  #####################	
####################  DO NOT MODIFY BELOW  #####################	
####################  DO NOT MODIFY BELOW  #####################	
####################  DO NOT MODIFY BELOW  #####################	
####################  DO NOT MODIFY BELOW  #####################	
####################  DO NOT MODIFY BELOW  #####################	
####################  DO NOT MODIFY BELOW  #####################	
####################  DO NOT MODIFY BELOW  #####################	

webpath='/jffs/scripts/www_FreshJR_QoS_Stats.asp'		#path of FreshJR_QoS_Stats.asp

#marks for iptable rules	 
	Net_mark_down="0x80090001"
	VOIP_mark_down="0x80060001"			# Marks for iptables variant of download rules
	Gaming_mark_down="0x80080001"		    # Note these marks are same as filter match/mask combo but have a 1 at the end.  That trailing 1 prevents them from being caught by unidentified mask
	Others_mark_down="0x800a0001"
	Web_mark_down="0x800d0001"
	Streaming_mark_down="0x80040001"
	Downloads_mark_down="0x80030001"
	Default_mark_down="0x803f0001"	

	Net_mark_up="0x40090001"
	VOIP_mark_up="0x40060001"			# Marks for iptables variant of upload rules
	Gaming_mark_up="0x40080001"		    # Note these marks are same as filter match/mask combo but have a 1 at the end.  That trailing 1 prevents them from being caught by unidentified mask
	Others_mark_up="0x400a0001"
	Web_mark_up="0x400d0001"
	Streaming_mark_up="0x40040001"
	Downloads_mark_up="0x40030001"
	Default_mark_up="0x403f0001"

set_tc_variables(){

	if [ -e "/usr/sbin/realtc" ] ; then	
		tc="realtc"
	else
		tc="tc"
	fi
	
	#read order of QOS categories
	Defaults="1:17"
	Net="1:10"
	flowid=0
	while read -r line;				# reads users order of QOS categories
	do		
		#logger -s "${line}    ${flowid}"
		case ${line} in	
		 '0')
			VOIP="1:1${flowid}"
			eval "Cat${flowid}DownBandPercent=${drp1}"
			eval "Cat${flowid}UpBandPercent=${urp1}"
			eval "Cat${flowid}DownCeilPercent=${dcp1}"
			eval "Cat${flowid}UpCeilPercent=${ucp1}"
			;;
		 '1')
			Downloads="1:1${flowid}"
			eval "Cat${flowid}DownBandPercent=${drp7}"
			eval "Cat${flowid}UpBandPercent=${urp7}"
			eval "Cat${flowid}DownCeilPercent=${dcp7}"
			eval "Cat${flowid}UpCeilPercent=${ucp7}"
			;;
		 '4')
			Streaming="1:1${flowid}"
			eval "Cat${flowid}DownBandPercent=${drp5}"
			eval "Cat${flowid}UpBandPercent=${urp5}"
			eval "Cat${flowid}DownCeilPercent=${dcp5}"
			eval "Cat${flowid}UpCeilPercent=${ucp5}"
			;;
		 '7')
			Others="1:1${flowid}"
			eval "Cat${flowid}DownBandPercent=${drp3}"
			eval "Cat${flowid}UpBandPercent=${urp3}"
			eval "Cat${flowid}DownCeilPercent=${dcp3}"
			eval "Cat${flowid}UpCeilPercent=${ucp3}"
			;;
		 '8')
			Gaming="1:1${flowid}"
			eval "Cat${flowid}DownBandPercent=${drp2}"
			eval "Cat${flowid}UpBandPercent=${urp2}"
			eval "Cat${flowid}DownCeilPercent=${dcp2}"
			eval "Cat${flowid}UpCeilPercent=${ucp2}"
			;;
		 '9')
			#net control
			flowid=0
			;;
		 '13')
			Web="1:1${flowid}"
			eval "Cat${flowid}DownBandPercent=${drp4}"
			eval "Cat${flowid}UpBandPercent=${urp4}"
			eval "Cat${flowid}DownCeilPercent=${dcp4}"
			eval "Cat${flowid}UpCeilPercent=${ucp4}"
			;;
		esac
		
		firstchar="${line%%[0-9]*}"
		if [ "${firstchar}" == "[" ] ; then
			flowid=$((flowid + 1))
			#logger -s "flowid = ${flowid} ==========="
		fi
		
	done <<EOF
		$(cat /tmp/bwdpi/qosd.conf | sed 's/rule=//g' | sed '/na/q')		
EOF

	#calculate up/down rates
	DownCeil="$(printf "%.0f" $(nvram get qos_ibw))"							
	UpCeil="$(printf "%.0f" $(nvram get qos_obw))"								
	
	DownRate0="$(expr ${DownCeil} \* ${drp0} / 100)"					#Minimum guaranteed Up/Down rates per QOS category corresponding to user defined percentages 
	DownRate1="$(expr ${DownCeil} \* ${Cat1DownBandPercent} / 100)"
	DownRate2="$(expr ${DownCeil} \* ${Cat2DownBandPercent} / 100)"
	DownRate3="$(expr ${DownCeil} \* ${Cat3DownBandPercent} / 100)"
	DownRate4="$(expr ${DownCeil} \* ${Cat4DownBandPercent} / 100)"
	DownRate5="$(expr ${DownCeil} \* ${Cat5DownBandPercent} / 100)"
	DownRate6="$(expr ${DownCeil} \* ${Cat6DownBandPercent} / 100)"
	DownRate7="$(expr ${DownCeil} \* ${drp6} / 100)"

	
	UpRate0="$(expr ${UpCeil} \* ${urp0} / 100)"
	UpRate1="$(expr ${UpCeil} \* ${Cat1UpBandPercent} / 100)"
	UpRate2="$(expr ${UpCeil} \* ${Cat2UpBandPercent} / 100)"
	UpRate3="$(expr ${UpCeil} \* ${Cat3UpBandPercent} / 100)"
	UpRate4="$(expr ${UpCeil} \* ${Cat4UpBandPercent} / 100)"
	UpRate5="$(expr ${UpCeil} \* ${Cat5UpBandPercent} / 100)"
	UpRate6="$(expr ${UpCeil} \* ${Cat6UpBandPercent} / 100)"
	UpRate7="$(expr ${UpCeil} \* ${urp6} / 100)"
	
	DownCeil0="$(expr ${DownCeil} \* ${dcp0} / 100)"					#Minimum guaranteed Up/Down rates per QOS category corresponding to user defined percentages 
	DownCeil1="$(expr ${DownCeil} \* ${Cat1DownCeilPercent} / 100)"
	DownCeil2="$(expr ${DownCeil} \* ${Cat2DownCeilPercent} / 100)"
	DownCeil3="$(expr ${DownCeil} \* ${Cat3DownCeilPercent} / 100)"
	DownCeil4="$(expr ${DownCeil} \* ${Cat4DownCeilPercent} / 100)"
	DownCeil5="$(expr ${DownCeil} \* ${Cat5DownCeilPercent} / 100)"
	DownCeil6="$(expr ${DownCeil} \* ${Cat6DownCeilPercent} / 100)"
	DownCeil7="$(expr ${DownCeil} \* ${dcp6} / 100)"

	
	UpCeil0="$(expr ${UpCeil} \* ${ucp0} / 100)"
	UpCeil1="$(expr ${UpCeil} \* ${Cat1UpCeilPercent} / 100)"
	UpCeil2="$(expr ${UpCeil} \* ${Cat2UpCeilPercent} / 100)"
	UpCeil3="$(expr ${UpCeil} \* ${Cat3UpCeilPercent} / 100)"
	UpCeil4="$(expr ${UpCeil} \* ${Cat4UpCeilPercent} / 100)"
	UpCeil5="$(expr ${UpCeil} \* ${Cat5UpCeilPercent} / 100)"
	UpCeil6="$(expr ${UpCeil} \* ${Cat6UpCeilPercent} / 100)"
	UpCeil7="$(expr ${UpCeil} \* ${ucp6} / 100)"
	
	ClassesPresent=0
	#read existing burst/cburst per download class
	while read -r line;																			
	do
		ClassesPresent=$(($ClassesPresent+1))
		if [ "$( echo ${line} | sed -n -e 's/.*1:10 //p' )" != "" ] ; then														
			DownBurst0=$( echo ${line} | sed -n -e 's/.* burst \([a-zA-z0-9]*\).*/\1/p' )
			DownCburst0=$( echo ${line} | sed -n -e 's/.*cburst \([a-zA-z0-9]*\).*/\1/p' )
		fi
		
		if [ "$( echo ${line} | sed -n -e 's/.*1:11 //p' )" != "" ] ; then														
			DownBurst1=$( echo ${line} | sed -n -e 's/.* burst \([a-zA-z0-9]*\).*/\1/p' )
			DownCburst1=$( echo ${line} | sed -n -e 's/.*cburst \([a-zA-z0-9]*\).*/\1/p' )
		fi
		
		if [ "$( echo ${line} | sed -n -e 's/.*1:12 //p' )" != "" ] ; then														
			DownBurst2=$( echo ${line} | sed -n -e 's/.* burst \([a-zA-z0-9]*\).*/\1/p' )
			DownCburst2=$( echo ${line} | sed -n -e 's/.*cburst \([a-zA-z0-9]*\).*/\1/p' )
		fi

		if [ "$( echo ${line} | sed -n -e 's/.*1:13 //p' )" != "" ] ; then														
			DownBurst3=$( echo ${line} | sed -n -e 's/.* burst \([a-zA-z0-9]*\).*/\1/p' )
			DownCburst3=$( echo ${line} | sed -n -e 's/.*cburst \([a-zA-z0-9]*\).*/\1/p' )
		fi

		if [ "$( echo ${line} | sed -n -e 's/.*1:14 //p' )" != "" ] ; then														
			DownBurst4=$( echo ${line} | sed -n -e 's/.* burst \([a-zA-z0-9]*\).*/\1/p' )
			DownCburst4=$( echo ${line} | sed -n -e 's/.*cburst \([a-zA-z0-9]*\).*/\1/p' )
		fi

		if [ "$( echo ${line} | sed -n -e 's/.*1:15 //p' )" != "" ] ; then														
			DownBurst5=$( echo ${line} | sed -n -e 's/.* burst \([a-zA-z0-9]*\).*/\1/p' )
			DownCburst5=$( echo ${line} | sed -n -e 's/.*cburst \([a-zA-z0-9]*\).*/\1/p' )
		fi

		if [ "$( echo ${line} | sed -n -e 's/.*1:16 //p' )" != "" ] ; then														
			DownBurst6=$( echo ${line} | sed -n -e 's/.* burst \([a-zA-z0-9]*\).*/\1/p' )
			DownCburst6=$( echo ${line} | sed -n -e 's/.*cburst \([a-zA-z0-9]*\).*/\1/p' )
		fi				

		if [ "$( echo ${line} | sed -n -e 's/.*1:17 //p' )" != "" ] ; then														
			DownBurst7=$( echo ${line} | sed -n -e 's/.* burst \([a-zA-z0-9]*\).*/\1/p' )
			DownCburst7=$( echo ${line} | sed -n -e 's/.*cburst \([a-zA-z0-9]*\).*/\1/p' )
		fi				
	done <<EOF
		$( tc class show dev br0 | grep "parent 1:1 " )
EOF

	#read existing burst/cburst per upload class
	while read -r line;																			
	do
		if [ "$( echo ${line} | sed -n -e 's/.*1:10 //p' )" != "" ] ; then														
			UpBurst0=$( echo ${line} | sed -n -e 's/.* burst \([a-zA-z0-9]*\).*/\1/p' )
			UpCburst0=$( echo ${line} | sed -n -e 's/.*cburst \([a-zA-z0-9]*\).*/\1/p' )
		fi
		
		if [ "$( echo ${line} | sed -n -e 's/.*1:11 //p' )" != "" ] ; then														
			UpBurst1=$( echo ${line} | sed -n -e 's/.* burst \([a-zA-z0-9]*\).*/\1/p' )
			UpCburst1=$( echo ${line} | sed -n -e 's/.*cburst \([a-zA-z0-9]*\).*/\1/p' )
		fi
		
		if [ "$( echo ${line} | sed -n -e 's/.*1:12 //p' )" != "" ] ; then														
			UpBurst2=$( echo ${line} | sed -n -e 's/.* burst \([a-zA-z0-9]*\).*/\1/p' )
			UpCburst2=$( echo ${line} | sed -n -e 's/.*cburst \([a-zA-z0-9]*\).*/\1/p' )
		fi

		if [ "$( echo ${line} | sed -n -e 's/.*1:13 //p' )" != "" ] ; then														
			UpBurst3=$( echo ${line} | sed -n -e 's/.* burst \([a-zA-z0-9]*\).*/\1/p' )
			UpCburst3=$( echo ${line} | sed -n -e 's/.*cburst \([a-zA-z0-9]*\).*/\1/p' )
		fi

		if [ "$( echo ${line} | sed -n -e 's/.*1:14 //p' )" != "" ] ; then														
			UpBurst4=$( echo ${line} | sed -n -e 's/.* burst \([a-zA-z0-9]*\).*/\1/p' )
			UpCburst4=$( echo ${line} | sed -n -e 's/.*cburst \([a-zA-z0-9]*\).*/\1/p' )
		fi

		if [ "$( echo ${line} | sed -n -e 's/.*1:15 //p' )" != "" ] ; then														
			UpBurst5=$( echo ${line} | sed -n -e 's/.* burst \([a-zA-z0-9]*\).*/\1/p' )
			UpCburst5=$( echo ${line} | sed -n -e 's/.*cburst \([a-zA-z0-9]*\).*/\1/p' )
		fi

		if [ "$( echo ${line} | sed -n -e 's/.*1:16 //p' )" != "" ] ; then														
			UpBurst6=$( echo ${line} | sed -n -e 's/.* burst \([a-zA-z0-9]*\).*/\1/p' )
			UpCburst6=$( echo ${line} | sed -n -e 's/.*cburst \([a-zA-z0-9]*\).*/\1/p' )
		fi				

		if [ "$( echo ${line} | sed -n -e 's/.*1:17 //p' )" != "" ] ; then														
			UpBurst7=$( echo ${line} | sed -n -e 's/.* burst \([a-zA-z0-9]*\).*/\1/p' )
			UpCburst7=$( echo ${line} | sed -n -e 's/.*cburst \([a-zA-z0-9]*\).*/\1/p' )
		fi				
	done <<EOF
		$( tc class show dev eth0 | grep "parent 1:1 " )
EOF


	#read parameters for fakeTC
	PARMS=""
	OVERHEAD=$(nvram get qos_overhead)
	if [ ! -z "$OVERHEAD" ] && [ "$OVERHEAD" -gt "0" ] ; then
		ATM=$(nvram get qos_atm)
		if [ "$ATM" == "1" ] ; then
			PARMS="overhead $OVERHEAD linklayer atm "
		else
			PARMS="overhead $OVERHEAD linklayer ethernet "
		fi
	fi
	
	
}	

## Main Menu -appdb function
appdb(){

	if [ "$( grep -i "${1}"  /tmp/bwdpi/bwdpi.app.db | wc -l )" -lt "25" ] ; then
		grep -i "${1}"  /tmp/bwdpi/bwdpi.app.db | while read -r line ; do
			echo $line | cut -f 4 -d ","

			cat_decimal=$(echo $line | cut -f 1 -d "," )
			cat_hex=$( printf "%02x" $cat_decimal )
			case "$cat_decimal" in
			 '9'|'20')
			   echo " Originally:  Net Control"
			   ;;
			 '0'|'5'|'6'|'15'|'17')
			   echo " Originally:  VoIP"
			   ;;
			 '8')
			   echo " Originally:  Gaming"
			   ;;
			 '7'|'10'|'11'|'21'|'23')
			   echo " Originally:  Others"
			   ;;
			 '13'|'24'|'18'|'19')
			   echo " Originally:  Web"
			   ;;			   
			 '4'|'12')
			   echo " Originally:  Streaming"
			   ;;						   
			 '1'|'3'|'14')
			   echo " Originally:  Downloads"
			   ;;				   
			esac
			
			echo -n  " Mark:        ${cat_hex}"
			echo $line | cut -f 2 -d "," | awk '{printf("%04x \n",$1)}'
			
			#parameters required for manually creating TC rules
			  #echo " TC Prio   : $(expr $(tc filter show dev br0 | grep "${cat_hex}0000" -B1 | tail -2 | cut -d " " -f7 | head -1) - 1)"
			  #printf " Down Mark : 0x80${cat_hex}"
			  #echo $line | cut -f 2 -d "," | awk '{printf("%04x 0xc03fffff\n",$1)}'
			  #printf " UP   Mark : 0x40${cat_hex}"
			  #echo $line | cut -f 2 -d "," | awk '{printf("%04x 0xc03fffff\n",$1)}'
			echo ""
		done
	else
		echo "AppDB search parameter has to be more specfic"
	fi
}

## Main Menu -debug function
debug(){
	echo -en "\033c\e[3J"		#clear screen
	echo -en '\033[?7l'			#disable line wrap
	echo -e  "\033[1;32mFreshJR QOS v${version}\033[0m"
	echo "Debug:"
	echo ""
	read_nvram
	set_tc_variables
	current_undf_rule="$(tc filter show dev br0 | grep -v "/" | grep "000ffff" -B1)"
	undf_flowid=$(echo $current_undf_rule | grep -o "flowid.*" | cut -d" " -f2 | head -1)
	undf_prio=$(echo $current_undf_rule | grep -o "pref.*" | cut -d" " -f2 | head -1)
	
	logger -t "adaptive QOS" -s "Undf Prio: $undf_prio"
	logger -t "adaptive QOS" -s "Undf FlowID: $undf_flowid"
	logger -t "adaptive QOS" -s "Classes Present: $ClassesPresent"
	logger -t "adaptive QOS" -s "Down Band: $DownCeil"
	logger -t "adaptive QOS" -s "Up Band  : $UpCeil"
	logger -t "adaptive QOS" -s "***********"
	logger -t "adaptive QOS" -s "Net = ${Net}"
	logger -t "adaptive QOS" -s "VOIP = ${VOIP}"
	logger -t "adaptive QOS" -s "Gaming = ${Gaming}"
	logger -t "adaptive QOS" -s "Others = ${Others}"
	logger -t "adaptive QOS" -s "Web = ${Web}"
	logger -t "adaptive QOS" -s "Streaming = ${Streaming}"
	logger -t "adaptive QOS" -s "Downloads = ${Downloads}"
	logger -t "adaptive QOS" -s "Defaults = ${Defaults}"
	logger -t "adaptive QOS" -s "***********"
	logger -t "adaptive QOS" -s "Downrates -- $DownRate0, $DownRate1, $DownRate2, $DownRate3, $DownRate4, $DownRate5, $DownRate6, $DownRate7"
	logger -t "adaptive QOS" -s "Downceils -- $DownCeil0, $DownCeil1, $DownCeil2, $DownCeil3, $DownCeil4, $DownCeil5, $DownCeil6, $DownCeil7"
	logger -t "adaptive QOS" -s "Downbursts -- $DownBurst0, $DownBurst1, $DownBurst2, $DownBurst3, $DownBurst4, $DownBurst5, $DownBurst6, $DownBurst7"
	logger -t "adaptive QOS" -s "DownCbursts -- $DownCburst0, $DownCburst1, $DownCburst2, $DownCburst3, $DownCburst4, $DownCburst5, $DownCburst6, $DownCburst7"
	logger -t "adaptive QOS" -s "***********"
	logger -t "adaptive QOS" -s "Uprates -- $UpRate0, $UpRate1, $UpRate2, $UpRate3, $UpRate4, $UpRate5, $UpRate6, $UpRate7"
	logger -t "adaptive QOS" -s "Upciels -- $UpCeil0, $UpCeil1, $UpCeil2, $UpCeil3, $UpCeil4, $UpCeil5, $UpCeil6, $UpCeil7"
	logger -t "adaptive QOS" -s "Upbursts -- $UpBurst0, $UpBurst1, $UpBurst2, $UpBurst3, $UpBurst4, $UpBurst5, $UpBurst6, $UpBurst7"
	logger -t "adaptive QOS" -s "UpCbursts -- $UpCburst0, $UpCburst1, $UpCburst2, $UpCburst3, $UpCburst4, $UpCburst5, $UpCburst6, $UpCburst7"
	echo -en '\033[?7h'			#enable line wrap
}

debug2(){
	echo -en "\033c\e[3J"		#clear screen
	echo -en '\033[?7l'			#disable line wrap
	echo -e  "\033[1;32mFreshJR QOS v${version}\033[0m"
	echo "Debug2:"
	echo ""
	read_nvram
	set_tc_variables
	parse_iptablerule "${e1}" "${e2}" "${e3}" "${e4}" "${e5}" "${e6}" "${e7}" ip1_down ip1_up
	parse_iptablerule "${f1}" "${f2}" "${f3}" "${f4}" "${f5}" "${f6}" "${f7}" ip2_down ip2_up
	parse_iptablerule "${g1}" "${g2}" "${g3}" "${g4}" "${g5}" "${g6}" "${g7}" ip3_down ip3_up
	parse_iptablerule "${h1}" "${h2}" "${h3}" "${h4}" "${h5}" "${h6}" "${h7}" ip4_down ip4_up
	parse_tcrule "${r1}" "${d1}" tc1_down tc1_up
	parse_tcrule "${r2}" "${d2}" tc2_down tc2_up
	parse_tcrule "${r3}" "${d3}" tc3_down tc3_up
	parse_tcrule "${r4}" "${d4}" tc4_down tc4_up
	echo -en '\033[?7l'			#disable line wrap
		
	echo "Game CIDR: ${gameCIDR}"
	echo ""
	if [ "$(echo ${ip1_down} | grep -c "both")" -ge "1" ] ; then
		echo "Rule1 Down: ${ip1_down//both/tcp}"
		echo "          : ${ip1_down//both/udp}"
		echo "Rule1 Up  : ${ip1_up//both/tcp}"
		echo "          : ${ip1_up//both/udp}"
	else
		echo "Rule1 Down: ${ip1_down}"
		echo "Rule1 Up  : ${ip1_up}"
	fi
	echo ""
	if [ "$(echo ${ip2_down} | grep -c "both")" -ge "1" ] ; then
		echo "Rule2 Down: ${ip2_down//both/tcp}"
		echo "            ${ip2_down//both/udp}"
		echo "Rule2 Up  : ${ip2_up//both/tcp}"
		echo "            ${ip2_up//both/udp}"
	else
		echo "Rule2 Down: ${ip2_down}"
		echo "Rule2 Up  : ${ip2_up}"
	fi
	echo ""
	if [ "$(echo ${ip3_down} | grep -c "both")" -ge "1" ] ; then
		echo "Rule3 Down: ${ip3_down//both/tcp}"
		echo "          : ${ip3_down//both/udp}"
		echo "Rule3 Up  : ${ip3_up//both/tcp}"
		echo "          : ${ip3_up//both/udp}"
	else
		echo "Rule3 Down: ${ip3_down}"
		echo "Rule3 Up  : ${ip3_up}"
	fi
	echo ""
	if [ "$(echo ${ip4_down} | grep -c "both")" -ge "1" ] ; then
		echo "Rule4 Down: ${ip4_down//both/tcp}"
		echo "            ${ip4_down//both/udp}"
		echo "Rule4 Up  : ${ip4_up//both/tcp}"
		echo "            ${ip4_up//both/udp}"
	else
		echo "Rule4 Down: ${ip4_down}"
		echo "Rule4 Up  : ${ip4_up}"
	fi
	echo ""
	echo "AppDB1 Down:  ${tc1_down}"	
	echo "AppDB1 Up  :  ${tc1_up}"
	echo ""
	echo "AppDB2 Down:  ${tc2_down}"	
	echo "AppDB2 Up  :  ${tc2_up}"
	echo ""
	echo "AppDB3 Down:  ${tc3_down}"	
	echo "AppDB3 Up  :  ${tc3_up}"
	echo ""
	echo "AppDB4 Down:  ${tc4_down}"	
	echo "AppDB4 Up  :  ${tc4_up}"

	echo -en '\033[?7h'			#enable line wrap
}

## Main Menu -gameip function
gameip(){
	if [ "$( echo $1 | tr -cd '.' | wc -c )" -eq "3" ] ; then
		gameCIDR=${input}
	else
		gameCIDR=''
	fi
	save_nvram
}

## helper function to parse csv nvram variables
read_nvram(){
	OLDIFS=$IFS
	IFS=";" 

	if [ $(nvram get fb_comment | sed 's/>/;/g' | tr -cd ';' | wc -c) -ne 20 ] ; then
		$(nvram set fb_comment=";;;;;;>;;;;;;>;;;;;;")
	fi

	if [ $(nvram get fb_email_dbg | sed 's/>/;/g' | tr -cd ';' | wc -c) -ne 48 ] ; then
		$(nvram set fb_email_dbg=";;;;;;>;>;>;>;>>>5;20;15;10;10;30;5;5>100;100;100;100;100;100;100;100>5;20;15;30;10;10;5;5>100;100;100;100;100;100;100;100")
	fi

	read \
		e1 e2 e3 e4 e5 e6 e7 \
		f1 f2 f3 f4 f5 f6 f7 \
		g1 g2 g3 g4 g5 g6 g7 \
<<EOF
$(nvram get fb_comment | sed 's/>/;/g' )
EOF

	read \
		h1 h2 h3 h4 h5 h6 h7 \
		r1 d1 \
		r2 d2 \
		r3 d3 \
		r4 d4 \
		gameCIDR \
		ruleFLAG \
		drp0 drp1 drp2 drp3 drp4 drp5 drp6 drp7 \
		dcp0 dcp1 dcp2 dcp3 dcp4 dcp5 dcp6 dcp7 \
		urp0 urp1 urp2 urp3 urp4 urp5 urp6 urp7 \
		ucp0 ucp1 ucp2 ucp3 ucp4 ucp5 ucp6 ucp7 \
<<EOF
$(nvram get fb_email_dbg | sed 's/>/;/g' )
EOF
	IFS=$OLDIFS

	#Verify each read nvram rate is between 5-100  (disabled unless needed in future)
	# [ "${drp0//[^0-9]}" -ge "5" ] && [ "${drp0//[^0-9]}" -le "100" ] && drp0="5"
	# [ "${drp1//[^0-9]}" -ge "5" ] && [ "${drp1//[^0-9]}" -le "100" ] && drp1="20"
	# [ "${drp2//[^0-9]}" -ge "5" ] && [ "${drp2//[^0-9]}" -le "100" ] && drp2="15"
	# [ "${drp3//[^0-9]}" -ge "5" ] && [ "${drp3//[^0-9]}" -le "100" ] && drp3="10"
	# [ "${drp4//[^0-9]}" -ge "5" ] && [ "${drp4//[^0-9]}" -le "100" ] && drp4="10"
	# [ "${drp5//[^0-9]}" -ge "5" ] && [ "${drp5//[^0-9]}" -le "100" ] && drp5="30"
	# [ "${drp6//[^0-9]}" -ge "5" ] && [ "${drp6//[^0-9]}" -le "100" ] && drp6="5"
	# [ "${drp7//[^0-9]}" -ge "5" ] && [ "${drp7//[^0-9]}" -le "100" ] && drp7="5"

	# [ "${dcp0//[^0-9]}" -ge "5" ] && [ "${dcp0//[^0-9]}" -le "100" ] && dcp0="100"
	# [ "${dcp1//[^0-9]}" -ge "5" ] && [ "${dcp1//[^0-9]}" -le "100" ] && dcp1="100"
	# [ "${dcp2//[^0-9]}" -ge "5" ] && [ "${dcp2//[^0-9]}" -le "100" ] && dcp2="100"
	# [ "${dcp3//[^0-9]}" -ge "5" ] && [ "${dcp3//[^0-9]}" -le "100" ] && dcp3="100"
	# [ "${dcp4//[^0-9]}" -ge "5" ] && [ "${dcp4//[^0-9]}" -le "100" ] && dcp4="100"
	# [ "${dcp5//[^0-9]}" -ge "5" ] && [ "${dcp5//[^0-9]}" -le "100" ] && dcp5="100"
	# [ "${dcp6//[^0-9]}" -ge "5" ] && [ "${dcp6//[^0-9]}" -le "100" ] && dcp6="100"
	# [ "${dcp7//[^0-9]}" -ge "5" ] && [ "${dcp7//[^0-9]}" -le "100" ] && dcp7="100"

	# [ "${urp0//[^0-9]}" -ge "5" ] && [ "${urp0//[^0-9]}" -le "100" ] && urp0="5"
	# [ "${urp1//[^0-9]}" -ge "5" ] && [ "${urp1//[^0-9]}" -le "100" ] && urp1="20"
	# [ "${urp2//[^0-9]}" -ge "5" ] && [ "${urp2//[^0-9]}" -le "100" ] && urp2="15"
	# [ "${urp3//[^0-9]}" -ge "5" ] && [ "${urp3//[^0-9]}" -le "100" ] && urp3="30"
	# [ "${urp4//[^0-9]}" -ge "5" ] && [ "${urp4//[^0-9]}" -le "100" ] && urp4="10"
	# [ "${urp5//[^0-9]}" -ge "5" ] && [ "${urp5//[^0-9]}" -le "100" ] && urp5="10"
	# [ "${urp6//[^0-9]}" -ge "5" ] && [ "${urp6//[^0-9]}" -le "100" ] && urp6="5"
	# [ "${urp7//[^0-9]}" -ge "5" ] && [ "${urp7//[^0-9]}" -le "100" ] && urp7="5"

	# [ "${ucp0//[^0-9]}" -ge "5" ] && [ "${ucp0//[^0-9]}" -le "100" ] && ucp0="100"
	# [ "${ucp1//[^0-9]}" -ge "5" ] && [ "${ucp1//[^0-9]}" -le "100" ] && ucp1="100"
	# [ "${ucp2//[^0-9]}" -ge "5" ] && [ "${ucp2//[^0-9]}" -le "100" ] && ucp2="100"
	# [ "${ucp3//[^0-9]}" -ge "5" ] && [ "${ucp3//[^0-9]}" -le "100" ] && ucp3="100"
	# [ "${ucp4//[^0-9]}" -ge "5" ] && [ "${ucp4//[^0-9]}" -le "100" ] && ucp4="100"
	# [ "${ucp5//[^0-9]}" -ge "5" ] && [ "${ucp5//[^0-9]}" -le "100" ] && ucp5="100"
	# [ "${ucp6//[^0-9]}" -ge "5" ] && [ "${ucp6//[^0-9]}" -le "100" ] && ucp6="100"
	# [ "${ucp7//[^0-9]}" -ge "5" ] && [ "${ucp7//[^0-9]}" -le "100" ] && ucp7="100"
	
	#takes protocol saved in nvram and makes it lower case
	e3=$(echo ${e3}  | tr '[A-Z]' '[a-z]')
	f3=$(echo ${f3}  | tr '[A-Z]' '[a-z]')
	g3=$(echo ${g3}  | tr '[A-Z]' '[a-z]')
	h3=$(echo ${h3}  | tr '[A-Z]' '[a-z]')
}

## helper function to save nvram variables in csv format
save_nvram(){
	$(nvram set fb_comment="${e1};${e2};${e3};${e4};${e5};${e6};${e7}>${f1};${f2};${f3};${f4};${f5};${f6};${f7}>${g1};${g2};${g3};${g4};${g5};${g6};${g7}")
	$(nvram set fb_email_dbg="${h1};${h2};${h3};${h4};${h5};${h6};${h7}>${r1};${d1}>${r2};${d2}>${r3};${d3}>${r4};${d4}>${gameCIDR}>${ruleFLAG}>${drp0};${drp1};${drp2};${drp3};${drp4};${drp5};${drp6};${drp7}>${dcp0};${dcp1};${dcp2};${dcp3};${dcp4};${dcp5};${dcp6};${dcp7}>${urp0};${urp1};${urp2};${urp3};${urp4};${urp5};${urp6};${urp7}>${ucp0};${ucp1};${ucp2};${ucp3};${ucp4};${ucp5};${ucp6};${ucp7}")
	$(nvram commit)
}

## helper function for interactive menu mode
dst_2_name()
{
	case "$1" in	
		0) echo "Net Control" ;;
		1) echo "Gaming" ;;
		2) echo "Streaming" ;;
		3) echo "VoIP" ;;
		4) echo "Web Surfing" ;;
		5) echo "Downloads" ;;
		6) echo "Others" ;;
		7) echo "Game Downloads" ;;
		*) echo "" ;;
	esac
}

## helper function for interactive menu mode
mark_2_name()
{
	return  #function disabled since grep is kinda slow
	[ -z "$1" ] && return
	cat="$( echo ${1} | head -c2 )"
	id="$( echo ${1} | tail -c -5 )"
	cat="$(printf "%d" 0x${cat})"
	id="$(printf "%d" 0x${id})"
	cat /tmp/bwdpi/bwdpi.app.db | grep "^${cat},${id}" | head -n1 |  cut -d',' -f4
}

## INTERACTIVE mode - rate main page (overview)
rates(){
	echo -en "\033c\e[3J"		#clear screen
	echo -en '\033[?7l'			#disable line wrap
	printf '\e[8;30;120t'		#set height/width of terminal
	echo -e  "\033[1;32mFreshJR QOS v${version}\033[0m"
	echo "QoS Rates:      -------Download-------          --------Upload--------"
	echo "                Minimum       Maximum           Minimum       Maximum"
	echo "                Reserved      Reserved          Allowed       Allowed"
	echo "                Bandwidth     Bandwidth         Bandwidth     Bandwidth"
	echo "                (%)           (%)               (%)           (%) "
	echo "                -----------------------         -----------------------"
	format="%-15s %-13s %-18s %-13s %-4s\n" 
	printf "${format}" "Net Control" 	"${drp0}"	"${dcp0}"	"${urp0}"	"${ucp0}"
	printf "${format}" "VoIP"			"${drp1}"	"${dcp1}"	"${urp1}"	"${ucp1}"
	printf "${format}" "Gaming"			"${drp2}"	"${dcp2}"	"${urp2}"	"${ucp2}"	
	printf "${format}" "Others"			"${drp3}"	"${dcp3}"	"${urp3}"	"${ucp3}"
	printf "${format}" "Web Surfing"	"${drp4}"	"${dcp4}"	"${urp4}"	"${ucp4}"
	printf "${format}" "Streaming"		"${drp5}"	"${dcp5}"	"${urp5}"	"${ucp5}"
	printf "${format}" "Game Downloads"	"${drp6}"	"${dcp6}"	"${urp6}"	"${ucp6}"
	printf "${format}" "File Downloads"	"${drp7}"	"${dcp7}"	"${urp7}"	"${ucp7}"
	echo ""
	echo "Available actions:"
	echo ""
	echo "1) Minimum Reserved Bandwidth -- Download"
	echo "2) Minimum Reserved Bandwidth -- Upload"
	echo ""
	echo "3) Maximum Allowed Bandwidth  -- Download"
	echo "4) Maximum Allowed Bandwidth  -- Upload"
	echo ""
	echo "r) Reset Values to Defaults"
	echo "s) Save & Exit"
	echo "e) Exit"
	echo -en '\033[?7h'			#enable line wrap
	echo ""
	echo -n "What would you like to do (Enter 1-10): "
	read input
	echo -en "\033[1A\r\033[0K"  
	echo -en "\033[1A\r\033[0K"  
	echo -en "\033[1A\r\033[0K"  
	echo -en "\033[1A\r\033[0K"  
	echo -en "\033[1A\r\033[0K"  
	echo -en "\033[1A\r\033[0K"  
	echo -en "\033[1A\r\033[0K"  
	echo -en "\033[1A\r\033[0K"  
	echo -en "\033[1A\r\033[0K"  
	echo -en "\033[1A\r\033[0K"  
	echo -en "\033[1A\r\033[0K"  
	case $input in
		1) 
			echo    "Minimum Reserved Bandwidth"
			read -p "  Net Control    : " in0	
			read -p "  Voip           : " in1
			read -p "  Gaming         : " in2
			read -p "  Others         : " in3
			read -p "  Web Surfing    : " in4
			read -p "  Streaming      : " in5
			read -p "  Game Downloads : " in6	
			read -p "  File Downloads : " in7
			[ "${in0//[^0-9]}" -ge "5" ] && [ "${in0//[^0-9]}" -le "100" ] && drp0="${in0//[^0-9]}"
			[ "${in1//[^0-9]}" -ge "5" ] && [ "${in1//[^0-9]}" -le "100" ] && drp1="${in1//[^0-9]}"
			[ "${in2//[^0-9]}" -ge "5" ] && [ "${in2//[^0-9]}" -le "100" ] && drp2="${in2//[^0-9]}"
			[ "${in3//[^0-9]}" -ge "5" ] && [ "${in3//[^0-9]}" -le "100" ] && drp3="${in3//[^0-9]}"
			[ "${in4//[^0-9]}" -ge "5" ] && [ "${in4//[^0-9]}" -le "100" ] && drp4="${in4//[^0-9]}"
			[ "${in5//[^0-9]}" -ge "5" ] && [ "${in5//[^0-9]}" -le "100" ] && drp5="${in5//[^0-9]}"
			[ "${in6//[^0-9]}" -ge "5" ] && [ "${in6//[^0-9]}" -le "100" ] && drp6="${in6//[^0-9]}"
			[ "${in7//[^0-9]}" -ge "5" ] && [ "${in7//[^0-9]}" -le "100" ] && drp7="${in7//[^0-9]}"
			rates			
			;;
		2) 
			echo    "Minimum Reserved Bandwidth"
			read -p "  Net Control    : " in0	
			read -p "  Voip           : " in1
			read -p "  Gaming         : " in2
			read -p "  Others         : " in3
			read -p "  Web Surfing    : " in4
			read -p "  Streaming      : " in5
			read -p "  Game Downloads : " in6	
			read -p "  File Downloads : " in7
			[ "${in0//[^0-9]}" -ge "5" ] && [ "${in0//[^0-9]}" -le "100" ] && urp0="${in0//[^0-9]}" 
			[ "${in1//[^0-9]}" -ge "5" ] && [ "${in1//[^0-9]}" -le "100" ] && urp1="${in1//[^0-9]}" 
			[ "${in2//[^0-9]}" -ge "5" ] && [ "${in2//[^0-9]}" -le "100" ] && urp2="${in2//[^0-9]}" 
			[ "${in3//[^0-9]}" -ge "5" ] && [ "${in3//[^0-9]}" -le "100" ] && urp3="${in3//[^0-9]}" 
			[ "${in4//[^0-9]}" -ge "5" ] && [ "${in4//[^0-9]}" -le "100" ] && urp4="${in4//[^0-9]}" 
			[ "${in5//[^0-9]}" -ge "5" ] && [ "${in5//[^0-9]}" -le "100" ] && urp5="${in5//[^0-9]}" 
			[ "${in6//[^0-9]}" -ge "5" ] && [ "${in6//[^0-9]}" -le "100" ] && urp6="${in6//[^0-9]}" 
			[ "${in7//[^0-9]}" -ge "5" ] && [ "${in7//[^0-9]}" -le "100" ] && urp7="${in7//[^0-9]}" 
			rates			
			;;
		3) 
			echo    "Minimum Reserved Bandwidth"
			read -p "  Net Control    : " in0	
			read -p "  Voip           : " in1
			read -p "  Gaming         : " in2
			read -p "  Others         : " in3
			read -p "  Web Surfing    : " in4
			read -p "  Streaming      : " in5
			read -p "  Game Downloads : " in6	
			read -p "  File Downloads : " in7
			[ "${in0//[^0-9]}" -ge "5" ] && [ "${in0//[^0-9]}" -le "100" ] && dcp0="${in0//[^0-9]}" 
			[ "${in1//[^0-9]}" -ge "5" ] && [ "${in1//[^0-9]}" -le "100" ] && dcp1="${in1//[^0-9]}" 
			[ "${in2//[^0-9]}" -ge "5" ] && [ "${in2//[^0-9]}" -le "100" ] && dcp2="${in2//[^0-9]}" 
			[ "${in3//[^0-9]}" -ge "5" ] && [ "${in3//[^0-9]}" -le "100" ] && dcp3="${in3//[^0-9]}" 
			[ "${in4//[^0-9]}" -ge "5" ] && [ "${in4//[^0-9]}" -le "100" ] && dcp4="${in4//[^0-9]}" 
			[ "${in5//[^0-9]}" -ge "5" ] && [ "${in5//[^0-9]}" -le "100" ] && dcp5="${in5//[^0-9]}" 
			[ "${in6//[^0-9]}" -ge "5" ] && [ "${in6//[^0-9]}" -le "100" ] && dcp6="${in6//[^0-9]}" 
			[ "${in7//[^0-9]}" -ge "5" ] && [ "${in7//[^0-9]}" -le "100" ] && dcp7="${in7//[^0-9]}" 
			rates			
			;;
		4) 
			echo    "Minimum Reserved Bandwidth"
			read -p "  Net Control    : " in0	
			read -p "  Voip           : " in1
			read -p "  Gaming         : " in2
			read -p "  Others         : " in3
			read -p "  Web Surfing    : " in4
			read -p "  Streaming      : " in5
			read -p "  Game Downloads : " in6	
			read -p "  File Downloads : " in7
			[ "${in0//[^0-9]}" -ge "5" ] && [ "${in0//[^0-9]}" -le "100" ] && ucp0="${in0//[^0-9]}" 
			[ "${in1//[^0-9]}" -ge "5" ] && [ "${in1//[^0-9]}" -le "100" ] && ucp1="${in1//[^0-9]}" 
			[ "${in2//[^0-9]}" -ge "5" ] && [ "${in2//[^0-9]}" -le "100" ] && ucp2="${in2//[^0-9]}" 
			[ "${in3//[^0-9]}" -ge "5" ] && [ "${in3//[^0-9]}" -le "100" ] && ucp3="${in3//[^0-9]}" 
			[ "${in4//[^0-9]}" -ge "5" ] && [ "${in4//[^0-9]}" -le "100" ] && ucp4="${in4//[^0-9]}" 
			[ "${in5//[^0-9]}" -ge "5" ] && [ "${in5//[^0-9]}" -le "100" ] && ucp5="${in5//[^0-9]}" 
			[ "${in6//[^0-9]}" -ge "5" ] && [ "${in6//[^0-9]}" -le "100" ] && ucp6="${in6//[^0-9]}" 
			[ "${in7//[^0-9]}" -ge "5" ] && [ "${in7//[^0-9]}" -le "100" ] && ucp7="${in7//[^0-9]}" 
			rates			
			;;
		'r'|'R') 
			drp0="5"
			drp1="20"
			drp2="15"
			drp3="10"
			drp4="10"
			drp5="30"
			drp6="5"
			drp7="5"
			
			dcp0="100"
			dcp1="100"
			dcp2="100"
			dcp3="100"
			dcp4="100"
			dcp5="100"
			dcp6="100"
			dcp7="100"
			
			urp0="5"
			urp1="20"
			urp2="15"
			urp3="30"
			urp4="10"
			urp5="10"
			urp6="5"
			urp7="5"
			
			ucp0="100"
			ucp1="100"
			ucp2="100"
			ucp3="100"
			ucp4="100"
			ucp5="100"
			ucp6="100"
			ucp7="100"
			rates
			;;
		's'|'S') 
			save_nvram
			echo " Saving Changes"			
			[ "$(nvram get qos_enable)" == "1" ] && prompt_restart
			return 1 
			;;
		'e'|'E') 
			echo -e "\033[1;31;7m  No Changes have been saved \033[0m"
			echo ""
			return 0 ;;
		*) 
			rates ;;
	esac
}

## INTERACTIVE mode - rule main page (overview)
rules(){
	echo -en "\033c\e[3J"		#clear screen
	echo -en '\033[?7l'			#disable line wrap
	printf '\e[8;30;120t'		#set height/width of terminal
	echo -e  "\033[1;32mFreshJR QOS v${version}\033[0m"
	echo "Custom QoS Rules:"
	echo "             Local IP            Remote IP           Proto  Local Port     Remote Port    Mark        Dst"
  printf '1)  Rule     %-19s %-19s %-6s %-14s %-14s %-7s %-10s\n' "$e1" "$e2" "$e3" "$e4" "$e5" "$e6" "$([ -z $e7 ] || echo "--> $(dst_2_name $e7)")"
  printf '2)  Rule     %-19s %-19s %-6s %-14s %-14s %-7s %-10s\n' "$f1" "$f2" "$f3" "$f4" "$f5" "$f6" "$([ -z $f7 ] || echo "--> $(dst_2_name $f7)")"
  printf '3)  Rule     %-19s %-19s %-6s %-14s %-14s %-7s %-10s\n' "$g1" "$g2" "$g3" "$g4" "$g5" "$g6" "$([ -z $g7 ] || echo "--> $(dst_2_name $g7)")"
  printf '4)  Rule     %-19s %-19s %-6s %-14s %-14s %-7s %-10s\n' "$h1" "$h2" "$h3" "$h4" "$h5" "$h6" "$([ -z $h7 ] || echo "--> $(dst_2_name $h7)")"
  printf '5)  Gameip   %-19s %-19s %-6s %-14s %-14s %-7s %-10s\n'  "${gameCIDR}" "" "$([ -z $gameCIDR ] || echo "both")" "" "$([ -z $gameCIDR ] || echo "!80:443")" "$([ -z $gameCIDR ] || echo "000000")" "--> Gaming"
  printf '6)  Appdb    %-44s                                 %-7s %-10s\n' "$(mark_2_name $r1)" "$r1" "$([ -z $d1 ] || echo "--> $(dst_2_name $d1)")"
  printf '7)  Appdb    %-44s                                 %-7s %-10s\n' "$(mark_2_name $r2)" "$r2" "$([ -z $d2 ] || echo "--> $(dst_2_name $d2)")"
  printf '8)  Appdb    %-44s                                 %-7s %-10s\n' "$(mark_2_name $r3)" "$r3" "$([ -z $d3 ] || echo "--> $(dst_2_name $d3)")"
  printf '9)  Appdb    %-44s                                 %-7s %-10s\n' "$(mark_2_name $r4)" "$r4" "$([ -z $d4 ] || echo "--> $(dst_2_name $d4)")"

	echo ""
	echo "s) Save & Exit"
	echo "e) Exit"
	echo -en '\033[?7h'			#enable line wrap
	echo ""
	echo -n "Select Rule to Modify (Enter 1-9): "
	read input
	case $input in
		'1') iprule e1 e2 e3 e4 e5 e6 e7 "Rule 1";;
		'2') iprule f1 f2 f3 f4 f5 f6 f7 "Rule 2";;
		'3') iprule g1 g2 g3 g4 g5 g6 g7 "Rule 3";; 
		'4') iprule h1 h2 h3 h4 h5 h6 h7 "Rule 4";;
		'5') gamerule ;;
		'6') apprule r1 d1 "Appdb 1" ;;
		'7') apprule r2 d2 "Appdb 2" ;;
		'8') apprule r3 d3 "Appdb 3" ;;
		'9') apprule r4 d4 "Appdb 4" ;;
		's'|'S') 
		    echo ""
			echo "Saving Changes"
		    save_nvram
			[ "$(nvram get qos_enable)" == "1" ] && prompt_restart
			return 1 
			;;
		'e'|'E') 
		    echo ""
			echo -e "\033[1;31;7m  No Changes have been saved \033[0m"
			echo ""
			return 0 ;;
		*) 
			rules ;;
	esac
}

## INTERACTIVE mode - modify iptable rule
iprule()
{
	echo -en "\033c\e[3J"
	echo -en '\033[?7l'			#disable line wrap
	echo -e  "\033[1;32mFreshJR QOS v${version} \033[0m"
	echo "Modifying ${8}"
	echo -n "1)  Name              " && sed -nE 's/var rulename'${8//[^0-9]/}'="(.*?)";/\1/p' "${webpath}"
	echo -n "2)  Local IP          " && eval "echo \${$1}"
	echo -n "3)  Remote IP         " && eval "echo \${$2}"
	echo -n "4)  Local Port        " && [ -z $(eval "echo \${$4}") ] && echo || eval "echo \${$3} \${$4}"	#if ${4} is blank then leave field blank else populate
	echo -n "5)  Remote Port       " && [ -z $(eval "echo \${$5}") ] && echo || eval "echo \${$3} \${$5}"	#if ${5} is blank then leave field blank else populate
	echo -n "6)  Protocol          " && eval "echo \${$3}"
	echo -n "7)  QoS Mark          " && eval "echo \${$6}"
	echo -n "8)  Destination       " && eval "dst_2_name \${$7}"
	echo ""
	echo "r)  Reset / Disable"
	echo "e)  Go Back"
	echo ""
	in_progress=1
	while [ ${in_progress} -eq 1 ] ; do
		echo -n "Select Parameter to Modify (Enter 1-8): "
		read input
		echo -en "\033[1A\r\033[0K" 		#clear user input prompt
			case $input in
				1) #name
					echo -ne "\033[1;32m"
					echo  "  WebUI Rule Name"
					echo  ""
					echo -ne  "\033[0m"
					echo -n "  Name(Rule${8//[^0-9]/})="
					#read user input
					read input
					if [ -z $input ] ; then
						input="${8// /}"
					fi
					echo -en "\033[1A\r\033[0K" 
					echo -en "\033[1A\r\033[0K"  
					echo -en "\033[1A\r\033[0K"  
					#make changes to WebUI.asp page
					echo "$( cat "${webpath}" | sed -E 's/var rulename'"${8//[^0-9]/}"'="(.*?)";/var rulename'"${8//[^0-9]/}"'="'"${input}"'";/')"  > "${webpath}"
					#update table entry
					echo -en "\033[3;0f\033[0K"  #move to line 3 pos 0 \ erase to end
					echo -n "1)  Name              " && sed -nE 's/var rulename'${8//[^0-9]/}'="(.*?)";/\1/p' "${webpath}"
					;;
					
				2) #local ip 
					#show valid syntax
					echo -ne "\033[1;32m"
					echo    "  Local IP      Syntax: 192.168.X.XXX      or !192.168.X.XXX"
					echo    "                        192.168.X.XXX/CIDR or !192.168.X.XXX/CIDR"
					echo    ""
					echo -ne  "\033[0m"
					echo -n "  Local IP="
					#read user input
					read input
					eval "$1=\$input" 
					#clear syntax+input
					echo -en "\033[1A\r\033[0K"  #up one line \ beginning line \ erase to end
					echo -en "\033[1A\r\033[0K"  
					echo -en "\033[1A\r\033[0K" 
					echo -en "\033[1A\r\033[0K"
					#update table entry
					echo -en "\033[4;0f\033[0K"  #move to line 4 pos 0 \ erase to end
					echo -n "2)  Local IP          " && eval "echo \${$1}"
					;;
				3) #remote ip
					#show valid syntax
					echo -ne "\033[1;32m"
					echo    "  Remote IP Syntax: 75.75.75.75      or !75.75.75.75     "
					echo    "                    75.75.75.75/CIDR or !75.75.75.75/CIDR"
					echo    ""
					echo -ne  "\033[0m"
					echo -n "  Remote IP="
					#read user input
					read input
					eval "$2=\$input" 
					#clear syntax+input
					echo -en "\033[1A\r\033[0K" 
					echo -en "\033[1A\r\033[0K"  
					echo -en "\033[1A\r\033[0K"  
					echo -en "\033[1A\r\033[0K"  
					#update table entry
					echo -en "\033[5;0f\033[0K"  #move to line 5 pos 0 \ erase to end
					echo -n "3)  Remote IP         " && eval "echo \${$2}"
					;;
				4) #local port
					#show valid syntax
					echo -ne "\033[1;32m"
					echo    "  Local Port Syntax: XXX         or !XXX"
					echo    "                     XXXX:YYYY   or !XXXX:YYYY"
					echo    "                     XXX,YYY,ZZZ or !XXX,YYY,ZZZ"
					echo    ""
					echo -ne  "\033[0m"
					echo -n "  Local Port="
					#read user input
					read input
					eval "$4=\$input"
					if [ -z $input ] ; then
						#if port entry blank --> do not continue
						#clear syntax + input
						echo -en "\033[1A\r\033[0K"  
						echo -en "\033[1A\r\033[0K"  
						echo -en "\033[1A\r\033[0K"  
						echo -en "\033[1A\r\033[0K"  
						echo -en "\033[1A\r\033[0K"  
						#if both ports are blank then reset protocol variable
						[ -z $(eval "echo \${$5}") ] && eval "$3='both'"		
					else
						#else port was defined --> ask for protocol definition
						#show additional valid syntax
						echo -ne "\033[1;32m"
						echo    ""
						echo    "  Protocol Syntax: tcp"
						echo    "                   udp"
						echo    "                   both"
						echo    ""
						echo -ne  "\033[0m"
						echo -n "  Protocol="
						#read user input
						read user input
						input=$(echo ${input}  | tr '[A-Z]' '[a-z]')
						if [ "${input}" = "udp" ] || [ "${input}" = "both" ] ; then
							eval "$3=\$input"
						else
							eval "$3='tcp'"
						fi
						#clear syntax+input
						echo -en "\033[1A\r\033[0K"  
						echo -en "\033[1A\r\033[0K"  
						echo -en "\033[1A\r\033[0K"  
						echo -en "\033[1A\r\033[0K"  
						echo -en "\033[1A\r\033[0K"  
						echo -en "\033[1A\r\033[0K"  
						echo -en "\033[1A\r\033[0K"  
						echo -en "\033[1A\r\033[0K"  
						echo -en "\033[1A\r\033[0K"  
						echo -en "\033[1A\r\033[0K"  
						echo -en "\033[1A\r\033[0K"  
					fi
						#update table entry
						echo -en "\033[8;0f\033[0K"  #move to line 8 pos 0 \ erase to end
						echo -en "\033[7;0f\033[0K"  #move to line 7 pos 0 \ erase to end
						echo -en "\033[6;0f\033[0K"  #move to line 6 pos 0 \ erase to end
						echo -n "4)  Local Port        " && [ -z $(eval "echo \${$4}") ] && echo || eval "echo \${$3} \${$4}"	#if ${4} is blank then leave field blank else populate
						echo -n "5)  Remote Port       " && [ -z $(eval "echo \${$5}") ] && echo || eval "echo \${$3} \${$5}"	#if ${5} is blank then leave field blank else populate	
						echo -n "6)  Protocol          " && eval "echo \${$3}"
					;;
				5) #remote port 
					#show valid syntax
					echo -ne "\033[1;32m"
					echo    "  Remote Port Syntax: XXX         or !XXX"
					echo    "                      XXXX:YYYY   or !XXXX:YYYY"
					echo    "                      XXX,YYY,ZZZ or !XXX,YYY,ZZZ"
					echo    ""
					echo -ne  "\033[0m"
					echo -n "  Remote Port="
					#read user input
					read input
					eval "$5=\$input"
					if [ -z $input ] ; then 
						#if port entry blank --> do not continue
						#clear syntax + input
						echo -en "\033[1A\r\033[0K"  
						echo -en "\033[1A\r\033[0K"  
						echo -en "\033[1A\r\033[0K"  
						echo -en "\033[1A\r\033[0K"  
						echo -en "\033[1A\r\033[0K" 
						#if both ports are blank then also clear protocol variable
						[ -z $(eval "echo \${$4}") ] && eval "$3='both'"
					else
						#else port was defined --> ask for protocol definition
						#show additional valid syntax
						echo -ne "\033[1;32m"
						echo    ""
						echo    "  Protocol Syntax: tcp"
						echo    "                   udp"
						echo    "                   both"
						echo    ""
						echo -ne  "\033[0m"
						echo -n "  Protocol="
						#read user input
						read input
						input=$(echo ${input}  | tr '[A-Z]' '[a-z]')
						if [ "${input}" = "udp" ] || [ "${input}" = "both" ] ; then
							eval "$3=\$input"
						else
							eval "$3='tcp'"
						fi
						#clear syntax+input
						echo -en "\033[1A\r\033[0K"  
						echo -en "\033[1A\r\033[0K"  
						echo -en "\033[1A\r\033[0K"  
						echo -en "\033[1A\r\033[0K"  
						echo -en "\033[1A\r\033[0K"
						echo -en "\033[1A\r\033[0K"
						echo -en "\033[1A\r\033[0K"  
						echo -en "\033[1A\r\033[0K"  
						echo -en "\033[1A\r\033[0K"  
						echo -en "\033[1A\r\033[0K"  
						echo -en "\033[1A\r\033[0K"  
					fi
						#update table entry
						echo -en "\033[8;0f\033[0K"  #move to line 8 pos 0 \ erase to end
						echo -en "\033[7;0f\033[0K"  #move to line 7 pos 0 \ erase to end
						echo -en "\033[6;0f\033[0K"  #move to line 6 pos 0 \ erase to end
						echo -n "4)  Local Port        " && [ -z $(eval "echo \${$4}") ] && echo || eval "echo \${$3} \${$4}"	#if ${4} is blank then leave field blank else populate
						echo -n "5)  Remote Port       " && [ -z $(eval "echo \${$5}") ] && echo || eval "echo \${$3} \${$5}"	#if ${5} is blank then leave field blank else populate	
						echo -n "6)  Protocol          " && eval "echo \${$3}"
					;;
				6) #protocol
					#show valid syntax
					echo -ne "\033[1;32m"
					echo    "  Protocol Syntax: tcp"
					echo    "                   udp"
					echo    "                   both"
					echo    ""
					echo -ne  "\033[0m"
					echo -n "  Protocol="
					#read user input
					read input 
					input=$(echo ${input}  | tr '[A-Z]' '[a-z]')
					if [ "${input}" = "udp" ] || [ "${input}" = "tcp" ] ; then
						eval "$3=\$input"
					else
						eval "$3='both'"
					fi
					#clear sytnax + input
					echo -en "\033[1A\r\033[0K"  #up one line \ beginning line \ erase to end
					echo -en "\033[1A\r\033[0K"  
					echo -en "\033[1A\r\033[0K" 
					echo -en "\033[1A\r\033[0K" 
					echo -en "\033[1A\r\033[0K" 
					#update table entry
					echo -en "\033[8;0f\033[0K"  #move to line 8 pos 0 \ erase to end
					echo -en "\033[7;0f\033[0K"  #move to line 7 pos 0 \ erase to end
					echo -en "\033[6;0f\033[0K"  #move to line 6 pos 0 \ erase to end
					echo -n "4)  Local Port        " && [ -z $(eval "echo \${$4}") ] && echo || eval "echo \${$3} \${$4}"	#if ${4} is blank then leave field blank else populate
					echo -n "5)  Remote Port       " && [ -z $(eval "echo \${$5}") ] && echo || eval "echo \${$3} \${$5}"	#if ${5} is blank then leave field blank else populate	
					echo -n "6)  Protocol          " && eval "echo \${$3}"
					;;
				7) #qos mark
					#show valid syntax
					echo -ne "\033[1;32m"
					echo    "  QoS Mark Syntax (hex): XXYYYY"
					echo    "    Note: YYYY can be **** wildcard"
					echo    ""
					echo -ne  "\033[0m"
					echo -n "  QoS Mark="
					#read user input
					read input
					input=${input//!/}
					eval "$6=\$input"
					#clear sytnax + input
					echo -en "\033[1A\r\033[0K"  #up one line \ beginning line \ erase to end
					echo -en "\033[1A\r\033[0K"  
					echo -en "\033[1A\r\033[0K"  
					echo -en "\033[1A\r\033[0K" 
					#update table entry
					echo -en "\033[9;0f\033[0K"  #move to line 9 pos 0 \ erase to end
					echo -n "7)  QoS Mark          " && eval "echo \${$6}"
					;;
				8) #packetdestination
					#show valid syntax
					echo -ne "\033[1;32m"
					echo "  Destination Syntax: 0-7"
					echo ""
				    echo "  Reference: "
				    echo "    0) Net Control"
					echo "    1) VoIP"
					echo "    2) Gaming"
					echo "    3) Others"
					echo "    4) Web Surfing"
					echo "    5) Streaming"
					echo "    6) Game Downloads"
					echo "    7) Downloads"
					echo ""
					echo -ne  "\033[0m"
					echo -n "  Destination="
					#read user input
					read input
					case $input in
						0) eval "$7='0'" ;;		#net
						1) eval "$7='3'" ;;		#voip
						2) eval "$7='1'" ;;		#game
						3) eval "$7='6'" ;;		#other
						4) eval "$7='4'" ;;		#web
						5) eval "$7='2'" ;;		#video
						6) eval "$7='7'" ;;		#game download
						7) eval "$7='5'" ;;		#downloads
						*) eval "$7='0'" ;;		#invalid input -> net
					esac
					#clear syntax + input
					echo -en "\033[1A\r\033[0K"
					echo -en "\033[1A\r\033[0K"
					echo -en "\033[1A\r\033[0K"
					echo -en "\033[1A\r\033[0K"
					echo -en "\033[1A\r\033[0K"
					echo -en "\033[1A\r\033[0K"
					echo -en "\033[1A\r\033[0K"
					echo -en "\033[1A\r\033[0K"
					echo -en "\033[1A\r\033[0K"
					echo -en "\033[1A\r\033[0K"
					echo -en "\033[1A\r\033[0K"
					echo -en "\033[1A\r\033[0K"
					echo -en "\033[1A\r\033[0K"
					#update table entry
					echo -en "\033[10;0f\033[0K"  #move to line 10 pos 0 \ erase to end
					echo -n "8)  Destination       " && eval "dst_2_name \${$7}"   #if all params empty leave blank else populate
					;;
				'r'|'R') #reset
					eval "$1=''"
					eval "$2=''"
					eval "$3=''"
					eval "$4=''"
					eval "$5=''"
					eval "$6=''"
					eval "$7=''"
					echo "$( cat "${webpath}" | sed -E 's/var rulename'"${8//[^0-9]/}"'="(.*?)";/var rulename'"${8//[^0-9]/}"'="Rule'"${8//[^0-9]/}"'";/')"  > "${webpath}"
					in_progress=0
					;;
				'e'|'E') 
				    in_progress=0 
					;;
			esac
		echo -en "\033[15;0f"	#set cursor to user prompt original position
	done
	rules #go back to rules page after modifying individual rule
}

## INTERACTIVE mode - modify gameip range
gamerule()
{
	echo -en "\033c\e[3J"
	echo -en '\033[?7l'			#disable line wrap
	echo -e  "\033[1;32mFreshJR QOS v${version} \033[0m"
	echo "Modifying Gaming Device IP Range "
	echo -ne "\033[1;32m"
	echo     ""
	echo     "  Gaming Device IP Syntax: 192.168.X.XXX "
	echo     "                           192.168.X.XXX/CIDR" 
	echo     ""
	echo -ne  "\033[0m"
	echo -ne "  Gaming Device IP="
	read input
	if [ "$( echo $input | tr -cd '.' | wc -c )" -eq "3" ] ; then
		gameCIDR=${input}
	else
		gameCIDR=''
	fi
	rules
}

## INTERACTIVE mode - modify appdb TC rule
apprule()
{
	echo -en "\033c\e[3J"
	echo -en '\033[?7l'			#disable line wrap
	echo -e  "\033[1;32mFreshJR QOS v${version} \033[0m"
	echo "Modifying ${3}"
	echo -n "1)  QoS Mark          " && eval "echo \${$1}"
	echo -n "2)  Destination       " && eval "dst_2_name \${$2}"
	echo ""
	echo "r)  Reset / Disable"
	echo "e)  Go Back"
	echo ""
	in_progress=1
	while [ ${in_progress} -eq 1 ] ; do
		echo -n "Select Parameter to Modify (Enter 1-2): "
		read input
		echo -en "\033[1A\r\033[0K" 		#clear user input prompt
		case $input in
			1) 	#QoS MARK				
				#show valid syntax
				echo -ne "\033[1;32m"
				echo    "  QoS Mark Syntax: XXYYYY"
				echo    ""
				echo -ne  "\033[0m"
				echo -n "  QoS Mark="
				#read user input
				read input
				eval "$1=\$input"
				#clear syntax + input
				echo -en "\033[1A\r\033[0K"  #up one line \ beginning line \ erase to end
				echo -en "\033[1A\r\033[0K"  
				echo -en "\033[1A\r\033[0K" 
				#update table entry
				echo -en "\033[3;0f\033[0K"  #move to line 3 pos 0 \ erase to end
				echo -n "1)  QoS Mark          " && eval "echo \${$1}"
				if [ -z $(eval "echo \${$2}") ] ; then
					echo -en "\033[9;0f"	
					#show valid syntax
					echo -ne "\033[1;32m"
					echo "  Destination Syntax: 0-7"
					echo ""
					echo "  Reference: "
					echo "    0) Net Control"
					echo "    1) VoIP"
					echo "    2) Gaming"
					echo "    3) Others"
					echo "    4) Web Surfing"
					echo "    5) Streaming"
					echo "    6) Game Downloads"
					echo "    7) Downloads"
					echo ""
					echo -ne  "\033[0m"
					echo -n "  Destination="
					#read user input
					read input
					case $input in
						0) eval "$2='0'" ;;		#net
						1) eval "$2='3'" ;;		#voip
						2) eval "$2='1'" ;;		#game
						3) eval "$2='6'" ;;		#other
						4) eval "$2='4'" ;;		#web
						5) eval "$2='2'" ;;		#video
						6) eval "$2='7'" ;;		#game download
						7) eval "$2='5'" ;;		#downloads
						*) eval "$2=''" ;;		#invalid input -> disable
					esac
					#clear syntax + input
					echo -en "\033[1A\r\033[0K"
					echo -en "\033[1A\r\033[0K"
					echo -en "\033[1A\r\033[0K"
					echo -en "\033[1A\r\033[0K"
					echo -en "\033[1A\r\033[0K"
					echo -en "\033[1A\r\033[0K"
					echo -en "\033[1A\r\033[0K"
					echo -en "\033[1A\r\033[0K"
					echo -en "\033[1A\r\033[0K"
					echo -en "\033[1A\r\033[0K"
					echo -en "\033[1A\r\033[0K"
					echo -en "\033[1A\r\033[0K"
					echo -en "\033[1A\r\033[0K"
					#update table entry 
					echo -en "\033[4;0f\033[0K"  #move to line 4 pos 0 \ erase to end
					echo -n "2)  Destination       " && eval "dst_2_name \${$2}"
				fi
				;;
			2)  #packet destination
				#show valid syntax
				echo -ne "\033[1;32m"
				echo "  Destination Syntax: 0-7"
				echo ""
				echo "  Reference: "
				echo "    0) Net Control"
				echo "    1) VoIP"
				echo "    2) Gaming"
				echo "    3) Others"
				echo "    4) Web Surfing"
				echo "    5) Streaming"
				echo "    6) Game Downloads"
				echo "    7) Downloads"
				echo ""
				echo -ne  "\033[0m"
				echo -n "  Destination="
				#read user input
				read input
				case $input in
					0) eval "$2='0'" ;;		#net
					1) eval "$2='3'" ;;		#voip
					2) eval "$2='1'" ;;		#game
					3) eval "$2='6'" ;;		#other
					4) eval "$2='4'" ;;		#web
					5) eval "$2='2'" ;;		#video
					6) eval "$2='7'" ;;		#game download
					7) eval "$2='5'" ;;		#downloads
					*) eval "$2=''" ;;		#invalid input -> disable
				esac
				#clear syntax + input
				echo -en "\033[1A\r\033[0K"
				echo -en "\033[1A\r\033[0K"
				echo -en "\033[1A\r\033[0K"
				echo -en "\033[1A\r\033[0K"
				echo -en "\033[1A\r\033[0K"
				echo -en "\033[1A\r\033[0K"
				echo -en "\033[1A\r\033[0K"
				echo -en "\033[1A\r\033[0K"
				echo -en "\033[1A\r\033[0K"
				echo -en "\033[1A\r\033[0K"
				echo -en "\033[1A\r\033[0K"
				echo -en "\033[1A\r\033[0K"
				echo -en "\033[1A\r\033[0K"
				#update table entry 
				echo -en "\033[4;0f\033[0K"  #move to line 4 pos 0 \ erase to end
				echo -n "2)  Destination       " && eval "dst_2_name \${$2}"
				;;
			'r'|'R') #reset
				eval "$1=''"
				eval "$2=''"
				#apprule $1 $2 "${3}"
				in_progress=0
				;;
			'e'|'E') 
				in_progress=0
				;;
		esac
		echo -en "\033[9;0f"	#set cursor to user prompt original position
	done
	rules #go back to rules page after modifying individual rule	
}


## helper function - parse parameters into tc syntax
parse_tcrule() {
	##requires global variables previously set by set_tc_variables
	##----------input-----------
	##$1 = mark
	##$2 = dst
	##----------output-----------	
	##byref sets $3
	##byref sets $4

	cat="$( echo ${1} | head -c2 )"
	id="$( echo ${1} | tail -c -5 )"

	#filter field
	if [ "$( echo ${1} | wc -c )" -eq "7" ] ; then
		if [ "${id}" == "****" ] ; then
			DOWN_mark="0x80${1//!/} 0xc03ff0000"
			UP_mark="0x40${1//!/} 0xc03ff0000"
		else	
			DOWN_mark="0x80${1//!/} 0xc03fffff"
			UP_mark="0x40${1//!/} 0xc03fffff"
		fi
	else
		##return early if mark is less than 6 digits
		return
	fi
	
	#destination field
	case "$2" in	
		0)	flowid=${Net};;
		1)	flowid=${Gaming};;
		2)  flowid=${Streaming};;
		3)  flowid=${VOIP};;
		4)  flowid=${Web};;
		5)  flowid=${Downloads};;
		6)  flowid=${Others};;
		7)  flowid=${Defaults};;
		##return early if destination missing
		*)  return ;;
	esac
	
	#prio field
	prio="$(tc filter show dev br0 | grep ${cat}0000 -B1 | tail -2 | cut -d " " -f7 | head -1)"
	if [ -z "${prio}" ] ; then
		prio="${undf_prio}"
	else
		prio="$(expr ${prio} - 1)"
	fi
	
	down_rule="prio $prio u32 match mark $DOWN_mark flowid $flowid"
	up_rule="prio $prio u32 match mark $UP_mark flowid $flowid"
	eval "$3=\$down_rule"	
	eval "$4=\$up_rule"
}


## helper function - parse parameters into iptable syntax
parse_iptablerule() {
	##----------input-----------
	#$1=local IP			accepted XXX.XXX.XXX.XXX or !XXX.XXX.XXX.XXX
	#$2=remote IP			accepted XXX.XXX.XXX.XXX or !XXX.XXX.XXX.XXX
	#$3=protocol  			accepted tcp or udp
	#$4=local port			accepted XXXXX or XXXXX:YYYYY or XXX,YYY,ZZZ or  !XXXXX or !XXXXX:YYYYY or !XXX,YYY,ZZZ
	#$5=remote port			accepted XXXXX or XXXXX:YYYYY or XXX,YYY,ZZZ or  !XXXXX or !XXXXX:YYYYY or !XXX,YYY,ZZZ
	#$6=mark				accepted XXYYYY   (setting YYYY to **** will filter entire "XX" parent category)
	#$7=qos destination		accepted 0-7
	##----------output-----------
	##byref sets $8
	##byref sets $9

	
	#local IP 
	if [ "$( echo ${1} | wc -c )" -gt "1" ] ; then
		DOWN_Lip="${1//[^!]*/} -d ${1//!/}"
		UP_Lip="${1//[^!]*/} -s ${1//!/}"
	else
		DOWN_Lip=""
		UP_Lip=""
	fi

	#remote IP 
	if [ "$( echo ${2} | wc -c )" -gt "1" ] ; then
		DOWN_Rip="${2//[^!]*/} -s ${2//!/}"
		UP_Rip="${2//[^!]*/} -d ${2//!/}"
	else
		DOWN_Rip=""
		UP_Rip=""
	fi

	#protocol (required for port rules)
	if [ "${3}" = 'tcp' ] || [ "${3}" = 'udp' ] ; then													#if tcp/udp
		PROTO="-p ${3}"
	else	
		if [ "$( echo ${4} | wc -c )" -gt "1" ] || [ "$( echo ${5} | wc -c )" -gt "1" ] ; then			#if both & port rules defined
			PROTO="-p both"			#"BOTH" gets replaced with tcp & udp during later prior to rule execution
		else																							#if both & port rules not defined
			PROTO=""
		fi
	fi


	#local port
	if [ "$( echo ${4} | wc -c )" -gt "1" ] ; then
		if [ "$( echo ${4} | tr -cd ',' | wc -c )" -ge "1" ] ; then
			#multiport XXX,YYY,ZZZ
			DOWN_Lport="-m multiport ${4//[^!]*/} --dports ${4//!/}"
			UP_Lport="-m multiport ${4//[^!]*/} --sports ${4//!/}"
		else
			#single port XXX or port range XXX:YYY
			DOWN_Lport="${4//[^!]*/} --dport ${4//!/}"
			UP_Lport="${4//[^!]*/} --sport ${4//!/}"	
		fi
	else
		DOWN_Lport=""
		UP_Lport=""
	fi


	#remote port
	if [ "$( echo ${5} | wc -c )" -gt "1" ] ; then
		if [ "$( echo ${5} | tr -cd ',' | wc -c )" -ge "1" ] ; then
			#multiport XXX,YYY,ZZZ
			DOWN_Rport="-m multiport ${5//[^!]*/} --sports ${5//!/}"
			UP_Rport="-m multiport ${5//[^!]*/} --dports ${5//!/}"
		else
			#single port XXX or port range XXX:YYY
			DOWN_Rport="${5//[^!]*/} --sport ${5//!/}"	
			UP_Rport="${5//[^!]*/} --dport ${5//!/}"
		fi
	else
		DOWN_Rport=""
		UP_Rport=""
	fi
	
	#match mark
	if [ "$( echo ${6} | wc -c )" -eq "7" ] ; then
		if [ "$( echo ${6} | tail -c -5 )" == "****" ] ; then
			DOWN_mark="-m mark --mark 0x80${6//!/}/0xc03f0000"
			UP_mark="-m mark --mark 0x40${6//!/}/0xc03f0000"
		else	
			DOWN_mark="-m mark --mark 0x80${6//!/}/0xc03fffff"
			UP_mark="-m mark --mark 0x40${6//!/}/0xc03fffff"
		fi
	else
		DOWN_mark=""
		UP_mark=""
	fi

	##if parameters are empty return early
	if [ -z "${DOWN_Lip}${DOWN_Rip}${DOWN_Lport}${DOWN_Rport}${DOWN_mark}" ] ; then
		return 
	fi

	#destination mark
	case "$7" in	
		0)	
			DOWN_dst="-j MARK --set-mark ${Net_mark_down}"
			UP_dst="-j MARK --set-mark ${Net_mark_up}"
			;;
		1)
			DOWN_dst="-j MARK --set-mark ${Gaming_mark_down}"
			UP_dst="-j MARK --set-mark ${Gaming_mark_up}"
			;;
		2)
			DOWN_dst="-j MARK --set-mark ${Streaming_mark_down}"
			UP_dst="-j MARK --set-mark ${Streaming_mark_up}"	
			;;
		3)
			DOWN_dst="-j MARK --set-mark ${VOIP_mark_down}"
			UP_dst="-j MARK --set-mark ${VOIP_mark_up}"
			;;
		4)
			DOWN_dst="-j MARK --set-mark ${Web_mark_down}"
			UP_dst="-j MARK --set-mark ${Web_mark_up}"
			;;
		5)
			DOWN_dst="-j MARK --set-mark ${Downloads_mark_down}"
			UP_dst="-j MARK --set-mark ${Downloads_mark_up}"
			;;
		6)
			DOWN_dst="-j MARK --set-mark ${Others_mark_down}"
			UP_dst="-j MARK --set-mark ${Others_mark_up}"
			;;
		7)
			DOWN_dst="-j MARK --set-mark ${Default_mark_down}"
			UP_dst="-j MARK --set-mark ${Default_mark_up}"
			;;
		*)
			##if destinations is empty return early
			return
			;;
	esac

	down_rule="$(echo "${DOWN_Lip} ${DOWN_Rip} ${PROTO} ${DOWN_Lport} ${DOWN_Rport} ${DOWN_mark} ${DOWN_dst}" | sed 's/  */ /g')"
	up_rule="$(echo "${UP_Lip} ${UP_Rip} ${PROTO} ${UP_Lport} ${UP_Rport} ${UP_mark} ${UP_dst}" | sed 's/  */ /g')"
	eval "$8=\$down_rule"	
	eval "$9=\$up_rule"
}

about(){
	echo -en "\033c\e[3J"		#clear screen
	echo -en '\033[?7l'			#disable line wrap
	printf '\e[8;41;160t'		#set height/width of terminal
	echo "FreshJR_QOS v${version} released ${release}"
	echo ""
	echo 'License'
	echo '  FreshJR_QOS is free to use under the GNU General Public License, version 3 (GPL-3.0).'
	echo '  https://opensource.org/licenses/GPL-3.0'
	echo ""
	echo 'For discussion visit this thread:'
	echo '  https://www.snbforums.com/threads/release-freshjr-adaptive-qos-improvements-custom-rules-and-inner-workings.36836/'
	echo "  https://github.com/FreshJR07/FreshJR_QOS (Source Code)"
	echo ""
	echo -e  "\033[1;32mFreshJR QOS v${version} \033[0m"
	echo "About"
	echo '  Script Changes Unidentified traffic destination away from "Defaults" into "Others"'
	echo '  Script Changes HTTPS traffic destination away from "Net Control" into "Web Surfing" '
	echo '  Script Changes Guaranteed Bandwidth per QOS category into logical percentages of upload and download.'
	echo ""
	echo '  Script Repurposes "Defaults" to contain "Game Downloads" '
	echo '    "Game Downloads" container moved into 6th position'
	echo '    "Lowest Defined" container moved into 7th position'
	echo ""
	echo '  Script includes misc hardcoded rules '
	echo '   (Wifi Calling)  -  UDP traffic on remote ports 500 & 4500 moved into VOIP'
	echo '   (Facetime)      -  UDP traffic on local  ports 16384 - 16415 moved into VOIP '
	echo '   (Usenet)        -  TCP traffic on remote ports 119 & 563 moved into Downloads '
	echo '   (Gaming)        -  Gaming TCP traffic from remote ports 80 & 443 moved into Game Downloads.'
	echo '   (Snapchat)      -  Moved into Others'
	echo '   (Speedtest.net) -  Moved into Downloads'
	echo '   (Google Play)   -  Moved into Downloads'
	echo '   (Apple AppStore)-  Moved into Downloads'
	echo '   (Advertisement) -  Moved into Downloads'
	echo '   (VPN Fix)       -  Router VPN Client upload traffic moved into Downloads instead of whitelisted'
	echo '   (VPN Fix)       -  Router VPN Client download traffic moved into Downloads instead of showing up in Uploads'
	echo '   (Gaming Manual) -  Unidentified traffic for specified devices, not originating from ports 80/443, moved into "Gaming"'
	echo ""
	echo 'Gaming Rule Note'
	echo '  Gaming traffic originating from ports 80 & 443 is primarily downloads & patches (some lobby/login protocols mixed within)'
	echo '  Manually configurable rule will take untracked traffic for specified devices, not originating from server ports 80/443, and place it into Gaming'
	echo '  Use of this gaming rule REQUIRES devices to have a continous static ip assignment && this range needs to be passed into the script'
	echo ""
	echo "How to Use Advanced Functionality"
	echo '  Interactive terminal mode can be accessed by running the -menu command:'
	echo '      (interactive mode) :  /jffs/scripts/FreshJR_QOS -menu'
	echo '  Custom rules can be created via the WebUI OR directly accessed by running the -rules command:'
	echo '      (custom rules)     :  /jffs/scripts/FreshJR_QOS -rules'
	echo '  Bandwidth allocation per category can be adjusted via the WebUI OR directly accessed by running the -rates command:'
	echo '      (custom rates)     :  /jffs/scripts/FreshJR_QOS -rates'
	echo ""
	echo 'Development'
	echo '  Tested with ASUS AC-68U, FW384.9, using Adaptive QOS with Manual Bandwidth Settings'
	echo '  Copyright (C) 2017-2019 FreshJR - All Rights Reserved '
	echo -en '\033[?7h'			#enable line wrap
}

update(){
	
	echo -en "\033c\e[3J"		#clear screen
	echo -en '\033[?7l'			#disable line wrap
	printf '\e[8;30;120t'		#set height/width of terminal
	echo -e  "\033[1;32mFreshJR QOS v${version} \033[0m"
	echo "Checking for updates"
	echo ""
	url="https://raw.githubusercontent.com/FreshJR07/FreshJR_QOS/master/FreshJR_QOS.sh"
	remotever=$(curl -fsN --retry 3 ${url} | grep "^version=" | sed -e s/version=//)

	if [ "$version" != "$remotever" ]; then
		echo " FreshJR QOS v${remotever} is now available!"
		echo ""
		echo -n " Would you like to update now? [1=Yes 2=No] : "
		read yn
		echo ""
		if ! [ "${yn}" == "1" ] ; then
			echo -e "\033[1;31;7m  No Changes have been made \033[0m"
			echo ""
			return 0
		fi
	else
		echo    " You have the latest version installed"
		echo -n " Would you like to overwrite your existing installation anyway? [1=Yes 2=No] : "
		read yn
		echo ""
		if ! [ "${yn}" == "1"  ] ; then
			echo -e "\033[1;31;7m  No Changes have been made \033[0m"
			echo ""
			return 0
		fi
	fi

	echo -e "Installing: FreshJR_QOS_v${remotever}"
	echo ""
	echo "Curl Output:"
	curl "https://raw.githubusercontent.com/FreshJR07/FreshJR_QOS/master/FreshJR_QOS.sh" -o /jffs/scripts/FreshJR_QOS --create-dirs && curl "https://raw.githubusercontent.com/FreshJR07/FreshJR_QOS/master/FreshJR_QoS_Stats.asp" -o "${webpath}" && sh /jffs/scripts/FreshJR_QOS -install
	exit
}

prompt_restart(){
	echo ""
	echo -en " Would you like to \033[1;32m[Restart QoS]\033[0m for modifications to take effect? [1=Yes 2=No] : "
	read yn
	if [ "${yn}" == "1" ] ; then
		if grep -q -x '/jffs/scripts/FreshJR_QOS -start $1 & ' /jffs/scripts/firewall-start ; then			#RMerlin install
			service "restart_qos;restart_firewall"
		else																								#Stock Install
			service "restart_qos;restart_firewall"
			cru a FreshJR_QOS_run_once "* * * * * /jffs/scripts/FreshJR_QOS -mount &"							#cron task so keeps running after terminal is closed
		fi	
		echo ""		
	else	
		echo ""
		if grep -q -x '/jffs/scripts/FreshJR_QOS -start $1 & ' /jffs/scripts/firewall-start ; then			#RMerlin install
			echo -e  "\033[1;31;7m  Remember: [ Restart QOS ] for modifications to take effect \033[0m"
			echo ""
		else																								#Stock install
			echo -e  "\033[1;31;7m  Remember: [ Restart Router ] for modifications to take effect \033[0m"
			echo ""
		fi
	fi
}

menu(){
    read_nvram
	echo -en "\033c\e[3J"		#clear screen
	echo -en '\033[?7l'			#disable line wrap
	printf '\e[8;30;120t'		#set height/width of terminal
	echo -e  "\033[1;32mFreshJR QOS v${version} released ${release} \033[0m"
	echo "  (1) about               explain functionality"
	echo "  (2) update              check for updates "
	echo ""
	echo "  (3) QoS rules           QoS rules (user defined)"
	echo "  (4) QoS rates           QoS rates (bandwidth allocation per category)"
	echo ""
	echo "  (5) debug               traffic control parameters"
	echo "  (6) debug2              parsed nvram parameters"
	echo ""
	echo "  (u) uninstall           uninstall script"
	echo ""
	echo "  (e) exit"
	echo ""	
	echo "  Current Setup:"
	echo "           Local IP            Remote IP           Proto  Local Port     Remote Port    Mark        Dst"
  printf '  Rule     %-19s %-19s %-6s %-14s %-14s %-7s %-10s\n' "$e1" "$e2" "$e3" "$e4" "$e5" "$e6" "$([ -z $e7 ] || echo "--> $(dst_2_name $e7)")"
  printf '  Rule     %-19s %-19s %-6s %-14s %-14s %-7s %-10s\n' "$f1" "$f2" "$f3" "$f4" "$f5" "$f6" "$([ -z $f7 ] || echo "--> $(dst_2_name $f7)")"
  printf '  Rule     %-19s %-19s %-6s %-14s %-14s %-7s %-10s\n' "$g1" "$g2" "$g3" "$g4" "$g5" "$g6" "$([ -z $g7 ] || echo "--> $(dst_2_name $g7)")"
  printf '  Rule     %-19s %-19s %-6s %-14s %-14s %-7s %-10s\n' "$h1" "$h2" "$h3" "$h4" "$h5" "$h6" "$([ -z $h7 ] || echo "--> $(dst_2_name $h7)")"
  printf '  Gameip   %-19s %-19s %-6s %-14s %-14s %-7s %-10s\n'  "${gameCIDR}" "" "$([ -z $gameCIDR ] || echo "both")" "" "$([ -z $gameCIDR ] || echo "!80:443")" "$([ -z $gameCIDR ] || echo "000000")" "--> Gaming"
  printf '  Appdb    %-44s                                 %-7s %-10s\n' "$(mark_2_name $r1)" "$r1" "$([ -z $d1 ] || echo "--> $(dst_2_name $d1)")"
  printf '  Appdb    %-44s                                 %-7s %-10s\n' "$(mark_2_name $r2)" "$r2" "$([ -z $d2 ] || echo "--> $(dst_2_name $d2)")"
  printf '  Appdb    %-44s                                 %-7s %-10s\n' "$(mark_2_name $r3)" "$r3" "$([ -z $d3 ] || echo "--> $(dst_2_name $d3)")"
  printf '  Appdb    %-44s                                 %-7s %-10s\n' "$(mark_2_name $r4)" "$r4" "$([ -z $d4 ] || echo "--> $(dst_2_name $d4)")"
	echo ""
	echo -en '\033[?7h'			#enable line wrap
	echo -n "Make a selection: "
	read input
	case $input in
			'1')  
				about
				read -n 1 -s -r -p "(Press any key to return)"
				echo -en "\033c"		#clear screen
				;;
			'2')  
			    update
				read -n 1 -s -r -p "(Press any key to return)"
				echo -en "\033c"		#clear screen
				;;
			'3')
				rules
				read -n 1 -s -r -p "(Press any key to return)"
				echo -en "\033c"		#clear screen
				;;
			'4')
				rates
				read -n 1 -s -r -p "(Press any key to return)"
				echo -en "\033c"		#clear screen
				;;
			'5')  
				debug
				echo ""
				read -n 1 -s -r -p "(Press any key to return)"
				echo -en "\033c"		#clear screen
				;;
			'6')  
				debug2
				echo ""
				read -n 1 -s -r -p "(Press any key to return)"
				echo -en "\033c"		#clear screen
				;;
			'u'|'U') 
				clear
				echo -e  "\033[1;32mFreshJR QOS v${version} released ${release} \033[0m"
				echo ""
				echo -en " Confirm you want to \033[1;32m[uninstall]\033[0m FreshJR_QOS [1=Yes 2=No] : "
				read yn
				if [ "${yn}" == "1" ] ; then
					echo ""
					sh /jffs/scripts/FreshJR_QOS -uninstall
					echo ""
					exit
				fi
				echo ""
				echo -e "\033[1;31;7m  FreshJR QOS has NOT been uninstalled \033[0m"
				echo ""
				read -n 1 -s -r -p "(Press any key to return)"
				echo -en "\033c"		#clear screen
				;;
			'e'|'E')
				echo -en "\033[1A\r\033[0K"  
				return
				;;

	esac
	menu
}

##alternative install for (non-RMerlin) firmware
stock_install(){
	if [ "$(nvram get script_usbmount)" != "/jffs/scripts/script_usbmount" ] ; then
		echo ""
		echo -e  "\033[1;32m Creating environment to trigger scripts post USB Mount \033[0m"
		nvram set script_usbmount="/jffs/scripts/script_usbmount"
		nvram commit
	fi
	
	 if [ -f /jffs/scripts/script_usbmount ] ; then									   #check if script_usbmount exists
	   if grep -q "#!/bin/sh" /jffs/scripts/script_usbmount ; then							#check if script_usbmount header is correct
			:																				  #if header is correct, do nothing
	   else																					  #if header is incorrect, fix header
			echo " Detected improper header in script_usbmount, fixing header"
			sed -i "1i #!/bin/sh" /jffs/scripts/script_usbmount
			chmod 0755 /jffs/scripts/script_usbmount
	   fi
		
		sed -i '/FreshJR_QOS/d' /jffs/scripts/script_usbmount
		echo '/jffs/scripts/FreshJR_QOS mount &' >> /jffs/scripts/script_usbmount
			
	else																			   #if script_usbmount did not exist then set it up entirely
	   echo " Creating script_usbmount in /jffs/scripts/"
	   echo " Placing FreshJR_QOS into script_usbmount"
	   echo "#!/bin/sh" > /jffs/scripts/script_usbmount
	   echo '/jffs/scripts/FreshJR_QOS mount &' >> /jffs/scripts/script_usbmount
	   chmod 0755 /jffs/scripts/script_usbmount
	fi
	
	echo -e  "\033[1;32mFreshJR QOS v${version} has been installed \033[0m"
	echo -e  "\033[1;32m   make sure a USB storage device is plugged in and \033[0m"
	echo -e "\033[1;31;7m   [ reboot router ] to finalize installation\033[0m"
	echo ""
}

#Main program here, will execute different things depending on arguments
arg1="$(echo "$1" | tr -d "-")"
case "$arg1" in	
 'start'|'check'|'mount')																	##RAN ON FIREWALL-START OR CRON TASK, (RAN ONLY POST USB MOUNT IF USING STOCK ASUS FIRMWARE)
	cru a FreshJR_QOS "30 3 * * * /jffs/scripts/FreshJR_QOS -check"			#makes sure daily check if active
	cru d FreshJR_QOS_run_once												#(used for stock firmware to trigger script and have it run after terminal is closed when making changes)

	if [ "$(nvram get qos_enable)" == "1" ] ; then
		for pid in $(pidof FreshJR_QOS); do
			if [ $pid != $$ ]; then
				if ! [ "$(ps -w | grep "${pid}.*\(install\|menu\|rules\|rates\)" | grep -v "grep")" ] ; then		#kill all previous instances of FreshJR_QOS (-install, -menu, -rules, -rates instances are whitelisted)
					kill $pid
					logger -t "adaptive QOS" -s "Delayed Start Canceled"
				fi
			fi 
		done

		##check if should mount QoS_stats page
		if [ "$(uname -o)" == "ASUSWRT-Merlin" ] ; then			
			buildno="$(nvram get buildno)";										#Example "User12 v17.2 Beta4"
			if [ "$(echo ${buildno} | tr -cd '.' | wc -c)" -ne 0 ]	; then					#if has decimal	
				CV="$(echo ${buildno} | cut -d "." -f 1 | grep -o '[0-9]\+' | tail -1)"		#get first number before decimal --> 17
				MV="$(echo ${buildno} | cut -d "." -f 2 | grep -o '[0-9]\+' | head -1)"		#get first number after decimal  --> 2
			else																
				CV="$(echo ${buildno} | grep -o '[0-9]\+' | head -1)"						#get first number --> 17
				MV="0"
			fi
			
			if [ "${CV}" -ge "382" ] ; then
				if ! [ "${webpath}" -ef "/www/QoS_Stats.asp" ] ; then
					mount -o bind "${webpath}" /www/QoS_Stats.asp
				fi
			#elif [ "${CV}" = "384" ] && [ ${MV} -ge "9" ] ; then
			fi
		fi

		read_nvram	#needs to be set before parse_iptablerule or custom rates 

		if [ "$arg1" == "start" ] ; then
			##iptables rules will only be reapplied on firewall "start" due to receiving interface name
			wan="${2}"
				if [ -z "$wan" ] ; then
					wan="eth0"
				fi
				
			parse_iptablerule "${e1}" "${e2}" "${e3}" "${e4}" "${e5}" "${e6}" "${e7}" ip1_down ip1_up		##last two arguments are variables that get set "ByRef"
			parse_iptablerule "${f1}" "${f2}" "${f3}" "${f4}" "${f5}" "${f6}" "${f7}" ip2_down ip2_up
			parse_iptablerule "${g1}" "${g2}" "${g3}" "${g4}" "${g5}" "${g6}" "${g7}" ip3_down ip3_up
			parse_iptablerule "${h1}" "${h2}" "${h3}" "${h4}" "${h5}" "${h6}" "${h7}" ip4_down ip4_up
			
			iptable_down_rules 2>&1 | logger -t "adaptive QOS"
			iptable_up_rules 2>&1 | logger -t "adaptive QOS"
			
			logger -t "adaptive QOS" -s -- "TC Modification Delayed Start (5min)"
			sleep 300s
		fi


		if [ "$arg1" == "mount" ] ; then			
			logger -t "adaptive QOS" -s -- "--Post USB Mount-- Delayed Start (10min)"
			sleep 600s

		fi
		
		current_undf_rule="$(tc filter show dev br0 | grep -v "/" | grep "000ffff" -B1)"
		undf_flowid=$(echo $current_undf_rule | grep -o "flowid.*" | cut -d" " -f2 | head -1)
		undf_prio=$(echo $current_undf_rule | grep -o "pref.*" | cut -d" " -f2 | head -1)
		#if TC modifcations have no been applied then run modification script
		#eg (if rule setting unidentified traffic to 1:17 exists) --> run modification script
		if [ "${undf_flowid}" == "1:17" ] ; then
			if [ "$arg1" == "check" ] ; then
				logger -t "adaptive QOS" -s "Scheduled Persistence Check -> Reapplying Changes"
			fi
			
			#this section is only used stock ASUS firmware.  It will will evaluate on (-mount && -check) parameters only on STOCK firmware
			if [ "$(nvram get script_usbmount)" == "/jffs/scripts/script_usbmount" ] && [ "$arg1" != "start" ] ; then		
				wan="$(iptables -vL -t mangle | grep -m 1 "BWDPI_FILTER" | tr -s ' ' | cut -d ' ' -f 7)"		#try to detect upload interface automatically
				if [ -z "$wan" ] ; then
					wan="eth0"
				fi
				parse_iptablerule "${e1}" "${e2}" "${e3}" "${e4}" "${e5}" "${e6}" "${e7}" ip1_down ip1_up		##last two arguments are variables that get set "ByRef"
				parse_iptablerule "${f1}" "${f2}" "${f3}" "${f4}" "${f5}" "${f6}" "${f7}" ip2_down ip2_up
				parse_iptablerule "${g1}" "${g2}" "${g3}" "${g4}" "${g5}" "${g6}" "${g7}" ip3_down ip3_up
				parse_iptablerule "${h1}" "${h2}" "${h3}" "${h4}" "${h5}" "${h6}" "${h7}" ip4_down ip4_up
				
				iptable_down_rules 2>&1 | logger -t "adaptive QOS"
				iptable_up_rules 2>&1 | logger -t "adaptive QOS"
			fi
			
			set_tc_variables 	#needs to be set before parse_tcrule
			##last two arguments are variables that get set "ByRef"
			parse_tcrule "${r1}" "${d1}" tc1_down tc1_up
			parse_tcrule "${r2}" "${d2}" tc2_down tc2_up
			parse_tcrule "${r3}" "${d3}" tc3_down tc3_up
			parse_tcrule "${r4}" "${d4}" tc4_down tc4_up
			tc_redirection_down_rules "$undf_prio"  2>&1 | logger -t "adaptive QOS"		#forwards terminal output & errors to logger
			tc_redirection_up_rules "$undf_prio"  2>&1 | logger -t "adaptive QOS"		#forwards terminal output & errors to logger
			
			if [ "$ClassesPresent" -lt "8" ] ; then
				logger -t "adaptive QOS" -s "Adaptive QOS not fully done setting up prior to modification script"
				logger -t "adaptive QOS" -s "(Skipping class modification, delay trigger time period needs increase)"
			else
				if [ "$DownCeil" -gt "500" ] && [ "$UpCeil" -gt "500" ] ; then
					custom_rates 2>&1 | logger -t "adaptive QOS"		#forwards terminal output & errors to logger
				fi
			fi
			
		else
			if [ "$arg1" == "check" ] ; then
				logger -t "adaptive QOS" -s "Scheduled Persistence Check -> No modifications necessary"
			else
				logger -t "adaptive QOS" -s "No modifications necessary"
			fi
		fi
	fi
	;;	
 'install'|'enable')															## INSTALLS AND TURNS ON SCRIPT
	printf '\e[8;30;120t'		#set height/width of terminal
	clear
 	chmod 0755 /jffs/scripts/FreshJR_QOS
	if grep -qs "FreshJR_QOS" /jffs/scripts/init-start ; then
		sed -i '/FreshJR_QOS/d' /jffs/scripts/init-start 2>/dev/null									
	fi
	if [ "/jffs/scripts/FreshJR_QOS_fakeTC" -ef "/bin/tc" ] || [ "/jffs/scripts/FreshJR_QOS_fakeTC" -ef "/usr/sbin/tc" ] ; then		##uninstall previous version FreshJR_QOS_fakeTC if not already uninstalled
		
		echo "Old version of FreshJR_QOS_fast(fakeTC) has been Detected"
		
		if [ -e "/bin/tc" ] ; then	
			umount /bin/tc &> /dev/null 			#suppresses error if present
			mount -o bind /usr/sbin/faketc /bin/tc										
		elif [ -e "/usr/sbin/tc" ] ; then	
			umount /usr/sbin/tc &> /dev/null 		#suppresses error if present
			mount -o bind /usr/sbin/faketc /usr/sbin/tc												
		fi
		
		rm -f /jffs/scripts/FreshJR_QOS_fakeTC
		nvram unset qos_downrates
		nvram unset qos_uprates
		nvram commit
		
		if [ "/usr/sbin/faketc" -ef "/usr/sbin/tc" ] || [ "/usr/sbin/faketc" -ef "/bin/tc" ] ; then
			echo "Old version of FreshJR_QOS_fast(fakeTC) has been Successfully Uninstalled"
		else
			echo "FreshJR_QOS_fast(fakeTC) Uninstall Process has been Initiated "
			echo  -e "\033[1;31;7m Please [ reboot router ] to finish the uninstall process \033[0m"
			echo  -e "\033[1;31;7m Rerun this install procedure after system reboot \033[0m"
			exit 0
		fi	
	fi	

	if [ "$(uname -o)" != "ASUSWRT-Merlin" ] ; then																				##GIVE USER CHOICE TO RUN STOCK INSTALL IF Non-RMerlin FIRMWARE detected
		echo -e "\033[1;31m Non-RMerlin Firmware Detected \033[0m"
		echo -e -n "\033[1;31m Is this installation for (Stock / Default / Unmodified) Asus firmware?  [1=Yes 2=No] : \033[0m"   # Display prompt in red
		read yn
		echo ""
		case $yn in
			'1') 
				sed -i '/FreshJR_QOS/d' /jffs/scripts/firewall-start 2>/dev/null
				stock_install; 
				exit 0
				;;
			'2') 
				sed -i '/FreshJR_QOS/d' /jffs/scripts/script_usbmount 2>/dev/null 
				echo -e "\033[1;32m Installing RMerlin version of the script \033[0m"   # Display prompt in red
				echo ""
				break
				;;
			*) 
				echo "Invalid Option"
				echo "ABORTING INSTALLATION "
				exit 0
				;;
		esac
	fi
	
	if [ -f /jffs/scripts/firewall-start ] ; then									   #check if firewall-start exists
	   if grep -q "#!/bin/sh" /jffs/scripts/firewall-start ; then							#check if firewall-start header is correct
			:																				  #if header is correct, do nothing
	   else																					  #if header is incorrect, fix header
			echo "Detected improper header in firewall-start, fixing header"
			sed -i "1i #!/bin/sh" /jffs/scripts/firewall-start
			chmod 0755 /jffs/scripts/firewall-start
	   fi
	
	   if grep -q -x '/jffs/scripts/FreshJR_QOS -start $1 & ' /jffs/scripts/firewall-start ; then	  #check if FreshJR_QOS is present as item in firewall start
			:																									#if FreshJR_QOS is present do nothing
		else																									#if not, appened it to the last line (also delete any previously formated entry)
			echo "Placing FreshJR_QOS entry into firewall-start"
			sed -i '/FreshJR_QOS/d' /jffs/scripts/firewall-start
			echo '/jffs/scripts/FreshJR_QOS -start $1 & ' >> /jffs/scripts/firewall-start
	   fi																									
	else																			   #if firewall-start does not exist then set it up entirely
	   echo "Firewall-start not detected, creating firewall-start"
	   echo "Placing FreshJR_QOS entry into firewall-start"
	   echo "#!/bin/sh" > /jffs/scripts/firewall-start
	   echo '/jffs/scripts/FreshJR_QOS -start $1 & ' >> /jffs/scripts/firewall-start
	   chmod 0755 /jffs/scripts/firewall-start
	fi
	cru a FreshJR_QOS "30 3 * * * /jffs/scripts/FreshJR_QOS -check"
	
	if [ "$(uname -o)" == "ASUSWRT-Merlin" ] ; then				  #Mounts webpage on RMerlin v382+	
		buildno="$(nvram get buildno)";										#Example "User12 v17.2 Beta4"
		if [ "$(echo ${buildno} | tr -cd '.' | wc -c)" -ne 0 ]	; then					#if has decimal	
			CV="$(echo ${buildno} | cut -d "." -f 1 | grep -o '[0-9]\+' | tail -1)"		#get first number before decimal --> 17
			MV="$(echo ${buildno} | cut -d "." -f 2 | grep -o '[0-9]\+' | head -1)"		#get first number after decimal  --> 2
		else																
			CV="$(echo ${buildno} | grep -o '[0-9]\+' | head -1)"						#get first number --> 17
			MV="0"
		fi
		
		if [ "${CV}" -ge "382" ] ; then
			if ! [ "${webpath}" -ef "/www/QoS_Stats.asp" ] ; then
				mount -o bind "${webpath}" /www/QoS_Stats.asp
			fi
		#elif [ "${CV}" = "384" ] && [ ${MV} -ge "9" ] ; then
		fi
	fi
	
	#shortcut to launching FreshJR_QOS  (/usr/bin was readonly)
	alias freshjr="sh /jffs/scripts/FreshJR_QOS -menu"		
	alias freshjrqos="sh /jffs/scripts/FreshJR_QOS -menu"
	alias freshjr_qos="sh /jffs/scripts/FreshJR_QOS -menu"	
	alias FreshJR_QOS="sh /jffs/scripts/FreshJR_QOS -menu"
	sed -i '/fresh/d' /jffs/configs/profile.add 2>/dev/null			
	echo 'alias freshjr="sh /jffs/scripts/FreshJR_QOS -menu"' >> /jffs/configs/profile.add
	echo 'alias freshjrqos="sh /jffs/scripts/FreshJR_QOS -menu"' >> /jffs/configs/profile.add
	echo 'alias freshjr_qos="sh /jffs/scripts/FreshJR_QOS -menu"' >> /jffs/configs/profile.add
	echo 'alias FreshJR_QOS="sh /jffs/scripts/FreshJR_QOS -menu"' >> /jffs/configs/profile.add

	
	echo -e  "\033[1;32mFreshJR QOS v${version} has been installed \033[0m"
	echo ""
	echo -n " Advanced configuration available via: "
	if [ "$(uname -o)" == "ASUSWRT-Merlin" ] ; then
		if [ -e "/jffs/scripts/amtm" ] ; then
			echo -e  "\033[1;32m[ WebUI ]\033[0m or \033[1;32m[ /jffs/scripts/FreshJR_QOS -menu ]\033[0m or \033[1;32m[ amtm ]\033[0m "
		else
			echo -e  "\033[1;32m[ WebUI ]\033[0m or \033[1;32m[ /jffs/scripts/FreshJR_QOS -menu ]\033[0m "
		fi
	else
		echo -e  "\033[1;32m[ /jffs/scripts/FreshJR_QOS -menu ]\033[0m "
	fi
	
	[ "$(nvram get qos_enable)" == "1" ] && prompt_restart
	;;
 'uninstall')																		## UNINSTALLS SCRIPT AND DELETES FILES
	sed -i '/FreshJR_QOS/d' /jffs/scripts/firewall-start 2>/dev/null						#remove FreshJR_QOS from firewall start
	sed -i '/FreshJR_QOS/d' /jffs/scripts/script_usbmount 2>/dev/null						#remove FreshJR_QOS from script_usbmount - only used on stock ASUS firmware installs
	sed -i '/freshjr/d' /jffs/configs/profile.add 2>/dev/null								#remove aliases used to launch interactive mode
	sed -i '/FreshJR/d' /jffs/configs/profile.add 2>/dev/null
	cru d FreshJR_QOS
	rm -f /jffs/scripts/FreshJR_QOS
	
	umount /www/QoS_Stats.asp &> /dev/null 			#suppresses error if present
	mount -o bind /www/QoS_Stats.asp /www/QoS_Stats.asp	
	umount /www/QoS_Stats.asp &> /dev/null 
	rm -f "${webpath}"
	
	if [ "$(nvram get script_usbmount)" == "/jffs/scripts/script_usbmount" ] ; then												   #only used on stock ASUS firmware installs
		nvram unset script_usbmount
	fi
	nvram set fb_comment=""
	nvram set fb_email_dbg=""
	nvram commit	
	echo -e  "\033[1;32m FreshJR QOS has been uninstalled \033[0m"
	;;
 'disable')																		## TURNS OFF SCRIPT BUT KEEP FILES
	sed -i '/FreshJR_QOS/d' /jffs/scripts/firewall-start  2>/dev/null
	sed -i '/FreshJR_QOS/d' /jffs/scripts/script_usbmount 2>/dev/null
	cru d FreshJR_QOS
	umount /www/QoS_Stats.asp &> /dev/null 			#suppresses error if present
	mount -o bind /www/QoS_Stats.asp /www/QoS_Stats.asp	
	umount /www/QoS_Stats.asp &> /dev/null 
	;;
 'debug')
	debug
	;;	
 'debug2')
	debug2
	;;	
 'debug3')
    debug3
	;;
 'appdb')
	appdb "$2"
	;;
  'gameip')
    read_nvram
	gameip "$2"
	;;
  'rules')
    read_nvram
    rules
	;;
  'rates')
    read_nvram
    rates
	;;
  'about')
    about
	;;
  'update')
    update
	;;
  'menu')
	menu
	;;
  'isinstalled')
		if grep -q -x '/jffs/scripts/FreshJR_QOS -start $1 & ' /jffs/scripts/firewall-start ; then
			exit 0		#script IS installed
		else
			exit 1		#script in NOT installed
		fi
    ;;
  'isuptodate')
		url="https://raw.githubusercontent.com/FreshJR07/FreshJR_QOS/master/FreshJR_QOS.sh"
		remotever=$(curl -fsN --retry 3 ${url} | grep "^version=" | sed -e s/version=//)
		if [ "$version" == "$remotever" ]; then
			exit 0 		#script IS current 
		else
			exit 1		#script is NOT up to date
		fi
		
    ;;
 *)
    read_nvram
	echo -en "\033c\e[3J"		#clear screen
	echo -en '\033[?7l'			#disable line wrap
	# printf '\e[8;30;120t'		#set height/width of terminal
	echo -e  "\033[1;32mFreshJR QOS v${version} \033[0m"
	echo -e  "\033[1;32mreleased ${release} \033[0m"
	echo ""
	echo "You have inputted an UNRECOGNIZED COMMAND"
	echo ""
    echo "  Available commands:"
	echo ""
	echo "  FreshJR_QOS -about              explains functionality"
	echo "  FreshJR_QOS -update             checks for updates "
	echo ""
	echo "  FreshJR_QOS -install            install   script"
	echo "  FreshJR_QOS -uninstall          uninstall script && delete from disk "
	echo ""
	echo "  FreshJR_QOS -enable             enable    script "
	echo "  FreshJR_QOS -disable            disable   script but do not delete from disk"
	echo ""
	echo "  FreshJR_QOS -debug              print traffic control parameters"
	echo "  FreshJR_QOS -debug2             print parsed nvram parameters"
	echo ""
	echo '  FreshJR_QOS -appdb "App Name"   looks up mark for specifed application'
	echo ""
	echo "  FreshJR_QOS -rules              create/modify custom rules"
	echo "  FreshJR_QOS -rates              modify bandwidth allocations"
	echo ""
	echo '  FreshJR_QOS -menu               interactive main menu'
	echo ""	
	echo "  Current Setup:"
	echo "           Local IP            Remote IP           Proto  Local Port     Remote Port    Mark        Dst"
  printf '  Rule     %-19s %-19s %-6s %-14s %-14s %-7s %-10s\n' "$e1" "$e2" "$e3" "$e4" "$e5" "$e6" "$([ -z $e7 ] || echo "--> $(dst_2_name $e7)")"
  printf '  Rule     %-19s %-19s %-6s %-14s %-14s %-7s %-10s\n' "$f1" "$f2" "$f3" "$f4" "$f5" "$f6" "$([ -z $f7 ] || echo "--> $(dst_2_name $f7)")"
  printf '  Rule     %-19s %-19s %-6s %-14s %-14s %-7s %-10s\n' "$g1" "$g2" "$g3" "$g4" "$g5" "$g6" "$([ -z $g7 ] || echo "--> $(dst_2_name $g7)")"
  printf '  Rule     %-19s %-19s %-6s %-14s %-14s %-7s %-10s\n' "$h1" "$h2" "$h3" "$h4" "$h5" "$h6" "$([ -z $h7 ] || echo "--> $(dst_2_name $h7)")"
  printf '  Gameip   %-19s %-19s %-6s %-14s %-14s %-7s %-10s\n'  "${gameCIDR}" "" "$([ -z $gameCIDR ] || echo "both")" "" "$([ -z $gameCIDR ] || echo "!80:443")" "$([ -z $gameCIDR ] || echo "000000")" "--> Gaming"
  printf '  Appdb    %-44s                                 %-7s %-10s\n' "$(mark_2_name $r1)" "$r1" "$([ -z $d1 ] || echo "--> $(dst_2_name $d1)")"
  printf '  Appdb    %-44s                                 %-7s %-10s\n' "$(mark_2_name $r2)" "$r2" "$([ -z $d2 ] || echo "--> $(dst_2_name $d2)")"
  printf '  Appdb    %-44s                                 %-7s %-10s\n' "$(mark_2_name $r3)" "$r3" "$([ -z $d3 ] || echo "--> $(dst_2_name $d3)")"
  printf '  Appdb    %-44s                                 %-7s %-10s\n' "$(mark_2_name $r4)" "$r4" "$([ -z $d4 ] || echo "--> $(dst_2_name $d4)")"
	echo ""
	echo -en '\033[?7h'			#enable line wrap
	;;
esac
