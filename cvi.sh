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
if [ $# -lt 1 ]; then
        echo "Usage: "$(basename $0)" . | sys <anychar_refresh_tags>"
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
tmpFile="${tmpDir}/ctags${RANDOM}"

git_root=$(git rev-parse --show-toplevel)
if [ $? -ne 0 ]; then
        git_root='.'
fi
tagName="tags"
tagFile="${git_root}/${tagName}"
if [ $# -gt 1 ]; then
        rm -f "${tagFile}"
fi

> ${tmpFile}
if [ "$1" = "." ]; then
        cmd="find "${git_root}" -type f \
        -a \( -name "*.h" -o -name "*.hpp" -o -name "*.cpp" -o -name "*.c" \
        -o -name "*.cc" -o -name "*.java" -o -name "*.pc" \)"
        if [ -f "${tagFile}" ]; then
                cmd="${cmd} -newer ${tagFile}"
        fi
        echo "$cmd"
        eval "$cmd" > $tmpFile
        putDir="${git_root}"
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
#rm -f cscope.* ${tagFile}
ctags -I "__THROW __nonnull __attribute_pure__ __attribute__ G_GNUC_PRINTF+" \
--append --file-scope=yes --c++-kinds=+px --c-kinds=+px --fields=+iaS -Ra --extra=+fq \
--langmap=c:.c.h.pc.ec --languages=c,c++ --links=yes -f ${tagFile} -L $tmpFile

#-k means kernel mode: don't parse /usr/include
#-q: large project use this
#cscope -Rqkb -i $tmpFile
if [ -s "${tmpFile}" ]; then
        cscope -Rb -i $tmpFile
fi


#-------cleanup--------------------
rm -f $tmpFile

echo "Done!"
