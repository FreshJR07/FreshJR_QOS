#!/bin/sh
cd "$(dirname "${0}")"
clear && printf '\e[3J'
echo "-------------------------------------------------"
echo "---- Ctrl + C to quit installer at any time  ----"
echo "-------------------------------------------------"
echo ""

echo "Detecting if files are present in current folder"
echo ""
file=1
if [ -e "./FreshJR_QOS.sh" ] ; then
   echo "  [x] FreshJR_QOS.sh"
else
   echo "  [ ] FreshJR_QOS.sh"
   file=0
fi

if [ -e "./FreshJR_QoS_Stats.asp" ] ; then
  echo "  [x] FreshJR_QoS_Stats"
else
  echo "  [ ] FreshJR_QoS_Stats"
  file=0
fi

echo ""

if [ "${file}" -eq 0 ] ; then
  echo "$(ls)"
  echo "Not all files detected"
  echo "--CANNOT CONTINUE!!--"
  echo ""  
  read -n 1 -s -r -p "(Press any key to Exit)"
  echo ""
  echo ""  
  exit
fi

echo "Getting router login information"
echo""
read -p "  Router ipaddress: " ip
read -p "  Router username:  " user
echo    "  Router password:  "
echo    "    (entry will appear blank - required twice)"
echo ""

echo "Transfering files onto router "
scp "./FreshJR_QOS.sh" "./FreshJR_QoS_Stats.asp" "${user}"@"${ip}":/jffs/
echo ""

echo "Starting script installer"
ssh -t -o LogLevel=quiet -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "${user}"@"${ip}" '
    mkdir /jffs/scripts/ 2> /dev/null;
    mv /jffs/FreshJR_QOS.sh /jffs/scripts/FreshJR_QOS;
    cat /jffs/FreshJR_QoS_Stats.asp > /jffs/scripts/www_FreshJR_QoS_Stats.asp;
    rm /jffs/FreshJR_QoS_Stats.asp
    sh /jffs/scripts/FreshJR_QOS -install;'

  read -n 1 -s -r -p "(Press any key to Exit)"
  echo ""
  echo ""  
  exit