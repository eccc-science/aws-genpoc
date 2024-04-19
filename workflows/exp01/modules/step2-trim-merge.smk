
rule step2_all:
   input:
       ### trimmomatic ###
        expand("{trimmed}/output_forward_paired_{sample}.fq.gz", trimmed=TRIM_FOLDER, sample=CONDITIONS),
        expand("{trimmed}/output_forward_unpaired_{sample}.fq.gz", trimmed=TRIM_FOLDER, sample=CONDITIONS),
        expand("{trimmed}/output_reverse_paired_{sample}.fq.gz", trimmed=TRIM_FOLDER, sample=CONDITIONS),
        expand("{trimmed}/output_reverse_unpaired_{sample}.fq.gz", trimmed=TRIM_FOLDER, sample=CONDITIONS),

        ### TRIMMED FASTQC ###
        expand("{fastqc_trimmed_reports}/output_forward_paired_{sample}_fastqc.html",sample=CONDITIONS, fastqc_trimmed_reports=FASTQC_TRIMMED_REPORTS),
        expand("{fastqc_trimmed_reports}/output_forward_paired_{sample}_fastqc.zip",sample=CONDITIONS, fastqc_trimmed_reports=FASTQC_TRIMMED_REPORTS),
        expand("{fastqc_trimmed_reports}/output_reverse_paired_{sample}_fastqc.html",sample=CONDITIONS, fastqc_trimmed_reports=FASTQC_TRIMMED_REPORTS),
        expand("{fastqc_trimmed_reports}/output_reverse_paired_{sample}_fastqc.zip",sample=CONDITIONS, fastqc_trimmed_reports=FASTQC_TRIMMED_REPORTS),
        expand("{fastqc_trimmed_reports}/output_forward_unpaired_{sample}_fastqc.html",sample=CONDITIONS, fastqc_trimmed_reports=FASTQC_TRIMMED_REPORTS),
        expand("{fastqc_trimmed_reports}/output_forward_unpaired_{sample}_fastqc.zip",sample=CONDITIONS, fastqc_trimmed_reports=FASTQC_TRIMMED_REPORTS),
        expand("{fastqc_trimmed_reports}/output_reverse_unpaired_{sample}_fastqc.html",sample=CONDITIONS, fastqc_trimmed_reports=FASTQC_TRIMMED_REPORTS),
        expand("{fastqc_trimmed_reports}/output_reverse_unpaired_{sample}_fastqc.zip",sample=CONDITIONS, fastqc_trimmed_reports=FASTQC_TRIMMED_REPORTS),
    
        ### MULTIQC ###
        #expand("{multiqc_folder}/multiqc_report.html", multiqc_folder=MUTIQC_FOLDER),
        expand("{multiqc_folder}/multiqc_report_trimmed.html", multiqc_folder=MUTIQC_FOLDER),

        ### Merge ###
        expand("{trimmed_merged_folder}/{sample}_merged.fq",trimmed_merged_folder=TRIM_MERGE_FOLDER, sample=CONDITIONS),
        expand("{trimmed_merged_folder}/{sample}_unmerged.fq",trimmed_merged_folder=TRIM_MERGE_FOLDER, sample=CONDITIONS),
        expand("{trimmed_merged_folder}/{sample}_ihist.txt",trimmed_merged_folder=TRIM_MERGE_FOLDER, sample=CONDITIONS),

# Running FastQC on reads before and after trimming should be done to validate trimming step
# When reading some claim fastp is 3x faster than trimmomatic.  Could be worth looking into. https://github.com/OpenGene/fastp
rule trimmomatic_pe:
    input:
        forward = s3.remote(expand("{s3bucket}/{folder}/{sample}_{rep}.fastq.gz", sample=CONDITIONS, rep="R1", s3bucket=S3_BUCKET, folder=DATA_FOLDER)),
        backward = s3.remote(expand("{s3bucket}/{folder}/{sample}_{rep}.fastq.gz", sample=CONDITIONS, rep="R2", s3bucket=S3_BUCKET, folder=DATA_FOLDER)),
        #adapter = expand("{adapter_folder}/{adapter_file}", adapter_folder=ADATPERS_FOLDER, adapter_file=ADAPTER_FILE)
        adapter = s3.remote(expand("{s3bucket}/{adapter_folder}/{adapter_file}", s3bucket=S3_BUCKET, adapter_folder=ADATPERS_FOLDER, adapter_file=ADAPTER_FILE))
    output:
        # forward reads
        forward_paired = "{trimmed}/output_forward_paired_{sample}.fq.gz",
        forward_unpaired = "{trimmed}/output_forward_unpaired_{sample}.fq.gz",
        # Backward reads
        backward_paired = "{trimmed}/output_reverse_paired_{sample}.fq.gz",
        backward_unpaired = "{trimmed}/output_reverse_unpaired_{sample}.fq.gz"
    conda:
        "../envs/environment.yaml"
    # log:
    #     "/logs/trimmomatic/{sample}.log"
    threads: TRIM_THREADS
    resources:
        mem_mb=TRIM_MEM_MB
    shell:
        "trimmomatic PE "
        "-threads {TRIM_THREADS} "
        "-phred33 "
        "{input.forward} {input.backward} "
        "{output.forward_paired} {output.forward_unpaired} {output.backward_paired} {output.backward_unpaired} "
        #"LEADING:3 "
        #"TRAILING:3 "
        "SLIDINGWINDOW:{TRIM_SLIDINGWINDOW} "
        "MINLEN:{TRIM_MINLEN} "
        #"HEADCROP:1 " # Have a look at the fastqc profiles to make sure you are cropping enough bases at the beginning of the reads.
        #"CROP:80"  # crop is optional. If for some reason you are still stuck with overrepresented kmers at the end, use crop=<in> to force them off.
        "ILLUMINACLIP:{input.adapter}:{TRIM_ADAPTER_SETTINGS}"  #https://github.com/usadellab/Trimmomatic/tree/main/adapters

# Merges paired end reads together to be used with Diamond
rule bbmerge:
    input:
       R1 = expand("{trimmed}/output_forward_paired_{sample}.fq.gz",trimmed=TRIM_FOLDER, sample=CONDITIONS),
       R2 = expand("{trimmed}/output_reverse_paired_{sample}.fq.gz",trimmed=TRIM_FOLDER, sample=CONDITIONS),
    output:
        out_merged = expand("{trimmed_merged_folder}/{sample}_merged.fq",trimmed_merged_folder=TRIM_MERGE_FOLDER, sample=CONDITIONS),
        out_unmerged = expand("{trimmed_merged_folder}/{sample}_unmerged.fq",trimmed_merged_folder=TRIM_MERGE_FOLDER, sample=CONDITIONS),
        ihist = expand("{trimmed_merged_folder}/{sample}_ihist.txt",trimmed_merged_folder=TRIM_MERGE_FOLDER, sample=CONDITIONS)
    conda: "../envs/environment.yaml"
    shell: "bbmerge.sh in1={input.R1} in2={input.R2} out={output.out_merged} outu={output.out_unmerged} ihist={output.ihist}"

# Run FastQC on the trimmed data
rule run_trimmed_fastqc:
    input:
        # forward reads
        forward_paired = expand("{trimmed}/output_forward_paired_{sample}.fq.gz",trimmed=TRIM_FOLDER, sample=CONDITIONS),
        forward_unpaired = expand("{trimmed}/output_forward_unpaired_{sample}.fq.gz",trimmed=TRIM_FOLDER, sample=CONDITIONS),
        # Backward reads
        backward_paired = expand("{trimmed}/output_reverse_paired_{sample}.fq.gz",trimmed=TRIM_FOLDER, sample=CONDITIONS),
        backward_unpaired = expand("{trimmed}/output_reverse_unpaired_{sample}.fq.gz",trimmed=TRIM_FOLDER, sample=CONDITIONS)
    output:
        html1=expand("{fastqc_trimmed_reports}/output_forward_paired_{sample}_fastqc.html",sample=CONDITIONS, rep=REPLICATES, fastqc_trimmed_reports=FASTQC_TRIMMED_REPORTS),
        zip1=expand("{fastqc_trimmed_reports}/output_forward_paired_{sample}_fastqc.zip",sample=CONDITIONS, rep=REPLICATES, fastqc_trimmed_reports=FASTQC_TRIMMED_REPORTS),
        html2=expand("{fastqc_trimmed_reports}/output_reverse_paired_{sample}_fastqc.html",sample=CONDITIONS, rep=REPLICATES, fastqc_trimmed_reports=FASTQC_TRIMMED_REPORTS),
        zip2=expand("{fastqc_trimmed_reports}/output_reverse_paired_{sample}_fastqc.zip",sample=CONDITIONS, rep=REPLICATES, fastqc_trimmed_reports=FASTQC_TRIMMED_REPORTS),
        html3=expand("{fastqc_trimmed_reports}/output_forward_unpaired_{sample}_fastqc.html",sample=CONDITIONS, rep=REPLICATES, fastqc_trimmed_reports=FASTQC_TRIMMED_REPORTS),
        zip3=expand("{fastqc_trimmed_reports}/output_forward_unpaired_{sample}_fastqc.zip",sample=CONDITIONS, rep=REPLICATES, fastqc_trimmed_reports=FASTQC_TRIMMED_REPORTS),
        html4=expand("{fastqc_trimmed_reports}/output_reverse_unpaired_{sample}_fastqc.html",sample=CONDITIONS, rep=REPLICATES, fastqc_trimmed_reports=FASTQC_TRIMMED_REPORTS),
        zip4=expand("{fastqc_trimmed_reports}/output_reverse_unpaired_{sample}_fastqc.zip",sample=CONDITIONS, rep=REPLICATES, fastqc_trimmed_reports=FASTQC_TRIMMED_REPORTS)
    threads: FASTQC_THREADS
    resources:
        mem_mb=FASTQC_MEM_MB
    conda:
        "../envs/environment.yaml"
    shell:
        "fastqc {input} --outdir {FASTQC_TRIMMED_REPORTS}/ --threads {FASTQC_THREADS}"


# Consolidates all QC files into single report post-trimming
rule multiqc_post_trim:
    input:
        R1_trimmed = expand("{fastqc_trimmed_reports}/output_forward_paired_{sample}_fastqc.html",sample=CONDITIONS, rep=REPLICATES, fastqc_trimmed_reports=FASTQC_TRIMMED_REPORTS),
    output:
        R2_trimmed_report = expand("{multiqc_folder}/multiqc_report_trimmed.html", multiqc_folder=MUTIQC_FOLDER)
    conda: "../envs/environment.yaml"
    shell:
        "multiqc -n multiqc_report_trimmed.html -o {MUTIQC_FOLDER} {FASTQC_TRIMMED_REPORTS} --force;"

