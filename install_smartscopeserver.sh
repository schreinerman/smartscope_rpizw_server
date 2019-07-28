#!/bin/sh
apt-get update
apt-get install git libusb-dev libusb-1.0-0-dev libusb-1.0-0 libavahi-common-dev libavahi-client-dev 
git clone https://github.com/labnation/DeviceInterface.CXX
cd DeviceInterface.CXX
make LEDE=0
make install

cat << EOF >/lib/systemd/system/smartscopeserver.service
[Unit]
Description=SmartScope server service
After=multi-user.target

[Service]
Type=idle
ExecStart=/usr/local/bin/smartscope.daemon

[Install]
WantedBy=multi-user.target
EOF


cat << EOF >/usr/local/bin/smartscope.daemon
#!/bin/bash
# Created by Manuel Schreiner
#
# Logfile
Logfile=/var/log/smartscope
#
LostCount=1
rm $Logfile
while true
do
   #Start smartscopeserver process
   /usr/bin/smartscopeserver >> $Logfile 2>&1 &
   PID=$!
   echo Pid is $PID >>$Logfile
   #Check for connection problems in logfile and restart
   while [ $(grep -s -c "Moving from state Started -> Stopped" $Logfile) -lt $LostCount ]
   do
     /bin/sleep 2
   done
   #We have a lost connection
   echo Found lost connection >>$Logfile
   echo Killing SmartScope process $PID >>$Logfile
   /bin/kill $PID
   echo This is the $LostCount restart >>$Logfile
   # Lostcount is used because multiple connection failures can be in logfile.
   (( LostCount += 1 ))
   /bin/sleep 2
done
EOF

chmod 755  /usr/local/bin/smartscope.daemon

systemctl enable smartscopeserver.service
systemctl daemon-reload 
systemctl start smartscopeserver
