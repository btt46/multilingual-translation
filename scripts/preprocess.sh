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
TRUECASER_TRAIN=$MOSES/recaser/train-truecaser.perl
TRUECASER=$MOSES/recaser/truecase.perl

FARISEQ=$PWD/fairseq

BPE_MODEL=$PWD/data/bpe-model

# data 
DATA_FOLDER=$PWD/data
RAW_DATA=$DATA_FOLDER/iwslt15
DATA=$DATA_FOLDER/data
PROCESSED_DATA=$DATA_FOLDER/processed-data
NORMALIZED_DATA=$DATA_FOLDER/normalized
TOKENIZED_DATA=$DATA_FOLDER/tok
TRUECASED_DATA=$DATA_FOLDER/truecased
BPE_DATA=$PWD/data/bpe-data
BIN_DATA=$PWD/data/bin-data

DATA_NAME="train valid test"

TEXT_PROCESS=$PWD/text-process
SCRIPTS=$PWD/scripts
# ***************************************
rm -rf $DATA
rm -rf $PROCESSED_DATA
rm -rf $NORMALIZED_DATA
rm -rf $TOKENIZED_DATA
rm -rf $TRUECASED_DATA
rm -rf $BPE_MODEL
rm -rf $BPE_DATA
rm -rf $BIN_DATA


mkdir -p $DATA
mkdir -p $PROCESSED_DATA
mkdir -p $NORMALIZED_DATA
mkdir -p $TOKENIZED_DATA
mkdir -p $TRUECASED_DATA

# remove rarewords and exporting a data
# python3.6 ${TEXT_PROCESS}/remove-rare.py ${RAW_DATA}/train.en ${DATA}/train.en
# python3.6 ${TEXT_PROCESS}/remove-rare.py ${RAW_DATA}/train.vi ${DATA}/train.vi

for lang in en vi; do
    cp ${RAW_DATA}/train.${lang} ${DATA}/train.${lang}
    cp ${RAW_DATA}/tst2012.${lang} ${DATA}/valid.${lang}
    cp ${RAW_DATA}/tst2013.${lang} ${DATA}/test.${lang}
done

# normalization
echo "=> normalizing..."
for lang in en vi; do
    echo "[$lang]..."
    for set in $DATA_NAME; do
        echo "$set..."
        python3.6 ${TEXT_PROCESS}/normalize.py ${DATA}/${set}.${lang}  ${NORMALIZED_DATA}/${set}.${lang}
    done
done

# Tokenization
echo "=> tokenize..."
for SET in $DATA_NAME ; do
    $TOK -l en < ${NORMALIZED_DATA}/${SET}.en > ${TOKENIZED_DATA}/${SET}.en
    python3.6 ${TEXT_PROCESS}/tokenize-vi.py  ${NORMALIZED_DATA}/${SET}.vi ${TOKENIZED_DATA}/${SET}.vi
done

# Truecaser
echo "=> Truecasing..."

echo "Traning for english..."
$TRUECASER_TRAIN --model truecase-model.en --corpus ${TOKENIZED_DATA}/train.en

echo "Traning for vietnamese..."
$TRUECASER_TRAIN --model truecase-model.vi --corpus ${TOKENIZED_DATA}/train.vi

for lang in en vi; do
    echo "[$lang]..."
    for set in $DATA_NAME; do
        echo "${set}..."
        $TRUECASER --model truecase-model.${lang} < ${TOKENIZED_DATA}/${set}.${lang} > ${TRUECASED_DATA}/${set}.${lang}
    done
done

# prepare data for the bidirectional model
echo "=> PREPROCESSING en <> vi DATA: $PWD....."
for SET in $DATA_NAME ; do
    # cat ${TRUECASED_DATA}/${SET}.en | awk -vtgt_tag="<e2v>" '{ print tgt_tag" "$0 }' >> ${PROCESSED_DATA}/${SET}.src
    # cat ${TRUECASED_DATA}/${SET}.vi | awk -vtgt_tag="<v2e>" '{ print tgt_tag" "$0 }' >> ${PROCESSED_DATA}/${SET}.src

    # cat ${TRUECASED_DATA}/${SET}.vi  >> ${PROCESSED_DATA}/${SET}.tgt
    # cat ${TRUECASED_DATA}/${SET}.en  >> ${PROCESSED_DATA}/${SET}.tgt
    python3.6 $SCRIPTS/merge-file.py -s1 ${TRUECASED_DATA}/${SET}.en -s2 ${TRUECASED_DATA}/${SET}.vi -msrc ${PROCESSED_DATA}/${SET}.src \
                                     -t1 ${TRUECASED_DATA}/${SET}.vi -t2 ${TRUECASED_DATA}/${SET}.en -mtgt ${PROCESSED_DATA}/${SET}.tgt

done

# learn bpe model with training data
if [ ! -d $BPE_MODEL ]; then  
  mkdir $BPE_MODEL
  echo "=> LEARNING BPE MODEL: $BPE_MODEL"
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

for SET in $DATA_NAME; do
    python3.6 $SCRIPTS/addTag.py -f $BPE_DATA/${SET}.src -p1 1 -t1 "<e2v>" -p2 2 -t "<v2e>" 
done

# binarize train/valid/test
if [ ! -d $BIN_DATA ]; then
    mkdir $BIN_DATA
    fairseq-preprocess -s src -t tgt \
				--destdir $BIN_DATA \
				--trainpref $BPE_DATA/train \
				--validpref $BPE_DATA/valid \
				--testpref $BPE_DATA/test \
				--joined-dictionary \
				--workers 32 
fi