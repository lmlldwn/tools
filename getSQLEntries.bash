#!/bin/bash

DIR=$1
OUTPUT_FILE="./$2.csv"
DOMAIN=$3
PROJECT=$4
PLATFORM=$5
NAMESPACE=$6
FILELIST=(`find $DIR -name "*-sqlmap-mapping.xml" | sort`)
echo ""> $OUTPUT_FILE
TOTAL_ITEM=0

if [ -z "$DIR" ]; then
    echo "No directory given"
    exit 0
fi

if [ -z "$DOMAIN" ]; then
    DOMAIN="Domain name"
fi

if [ -z "$PROJECT" ]; then
    PROJECT="Project Name"
fi

if [ -z "$PLATFORM" ]; then
    PLATFORM="A+"
fi

if [ -z "$NAMESPACE" ]; then
    NAMESPACE="alipayplus_ph_release"
fi

for FILE in ${FILELIST[*]}; do
    cat "$FILE"| nl -b a| grep -e '<insert ' -e '<insert>' -e '</insert>' -e '<select '  -e '<select>' -e '</select>' -e '<update ' -e '<update>' -e '</update>' -e '<delete>' -e '<delete ' -e '</delete>' | grep -v '<!--'| grep -v '\-\->' | expand | tr -s " " > ./sqlkeywords.txt
    LINENUMBERS=(`cat ./sqlkeywords.txt | cut -d " " -f 2`)
    COUNT=0
    (( ITEMS= ${#LINENUMBERS[*]} / 2))

    #echo "==========          $FILE          =========="        >> $OUTPUT_FILE
    SOURCE_FILE="${FILE#/*/*/sqlmap/}"
    if [ $ITEMS -eq 0 ]; then
        echo "No SQL Queries found in $FILE"
    else
        for ITEM in `seq $ITEMS`; do 
            (( TOTAL_ITEM=$TOTAL_ITEM+1 ))
            (( STARTLINEINDEX=$COUNT ))
            (( ENDLINEINDEX=$COUNT + 1 ))
            (( STARTLINE=${LINENUMBERS[$STARTLINEINDEX]} + 1 ))
            (( ENDLINE=${LINENUMBERS[$ENDLINEINDEX]} - 1 ))
            QUERY=`tail -n "+$STARTLINE" $FILE | head -n "$((ENDLINE-STARTLINE+1))" | grep -v "CDATA" | grep -v "\]\]>" | grep -v '<!--'| grep -v '\-\->' | sed 's/"/""/g' `
            FORMATTED_QUERY="\"${QUERY}\""
            # echo "==========               $TOTAL_ITEM               =========="                >> $OUTPUT_FILE
            # echo "==========               $ITEM               =========="                      >> $OUTPUT_FILE
            echo "$DOMAIN,$PLATFORM,$NAMESPACE,$PROJECT,$SOURCE_FILE,$FORMATTED_QUERY"                                                            >> $OUTPUT_FILE
            # echo "==========               $ITEM               =========="                      >> $OUTPUT_FILE
            (( COUNT=$COUNT+2 ))
        done
    fi
done
echo "Total Entries: $TOTAL_ITEM"
echo "Output File: $OUTPUT_FILE"
rm ./sqlkeywords.txt
exit 0