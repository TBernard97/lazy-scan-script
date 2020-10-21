#!/bin/bash

####################################################################
############# INITIAL VARIABLES ####################################
PATH_TO_NMAP_PARSE_OUTPUT="/opt/nmap-parse-output/nmap-parse-output"
NMAP_TIME=-T4
GOBUSTER_OUTPUT="./gobuster.txt"
NMAP_OUTPUT="./nmap.txt"
NMAP_PARSE_OUTPUT="./nmap_parse.txt"
###################################################################
###################################################################

usage(){
    echo "[?] Usage $0 -h [host] [OTHER FLAGS]."
    echo "[?] -h: Host or IP."
    echo "[?] -v: nmap version scan."
    echo "[?] -g: gobuster if 80, 443, or 8080 open."
    echo "[?] -w: wordlist for gobuster."
    echo "[?] -s: smbmap if 445 open."
    exit 1
}
gobust(){
    IFS=',' read -r -a array <<< $OPEN_PORTS

    if [[ " ${array[@]} " =~ "80" ||  " ${array[@]} " =~ "443" || " ${array[@]} " =~ "8080" ]]; then
        if [ ! -z "$wordlist" ] 
            then
            gobuster -u http://${host} -w $wordlist -o $GOBUSTER_OUTPUT
        elif [  -z "$wordlist" ]  
            then
                echo "[ERROR] Need a wordlist for gobuster. Use -w flag."
        fi
        else
            echo "[ERROR] No Standard HTTP ports found."
    
    fi
}

smap(){
    IFS=',' read -r -a array <<< $OPEN_PORTS

    if [[ " ${array[@]} " =~ "445" ]]; then
            smbmap -H $host
        else
            echo "[ERROR] No Standard SMB ports found."
    fi
}

version_scan(){

    echo "[+] Doing version scan on open ports"
    nmap -sS -sV -p$OPEN_PORTS -oN $NMAP_OUTPUT -oX nmap.xml $host
    
    if test -f $NMAP_PARSE_OUTPUT; then
        rm $NMAP_PARSE_OUTPUT
    fi

    echo "###################### PORT INFO #########################################" >> $NMAP_PARSE_OUTPUT
    IFS=',' read -r -a array <<< $OPEN_PORTS

    for port in ${array[@]}
    do
        echo $(${PATH_TO_NMAP_PARSE_OUTPUT} nmap.xml port-info ${port}) >> $NMAP_PARSE_OUTPUT
    done
    echo "##########################################################################" >> $NMAP_PARSE_OUTPUT

    echo $'\n' >> $NMAP_PARSE_OUTPUT

    echo "###################### HTTP PORTS #########################################" >> $NMAP_PARSE_OUTPUT
    echo $(${PATH_TO_NMAP_PARSE_OUTPUT} nmap.xml http-ports) >> $NMAP_PARSE_OUTPUT
    echo "##########################################################################" >> $NMAP_PARSE_OUTPUT

    echo $'\n' >> $NMAP_PARSE_OUTPUT

    echo "###################### SERVICE NAMES ######################################" >> $NMAP_PARSE_OUTPUT
    echo $(${PATH_TO_NMAP_PARSE_OUTPUT} nmap.xml service-names) >> $NMAP_PARSE_OUTPUT
    echo "###########################################################################" >> $NMAP_PARSE_OUTPUT

    echo $'\n' >> $NMAP_PARSE_OUTPUT

    echo "###################### PRODUCTS ###########################################" >> $NMAP_PARSE_OUTPUT
    echo $(${PATH_TO_NMAP_PARSE_OUTPUT} nmap.xml product) >> $NMAP_PARSE_OUTPUT
    echo "###########################################################################" >> $NMAP_PARSE_OUTPUT

}

while getopts h:vgw:s flag
do
    case "${flag}" in
        h ) host=${OPTARG};;
        v ) version=1;;
        g ) gobust=1;;
        w ) wordlist=${OPTARG};;
        s)  smbmap_flag=1;;
        \?) echo "[?] Invalid flag"
    esac
done

shift $((OPTIND-1))

if [  -z "$host" ]; then
    usage
fi

nmap -Pn -oX nmap.xml $NMAP_TIME $host
OPEN_PORTS=$(${PATH_TO_NMAP_PARSE_OUTPUT} nmap.xml ports)
echo "[!] Open ports found: ${OPEN_PORTS}."



if [[ "${version}" -eq 1 ]]; then
    version_scan
fi


if [[ "${gobust}" -eq 1 ]]; then
    gobust
fi

if [[ "${smbmap_flag}" -eq 1 ]]; then
    smap
fi


