
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
echo ${ids[@]}

for i in ${ids[@]}
do
  url="https://itunes.apple.com/lookup?id=$i"
  open $url
done
# open "https://itunes.apple.com/lookup?id=000000000"
