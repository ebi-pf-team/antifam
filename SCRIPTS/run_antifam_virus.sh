#!/bin/bash
hmmsearch --noali -E 0.01 --domE 0.01 AntiFam_Virus.hmm /nfs/production/xfam/pfam/data/pfamseq28/pfamseq > AntiFam_Virus.output
