#!/bin/bash

HYP=$1
REF=$2

EXPDIR=$PWD
MOSES=$EXPDIR/mosesdecoder/scripts
MULTIBLUE=$MOSES/generic/multi-bleu.perl

$MULTIBLUE ${REF} < ${HYP} | cut -f 3 -d ' ' | cut -f 1 -d ','