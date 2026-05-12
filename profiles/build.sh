#!/usr/bin/env bash

if (( ${BASH_VERSION%%.*} < 5 )); then
    echo "Bash version 5 or higher is required. Detected: $BASH_VERSION"
    exit 1
fi

DRYRUN=false
if [ "$1" == --dry-run ]
then
    DRYRUN=true
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROFILES=(fsrw fsro git web full)

declare -A SERVERS
SERVERS["context7"]=context7
SERVERS["fetch"]=fetch
SERVERS["git"]=git
SERVERS["filesystem"]=rust-mcp-filesystem
SERVERS["search"]=duckduckgo
declare -A CATALOG
CATALOG["context7"]=catalog://mcp/docker-mcp-catalog/${SERVERS["context7"]}
CATALOG["fetch"]=catalog://mcp/docker-mcp-catalog/${SERVERS["fetch"]}
CATALOG["git"]=catalog://mcp/docker-mcp-catalog/${SERVERS["git"]}
CATALOG["filesystem"]=catalog://mcp/docker-mcp-catalog/${SERVERS["filesystem"]}
CATALOG["search"]=catalog://mcp/docker-mcp-catalog/${SERVERS["search"]}

dmp(){
    if $DRYRUN
    then
        echo docker mcp profile $@
    else
        docker mcp profile $@
    fi
}

# Create the profiles, removing old before if those exist
existing=($(docker mcp profile list --format json | jq -r ".[].name"))
for profile in ${PROFILES[@]}; do
    if [[ ${existing[@]} =~ $profile ]]
    then
        dmp remove $profile
    fi

    dmp create --name $profile
done

# Writable filesystem
profile=fsrw
dmp server add $profile --server ${CATALOG["filesystem"]}
dmp tools $profile --disable-all ${SERVERS["filesystem"]}
dmp tools $profile --enable ${SERVERS["filesystem"]}.create_directory
dmp tools $profile --enable ${SERVERS["filesystem"]}.directory_tree
dmp tools $profile --enable ${SERVERS["filesystem"]}.edit_file
dmp tools $profile --enable ${SERVERS["filesystem"]}.get_file_info
dmp tools $profile --enable ${SERVERS["filesystem"]}.head_file
dmp tools $profile --enable ${SERVERS["filesystem"]}.list_directory
dmp tools $profile --enable ${SERVERS["filesystem"]}.move_file
dmp tools $profile --enable ${SERVERS["filesystem"]}.read_file_lines
dmp tools $profile --enable ${SERVERS["filesystem"]}.read_multiple_text_files
dmp tools $profile --enable ${SERVERS["filesystem"]}.read_text_file
dmp tools $profile --enable ${SERVERS["filesystem"]}.search_files
dmp tools $profile --enable ${SERVERS["filesystem"]}.search_files_content
dmp tools $profile --enable ${SERVERS["filesystem"]}.tail_file
dmp tools $profile --enable ${SERVERS["filesystem"]}.write_file

# Readonly filesystem
profile=fsro
dmp server add $profile --server ${CATALOG["filesystem"]}
dmp tools $profile --disable-all ${SERVERS["filesystem"]}
dmp tools $profile --enable ${SERVERS["filesystem"]}.directory_tree
dmp tools $profile --enable ${SERVERS["filesystem"]}.get_file_info
dmp tools $profile --enable ${SERVERS["filesystem"]}.head_file
dmp tools $profile --enable ${SERVERS["filesystem"]}.list_directory
dmp tools $profile --enable ${SERVERS["filesystem"]}.read_file_lines
dmp tools $profile --enable ${SERVERS["filesystem"]}.read_multiple_text_files
dmp tools $profile --enable ${SERVERS["filesystem"]}.read_text_file
dmp tools $profile --enable ${SERVERS["filesystem"]}.search_files
dmp tools $profile --enable ${SERVERS["filesystem"]}.search_files_content
dmp tools $profile --enable ${SERVERS["filesystem"]}.tail_file

# Git repository
profile=git
dmp server add $profile --server ${CATALOG["git"]}
dmp tools $profile --disable-all ${SERVERS["git"]}
dmp tools $profile --enable ${SERVERS["git"]}.git_add
dmp tools $profile --enable ${SERVERS["git"]}.git_checkout
dmp tools $profile --enable ${SERVERS["git"]}.git_commit
dmp tools $profile --enable ${SERVERS["git"]}.git_diff
dmp tools $profile --enable ${SERVERS["git"]}.git_diff_staged
dmp tools $profile --enable ${SERVERS["git"]}.git_diff_unstaged
dmp tools $profile --enable ${SERVERS["git"]}.git_log
dmp tools $profile --enable ${SERVERS["git"]}.git_show
dmp tools $profile --enable ${SERVERS["git"]}.git_status

# Web search and fetching
profile=web
dmp server add $profile --server ${CATALOG["search"]}
dmp tools $profile --disable-all ${SERVERS["search"]}
dmp tools $profile --enable ${SERVERS["search"]}.search
dmp server add $profile --server ${CATALOG["fetch"]}
dmp tools $profile --disable-all ${SERVERS["fetch"]}
dmp tools $profile --enable ${SERVERS["fetch"]}.fetch
dmp server add $profile --server ${CATALOG["context7"]}
dmp tools $profile --disable-all ${SERVERS["context7"]}
dmp tools $profile --enable ${SERVERS["context7"]}.resolve-library-id
dmp tools $profile --enable ${SERVERS["context7"]}.get-library-docs

# Full, contains all tools of the above
profile=full
dmp server add $profile --server ${CATALOG["filesystem"]}
dmp tools $profile --disable-all ${SERVERS["filesystem"]}
dmp tools $profile --enable ${SERVERS["filesystem"]}.create_directory
dmp tools $profile --enable ${SERVERS["filesystem"]}.directory_tree
dmp tools $profile --enable ${SERVERS["filesystem"]}.edit_file
dmp tools $profile --enable ${SERVERS["filesystem"]}.get_file_info
dmp tools $profile --enable ${SERVERS["filesystem"]}.head_file
dmp tools $profile --enable ${SERVERS["filesystem"]}.list_directory
dmp tools $profile --enable ${SERVERS["filesystem"]}.move_file
dmp tools $profile --enable ${SERVERS["filesystem"]}.read_file_lines
dmp tools $profile --enable ${SERVERS["filesystem"]}.read_multiple_text_files
dmp tools $profile --enable ${SERVERS["filesystem"]}.read_text_file
dmp tools $profile --enable ${SERVERS["filesystem"]}.search_files
dmp tools $profile --enable ${SERVERS["filesystem"]}.search_files_content
dmp tools $profile --enable ${SERVERS["filesystem"]}.tail_file
dmp tools $profile --enable ${SERVERS["filesystem"]}.write_file
dmp server add $profile --server ${CATALOG["git"]}
dmp tools $profile --disable-all ${SERVERS["git"]}
dmp tools $profile --enable ${SERVERS["git"]}.git_add
dmp tools $profile --enable ${SERVERS["git"]}.git_checkout
dmp tools $profile --enable ${SERVERS["git"]}.git_commit
dmp tools $profile --enable ${SERVERS["git"]}.git_diff
dmp tools $profile --enable ${SERVERS["git"]}.git_diff_staged
dmp tools $profile --enable ${SERVERS["git"]}.git_diff_unstaged
dmp tools $profile --enable ${SERVERS["git"]}.git_log
dmp tools $profile --enable ${SERVERS["git"]}.git_show
dmp tools $profile --enable ${SERVERS["git"]}.git_status
dmp server add $profile --server ${CATALOG["search"]}
dmp tools $profile --disable-all ${SERVERS["search"]}
dmp tools $profile --enable ${SERVERS["search"]}.search
dmp server add $profile --server ${CATALOG["fetch"]}
dmp tools $profile --disable-all ${SERVERS["fetch"]}
dmp tools $profile --enable ${SERVERS["fetch"]}.fetch
dmp server add $profile --server ${CATALOG["context7"]}
dmp tools $profile --disable-all ${SERVERS["context7"]}
dmp tools $profile --enable ${SERVERS["context7"]}.resolve-library-id
dmp tools $profile --enable ${SERVERS["context7"]}.get-library-docs

# export profiles
for profile in ${PROFILES[@]}; do
    dmp export $profile $DIR/$profile.yaml
done
