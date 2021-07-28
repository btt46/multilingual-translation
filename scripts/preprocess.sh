#!/bin/bash
set -e

# **************** Update ***************
SRCS="en vi"
TGTS="vi en"
BPESIZE=5000

MOSES=$PWD/mosesdecoder/scripts
NORM=$MOSES/tokenizer/normalize-punctuation.perl
TOK=$MOSES/tokenizer/tokenizer.perl
DEES=$MOSES//tokenizer/deescape-special-chars.perl

FARISEQ=$PWD/fairseq

BPE_MODEL=$PWD/data/bpe-model

# data 
DATA_FOLDER=$PWD/data
RAW_DATA=$DATA_FOLDER/iwslt15
DATA=$DATA_FOLDER/data
PROCESSED_DATA=$DATA_FOLDER/processed-data
BPE_DATA=$PWD/data/bpe-data
BIN_DATA=$PWD/data/bin-data

DATA_NAME="train valid test"

TEXT_PROCESS=$PWD/text-process
# ***************************************

mkdir -p $DATA
mkdir -p $PROCESSED_DATA

# remove rarewords and exporting a data
python3.6 ${TEXT_PROCESS}/remove-rare.py ${RAW_DATA}/train.en ${DATA}/train.en
python3.6 ${TEXT_PROCESS}/remove-rare.py ${RAW_DATA}/train.vi ${DATA}/train.vi

for lang in en vi; do
    cp ${RAW_DATA}/tst2012.${lang} ${DATA}/valid.${lang}
    cp ${RAW_DATA}/tst2013.${lang} ${DATA}/test.${lang}
done


# for SRC in en vi; do
#     for TGT in en vi; do
#         if [ $SRC != $TGT ]; then
#             echo "PREPROCESSING $SRC <> $TGT DATA: $PWD"
#             for SET in $DATA_NAME ; do
#                 $NORM  < ${DATA}/${SET}.$SRC | $TOK -l $SRC -q | $DEES | awk -vtgt_tag="<${SRC}2${TGT}>" '{ print tgt_tag" "$0 }' >> ${PROCESSED_DATA}/${SET}.src
#                 $NORM  < ${DATA}/${SET}.$TGT | $TOK -l $TGT -q | $DEES | awk -vtgt_tag="<${TGT}2${SRC}>" '{ print tgt_tag" "$0 }' >> ${PROCESSED_DATA}/${SET}.src

#                 $NORM < ${DATA}/${SET}.$TGT | $TOK -l $TGT -q | $DEES >> ${PROCESSED_DATA}/${SET}.tgt
#                 $NORM < ${DATA}/${SET}.$SRC | $TOK -l $SRC -q | $DEES >> ${PROCESSED_DATA}/${SET}.tgt
#             done
#         fi
#     done

# done

# prepare data for the bidirectional model
echo "PREPROCESSING en <> vi DATA: $PWD"
for SET in $DATA_NAME ; do
    $NORM  < ${DATA}/${SET}.en | $TOK -l $SRC -q | $DEES | awk -vtgt_tag="<${SRC}2${TGT}>" '{ print tgt_tag" "$0 }' >> ${PROCESSED_DATA}/${SET}.src
    cat ${DATA}/${SET}.vi | awk -vtgt_tag="<${TGT}2${SRC}>" '{ print tgt_tag" "$0 }' >> ${PROCESSED_DATA}/${SET}.src

    cat ${DATA}/${SET}.vi  >> ${PROCESSED_DATA}/${SET}.tgt
    $NORM < ${DATA}/${SET}.en | $TOK -l $SRC -q | $DEES >> ${PROCESSED_DATA}/${SET}.tgt
done

# learn bpe model with training data
if [ ! -d $BPE_MODEL ]; then  
  mkdir $BPE_MODEL
  echo "LEARNING BPE MODEL: $BPE_MODEL"
  subword-nmt learn-joint-bpe-and-vocab --input ${PROCESSED_DATA}/train.src ${PROCESSED_DATA}/train.tgt \
					-s $BPESIZE -o $BPE_MODEL/code.${BPESIZE}.bpe \
					--write-vocabulary $BPE_MODEL/train.src.vocab $BPE_MODEL/train.tgt.vocab 
fi

# apply sub-word segmentation
if [ ! -d $BPE_DATA ]; then
    mkdir $BPE_DATA

    for SET in $DATA_NAME; do
        subword-nmt apply-bpe -c $BPE_MODEL/code.${BPESIZE}.bpe < ${PROCESSED_DATA}/${SET}.src > $BPE_DATA/${SET}.src 
        subword-nmt apply-bpe -c $BPE_MODEL/code.${BPESIZE}.bpe < ${PROCESSED_DATA}/${SET}.tgt > $BPE_DATA/${SET}.tgt
    done
fi

# binarize train/valid/test
if [ ! -d $BIN_DATA ]; then
    mkdir $BIN_DATA
    fairseq-preprocess -s src -t tgt \
				--destdir $BIN_DATA \
				--trainpref $BPE_DATA/train \
				--validpref $BPE_DATA/dev \
				--testpref $BPE_DATA/test \
				--joined-dictionary \
				--workers 32 
fi