GPUS=$1
SRC=$2
TGT=$3

MOSES=$PWD/mosesdecoder/scripts
DETRUECASER=$MOSES/recaser/detruecase.perl

# prepare data for evaluating a model
DATA_FOLDER=$PWD/data
PROCESSED_DATA=$DATA_FOLDER/processed-data
BIN_DATA=$DATA_FOLDER/oneway/bin-data
BPE_DATA=$DATA_FOLDER/oneway/bpe-data
DETOK=$PWD/text-process/detokenize.py




BLEU=$PWD/multi-bleu.perl

# test data
mkdir -p $PWD/test-oneway
TEST=$PWD/test-oneway

TEST_HYP=$TEST/test.hyp.${TGT}
TEST_REF=$DATA_FOLDER/data/test.${TGT}

VALID_HYP=$TEST/valid.hyp.${TGT}
VALID_REF=$DATA_FOLDER/data/valid.${TGT}

echo >  $TEST/${SRC}2${TGT}.eval.result
for i in 21 22 23 24 25 26 27 28 29 30
do
	# The model used for evaluate
	MODEL=$PWD/models/${SRC}2${TGT}.model/checkpoint${i}.pt
	echo "${MODEL}" >> $TEST/${SRC}2${TGT}.eval.result
	CUDA_VISIBLE_DEVICES=$GPUS env LC_ALL=en_US.UTF-8 fairseq-interactive $BIN_DATA \
	            --input $BPE_DATA/test.${SRC} \
	            --path $MODEL \
	            --beam 5 | tee ${TEST}/test.translation.result.${TGT}

	grep ^H $TEST/test.translation.result.${TGT}| cut -f3 > $TEST/test.result
	cat $TEST/test.result | sed -r 's/(@@ )|(@@ ?$)//g' > ${TEST}/test.result.${TGT}

	# detruecase
	$DETRUECASER < ${TEST}/test.result.${TGT} > ${TEST}/test.detruecase.${TGT}

	# detokenize
	python3.6 $DETOK ${TEST}/test.detruecase.${TGT} $TEST_HYP


	# English to Vietnamese
	echo "TEST" >> $TEST/${SRC}2${TGT}.eval.result
	echo "${SRC} > ${TGT}" >> $TEST/${SRC}2${TGT}.eval.result
	env LC_ALL=en_US.UTF-8 perl $BLEU $TEST_REF < $TEST_HYP >> $TEST/${SRC}2${TGT}.eval.result



	#### validation
	CUDA_VISIBLE_DEVICES=$GPUS env LC_ALL=en_US.UTF-8 fairseq-interactive $BIN_DATA \
	            --input $BPE_DATA/valid.${SRC} \
	            --path $MODEL \
	            --beam 5 | tee ${TEST}/valid.translation.result.${TGT}

	grep ^H $TEST/valid.translation.result.${TGT}| cut -f3 > $TEST/valid.result
	cat $TEST/valid.result | sed -r 's/(@@ )|(@@ ?$)//g' > ${TEST}/valid.result.${TGT}

	# detruecase
	$DETRUECASER < ${TEST}/valid.result.${TGT} > ${TEST}/valid.detruecase.${TGT}

	# detokenize
	python3.6 $DETOK ${TEST}/valid.detruecase.${TGT} $VALID_HYP

	# English to Vietnamese
	echo "VALID" >> $TEST/${SRC}2${TGT}.eval.result
	echo "${SRC} > ${TGT}" >> $TEST/${SRC}2${TGT}.eval.result
	env LC_ALL=en_US.UTF-8 perl $BLEU $VALID_REF < $VALID_HYP >> $TEST/${SRC}2${TGT}.eval.result
done

