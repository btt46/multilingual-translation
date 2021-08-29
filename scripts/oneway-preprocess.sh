#!/bin/bash
set -e

BPESIZE=5000

DATA_FOLDER=$PWD/data
TRUECASED_DATA=$DATA_FOLDER/truecased
ONEWAYDATA=$DATA_FOLDER/oneway
BPE_DATA=$ONEWAYDATA/bpe-data
BIN_DATA=$ONEWAYDATA/bin-data
BPE_MODEL=$ONEWAYDATA/bpe-model
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

subword-nmt learn-bpe -s ${BPESIZE} < ${TRUECASED_DATA}/train.vi > ${BPE_MODEL}/model.vi
subword-nmt learn-bpe -s ${BPESIZE} < ${TRUECASED_DATA}/train.en > ${BPE_MODEL}/model.en

DATA_NAME="train valid test"
for lang in en vi; do
    echo "[$lang]..."
    for set in $DATA_NAME; do
        echo "${set}..."
        subword-nmt apply-bpe -c ${BPE_MODEL}/model.${lang} < ${TRUECASED_DATA}/${SET}.${lang} > $BPE_DATA/${SET}.{lang} 
    done
done

# binarize train/valid/test
if [ ! -d $BIN_DATA ]; then
    mkdir $BIN_DATA
    fairseq-preprocess -s en -t vi \
				--destdir $BIN_DATA \
				--trainpref $BPE_DATA/train \
				--validpref $BPE_DATA/valid \
				--testpref $BPE_DATA/test \
				--joined-dictionary \
				--workers 32 
fi