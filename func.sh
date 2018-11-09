
checkDir ()
{
    if [ -z "$1" ]; then
        $1=$2
    fi

    if [ ! -d $1 ]; then
        mkdir -p $1 && sudo chmod -R 777 $1
    fi

    echo $1
}

errorReport()
{
    if [ $? -gt 0 ]; then
        exit $?
    fi
}

specifyDomain ()
{
    read -p 'please input the domain name, like [zhufengwei.com]: ' -a domainName

    domainName=$(echo $domainName | sed -n 's/^[ ]*\(.*\)[ ]*$/\1/p')

    if [ -z "$domainName" ]; then
        echo "The Domain Name Can't Be Null!"
        exit 1
    fi

    echo $domainName
}
