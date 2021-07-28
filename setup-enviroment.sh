#!/bin/bash

EXPDIR=$PWD

# mosesdecoder
if [ ! -d $EXPDIR/mosesdecoder]; then
    echo 'Cloning Moses github repository (for tokenization scripts)...'
    git clone https://github.com/moses-smt/mosesdecoder.git
fi

# fairseq
if [ ! -d $EXPDIR/fairseq ]; then 
    echo 'Cloning fairseq repository (for training models)...'
    git clone https://github.com/pytorch/fairseq
    pushd fairseq
    pip install --editable ./
    popd
fi


# subword-nmt 
# git clone https://github.com/rsennrich/subword-nmt.git
echo 'Cloning Subword NMT repository (for BPE pre-processing)...'
pip install subword-nmt