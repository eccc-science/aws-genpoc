rule step6_all:
   input:
        ### CLEAN UP Download files ##
        "outputs/workflow_complete"

# Clean up the S3 bucket files after trimming.  
# This is because keep_local was used and it will leave them on the EFS otherwise.  Snakemake is supposed to only remove the remote files once all rules did not depend on it but that is not working right when using expand().
rule step6_clean_up:
    input:
       R1_report = expand("{multiqc_folder}/multiqc_report.html", multiqc_folder=MUTIQC_FOLDER)
    output:
        "outputs/workflow_complete"
    shell:
        "rm -rf {S3_BUCKET}; touch {output}"