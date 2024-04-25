# Clean up the S3 bucket files after trimming.  
# This is because keep_local was used and it will leave them on the EFS otherwise.  Snakemake is supposed to only remove the remote files once all rules did not depend on it but that is not working right when using expand().
# rule step6_clean_up:
#     input:
#         expand("{multiqc_folder}/multiqc_report.html", multiqc_folder=MUTIQC_FOLDER),
#     output:
#         "outputs/step6_clean_up"
#     shell:
#         "rm -rf {S3_BUCKET}; touch {output}"

rule step6_workflow_complete:
    input:
        expand("{multiqc_folder}/multiqc_report.html", multiqc_folder=MUTIQC_FOLDER),
        #"outputs/step6_clean_up"
    output:
        touch("outputs/workflow_complete")