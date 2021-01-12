#!/bin/bash

# Colors
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHTGRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[1;34m'
LIGHTPURPLE='\033[1;35m'
LIGHTCYAN='\033[1;36m'
WHITE='\033[1;37m'

# http://patorjk.com/software/taag/#p=display&f=Sub-Zero&t=digenum
echo -e $CYAN
echo " _____     __     ______     ______     __   __     __  __     __    __     "
echo "/\  __-.  /\ \   /\  ___\   /\  ___\   /\ \"-.\ \   /\ \/\ \   /\ \"-./  \   "
echo "\ \ \/\ \ \ \ \  \ \ \__ \  \ \  __\   \ \ \-.  \  \ \ \_\ \  \ \ \-./\ \  "
echo " \ \____-  \ \_\  \ \_____\  \ \_____\  \ \_\\\\\"\_\  \ \_____\  \ \_\ \ \_\ "
echo "  \/____/   \/_/   \/_____/   \/_____/   \/_/ \/_/   \/_____/   \/_/  \/_/ "
echo " -- Enumerate the history of your router"
echo "    By Matthias Kesenheimer"
echo -e $NOCOLOR

usage() {
  echo -e $NOCOLOR
  echo "usage: exerror.sh -ip <IP-Address> -w <wordlist> [options...]"
  echo "       -h|--help           show this message"
  echo "       -u|--url            enum a single url/host instead of using a wordlist"
  echo "       -v|--verbosity <n>  level of verbosity"
  echo "       -s|--show           show negative results"
}

if [[ $# -lt 1 ]]; then 
  usage
  exit -1
fi

# parse the arguments
ipaddress=""
verbosity="0"
wordlist=""
urlAsArg=""
show="false"
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -ip|--ip-address)
    ipaddress="$2"
    shift # past argument
    shift # past value
    ;;
    -h|--help)
    usage
    exit 0
    ;;
    -w|--wordlist)
    wordlist="$2"
    shift
    shift
    ;;
    -u|--url)
    urlAsArg="$2"
    shift
    shift
    ;;
    -v|--verbosity)
    verbosity="$2"
    shift
    shift
    ;;
    -s|--show)
    show="true"
    shift
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
  esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# throw error if no ip address is provided
if [[ "$ipaddress" == "" ]]; then
  echo -e "$RED[-]$NOCOLOR Please provide an ip-address"
  usage
  exit -1
fi

if [[ "$urlAsArg" != "" ]]; then
  echo $urlAsArg > url.temp
  wordlist="url.temp"
fi

# throw error if no wordlist is provided
if [[ "$wordlist" == "" ]]; then
  echo -e "$RED[-]$NOCOLOR Please provide a wordlist"
  usage
  exit -1
fi


if [[ $verbosity -ge 1 ]]; then
  echo -e "$GREEN[+]$NOCOLOR Starting enumeration..."
  echo -e "$GREEN[+]$NOCOLOR ip-address is $ipaddress"
  echo -e "$GREEN[+]$NOCOLOR wordlist is $wordlist"
fi

for url in $(cat $wordlist); do
  if [[ $verbosity -ge 1 ]]; then
    echo -e "\n\n$GREEN[+]$NOCOLOR Current url: $url"
    echo -e "$GREEN[+]$NOCOLOR Command: dig @$ipaddress $url +norecurse"
  fi

  result=$(dig @$ipaddress $url +norecurse)

  if [[ "$verbosity" == "2" ]]; then
    echo -e "\n\n$YELLOW[+]$NOCOLOR Response:"
    echo "$result"
  fi

  answerSection=$(echo "$result" | grep -A 2 ";; ANSWER SECTION:")

  if [[ "$verbosity" == "1" ]] && [[ "$answerSection" != "" ]]; then
    echo -e "$GREEN[+]$NOCOLOR Answer section:"
    echo "$answerSection"
  fi

  if [[ "$answerSection" != "" ]]; then
    ip=$(echo "$answerSection" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | head -1)
    echo -e "$GREEN[+]$NOCOLOR $url is cached and has ip-address $ip."
  fi
  if [[ "$show" == "true" ]]; then
    echo -e "$YELLOW[+]$NOCOLOR $url is not cached."
  fi
done

if [[ "$urlAsArg" != "" ]]; then
  rm url.temp
fi

