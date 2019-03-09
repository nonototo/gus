#!/bin/sh 
# If you are under ULTRIX use /bin/sh5 instead of /bin/sh (too buggy) 
################################################################################ 
# @(#)gus,v 2.8 11/22/1994 (c) XaBier Vazquez Gallardo 
# You'll need this external programs: 
# gzip, tar, sed, awk, unarj, lha, zoo, unzip, test, pgp, uncompress, echo and 
# uudecode. If you don't have all those programs maybe gus won't work. 
# 
# Program Description: 
# Decompress all this kind of files and combinations of them: 
# .arc .zip .ZIP .arj .zoo .lzh .lha .lzh .Z .z .tar .tgz .shar .pgp 
# .[1-8ln] .man .uu and .uue 
# * Man type files will be displayed 
# 
# Please send suggestions or gub reports to XaBi 
# Sorry about my English, but it's better than Spanish, isn't it? 
################################################################################ 
gus_version="V2.8" 
gus_date="11/22/1994" 

# Show a long help :) 
do_help () 
{ 
 echo 
 echo This script helps you decompressing Unix archives compressed with compress, 
 echo gzip, tar, shar, lha, arj, zip, zoo, pgp, arc and uuencode. It also formats 
 echo manual pages. Now you don\'t need to type all those long lines to decompress 
 echo a tar + gz archive, only type \'gus file\' and it will do all the work. 
 echo "GUS knows this extensions and combinations of them (tar + gzip, etc):" 
 echo ".Z .z .zip .arj .zoo .arc .lha .lz .pgp .tar .tgz .shar .[1-8ln] .man .uu .uue" 
 echo 
 echo "USAGE: '`basename $0` [-h | [[-r | -rf] f1 [f2] ...]' will decompress f1, f2, ..." 
 echo "       '-h'  show you this help" 
 echo "       '-r'  remove with prompt compressed file after decompress it" 
 echo "       '-rf' remove without prompt compressed file after decompress it" 
 echo "ie:    '`basename $0` file1 -rf file2 file3' will do this:" 
 echo "        decompress file[123] and remove file[23] without any ask" 
 echo "       *WARNING* Be careful with option '-rf'" 
 exit 0 
} 

# Find a file in your path 
# input : "filename" 
# output: $filresult=full_path/filename || $filename="" + error message 
# ie    : findfile zip 
findfile () 
{ 
 sifs=$IFS 
 IFS=: 
 fileresult="" 
 for dir in $PATH; do 
   test -z "$dir" && dir=. 
   if [ -x $dir/$1 ] ; then 
      fileresult="$dir/$1" 
      break 
   fi 
 done 
 IFS=$sifs 
 test -z "$fileresult" && echo ERROR: Can\'t find $1 
} 

# Change status variables 
# input: " | decompress_command_line" \ 
#        " decompress_program_name +" \ 
#        1 (if gus must create a decompressed file) || 0 (if not) \ 
#        1 (if decompress program can pipe it result) || 0 (if not) \ 
#        1 (if decompress program accepts stdin pipes) || 0 (if not) 
# output: none 
# ie    : changevars " | tar xvfo -" " tar +" 0 1 1 
changevars () 
{ 
 command=$command$1 
 message=$message$2 
 create=$3 
 exit_f=$4 
 do_cat=$5 
} 

# Ask Y/N before remove a file 
# input  : "filename" 
# output : $removeit = 0 (if answer is no) || 1 (if is yes) 
# ie     : makeask /usr/local/foo.bar.tar 
makeask () 
{ 
 exit_ask=0 
 while [ $exit_ask = 0 ] ; do 
   echo "Do you want to remove '$1' [Y/N]? \c" 
   read yesno 
   case $yesno in 
     y* | Y*) 
       removeit=1 
       exit_ask=1 
     ;; 
     n* | N*) 
       removeit=0 
       exit_ask=1 
     ;; 
   esac 
 done 
} 

# Check program parameters and count files 
# input  : "command_line_params" 
# output : $total_files=num_of_files_to_process || or help_screen 
# ie     : check_params -rf foo.tar 
check_params () 
{ 
 for i in $* 
 do 
   case $i in 
     -rf | -r) 
       total_files=`expr $total_files - 1` 
     ;; 
     -h) 
       do_help 
     ;; 
   esac 
 done 
} 

echo GUS $gus_version [$gus_date] General Unpack Shell for Un*x \(c\) XaBi 

total_files=$# 

check_params $* 

if [ $total_files = 0 ] ; then 
   echo ERROR: not enough params 
   echo "TRY  : `basename $0` -h" 
   exit 1 
fi 

if [ $total_files = 1 ] ; then 
   echo [ $total_files ] file to process ... 
else 
   echo [ $total_files ] files to process ... 
fi 

removefile=0 
promptbefore=0 

for file_tmp in $* 
do 
  case $file_tmp in 
       -rf) 
          removefile=1 
          promptbefore=0 
          continue 
        ;; 
       -r) 
          removefile=1 
          promptbefore=1 
          continue 
        ;; 
  esac 
  if test -f $file_tmp ; then 
     exit_f=0 
     command="" 
     message="" 
     do_cat=1 
     create=1 
     file=`basename $file_tmp` 
     while [ $exit_f -eq 0 ] ; do 
       old_file=$file 
       extension=`echo $file | sed -e 's/.*\.//'` 
       if [ "$extension" = "$file" ] ; then 
          extension="" 
       else 
          file=`echo $file | sed -e s/\.$extension$//` 
       fi 
       case $extension in 
         tar) 
           changevars " | tar xvfo -" " tar +" 0 1 1 
         ;; 
         Z) 
           changevars " | uncompress" " compress +" 1 0 1 
         ;; 
         z | gz) 
           changevars " | gzip -d" " gzip +" 1 0 1 
         ;; 
         tgz) 
           changevars " | gzip -d | tar xvfo -" " tar + gzip +" 0 1 1 
         ;; 
         uu | uue) 
           changevars " | uudecode" " uuencode +" 0 1 1 
         ;; 
         shar) 
           changevars " | sh" " shar +" 0 1 1 
         ;; 
         zip | ZIP) 
           if [ -z "$command" ] ; then 
              findfile unzip 
              test ! -z "$fileresult" && changevars $fileresult " zip +" 0 1 0 
           else 
              echo ERROR: Can\'t pipe to unzip. File partialy decompressed. 
           fi 
           exit_f=1 
         ;; 
         arj | ARJ) 
           if [ -z "$command" ] ; then 
              findfile unarj 
              test ! -z "$fileresult" && changevars $fileresult" x" " arj +" 0 1 0 
           else 
              echo ERROR: Can\'t pipe to unarj. File partialy decompressed. 
           fi 
           exit_f=1 
         ;; 
         arc | ARC) 
           if [ -z "$command" ] ; then 
              findfile arc 
              test ! -z "$fileresult" && changevars $fileresult" x" " arc +" 0 1 0 
           else 
              echo ERROR: Can\'t pipe to arc. File partialy decompressed. 
           fi 
           exit_f=1 
         ;; 
         zoo | ZOO) 
           if [ -z "$command" ] ; then 
              findfile zoo 
              test ! -z "$fileresult" && changevars $fileresult" x" " zoo +" 0 1 0 
           else 
              echo ERROR: Can\'t pipe to zoo. File partialy decompressed. 
           fi 
           exit_f=1 
         ;; 
         lzh | lha | lz | LZH | LHZ | LZ) 
           findfile lha 
           test ! -z "$fileresult" && changevars " | "$fileresult" x -" " lha +" 0 1 1 
           exit_f=1 
         ;; 
         pgp) 
           findfile pgp 
           if [ ! -z "$fileresult" ] ; then 
              changevars " | "$fileresult " pgp +" 0 0 1 
           else 
              exit_f=1 
           fi 
         ;; 
         [1-8nl] | man) 
           test -z "$command" && changevars " | nroff -man | more" " man +" 0 1 1 
           exit_f=1 
         ;; 
         *) 
           exit_f=1 
         ;; 
       esac 
     done 
     test $create -eq 1 && command=$command" > "$old_file 
     if [ -z "$message" ] ; then 
         echo ERROR: Don\'t know how to handle [ $file_tmp ] 
     else 
         message=`echo $message | sed -e 's/ +$//'` 
         echo "File [ `basename $file_tmp` ]" 
         echo "Type [ $message ]" 
         if [ $do_cat = 1 ] ; then 
            command="cat "$file_tmp" "$command 
         else 
            command=$command" "$file_tmp 
         fi 
         eval $command && { 
           if [ $removefile = 1 ] ; then 
              if [ $promptbefore = 1 ] ; then 
                 makeask $file_tmp 
                 test $removeit -eq 1 && rm -f $file_tmp 
              else 
                 rm -f $file_tmp 
              fi 
           fi 
         } || echo ERROR: [ $file_tmp ] can\'t decompress ... 
     fi 
  else 
     echo ERROR: [ $file_tmp ] Can\'t process it! Exists???? 
  fi 
done