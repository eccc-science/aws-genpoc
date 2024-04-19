
rule download_kraken:
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