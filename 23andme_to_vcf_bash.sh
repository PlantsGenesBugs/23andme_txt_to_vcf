#!/usr/bin/env bash

convert_23andme_to_vcf() {
    INPUT="gt_23andme.txt"
    FASTA="Homo_sapiens.GRCh37.dna.primary_assembly.fa"
    OUT="vcf_out.vcf"
    
    # set arguments for function
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --input) INPUT="$2"; shift 2 ;;
            --fasta) FASTA="$2"; shift 2 ;;
            --out) OUT="$2"; shift 2 ;;
            *) echo "Unknown arg: $1" >&2; exit 1 ;;
        esac
    done    

    set -euo pipefail

# check if output file has extension
if [[ "$OUT" != *.vcf ]]; then
    OUT="${OUT}.vcf"
fi


# write VCF header
cat <<END > "$OUT"
##fileformat=VCFv4.2
##source=$INPUT
##reference=$FASTA
##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	SAMPLE
END

# read input file
while IFS=$'\t' read -r rsid chromosome position genotype
do
    # skip comments
    [[ $rsid == \#* ]] && continue

    # skip no-calls
    [[ $genotype == "--" ]] && continue

    # obtain reference allele
    ref=$(samtools faidx "$FASTA" "${chromosome}:${position}-${position}" | awk 'NR==2')

    # determine ALT and GT
    # pull genotype one and two from genotype column; start at index 0 and take 1 char for g1, start idx 1 and take 1char for g2
    g1="${genotype:0:1}"
    g2="${genotype:1:1}"

    # default setting for GT is "."
    ALT=""
    GT="."
    
    # fill GT column in reference to REF; if gt homozygous REF, then 0/0, else create ALT column based on non-ref genotype
    if [[ "$g1" == "$ref" && "$g2" == "$ref" ]]; then
            ALT="."
            GT="0/0"
        else
            for allele in "$g1" "$g2"; do
                if [[ "$allele" != "$ref" ]]; then
                    if [[ -z "$ALT" ]]; then
                        ALT="$allele"
                    elif [[ "$ALT" != *"$allele"* ]]; then
                        ALT="$ALT,$allele"
                    fi
                fi
            done

            if [[ "$g1" == "$ref" || "$g2" == "$ref" ]]; then
                GT="0/1"

            elif [[ "$g1" != "$g2" ]]; then
                GT="1/2"

            else
                GT="1/1"
            fi
        fi

        printf "%s\t%s\t%s\t%s\t%s\t.\tPASS\t.\tGT\t%s\n" \
            "$chromosome" "$position" "$rsid" "$ref" "$ALT" "$GT" >> "$OUT"

    done < "$INPUT"
}

# make function call-able when running script; expand the arguments included in script execution command, and pass to function
convert_23andme_to_vcf "$@"