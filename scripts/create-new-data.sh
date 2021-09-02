#!/bin/bash
set -e

BPESIZE=5000
GPUS=$1
SRC=$2
TGT=$3
echo "GPU: $GPUS"
echo "$SRC -> $TGT"
# the directories for new data 
DATA_FOLDER=$PWD/data
NEW_DATA_FOLDER=$DATA_FOLDER/new-data
NEW_BPE_DATA=$NEW_DATA_FOLDER/bpe-data
NEW_BIN_DATA=$NEW_DATA_FOLDER/bin-data
TRANSLATION_DATA=$NEW_DATA_FOLDER/translation-data
NEW_DATA=$NEW_DATA_FOLDER/new-data
NEW_PROCESSED_DATA==$NEW_DATA_FOLDER/processed-data
PROCESSED_DATA=$DATA_FOLDER/processed-data

# The model used for evaluate
MODEL=$PWD/models/model/checkpoint_best.pt
NEW_BPE_MODEL=$NEW_DATA_FOLDER/bpe-model

BIN_DATA=$DATA_FOLDER/bin-data

ONEWAYDATA=$DATA_FOLDER/oneway
BPE_DATA=$ONEWAYDATA/bpe-data

DATA_NAME="train valid test"
TRUECASED_DATA=$DATA_FOLDER/truecased

mkdir -p $NEW_DATA_FOLDER
mkdir -p $NEW_DATA
mkdir -p $NEW_BPE_DATA
mkdir -p $NEW_BIN_DATA
mkdir -p $TRANSLATION_DATA
mkdir -p $NEW_DATA
mkdir -p $NEW_PROCESSED_DATA
mkdir -p $NEW_BPE_MODEL

if [$SRC = "en"] ; then
	TAG="<e2v"
fi

if [$SRC = "vi"] ; then
	TAG="<v2e"
fi 

cat ${BPE_DATA}/train.${SRC} | awk -vtgt_tag="$TAG" '{ print tgt_tag" "$0 }' > ${TRANSLATION_DATA}/translation.${SRC}

CUDA_VISIBLE_DEVICES=$GPUS env LC_ALL=en_US.UTF-8 fairseq-interactive $BIN_DATA \
            --input ${TRANSLATION_DATA}/translation.${SRC} \
            --path $MODEL \
            --beam 5 | tee $NEW_DATA/result.${TGT}


grep ^H ${NEW_DATA}/result.${TGT} | cut -f3 > ${NEW_DATA}/data.${TGT}

cat ${NEW_DATA}/data.${TGT}  | sed -r 's/(@@ )|(@@ ?$)//g'  > $NEW_DATA/new.${TGT} 

