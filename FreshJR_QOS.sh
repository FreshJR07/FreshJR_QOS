#!/bin/sh
##FreshJR_QOS_v7 released 08/03/2018
##Script Tested on ASUS AC-68U, FW384.4, using Adaptive QOS with Manual Bandwidth Settings
##Script Changes Unidentified Packet QOS destination from "Default" Traffic Container (Category7) into user definable (in WebUI) "Others" Traffic Container
##Script Changes Minimum Guaranteed Bandwidth per QOS category from 128Kbit into user defined percentages of upload and download.
##Script moves "Defaults" (unidentified traffic) Traffic Container priority into position 6 (originally position 7)
##  This moves the users "bottom traffic container" into position 7 from position position 6
##  In simplest terms, the user defined "bottom traffic container" will have worse priority than unidentified traffic
##Script supports custom QOS rules. To create rules, copy applicable rules from templates below, change filter parameters as desired, and then paste into applicable location.
##	Included custom rule moves any UDP traffic on ports 500 & 4500 into VOIP traffic Container.				(Wifi Calling)
##	Included custom rule moves any UDP traffic on ports 16384 - 16415 into VOIP traffic Container.			(Facetime)
##	Included custom rule moves any Snapchat traffic into Others traffic Container.							(Snapchat)
##	Included custom rule moves any Speedtest.net traffic into Downloads traffic Container.					(Speedtest.net)
##	Included custom rule moves any Google Play Store traffic into Downloads traffic Container.				(Google Play)
##	Included custom rule moves any Apple AppStore traffic into Downloads traffic Container.					(Apple AppStore)
##  Included custom rule moves any Gaming traffic from ports 80 & 443 into Defaults traffic Container.		(Gaming)
##     port 80 & 443 is primarily game downloads & patches BUT game login protocols are also caught within
##  Included, but disabled by default (commented out) is an additional gaming device oriented rule			(Gaming)
##     The use of this gaming rule REQUIRES gaming devices to have a static dhcp ip assignment (in webUI)  <<AND>>
##     this static IP needs to once AGAIN be specified within this scripts up/down gaming rules, using CIDR notation
##     The gaming rule takes unidentified traffic for user specified devices and routes it into the Gaming traffic Container.
#
#---------------------------------------------------------------------------------------------------------------
#	VALID FLOW ID'S FOR TC APP REDIRECTION
#	 ${VOIP}, ${Gaming}, ${Others}, ${Web}, ${Streaming}, ${Downloads}, ${Net}, ${Defaults}
#
#	VALID MARKS FOR **DOWNLOAD** IPTABLES RULES
#	 ${VOIP_mark_down}, ${Gaming_mark_down}, ${Others_mark_down}, ${Web_mark_down}, ${Streaming_mark_down}, ${Downloads_mark_down}, ${Net_mark_down}, ${Default_mark_down}
#
#	VALID MARKS FOR **UPLOAD** IPTABLES RULES
#	 ${VOIP_mark_up}, ${Gaming_mark_up}, ${Others_mark_up}, ${Web_mark_up}, ${Streaming_mark_up}, ${Downloads_mark_up}, ${Net_mark_up}, ${Default_mark_up}
#
#   DOWNLOAD/INCOMMING TRAFFIC rule templates.	See comments next to rule for details.  Make sure to correctly define TCP or UDP designation.
#	 See comments next to rule for details.  
#	 Make sure to correctly define TCP or UDP designation for port rules.
#
#	 iptables -D POSTROUTING -t mangle -o br0 -p tcp --dport 1234:1236 -j MARK --set-mark ${Downloads_mark_down} &> /dev/null		#Template Rule 1 	(Download traffic towards LAN (local) device ports 1234-1236 via TCP 	goes to "Downloads" Traffic Container)
#	 iptables -A POSTROUTING -t mangle -o br0 -p tcp --dport 1234:1236 -j MARK --set-mark ${Downloads_mark_down} 									  	  (XXXX:YYYY defines port range, XXXX defines for single port)
#																																	
#	 iptables -D POSTROUTING -t mangle -o br0 -d 192.168.2.123/32 -j MARK --set-mark ${Downloads_mark_down} &> /dev/null  			#Template Rule 2 	(Download traffic towards LAN (local) device 192.168.2.123  			goes to "Downloads" Traffic Container) 
#	 iptables -A POSTROUTING -t mangle -o br0 -d 192.168.2.123/32 -j MARK --set-mark ${Downloads_mark_down}												  ( /32 CIDR mask defines only one ip, see CIDR calculator ip ranges)
#																																	
#	 iptables -D POSTROUTING -t mangle -o br0 -p udp --sport 5555 -j MARK --set-mark ${VOIP_mark_down} &> /dev/null					#Template Rule 3 	(Download traffic from WAN (remote) server port 5555 via UDP)			goes to "VOIP" Traffic Container)
#	 iptables -A POSTROUTING -t mangle -o br0 -p udp --sport 5555 -j MARK --set-mark ${VOIP_mark_down}													  (XXXX:YYYY defines port range, XXXX defines for single port)
#																																					
#	 iptables -D POSTROUTING -t mangle -o br0 -s 75.75.75.75/32 -j MARK --set-mark ${VOIP_mark_down} &> /dev/null 					#Template Rule 4 	(Download traffic from WAN (remote) server 75.75.75.75 					goes to "VOIP" Traffic Container)
#	 iptables -A POSTROUTING -t mangle -o br0 -s 75.75.75.75/32 -j MARK --set-mark ${VOIP_mark_down} 													  ( /32 CIDR mask defines only one ip, see CIDR calculator ip ranges)
#
#
#   UPLOAD/OUTOING TRAFFIC rule templates.		
#	 See comments next to rule for details.  
#	 Make sure to correctly define TCP or UDP designation for port rules.
#
#	  iptables -D POSTROUTING -t mangle -o $wan -p tcp --sport 1234:1236 -j MARK --set-mark ${Downloads_mark_up} &> /dev/null		#Template Rule 1	  (Upload traffic from LAN (local) device ports 1234-1236 via TCP) 		goes to "Downloads" Traffic Container) 	
#	  iptables -A POSTROUTING -t mangle -o $wan -p tcp --sport 1234:1236 -j MARK --set-mark ${Downloads_mark_up} 											(XXXX:YYYY defines port range, XXXX defines for single port)
#																																	
#	  iptables -D POSTROUTING -t mangle -o $wan -s 192.168.2.123/32 -j MARK --set-mark ${Downloads_mark_up} &> /dev/null			#Template Rule 2	  (Upload traffic from LAN (local) device ip 192.168.2.123 				goes to "Downloads" Traffic Container)
#	  iptables -A POSTROUTING -t mangle -o $wan -s 192.168.2.123/32 -j MARK --set-mark ${Downloads_mark_up} 												( /32 CIDR mask defines only one ip, see CIDR calculator ip ranges)
#																																	
#	  iptables -D POSTROUTING -t mangle -o $wan -p udp --dport 5555 -j MARK --set-mark ${VOIP_mark_up} &> /dev/null					#Template Rule 3	  (Upload traffic towards WAN (remote) server port 5555 via UDP 		goes to "VOIP" Traffic Container) 
#	  iptables -A POSTROUTING -t mangle -o $wan -p udp --dport 5555 -j MARK --set-mark ${VOIP_mark_up}														(XXXX:YYYY defines port range, XXXX defines for single port)
#																																	
#	  iptables -D POSTROUTING -t mangle -o $wan -d 75.75.75.75/32 -j MARK --set-mark ${VOIP_mark_up} &> /dev/null					#Template Rule 4 	  (Upload traffic towards WAN (remote) server 75.75.75.75 				goes to "VOIP" Traffic Container)
#	  iptables -A POSTROUTING -t mangle -o $wan -d 75.75.75.75/32 -j MARK --set-mark ${VOIP_mark_up} 													    ( /32 CIDR mask defines only one ip, see CIDR calculator ip ranges)
#																																	
#---------------------------------------------------------------------------------------------------------------						


####################  Bandwidth Setup #####################

	user_variables() {
		#Percent of download speed guaranteed per QOS category, change below as desired 	(minimum value per section 5, sum should not be greater than 100)
		NetControl_DownBandPercent=5					#This value can be adjust as desired		**  no spaces before or after the "=" sign **
		VoIP_DownBandPercent=20							#This value can be adjust as desired		**                no decimals              **
		Gaming_DownBandPercent=15						#This value can be adjust as desired
		Others_DownBandPercent=10						#This value can be adjust as desired		#Note: New destination for unidentified traffic
		WebSurfing_DownBandPercent=10					#This value can be adjust as desired
		Video_DownBandPercent=30						#This value can be adjust as desired
		FileTransfer_DownBandPercent=5					#This value can be adjust as desired
		Default_DownBandPercent=5						#This value can be adjust as desired		#Note: Original destination for unidentified traffic, repurposed for "Gaming Downloads on ports 80/443"
	
		#Percent of upload speed guaranteed per QOS category, change below as desired 		(minimum value per section 5, sum should not be greater than 100)
		NetControl_UpBandPercent=5						#This value can be adjust as desired
		VoIP_UpBandPercent=20							#This value can be adjust as desired
		Gaming_UpBandPercent=15							#This value can be adjust as desired
		Others_UpBandPercent=30							#This value can be adjust as desired		#Note: New destination for unidentified traffic
		WebSurfing_UpBandPercent=10						#This value can be adjust as desired
		Video_UpBandPercent=10							#This value can be adjust as desired
		FileTransfer_UpBandPercent=5					#This value can be adjust as desired
		Default_UpBandPercent=5							#This value can be adjust as desired		#Note: Original destination for unidentified traffic, repurposed for "Gaming Downloads on ports 80/443"
	}


####################  Custom Rules Setup #####################
	
	iptable_down_rules() {
		echo "Applying - Iptable Down Rules"
		##DOWNLOAD (INCOMMING TRAFFIC) CUSTOM RULES START HERE	
			
			iptables -D POSTROUTING -t mangle -o br0 -p udp --sport 500 -j MARK --set-mark ${VOIP_mark_down} &> /dev/null												#Wifi Calling (1/2) - (All incoming traffic w/ WAN source port 500  goes to "VOIP" Traffic Container) 								
			iptables -A POSTROUTING -t mangle -o br0 -p udp --sport 500 -j MARK --set-mark ${VOIP_mark_down}
			
			iptables -D POSTROUTING -t mangle -o br0 -p udp --sport 4500 -j MARK --set-mark ${VOIP_mark_down} &> /dev/null												#Wifi Calling (2/2) - (All incoming traffic w/ WAN source port 4500 goes to "VOIP" Traffic Container)
			iptables -A POSTROUTING -t mangle -o br0 -p udp --sport 4500 -j MARK --set-mark ${VOIP_mark_down} 
			
			iptables -D POSTROUTING -t mangle -o br0 -p udp --dport 16384:16415 -j MARK --set-mark ${VOIP_mark_down} &> /dev/null										#Facetime
			iptables -A POSTROUTING -t mangle -o br0 -p udp --dport 16384:16415 -j MARK --set-mark ${VOIP_mark_down} 
			
			iptables -D POSTROUTING -t mangle -o br0 -m mark --mark 0x80080000/0xc03f0000 -p tcp --sport 80 -j MARK --set-mark ${Default_mark_down} &> /dev/null		#Gaming (1/3) - Routes "Gaming" traffic coming from port 443 into "Defaults"
			iptables -A POSTROUTING -t mangle -o br0 -m mark --mark 0x80080000/0xc03f0000 -p tcp --sport 80 -j MARK --set-mark ${Default_mark_down}
			
			iptables -D POSTROUTING -t mangle -o br0 -m mark --mark 0x80080000/0xc03f0000 -p tcp --sport 443 -j MARK --set-mark ${Default_mark_down} &> /dev/null		#Gaming (2/3) - Routes "Gaming" traffic coming from port 80 into "Defaults"
			iptables -A POSTROUTING -t mangle -o br0 -m mark --mark 0x80080000/0xc03f0000 -p tcp --sport 443 -j MARK --set-mark ${Default_mark_down}
			
			#iptables -D POSTROUTING -t mangle -o br0 -d 192.168.2.100/30 -m mark --mark 0x80000000/0x8000ffff -p tcp -m multiport ! --sports 443,80  -j MARK --set-mark ${Gaming_mark_down} &> /dev/null    	#Gaming (3/3) - Routes Unidentified Traffic into "Gaming", instead of "Others", for LAN clients specified
			#iptables -A POSTROUTING -t mangle -o br0 -d 192.168.2.100/30 -m mark --mark 0x80000000/0x8000ffff -p tcp -m multiport ! --sports 443,80  -j MARK --set-mark ${Gaming_mark_down}
			
		##DOWNLOAD (INCOMMING TRAFFIC) CUSTOM RULES END HERE
	}

	iptable_up_rules(){
		
		#wan="ppp0"				## WAN interface over-ride for upload traffic -- Variable ONLY needs to be defined for users non-Rmerlin 384+ firmware 
								# RMerlin v384+ Firmware AUTOMATICALLY detects correct interface --> this variable should be left COMMENTED/DISABLED on RMerlin v384+
								# Other firmwares are configured to assume an eth0 interface --> this variable should be manually set if the connection type differs from eth0 ( ppp0, vlanXXX, etc)
								
		echo "Applying - Iptable Up   Rules ($wan)"

		##UPLOAD (OUTGOING TRAFFIC) CUSTOM RULES START HERE	
		
			iptables -D POSTROUTING -t mangle -o $wan -p udp --dport 500 -j MARK --set-mark ${VOIP_mark_up} &> /dev/null											#Wifi Calling (1/2) - (All outgoing traffic w/ WAN destination port 500  goes to "VOIP" Traffic Container)  										
			iptables -A POSTROUTING -t mangle -o $wan -p udp --dport 500 -j MARK --set-mark ${VOIP_mark_up}
			
			iptables -D POSTROUTING -t mangle -o $wan -p udp --dport 4500 -j MARK --set-mark ${VOIP_mark_up} &> /dev/null											#Wifi Calling (2/2) - (All outgoing traffic w/ WAN destination port 4500 goes to "VOIP" Traffic Container) 
			iptables -A POSTROUTING -t mangle -o $wan -p udp --dport 4500 -j MARK --set-mark ${VOIP_mark_up} 
			
			iptables -D POSTROUTING -t mangle -o $wan -p udp --sport 16384:16415 -j MARK --set-mark ${VOIP_mark_up} &> /dev/null									#Facetime
			iptables -A POSTROUTING -t mangle -o $wan -p udp --sport 16384:16415 -j MARK --set-mark ${VOIP_mark_up} 
			
			iptables -D POSTROUTING -t mangle -o $wan -m mark --mark 0x40080000/0xc03f0000 -p tcp --sport 80 -j MARK --set-mark ${Default_mark_up} &> /dev/null   	#Gaming (1/3) - Routes "Gaming" traffic going to port 443 into "Defaults"
			iptables -A POSTROUTING -t mangle -o $wan -m mark --mark 0x40080000/0xc03f0000 -p tcp --sport 80 -j MARK --set-mark ${Default_mark_up}
			
			iptables -D POSTROUTING -t mangle -o $wan -m mark --mark 0x40080000/0xc03f0000 -p tcp --sport 443 -j MARK --set-mark ${Default_mark_up} &> /dev/null  	#Gaming (2/3) - Routes "Gaming" traffic going to port 80 into "Defaults"
			iptables -A POSTROUTING -t mangle -o $wan -m mark --mark 0x40080000/0xc03f0000 -p tcp --sport 443 -j MARK --set-mark ${Default_mark_up}
			
			#iptables -D POSTROUTING -t mangle -o $wan -s 192.168.2.100/30 -m mark --mark 0x40000000/0x4000ffff -p tcp -m multiport ! --dports 80,443 -j MARK --set-mark ${Gaming_mark_up} &> /dev/null 	#Gaming (3/3) - Routes Unidentified Traffic into "Gaming", instead of "Others", from specified LAN devices in rule (line 1/2)
			#iptables -A POSTROUTING -t mangle -o $wan -s 192.168.2.100/30 -m mark --mark 0x40000000/0x4000ffff -p tcp -m multiport ! --dports 80,443 -j MARK --set-mark ${Gaming_mark_up}
	
		##UPLOAD (OUTGOING TRAFFIC) CUSTOM RULES END HERE
	}
	
	tc_redirection_down_rules() {
		echo "Applying  TC Down Rules"
		${tc} filter del dev br0 parent 1: prio $1																					#remove original unidentified traffic rule
		${tc} filter del dev br0 parent 1: prio 22 &> /dev/null																		#remove original HTTPS rule
		${tc} filter del dev br0 parent 1: prio 23 &> /dev/null																		#remove original HTTPS rule
		${tc} filter add dev br0 protocol all prio 22 u32 match mark 0x80130000 0xc03f0000 flowid ${Web}							#recreate HTTPS rule with different destination
		${tc} filter add dev br0 protocol all prio 23 u32 match mark 0x80140000 0xc03f0000 flowid ${Web}							#recreate HTTPS rule with different destination
		##DOWNLOAD APP_DB TRAFFIC REDIRECTION RULES START HERE	
			
			${tc} filter add dev br0 protocol all prio $1 u32 match mark 0x8000006B 0xc03fffff flowid ${Others}							#Snapchat
			${tc} filter add dev br0 protocol all prio 15 u32 match mark 0x800D0007 0xc03fffff flowid ${Downloads}						#Speedtest.net
			${tc} filter add dev br0 protocol all prio 15 u32 match mark 0x800D0086 0xc03fffff flowid ${Downloads}						#Google Play 
			${tc} filter add dev br0 protocol all prio 15 u32 match mark 0x800D00A0 0xc03fffff flowid ${Downloads}						#Apple AppStore	
			
		##DOWNLOAD APP_DB TRAFFIC REDIRECTION RULES END HERE	
		${tc} filter add dev br0 protocol all prio $1 u32 match mark 0x80000000 0x8000ffff flowid ${Others}							#recreate unidentified traffic rule with different destination - Routes Unidentified Traffic into webUI adjustable "Others" traffic container instead of "Defaults"
		${tc} filter add dev br0 protocol all prio 10 u32 match mark 0x803f0001 0xc03fffff flowid ${Defaults}						#Used to achieve iptables Default_mark_down functionality
	}

	tc_redirection_up_rules() {
		echo "Applying  TC Up   Rules"
		${tc} filter del dev eth0 parent 1: prio $1																					#remove original unidentified traffic rule
		${tc} filter del dev eth0 parent 1: prio 22 &> /dev/null																	#remove original HTTPS rule
		${tc} filter del dev eth0 parent 1: prio 23 &> /dev/null																	#remove original HTTPS rule
		${tc} filter add dev eth0 protocol all prio 22 u32 match mark 0x40130000 0xc03f0000 flowid ${Web}							#recreate HTTPS rule with different destination
		${tc} filter add dev eth0 protocol all prio 23 u32 match mark 0x40140000 0xc03f0000 flowid ${Web}							#recreate HTTPS rule with different destination
		##UPLOAD APP_DB TRAFFIC REDIRECTION RULES START HERE	
			
			${tc} filter add dev eth0 protocol all prio $1 u32 match mark 0x4000006B 0xc03fffff flowid ${Others}						#Snapchat
			${tc} filter add dev eth0 protocol all prio 15 u32 match mark 0x400D0007 0xc03fffff flowid ${Downloads}						#Speedtest.net
			${tc} filter add dev eth0 protocol all prio 15 u32 match mark 0x400D0086 0xc03fffff flowid ${Downloads}						#Google Play 
			${tc} filter add dev eth0 protocol all prio 15 u32 match mark 0x400D00A0 0xc03fffff flowid ${Downloads}						#Apple AppStore
			
		##UPLOAD APP_DB TRAFFIC REDIRECTION RULES END HERE
		${tc} filter add dev eth0 protocol all prio $1 u32 match mark 0x40000000 0x4000ffff flowid ${Others}						#recreate unidentified traffic rule with different destination - Routes Unidentified Traffic into webUI adjustable "Others" traffic container, instead of "Default" traffic container		
		${tc} filter add dev eth0 protocol all prio 10 u32 match mark 0x403f0001 0xc03fffff flowid ${Defaults}						#Used to achieve iptables Default_mark_up functionality
	}

	custom_rates() {
		echo "Modifying TC Class Rates"
		${tc} class change dev br0 parent 1:1 classid 1:10 htb ${PARMS}prio 0 rate ${DownRate0}Kbit ceil ${DownCeil}Kbit burst ${DownBurst0} cburst ${DownCburst0}
		${tc} class change dev br0 parent 1:1 classid 1:11 htb ${PARMS}prio 1 rate ${DownRate1}Kbit ceil ${DownCeil}Kbit burst ${DownBurst1} cburst ${DownCburst1} 
		${tc} class change dev br0 parent 1:1 classid 1:12 htb ${PARMS}prio 2 rate ${DownRate2}Kbit ceil ${DownCeil}Kbit burst ${DownBurst2} cburst ${DownCburst2} 
		${tc} class change dev br0 parent 1:1 classid 1:13 htb ${PARMS}prio 3 rate ${DownRate3}Kbit ceil ${DownCeil}Kbit burst ${DownBurst3} cburst ${DownCburst3} 
		${tc} class change dev br0 parent 1:1 classid 1:14 htb ${PARMS}prio 4 rate ${DownRate4}Kbit ceil ${DownCeil}Kbit burst ${DownBurst4} cburst ${DownCburst4} 
		${tc} class change dev br0 parent 1:1 classid 1:15 htb ${PARMS}prio 5 rate ${DownRate5}Kbit ceil ${DownCeil}Kbit burst ${DownBurst5} cburst ${DownCburst5} 
		${tc} class change dev br0 parent 1:1 classid 1:16 htb ${PARMS}prio 7 rate ${DownRate6}Kbit ceil ${DownCeil}Kbit burst ${DownBurst6} cburst ${DownCburst6} 
		${tc} class change dev br0 parent 1:1 classid 1:17 htb ${PARMS}prio 6 rate ${DownRate7}Kbit ceil ${DownCeil}Kbit burst ${DownBurst7} cburst ${DownCburst7}
		
		${tc} class change dev eth0 parent 1:1 classid 1:10 htb ${PARMS}prio 0 rate ${UpRate0}Kbit ceil ${UpCeil}Kbit burst ${UpBurst0} cburst ${UpCburst0}
		${tc} class change dev eth0 parent 1:1 classid 1:11 htb ${PARMS}prio 1 rate ${UpRate1}Kbit ceil ${UpCeil}Kbit burst ${UpBurst1} cburst ${UpCburst1}
		${tc} class change dev eth0 parent 1:1 classid 1:12 htb ${PARMS}prio 2 rate ${UpRate2}Kbit ceil ${UpCeil}Kbit burst ${UpBurst2} cburst ${UpCburst2}
		${tc} class change dev eth0 parent 1:1 classid 1:13 htb ${PARMS}prio 3 rate ${UpRate3}Kbit ceil ${UpCeil}Kbit burst ${UpBurst3} cburst ${UpCburst3}
		${tc} class change dev eth0 parent 1:1 classid 1:14 htb ${PARMS}prio 4 rate ${UpRate4}Kbit ceil ${UpCeil}Kbit burst ${UpBurst4} cburst ${UpCburst4}
		${tc} class change dev eth0 parent 1:1 classid 1:15 htb ${PARMS}prio 5 rate ${UpRate5}Kbit ceil ${UpCeil}Kbit burst ${UpBurst5} cburst ${UpCburst5}
		${tc} class change dev eth0 parent 1:1 classid 1:16 htb ${PARMS}prio 7 rate ${UpRate6}Kbit ceil ${UpCeil}Kbit burst ${UpBurst6} cburst ${UpCburst6}
		${tc} class change dev eth0 parent 1:1 classid 1:17 htb ${PARMS}prio 6 rate ${UpRate7}Kbit ceil ${UpCeil}Kbit burst ${UpBurst7} cburst ${UpCburst7}
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

set_all_variables(){

	if [ -e "/usr/sbin/realtc" ] ; then	
		tc="realtc"
	else
		tc="tc"
	fi

	#read variables at beginning of script
	user_variables					
	
										
	#read order of QOS categories
	Defaults="1:17"
	Net="1:10"
	flowid=0
	while read -r line;				# reads users order of QOS categories
	do		
		#logger -s "${line}"
		case ${line} in	
		 '0')
			VOIP="1:1${flowid}"
			eval "Cat${flowid}DownBandPercent=${VoIP_DownBandPercent}"
			eval "Cat${flowid}UpBandPercent=${VoIP_UpBandPercent}"
			;;
		 '1')
			Downloads="1:1${flowid}"
			eval "Cat${flowid}DownBandPercent=${FileTransfer_DownBandPercent}"
			eval "Cat${flowid}UpBandPercent=${FileTransfer_UpBandPercent}"
			;;
		 '4')
			Streaming="1:1${flowid}"
			eval "Cat${flowid}DownBandPercent=${Video_DownBandPercent}"
			eval "Cat${flowid}UpBandPercent=${Video_UpBandPercent}"
			;;
		 '7')
			Others="1:1${flowid}"
			eval "Cat${flowid}DownBandPercent=${Others_DownBandPercent}"
			eval "Cat${flowid}UpBandPercent=${Others_UpBandPercent}"
			;;
		 '8')
			Gaming="1:1${flowid}"
			eval "Cat${flowid}DownBandPercent=${Gaming_DownBandPercent}"
			eval "Cat${flowid}UpBandPercent=${Gaming_UpBandPercent}"
			;;
		 '9')
			flowid=0
			;;
		 '13')
			Web="1:1${flowid}"
			eval "Cat${flowid}DownBandPercent=${WebSurfing_DownBandPercent}"
			eval "Cat${flowid}UpBandPercent=${WebSurfing_UpBandPercent}"
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
	
	
	DownRate0="$(expr ${DownCeil} \* ${NetControl_DownBandPercent} / 100)"				#Minimum guaranteed Up/Down rates per QOS category corresponding to user defined percentages 
	DownRate1="$(expr ${DownCeil} \* ${Cat1DownBandPercent} / 100)"
	DownRate2="$(expr ${DownCeil} \* ${Cat2DownBandPercent} / 100)"
	DownRate3="$(expr ${DownCeil} \* ${Cat3DownBandPercent} / 100)"
	DownRate4="$(expr ${DownCeil} \* ${Cat4DownBandPercent} / 100)"
	DownRate5="$(expr ${DownCeil} \* ${Cat5DownBandPercent} / 100)"
	DownRate6="$(expr ${DownCeil} \* ${Cat6DownBandPercent} / 100)"
	DownRate7="$(expr ${DownCeil} \* ${Default_DownBandPercent} / 100)"

	
	UpRate0="$(expr ${UpCeil} \* ${NetControl_UpBandPercent} / 100)"
	UpRate1="$(expr ${UpCeil} \* ${Cat1UpBandPercent} / 100)"
	UpRate2="$(expr ${UpCeil} \* ${Cat2UpBandPercent} / 100)"
	UpRate3="$(expr ${UpCeil} \* ${Cat3UpBandPercent} / 100)"
	UpRate4="$(expr ${UpCeil} \* ${Cat4UpBandPercent} / 100)"
	UpRate5="$(expr ${UpCeil} \* ${Cat5UpBandPercent} / 100)"
	UpRate6="$(expr ${UpCeil} \* ${Cat6UpBandPercent} / 100)"
	UpRate7="$(expr ${UpCeil} \* ${Default_UpBandPercent} / 100)"
	
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

appdb(){

	if [ "$( grep -i "${1}"  /tmp/bwdpi/bwdpi.app.db | wc -l )" -lt "5" ] ; then
		grep -i "${1}"  /tmp/bwdpi/bwdpi.app.db | while read -r line ; do
			echo $line | cut -f 4 -d ","

			cat_decimal=$(echo $line | cut -f 1 -d "," )
			cat_hex=$( printf "80%02x" $cat_decimal )
			case "$cat_decimal" in
			 '9'|'20')
			   echo " Cat:  Net Control"
			   ;;
			 '0'|'5'|'6'|'15'|'17')
			   echo " Cat:  VoIP"
			   ;;
			 '8')
			   echo " Cat:  Gaming"
			   ;;
			 '7'|'10'|'11'|'21'|'23')
			   echo " Cat:  Others"
			   ;;
			 '13'|'24'|'18'|'19')
			   echo " Cat:  Web"
			   ;;			   
			 '4'|'12')
			   echo " Cat:  Streaming"
			   ;;						   
			 '1'|'3'|'14')
			   echo " Cat:  Downloads"
			   ;;				   
			esac
			
			
			printf " Mark: 0x${cat_hex}"
			echo $line | cut -f 2 -d "," | awk '{printf("%04x 0xc03fffff\n",$1)}'
			echo -e " Prio: $(expr $(tc filter show dev br0 | grep "${cat_hex}0000" -B1 | tail -2 | cut -d " " -f7 | head -1) - 1) \n"
		done
	else
		echo "AppDB search parameter has to be more specfic"
	fi
}

debug(){
	current_undf_rule="$(tc filter show dev br0 | grep -v "/" | grep "000ffff" -B1)"
	undf_flowid=$(echo $current_undf_rule | grep -o "flowid.*" | cut -d" " -f2 | head -1)
	undf_prio=$(echo $current_undf_rule | grep -o "pref.*" | cut -d" " -f2 | head -1)
	set_all_variables
	
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
	logger -t "adaptive QOS" -s "Downbursts -- $DownBurst0, $DownBurst1, $DownBurst2, $DownBurst3, $DownBurst4, $DownBurst5, $DownBurst6, $DownBurst7"
	logger -t "adaptive QOS" -s "DownCbursts -- $DownCburst0, $DownCburst1, $DownCburst2, $DownCburst3, $DownCburst4, $DownCburst5, $DownCburst6, $DownCburst7"
	logger -t "adaptive QOS" -s "***********"
	logger -t "adaptive QOS" -s "Uprates -- $UpRate0, $UpRate1, $UpRate2, $UpRate3, $UpRate4, $UpRate5, $UpRate6, $UpRate7"
	logger -t "adaptive QOS" -s "Upbursts -- $UpBurst0, $UpBurst1, $UpBurst2, $UpBurst3, $UpBurst4, $UpBurst5, $UpBurst6, $UpBurst7"
	logger -t "adaptive QOS" -s "UpCbursts -- $UpCburst0, $UpCburst1, $UpCburst2, $UpCburst3, $UpCburst4, $UpCburst5, $UpCburst6, $UpCburst7"
}

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
	
	echo -e  "\033[1;32m FreshJR QOS has been installed \033[0m"
	echo -e  "\033[1;32m   make sure a USB storage device is plugged in and \033[0m"
	echo  -e "\033[1;31;7m   [ reboot router ] to finalize installation\033[0m"
}

#Main program here, will execute different things depending on arguments
arg1="$(echo "$1" | tr -d "-")"
case "$arg1" in	
 'start'|'check'|'mount')																	##RAN ON FIREWALL-START OR CRON TASK, (RAN ONLY POST USB MOUNT IF USING STOCK ASUS FIRMWARE)
	cru a FreshJR_QOS "30 3 * * * /jffs/scripts/FreshJR_QOS -check"
	if [ "$(nvram get qos_enable)" == "1" ] ; then
		for pid in $(pidof FreshJR_QOS); do
			if [ $pid != $$ ]; then
				kill $pid
				logger -t "adaptive QOS" -s "Delayed Start Canceled"
			fi 
		done
		
		if [ "$arg1" == "start" ] ; then
			wan="${2}"
				if [ -z "$wan" ] ; then
					wan="eth0"
				fi
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
		if [ "${undf_flowid}" == "1:17" ] ; then		#if rule setting unidentified traffic to 1:17 exists then run modification script
			if [ "$arg1" == "check" ] ; then
				logger -t "adaptive QOS" -s "Scheduled Persistence Check -> Reapplying Changes"
			fi
			
			if [ "$(nvram get script_usbmount)" == "/jffs/scripts/script_usbmount" ] && [ "$arg1" != "start" ] ; then		#used only on stock ASUS firmware -mount && -check script calls
				wan="eth0"
				iptable_down_rules 2>&1 | logger -t "adaptive QOS"
				iptable_up_rules 2>&1 | logger -t "adaptive QOS"
			fi
			
			set_all_variables 
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
 	chmod 0755 /jffs/scripts/FreshJR_QOS
	
	sed -i '/FreshJR_QOS/d' /jffs/scripts/init-start 2>/dev/null									
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
			exit 1
		fi	
	fi	
	
	if ! grep -iq "merlin" /proc/version ; then																					##GIVE USER CHOICE TO RUN STOCK INSTALL IF Non-RMerlin FIRMWARE detected
		echo -e "\033[1;31m Non-RMerlin Firmware Detected \033[0m"
		echo -e -n "\033[1;31m Is this installation for (Stock / Default / Unmodified) Asus firmware?  [1=Yes 2=No]? \033[0m"   # Display prompt in red
		read yn
		case $yn in
			'1') 
				sed -i '/FreshJR_QOS/d' /jffs/scripts/firewall-start 2>/dev/null
				stock_install; 
				exit 1
				;;
			'2') 
				sed -i '/FreshJR_QOS/d' /jffs/scripts/script_usbmount 2>/dev/null 
				echo -e "\033[1;32m Installing RMerlin version of the script \033[0m"   # Display prompt in red
				break
				;;
			*) 
				echo "Invalid Option"
				echo "ABORTING INSTALLATION "
				exit 1
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
	echo -e  "\033[1;32m FreshJR QOS has been installed \033[0m"
	echo -e  "\033[1;31;7m [ Turn ON OR Restart QOS ] for modifications to take effect \033[0m"
	;;
 'uninstall')																		## UNINSTALLS SCRIPT AND DELETES FILES
	sed -i '/FreshJR_QOS/d' /jffs/scripts/firewall-start 2>/dev/null						#remove FreshJR_QOS from firewall start
	sed -i '/FreshJR_QOS/d' /jffs/scripts/script_usbmount 2>/dev/null						#remove FreshJR_QOS from script_usbmount - only used on stock ASUS firmware installs
	cru d FreshJR_QOS
	rm -f /jffs/scripts/FreshJR_QOS
	if [ "$(nvram get script_usbmount)" == "/jffs/scripts/script_usbmount" ] ; then												   #only used on stock ASUS firmware installs
		nvram unset script_usbmount
		nvram commit
	fi
	echo -e  "\033[1;32m FreshJR QOS has been uninstalled \033[0m"
	;;
 'disable')																		## TURNS OFF SCRIPT BUT KEEP FILES
	sed -i '/FreshJR_QOS/d' /jffs/scripts/firewall-start  2>/dev/null
	sed -i '/FreshJR_QOS/d' /jffs/scripts/script_usbmount 2>/dev/null
	cru d FreshJR_QOS
	;;
 'debug')
	debug
	;;	
 'appdb')
	appdb "$2"
	;;
 *)
	echo "These are available commands:"
	echo ""
	echo "  FreshJR_QOS -install            installs   script"
	echo "  FreshJR_QOS -uninstall          uninstalls script && deletes from disk "
	echo ""
	echo "  FreshJR_QOS -enable             enables    script "
	echo "  FreshJR_QOS -disable            disables   script but does not delete from disk"
	echo ""
	echo "  FreshJR_QOS -debug              checks current status of QOS configuration"
	echo ""
	echo "  FreshJR_QOS -check              instantaneously performs script modifications if required"
	echo ""
	echo '  FreshJR_QOS -appdb "App Name"   Use this to lookup mark/prio paramters required to create an App Analysis redirection rules'
	echo ""
	;;
esac	