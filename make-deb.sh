#!/bin/bash

set -e

# add command line flag processing

function usage() {
    echo "Usage: `basename $0` -c <URL to YAML config file> or `basename $0` -v <version> -p <package> -c <command> -d <deps>" >&2
    echo "Options:"  >&2
    echo "  -v <version>   Set the version (e.g. 0.0.1), not needed with URL config" >&2
    echo "  -p <package>   Set the package name, not needed with URL config" >&2    
    echo "  -c <command>   Set the command to run OR the URL to a YAML config file (http or file, where a file ahs to a yaml file in the current directory)" >&2
    echo "  -b <image_tag> Docker baseimage to use (default: ubuntu:jammy), not needed with URL config" >&2
    echo "  -d <deps>      declare the ubuntu package dependencies, not needed with URL config" >&2
    exit 1
}



baseimage="ubuntu:jammy"

while getopts ":v:p:c:d:b:u:h" opt; do
    case $opt in
        v) version=$OPTARG;;
        p) package=$OPTARG;;
        c) command=$OPTARG;;
        b) baseimage=$OPTARG;;
        d) deps=$OPTARG;;
        h) usage;;
        \?) echo "Invalid option -$OPTARG" >&2;;
    esac
done



# if $command or $version or $package is empty, then print usage and exit
if [ -z "$command" ]; then
    usage
else  
    if echo "$command" | grep -q "^http\|^file:"; then
        echo "Using URL config file: $command"
        image_name=`echo "$command" | sed 's/[^a-zA-Z0-9]/-/g'`
        image_name="fpm_build_debian_${image_name}"
    else
        if [ -z "$command" ] || [ -z "$version" ] || [ -z "$package" ]; then
            usage
        fi  
    fi
fi

# Usage example:
# ./make-deb.sh -v 0.0.1 -p mypackage -c mycommand
mkdir -p output

image_name=${image_name:-"fpm_build_debian_${package}_${version}"}

docker build \
    --build-arg VERSION="$version" \
    --build-arg DEBIAN_DEPS="$deps" \
    --build-arg INSTALL_CMD="$command" \
    --build-arg PACKAGE_NAME="$package" \
    --build-arg BASE_IMAGE="$baseimage" \
    --progress=plain -t lcas.lincoln.ac.uk/lcas/$image_name . 2>&1  | tee `pwd`/output/build-${image_name}.log \
        | sed 's/^#[0-9 \.]*::\(.*\)::\(.*\)/::\1::\2/' \
    && \
  docker run -v `pwd`/output:/output --rm lcas.lincoln.ac.uk/lcas/$image_name
  #docker rmi $image_name


        #| sed 's/^#[0-9 \.]*::\([a-z]*\)group\(.*\)/::\1group\2/'
