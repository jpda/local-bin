#!/bin/bash

echo $(ambient) | jq '[ (.[] | select(.lastData.pm25 != null ) | 
                                {"pm25": .lastData.pm25, "lastDate": .lastData.date, "reportedBy":.info.name}), 
                            (.[] | select(.lastData.pm25_in != null) | 
                                {"pm25_in": .lastData.pm25_in, "lastDate": .lastData.date, "reportedBy":.info.name}) 
                        ]'
