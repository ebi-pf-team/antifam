#!/bin/bash
hmmsearch --noali -E 0.01 --domE 0.01 AntiFam_Archaea.hmm /nfs/production/xfam/pfam/data/pfamseq28/pfamseq > AntiFam_Archaea.output
