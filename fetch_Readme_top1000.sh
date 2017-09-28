#!/bin/bash

topNumber=$1 #how many top repo do you want to retrieve their readme files.
clientAccount=$2
clientCnt=$(cat $clientAccount | wc -l)
prefix="https://api.github.com/search/repositories?"
query="q=created:>1970-01-01+forks:>1000&sort=forks&order=desc"
pageLimit=100

mkdir -p readme_dir

#example get_topN_forkedRepo $topNumber
function get_topN_forkedRepo(){

    rm topN_fnBranch
    topN=$1
    gotFn=0
    cnt=1
    clientNum=$((cnt%clientCnt + 1))
    client=$(sed -n "${clientNum}p" $clientAccount)
    pageCnt=1
    url="${prefix}${query}&page=${pageCnt}&per_page=${pageLimit}&${client}"
    curl -m 120 $url -o tmpFilter

    grep -E "\"full_name\":" tmpFilter >tmp_fn
    grep -E "\"full_name\":|\"language\":|\"forks_count\":|\"default_branch\":" tmpFilter >tmp_fn_branch
    fnCnt=$(cat tmp_fn | wc -l)
    gotFn=$((gotFn+fnCnt))
    cat tmp_fn_branch >> topN_fnBranch

    if [ $fnCnt -eq 0 ];then
       return 
    fi

    if [ $gotFn -eq $topN ];then
        return
    fi
    while [ $gotFn -lt $topN ]
    do
        pageCnt=$((pageCnt+1))
        cnt=$((cnt+1))
        clientNum=$((cnt%clientCnt + 1))
        client=$(sed -n "${clientNum}p" $clientAccount)
        url="${prefix}${query}&page=${pageCnt}&per_page=${pageLimit}&${client}"

        rm tmpFilter
        curl -m 120 $url -o tmpFilter

        grep -E "\"full_name\":" tmpFilter >tmp_fn
        grep -E "\"full_name\":|\"language\":|\"forks_count\":|\"default_branch\":" tmpFilter >tmp_fn_branch
        fnCnt=$(cat tmp_fn | wc -l)
        gotFn=$((gotFn+fnCnt))
        cat tmp_fn_branch >> topN_fnBranch
    done
    rm tmp_fn tmpFilter tmp_fn_branch
}

#usage: download_readme fn_branch_fin
function download_readme(){
   fnBr=$1
   num=$(cat $fnBr | wc -l)
   num=$((num/4))
   for i in `seq 1 $num` #file format:fn\nforks\ndefault_br
   do
       fnNo=$((4*(i-1)+1))
       langNo=$((4*(i-1)+2))
       brNo=$((4*i))
       fn=$(sed -n "${fnNo}p" $fnBr | awk -F "\"" '{print $4}')
       lang=$(sed -n "${langNo}p" $fnBr | awk '{print $NF}' | cut -f1 -d ",")
       br=$(sed -n "${brNo}p" $fnBr | awk -F "\"" '{print $4}')
       if [ "$lang" = "null" ];then
           echo $fn, $br, $lang >>nulllanguage_fn
           continue
       fi
       #https://raw.githubusercontent.com/case451/hw3_rottenpotatoes/master/README
       user=$(echo $fn | cut -f1 -d "/")
       repo=$(echo $fn | cut -f2 -d "/")
       crawl $fn $br "README"
       crawl $fn $br "CONTRIBUTING"
       crawl $fn $br "CHANGELOG"
   done
}

function crawl(){
    fn=$1
    br=$2
    fileType=$3 #canbe: README, CONTRIBUTING
    url="https://raw.githubusercontent.com/$fn/$br/${fileType}{.md,.txt,}"
    curl --fail $url -o readme_dir/${user}_${repo}_${fileType}
}

get_topN_forkedRepo $topNumber
download_readme topN_fnBranch
