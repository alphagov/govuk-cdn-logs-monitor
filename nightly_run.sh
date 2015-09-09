# accept an output directory to store the processed logs
outdirectory=$1

# find the newest file
infile=$(ls | sort -n -t _ -k 2 | tail -1)

# expect name to be formatted: cdn-govuk.log-YYYYMMDD.gz
# extract YYYYMMDD part of newest file
outfile=$(echo "$infile" | awk -F_ '{print $2}' | awk -F. '{print $1}')

echo "This process is creating $outdirectory/$outfile.csv"
cat $infile | ruby process_200s_from_cdn_log.rb "$outdirectory/$outfile.csv"
