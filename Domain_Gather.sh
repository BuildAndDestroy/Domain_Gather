#!/bin/bash

if [ $(id -u) != 0 ]; then
    echo 'Please run as root'
    exit
fi


if [ $# -eq 0 ]; then
    echo Help Menu
    echo "-p    Print records to Terminal."
    echo "-d    Send Domain Records to a text file."
    echo "-n    Nmap, the A record, soft and aggressively."
    echo "-f    Fierce DNS attempt to extract zone file."
    echo "-a    Run all options. Time Consuming!"
    exit
fi

function BuildDirectory () {
if [ ! -d /root/Hack/ ]; then
    mkdir -p /root/Hack/
fi

if [ ! -d root/Hack/$domainName ]; then
    mkdir -p /root/Hack/$domainName/
fi
}


function PullDomain () {
    read -r -p '>>> ' domainName
}

function ARecordF () {
    ARecord=$(dig A $domainName | grep $domainName | awk 'NR==3' | awk '{print $5}')
    echo $ARecord
}

function MXRecordF () {
    MXRecord=$(dig MX $domainName | grep $domainName | sed '1,2d' | awk '{print $5,$6}' | sort | sed 's/^/Priority:\ /g')
    echo $MXRecord
}

function NSRecordF () {
    NSRecord=$(dig NS $domainName | grep $domainName | sed '1,2d' | awk '{print $5,$6}' | sort)
    echo $NSRecord
}

function TXTRecordF () {
    TXTRecord=$(dig TXT $domainName | grep $domainName | sed '1,2d' | awk '{$1=$2=$3=$4=""; print $0}' | sed 's/^ *//g')
    echo $TXTRecord
}


function allDNSRecordsToTerminal () {
###Print out Domain Info To Terminal###
    echo ''
    echo $(tput setaf 2)$domainName$(tput sgr0)
    echo ''
    echo $(tput setaf 6)A Record$(tput sgr0)
    ARecordF
    echo ''
    echo $(tput setaf 6)MX Record$(tput sgr0)
    MXRecordF | sed 's/^/>/g' | sed 's/Priority/\n\Priority/g' | sed '1d'
    echo ''
    echo $(tput setaf 6)Name Servers$(tput sgr0)
    NSRecordF | sed 's/\ /\n/g'
    echo ''
    echo $(tput setaf 6)TXT Records$(tput sgr0)
    TXTRecordF | sed 's/"\ "/"\n"/g'
}

function DomainFileF () {
    ###Domain_Records.txt###
    echo ''
    echo Sending zone file details to /root/Hack/$domainName/Domain_Records.txt

    BuildDirectory

    echo $domainName > /root/Hack/$domainName/Domain_Records.txt
    echo '' >> /root/Hack/$domainName/Domain_Records.txt

    echo '> A Record' >> /root/Hack/$domainName/Domain_Records.txt
    echo $(ARecordF) >> /root/Hack/$domainName/Domain_Records.txt
    echo '' >> /root/Hack/$domainName/Domain_Records.txt

    echo '> MX Records' >> /root/Hack/$domainName/Domain_Records.txt
    echo $(MXRecordF) | sed 's/^/>/g' | sed 's/Priority/\n\Priority/g' | sed '1d' >> /root/Hack/$domainName/Domain_Records.txt
    echo '' >> /root/Hack/$domainName/Domain_Records.txt

    echo '> Name Servers' >> /root/Hack/$domainName/Domain_Records.txt
    echo $(NSRecordF) | sed 's/\ /\n/g' >> /root/Hack/$domainName/Domain_Records.txt
    echo '' >> /root/Hack/$domainName/Domain_Records.txt

    echo '> TXT Records' >> /root/Hack/$domainName/Domain_Records.txt
    echo $(TXTRecordF) | sed 's/"\ "/"\n"/g' >> /root/Hack/$domainName/Domain_Records.txt
    echo '' >> /root/Hack/$domainName/Domain_Records.txt
    echo Output saved to /root/Hack/$domainName/Domain_Records.txt
    echo $(tput setaf 2)Complete!$(tput sgr0)
}

function nmapDomain () {
    echo ''
    echo "nmap -sV $(ARecordF)"
    BuildDirectory
    nmap -sV $(ARecordF) > /root/Hack/$domainName/Simple_nmap.txt
    echo Output saved to /root/Hack/$domainName/Simple_nmap.txt
    echo "nmap -Pn -O -sV -A $(ARecordF)"
    nmap -Pn -O -sV -A $(ARecordF) > /root/Hack/$domainName/Aggressive_nmap.txt
    echo Output saved to /root/Hack/$domainName/Aggressive_nmap.txt
    echo $(tput setaf 2)Complete!$(tput sgr0)
}

function fierceDNS () {
    echo ''
    BuildDirectory
    echo fierce -dns $domainName
    fierce -dns $domainName > /root/Hack/$domainName/Fierce.txt
    echo Output saved to /root/Hack/$domainName/Fierce.txt
    echo $(tput setaf 2)Complete!$(tput sgr0)
}



###If no arg passed, don't ask for domain###
while [ $# -ne 0 ]; do
    PullDomain
    break
done

###Switch Flags###
while getopts 'pdnfa' opt; do
    case $opt in
        p)
	    allDNSRecordsToTerminal
	    ;;
	d)
            DomainFileF
	    ;;
        n)
	    nmapDomain
	    ;;
	f)
	    fierceDNS
	    ;;
	a)
	    allDNSRecordsToTerminal
	    DomainFileF
	    nmapDomain
            fierceDNS
	    ;;
    esac
done

