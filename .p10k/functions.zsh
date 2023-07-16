source ~/.local/bin/_env
source "${CONFIG_ROOT}/.wkit"

function prompt_weather() {
	local usingCache=true
	local cacheAge=0
	local weatherCacheFile=${POWERLEVEL9K_WEATHER_LOCAL_CACHE_FILE}
	local weatherFileExists=$(test -f $weatherCacheFile)
	local weatherLastModified=300;
    local hasData=false;
	if [[ weatherFileExists ]] ;
	then now=$(date +%s) ;
    if [[ $(uname -s) == "Darwin" ]]
        then file=$(date -j -f "%s" "$(stat -f "%m" $weatherCacheFile)" +"%s") ;
        else file=$(date +%s -r $weatherCacheFile) ;
    fi
    weatherLastModified=$((now-file))
    cacheAge=$weatherLastModified
	fi
	
	if [[ weatherLastModified -ge ${POWERLEVEL9K_WEATHER_LOCAL_CACHE_EXPIRATION_SECONDS} || ! weatherFileExists ]] ;
    then
        weatherData=$(wkit --json --latitude ${POWERLEVEL9K_WEATHER_LATITUDE} --longitude ${POWERLEVEL9K_WEATHER_LONGITUDE} --key-path "${POWERLEVEL9K_WEATHER_WEATHERKIT_KEY_PATH}")
        echo $weatherData > $weatherCacheFile
		cacheAge=0
		usingCache=false
	fi
	
	local weather=$(<$weatherCacheFile)
    local tempInC=$(echo $weather | jq .currentWeather.temperatureApparent)
    if [[ -n $tempInC ]] ;
        then hasData=true ;
        else tempInC=0 ;
    fi
    
    local temp=$(($tempInC * 9/5 + 32))
	local precipProb=$(echo $weather | jq .currentWeather.precipitationIntensity)

    if [[ -n $precipProb ]] ;
        then hasData=true ;
            else precipProb=0 ;
    fi

    local condition=$(echo $weather | jq .currently.conditionCode)
    if [[ -n $condition ]] ;
        then ;
        else condition="clear" ;
    fi

    local symbol="\uF2CB"
    local color=0
    local bg=0

    if [[ $temp -eq '' ]]
        then temp='0'
    fi
            
    if [[ $condition == *"clear"* ]] ;
        then symbol="\uE30D" ;
    fi

    if [[ $condition == *"rain"* ]] ;
        then symbol="\uE318" ;
    fi

    if [[ $condition == *"cloudy"* ]] ;
        then symbol="\uE312" ;
    fi	

    if [[ $condition == *"snow"* ]] ;
        then symbol="\uE31A" ;	
    fi

    if [[ $condition == *"sleet"* ]] ;
        then symbol="\uE3AD" ;
    fi

    if [[ $condition == *"wind"* ]] ;
        then symbol="\uE31E" ;
    fi

    if [[ $condition == *"fog"* ]] ;
        then symbol="\uE313" ;
    fi

    if [[ $temp -le 30 ]] ;
        then bg=020 ; color=255 ;
    fi

    if [[ $temp -gt 30 && $temp -le 40 ]] ;
        then bg=032 ; color=0 ;
    fi

    if [[ $temp -gt 40 && $temp -le 50 ]] ;
        then bg=044 ; color=0 ;
    fi

    if [[ $temp -gt 50 && $temp -le 60 ]] ;
        then bg=056 ; color=255 ;
    fi

    if [[ $temp -gt 60 && $temp -le 70 ]] ;
        then bg=068 ; color=0 ;
    fi

    if [[ $temp -gt 70 && $temp -le 80 ]] ;
        then bg=082 ; color=0 ;
    fi

    if [[ $temp -gt 80 && $temp -le 90 ]] ;
        then bg=214 ; color=0 ;
    fi

    if [[ $temp -gt 90 ]] ;
        then bg=196 ; color=0 ;
    fi

integer roundTemp=$((rint($temp)))

#local val=$(echo -n "$roundTemp\uE33EF $((precipProb*100))%% \uF5E7 ${cacheAge}s")
local val=$(echo -n "$roundTemp\uE33EF $((precipProb*100))%%")
local sym=$(echo -n "$symbol")

if [[ $hasData == true ]] ;
then p10k segment -b $bg -f $bg -i $sym -t "$val";
else p10k segment -b $bg -f $bg -i $sym -t "no data" ;
fi ;

}

typeset -g POWERLEVEL9K_STOCK_CONFIG_FILE="$HOME/.ticker.yaml"
typeset -g POWERLEVEL9K_STOCK_LOCAL_CACHE_FILE=~/.stocks
typeset -g POWERLEVEL9K_STOCK_LOCAL_CACHE_EXPIRATION_SECONDS=600

function prompt_stocks(){
local usingCache=true
local cacheAge=0
local stockCacheFile=${POWERLEVEL9K_STOCK_LOCAL_CACHE_FILE}
local stockFileExists=$(test -f $stockCacheFile)
local stockLastModified=300;
if [[ stockFileExists ]] ;
then 
    now=$(date +%s)
if [[ $(uname -s) == "Darwin" ]]
then file=$(date -j -f "%s" "$(stat -f "%m" $stockCacheFile)" +"%s") ;
    else file=$(date +%s -r $stockCacheFile) ;
fi
    stockLastModified=$((now-file))
    cacheAge=$stockLastModified
fi

if [[ stockLastModified -ge ${POWERLEVEL9K_STOCK_LOCAL_CACHE_EXPIRATION_SECONDS} || ! stockFileExists ]] ;
then
    stockData=$(curl -s "https://query1.finance.yahoo.com/v7/finance/quote?fields=shortName,regularMarketChange,regularMarketChangePercent,regularMarketPrice&region=US&lang=en-US&symbols=MSFT" | jq '.quoteResponse | .result')
    echo $stockData > $stockCacheFile
    cacheAge=0
    usingCache=false
fi

local stock=$(<$stockCacheFile)
local price=$(echo $stock | jq '.[0].regularMarketPrice | tonumber')
local stockSymbol=$(echo $stock | jq -r '.[0].symbol')
local changePercent=$(echo $stock | jq '.[0].regularMarketChangePercent | tonumber')
# echo "$(($((ticker print) | jq '.[0].changePercent | tonumber') * 100))"
local changeDirection=$(echo $stock | jq '.[0].regularMarketChange | tonumber')
#local symbol="\uFC2C"
local symbol="ﰬ"
local color=0
local bg=196
if [[ changeDirection -gt 0 ]] ;
then
bg=046 ; symbol="\uFC35" ; symbol="ﰵ" ;
fi

local val=$(echo -n \$$price $(printf '%.3g' $changePercent)\%%)
#local sym=$(echo -n "$symbol ")
#local sym=$symbol

p10k segment -b $bg -f $bg -t $val +e #-i $sym +r +e

}

function prompt_pm25out() {
    local PMIN=$(echo $(~/.local/bin/pm) | jq '[.[] | select(.pm25 != null)][0] | .pm25')
    local bg=196
    local color=0
    if [[ $PMIN -le 12 ]]; then
        bg=green
        color=0
    fi
    if [[ $PMIN -gt 12 && $PMIN -le 35 ]]; then
        bg=yellow
        color=0
    fi
    if [[ $PMIN -gt 35 && $PMIN -le 55 ]]; then
        bg=208
        color=0
    fi
    if [[ $PMIN -gt 55 && $PMIN -le 150 ]]; then
        bg=red
        color=0
    fi
    if [[ $PMIN -gt 150 && $PMIN -le 250 ]]; then
        bg=purple
        color=0
    fi
    if [[ $PMIN -gt 250 ]]; then
        bg=maroon
        color=0
    fi
    p10k segment -b $bg -f $bg -i $'\uE27E' +r -t "${PMIN}µg/m3"
}

function prompt_pm25in() {
    local PMIN=$(echo $(~/.local/bin/pm) | jq '[.[] | select(.pm25_in != null)][0] | .pm25_in')
    local bg=196
    local color=0
    if [[ $PMIN -le 12 ]]; then
        bg=green
        color=0
    fi
    if [[ $PMIN -gt 12 && $PMIN -le 35 ]]; then
        bg=yellow
        color=0
    fi
    if [[ $PMIN -gt 35 && $PMIN -le 55 ]]; then
        bg=orange
        color=0
    fi
    if [[ $PMIN -gt 55 && $PMIN -le 150 ]]; then
        bg=red
        color=0
    fi
    if [[ $PMIN -gt 150 && $PMIN -le 250 ]]; then
        bg=purple
        color=0
    fi
    if [[ $PMIN -gt 250 ]]; then
        bg=maroon
        color=0
    fi
    p10k segment -b $bg -f $bg -i $'\uF015' +r -t "${PMIN}µg/m3"
}