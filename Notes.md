#### Test Data

**transcript reference file**  
gencode.v28.transcripts.fa.gz ~65MB  
Downloaded from GENCODE release 28 (GRCh38.p12)  
```bash
wget "ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_28/gencode.v28.annotation.gtf.gz"
```
* Note: refused connection error being encountered, currently unresolved  

**Paired read files**  
* fastq read files were taken from the lab directory /homes/wheelerlab2/Data/gEUVADIS_RNASeq  

## Kallisto

**references**  
https://pachterlab.github.io/kallisto/  
**Kallisto installation**  
requires conda installed and the bioconda channel be opened

```bash
conda config --add channels conda-forge
conda config --add channels bioconda

conda install kallisto
```
* Note: permission denied error encountered, resolved by running these commands with **sudo**  
* Note: conda is not currently in the PATH. Typing out the full path to conda resolves this, but is not optimal.

**running Kallisto**  
* Initial testing was run on the using the transcript fastq file taken from the GENCODE project, see **Test Data** for download instructions
* Paired reads ERR188030_1.fastq.gz (1151 MB) and ERR188030_2.fastq.gz (1136 MB) were used to test this data

1. Creating an index file  
```bash
kallisto index -i name_of_index_file.idx gencode.v28.transcripts.fa.gz
```
* Runtime of this step on GENCODE data 3m38s
* Name of index file should be established here and used from this point on for .idx arguments
* Note: Kallisto and transcript file are not currently in the PATH. Typing out the full PATH to these items resolves this, but is not optimal.

2. Quantifying transcript abundances
 ```bash
 kallisto quant -i name_of_index_file.idx -o output_directory -b 100 ERR188030_1.fastq.gz ERR188030_2.fastq.gz
 ```
* Runtime with bootstrap = 100 (-b 100) 42m47s
* Runtime without bootstrap (-b 0 is the default) 2m37s
* Manual notes it is possible to increase the runtime by up to 15% but this has not been explored
* Note: read files may not be in a different directory than the wd. Typing out the full PATH to these items resolves this, but is not optimal.
* Note: Uncertain if kallisto has the ability to name the output files for this step may interfere with downstream processing - may be adequate to name a unique directory for each output but not optimal


## STAR