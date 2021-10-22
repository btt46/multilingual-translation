#!/bin/bash

GPUS=$1

MOSES=$PWD/mosesdecoder/scripts
DETRUECASER=$MOSES/recaser/detruecase.perl

# prepare data for evaluating a model
DATA_FOLDER=$PWD/data
PROCESSED_DATA=$DATA_FOLDER/processed-data
# BIN_DATA=$DATA_FOLDER/new-data-random/bin-data
# BPE_DATA=$DATA_FOLDER/new-data-random/bpe-data
BIN_DATA=$DATA_FOLDER/bin-data
BPE_DATA=$DATA_FOLDER/bpe-data
DETOK=$PWD/text-process/detokenize.py

# The model used for evaluate
MODEL=$PWD/models/model.bi/checkpoint_best.pt
# MODEL=$PWD/models/model_06/checkpoint_best.pt

BLEU=$PWD/multi-bleu.perl

# test data
mkdir -p $PWD/test
TEST=$PWD/test

REF_EN=$DATA_FOLDER/data/test.en
REF_VI=$DATA_FOLDER/data/test.vi

VALID_REF_EN=$DATA_FOLDER/data/valid.en
VALID_REF_VI=$DATA_FOLDER/data/valid.vi

HYP_EN=$TEST/hyp.en
HYP_VI=$TEST/hyp.vi

VALID_HYP_EN=$TEST/dev_hyp.en
VALID_HYP_VI=$TEST/dev_hyp.vi

############################################################################################
CUDA_VISIBLE_DEVICES=$GPUS env LC_ALL=en_US.UTF-8 fairseq-interactive $BIN_DATA \
            --input $BPE_DATA/test.src \
            --path $MODEL \
            --beam 5 | tee $TEST/translation.result

grep ^H $TEST/translation.result| cut -f3 > $TEST/test.result

# the size of a test file is 1268.
# 普通文字に戻す
# cat $TEST/test.result | head -n 1268 | sed -r 's/(@@ )|(@@ ?$)//g'  > $PWD/test/result.vi
# cat $TEST/test.result | tail -n +1269 | sed -r 's/(@@ )|(@@ ?$)//g' > $PWD/test/result.en

cat $TEST/test.result | awk 'NR % 2 == 1' | sed -r 's/(@@ )|(@@ ?$)//g'  > $PWD/test/result.vi
cat $TEST/test.result | awk 'NR % 2 == 0'| sed -r 's/(@@ )|(@@ ?$)//g' > $PWD/test/result.en

# detruecase
$DETRUECASER < $PWD/test/result.vi > $PWD/test/detruecase.vi
$DETRUECASER < $PWD/test/result.en > $PWD/test/detruecase.en

# detokenize
python3.6 $DETOK $PWD/test/detruecase.vi $HYP_VI
python3.6 $DETOK $PWD/test/detruecase.en $HYP_EN

# English to Vietnamese
echo "En > Vi"
env LC_ALL=en_US.UTF-8 perl $BLEU $REF_VI < $HYP_VI

# Vietnamese to English
echo "Vi > En"
env LC_ALL=en_US.UTF-8 perl $BLEU $REF_EN < $HYP_EN


####### DEV ######
# CUDA_VISIBLE_DEVICES=$GPUS env LC_ALL=en_US.UTF-8 fairseq-interactive $BIN_DATA \
#             --input $BPE_DATA/valid.src \
#             --path $MODEL \
#             --beam 5 | tee $TEST/translation.valid.result

# grep ^H $TEST/translation.valid.result| cut -f3 > $TEST/valid.result

# # the size of a test file is 1268.
# # 普通文字に戻す
# # cat $TEST/test.result | head -n 1268 | sed -r 's/(@@ )|(@@ ?$)//g'  > $PWD/test/result.vi
# # cat $TEST/test.result | tail -n +1269 | sed -r 's/(@@ )|(@@ ?$)//g' > $PWD/test/result.en

# cat $TEST/valid.result | awk 'NR % 2 == 1' | sed -r 's/(@@ )|(@@ ?$)//g'  > $PWD/test/valid.result.vi
# cat $TEST/valid.result | awk 'NR % 2 == 0'| sed -r 's/(@@ )|(@@ ?$)//g' > $PWD/test/valid.result.en

# # detruecase
# $DETRUECASER < $PWD/test/valid.result.vi > $PWD/test/valid_detruecase.vi
# $DETRUECASER < $PWD/test/valid.result.en > $PWD/test/valid_detruecase.en

# # detokenize
# python3.6 $DETOK $PWD/test/valid_detruecase.vi $VALID_HYP_VI
# python3.6 $DETOK $PWD/test/valid_detruecase.en $VALID_HYP_EN

# # English to Vietnamese
# echo "En > Vi"
# env LC_ALL=en_US.UTF-8 perl $BLEU $VALID_REF_VI < $VALID_HYP_VI

# # Vietnamese to English
# echo "Vi > En"
# env LC_ALL=en_US.UTF-8 perl $BLEU $VALID_REF_EN < $VALID_HYP_EN





##############################################################################################
# HYP_EN_2=$TEST/hyp.en.2
# HYP_VI_2=$TEST/hyp.vi.2

# CUDA_VISIBLE_DEVICES=$GPUS env LC_ALL=en_US.UTF-8 fairseq-interactive $BIN_DATA \
#             --input $BPE_DATA/test.src \
#             --sampling  \
#             --sampling-topk -1 \
#             --beam 1\
#             --nbest 1\
#             --temperature 0.6\
#             --path $MODEL \
#             --seed 10000 | tee $TEST/translation.result.2

# grep ^H $TEST/translation.result.2| cut -f3 > $TEST/test.result.2

# # # the size of a test file is 1268.
# # 普通文字に戻す
# # cat $TEST/test.result | head -n 1268 | sed -r 's/(@@ )|(@@ ?$)//g'  > $PWD/test/result.vi
# # cat $TEST/test.result | tail -n +1269 | sed -r 's/(@@ )|(@@ ?$)//g' > $PWD/test/result.en

# cat $TEST/test.result.2 | awk 'NR % 2 == 1' | sed -r 's/(@@ )|(@@ ?$)//g'  > $PWD/test/result.vi.2
# cat $TEST/test.result.2 | awk 'NR % 2 == 0'| sed -r 's/(@@ )|(@@ ?$)//g' > $PWD/test/result.en.2

# # detruecase
# $DETRUECASER < $PWD/test/result.vi.2 > $PWD/test/detruecase.vi.2
# $DETRUECASER < $PWD/test/result.en.2 > $PWD/test/detruecase.en.2

# # detokenize
# python3.6 $DETOK $PWD/test/detruecase.vi.2 $HYP_VI_2
# python3.6 $DETOK $PWD/test/detruecase.en.2 $HYP_EN_2

# # English to Vietnamese
# echo "En > Vi"
# env LC_ALL=en_US.UTF-8 perl $BLEU $REF_VI < $HYP_VI_2

# # Vietnamese to English
# echo "Vi > En"
# env LC_ALL=en_US.UTF-8 perl $BLEU $REF_EN < $HYP_EN_2	


