#############################
#usage: 1. cvi.sh .    -------> seaching files in current directory Recursively
#       2. cvi.sh sys  -------> searching files in /usr/include
#
#I hope you can provide some suggestions, thank you.
#############################
#!/bin/bash
#####
#find . -regex ".*\.\(c\|h\|hpp\|cc\|cpp\)" -print
#####
if [ $# -ne 1 ]; then
        echo "Usage: "$(basename $0)" . | sys"
        exit 1
fi


scanincludePath=(
"sys" "bits" "asm" "asm-generic" "netinet" "arpa"
"glib-2.0" "gtk-2.0" "gtk-3.0" "cairo" "c++/10"
"openssl" "xorg" "boost"
#"boost" "glibmm-2.4" "gdkmm-2.4" "gtkmm-2.4"
#"AL" "GL" "SDL" "libxml2"
)

scanlocalPath=(
"cuda-11.3/include"
)

# don't modify below
#---------------------------------------------------------------------------------#
tmpDir=~/.vim/tmp
[ -d "${tmpDir}" ] || mkdir -p ${tmpDir}
#randomNum=`head -50 /dev/urandom | md5sum | awk '{print $1}'`
tmpFile="${tmpDir}/ctags${RANDOM}"
tagName="tags"

> ${tmpFile}
if [ "$1" = "." ]; then
        find . -type f \
        -a \( -name "*.h" -o -name "*.hpp" -o -name "*.cpp" -o -name "*.c" \
        -o -name "*.cc" -o -name "*.java" -o -name "*.pc" \) > $tmpFile
        putDir=.
elif [ "$1" = "sys" ]; then
        # get file list to be operating
        for dir in ${scanincludePath[*]}; do
                scanDir=${scanDir}" /usr/include/"${dir}
        done
        for dir in ${scanlocalPath[*]}; do
                scanDir=${scanDir}" /usr/local/"${dir}
        done

        putDir=${tmpDir}
        find /usr/include /usr/local/include -maxdepth 1 -type f \
        -a \( -name "*.h" -o -name "*.hpp" -o -name "*.cpp" -o -name "*.c" \
    -o -name "*.cc" -o -name "*.java" -o -name "*.pc" \) > ${tmpFile}

        find ${scanDir} -type f \
        -a \( -name "*.h" -o -name "*.hpp" -o -name "*.cpp" -o -name "*.c" \
    -o -name "*.cc" -o -name "*.java" -o -name "*.pc" \) >> ${tmpFile}
fi

cd ${putDir}
rm -f cscope.* ${tagName}
ctags -I "__THROW __nonnull __attribute_pure__ __attribute__ G_GNUC_PRINTF+" \
--file-scope=yes --c++-kinds=+px --c-kinds=+px --fields=+iaS -Ra --extra=+fq \
--langmap=c:.c.h.pc.ec --languages=c,c++ --links=yes -f ${tagName} -L $tmpFile

#-k means kernel mode: don't parse /usr/include
#-q: large project use this
#cscope -Rqkb -i $tmpFile
ctags -L $tmpFile
cscope -Rb -i $tmpFile


#-------cleanup--------------------
rm -f $tmpFile

echo "Done!"
