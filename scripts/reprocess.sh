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
NEW_PROCESSED_DATA=$NEW_DATA_FOLDER/processed-data
PROCESSED_DATA=$DATA_FOLDER/processed-data

# The model used for evaluate
MODEL=$PWD/models/model/checkpoint_best.pt
NEW_BPE_MODEL=$NEW_DATA_FOLDER/bpe-model

BIN_DATA=$DATA_FOLDER/bin-data

ONEWAYDATA=$DATA_FOLDER/oneway
BPE_DATA=$ONEWAYDATA/bpe-data

MERGE_FILE=$PWD/scripts/merge-file.py


TRUECASED_DATA=$DATA_FOLDER/truecased

rm -rf $NEW_PROCESSED_DATA
rm -rf $NEW_BIN_DATA

mkdir -p $NEW_DATA_FOLDER
mkdir -p $NEW_DATA
mkdir -p $NEW_BPE_DATA
mkdir -p $NEW_BIN_DATA
mkdir -p $TRANSLATION_DATA
mkdir -p $NEW_DATA
mkdir -p $NEW_PROCESSED_DATA
mkdir -p $NEW_BPE_MODEL

# prepare data for the bidirectional model
DATA_NAME="valid test"

# copy processed-data to new processed data
for SET in $DATA_NAME ; do
	cat $PROCESSED_DATA/${SET}.src > $NEW_PROCESSED_DATA/${SET}.src
	cat $PROCESSED_DATA/${SET}.tgt > $NEW_PROCESSED_DATA/${SET}.tgt
done

cat ${TRANSLATION_DATA}/translation.vi | sed -r 's/(@@ )|(@@ ?$)|(<v2e> )//g'  > ${NEW_DATA}/train.vi
# cat  ${NEW_DATA}/new.en | awk -vtgt_tag="<e2v>" '{ print tgt_tag" "$0 }' >>  $NEW_PROCESSED_DATA/train.src
# cat $NEW_DATA/train.vi >> $NEW_PROCESSED_DATA/train.tgt

cat ${TRANSLATION_DATA}/translation.en | sed -r 's/(@@ )|(@@ ?$)|(<e2v> )//g'  > ${NEW_DATA}/train.en
# cat  ${NEW_DATA}/new.vi | awk -vtgt_tag="<v2e>" '{ print tgt_tag" "$0 }' >>  $NEW_PROCESSED_DATA/train.src
# cat $NEW_DATA/train.en >> $NEW_PROCESSED_DATA/train.tgt

##train: real, new:synthetic

##model_02
# python3.6 $MERGE_FILE -s1 ${NEW_DATA}/new.en -s2 ${TRUECASED_DATA}/train.en \
# 					  -s3 ${NEW_DATA}/new.vi -s4 ${TRUECASED_DATA}/train.vi -msrc ${NEW_PROCESSED_DATA}/train.src \
# 					  -t1 ${NEW_DATA}/train.vi -t2 ${TRUECASED_DATA}/train.vi \
# 					  -t3 ${NEW_DATA}/train.en -t4 ${TRUECASED_DATA}/train.en -mtgt ${NEW_PROCESSED_DATA}/train.tgt


##mode_03
# python3.6 $MERGE_FILE -s2 ${NEW_DATA}/new.en -s1 ${TRUECASED_DATA}/train.en \
# 					  -s4 ${NEW_DATA}/new.vi -s3 ${TRUECASED_DATA}/train.vi -msrc ${NEW_PROCESSED_DATA}/train.src \
# 					  -t2 ${NEW_DATA}/train.vi -t1 ${TRUECASED_DATA}/train.vi \
# 					  -t4 ${NEW_DATA}/train.en -t3 ${TRUECASED_DATA}/train.en -mtgt ${NEW_PROCESSED_DATA}/train.tgt

##model_04
# python3.6 $MERGE_FILE -s1 ${NEW_DATA}/new.en -s2 ${NEW_DATA}/new.vi \
# 					  -s3 ${TRUECASED_DATA}/train.en -s4 ${TRUECASED_DATA}/train.vi -msrc ${NEW_PROCESSED_DATA}/train.src \
# 					  -t1 ${NEW_DATA}/train.vi -t2 ${NEW_DATA}/train.en \
# 					  -t3 ${TRUECASED_DATA}/train.vi -t4 ${TRUECASED_DATA}/train.en -mtgt ${NEW_PROCESSED_DATA}/train.tgt

##model_05
# python3.6 $MERGE_FILE -s1 ${TRUECASED_DATA}/train.en  -s2 ${TRUECASED_DATA}/train.vi  \
# 					  -s3 ${NEW_DATA}/new.en -s4 ${NEW_DATA}/new.vi -msrc ${NEW_PROCESSED_DATA}/train.src \
# 					  -t1 ${TRUECASED_DATA}/train.vi  -t2 ${TRUECASED_DATA}/train.en  \
# 					  -t3 ${NEW_DATA}/train.vi -t4 ${NEW_DATA}/train.en -mtgt ${NEW_PROCESSED_DATA}/train.tgt

##model_06: model_02 + random sampling
TRAIN_SIZE="$(sed -n '$=' ${NEW_DATA}/new.en)" 

paste -d'切' ${NEW_DATA}/new.en ${NEW_DATA}/train.vi | cat -n | gshuf -n ${TRAIN_SIZE} | sort -n | cut -f2 > ${NEW_DATA}/v2e.random
cut -d'切' -f1 ${NEW_DATA}/v2e.random > ${NEW_DATA}/new-random.en
cut -d'切' -f2 ${NEW_DATA}/v2e.random > ${NEW_DATA}/train-random.vi

paste -d'切' ${NEW_DATA}/new.vi ${NEW_DATA}/train.en | cat -n | gshuf -n ${TRAIN_SIZE} | sort -n | cut -f2 > ${NEW_DATA}/e2v.random
cut -d'切' -f1 ${NEW_DATA}/e2v.random > ${NEW_DATA}/new-random.vi
cut -d'切' -f2 ${NEW_DATA}/e2v.random > ${NEW_DATA}/train-random.en

python3.6 $MERGE_FILE -s1 ${NEW_DATA}/new-random.en -s2 ${TRUECASED_DATA}/train.en \
					  -s3 ${NEW_DATA}/new-random.vi -s4 ${TRUECASED_DATA}/train.vi -msrc ${NEW_PROCESSED_DATA}/train.src \
					  -t1 ${NEW_DATA}/train-random.vi -t2 ${TRUECASED_DATA}/train.vi \
					  -t3 ${NEW_DATA}/train-random.en -t4 ${TRUECASED_DATA}/train.en -mtgt ${NEW_PROCESSED_DATA}/train.tgt


########################################################

# DATA_NAME="valid test"
# # copy processed-data to new processed data
# for SET in $DATA_NAME ; do
# 	echo "${NEW_PROCESSED_DATA}/${SET}.src...."
# 	cat ${PROCESSED_DATA}/${SET}.src > ${NEW_PROCESSED_DATA}/${SET}.src
# 	cat ${PROCESSED_DATA}/${SET}.tgt > ${NEW_PROCESSED_DATA}/${SET}.tgt
# done

# echo "old data"
# cat ${PROCESSED_DATA}/train.src | head -n 133317   > ${NEW_PROCESSED_DATA}/old.src.en
# cat ${PROCESSED_DATA}/train.src | tail -n +133318   > ${NEW_PROCESSED_DATA}/old.src.vi
# cat ${PROCESSED_DATA}/train.tgt | head -n 133317   > ${NEW_PROCESSED_DATA}/old.tgt.vi
# cat ${PROCESSED_DATA}/train.tgt | tail -n +133318   > ${NEW_PROCESSED_DATA}/old.tgt.en

# echo "new data"

# cat  ${NEW_PROCESSED_DATA}/old.src.en > ${NEW_PROCESSED_DATA}/train.src
# cat  ${NEW_PROCESSED_DATA}/old.tgt.vi > ${NEW_PROCESSED_DATA}/train.tgt


# cat ${NEW_DATA}/new.en | awk -vtgt_tag="<e2v>" '{ print tgt_tag" "$0 }' >>  ${NEW_PROCESSED_DATA}/train.src
# cat ${BPE_DATA}/train.vi | sed -r 's/(@@ )|(@@ ?$)//g'  > ${NEW_DATA}/train.vi
# cat ${NEW_DATA}/train.vi >> ${NEW_PROCESSED_DATA}/train.tgt

# cat  ${NEW_PROCESSED_DATA}/old.src.vi >> ${NEW_PROCESSED_DATA}/train.src
# cat  ${NEW_PROCESSED_DATA}/old.tgt.en >> ${NEW_PROCESSED_DATA}/train.tgt

# cat  ${NEW_DATA}/new.vi | awk -vtgt_tag="<v2e>" '{ print tgt_tag" "$0 }' >>  ${NEW_PROCESSED_DATA}/train.src
# cat ${BPE_DATA}/train.en | sed -r 's/(@@ )|(@@ ?$)//g'  > ${NEW_DATA}/train.en
# cat ${NEW_DATA}/train.en >> ${NEW_PROCESSED_DATA}/train.tgt

################################################################################################################
# learn bpe model with training data

echo "=> LEARNING BPE MODEL: $BPE_MODEL"
subword-nmt learn-joint-bpe-and-vocab --input ${NEW_PROCESSED_DATA}/train.src ${NEW_PROCESSED_DATA}/train.tgt \
				-s $BPESIZE -o ${NEW_BPE_MODEL}/code.${BPESIZE}.bpe \
				--write-vocabulary ${NEW_BPE_MODEL}/train.src.vocab ${NEW_BPE_MODEL}/train.tgt.vocab 


# apply sub-word segmentation

DATA_NAME="train valid test"
for SET in $DATA_NAME; do
    subword-nmt apply-bpe -c ${NEW_BPE_MODEL}/code.${BPESIZE}.bpe < ${NEW_PROCESSED_DATA}/${SET}.src > ${NEW_BPE_DATA}/${SET}.src 
    subword-nmt apply-bpe -c ${NEW_BPE_MODEL}/code.${BPESIZE}.bpe < ${NEW_PROCESSED_DATA}/${SET}.tgt > ${NEW_BPE_DATA}/${SET}.tgt
done


# binarize train/valid/test

fairseq-preprocess -s src -t tgt \
			--destdir ${NEW_BIN_DATA} \
			--trainpref ${NEW_BPE_DATA}/train \
			--validpref ${NEW_BPE_DATA}/valid \
			--testpref ${NEW_BPE_DATA}/test \
			--joined-dictionary \
			--workers 32 


