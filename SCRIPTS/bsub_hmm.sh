#!/bin/bash
hmmsearch --noali -E 0.01 --domE 0.01 AntiFam.hmm /nfs/production/xfam/pfam/data/pfamseq28/pfamseq > Antifam.output
hmmsearch --noali -E 0.01 --domE 0.01 AntiFam_Archaea.hmm /nfs/production/xfam/pfam/data/pfamseq28/pfamseq > Antifam_Archaea.output
hmmsearch --noali -E 0.01 --domE 0.01 AntiFam_Bacteria.hmm /nfs/production/xfam/pfam/data/pfamseq28/pfamseq > Antifam_Bacteria.output
hmmsearch --noali -E 0.01 --domE 0.01 AntiFam_Eukaryota.hmm /nfs/production/xfam/pfam/data/pfamseq28/pfamseq > Antifam_Eukaryota.output
hmmsearch --noali -E 0.01 --domE 0.01 AntiFam_Virus.hmm /nfs/production/xfam/pfam/data/pfamseq28/pfamseq > Antifam_Virus.output
hmmsearch --noali -E 0.01 --domE 0.01 AntiFam_Unidentified.hmm /nfs/production/xfam/pfam/data/pfamseq28/pfamseq > Antifam_Unidentified.output
