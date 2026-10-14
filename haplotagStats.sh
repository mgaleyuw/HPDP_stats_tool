#!/bin/bash

set -euo pipefail

scriptdir=bin

HEADER="File,Region,Coords,Depth,HP1,HP2,PercentAssigned,Phaseblocks"
LONGFORM=0
COVERAGE=0
STEP=1000
THREADS=1

temp=tmpfile


while getopts "i:r:b:lt:cw:p:T:" option; do
    case $option in 
        i) INPUT=$OPTARG ;;
        r) TARGET=$OPTARG ;;
        b) BEDFILE=$OPTARG ;;
        l) LONGFORM=1 ;;
        t) TEMPFILE=$OPTARG ;;
        c) COVERAGE=1 ;;
        w) STEP=$OPTARG ;;
        g) scriptdir=$OPTARG ;;
        T) THREADS=$OPTARG ;;
    esac
done

RUSTSCRIPT="$scriptdir/haplotagParse"

if [ "${LONGFORM}" -eq 1 ]
then
    if [ -z ${RUSTSCRIPT+x} ]
    then
        RUSTSCRIPT="$scriptdir/haplotagParseLong"
    fi
    HEADER="File,Region,Chromosome,Position,Depth,HP1,HP2,PercentAssigned"
elif [ $COVERAGE -eq 1 ]
then
    HEADER="File,Region,Coords,Depth,HP1,HP2,PercentAssigned,Phaseblocks,PercentCoverage"
fi

if [ -z ${BEDFILE+x} ]
then
    ###make temp for $TARGET

    coord="${TARGET##*:}"
    chr="${TARGET%:*}"
    seq ${coord%-*} $STEP ${coord##*-} | awk -v chr=$chr '{print chr,$1,$1+1}' | tr ' ' '\t' > $temp.positions

    region=$TARGET

    samtools mpileup -r $region --positions $temp.positions --ff SUPPLEMENTARY,UNMAP,SECONDARY,QCFAIL,DUP -q 1 -Q 1 --output-extra "PS,HP" $INPUT > $temp.pileup.tsv 2>out.err

    TARGET_RESULTS=$( cut -f8 $temp.pileup.tsv | $RUSTSCRIPT )
    rm $temp.positions
    rm $temp.pileup.tsv
    echo -e "$HEADER"
    echo -e "$INPUT\tTARGET\t$TARGET\t"${TARGET_RESULTS[@]} | tr ' ' '\t'
else
    printresults=( "$HEADER" )

    while read line
    do
        coordparts=( $line )
        seq ${coordparts[2]} $STEP ${coordparts[3]} | awk -v chr=${coordparts[1]} '{print chr,$1,$1+1}' | tr ' ' '\t' > $temp.positions
        region=${coordparts[1]}":"${coordparts[2]}"-"${coordparts[3]}
        echo $region >> haplotagLog.log
        samtools mpileup --verbosity 0 --region $region --positions $temp.positions --ff SUPPLEMENTARY,UNMAP,SECONDARY,QCFAIL,DUP -q 1 -Q 1 --output-extra "PS,HP" -aa $INPUT > $temp.pileup.tsv 2>out.err
        TARGET_RESULTS=$( cut -f8 $temp.pileup.tsv | $RUSTSCRIPT)
        if [ "$LONGFORM" -eq 1 ]
        then
            TARGET_RESULTS=( $( cut -f8 $temp.pileup.tsv | $RUSTSCRIPT) )
            numTargets="${#TARGET_RESULTS[@]}"
            n=( $(seq 1 "$numTargets") )
            printresults+=( $(paste -d ',' <(paste -d ',' <( printf "$INPUT,${coordparts[0]}\n"%.0s "${n[@]}" ) <( cut -f1,2 $temp.pileup.tsv | tr '\t' ',' ) ) <( echo ${TARGET_RESULTS[@]} | tr ' ' '\n') ))
        else
            TARGET_RESULTS=$( cut -f8 $temp.pileup.tsv | $RUSTSCRIPT)
            PRINT_TARGETS=$(echo ${TARGET_RESULTS[@]} | tr ' ' ',')
            set -o noglob
            PS=( $( cut -f7 $temp.pileup.tsv | tr ',' ' ' | tr ' ' '\n' | sort | uniq) )
            numPS="${#PS[@]}"
            if [ "${PS[0]}" == '*' ]
            then
                numPS=$(echo "$numPS - 1" | bc)
            fi
            set +o noglob
            if [ $COVERAGE -eq 1 ]
            then
                non0pos=$(wc -l $temp.pileup.tsv | tr -s ' ' | cut -d ' ' -f1)
                totalpos=$(wc -l $temp.positions | tr -s ' ' | cut -d ' ' -f1)
                percCoverage=$( echo "scale=2; $non0pos/$totalpos*100" | bc )
                result=$(echo "$INPUT,${coordparts[0]},$region,$PRINT_TARGETS,$numPS,$percCoverage")
            else       
                result=$(echo "$INPUT,${coordparts[0]},$region,$PRINT_TARGETS,$numPS")
            fi
            printresults+=( $result ) 
        fi   
    done <<< $( cat $BEDFILE )

    echo -e "${printresults[@]}" | tr ' ' '\n'
fi

rm -rf $temp*

