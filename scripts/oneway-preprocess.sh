#!/bin/bash
set -e

BPESIZE=5000
SRC=$1
TGT=$2

DATA_FOLDER=$PWD/data
TRUECASED_DATA=$DATA_FOLDER/truecased
ONEWAYDATA=$DATA_FOLDER/oneway
BPE_DATA=$ONEWAYDATA/bpe-data
BIN_DATA=$ONEWAYDATA/bin-data
# BPE_MODEL=$DATA_FOLDER/bpe-model
BPE_MODEL=$DATA_FOLDER/bpe-model

if [ -d $BIN_DATA ]; then
	rm  -rf $BIN_DATA
fi

if [ ! -d $ONEWAYDATA ]; then
	mkdir -p $ONEWAYDATA
fi 

if [ ! -d $BPE_DATA ]; then
	mkdir -p $BPE_DATA
fi

if [ ! -d $BIN_DATA ]; then
	mkdir -p $BIN_DATA
fi

if [ ! -d $BPE_MODEL ]; then
	mkdir -p $BPE_MODEL
fi


DATA_NAME="train valid test"

for lang in en vi; do
    echo "[$lang]..."
    for SET in $DATA_NAME; do
        echo "${SET}..."
        subword-nmt apply-bpe -c ${BPE_MODEL}/code.${BPESIZE}.bpe < ${TRUECASED_DATA}/${SET}.${lang} > ${BPE_DATA}/${SET}.${lang} 
    done
done



fairseq-preprocess -s ${SRC} -t ${TGT} \
			--destdir $BIN_DATA \
			--trainpref $BPE_DATA/train \
			--validpref $BPE_DATA/valid \
			--testpref $BPE_DATA/test \
			--workers 32 