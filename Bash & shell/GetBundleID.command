ids=(
"1549488238"   ## Experience Nanup
)
# echo ${ids[@]}

for i in ${ids[@]}
do
  url="https://itunes.apple.com/lookup?id=$i"
  json=`curl -s $url`
  # bundleID=`grep "bundleId:"`
  # printf %s "$json" | grep "description" | awk -F "," '{print $0}'
  # echo $json | grep "bundleId" | awk -F "," '/bundle/{print $0}'
  bundle=`echo $json | tr ',' '\n' | grep "bundleId" | sed 's/["]//g' | awk -F : '{print $2}'`
  name=`echo $json | tr ',' '\n' | grep "trackName" | sed 's/["]//g' | awk -F : '{print $2}'`
  echo "$name => $bundle"
done
# open "https://itunes.apple.com/lookup?id=1033713849"
