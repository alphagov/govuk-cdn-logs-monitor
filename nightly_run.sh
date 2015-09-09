outdirectory=$1
infile=$(ls | sort -n -t _ -k 2 | tail -1)
outfile=$(echo "$infile" | awk -F_ '{print $2}' | awk -F. '{print $1}')

echo "This process is creating $outdirectory/$outfile.csv"
cat $infile | ruby process_200s_from_cdn_log.rb "$outdirectory/$outfile.csv"
