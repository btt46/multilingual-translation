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

# The model used for evaluate
MODEL=$PWD/models/${SRC}-${TGT}.model/checkpoint_best.pt


BLEU=$PWD/multi-bleu.perl

# test data
mkdir -p $PWD/test-oneway
TEST=$PWD/test-oneway

HYP=$TEST/hyp.${TGT}
REF=$DATA_FOLDER/data/test.${TGT}


CUDA_VISIBLE_DEVICES=$GPUS env LC_ALL=en_US.UTF-8 fairseq-interactive $BIN_DATA \
            --input $BPE_DATA/test.${SRC} \
            --path $MODEL \
            --beam 5 | tee ${TEST}/translation.result.${TGT}

grep ^H $TEST/translation.result.${TGT}| cut -f3 > $TEST/test.result

# detruecase
$DETRUECASER < ${TEST}/test.result.${TGT} > ${TEST}/detruecase.${TGT}

# detokenize
python3.6 $DETOK ${TEST}/detruecase.${TGT} $HYP

# English to Vietnamese
echo "${SRC} > ${TGT}"
env LC_ALL=en_US.UTF-8 perl $BLEU $REF < $HYP

# Vietnamese to English

