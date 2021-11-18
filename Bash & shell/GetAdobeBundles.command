ids=(
"331975235"   # Adobe Photoshop Express
"1457771281"  # Adobe Photoshop
"804177739"   # Adobe Lightroom
"1188753863"  # Adobe Premiere Rush
"1146597773"  # Adobe XD
"852555131"   # Adobe Spark Video
"1274204902"  # Adobe Photoshop Camera Filters
"1401748913"  # Adobe Aero
"331975235"   # Adobe Photoshop Express
"1199564834"  # Adobe Scan
"1458660369"  # Adobe Fresco
"885271158"   # Adobe Photoshop Mix
"911156590"   # Adobe Illustrator Draw
"1040200189"  # Adobe Capture
"1033713849"  # Adobe Photoshop Fix
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
