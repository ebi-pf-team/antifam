AntiFam
=======

AntiFam is a resource of profile-HMMs designed to identify spurious
protein predictions. AntiFam profile-HMMs come from two sources:

 i) A number of spurious Pfam families have been built in the past. These
    were based on erronous gene predictions.  These protein families
    have been deleted from Pfam, but new proteins may be predicted.

 ii) Profile-HMMs have been created from translations of commonly occuring
     non-coding RNAs such as tRNAs. 

This collection of profile-HMM models is designed to be used as a
quality control step for the UniProt sequence database as well as
metagenomic projects.


Release   # Entries
   1.0        8
   1.1       23    
   2.0       49
   3.0       54
   4.0       67

AntiFam is freely available under the Creative commons Zero (CC0) licence.
http://creativecommons.org/publicdomain/zero/1.0/


How to use AntiFam
==================

AntiFam is composed of a collection of alignments found in the file AntiFam.seed.
Using the HMMER3 software a library of profile-HMMs was built. This library is
found in the file AntiFam.hmm.

To use the hmm library you must first make index files with the following command

  hmmpress AntiFam.hmm

To search AntiFam against a set of sequences you run the following command

  hmmsearch --cut_ga AntiFam.hmm yourseq.fasta

Any reported matches are very likely to be spurious gene predictions.

Superkingdom-specific sets
==========================

AntiFam includes superkindom-specific sets of HMMs:
AntiFam_Eukaryota.hmm
AntiFam_Bacteria.hmm
AntiFam_Archaea.hmm
AntiFam_Virus.hmm
AntiFam_Unidentified.hmm

These contain HMMs that we have found to identify spurious proteins in each of
the superkingdoms, unidentified includes unclassified organisms. One HMM may
identify spurious proteins from multiple superkingdoms, and therefore may be 
present in more than one of these superkingdom-specific sets.

How to cite AntiFam
===================

Please cite the following paper:

Ruth Y Eberhardt, Dan Haft, Marco Punta, Maria Martin, Claire O’Donovan, 
Alex Bateman. (2012) AntiFam: A tool to help identify spurious ORFs in protein
annotation. Database:bas003. PMID:22434837.
