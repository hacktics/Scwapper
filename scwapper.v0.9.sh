#!/bin/sh
# Tomer Hadad, twitter: @psmith_sec

 if [ -z $1 ]; then
	echo "";
	echo "usage: scwapper [Binary Name]";
	echo "Please make sure you run Scwapper from the app binary's directory";
	exit 1;
 fi
 
#path to write output
dirpath=/private/var/mobile/Documents/scwapper
appname=$1
appname=${appname//\ /\\ }
#recursive function
#enumerate storyboard files in current dir
#and call function to all files
#store results in sbarraywext
enumsb (){
sbarraywext+=($1/*.storyboardc);
for file in $1/*; do
enumsb $file;
done;
}

#run the enumsb function in current dir
shopt -s nullglob
unset sbarraywext;
unset sbarray;
enumsb .

#parse the sbarray to not contain file extension
#sbarray=${sbarraywext[*]};
#for sbi in ${!sbarraywext[@]}; do
#sb=${sbarraywext[$sbi]};
#sbarray[$sbi]=${sb%.storyboardc};
#sbarray[$sbi]=${sbarray[$sbi]//\ /\\\ },;
#done;

#Test
#echo ${sbarraywext[*]}
#echo ${sbarray[*]}


#Prepare cycript script 
CYSH="
var sbfiles = \""${sbarraywext[*]}"\";
var sbarr = [ ];
var sbfilesarr = sbfiles.split(\".storyboardc \");
sbfilesarr [ sbfilesarr.length-1 ] = sbfilesarr [ sbfilesarr.length-1 ].replace (\".storyboardc\", \"\");
sbfilesarr.forEach(function(sbfile){
	sbarr.push([UIStoryboard storyboardWithName:sbfile bundle:nil]);
});
var outputarr = [ ];
sbarr.forEach(function(sb,i){
	outputarr.push (sb.identifierToNibNameMap.allKeys());
	outputarr[ i ].sbname = sb.name;
});
";
CYSH=$CYSH"var outputstring = \"\";
outputarr.forEach(function(sb,i){
outputstring+= \"\"+i + \" \";
outputstring += sb.sbname + \"\\n\";
sb.mutableCopy().forEach(function(vcname,j){
outputstring += \".\" + j + \" \" + vcname + \"\\n\";
});outputstring += \"\\n\";
});
[ [ NSFileManager defaultManager ] createDirectoryAtPath:\""$dirpath"\" withIntermediateDirectories:NO attributes:nil error: nil ];
[ outputstring writeToFile:\""$dirpath"/"$appname".txt\" atomically:YES ];
";

echo $CYSH | cycript -p $appname

#Present the created file as output to user
echo -e "\033[1;31m"
cat $dirpath/$appname.txt
echo ""
echo -e "\033[1;32m"
echo "Above are the View Controllers identified by Scwapper,"
echo "grouped by their respective storyboards."
while [ true ]
do
echo ""
echo "What should I load?"
echo "Usage: [Storyboard Number].[ViewController Number] <m> "
echo "m - load the controller modally "
echo "examples: 5.0, 11.12 m, ..."
echo ""
echo -e "\033[0m"

#Get controller to load and do it
read whattoload howtoload
if [ "$whattoload" = "d" ]; then
echo "dismissing";
CYSH="[ UIApp.keyWindow.rootViewController dismissViewControllerAnimated:YES completion:nil ];";
else
CYSH="var whattoload = \""$whattoload"\";
var howtoload = \""$howtoload"\";
var sbtoloadidx = floor(whattoload);
var vctoloadidx = (\"\" + whattoload).substr(whattoload.indexOf(\".\")+1);
var sbtoload = sbarr [ sbtoloadidx ];
var vctoload = [ sbtoload instantiateViewControllerWithIdentifier:outputarr [ sbtoloadidx ] .mutableCopy()[ vctoloadidx ] ];
if(howtoload==\"m\")
[ UIApp.keyWindow.rootViewController presentViewController:vctoload animated:NO completion:nil ];
else
[ UIApp.keyWindow.rootViewController showViewController:vctoload sender:nil ];
";
fi

echo $CYSH | cycript -p $appname
done

