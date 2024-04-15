####################################
# BLAST Databases #
####################################
Last Updated:  7-1-2020
Description: A centralized repository of pre-formatted BLAST databases created by the National Center for Biotechnology Information (NCBI). 

The pre-formatted databases offer the following advantages:
    * Pre-formatting removes the need to run makeblastdb;
    * Species-level taxonomy ids are included for each database entry;
    * Databases are broken into smaller-sized volumes and are therefore easier 
      to download;
    * A convenient script (update_blastdb.pl) is available in the BLAST+Docker package 
      to download the pre-formatted databases.

Databases are updated periodically to add the latest information available. A time stamp is available to see when the database was last updated.  To see a listing of databases available, use the command:

## Show BLAST databases available for download
docker run --rm ncbi/blast update_blastdb.pl --showall pretty

