#!/bin/sh

sleep 15

/usr/local/bin/EpgDataCap_Bon -d BonDriver_LinuxMirakc.so -chscan \
&& /usr/local/bin/EpgTimerSrv
