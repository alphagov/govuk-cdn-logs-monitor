# accept an output directory to store the processed logs
outdirectory=$1

for f in *.gz; do
    # expect name to be formatted: cdn-govuk.log-YYYYMMDD.gz
    # extract YYYYMMDD part of zipped file name
    outfile=$(echo $f | awk -F- '{print $3}' | awk -F. '{print $1}')

    echo "creating $outdirectory/$outfile.csv"
    gunzip $f -c | ruby process_200s_from_cdn_log.rb "$outdirectory/$outfile.csv"
done
