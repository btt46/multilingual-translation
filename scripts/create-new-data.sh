#!/bin/bash
set -e

BPESIZE=5000
GPUS=$1
SRC=$2
TGT=$3
SEED=$4
TEMP=$5
NUM=$6
echo "GPU: $GPUS"
echo "$SRC -> $TGT"
# the directories for new data 
DATA_FOLDER=$PWD/data
NEW_DATA_FOLDER=$DATA_FOLDER/new-data-random
NEW_BPE_DATA=$NEW_DATA_FOLDER/bpe-data
NEW_BIN_DATA=$NEW_DATA_FOLDER/bin-data
TRANSLATION_DATA=$NEW_DATA_FOLDER/translation-data
NEW_DATA=$NEW_DATA_FOLDER/new-data
NEW_PROCESSED_DATA=$NEW_DATA_FOLDER/processed-data
PROCESSED_DATA=$DATA_FOLDER/processed-data
DETOK=$PWD/text-process/detokenize.py

# The model used for evaluate
MODEL=$PWD/models/model.bi/checkpoint_best.pt
NEW_BPE_MODEL=$NEW_DATA_FOLDER/bpe-model

BIN_DATA=$DATA_FOLDER/bin-data

UNIDATA=$DATA_FOLDER/unidirect-data
BPE_DATA=$UNIDATA/bpe-data
BPE_MODEL=$DATA_FOLDER/bpe-model

DATA_NAME="train valid test"
TRUECASED_DATA=$DATA_FOLDER/truecased

# rm -rf $NEW_DATA_FOLDER
# rm -rf $NEW_DATA
# rm -rf $NEW_BPE_DATA
# rm -rf $NEW_BIN_DATA
# rm -rf $TRANSLATION_DATA
# rm -rf $NEW_DATA
# rm -rf $NEW_PROCESSED_DATA
# rm -rf $NEW_BPE_MODEL

mkdir -p $NEW_DATA_FOLDER
mkdir -p $NEW_DATA
mkdir -p $NEW_BPE_DATA
mkdir -p $NEW_BIN_DATA
mkdir -p $TRANSLATION_DATA
mkdir -p $NEW_DATA
mkdir -p $NEW_PROCESSED_DATA
mkdir -p $NEW_BPE_MODEL

TAG=""

if [ "${SRC}" = "en" ] ; then
	TAG="<e2v>"
fi

if [ "${SRC}" = "vi" ] ; then
	TAG="<v2e>"
fi 

echo "${TAG}"


if [ $NUM -lt 9 ]; then
      cat ${BPE_DATA}/train.${SRC} | awk -vtgt_tag="${TAG}" '{ print tgt_tag" "$0 }' > ${TRANSLATION_DATA}/translation.${SRC}		
      if [ $NUM -gt 0 ] ; then		
            echo "random"			
            CUDA_VISIBLE_DEVICES=$GPUS env LC_ALL=en_US.UTF-8 fairseq-interactive $BIN_DATA \
                        --input ${TRANSLATION_DATA}/translation.${SRC} \
                        --sampling \
                        --seed ${SEED} \
                        --sampling-topk -1 \
                        --nbest 1\
                        --beam 1\
            		--temperature ${TEMP} \
                        --path $MODEL  | tee $NEW_DATA/result.${TGT}.${NUM}
      fi

      if [ $NUM -eq 0 ]; then     
            echo "beam"                    
            CUDA_VISIBLE_DEVICES=$GPUS env LC_ALL=en_US.UTF-8 fairseq-interactive $BIN_DATA \
                        --input ${TRANSLATION_DATA}/translation.${SRC} \
                        --beam 5 \
                        --path $MODEL  | tee $NEW_DATA/result.${TGT}.${NUM}

      fi

      grep ^H ${NEW_DATA}/result.${TGT}.${NUM} | cut -f3 > ${NEW_DATA}/data.${TGT}.${NUM}

      cat ${NEW_DATA}/data.${TGT}.${NUM}  | sed -r 's/(@@ )|(@@ ?$)//g'  > $NEW_DATA/new.tok.${TGT}.${NUM} 

      if [ "${SRC}" = "en" ] ; then
            python3.6 $DETOK $NEW_DATA/new.tok.${TGT}.${NUM} $NEW_DATA/new.${TGT}.${NUM}
      fi

      if [ "${SRC}" = "vi" ] ; then
            cp $NEW_DATA/new.tok.${TGT}.${NUM} $NEW_DATA/new.${TGT}.${NUM}
      fi

fi 

if [ $NUM -ge 9 ] ; then
      echo "beam IBT"  
      MODEL=$PWD/models/model.bi.BT0.new/checkpoint26.pt
      BIN_DATA=$DATA_FOLDER/new-data-random/bin-data-0
      subword-nmt apply-bpe -c ${BPE_MODEL}/code.${BPESIZE}.bpe < ${NEW_DATA}/new.${SRC}.0 > ${NEW_DATA}/ibt.bpe.translation.${SRC}.${NUM}

      cat ${NEW_DATA}/ibt.bpe.translation.${SRC}.${NUM} | awk -vtgt_tag="${TAG}" '{ print tgt_tag" "$0 }' > ${NEW_DATA}/ibt.translation.${SRC}.${NUM}  

      # NUM == 9
      # CUDA_VISIBLE_DEVICES=$GPUS env LC_ALL=en_US.UTF-8 fairseq-interactive $BIN_DATA \
      #             --input ${NEW_DATA}/ibt.translation.${SRC}.${NUM}   \
      #             --beam 5 \
      #             --path $MODEL  | tee $NEW_DATA/result.ibt.${TGT}.${NUM}

      # # NUM == 10
      # CUDA_VISIBLE_DEVICES=$GPUS env LC_ALL=en_US.UTF-8 fairseq-interactive $BIN_DATA \
      #             --input ${TRANSLATION_DATA}/translation.${SRC}   \
      #             --beam 5 \
      #             --path $MODEL  | tee $NEW_DATA/result.ibt.${TGT}.${NUM}


      # NUM == 11
      CUDA_VISIBLE_DEVICES=$GPUS env LC_ALL=en_US.UTF-8 fairseq-interactive $BIN_DATA \
                  --input ${TRANSLATION_DATA}/translation.${SRC}   \
                   --sampling \
                  --seed ${SEED} \
                  --sampling-topk -1 \
                  --nbest 1\
                  --beam 1\
                  --temperature ${TEMP} \
                  --path $MODEL  | tee $NEW_DATA/result.ibt.${TGT}.${NUM}




      grep ^H ${NEW_DATA}/result.ibt.${TGT}.${NUM} | cut -f3 > ${NEW_DATA}/data.ibt.${TGT}.${NUM}

      cat ${NEW_DATA}/data.ibt.${TGT}.${NUM}  | sed -r 's/(@@ )|(@@ ?$)//g'  > $NEW_DATA/ibt.new.tok.${TGT}.${NUM} 

      if [ "${SRC}" = "en" ] ; then
      	python3.6 $DETOK $NEW_DATA/ibt.new.tok.${TGT}.${NUM} $NEW_DATA/ibt.new.${TGT}.${NUM}
      fi

      if [ "${SRC}" = "vi" ] ; then
      	cp $NEW_DATA/ibt.new.tok.${TGT}.${NUM} $NEW_DATA/ibt.new.${TGT}.${NUM}
      fi

fi


#####
# (update)
## model.bi.BT0.new seed: 0 temperature 0.0 beam-search
## model.bi.BT1.new seed: 10011 temperature 0.1
## model.bi.BT2.new seed: 10012 temperature 0.2
## model.bi.BT3.new seed: 10013 temperature 0.3
## model.bi.BT4.new seed: 10014 temperature 0.4
## model.bi.BT5.new seed: 10015 temperature 0.5
## model.bi.BT6.new seed: 10016 temperature 0.6
## model.bi.BT7.new seed: 10017 temperature 0.7
## model.bi.BT8.new seed: 10018 temperature 0.8
## model.bi.IBT0.new seed: 10019 temperature 0.0 beam-search

########3
# (old)
## model.bi.BT1 seed: 10001 temperature 0.8
## model.bi.BT2 seed: 10002 temperature 0.7
## model.bi.BT3 seed: 10003 temperature 0.6
## model.bi.BT4 seed: 10004 temperature 0.5
## model.bi.BT5 seed: 10005 temperature 0.4
## model.bi.BT6 seed: 10006 temperature 0.3
