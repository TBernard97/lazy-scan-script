#!/bin/bash

####################################################################
############# INITIAL VARIABLES ####################################
PATH_TO_NMAP_PARSE_OUTPUT="/opt/nmap-parse-output/nmap-parse-output"
NMAP_TIME=-T4
GOBUSTER_OUTPUT="./gobuster.txt"
NMAP_OUTPUT="./nmap.txt"
NMAP_PARSE_OUTPUT="./nmap_parse.txt"
ASSETFINDER_DIRECTORY="/home/nomad/Tools/assetfinder/"
HTTPROBE_DIRECTORY="/home/nomad/Tools/httprobe/"
###################################################################
###################################################################

usage(){
    echo "[?] Usage $0 -h [host] [OTHER FLAGS]."
    echo "[?] -h: Host or IP."
    echo "[?] -v: nmap version scan."
    echo "[?] -g: gobuster if 80, 443, or 8080 open."
    echo "[?] -w: wordlist for gobuster."
    echo "[?] -s: smbmap if 445 open."
    echo "[?] -r: perform automated recon against a domain"
    exit 1
}

initial_scan(){

    nmap -Pn -oX nmap.xml $NMAP_TIME $host
    OPEN_PORTS=$(${PATH_TO_NMAP_PARSE_OUTPUT} nmap.xml ports)
    echo "[!] Open ports found: ${OPEN_PORTS}."
}

gobust(){

    initial_scan
    IFS=',' read -r -a array <<< $OPEN_PORTS

    if [[ " ${array[@]} " =~ "80" ||  " ${array[@]} " =~ "443" || " ${array[@]} " =~ "8080" ]]; then
        if [ ! -z "$wordlist" ] 
            then
            gobuster dir -u http://${host} -w $wordlist -o $GOBUSTER_OUTPUT
        elif [  -z "$wordlist" ]  
            then
                echo "[ERROR] Need a wordlist for gobuster. Use -w flag."
        fi
        else
            echo "[ERROR] No Standard HTTP ports found."
    
    fi
}

smap(){
    initial_scan
    IFS=',' read -r -a array <<< $OPEN_PORTS

    if [[ " ${array[@]} " =~ "445" ]]; then
            smbmap -H $host
        else
            echo "[ERROR] No Standard SMB ports found."
    fi
}

version_scan(){
    initial_scan
    echo "[+] Doing version scan on open ports"
    sudo nmap -sS -sV -p$OPEN_PORTS -oN $NMAP_OUTPUT -oX nmap.xml $host
    
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

recon(){
    #Used several lines of code from https://pastebin.com/MhE6zXVt

    if [ ! -d "$host" ]; then
	    mkdir $host
    fi

    if [ ! -d "$host/recon" ]; then
        mkdir "$host/recon"
    fi

     if [ ! -d "$host/recon" ]; then
        mkdir "$host/recon"
    fi

     if [ ! -d "$host/recon/httprobe" ]; then
        mkdir "$host/recon/httprobe"
    fi

    echo "[+] Starting intial recon with assetfinder"
    "$ASSETFINDER_DIRECTORY/assetfinder" $host >> $host/recon/final.txt

    echo "[+] Running additional subdomain checks with amass, this may take a while.."
    amass enum -d $host >> $host/recon/f.txt
    sort -u $host/recon/f.txt >> $host/recon/final.txt
    rm $host/recon/f.txt

    echo "[+] Final checks for alive domains"
    cat $host/recon/final.txt | sort -u | "$HTTPROBE_DIRECTORY/httprobe" -s -p https:443 | sed 's/https\?:\/\///' | tr -d ':443' >> $host/recon/httprobe/a.txt
    sort -u $host/recon/httprobe/a.txt > $host/recon/httprobe/alive.txt
    rm $host/recon/httprobe/a.txt


}

while getopts h:rvgw:s flag
do
    case "${flag}" in
        h ) host=${OPTARG};;
        v ) version=1;;
        g ) gobust=1;;
        w ) wordlist=${OPTARG};;
        s ) smbmap_flag=1;;
        r ) recon=1;;
        n ) initial=1;;
        \?) echo "[?] Invalid flag"
    esac
done

shift $((OPTIND-1))

if [  -z "$host" ]; then
    usage
fi

if [[ "${initial}" -eq 1 ]]; then
    initial_scan
fi

if [[ "${version}" -eq 1 ]]; then
    version_scan
fi


if [[ "${gobust}" -eq 1 ]]; then
    gobust
fi

if [[ "${smbmap_flag}" -eq 1 ]]; then
    smap
fi

if [[ "${recon}" -eq 1 ]]; then
    recon
fi
