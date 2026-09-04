# /bin/zsh
# apple weather attribution requirements 🙄

#echo "Weather data provided by \ue711 $(curl -s "https://weatherkit.apple.com/attribution/en" | jq -r '.serviceName')"
# echo "Weather data provided by \ue711 Weather"

weather() {
    # weather command here
    echo "Weather data provided by  Weather"
}