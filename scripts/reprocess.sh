#!/bin/bash
set -e

BPESIZE=5000
NUM=$1
CHOOSE_BPE=$2
# the directories for new data 
DATA_FOLDER=$PWD/data
NEW_DATA_FOLDER=$DATA_FOLDER/new-data-random
NEW_BPE_DATA=$NEW_DATA_FOLDER/bpe-data-${NUM}
NEW_BIN_DATA=$NEW_DATA_FOLDER/bin-data-${NUM}
TRANSLATION_DATA=$NEW_DATA_FOLDER/translation-data
NEW_DATA=$NEW_DATA_FOLDER/new-data
NEW_PROCESSED_DATA=$NEW_DATA_FOLDER/processed-data-${NUM}
PROCESSED_DATA=$DATA_FOLDER/processed-data

# The model used for evaluate
MODEL=$PWD/models/model/checkpoint_best.pt
NEW_BPE_MODEL=$NEW_DATA_FOLDER/bpe-model-${NUM}

BIN_DATA=$DATA_FOLDER/bin-data
BPE_MODEL=$DATA_FOLDER/bpe-model

UNIDATA=$DATA_FOLDER/unidirect-data
BPE_DATA=$UNIDATA/bpe-data

MERGE_FILE=$PWD/scripts/merge-file.py
MERGE_IBT=$PWD/scripts/merge-ibt.py


TRUECASED_DATA=$DATA_FOLDER/truecased

if [ -d $NEW_PROCESSED_DATA ]; then
	rm  -rf $NEW_PROCESSED_DATA
fi 

if [ -d $NEW_BIN_DATA ]; then
	rm  -rf $NEW_BIN_DATA
fi

mkdir -p $NEW_DATA_FOLDER
mkdir -p $NEW_DATA
mkdir -p $NEW_BPE_DATA
mkdir -p $NEW_BIN_DATA
mkdir -p $TRANSLATION_DATA
mkdir -p $NEW_DATA
mkdir -p $NEW_PROCESSED_DATA
mkdir -p $NEW_BPE_MODEL

# prepare data for the bidirectional model
DATA_NAME="valid test"

# copy processed-data to new processed data
for SET in $DATA_NAME ; do
	cat $PROCESSED_DATA/${SET}.src > $NEW_PROCESSED_DATA/${SET}.src
	cat $PROCESSED_DATA/${SET}.tgt > $NEW_PROCESSED_DATA/${SET}.tgt
done

cat ${TRANSLATION_DATA}/translation.vi | sed -r 's/(@@ )|(@@ ?$)|(<v2e> )//g'  > ${NEW_DATA}/train.vi.${NUM}
# cat  ${NEW_DATA}/new.en | awk -vtgt_tag="<e2v>" '{ print tgt_tag" "$0 }' >>  $NEW_PROCESSED_DATA/train.src
# cat $NEW_DATA/train.vi >> $NEW_PROCESSED_DATA/train.tgt

cat ${TRANSLATION_DATA}/translation.en | sed -r 's/(@@ )|(@@ ?$)|(<e2v> )//g'  > ${NEW_DATA}/train.en.${NUM}
# cat  ${NEW_DATA}/new.vi | awk -vtgt_tag="<v2e>" '{ print tgt_tag" "$0 }' >>  $NEW_PROCESSED_DATA/train.src
# cat $NEW_DATA/train.en >> $NEW_PROCESSED_DATA/train.tgt

##train: real, new:synthetic

#model_02
if [ $NUM -lt 9 ] ; then
	echo "back translation"
	python3.6 $MERGE_FILE -s1 ${NEW_DATA}/new.en.${NUM} -s2 ${TRUECASED_DATA}/train.en \
						  -s3 ${NEW_DATA}/new.vi.${NUM} -s4 ${TRUECASED_DATA}/train.vi -msrc ${NEW_PROCESSED_DATA}/train.src \
						  -t1 ${NEW_DATA}/train.vi.${NUM} -t2 ${TRUECASED_DATA}/train.vi \
						  -t3 ${NEW_DATA}/train.en.${NUM} -t4 ${TRUECASED_DATA}/train.en -mtgt ${NEW_PROCESSED_DATA}/train.tgt -t "sentence"
fi

if [ $NUM -ge 9 ] ; then
	echo "iterative back translation"
	# NUM = 9
	# python3.6 $MERGE_IBT -s1 ${NEW_DATA}/new.en.0 -s2 ${TRUECASED_DATA}/train.en \
	# 					  -s3 ${NEW_DATA}/ibt.new.en.${NUM} -s4 ${NEW_DATA}/new.vi.0 \
	# 					  -s5 ${TRUECASED_DATA}/train.vi -s6 ${NEW_DATA}/ibt.new.vi.${NUM} -msrc ${NEW_PROCESSED_DATA}/train.src \
	# 					  -t1 ${NEW_DATA}/train.vi.0 -t2 ${TRUECASED_DATA}/train.vi \
	# 					  -t3 ${NEW_DATA}/new.vi.0 -t4 ${NEW_DATA}/train.en.0 \
	# 					  -t5 ${TRUECASED_DATA}/train.en -t6 ${NEW_DATA}/new.en.0 -mtgt ${NEW_PROCESSED_DATA}/train.tgt -t "sentence"

	# NUM = 10
	echo "NUM: ${NUM}"
	python3.6 $MERGE_IBT -s1 ${NEW_DATA}/new.en.0 -s2 ${TRUECASED_DATA}/train.en \
						  -s3 ${NEW_DATA}/ibt.new.en.${NUM} -s4 ${NEW_DATA}/new.vi.0 \
						  -s5 ${TRUECASED_DATA}/train.vi -s6 ${NEW_DATA}/ibt.new.vi.${NUM} -msrc ${NEW_PROCESSED_DATA}/train.src \
						  -t1 ${NEW_DATA}/train.vi.0 -t2 ${TRUECASED_DATA}/train.vi \
						  -t3 ${NEW_DATA}/train.vi.${NUM} -t4 ${NEW_DATA}/train.en.0 \
						  -t5 ${TRUECASED_DATA}/train.en -t6 ${NEW_DATA}/train.en.${NUM} -mtgt ${NEW_PROCESSED_DATA}/train.tgt -t "sentence"

fi

DATA_NAME="train valid test"

# apply sub-word segmentation
if [ $CHOOSE_BPE -eq 0 ]; then

	echo "=> LEARNING BPE MODEL: $BPE_MODEL"
	subword-nmt learn-joint-bpe-and-vocab --input ${NEW_PROCESSED_DATA}/train.src ${NEW_PROCESSED_DATA}/train.tgt \
					-s $BPESIZE -o ${NEW_BPE_MODEL}/code.${BPESIZE}.bpe \
					--write-vocabulary ${NEW_BPE_MODEL}/train.src.vocab ${NEW_BPE_MODEL}/train.tgt.vocab 

	for SET in $DATA_NAME; do
	    subword-nmt apply-bpe -c ${NEW_BPE_MODEL}/code.${BPESIZE}.bpe < ${NEW_PROCESSED_DATA}/${SET}.src > ${NEW_BPE_DATA}/${SET}.src 
	    subword-nmt apply-bpe -c ${NEW_BPE_MODEL}/code.${BPESIZE}.bpe < ${NEW_PROCESSED_DATA}/${SET}.tgt > ${NEW_BPE_DATA}/${SET}.tgt
	done
fi

if [ $CHOOSE_BPE -eq 1 ]; then
	for SET in $DATA_NAME; do
	    subword-nmt apply-bpe -c ${BPE_MODEL}/code.${BPESIZE}.bpe < ${NEW_PROCESSED_DATA}/${SET}.src > ${NEW_BPE_DATA}/${SET}.src 
	    subword-nmt apply-bpe -c ${BPE_MODEL}/code.${BPESIZE}.bpe < ${NEW_PROCESSED_DATA}/${SET}.tgt > ${NEW_BPE_DATA}/${SET}.tgt
	done
fi

if [ $NUM -lt 9 ]; then

    echo "BT: add tags"
	python3.6 $PWD/scripts/addTag.py -f ${NEW_BPE_DATA}/train.src -p1 2 -t1 "<e2v>" -p2 4 -t2 "<v2e>" 

	python3.6 $PWD/scripts/addTag.py -f ${NEW_BPE_DATA}/valid.src -p1 1 -t1 "<e2v>" -p2 2 -t2 "<v2e>" 

	python3.6 $PWD/scripts/addTag.py -f ${NEW_BPE_DATA}/test.src -p1 1 -t1 "<e2v>" -p2 2 -t2 "<v2e>" 

fi

if [ $NUM -ge 9 ]; then
	echo "IBT: add tags"
	python3.6 $PWD/scripts/addTag.py -f ${NEW_BPE_DATA}/train.src -p1 3 -t1 "<e2v>" -p2 6 -t2 "<v2e>" 

	python3.6 $PWD/scripts/addTag.py -f ${NEW_BPE_DATA}/valid.src -p1 1 -t1 "<e2v>" -p2 2 -t2 "<v2e>" 

	python3.6 $PWD/scripts/addTag.py -f ${NEW_BPE_DATA}/test.src -p1 1 -t1 "<e2v>" -p2 2 -t2 "<v2e>" 

fi

# binarize train/valid/test

fairseq-preprocess -s src -t tgt \
			--destdir ${NEW_BIN_DATA} \
			--trainpref ${NEW_BPE_DATA}/train \
			--validpref ${NEW_BPE_DATA}/valid \
			--testpref ${NEW_BPE_DATA}/test \
			--tgtdict ${BIN_DATA}/dict.tgt.txt \
			--srcdict ${BIN_DATA}/dict.src.txt \
			--workers 32 


