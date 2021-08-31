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
MODEL=$PWD/models/model/checkpoint_best.pt


BLEU=$PWD/multi-bleu.perl

# test data
mkdir -p $PWD/test
TEST=$PWD/test

REF_EN=$DATA_FOLDER/data/test.en
REF_VI=$DATA_FOLDER/data/test.vi

HYP_EN=$TEST/hyp.en
HYP_VI=$TEST/hyp.vi

CUDA_VISIBLE_DEVICES=$GPUS env LC_ALL=en_US.UTF-8 fairseq-interactive $BIN_DATA \
            --input $BPE_DATA/test.${SRC} \
            --path $MODEL \
            --beam 5 | tee $TEST/translation.result.${TGT}



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
