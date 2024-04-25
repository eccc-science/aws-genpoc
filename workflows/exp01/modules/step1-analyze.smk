
# rule step1_all:
#     output:
#         ### FASTQC ###
#         expand("{fastqc_reports}/{sample}_{rep}_fastqc.html", sample=CONDITIONS, rep=REPLICATES, fastqc_reports=FASTQC_REPORTS),
#         expand("{fastqc_reports}/{sample}_{rep}_fastqc.zip", sample=CONDITIONS, rep=REPLICATES, fastqc_reports=FASTQC_REPORTS),

#         ### MULTIQC ###
#         expand("{multiqc_folder}/multiqc_report.html", multiqc_folder=MUTIQC_FOLDER),



# Run FastQC on the data
rule step1_run_fastqc:
    input:
        fastq = s3.remote(expand("{s3bucket}/{folder}/{sample}_{rep}.fastq.gz", sample=CONDITIONS, rep=REPLICATES, s3bucket=S3_BUCKET, folder=DATA_FOLDER), keep_local=True)
    output:
        report_html = expand("{fastqc_reports}/{sample}_{rep}_fastqc.html",sample=CONDITIONS, rep=REPLICATES,fastqc_reports=FASTQC_REPORTS),
        report_zip = expand("{fastqc_reports}/{sample}_{rep}_fastqc.zip",sample=CONDITIONS, rep=REPLICATES,fastqc_reports=FASTQC_REPORTS)
    conda:
        "../envs/environment.yaml"
    threads: FASTQC_THREADS
    resources:
        mem_mb=FASTQC_MEM_MB
    shell:
        "fastqc {input} --outdir {FASTQC_REPORTS}/ --threads {FASTQC_THREADS}"

# Consolidates all QC files into single report pre-trimming
rule step1_multiqc:
    input:
        # Although we are not using these files in the shell command, they are needed to trigger the rule after the fastqc reports are created
        R1 = expand("{fastqc_reports}/{sample}_{rep}_fastqc.html",sample=CONDITIONS, rep=REPLICATES,fastqc_reports=FASTQC_REPORTS),
    output:
         touch("outputs/step1_complete"),
         R1_report = expand("{multiqc_folder}/multiqc_report.html", multiqc_folder=MUTIQC_FOLDER),
    conda: 
        "../envs/environment.yaml"
    shell:
        "multiqc -n multiqc_report.html -o {MUTIQC_FOLDER} {FASTQC_REPORTS} --force"