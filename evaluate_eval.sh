#!/bin/bash

GPUS=$1
MODEL_NAME=$2
NUM=$3

MOSES=$PWD/mosesdecoder/scripts
DETRUECASER=$MOSES/recaser/detruecase.perl

# prepare data for evaluating a model
DATA_FOLDER=$PWD/data
PROCESSED_DATA=$DATA_FOLDER/processed-data

# if [ $NUM -gt 1 ]; then
echo "$NUM"
BIN_DATA=$DATA_FOLDER/new-data-random/bin-data-${NUM}
BPE_DATA=$DATA_FOLDER/new-data-random/bpe-data-${NUM}
# fi

# if [ $NUM -eq 1 ]; then
# 	echo "$NUM default"
# 	BIN_DATA=$DATA_FOLDER/new-data-random/bin-data
# 	BPE_DATA=$DATA_FOLDER/new-data-random/bpe-data
# fi

if [ $NUM -lt 0 ]; then
	echo "$NUM base"
	BIN_DATA=$DATA_FOLDER/bin-data
	BPE_DATA=$DATA_FOLDER/bpe-data
fi

DETOK=$PWD/text-process/detokenize.py



# MODEL=$PWD/models/model_06/checkpoint_best.pt

BLEU=$PWD/multi-bleu.perl

# test data
mkdir -p $PWD/test
TEST=$PWD/test

REF_EN=$DATA_FOLDER/data/test.en
REF_VI=$DATA_FOLDER/data/test.vi

VALID_REF_EN=$DATA_FOLDER/data/valid.en
VALID_REF_VI=$DATA_FOLDER/data/valid.vi

HYP_EN=$TEST/hyp.en.${NUM}
HYP_VI=$TEST/hyp.vi.${NUM}

VALID_HYP_EN=$TEST/dev_hyp.en.${NUM}
VALID_HYP_VI=$TEST/dev_hyp.vi.${NUM}

echo >  $TEST/${MODEL_NAME}.eval.result

############################################################################################

for i in 21 22 23 24 25 26 27 28 29 30
do
	echo "${MODEL_NAME}/checkpoint${i}.pt" >> $TEST/${MODEL_NAME}.eval.result
	# The model used for evaluate
	MODEL=$PWD/models/${MODEL_NAME}/checkpoint${i}.pt
	CUDA_VISIBLE_DEVICES=$GPUS env LC_ALL=en_US.UTF-8 fairseq-interactive $BIN_DATA \
	            --input $BPE_DATA/test.src \
	            --path $MODEL \
	            --beam 5 | tee $TEST/translation.result.${NUM}

	grep ^H $TEST/translation.result.${NUM}| cut -f3 > $TEST/test.result.${NUM}

	# the size of a test file is 1268.
	# 普通文字に戻す
	# cat $TEST/test.result | head -n 1268 | sed -r 's/(@@ )|(@@ ?$)//g'  > $PWD/test/result.vi
	# cat $TEST/test.result | tail -n +1269 | sed -r 's/(@@ )|(@@ ?$)//g' > $PWD/test/result.en

	cat $TEST/test.result.${NUM} | awk 'NR % 2 == 1' | sed -r 's/(@@ )|(@@ ?$)//g'  > $PWD/test/result.vi.${NUM}
	cat $TEST/test.result.${NUM} | awk 'NR % 2 == 0'| sed -r 's/(@@ )|(@@ ?$)//g' > $PWD/test/result.en.${NUM}

	# detruecase
	$DETRUECASER < $PWD/test/result.vi.${NUM} > $PWD/test/detruecase.vi.${NUM}
	$DETRUECASER < $PWD/test/result.en.${NUM} > $PWD/test/detruecase.en.${NUM}

	# detokenize
	python3.6 $DETOK $PWD/test/detruecase.vi.${NUM} $HYP_VI
	python3.6 $DETOK $PWD/test/detruecase.en.${NUM} $HYP_EN

	# English to Vietnamese
	echo "TEST" >> $TEST/${MODEL_NAME}.eval.result
	echo "En > Vi" >> $TEST/${MODEL_NAME}.eval.result
	env LC_ALL=en_US.UTF-8 perl $BLEU $REF_VI < $HYP_VI >> $TEST/${MODEL_NAME}.eval.result

	# Vietnamese to English
	echo "Vi > En"  >> $TEST/${MODEL_NAME}.eval.result
	env LC_ALL=en_US.UTF-8 perl $BLEU $REF_EN < $HYP_EN >> $TEST/${MODEL_NAME}.eval.result


	####### DEV ######
	CUDA_VISIBLE_DEVICES=$GPUS env LC_ALL=en_US.UTF-8 fairseq-interactive $BIN_DATA \
	            --input $BPE_DATA/valid.src \
	            --path $MODEL \
	            --beam 5 | tee $TEST/translation.valid.result.${NUM}

	grep ^H $TEST/translation.valid.result.${NUM} | cut -f3 > $TEST/valid.result.${NUM}

	# the size of a test file is 1268.
	# 普通文字に戻す
	# cat $TEST/test.result | head -n 1268 | sed -r 's/(@@ )|(@@ ?$)//g'  > $PWD/test/result.vi
	# cat $TEST/test.result | tail -n +1269 | sed -r 's/(@@ )|(@@ ?$)//g' > $PWD/test/result.en

	cat $TEST/valid.result.${NUM} | awk 'NR % 2 == 1' | sed -r 's/(@@ )|(@@ ?$)//g'  > $PWD/test/valid.result.vi.${NUM}
	cat $TEST/valid.result.${NUM} | awk 'NR % 2 == 0'| sed -r 's/(@@ )|(@@ ?$)//g' > $PWD/test/valid.result.en.${NUM}

	# detruecase
	$DETRUECASER < $PWD/test/valid.result.vi.${NUM} > $PWD/test/valid_detruecase.vi.${NUM}
	$DETRUECASER < $PWD/test/valid.result.en.${NUM} > $PWD/test/valid_detruecase.en.${NUM}

	# detokenize
	python3.6 $DETOK $PWD/test/valid_detruecase.vi.${NUM} $VALID_HYP_VI
	python3.6 $DETOK $PWD/test/valid_detruecase.en.${NUM} $VALID_HYP_EN

	# English to Vietnamese
	echo "VALID" >> $TEST/${MODEL_NAME}.eval.result
	echo "En > Vi" >> $TEST/${MODEL_NAME}.eval.result
	env LC_ALL=en_US.UTF-8 perl $BLEU $VALID_REF_VI < $VALID_HYP_VI >> $TEST/${MODEL_NAME}.eval.result

	# Vietnamese to English
	echo "Vi > En" >> $TEST/${MODEL_NAME}.eval.result
	env LC_ALL=en_US.UTF-8 perl $BLEU $VALID_REF_EN < $VALID_HYP_EN >> $TEST/${MODEL_NAME}.eval.result
done








