#!/bin/bash

# ------------------------------------------------------------------------------
# Script Name : ChirpShell
# Description : A TUI for cli chirp, using fzf menus
# Author      : xqtr
# Created     : 2025.05.20
# License     : GPLv3
# Version     : 1.0
# ------------------------------------------------------------------------------
# Usage       : ./chirpshell.sh 
#
# Dependencies: fzf, chirp, mc
#
# ------------------------------------------------------------------------------
# Changelog   :
# 1.0 - Initial version
# ------------------------------------------------------------------------------


script="${0##*/}"
script="${script%.*}"
DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
VERSION="1.0.0"
#yellow start 
	C14="\e[1;33m"
#blue start 
	C01="\e[0;34m"
#color end
	CE="\e[0m"
#red start
	C04="\e[1;31m"
#black start
	C00="\e[0;30m"
#dark gray start
	C08="\e[1;30m"
#light blue start
	C09="\e[1;34m"
#green start
	C02="\e[0;32m"
#light green start
	C10="\e[1;32m"
#cyan start
	C03="\e[0;36m"
#light cyan start
	C11="\e[1;36m"
#light red start
	C12="\e[0;31m"
#purple start
	C05="\e[0;35m"
#light purple start
	C13="\e[1;35m"
#brown start
	C06="\e[0;33m"
#light gray start
	C07="\e[0;37m"
#white 
	C15="\e[1;37m"
  
#setting frequent stings
	YNYES="("$C14"Y"$CE"/"$C14"n"$CE")("$C14"Enter"$CE"=yes)"
	YNNO="("$C14"y"$CE"/"$C14"N"$CE")("$C14"Enter"$CE"=no)"

dependencies=(fzf chirpc mc)
READAK="read -n 1"

radio=""
mmap=""
port=""

function show_version() {
  clear
  echo -e $C14"BashChirp:"$CE" v"$VERSION
  echo -e $C14"Chirpc: "$CE"$(chirpc --version)"
  presskey
}

function presskey() {
  echo ""
  echo -e $C10"Press a key to continue..."$CE
  read -n 1
}

prompt_confirm_no() {
  while true; do
    echo -e -n "${1:-Continue?} ${YNNO}: "
    read -e -r -n 1 REPLY
    case $REPLY in
      [yY]) echo ; return 0 ;;
      [nN]) echo; echo "Going back..."; sleep 1; return 1 ;;
      $'\0A') echo; echo "Going back..."; sleep 1; return 1 ;;
      *) printf " \033[31m %s \n\033[0m" "invalid input"
    esac 
  done  
}

prompt_confirm_yes() {
  while true; do
    echo -e -n "${1:-Continue?} $YNYES: "
    read -e -r -n 1 REPLY
    case $REPLY in
      [yY]) echo ; return 0 ;;
      [nN]) echo; echo "Going back..."; sleep 1; return 1 ;;
      $'\0A') echo; echo "Going back..."; sleep 1; return 0 ;;
      *) printf " \033[31m %s \n\033[0m" "invalid input"
    esac 
  done  
}

function check_dependencies() {
  missing_dependencies=()
  for name in ${dependencies[@]}
  do
    if [ ! -x "$(command -v $name)" ]; then
      missing_dependencies+=($name)
    fi
  done
  if [ ! ${#missing_dependencies[@]} -eq 0 ]; then
    echo ""
    echo -e $C12"Missing dependencies:"$CE
    printf "%s\n" " - ${missing_dependencies[@]}"
    echo ""
    prompt_confirm_no "Missing Dependencies. Continue?" || exit 1
  fi 
}

function initvars() {
  # radio
  if [ -f ./radio ]; then 
    radio=$(cat ./radio)
  else
    radio=""
  fi
  # port
  if [ -f ./port ]; then 
    port=$(cat ./port)
  else
    port=""
  fi
}

function get_mmap() {
  #chirpc -r <radio> --serial=<port> --mmap=<file> --download-mmap
  clear
  if [ -z $radio ]; then
    echo "No Radio selected!"
    presskey
    return -1
  fi
  if [ -z $port ]; then
    echo "No Port selected!"
    presskey
    return -1
  fi
  tmp="./files/${radio}_$(date +"%Y%m%d-%H%M%S").mmap"
  echo "Memory will be saved in file:"
  echo "> $tmp"
  echo ""
  prompt_confirm_no || return -1
  
  chirpc -r $radio --serial=$port --mmap=$tmp --download-mmap
  echo ""
  presskey
  clear
}

function set_mmap() {
  clear
  clear
  if [ -z $radio ]; then
    echo "No Radio selected!"
    presskey
    return -1
  fi
  if [ -z $port ]; then
    echo "No Port selected!"
    presskey
    return -1
  fi
  if [ -z $mmap ]; then 
    echo "No file selected."
    presskey
    return -1
  fi
  chirpc -r $radio --serial=$port --mmap=$tmp --upload-mmap
  echo ""
  presskey
  clear
  
}

function select_port() {
  clear
  read -p "Enter port [/dev/ttyUSB0]: " port
  port=${port:-/dev/ttyUSB0}
  echo $port > ./port
  clear
}

function fzz() {
  #"right,50%,:wrap"
  fzf --ansi --bind 'enter:execute(echo {1})+abort' --bind 'end:last' --bind 'home:first' --header $"Radio: ${radio} | Port: ${port} | MMAP: ${mmap}"
  }


function list_settings(){
  clear
  if [ -z $mmap ]; then 
    echo "No file selected."
    presskey
    return -1
  fi
  chirpc --mmap=./files/${mmap} -r ${radio} --list-settings | less
  clear
}

function view_channel(){
  clear
  if [ -z $mmap ]; then 
    echo "No file selected."
    presskey
    return -1
  fi
  
  read -p "Enter channel: " chan
  isinteger $chan || return -1
  mchan=$(chirpc --mmap=./files/${mmap} -r ${radio} --get-mem $chan)
  echo "Memory: $chan"
  echo "Freq  : $(echo $mchan | cut -d" " -f3)"
  echo "Band  : $(echo $mchan | cut -d" " -f4)"
  echo "Name  : $(echo $mchan | cut -d" " -f5)"
  echo "ToneR : $(echo $mchan | cut -d" " -f6)"
  echo "ToneC : $(echo $mchan | cut -d" " -f7)"
  echo "      : $(echo $mchan | cut -d" " -f8)"
  echo "      : $(echo $mchan | cut -d" " -f9)"
  echo "Power : $(echo $mchan | cut -d" " -f10)"
  presskey
  clear
}


function list_channels(){
  clear
  if [ -z $mmap ]; then 
    echo "No file selected."
    presskey
    return -1
  fi
  chirpc --mmap=./files/${mmap} -r ${radio} --list-mem | sed 's/Memory\ //g' | fzf --header " #        Receive/Trans. Band    Name    ToneR  ToneS   #   Power"
  clear
}

function select_radio() {  
  radio=$(chirpc --list-radios | sed 1d | sed -e 's/^[ \t]*//' | fzf)
  if [ ! -z $radio ]; then
    echo $radio > ./radio
  else
    radio="None"
  fi
}

function select_file() {  
  mmap=$(ls ./files | fzf)
  if [ -z $mmap ]; then
    mmap=""
  fi
}

function isinteger(){
  case $1 in
    ''|*[!0-9]*) echo ""; echo "Invalid number."; sleep 3; return -1;;
    *) return 0;;
  esac
}

function isfile() {
  if [ -z $mmap ]; then 
    echo "No file selected."
    presskey
    return -1
  fi
  return 0
}

function mem_clear(){
  prompt_confirm_no "Clear channel $1 ?" || return -1
  chirpc --mmap=./files/${mmap} -r ${radio} --clear-mem $1 
  presskey
}

function mem_copy() {
  read -p "Enter destination position: " chant
  isinteger $chant || return -1
  if [ $1 -eq $chant ]; then
    echo -e $C04"Source and destination channels are same. Aborting."$CE
    sleep 3
    return 1
  fi
  prompt_confirm_no "Copy channel $1 to position $chant ?" || return -1
  
  chirpc --mmap=./files/${mmap} -r ${radio} --copy-mem $1 $chant
  presskey
}

function mem_polarity() {
  clear
  pol=$(echo "NN
NR
RN
RR" | fzf --bind 'end:last' --bind 'home:first' --header $'\e[33;1mSelect Polarity \e[1;37m| Enter\e[0;36m: Input selection.')
  
  if [ ! -z $pol ]; then
    chirpc --mmap=./files/${mmap} -r ${radio} --set-mem-dtcspol $pol $1
    if [ $? -eq 0 ]; then
      echo "Success..."
    else
      echo "Error..."
    fi
    presskey
  fi
}

function mem_duplex() {
  clear
  pol=$(echo "+
-
blank" | fzf --bind 'end:last' --bind 'home:first' --header $'\e[33;1mSelect Duplex \e[1;37m| Enter\e[0;36m: Input selection.')
  
  if [ ! -z $pol ]; then
    chirpc --mmap=./files/${mmap} -r ${radio} --set-mem-dup $pol $1
    if [ $? -eq 0 ]; then
      echo "Success..."
    else
      echo "Error..."
    fi
    presskey
  fi
}

function mem_offset() {
  clear
  offset=$(seq 0 0.125 1 | sed 's/,/./g' | fzf --bind 'enter:replace-query' --bind 'ctrl-y:replace-query+print-query' --bind 'end:last' --bind 'home:first' --header $'\e[33;1mSet Offset in MHz\e[1;37m| Enter\e[0;36m: Input selection. \e[1;37mCTRL+Y\e[0;36m:Accept query and proceed')
  
  if [ ! -z $offset ]; then
    chirpc --mmap=./files/${mmap} -r ${radio} --set-mem-offset $offset $1
    if [ $? -eq 0 ]; then
      echo "Success..."
    else
      echo "Error..."
    fi
    presskey
  fi
}

function mem_freq() {
  clear
  freq=$(seq 1000 500 10000 | sed 's/,/./g' | fzf --bind 'enter:replace-query' --bind 'ctrl-y:replace-query+print-query' --bind 'end:last' --bind 'home:first' --header $'\e[33;1mSet Frequency in Hz\e[1;37m| Enter\e[0;36m: Input selection. \e[1;37mCTRL+Y\e[0;36m:Accept query and proceed')
  
  if [ ! -z $freq ]; then
    chirpc --mmap=./files/${mmap} -r ${radio} --set-mem-freq $freq $1
    if [ $? -eq 0 ]; then
      echo "Success..."
    else
      echo "Error..."
    fi
    presskey
  fi
}


function mem_name() {
  clear
  name=$(echo "" | fzf --bind 'enter:replace-query' --bind 'ctrl-y:replace-query+print-query' --bind 'end:last' --bind 'home:first' --header $'\e[33;1mSet Name (CAPITAL)\e[1;37m| Enter\e[0;36m: Input selection. \e[1;37mCTRL+Y\e[0;36m:Accept query and proceed')
  
  if [ ! -z $name ]; then
    chirpc --mmap=./files/${mmap} -r ${radio} --set-mem-name $name $1
    if [ $? -eq 0 ]; then
      echo "Success..."
    else
      echo "Error..."
    fi
    presskey
  fi
}

function mem_mode() {
  clear
  pol=$(echo "WFM
FM
NFM
AM
NAM
DV
USB
LSB
CW
RTTY
DIG
PKT
NCW
NCWR
CWR
P25
Auto
RTTYR
FSK
FSKR
DMR
DN" | fzf --bind 'end:last' --bind 'home:first' --header $'\e[33;1mSelect Mode \e[1;37m| Enter\e[0;36m: Input selection.')
  
  if [ ! -z $pol ]; then
    chirpc --mmap=./files/${mmap} -r ${radio} --set-mem-mode "$pol" $1
    if [ $? -eq 0 ]; then
      echo "Success..."
    else
      echo "Error..."
    fi
    presskey
  fi
}

function channel_operations() {
  clear
  isfile || return 1
    
  mchan="$(chirpc --mmap=./files/${mmap} -r ${radio} --list-mem | fzf --bind 'end:last' --bind 'home:first' --header "Select Channel")" 
  channum=$(echo "$mchan" | cut -d" " -f 2 | cut -d":" -f 1)
  option=""
  while [ -z "$option"  ]
  do 
  
  ichan=$(chirpc --mmap=./files/${mmap} -r ${radio} --get-mem $channum)
  ffreq="$(echo $ichan | cut -d" " -f3)"
  fband="$(echo $ichan | cut -d" " -f4)"
  fname="$(echo $ichan | cut -d" " -f5)"
  ftoner="$(echo $ichan | cut -d" " -f6)"
  ftonec="$(echo $ichan | cut -d" " -f7)"
  finfo1="$(echo $ichan | cut -d" " -f8)"
  finfo2="$(echo $ichan | cut -d" " -f9)"
  fpower="$(echo $ichan | cut -d" " -f10)"
  fheader="#$channum | $fname | $ffreq | $fband | $ftoner | $tonec | $finfo1 | $finfo2 | $fpower"
  
  option=$(echo "1. Clear Memory Channel
2. Copy Channel
N. Set Name
F. Set Frequency
D. Set Duplex
P. Set memory DTCS polarity 
M. Set memory mode
O. Offset
X. Back" | fzf --header "$fheader" --bind 'end:last' --bind 'home:first')

    if [ ! -z "$option" ]
    then
      ch="$option"
      clear
      case $ch in
        1.*) mem_clear $channum;;
        2.*) mem_copy $channum;;
        F.*) mem_freq $channum;;
        D.*) mem_duplex $channum;;
        P.*) mem_polarity $channum;;
        M.*) mem_mode $channum;;
        O.*) mem_offset $channum;;
        N.*) mem_name $channum;;
        X.*) break;;
        esac
    fi
  option=""
  done
  clear
}

if [ ! -d $DIR/files ]; then
  mkdir $DIR/files
fi

check_dependencies
initvars
option=""
while [ -z "$option"  ]
do 
  option=$(echo "1. Select Radio
2. Select Port
3. Download from: $radio
4. Select MMAP File
5. List Settings of image file
6. List Channels
7. View Channel...
8. Channel Operations ->
F. File Manager (Midnight Commander)
U. Upload to: $radio
V. Version
X. Exit" | fzz)

  if [ ! -z "$option" ]
  then
    ch="$option"
    case $ch in
      1.*) select_radio;;
      2.*) select_port;;
      3.*) get_mmap;;
      4.*) select_file;;
      5.*) list_settings;;
      6.*) list_channels;;
      7.*) view_channel;;
      8.*) channel_operations;;
      F.*) mc;;
      U.*) set_mmap;;
      V.*) show_version;;
      X.*) exit;;
      esac
  fi
option=""
done

exit
