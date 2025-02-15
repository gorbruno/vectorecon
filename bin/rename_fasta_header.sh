#!/bin/bash

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 -f <fasta> -n <name> -o <out> -d <date> -r <run> -a <agent>"
  echo -e "For more info call -h flag"
  exit 1
fi

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      echo "-h, --help                show brief help"
      echo "Required:"
      echo "-f, --fasta               specify fasta file"
      echo "-n, --name                specify sample name"
      echo "Optional:"
      echo "-o, --out                 specify fasta out name"
      echo "-d, --date                specify date of run"
      echo "-r, --run                 specify run number"
      echo "-a, --agent               specify virus agent"
      exit 0
      ;;
      -f|--fasta)
      shift
      if test $# -gt 0; then
        fasta=$1
      else
        echo "No fasta file specified"
        exit 0
      fi
      shift
      ;;
    -n|--name)
      shift
      if test $# -gt 0; then
        name=$1
      else
        echo "No sample name specified"
        exit 0
      fi
      shift
      ;;
    -o|--out)
      shift
      if test $# -gt 0; then
        out=$1
      else
        echo "No sample out name specified"
        exit 0
      fi
      shift
      ;;
    -d|--date)
      shift
      if test $# -gt 0; then
        date=$1
      else
        echo "No run date specified"
        exit 0
      fi
      shift
      ;;
    -r|--run)
      shift
      if test $# -gt 0; then
        run=$1
      else
        echo "No run specified"
        exit 0
      fi
      shift
      ;;
    -a|--agent)
      shift
      if test $# -gt 0; then
        agent=$1
      else
        echo "No agent specified"
        exit 0
      fi
      shift
      ;;
    --dry)
      shift
      if test $# -eq 0; then
        dry=true
      else
        echo "Dry is a boolean flag"
        exit 0
      fi
      shift
      ;;
    *)
      break
      ;;
  esac
done

agent_dry=$(echo $agent | tr -d '[:space:]\t' | tr -cd '[:alnum:]_' | tr '[:upper:]' '[:lower:]')
dry_head="${date} ${run} ${agent_dry}"

optional_head="${date} ${run} ${agent}"
if [[ -n "${optional_head// /}" ]]; then
  optional_head="$(echo ${optional_head} | tr " " "_")-"
  dry_head=$(echo ${dry_head} | tr " " ".")
else
  optional_head=""
  dry_head=""
fi

if [[ -n $dry ]]; then
  echo $dry_head;
  exit 0
fi

# At least not python (kill me)
if [[ -n $fasta ]]; then
  if [[ -n $name ]]; then

    if [[ -n $out ]]; then
      sed "s/>/>${optional_head}${name} /g" $fasta > ${out}
    else
      sed "s/>/>${optional_head}${name} /g" $fasta
    fi
  else
    echo "Error: sample name is not defined!"
  fi
else
  echo "Error: fasta file is not defined!"
fi
