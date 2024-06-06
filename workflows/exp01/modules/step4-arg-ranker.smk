rule step4_1_download_kraken:
    output:
        "outputs/download_kraken.txt"
    conda:
        "../envs/environment.yaml"
    shell:
       """
        # Make the directories if required
        mkdir -p ../database
        mkdir -p ../database/KRAKEN
        mkdir -p outputs
        if [ ! -f "../database/KRAKEN/{KRAKEN_FILE}" ]; then         
           file="../database/KRAKEN/{KRAKEN_FILE}.{KRAKEN_FILE_ZIP_EXT}"
           if [ -f "$file" ]; then
                echo "Local kraken file does exist."
                local_size=$(stat -c %s "$file")
                remote_size=$(curl -sI {KRAKEN_URL} | grep -i Content-Length | awk '{{print $2}}')
                if [ "$local_size" -eq "$remote_size" ]; then
                   echo "Local file size matches remote file size"
                else
                   echo "Local file size does not match remote file size.  Continue download."
                   wget -c {KRAKEN_URL} -P "../database/KRAKEN"
                   echo "download complete" 
               fi
               #replace with gunzip for gz
               tar -xzf ../database/KRAKEN/{KRAKEN_FILE}.{KRAKEN_FILE_ZIP_EXT} -C ../database/KRAKEN/
               echo "unzip complete"
            else
                echo "Local zip file does not exist."
                # check if unziped file exists and if not download it 
                if [ ! -f "../database/KRAKEN/{KRAKEN_FILE}" ]; then
                    wget -c {KRAKEN_URL} -P "../database/KRAKEN"
                    tar -xzf ../database/KRAKEN/{KRAKEN_FILE}.{KRAKEN_FILE_ZIP_EXT} -C ../database/KRAKEN/  
                    echo "download and unzip complete"
                fi
            fi      
        fi
        echo "KRAKEN download complete" > outputs/download_kraken.txt
        """

# Run arg_ranker on the trimmed, merged files.  Note the database is downloaded outside the workflow to save time and storage costs.
# Adjust settings as required.  This is a basic example.
rule step4_2_arg_ranker:
    input:
       merged_paired = expand("{trimmed_merged_folder}/{sample}_merged.fq",trimmed_merged_folder=TRIM_MERGE_FOLDER, sample=CONDITIONS),
       db="/database/KRAKEN"
    output:
       expand("{sample}.txt")
    conda:
        "../envs/environment.yaml"
    shell:
        "arg_ranker -i {input.merged_paired} -kkdb outputs/KRAKEN
        "sh arg_ranking/script_output/arg_ranker.sh"
