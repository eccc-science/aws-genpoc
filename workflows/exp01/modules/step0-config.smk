#configuration file to run the workflow
configfile: "config.yaml"

STAGE_OUTPUTS = []

# NOTE: caching as specified in the MANIFEST does not work with snakemake wrappers.  If you use them it installs the environment each time.
# Snakemake file for running FastQC on all files in the mydata folder using s3.remote()
from snakemake.remote.S3 import RemoteProvider as S3RemoteProvider
# use s3=S3RemoteProvider(keep_local=True) to have the download files stay when running locally.  Note delete local files or move them outside the workflow before running agc workflow run or else they will get zipped and copied back up.
s3=S3RemoteProvider(keep_local=True)

# Define the S3 bucket and folder where the data is stored
S3_BUCKET = config["S3"]["BUCKET"]
#DATA_FOLDER = "Genomics-Jordyn/2022" 
DATA_FOLDER = config["S3"]["DATA_FOLDER"]

# Comment out this line to use a single file set.  Note this is faster when running a test.
#CONDITIONS = ["OS00E70F"] 
CONDITIONS = config["S3"]["CONDITIONS"]

# Comment out this line to use the glob_wildcards function that will read and process all files in the directory
#CONDITIONS = s3.glob_wildcards("genpocdata-992085379228-ca-central-1/aws-genomics-cli/{condition}_R1.fastq.gz").condition

# Assumes all paired files are in the format <filename>_R1 and <filename>_R2
REPLICATES = config["S3"]["REPLICATES"]

# Folders to store the output data in
FASTQC_REPORTS = config["OUTPUT_FOLDERS"]["FASTQC_REPORTS"]
FASTQC_TRIMMED_REPORTS = config["OUTPUT_FOLDERS"]["FASTQC_TRIMMED_REPORTS"]
TRIM_FOLDER = config["OUTPUT_FOLDERS"]["TRIM_FOLDER"]
TRIM_MERGE_FOLDER = config["OUTPUT_FOLDERS"]["TRIM_MERGE_FOLDER"]     
MUTIQC_FOLDER = config["OUTPUT_FOLDERS"]["MUTIQC_FOLDER"]
DIAMOND_FOLDER = config["OUTPUT_FOLDERS"]["DIAMOND_FOLDER"]

ADATPERS_FOLDER = config["DATABASES"]["FOLDER"]
ADAPTER_FILE = config["TRIM"]["ADAPTER_FILE"]


# Define the input fasta file to use for diamond
INPUT_FASTA_ZIP = config["DATABASES"]["FASTA"]["ZIP"]
INPUT_FASTA= config["DATABASES"]["FASTA"]["FILE"]
INPUT_FASTA_URL = config["DATABASES"]["FASTA"]["URL"]
INPUT_FASTA_ZIP_EXT= config["DATABASES"]["FASTA"]["ZIP_EXT"]
INPUT_FASTA_EXT= config["DATABASES"]["FASTA"]["FILE_EXT"]
INPUT_FASTA_FOLDER= config["DATABASES"]["FASTA"]["FOLDER"]

FASTQC_THREADS = config["FASTQC"]["THREADS"]
FASTQC_MEM_MB = config["FASTQC"]["MEM_MB"]

TRIM_THREADS = config["TRIM"]["THREADS"]
TRIM_MEM_MB = config["TRIM"]["MEM_MB"]
TRIM_SLIDINGWINDOW = config["TRIM"]["SLIDINGWINDOW"]
TRIM_MINLEN = config["TRIM"]["MINLEN"]
TRIM_ADAPTER_SETTINGS = config["TRIM"]["ADAPTER_SETTINGS"]

DIAMOND_THREADS = config["DIAMOND"]["THREADS"]
DIAMOND_MEM_MB = config["DIAMOND"]["MEM_MB"] 
DIAMOND_OUTPUT_FMT = config['DIAMOND']['OUTPUT_FORMAT']
DIAMOND_EVALUE=config['DIAMOND']['EVALUE']
DIAMOND_K = config['DIAMOND']['MAX_TARGET_SEQS']
DIAMOND_ARGS = config['DIAMOND']['ARGS']
DIAMOND_ID = config['DIAMOND']['ID']

KRAKEN_FILE = config["KRAKEN"]["FILE"]
KRAKEN_FILE_ZIP_EXT = config["KRAKEN"]["FILE_ZIP_EXT"]
KRAKEN_URL = config["KRAKEN"]["URL"]