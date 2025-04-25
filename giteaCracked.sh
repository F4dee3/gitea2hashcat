#!/bin/bash

# Script to extract password hashes from a Gitea database (SQLite format).
# It retrieves user password hashes and algorithms, then formats the output for use with tools like Hashcat.
# By Fadee
# References: IppSec's video https://youtu.be/aG_N2ZiCfxk?t=2219

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

function ctrl_c(){
  echo -e "\n\n${redColour}[!] Exiting...${endColour}\n"
  tput cnorm; exit 1
}

#Ctrl + C
trap ctrl_c SIGINT

function helpPanel(){
  echo -e "\n${yellowColour}[+]${endColour}${grayColour} Usage:${endColour}${blueColour} $0${endColour}\n"
  echo -e "\t${purpleColour}-d)${endColour}${grayColour} Provide the database file (e.g., gitea.db)${endColour}"
  echo -e "\t${purpleColour}-o)${endColour}${grayColour} Specify the output file${endColour}"
  echo -e "\t${purpleColour}-h)${endColour}${grayColour} Display this help panel${endColour}\n"
}

function crackedDB(){
  DB_FILE="$1"
  if [ ! -f "$DB_FILE" ]; then
    echo -e "\n${redColour}[!] The provided file is invalid or cannot be read${endColour}"
    exit 1
  else
   data="$(sqlite3 "$DB_FILE" "SELECT name, passwd_hash_algo, salt, passwd FROM user;")"
    while IFS='|' read -r name algo salt passwd; do
      if [[ "$algo" == *"pbkdf2"* ]]; then
          IFS='$' read -r _ loop keyleno <<< "$algo"
          algo="sha256"
      else
          echo "${redColour}[!] Error: Unknown Algorithm${endColour}"
          exit 1
      fi

      salt_b64="$(echo "$salt" | xxd -r -p | base64)"
      passwd_b64="$(echo "$passwd" | xxd -r -p | base64)"

      echo -e "$name:$algo:$loop:$salt_b64:$passwd_b64"
    done <<< "$data"
  fi
}

function getDBOutputfile(){
  DB_FILE="$1"
  fileName="$2"
  crackedDB "$DB_FILE" > "$fileName" 
}

# Indicators
declare -i parameter_counter=0

# Chivatos
declare -i chivato_db=0
declare -i chivato_output=0

while getopts "d:o:h" arg; do
  case "${arg}" in
    d) database="${OPTARG}"; chivato_db=1; let parameter_counter+=1;;
    o) output="${OPTARG}"; chivato_output=1; let parameter_counter+=2;;
    h) helpPanel; exit 0;;
    *) helpPanel; exit 1;;
  esac
done

shift "$((OPTIND - 1))"
if [ $# -gt 0 ]; then
  helpPanel
fi

if [ $parameter_counter -eq 1 ]; then
  crackedDB $database
elif [ $chivato_db -eq 1 ] && [ $chivato_output -eq 1 ]; then
  getDBOutputfile $database "$output"
else
  helpPanel; exit 1
fi
