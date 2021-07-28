#!/bin/bash

GPUS=$1
DATA_FOLDER=$PWD/data
PROCESSED_DATA=$DATA_FOLDER/processed-data
MODEL=$PWD/models/model/checkpoint_best.pt
BLEU=$PWD/mosesdecoder/scripts/generic/multi-bleu.perl
REF_EN=$DATA_FOLDER/data/test.en
REF_VI=$DATA_FOLDER/data/test.vi

mkdir -p $PWD/test
TEST=$PWD/test

CUDA_VISIBLE_DEVICES=GPUS env LC_ALL=en_US.UTF-8 fairseq-interactive \
            --input $PROCESSED_DATA/test.src \
            --path MODEL \
            --beam 5 | tee $TEST/test.result

cat $TEST/test.result | head -n 1268 | sed -r 's/(@@ )|(@@ ?$)//g'  > test.result.vi
cat $TEST/test.result | tail -n +1269 | sed -r 's/(@@ )|(@@ ?$)//g' > test.result.en

# English to Vietnamese
echo "En > Vi"
env LC_ALL=en_US.UTF-8 perl BLEU REF_VI < test.result.vi

# Vietnamese to English
echo "Vi > En"
env LC_ALL=en_US.UTF-8 perl BLEU REF_EN < test.result.en

