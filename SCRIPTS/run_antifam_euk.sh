#!/bin/bash
hmmsearch --noali -E 0.01 --domE 0.01 AntiFam_Eukaryota.hmm /nfs/production/xfam/pfam/data/pfamseq28/pfamseq > AntiFam_Eukaryota.output
