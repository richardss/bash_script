#!/bin/bash

CLI_COMMAND="/b5/data/jboss/bin/jboss-cli.sh -c --controller=10.8.6.8"
MGMT_USER="admin"
MGMT_PASS=""

#Check Correct JBOSS ID
if [ `id -u` != "1002" ] ; then
echo "Lo script deve essere eseguito come utente jboss"
exit 0 
fi

manage_mod_cluster_manager_lbgroup(){
unset SERVERGROUP
unset PROFILE
unset RESPONSE
unset EXIT
clear
echo "Inserisci il nome del profilo su cui operare:"
echo
echo "Profili Presenti:"
echo
curl --digest -u "$MGMT_USER:$MGMT_PASS" -s "http://10.8.6.8:9990/management/host" | python -c 'import json,sys;obj=json.load(sys.stdin);print json.dumps(obj["profile"].keys())' | sed s/\"//g
EXIT=false
until [ "$EXIT" == "true" ]; do
echo "Seleziona il profilo:"
read PROFILE
$CLI_COMMAND command="/profile=$PROFILE:read-resource(attributes-only=true)"  > /dev/null
if [ $? == 0 ]; then
EXIT="true"
else
echo "Profilo inesistente"
fi
done

echo
unset INSTANCE
unset SERVERGROUP
echo "Server Group Associati al profilo:"
echo
$CLI_COMMAND command="/server-group=*:query(select=[\"profile\"],where=[\"profile\",\"$PROFILE\"])" | perl  -lne 'print $1 if /"server-group" => "(.*?)"/'
for  SERVERGROUP in `$CLI_COMMAND command="/server-group=*:query(select=["profile"],where=["profile","$PROFILE"])" | perl  -lne 'print $1 if /"server-group" => "(.*?)"/'`; do
echo -----------------------------------
echo "Host del ServerGroup:" $SERVERGROUP
echo
nservercount=`$CLI_COMMAND command="/host=*/server-config=*:query(select=[\"host\",\"name\"],where=[\"group\",\"$SERVERGROUP\"])" | perl  -lne 'print $1 if /"host" => "(.*?)"/' |wc -l`
if [ "$nservercount" -eq "0" ] ; then
echo "Nessun Server Associato al Server Group"
fi
for  SERVER in `$CLI_COMMAND command="/host=*/server-config=*:query(select=[\"host\",\"name\"],where=[\"group\",\"$SERVERGROUP\"])" | perl  -lne 'print $1 if /"host" => "(.*?)"/'` ; do
echo
echo "Server :" $SERVER
echo "Applicazioni Presenti sul SG:" $SERVERGROUP
ncountapp=`$CLI_COMMAND command="/server-group=$SERVERGROUP:read-resource" | perl -lne 'print $1 if /"deployment" => ."(.*?)"/' | wc -l`
if [ "$ncountapp" -eq "0" ] ; then
echo "Nessuna applicazione deployed"
else
$CLI_COMMAND command="/server-group=$SERVERGROUP:read-resource" | perl -lne 'print $1 if /"deployment" => ."(.*?)"/'
fi
echo
INSTANCE=`$CLI_COMMAND command="/host=$SERVER/server=*:query(select=["name"])" | perl  -lne 'print $1 if /"name" => "(.*?)"/'`
echo "Instance:" $INSTANCE
LBGROUP=`$CLI_COMMAND command="/host=$SERVER/server-config=$INSTANCE/system-property=modcluster.group:read-resource" | perl  -lne 'print $1 if /"value" => "(.*?)"/'`
echo "LBGroup:" $LBGROUP
for proxy in `$CLI_COMMAND command="/host=$SERVER/server=$INSTANCE/subsystem=modcluster:list-proxies()" | grep 9000 | sed s/[\,\"]//g` ; do
echo "Stato dei SG/LBGroup sui server Apache: "
echo "Server Apache :"$proxy
curl -s -k "https://$proxy/mod_cluster_manager?Cmd=INFO&Range=ALL" | grep -i $LBGROUP | awk  'BEGIN { FS = "," } ; { print $1,$5 }' 
for NODEID in `curl -s -k "https://$proxy/mod_cluster_manager?Cmd=INFO&Range=ALL" | grep -i $LBGROUP |  awk  '{print $2}' | cut -c 2`; do
curl -s -k "https://$proxy/mod_cluster_manager?Cmd=INFO&Range=ALL" | grep "Context: \[$NODEID"
done
done 
done
done
unset EXIT
EXIT=false
until [ "$EXIT" == "true" ]; do
echo "##############################################"
echo "#############OPERAZIONI SUI SG################"
echo "#                                            #" 
echo "# 1)Abilita SG                               #"
echo "# 2)Disabilita Drain SG (no new sessions)    #"
echo "# 3)Stop SG                                  #"
echo "# 4)Deploy new Version                       #"
echo "#                                            #" 
echo "# e/E)EXIT --> Torna al Menù Principale      #"
echo "#                                            #"
echo "# OPERAZIONE :                               #"
echo "#                                            #"
echo "##############################################" 
echo
seleziona_sg(){
unset SERVERGROUP
sgroups=`$CLI_COMMAND command="/server-group=*:query(select=["profile"],where=["profile","$PROFILE"])" | perl  -lne 'print $1 if /"server-group" => "(.*?)"/'| tr '\n' ' - '`
unset EXIT
EXIT=false
until [ "$EXIT" == "true" ]; do
echo "Inserisci il Server Group su cui operare ---> ("$sgroups"):"
read SERVERGROUP
$CLI_COMMAND command="/server-group=$SERVERGROUP:read-resource" > /dev/null
if [ $? == 0 ]; then
EXIT="true"
else
echo "profile inesistente"
EXIT="false"
fi
done
}
stop_apache_sg(){
		for  SERVER in `$CLI_COMMAND command="/host=*/server=*:query(select=[\"host\"],where=[\"server-group\",\"$SERVERGROUP\"])" | grep result | perl  -lne 'print $1 if /"host" => "(.*?)"/'` ; do
		INSTANCE=`$CLI_COMMAND command="/host=$SERVER/server=*:query(select=["name"])" | perl  -lne 'print $1 if /"name" => "(.*?)"/'`
		echo "Instance:" $INSTANCE
		LBGROUP=`$CLI_COMMAND command="/host=$SERVER/server-config=$INSTANCE/system-property=modcluster.group:read-resource" | perl  -lne 'print $1 if /"value" => "(.*?)"/'`
		echo "LBGroup:" $LBGROUP
		for proxy in `$CLI_COMMAND command="/host=$SERVER/server=$INSTANCE/subsystem=modcluster:list-proxies()" | grep 9000 | sed s/[\,\"]//g` ; do
		echo "Disabilito il ServerGroup:" $SERVERGROUP "sul proxy" $proxy 
		curl -s -k "https://$proxy/mod_cluster_manager?Cmd=STOP-APP&Range=DOMAIN&Domain=$LBGROUP" > /dev/null
		done
		done
}
enable_apache_sg(){

		for  SERVER in `$CLI_COMMAND command="/host=*/server=*:query(select=[\"host\"],where=[\"server-group\",\"$SERVERGROUP\"])" | grep result | perl  -lne 'print $1 if /"host" => "(.*?)"/'` ; do
		INSTANCE=`$CLI_COMMAND command="/host=$SERVER/server=*:query(select=["name"])" | perl  -lne 'print $1 if /"name" => "(.*?)"/'`
		echo "Instance:" $INSTANCE
		LBGROUP=`$CLI_COMMAND command="/host=$SERVER/server-config=$INSTANCE/system-property=modcluster.group:read-resource" | perl  -lne 'print $1 if /"value" => "(.*?)"/'`
		echo "LBGroup:" $LBGROUP
		for proxy in `$CLI_COMMAND command="/host=$SERVER/server=$INSTANCE/subsystem=modcluster:list-proxies()" | grep 9000 | sed s/[\,\"]//g` ; do
		echo "Abilito il ServerGroup:" $SERVERGROUP "sul proxy" $proxy 
		curl -s -k "https://$proxy/mod_cluster_manager?Cmd=ENABLE-APP&Range=DOMAIN&Domain=$LBGROUP" > /dev/null
		done
		done 
}
disable_apache_sg(){
		for  SERVER in `$CLI_COMMAND command="/host=*/server=*:query(select=[\"host\"],where=[\"server-group\",\"$SERVERGROUP\"])" | grep result | perl  -lne 'print $1 if /"host" => "(.*?)"/'` ; do
		INSTANCE=`$CLI_COMMAND command="/host=$SERVER/server=*:query(select=["name"])" | perl  -lne 'print $1 if /"name" => "(.*?)"/'`
		echo "Instance:" $INSTANCE
		LBGROUP=`$CLI_COMMAND command="/host=$SERVER/server-config=$INSTANCE/system-property=modcluster.group:read-resource" | perl  -lne 'print $1 if /"value" => "(.*?)"/'`
		echo "LBGroup:" $LBGROUP
		for proxy in `$CLI_COMMAND command="/host=$SERVER/server=$INSTANCE/subsystem=modcluster:list-proxies()" | grep 9000 | sed s/[\,\"]//g` ; do
		echo "Disabilito il ServerGroup:" $SERVERGROUP "sul proxy" $proxy 
		curl -s -k "https://$proxy/mod_cluster_manager?Cmd=DISABLE-APP&Range=DOMAIN&Domain=$LBGROUP" > /dev/null
		done
		done
}
deploy(){
unset EXIT
echo "deploy"
echo "Applicazioni Presenti sul SG:" $SERVERGROUP
ncountapp=`$CLI_COMMAND command="/server-group=$SERVERGROUP:read-resource" | perl -lne 'print $1 if /"deployment" => ."(.*?)"/' | wc -l`
if [ "$ncountapp" -eq "0" ] ; then
echo "Nessuna applicazione deployed"
else
for application in `$CLI_COMMAND command="/server-group=$SERVERGROUP:read-resource" | perl -lne 'print $1 if /"deployment" => ."(.*?)"/'` ; do
echo "Eseguo undeploy di" $application
$CLI_COMMAND command="undeploy $application --server-groups=$SERVERGROUP --keep-content"
echo
done
fi
echo "Procedo con il deploy, seleziona il war dalla cartella : /opt/scripts/deploy_dir : "
DEPLOY_DIR=/opt/scripts/deploy_dir
ls -la $DEPLOY_DIR
echo
echo "Inserisci file:"
echo
read newapp
echo "Eseguo il deploy di:" $newapp
found=`/b5/data/jboss/bin/jboss-cli.sh -c command="deployment-info --name=$newapp" | awk   '{print $22,$23}' | sed s/\"}}//g`
if [ "$found" == "not found" ] ; then
$CLI_COMMAND command="deploy $DEPLOY_DIR/$newapp --disabled=true --name=$newapp --runtime-name=$newapp"
$CLI_COMMAND command="deploy --name=$newapp --server-groups=$SERVERGROUP"
$CLI_COMMAND command="deployment-info --name=$newapp"
else
$CLI_COMMAND command="deploy --name=$newapp --server-groups=$SERVERGROUP"
$CLI_COMMAND command="deployment-info --name=$newapp"
fi

}
read OPERAZIONE
case "$OPERAZIONE" in
	1)
		echo "abilita SG"
                seleziona_sg
                enable_apache_sg
                mod_cluster_manager_lbgroup
                EXIT=false  
                ;;
	2)
                echo "Disabilto SG"
                seleziona_sg
                disable_apache_sg
                mod_cluster_manager_lbgroup
                EXIT=false  
                ;;
        3)     
                echo "Stoppo SG..."
                seleziona_sg
                stop_apache_sg 
                mod_cluster_manager_lbgroup
                EXIT=false  
                ;;
        4)     
                echo "Deploy"
                seleziona_sg
		echo "Eseguo il deploy sul Serverg Group" $SERVERGROUP
		echo
		echo "Stoppo il Context del Server Group" $SERVERGROUP "sui server apache ? [y/n]"
		read resp
		if [ "$resp" == "y" ] ; then
		echo "procedo con lo stop"
		stop_apache_sg
                deploy
		fi
                unset resp
                echo
                echo "Riavvio i server del ServerGroup: " $SERVERGROUP "[y/n]?" 
                read resp 
                if [ "$resp" == "y" ] ; then
                $CLI_COMMAND command="/server-group=$SERVERGROUP:restart-servers(blocking=true)" 
                fi
                unset resp
                echo "Riabilito il ServerGroup" $SERVERGROUP "sugli apache di FE [y/n]?"
                read resp
		if [ "$resp" == "y" ] ; then
                enable_apache_sg
                fi   
                unset resp
                SERVERGROUP=`echo $sgroups | sed  -r s/.?$SERVERGROUP.?//g`
                echo "Disabilito(DRAIN) il ServerGroup" $SERVERGROUP "sugli apache di FE ? [y/n]"
                read resp
		if [ "$resp" == "y" ] ; then
                disable_apache_sg
                fi   
                mod_cluster_manager_lbgroup
                ;;
	E|e)
		echo "EXIT...BYE"
		EXIT="true"

		;;
        *)   
                echo "Operazione insesistente"
                ;;  

esac
done

}

mod_cluster_manager_lbgroup(){
echo
unset INSTANCE
unset SERVERGROUP
echo "Server Group Associati al profilo:"
echo
$CLI_COMMAND command="/server-group=*:query(select=[\"profile\"],where=[\"profile\",\"$PROFILE\"])" | perl  -lne 'print $1 if /"server-group" => "(.*?)"/'
for  SERVERGROUP in `$CLI_COMMAND command="/server-group=*:query(select=["profile"],where=["profile","$PROFILE"])" | perl  -lne 'print $1 if /"server-group" => "(.*?)"/'`; do
echo -----------------------------------
echo "Host del ServerGroup:" $SERVERGROUP
echo
nservercount=`$CLI_COMMAND command="/host=*/server-config=*:query(select=[\"host\",\"name\"],where=[\"group\",\"$SERVERGROUP\"])" | perl  -lne 'print $1 if /"host" => "(.*?)"/' |wc -l`
if [ "$nservercount" -eq "0" ] ; then
echo "Nessun Server Associato al Server Group"
fi
for  SERVER in `$CLI_COMMAND command="/host=*/server-config=*:query(select=[\"host\",\"name\"],where=[\"group\",\"$SERVERGROUP\"])" | perl  -lne 'print $1 if /"host" => "(.*?)"/'` ; do
echo
echo "Server :" $SERVER
echo "Applicazioni Presenti sul SG:"
ncountapp=`$CLI_COMMAND command="/server-group=$SERVERGROUP:read-resource" | perl -lne 'print $1 if /"deployment" => ."(.*?)"/' | wc -l`
if [ "$ncountapp" -eq "0" ] ; then
echo "Nessuna applicazione deployed"
else
$CLI_COMMAND command="/server-group=$SERVERGROUP:read-resource" | perl -lne 'print $1 if /"deployment" => ."(.*?)"/'
fi
echo
INSTANCE=`$CLI_COMMAND command="/host=$SERVER/server=*:query(select=["name"])" | perl  -lne 'print $1 if /"name" => "(.*?)"/'`
echo "Instance:" $INSTANCE
LBGROUP=`$CLI_COMMAND command="/host=$SERVER/server-config=$INSTANCE/system-property=modcluster.group:read-resource" | perl  -lne 'print $1 if /"value" => "(.*?)"/'`
echo "LBGroup:" $LBGROUP
for proxy in `$CLI_COMMAND command="/host=$SERVER/server=$INSTANCE/subsystem=modcluster:list-proxies()" | grep 9000 | sed s/[\,\"]//g` ; do
echo $proxy
echo "Stato dei SG/LBGroup:"
curl -s -k "https://$proxy/mod_cluster_manager?Cmd=INFO&Range=ALL" | grep -i $LBGROUP | awk  'BEGIN { FS = "," } ; { print $1,$5 }' 
for NODEID in `curl -s "https://$proxy/mod_cluster_manager?Cmd=INFO&Range=ALL" | grep -i $LBGROUP |  awk  '{print $2}' | cut -c 2`; do
curl -s -k "https://$proxy/mod_cluster_manager?Cmd=INFO&Range=ALL" | grep "Context: \[$NODEID"
done
done 
done
done

}

display_all(){
#allprofile=`curl --digest -u "$MGMT_USER:$MGMT_PASS" -s "http://10.8.6.8:9990/management/host" | python -c 'import json,sys;obj=json.load(sys.stdin);print json.dumps(obj["profile"].keys())'`
#for PROFILE in `echo $allprofile  | sed -r s/\\"\|\\\[\|\\\]//g | sed s/\\,\\\s/\\\n/g | grep -v "full|full-ha|ha|ha-TestProfile|HA-ITB-TEMPLATE"` ; do
echo
echo -----------------------
echo "Profilo :" $PROFILE
unset INSTANCE
unset SERVERGROUP
#echo "Server Group:"
#echo
#$CLI_COMMAND command="/server-group=*:query(select=[\"profile\"],where=[\"profile\",\"$PROFILE\"])" | perl  -lne 'print $1 if /"server-group" => "(.*?)"/'
for  SERVERGROUP in `$CLI_COMMAND command="/server-group=*:query(select=["profile"],where=["profile","$PROFILE"])" | perl  -lne 'print $1 if /"server-group" => "(.*?)"/'`; do
#echo "Host del ServerGroup:" $SERVERGROUP
nservercount=`$CLI_COMMAND command="/host=*/server-config=*:query(select=[\"host\",\"name\"],where=[\"group\",\"$SERVERGROUP\"])" | perl  -lne 'print $1 if /"host" => "(.*?)"/' |wc -l`
if [ "$nservercount" -eq "0" ] ; then
echo "Nessun Server Associato al Server Group"
fi
for  SERVER in `$CLI_COMMAND command="/host=*/server-config=*:query(select=[\"host\",\"name\"],where=[\"group\",\"$SERVERGROUP\"])" | perl  -lne 'print $1 if /"host" => "(.*?)"/'` ; do
#echo
#echo "Server :" $SERVER
#echo "Applicazioni Presenti sul SG:"
#ncountapp=`$CLI_COMMAND command="/server-group=$SERVERGROUP:read-resource" | perl -lne 'print $1 if /"deployment" => ."(.*?)"/' | wc -l`
#if [ "$ncountapp" -eq "0" ] ; then
#echo "Nessuna applicazione deployed"
#else
#$CLI_COMMAND command="/server-group=$SERVERGROUP:read-resource" | perl -lne 'print $1 if /"deployment" => ."(.*?)"/'
#fi

INSTANCE=`$CLI_COMMAND command="/host=$SERVER/server-config=*:query(select=["name"])" | perl  -lne 'print $1 if /"name" => "(.*?)"/'`
#echo "Server:" $SERVER
STATE=`$CLI_COMMAND command="/host=$SERVER/server-config=*:read-attribute(name=status)" | perl  -lne 'print $1 if /"result" => "(.*?)"/'`
echo "Nome istanza:" $INSTANCE "Stato:" $STATE
#LBGROUP=`$CLI_COMMAND command="/host=$SERVER/server-config=$INSTANCE/system-property=modcluster.group:read-resource" | perl  -lne 'print $1 if /"value" => "(.*?)"/'`
#echo "LBGroup:" $LBGROUP
#for proxy in `$CLI_COMMAND command="/host=$SERVER/server=$INSTANCE/subsystem=modcluster:list-proxies()" | grep 9000 | sed s/[\,\"]//g` ; do
#echo $proxy
#echo "Stato dei SG/LBGroup:"
#curl -s "http://$proxy/mod_cluster_manager?Cmd=INFO&Range=ALL" | grep -i $LBGROUP | awk  'BEGIN { FS = "," } ; { print $1,$5 }' 
#for NODEID in `curl -s "http://$proxy/mod_cluster_manager?Cmd=INFO&Range=ALL" | grep -i $LBGROUP |  awk  '{print $2}' | cut -c 2`; do
#curl -s "http://$proxy/mod_cluster_manager?Cmd=INFO&Range=ALL" | grep "Context: \[$NODEID"
#done
#done 
done
done
#done
unset exit
exit=0
until [ "$exit" -eq "1" ] ; do
echo "Inserisci l'operazione : [stop/start] "
echo
echo "e ---> EXIT"
echo
read operazione
case "$operazione" in
	start)
              echo "Inserisci il nome dell'istanza da avviare:" 
              read INSTANCE
	      host=`$CLI_COMMAND command="/host=*/server-config=*:query(select=["name"],where=[\"name\",\"$INSTANCE\"])" | perl  -lne 'print $1 if /"host" => "(.*?)"/'`
              $CLI_COMMAND command="/host=$host/server-config=$INSTANCE:start(blocking=true)" > /dev/null  
	      STATE=`$CLI_COMMAND command="/host=$host/server-config=*:read-attribute(name=status)" | perl  -lne 'print $1 if /"result" => "(.*?)"/'`
	      echo "Instance:" $INSTANCE "Stato:" $STATE
              ;;
        stop)
              echo "Inserisci il nome dell'istanza da fermare :" 
              read INSTANCE
	      host=`$CLI_COMMAND command="/host=*/server-config=*:query(select=["name"],where=[\"name\",\"$INSTANCE\"])" | perl  -lne 'print $1 if /"host" => "(.*?)"/'`
              $CLI_COMMAND command="/host=$host/server-config=$INSTANCE:stop(blocking=true,timeout=10)" > /dev/null  
	      STATE=`$CLI_COMMAND command="/host=$host/server-config=*:read-attribute(name=status)" | perl  -lne 'print $1 if /"result" => "(.*?)"/'`
	      echo "Instance:" $INSTANCE "Stato:" $STATE
              ;;
           e)
              exit=1
              ;; 
          
esac
done
           				
echo "Premere un tasto per continuare"
read


}

crea_ServerGroup(){
clear
SG=0
until [ "$SG" -eq "2" ] ;  do
echo "1)Aggiungi in EAP un nuovo Server Group"
echo "2)- EXIT -"
unset SERVERGROUP
unset PROFILE
unset RESPONSE
read SG
case "$SG" in
            1)
        	until [ "$RESPONSE" == "y" ] ; do
                clear
                echo "Server Group Presenti"
                echo
		$CLI_COMMAND command="/server-group=*:query(select=["profile"])" | perl  -lne 'print $1 if /"server-group" => "(.*?)"/'
                echo
                echo "Inserisci il nome del nuovo ServerGroup:(ex: sg-XXXXX - CTRL-C per terminare):"
        	read SERVERGROUP
        	$CLI_COMMAND command="/server-group=$SERVERGROUP:read-resource" > /dev/null
        	if  [ $? -eq 0 ] ; then
        	echo "Server Group già Presente"
                echo "Premere un tasto per continuare"
        	read 
        	else
        	echo "Profili Presenti:" 
		curl --digest -u "$MGMT_USER:$MGMT_PASS" -s "http://10.8.6.8:9990/management/profile=*" | python -c 'import json,sys;obj=json.load(sys.stdin);print json.dumps(obj["profile"].keys())' | sed s/\"//g
        	echo
        	echo "Inserisci il profile da associare al ServerGroup: (ex: ha-orc)"
        	read PROFILE  
        	$CLI_COMMAND command="/profile=$PROFILE:read-resource" > /dev/null 
        	if  [ $? -eq 0 ] ; then 
        	echo "ServerGroup Inserito:"$SERVERGROUP "Profilo:" $PROFILE "Continuo (y/n)"
        	read RESPONSE
        	else
        	echo "Profilo non esistente"   
                echo "Premere un tasto per continuare"
                read
        	fi
        	fi
        	done
        	$CLI_COMMAND command="/server-group=$SERVERGROUP:add(profile=$PROFILE,socket-binding-group=$PROFILE-sockets)"  
                unset RESP
        	until [ "$RESP" == "y" ] ; do
                echo "Inserisci la HeapSize delle JVM associare al ServerGorup: (default : 2048 )"
                read heapsize
                if [ -z "$heapsize" ]; then
                heapsize=2048 
                fi  
                echo "Heap Size inserita:" $heapsize "Continuo (y/n)" 
                read RESP 
                done
                $CLI_COMMAND command="/server-group=$SERVERGROUP/jvm="$SERVERGROUP"_jvm:add(heap-size="$heapsize"m,jvm-options=[\"-XX:MetaspaceSize=512M\",\"-XX:MaxMetaspaceSize=512M\",\"-server\",\"-verbose:gc\",\"-Xloggc:/b5/log/jboss/gc/gc-eap-instance.log\",\"-XX:+PrintGCDetails\",\"-XX:+PrintGCDateStamps\"],max-heap-size="$heapsize"m)" 
                  
                echo  
                echo "MULTICAST ADDRESS: Indirizzi assegnati ad altri Server Group:"
                echo
                for multicast in  `$CLI_COMMAND command="/server-group=*:query(select=["profile"])" | perl  -lne 'print $1 if /"server-group" => "(.*?)"/'` ; do
        	$CLI_COMMAND command="/server-group=$multicast/system-property=jboss.default.multicast.address:read-attribute(name=value)" > /dev/null
        	if  [ $? -eq 0 ] ; then
                echo $multicast
                echo
                $CLI_COMMAND command="/server-group=$multicast/system-property=jboss.default.multicast.address:read-attribute(name=value)" 
               fi
done
                echo "Inserisci l'indirizzo Multicast:ex(230.0.0.XX)"
                echo  
                read multicastaddr
                $CLI_COMMAND command="/server-group=$SERVERGROUP/system-property=jboss.default.multicast.address:add(value=$multicastaddr)"

                echo "Premere un tasto per continuare"
                read
        ;; 
	esac
clear
done



}

add_dataSources(){
clear
DS=0
until [ "$DS" -eq "3" ] ;  do
echo "Selezione il DataSource da associare al profilo:"
echo "1)orchestratorDS"
echo "2)backofficeDS"
echo "3)Nessun DS - EXIT -"
read DS
case "$DS" in
        1)
                echo "CREO DS orchestratorDS"
                $CLI_COMMAND --command="/profile=$PROFILE/subsystem="datasources"/data-source="orchestratorDS":add(background-validation="false",connection-url="jdbc:sqlserver:\/\/B5BPRDVDB02.ITBPROD.LOC\\\\\ANAG\;DatabaseName\\=MasterData",driver-name="SQLServer",enabled="true",exception-sorter-class-name="org.jboss.jca.adapters.jdbc.extensions.mssql.MSSQLExceptionSorter",jndi-name="java:/jboss/datasources/b5db",jta="true",max-pool-size="50",min-pool-size="10",password="$\{VAULT::orchestratorDS::password::1\}",use-ccm="true",user-name="MasterData",valid-connection-checker-class-name="org.jboss.jca.adapters.jdbc.extensions.mssql.MSSQLValidConnectionChecker",validate-on-match="true,statistics-enabled=true")"
                ;;
        2)
                echo "creo backofficeDS"
                $CLI_COMMAND --command="/profile=$PROFILE/subsystem="datasources"/data-source="backofficeDS":add(background-validation="false",connection-url="jdbc:sqlserver://B5BPRDVDB03.ITBPROD.LOC\\\\\STOR\;DatabaseName\\=BackofficeGUI",driver-name="SQLServer",enabled="true",exception-sorter-class-name="org.jboss.jca.adapters.jdbc.extensions.mssql.MSSQLExceptionSorter",jndi-name="java:/jboss/datasources/b5off-mssql",jta="true",max-pool-size="50",min-pool-size="10",password="$\{VAULT::backofficeDS::password::1\}",use-ccm="true",user-name="BackOfficeGUI",valid-connection-checker-class-name="org.jboss.jca.adapters.jdbc.extensions.mssql.MSSQLValidConnectionChecker",validate-on-match="true",statistics-enabled="true")"
                ;;
        *)
                ;;

esac
done

}

modcluster() {
clear
MC=0
until [ "$MC" -eq "2" ] ;  do
echo "1)Aggiungi in EAP un istanza apache (proxy)"
echo "2)- EXIT -"
read MC
case "$MC" in
	1)
        echo "Attendere...."
        RESPONSE=n
        until [ "$RESPONSE" == "y" ] ; do
        PROXY=0
        until  [ $? != 0 ] ; do
        PROXY=$[$PROXY+1]
        $CLI_COMMAND command="/socket-binding-group=$PROFILE-sockets/remote-destination-outbound-socket-binding=proxy$PROXY:read-resource" > /dev/null
        done
        for  (( nproxy=1; nproxy<$PROXY; nproxy++ )) ; do
        echo "Indirizzi IP Apache HTTPD presenti :"  
        $CLI_COMMAND command="/socket-binding-group=$PROFILE-sockets/remote-destination-outbound-socket-binding=proxy$nproxy:read-attribute(name=host)" 
        echo "PROXY:" $nproxy
        done
        echo "Inserisci hostname(DNS) o IP ADDRESS dell'istanza httpd/Apache" 
        read IPADDRESS
        echo "Indirizzo IP inserito:" $IPADDRESS "Continuo (y/n)"
        read RESPONSE
        done
        
        
        $CLI_COMMAND command="/socket-binding-group=$PROFILE-sockets/remote-destination-outbound-socket-binding=proxy$PROXY:add(host=$IPADDRESS,port=9000)"
        $CLI_COMMAND command="/profile=$PROFILE/subsystem=modcluster/mod-cluster-config=configuration:list-add(name=proxies,value=proxy$PROXY)"
        echo "Aggiunto Proxy :" $PROXY "con IP:" $IPADDRESS "Eseguire il restart delle istanze per rendere effettive le modifiche"
        echo "Premere un tast per continuare"
        read
	;;
esac
clear
done
}

visualizza_proxy() {
        echo "Attendere alcuni secondi..."
        PROXY=0
        until  [ $? != 0 ] ; do
        PROXY=$[$PROXY+1]
        $CLI_COMMAND command="/socket-binding-group=$PROFILE-sockets/remote-destination-outbound-socket-binding=proxy$PROXY:read-resource" > /dev/null
        done
        for  (( nproxy=1; nproxy<$PROXY; nproxy++ )) ; do
        echo "Indirizzi IP Apache HTTPD presenti :"  
        $CLI_COMMAND command="/socket-binding-group=$PROFILE-sockets/remote-destination-outbound-socket-binding=proxy$nproxy:read-attribute(name=host)" 
        echo "PROXY:" $nproxy
        done
        echo "Premere un Tasto Per continuare..."
        read
	
}

crea_profilo() { 
clear
echo "Creo Profilo"
echo
echo "Questo Script crea un nuovo profile clonando l'HA-ITB-TEMPLATE"
echo "permette inoltre di aggiungere le componenti ITB (DataSource, Socket Binding) .. "
echo
echo "Profili Esistenti:"
echo
curl --digest -u "$MGMT_USER:$MGMT_PASS" -s "http://10.8.6.8:9990/management/profile=*" | python -c 'import json,sys;obj=json.load(sys.stdin);print json.dumps(obj["profile"].keys())' | sed s/\"//g
echo
EXIST=1
until [ "$EXIST" -eq "0" ] ; do
echo "Inserisci il nome del nuovo Profilo : ex ( ha-batch):"
read PROFILE
echo 
$CLI_COMMAND command="/profile=$PROFILE:read-resource(attributes-only=true)" > /dev/null 
if [ $? == 0 ]; then
echo "Profilo già presente selezionare nuovo nome profilo"
echo
echo "Premere un tasto per continuare..."
read
clear
else
echo "Eseguo il backup del domain.xml"
$CLI_COMMAND command=":take-snapshot()"
echo
$CLI_COMMAND command="/profile=HA-ITB-TEMPLATE:clone(to-profile=$PROFILE)"
if [ $? == 0 ]; then
echo "Profilo Creato correttamente"
else
echo "Errore di creazione, controllare Log files..."
fi
EXIST=0
fi
done

EXIT=0
until [ "$EXIT" -eq "1" ] ; do
echo "Creo il nuovo e relativo SocketBinding [$PROFILE-sockets] ? (Y/N)"
read RESPONSE
case "$RESPONSE" in
        y|Y)
        echo "Creo socket binding clonando ha-socket"
        echo
        echo "Attendere....." 
        $CLI_COMMAND command="/socket-binding-group=$PROFILE-sockets/:read-resource" > /dev/null 
        if [ $? == 0 ]; then
        echo "Socket-Binding già presente"
        echo "Premere un tasto per continuare..."
        read  
        add_dataSources       
        modcluster
        EXIT=1 
	else
	$CLI_COMMAND command="/socket-binding-group=$PROFILE-sockets/:add(default-interface=public)" > /dev/null
	$CLI_COMMAND command="/socket-binding-group=$PROFILE-sockets/socket-binding=ajp/:add(port=8009,fixed-port=false)" > /dev/null
	$CLI_COMMAND command="/socket-binding-group=$PROFILE-sockets/socket-binding=http/:add(port=8080,fixed-port=false)" > /dev/null
	$CLI_COMMAND command="/socket-binding-group=$PROFILE-sockets/socket-binding=https/:add(port=8443,fixed-port=false)" > /dev/null
	$CLI_COMMAND command="/socket-binding-group=$PROFILE-sockets/socket-binding=jgroups-mping/:add(interface=private,port=0,fixed-port=false,multicast-address=$\{jboss.default.multicast.address:230.0.0.4\},multicast-port=45700)" > /dev/null
	$CLI_COMMAND command="/socket-binding-group=$PROFILE-sockets/socket-binding=jgroups-tcp/:add(port=7600,fixed-port=false)" > /dev/null
	$CLI_COMMAND command="/socket-binding-group=$PROFILE-sockets/socket-binding=jgroups-tcp-fd/:add(port=57600,fixed-port=false)" > /dev/null
	$CLI_COMMAND command="/socket-binding-group=$PROFILE-sockets/socket-binding=jgroups-udp/:add(port=55200,fixed-port=false,multicast-address=$\{jboss.default.multicast.address:230.0.0.4\},multicast-port=45688)" > /dev/null
	$CLI_COMMAND command="/socket-binding-group=$PROFILE-sockets/socket-binding=jgroups-udp-fd/:add(interface=private,port=54200,fixed-port=false)" > /dev/null
	$CLI_COMMAND command="/socket-binding-group=$PROFILE-sockets/socket-binding=modcluster/:add(port=0,fixed-port=false,multicast-address=224.0.1.105,multicast-port=23364)" > /dev/null
	$CLI_COMMAND command="/socket-binding-group=$PROFILE-sockets/socket-binding=txn-recovery-environment/:add(port=4712,fixed-port=false)" > /dev/null
	$CLI_COMMAND command="/socket-binding-group=$PROFILE-sockets/socket-binding=txn-status-manager/:add(port=4713,fixed-port=false)" > /dev/null
	$CLI_COMMAND command="/socket-binding-group=$PROFILE-sockets/remote-destination-outbound-socket-binding=mail-smtp/:add(host=localhost,port=25)" > /dev/null
	$CLI_COMMAND command="/socket-binding-group=$PROFILE-sockets/remote-destination-outbound-socket-binding=mail-b5-smtp/:add(host=mx1.bancaitb.it,port=25)" > /dev/null
	echo "Socket Binding Creato co successo."
	echo
	echo " Premere un tasto per continuare..."
        read
        add_dataSources
        modcluster
        EXIT=1
        fi
        ;;
        n|N)
        add_dataSources  
        modcluster
        EXIT=1
        ;;
        *)

esac

done

}               
HostController() { 
clear
echo "Inizializzazione Nuovi HostController: Configurazione Vault - Server Group - ModCluster [CTRL-C per terminare]"
echo
echo "Host Presenti:"
echo
echo `curl --digest -u "$MGMT_USER:$MGMT_PASS" -s "http://10.8.6.8:9990/management/host" | python -c 'import json,sys;obj=json.load(sys.stdin);print json.dumps(obj["host"].keys())'` | sed s/[\",]//g
echo
echo "Inserisci l'HostName del nuovo HostController : (ex: b5bprdljorc02.itbprod.loc) "
read HC
$CLI_COMMAND command="/host=$HC:read-resource" > /dev/null
if  [ $? -eq 0 ] ; then
curl --digest -u "$MGMT_USER:$MGMT_PASS" -s "http://10.8.6.8:9990/management/host/$HC/server-config=*" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["server-config"].keys()' > /dev/null 2>&1
if  [ $? -eq 0 ] ; then
echo "Il Server" $HC "Risulta già configurato. Controllare"
instance=`curl --digest -u "$MGMT_USER:$MGMT_PASS" -s "http://10.8.6.8:9990/management/host/$HC/server-config=*" | python -c 'import json,sys;obj=json.load(sys.stdin);print json.dumps(obj["server-config"].keys()[0])'`
echo "Istanza :" $instance
echo
$CLI_COMMAND command="/host=$HC/server-config=$instance:read-attribute(name=name)"
echo
echo "Eliminare l'istanza associata all'Host controller" $HC "? y/n"
read RISP
if [ "$RISP" == "y" ] ; then
echo "Elimino l'istanza:"
$CLI_COMMAND command="/host=$HC/server-config=$instance:stop" 
$CLI_COMMAND command="/host=$HC/server-config=$instance:remove"
echo
echo "Premere un tasto per continuare"
read
else 
echo "Esco..."
exit 0
fi

fi
echo "Inserisci il nome del ServerGroup da associare al nuovo HostController: (ex: sg-orc)"
echo
echo "Server Group Esistenti:"
curl --digest -u "$MGMT_USER:$MGMT_PASS" -s "http://10.8.6.8:9990/management/server-group" | python -c 'import json,sys;obj=json.load(sys.stdin);print json.dumps(obj["server-group"].keys())' | sed s/[\",]//g
#$CLI_COMMAND command="/server-group=*:read-attribute-group(name=*)"
echo "Inserisci il Server Group:"
read SERVERGROUP
$CLI_COMMAND command="/server-group=$SERVERGROUP:read-resource" > /dev/null
if  [ $? -eq 0 ] ; then
echo "Inizializzo l'Host Controller"

INSTANCENUMBER=`echo $HC | cut -d "." -f 1 | tail -c 3`
INSTANCENAME=`echo $SERVERGROUP | cut -d "-" -f 2,3 | head -c -3`
INSTANCEDEFAULT=$INSTANCENAME$INSTANCENUMBER

unset RESP
until [ "$RESP" == "y" ] ; do
                echo "Inserire il nome istanza o premere invio per utilizzare il nome ricavato :  ---> :"$INSTANCEDEFAULT")"
                read INSTANCE
                if [ -z "$INSTANCE" ]; then
                INSTANCE=$INSTANCEDEFAULT
                fi  
                echo "Nome dell'Istanza:" $INSTANCE "Continuo (y/n)" 
                read RESP 
                done
unset RESP
unset RISP


until [ "$RESP" == "y" ] ; do
                LBGROUP=lb-$INSTANCENAME
                echo "Selezionare il Cluster-LBGroup corrispondende : "
                echo
                echo "1) LBGroup:" $LBGROUP"01" 
		echo "2) LBGroup:" $LBGROUP"02"
                echo
                echo "Seleziona 1 o 2"
                read RISP
		case "$RISP" in
		1)
                LBGROUP=$LBGROUP"01"
		;;
		2) 
                LBGROUP=$LBGROUP"02"
		;;
                esac
                echo "LBGroup:" $LBGROUP "Continuo (y/n)" 
                read RESP 
                done

echo "Inizializzo il nuovo Host Controller utilizzando i seguenti parametri:"
echo "ServerGroup:" $SERVERGROUP
echo "INSTANCE-ID:" $INSTANCE
echo "ModCluster-LBGroup": $LBGROUP
echo
echo "Premere un tasto per continuare. (CTRL-C per terminare) "
read
$CLI_COMMAND command="/host=$HC/core-service=vault:add(vault-options=["KEYSTORE_URL"=>"/b5/data/jboss/vault/vault.keystore","KEYSTORE_PASSWORD"=>"MASK-2nVme0NY5Fu6dZnXzlqtQd","KEYSTORE_ALIAS"=>"vault","SALT"=>"24681357","ITERATION_COUNT"=>"95","ENC_FILE_DIR"=>"/b5/data/jboss/vault/"])" > /dev/null
$CLI_COMMAND command="/host=$HC/server-config=$INSTANCE:add(group=$SERVERGROUP,auto-start=true,socket-binding-port-offset="0")"
$CLI_COMMAND command="/host=$HC/server-config=$INSTANCE/system-property=modcluster.group:add(value="$LBGROUP",boot-time="true")"
$CLI_COMMAND command="/host=$HC/server-config=$INSTANCE/system-property=jboss.instance.id:add(value="$INSTANCE",boot-time="true")"
$CLI_COMMAND command="/host=$HC/server-config=$INSTANCE:stop"
$CLI_COMMAND command="/host=$HC/server-config=$INSTANCE:start"

echo "Procedura Terminata"
echo "Premere un tasto per tornare al menu.."
read
else
echo "Server Group Non Esistente"

fi

else
echo "HC non connesso al Domain"
fi
}               

until ( "$WHAT" == "E" );  do

clear
echo "###########################################################"
echo "#   1) Crea nuovo Profilo                                 #"
echo "#   2) Crea nuovi Server Group                            #"
echo "#   3) Configura/Riconfigura  Host Controller             #"
echo "#   4) Visualizza proxy associati ad un profilo           #"
echo "#   5) Aggiungi proxy ad un profilo esistente             #"
echo "#   6) Aggiungi DataSource --- DA CONSOLE                 #"
echo "#   7) Display Domain configuration Changes               #"
echo "#   8) Visualizza stato SG/APP - DEPLOY new app           #"
echo "#      Abilita/disabilita/Stop ModCluster                 #"
echo "#   9) Stop/Start JBOSS Server Instance (JVM)             #"
echo "#   10) Stop/Start Server Group (ancora da implementare)  #"
echo "#                                                         #"
echo "#   E/e) Exit                                             #"
echo "###########################################################"

read WHAT  

case "$WHAT" in
	1)
		crea_profilo
		;;
	2)
                crea_ServerGroup
		;;
	3)
                HostController
		;;
	4)
                clear
                        echo "Profili Presenti:"
                	echo
			curl --digest -u "$MGMT_USER:$MGMT_PASS" -s "http://10.8.6.8:9990/management/host" | python -c 'import json,sys;obj=json.load(sys.stdin);print json.dumps(obj["profile"].keys())' | sed s/\"//g
                        echo
        		echo "Inserisci il nome del profile EAP ex(ha-orc)"
        		read PROFILE
                        visualizza_proxy
		;;
	5)
                clear
        		SPONSE=n
        		until [ "$RESPONSE" == "y" ] ; do
                        echo "Profili Presenti:"
                	echo
			curl --digest -u "$MGMT_USER:$MGMT_PASS" -s "http://10.8.6.8:9990/management/host" | python -c 'import json,sys;obj=json.load(sys.stdin);print json.dumps(obj["profile"].keys())' | sed s/\"//g
                        echo
        		echo "Inserisci il nome del profile EAP ex(ha-orc)"
        		read PROFILE
        		echo "Profile inserito:" $PROFILE "Continuo (y/n)"
        		read RESPONSE
        		done
        		$CLI_COMMAND command="/profile=$PROFILE:read-resource" > /dev/null
                        if [ $? -eq 0 ] ; then
                        modcluster
                        else
                        echo "Profile non esistente"
                        echo "Premere un tasto per continuare"
                        read
                        fi    
		;;
        6)
        echo "Questa operazione viene meglio da console...."
        echo "Premere un tasto per continuare"
        read
        ;;
        7)
        $CLI_COMMAND command="/core-service=management/service=configuration-changes:list-changes"
        echo "Premere un tasto per continuare"
        read
        ;;
        8)
        manage_mod_cluster_manager_lbgroup
        echo "Premere un tasto per continuare"
        read
        ;; 
        9)
	unset SERVERGROUP
	unset PROFILE
	unset RESPONSE
	unset EXIT
	clear
	echo "Inserisci il nome del profilo su cui operare:"
	echo
	echo "Profili Presenti:"
	echo
	curl --digest -u "$MGMT_USER:$MGMT_PASS" -s "http://10.8.6.8:9990/management/host" | python -c 'import json,sys;obj=json.load(sys.stdin);print json.dumps(obj["profile"].keys())' | sed s/\"//g
	EXIT=false
	until [ "$EXIT" == "true" ]; do
	echo "Seleziona il profilo:"
	read PROFILE
	$CLI_COMMAND command="/profile=$PROFILE:read-resource(attributes-only=true)" > /dev/null
	if [ $? == 0 ]; then
	EXIT="true"
	else
	echo "Profilo inesistente"
	fi
        done
        display_all
        ;; 
	E|e)
		echo "EXIT...BYE"
		exit 0
		;;
	*)
		echo "Selezione non trovata"
                echo
                echo "Premere un tasto per Tornare al Menu"
                read
esac
done
 


