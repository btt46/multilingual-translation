#!/bin/bash

GPUS=$1

# prepare data for evaluating a model
DATA_FOLDER=$PWD/data
PROCESSED_DATA=$DATA_FOLDER/processed-data
BIN_DATA=$DATA_FOLDER/bin-data

# The model used for evaluate
MODEL=$PWD/models/model/checkpoint_best.pt


BLEU=$PWD/mosesdecoder/scripts/generic/multi-bleu.perl

# test data
mkdir -p $PWD/test
TEST=$PWD/test

REF_EN=$DATA_FOLDER/data/test.en
REF_VI=$DATA_FOLDER/data/test.vi

HYP_EN=$TEST/test.en
HYP_VI=$TEST/test.vi

CUDA_VISIBLE_DEVICES=$GPUS env LC_ALL=en_US.UTF-8 fairseq-interactive $BIN_DATA \
            --input $PROCESSED_DATA/test.src \
            --path $MODEL \
            --beam 5 | tee $TEST/test.translation

grep ^H $TEST/test.translation| cut -f3 > $TEST/test.result

# the size of a test file is 1268
cat $TEST/test.result | head -n 1268 | sed -r 's/(@@ )|(@@ ?$)//g'  > $HYP_VI
cat $TEST/test.result | tail -n +1269 | sed -r 's/(@@ )|(@@ ?$)//g' > $HYP_EN

# English to Vietnamese
echo "En > Vi"
env LC_ALL=en_US.UTF-8 perl BLEU REF_VI < $HYP_VI

# Vietnamese to English
echo "Vi > En"
env LC_ALL=en_US.UTF-8 perl BLEU REF_EN < $HYP_EN

