# accept a source and output directory to get and store the processed logs
srcdirectory=$1
outdirectory=$2

# find the newest file
infile=$(ls $srcdirectory | sort -n -t _ -k 2 | tail -1)

# expect name to be formatted: cdn-govuk.log-YYYYMMDD.gz
# extract YYYYMMDD part of newest file
outfile=$(echo "$infile" | awk -F_ '{print $2}' | awk -F. '{print $1}')

echo "This process is creating $outdirectory/$outfile.csv"
cat "$srcdirectory/$infile" | ruby process_200s_from_cdn_log.rb "$outdirectory/$outfile.csv"
