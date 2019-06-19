# HORRIBLY written script to make a fasta of all antifam sequences. 

import numpy as np
import re,pdb


outfile = open('anti.fa', 'w')
for i in np.arange(1,69,1):
    file_ = 'ANF000'+str(i).zfill(2)+'.seed'
    if not i == 30:
        with open(file_) as f:
            for line in f:
                if re.findall(r'(?<=#=GF\ )(ID)(?=[^\n])',line):
                    ID =  re.findall(r'Spurious_ORF_\d+',line)
                if not (line[0] == '#') and not (line[0] == '/'):
                    name = re.findall(r'(\S+)\s+(\S+)',line)
                    outfile.write('>{}\n{}\n'.format(ID[0]+'|'+name[0][0], name[0][1].translate(None,'.')))            
        
