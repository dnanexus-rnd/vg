#!/usr/bin/env bash

BASH_TAP_ROOT=../bash-tap
. ../bash-tap/bash-tap-bootstrap

PATH=..:$PATH # for vg


plan tests 8

vg construct -r small/x.fa >j.vg
vg construct -r small/x.fa -v small/x.vcf.gz >x.vg
vg index -s -k 11 x.vg

is $(vg map -r <(vg sim -s 1337 -n 100 j.vg) x.vg | vg surject -p x -d x.vg.index -t 1 - | vg view -a - | jq .score | grep 200 | wc -l) \
    100 "vg surject works perfectly for perfect reads derived from the reference"

is $(vg map -r <(vg sim -s 1337 -n 100 x.vg) x.vg | vg surject -p x -d x.vg.index -t 1 - | vg view -a - | wc -l) \
    100 "vg surject works for every read simulated from a dense graph"

is $(vg map -r <(vg sim -s 1337 -n 100 x.vg) x.vg | vg surject -p x -d x.vg.index -s - | grep -v ^@ | wc -l) \
    100 "vg surject produces valid SAM output"

is $(vg map -r <(vg sim -s 1337 -n 100 x.vg) x.vg | vg surject -p x -d x.vg.index -b - | samtools view - | wc -l) \
    100 "vg surject produces valid BAM output"

#is $(vg map -r <(vg sim -s 1337 -n 100 x.vg) x.vg | vg surject -p x -d x.vg.index -c - | samtools view - | wc -l) \
#    100 "vg surject produces valid CRAM output"

rm -rf j.vg x.vg x.vg.index

vg index -s -k 27 -e 7 graphs/fail.vg

read=TTCCTGTGTTTATTAGCCATGCCTAGAGTGGGATGCGCCATTGGTCATCTTCTGGCCCCTGTTGTCGGCATGTAACTTAATACCACAACCAGGCATAGGTGAAAGATTGGAGGAAAGATGAGTGACAGCATCAACTTCTCTCACAACCTAG
is $(vg map -s $read graphs/fail.vg | vg surject -i graphs/GRCh37.path_names -d graphs/fail.vg.index -s - | grep $read | wc -l) 1 "surjection works for a longer (151bp) read"

rm -rf graphs/fail.vg.index

vg index -s -k 27 -e 7 graphs/fail2.vg

read=TATTTACGGCGGGGGCCCACCTTTGACCCTTTTTTTTTTTCAAGCAGAAGACGGCATACGAGATCACTTCGAGAGATCGGTCTCGGCATTCCTGCTGAACCGCTCTTCCGATCTACCCTAACCCTAACCCCAACCCCTAACCCTAACCCCA
is $(vg map -s $read graphs/fail2.vg | vg surject -i graphs/GRCh37.path_names -d graphs/fail2.vg.index -s - | grep $read | wc -l) 1 "surjection works for another difficult read"

rm -rf graphs/fail2.vg.index

vg construct -r minigiab/q.fa -v minigiab/NA12878.chr22.tiny.giab.vcf.gz >minigiab.vg
vg index -s -k 11 minigiab.vg
is $(vg map -b minigiab/NA12878.chr22.tiny.bam minigiab.vg | vg surject -d minigiab.vg.index -s - | grep chr22.bin8.cram:166:6027 | grep BBBBBFBFI | wc -l) 1 "mapping reproduces qualities from BAM input"
is $(vg map -f minigiab/NA12878.chr22.tiny.fq.gz minigiab.vg | vg surject -d minigiab.vg.index -s - | grep chr22.bin8.cram:166:6027 | grep BBBBBFBFI | wc -l) 1 "mapping reproduces qualities from fastq input"
rm -rf minigiab.vg*
