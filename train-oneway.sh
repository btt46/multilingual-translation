#!/bin/bash

GPUS=$1
SRC=$2
TGT=$3
echo "GPU=${GPUS}"
DATA=$PWD/data/oneway/bin-data	
MODEL=$PWD/models/${SRC}2${TGT}.model	
mkdir -p $MODEL
mkdir -p $PWD/log
LOG=$PWD/log


CUDA_VISIBLE_DEVICES=$GPUS fairseq-train $DATA -s ${SRC} -t ${TGT} \
            --log-interval 100 \
			--log-format json \
			--max-epoch 30 \
    		--optimizer adam --lr 0.0001 \
			--clip-norm 0.0 \
			--max-tokens 4096 \
			--no-progress-bar \
			--log-interval 100 \
			--min-lr '1e-09' \
			--weight-decay 0.0001 \
			--criterion label_smoothed_cross_entropy \
			--label-smoothing 0.1 \
			--lr-scheduler inverse_sqrt \
			--warmup-updates 4000 \
			--warmup-init-lr '1e-08' \
			--adam-betas '(0.9, 0.98)' \
			--arch transformer_iwslt_de_en \
			--dropout 0.1 \
			--attention-dropout 0.1 \
			--save-dir $MODEL \
			2>&1 | tee $LOG/log.train.${MODEL_NAME}

echo "TRAINING LOG: $LOG"