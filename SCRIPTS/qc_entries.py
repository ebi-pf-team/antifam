# This script runs through all entries in the antifam/ENTRIES folder and checks sanity.
# Discovered problems are saved in diagnosis.log

import os,re,pdb

def init_logfile(logfile):
    logf = open(logfile, "w")
    logf.write("This is a list of potential flaws in /nfs/production/agb/antifam/ENTRIES/. Created with qc_entries.py.\n\n")
    logf.write("Seed File         Problem description\n--------------------------------------\n")
    return logf

def test_if_compulsory_entries_exit(path,filename, n_flaws):
    #compuls = ["ID", "AC","DE","DO", "AU", "SE", "CC", ]#, "SS", "BM", "SM", "GA", "TP", "SQ"]
    #prefix = '#=GF'

    with open(path+filename) as seedfile:
        f = seedfile.read()

    ### Check existence and correctness of desired entries ###

    #Filename
    if not re.findall(r'^ANF\d{5}\b.seed$',filename):
        logf.write("{0}    Invalid filename \n".format(filename)); n_flaws+=1
    #Stockholm
    if not re.findall(r'^#\ STOCKHOLM\ \d.+?',f):
        logf.write("{0}     \"STOCKHOLM\" identifier missing or flawed \n".format(filename)); n_flaws+=1
    #ID
    if not re.findall(r'(?<=\n#=GF\ )(ID)(?=\s+Spurious_ORF_\d)',f):
        logf.write("{0}     \"ID\" identifier missing or flawed (not called \"Spurious_ORF\"?)\n".format(filename)); n_flaws+=1
    #DO
    if not re.findall(r'(?<=\n#=GF\ )(DO)(?=\s+(?:Delete protein|Edit to correct frame))',f):
        logf.write("{0}     \"DO\" identifier missing or flawed (Value different from \"Delete Protein\" or \"Edit to correct frame\"?)\n".format(filename)); n_flaws+=1
    #AC
    if not re.findall(r'(?<=\n#=GF\ )(AC)(?=\s+ANF\d{5}\b)',f):
        logf.write("{0}     \"AC\" identifier missing or flawed (Value different from ANFxxxxx?)\n".format(filename)); n_flaws+=1
    #DE
    if not re.findall(r'(?<=\n#=GF\ )(DE)(?=[^\n])',f):
        logf.write("{0}     \"DE\" identifier missing or flawed \n".format(filename)); n_flaws+=1
    #AU
    if not re.findall(r'(?<=\n#=GF\ )(AU)(?=[^\n])',f):
        logf.write("{0}     \"AU\" identifier missing or flawed \n".format(filename)); n_flaws+=1
    #SE
    if not re.findall(r'(?<=\n#=GF\ )(SE)(?=[^\n])',f):
        logf.write("{0}     \"SE\" identifier missing or flawed \n".format(filename)); n_flaws+=1
    #CC
    if not re.findall(r'(?<=\n#=GF\ )(CC)(?=[^\n])',f):
        logf.write("{0}     \"CC\" identifier missing or flawed \n".format(filename)); n_flaws+=1
    #SQ
    if not re.findall(r'(?<=\n#=GF\ )(SQ)(?=\s+\d)',f):
        logf.write("{0}     \"SQ\" identifier missing or flawed (Value not a number?)\n".format(filename)); n_flaws+=1
    #BM
    if not re.findall(r'(?<=\n#=GF\ )(BM)(?=[^\n])',f):
        logf.write("{0}     \"BM\" identifier missing or flawed (Value not a number?)\n".format(filename)); n_flaws+=1
    #TP
    if not re.findall(r'(?<=\n#=GF\ )(TP)(?=\s+(?:Family|Domain|Motif|Repeat))',f):
        logf.write("{0}     \"TP\" identifier missing or flawed (Value not \"Family\" or \"Domain\"?)\n".format(filename)); n_flaws+=1
    #TX
    if not re.findall(r'(?<=\n#=GF\ )(TX)(?=\s+(?:Bacteria|Eukaryota|Bacteria|Archaea|Virus|unidentified))',f):
        logf.write("{0}     \"TX\" identifier missing or flawed (Unknown species?)\n".format(filename)); n_flaws+=1
    #//
    if not re.findall(r'\/\/\n',f):
        logf.write("{0}     \"//\" record seperator missing or lacking final newline \n".format(filename)); n_flaws+=1
    

    ### Check non-existence of undesired entries ###
    
    #AM
    if re.findall(r'(?<=\n#=GF\ )(AM)\s+',f):
        logf.write("{0}     Found entry \"AM\" (no longer used in AntiFam)\n".format(filename)); n_flaws+=1
    ##=GS
    if re.findall(r'(#=GS)\s+',f):
        logf.write("{0}     Found entry \"#=GS\" (no longer used in AntiFam)\n".format(filename)); n_flaws+=1
    #BM: no more than 1 line
    if len(re.findall(r'(?<=\n#=GF\ )(BM)\s+',f))>1:
        logf.write("{0}     Found more than one entry for \"BM\".\n".format(filename)); n_flaws+=1

    #To do: Check if file contains sequences
    return n_flaws

#Remove old diagnosis.log
if os.path.isfile('diagnosis.log'):
    print('Overwriting existing diagnosis.log')
    os.remove('diagnosis.log')

#Init logfile, specify path to seed folder
outfile = 'diagnosis.log'
logf = init_logfile(outfile)
path = '/nfs/production/agb/antifam/ENTRIES/'
global n_flaws
n_flaws = 0

#For every file in the folder: check sanity
for filename in sorted(os.listdir(path)):
    n_flaws = test_if_compulsory_entries_exit(path,filename, n_flaws)
# Write summary in logfile
#logf.write("\nSearched {} files; {} problems found".format(len(os.listdir(path),n_flaws)))


# Give a short summary in terminal
print('{} problem(s) found after searching a total of {} files.\nWriting logfile to {}'.format(n_flaws,len(os.listdir(path)),outfile))
