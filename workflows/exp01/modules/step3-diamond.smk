# rule step3_all:
#     input:
#         ### DIAMOND ###
#         "outputs/download_ref.txt",  #Placeholder to exectue download rule for the FASTA database
#         expand("{diamond_folder}/{sample}.dmd", sample=CONDITIONS, diamond_folder=DIAMOND_FOLDER),

#         ### KRAKEN ###
#         #"outputs/download_kraken.txt", #Placeholder to exectue download rule for the KRAKEN database


# Download the diamond reference and store it outside the workflow.  Note it is not an output because we don't want it uploaded back to s3 under the job output files.
# By downloading it outside the workflow it will only be done one time and will not have to download 300GB each time however you will be charged storage for it on the EFS for the life of the context.
# wget -c will resume the file if it fails
rule step3_1_download_reference_makedb:
    output:
        "outputs/download_ref.txt"
    conda:
        "../envs/environment.yml"
    shell:
       """
        # Make the directories if required
        mkdir -p ../database/FASTA
        mkdir -p outputs
        if [ ! -f "../database/FASTA/{INPUT_FASTA}.dmnd" ]; then         
            file="../database/FASTA/{INPUT_FASTA_ZIP}.{INPUT_FASTA_ZIP_EXT}"
            if [ -f "$file" ]; then
                echo "Local zip file does exist."
                local_size=$(stat -c %s "$file")
                remote_size=$(curl -sI {INPUT_FASTA_URL} | grep -i Content-Length | awk '{{print $2}}')
                if [ "$local_size" -eq "$remote_size" ]; then
                    echo "Local file size matches remote file size"
                else
                    echo "Local file size does not match remote file size.  Continue download."
                    wget -c {INPUT_FASTA_URL} -P "../database/FASTA"
                    echo "download complete" 
                fi
                #replace with gunzip for gz
                unzip -o ../database/FASTA/{INPUT_FASTA_ZIP}.{INPUT_FASTA_ZIP_EXT} -d ../database/FASTA/
                echo "unzip complete"
            else
                echo "Local zip file does not exist."
                # check if unziped file exists and if not download it 
                if [ ! -f "../database/FASTA/{INPUT_FASTA}" ]; then
                    wget -c {INPUT_FASTA_URL} -P "../database/FASTA"
                    unzip -o ../database/FASTA/{INPUT_FASTA_ZIP}.{INPUT_FASTA_ZIP_EXT} -d ../database/FASTA/  
                    echo "download and unzip complete"
                fi
            fi      

            # make the db if it does not exist
            if [ ! -f "../database/FASTA/{INPUT_FASTA}.dmnd" ]; then
                diamond makedb --in ../database/FASTA/{INPUT_FASTA_FOLDER}/{INPUT_FASTA}.{INPUT_FASTA_EXT} --db ../database/FASTA/{INPUT_FASTA}.dmnd
                rm -r {INPUT_FASTA_FOLDER}
                rm -r *.{INPUT_FASTA_ZIP_EXT}
                echo "makedb complete" 
            fi
        fi
        echo "download_reference_makedb complete" > outputs/download_ref.txt
        """



# Run diamond blastx on the trimmed files.  Note the database is downloaded outside the workflow to save time and storage costs.
# Adjust settings as required.  This is a basic example.
rule step3_2_diamond_blastx:
    input:
       merged_paired = expand("{trimmed_merged_folder}/{sample}_merged.fq",trimmed_merged_folder=TRIM_MERGE_FOLDER, sample=CONDITIONS),
       db="outputs/download_ref.txt"
    output:
       expand("{diamond_folder}/{sample}.dmd", sample=CONDITIONS, diamond_folder=DIAMOND_FOLDER)
    threads: DIAMOND_THREADS
    resources:
        mem_mb=DIAMOND_MEM_MB
    conda:
        "../envs/environment.yml"
    shell:
        "diamond blastx --threads {DIAMOND_THREADS} --outfmt {DIAMOND_OUTPUT_FMT} -q {input.merged_paired} -d ../database/FASTA/{INPUT_FASTA}.dmnd -o {output} -e {DIAMOND_EVALUE} -k {DIAMOND_K} --id {DIAMOND_ID} {DIAMOND_ARGS}"