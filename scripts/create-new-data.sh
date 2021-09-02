#!/bin/bash
set -e

BPESIZE=5000
GPUS=$1
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

# prepare data for the bidirectional model
echo "=> PREPROCESSING en <> vi DATA: $PWD....."

cat ${BPE_DATA}/train.en | awk -vtgt_tag="<e2v>" '{ print tgt_tag" "$0 }' > ${TRANSLATION_DATA}/translation.en
cat ${BPE_DATA}/train.vi | awk -vtgt_tag="<v2e>" '{ print tgt_tag" "$0 }' > ${TRANSLATION_DATA}/translation.vi


CUDA_VISIBLE_DEVICES=$GPUS env LC_ALL=en_US.UTF-8 fairseq-interactive $BIN_DATA \
            --input ${TRANSLATION_DATA}/translation.en \
            --path $MODEL \
            --beam 5 | tee $NEW_DATA/result.vi


CUDA_VISIBLE_DEVICES=$GPUS env LC_ALL=en_US.UTF-8 fairseq-interactive $BIN_DATA \
            --input ${TRANSLATION_DATA}/translation.vi \
            --path $MODEL \
            --beam 5 | tee $NEW_DATA/result.en

# grep ^H ${NEW_DATA}/result.vi | cut -f3 > ${NEW_DATA}/data.vi
grep ^H ${NEW_DATA}/result.en | cut -f3 > ${NEW_DATA}/data.en

# 普通文字に戻す
cat ${NEW_DATA}/data.vi | sed -r 's/(@@ )|(@@ ?$)//g'  > $NEW_DATA/new.vi
cat ${NEW_DATA}/data.en  | sed -r 's/(@@ )|(@@ ?$)//g' > $NEW_DATA/new.en

# copy processed-data to new processed data
for SET in $DATA_NAME ; do
	cat $PROCESSED_DATA/${SET}.src > $NEW_PROCESSED_DATA/${SET}.src
	cat $PROCESSED_DATA/${SET}.tgt > $NEW_PROCESSED_DATA/${SET}.tgt
done

cat  ${TRUECASED_DATA}/train.en | awk -vtgt_tag="<e2v>" '{ print tgt_tag" "$0 }' >>  $NEW_PROCESSED_DATA/train.src
cat $NEW_DATA/new.vi >> $NEW_PROCESSED_DATA/train.tgt

cat  ${TRUECASED_DATA}/train.vi | awk -vtgt_tag="<v2e>" '{ print tgt_tag" "$0 }' >>  $NEW_PROCESSED_DATA/train.src
cat $NEW_DATA/new.en >> $NEW_PROCESSED_DATA/train.tgt


# learn bpe model with training data

echo "=> LEARNING BPE MODEL: $BPE_MODEL"
subword-nmt learn-joint-bpe-and-vocab --input ${NEW_PROCESSED_DATA}/train.src ${NEW_PROCESSED_DATA}/train.tgt \
				-s $BPESIZE -o $NEW_BPE_MODEL/code.${BPESIZE}.bpe \
				--write-vocabulary $NEW_BPE_MODEL/train.src.vocab $NEW_BPE_MODEL/train.tgt.vocab 


# apply sub-word segmentation


for SET in $DATA_NAME; do
    subword-nmt apply-bpe -c $NEW_BPE_MODEL/code.${BPESIZE}.bpe < ${NEW_PROCESSED_DATA}/${SET}.src > $NEW_BPE_DATA/${SET}.src 
    subword-nmt apply-bpe -c $NEW_BPE_MODEL/code.${BPESIZE}.bpe < ${NEW_PROCESSED_DATA}/${SET}.tgt > $NEW_BPE_DATA/${SET}.tgt
done


# binarize train/valid/test

fairseq-preprocess -s src -t tgt \
			--destdir $NEW_BIN_DATA \
			--trainpref $NEW_BPE_DATA/train \
			--validpref $NEW_BPE_DATA/valid \
			--testpref $NEW_BPE_DATA/test \
			--joined-dictionary \
			--workers 32 


