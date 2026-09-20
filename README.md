# Manipulating 23andMe output files
On the 23rd of March 2025 23andMe filed for bankruptcy. On the 24th of March 2025 I decided to download as much of my own data as possible, and then withdrew my data from the company and deleted my account. When I initially sent my sample off in 2015, I was curious to know all the things I could based on my *personal genotype* and, crucially, I didn't have the tools to do the analysis myself. Fast forward 10 years, and I have the skill to sequence my own genome if I wanted to (I don't have the resources, sadly) and, more importantly, I have the ability to manipulate genomic data. With this tool I hope that more people will be able to convert their individual data to a more universally applicable bioinformatic file format.   

## Converting txt to vcf  
Many bioinformatics tools use .vcf files. This is simply data that is structured in a fixed way. The VCF file format documentation that I used for my bash script here is the spec for V 4.2 (modified 5 Nov 2025) on the [samtools github repository](https://github.com/samtools/hts-specs). 

The 23andMe output file is plain .txt which makes it human-readable, even for someone with no bioinformatics skills. This is raw data with information on SNP calls for the individual, taken from an array with 600k SNPs. 23andMe also generate imputed data based on your own SNPs - this is available as individual chromosome-based bcf files. As far as I understand it, the imputation relies on the concept of linkage disequilibrium in haplotypes, and is generated through some statistical analysis. For the raw data, the reference human genome build 37 (GRCh37) is used. For the imputed data, the reference human genome build 38 (GRCh38) is used. Here I am focusing on the raw data, since it is unique to the individual and empirically determined.    

## Repo contents  
1. `23andme_to_vcf_bash.sh` - a bash script containing a function that will convert the raw SNP data in a 23andme .txt file to a .vcf file for downstream applications. It has 3 associated flags:  
  - `--input`  : your individual .txt file  
  - `--fasta`  : the reference genome in .fa format   
  - `--out`    : the name you want to give your output file (it will automatically be assigned a .vcf extension)  

2. `Homo_sapiens.GRCh37.dna.primary_assembly.fa.fai` - index file relating to human genome build GRCh37 (hg19).  

**PLEASE NOTE:** you will need the index (.fai) file of the related .fa reference file available to run this code without an error. To generate the index file, run `samtools faidx <file.fa>` in the directory where your reference human genome is stored. Then proceed to the script. If you are using the GRCh37 (hg19) version of the human genome (available through the Ensembl link below), I have included an index file in this repository, which you can download for ease of use. If you are using a different build, follow the steps below.  

### Step-wise preparation of index file  
1. Navigate to the working directory, where you will save and run the bash script, through the terminal (command prompt). (This is just a suggestion and can be adjusted if all directory references are changed accordingly when running the script)
2. Ensure you have a copy of the human genome in FASTA format (e.g. Homo_sapiens.GRCh37.dna.primary_assembly.fa.gz) available in that folder. If not, you can get a reference FASTA for GRCh37 from [Ensembl](ftp://ftp.ensembl.org/pub/grch37/current/fasta/homo_sapiens/dna/Homo_sapiens.GRCh37.dna.primary_assembly.fa.gz). The genome should be uncompressed, so unpack it and ensure there is a .fa file available (the file `Homo_sapiens.GRCh37.dna.primary_assembly.fa` will be about 3.15 GB).
3. Install samtools if not already installed. This can be done most easily using package managers such as Conda or Homebrew (macOS). Conda: `conda install -c bioconda samtools`. Homebrew: `brew install samtools`.
4. Creat index file by running `samtools faidx <human_genome_filename.fa>`. This returns a small index file (3kb).   

## How the function determines reference and alternative alleles  
For each SNP in the raw 23andMe data, the associated reference allele is determined in the reference genome using the `faidx` function from samtools. The alternative allele is populated relative to the 23andMe SNP such that:  
- `if` SNP = REF `then` ALT = .   
- `if` SNP != REF  `then` ALT = SNP  

## How the function codes values for the genotype column  
The genotype (GT) is coded based on similarity between the SNP and the REF, such that:  
- `if` SNP = REF `then` GT = 0   
- `if` SNP != REF `then` GT = 1 for first dissimilarity and GT = 2 for second dissimilarity   

The raw SNP data is NOT phased, so that a heterozygous SNP sharing one allele with the REF allele can be either 0/1 or 1/0.
