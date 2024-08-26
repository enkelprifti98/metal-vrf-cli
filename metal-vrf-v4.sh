#!/bin/bash

list_vrfs () {

        echo -e "\nChoose an option:"
        PS3=$'\n''Choose an option: '
        options=("Show all VRFs" "Show VRFs in a specific metro" "Show specific VRF by UUID")
        select opt in "${options[@]}"
        do
            case $opt in
                "Show all VRFs")
                        USER_CHOICE=all_vrfs
                        break
                    ;;
                "Show VRFs in a specific metro")
                        USER_CHOICE=by_metro
                        break
                    ;;
                "Show specific VRF by UUID")
                        USER_CHOICE=by_uuid
                        break
                    ;;
                *) echo "invalid option $REPLY";;
            esac
        done
        PS3='Please enter your choice: '


        if [ $USER_CHOICE = "all_vrfs" ] ; then
            echo "Printing all VRFs in the Project..."
            sleep 1
            OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/projects/$PROJECT_UUID/vrfs?per_page=250&include=metro" \
                    -X GET \
                    -H "Content-Type: application/json" \
                    -H "X-Auth-Token: $AUTH_TOKEN" )
            sleep 1
            if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                    echo $OUTPUT
            else
                    echo $OUTPUT | jq -r '.vrfs[] | { "VRF ID":.id, "Name":.name, "Description":.description, "Metro":.metro | "\(.name) (\(.code))", "Local ASN":.local_asn, "IP Ranges":.ip_ranges, "BGP Dynamic Neighbors enabled":.bgp_dynamic_neighbors_enabled, "BGP Dynamic Neighbors export route map":.bgp_dynamic_neighbors_export_route_map, "BGP Dynamic Neighbors BFD enabled":.bgp_dynamic_neighbors_bfd_enabled}'
                    echo "Done..."
            fi

        elif [ $USER_CHOICE = "by_metro" ] ; then
            read -e -p "Enter metro code: " METRO
            sleep 1
            OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/projects/$PROJECT_UUID/vrfs?per_page=250&metro=$METRO&include=metro" \
                    -X GET \
                    -H "Content-Type: application/json" \
                    -H "X-Auth-Token: $AUTH_TOKEN" )
            sleep 1
            if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                    echo $OUTPUT
            else
                    echo $OUTPUT | jq -r '.vrfs[] | { "VRF ID":.id, "Name":.name, "Description":.description, "Metro":.metro | "\(.name) (\(.code))", "Local ASN":.local_asn, "IP Ranges":.ip_ranges, "BGP Dynamic Neighbors enabled":.bgp_dynamic_neighbors_enabled, "BGP Dynamic Neighbors export route map":.bgp_dynamic_neighbors_export_route_map, "BGP Dynamic Neighbors BFD enabled":.bgp_dynamic_neighbors_bfd_enabled}'
                    echo "Done..."
            fi

        elif [ $USER_CHOICE = "by_uuid" ] ; then
            read -e -p "Enter VRF UUID: " VRF_UUID
            sleep 1

            OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/vrfs/$VRF_UUID?include=metro" \
                    -X GET \
                    -H "Content-Type: application/json" \
                    -H "X-Auth-Token: $AUTH_TOKEN" )
            sleep 1
            if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                    echo $OUTPUT
            else
                    echo $OUTPUT | jq -r '.vrfs[] | { "VRF ID":.id, "Name":.name, "Description":.description, "Metro":.metro | "\(.name) (\(.code))", "Local ASN":.local_asn, "IP Ranges":.ip_ranges, "BGP Dynamic Neighbors enabled":.bgp_dynamic_neighbors_enabled, "BGP Dynamic Neighbors export route map":.bgp_dynamic_neighbors_export_route_map, "BGP Dynamic Neighbors BFD enabled":.bgp_dynamic_neighbors_bfd_enabled}'
                    echo "Done..."
            fi

        fi

}

create_vrf () {
        echo -e "\nCreate VRF\n( Type c to cancel )\n"
        read -e -p "Enter VRF Name: " VRF_NAME
        if [ "$VRF_NAME" = "c" ] ; then
            echo -e ""
            return
        fi
        read -e -p "Enter VRF Description: " VRF_DESCRIPTION
        if [ "$VRF_DESCRIPTION" = "c" ] ; then
            echo -e ""
            return
        fi
        read -e -p "Enter Metro Code: " METRO_CODE
        if [ "$METRO_CODE" = "c" ] ; then
            echo -e ""
            return
        fi
        read -e -p "Enter Local ASN: " LOCAL_ASN
        if [ "$LOCAL_ASN" = "c" ] ; then
            echo -e ""
            return
        fi
        echo -e "\nVRF IP Ranges is a list of IP subnets that will be used for private Metal networks with hosts and BGP sessions across Fabric Virtual Circuits."
        echo -e "All subnets in a VRF IP Ranges list will be announced in BGP sessions as long as there is at least one host added to the VLAN which the subnet belongs to."
        echo -e "IPv4 blocks must be between /8 and /29 in size. IPv6 is not supported."
        echo -e "Example array: [\"10.0.0.0/16\", \"192.168.0.0/24\"]\n"
        read -e -p "Enter an array of IP Ranges: " IP_RANGES
        if [ "$IP_RANGES" = "c" ] ; then
            echo -e ""
            return
        fi
        echo "Creating the VRF..."
        sleep 1
        OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/projects/$PROJECT_UUID/vrfs?include=metro" \
                -X POST \
                -H "Content-Type: application/json" \
                -H "X-Auth-Token: $AUTH_TOKEN" \
                --data '{
                        "name":"'"$VRF_NAME"'",
                        "description":"'"$VRF_DESCRIPTION"'",
                        "metro":"'"$METRO_CODE"'",
                        "local_asn":'"$LOCAL_ASN"',
                        "ip_ranges":'"$IP_RANGES"'
                }')
        sleep 1
        if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                echo $OUTPUT | jq
        else
                echo "Here is the new VRF..."
                echo "$OUTPUT" | jq -r '{ "VRF ID":.id, "Name":.name, "Description":.description, "Metro":.metro | "\(.name) (\(.code))", "Local ASN":.local_asn, "IP Ranges":.ip_ranges}'
                echo "Done..."
        fi
}

update_vrf () {
        echo -e "\nUpdate VRF\n( Type c to cancel )\n"
        read -e -p "Enter VRF UUID: " VRF_UUID
        if [ "$VRF_UUID" = "c" ] ; then
            echo -e ""
            return
        fi

        OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/vrfs/$VRF_UUID" \
                -X GET \
                -H "Content-Type: application/json" \
                -H "X-Auth-Token: $AUTH_TOKEN" )
        sleep 1
        if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                echo $OUTPUT
        else
                echo -e "\nWhat would you like to update?"
                PS3=$'\n''What would you like to update? '
                options=("Name" "Description" "IP Ranges")
                select opt in "${options[@]}"
                do
                    case $opt in
                        "Name")
                                USER_CHOICE=name
                                break
                            ;;
                        "Description")
                                USER_CHOICE=description
                                break
                            ;;
                        "IP Ranges")
                                USER_CHOICE=ip_ranges
                                break
                            ;;
                        *) echo "invalid option $REPLY";;
                    esac
                done
                PS3='Please enter your choice: '

                if [ $USER_CHOICE = "name" ] ; then
                    echo -e "\nCurrent VRF name:"
                    echo $OUTPUT | jq -r .name
                    echo -e ""
                    read -e -p "Enter the new VRF name: " VRF_NAME
                    if [ "$VRF_NAME" = "c" ] ; then
                        echo -e ""
                        return
                    fi
                    JSON_PAYLOAD='{"name":"'"$VRF_NAME"'"}'
                    echo "Updating VRF name..."

                elif [ $USER_CHOICE = "description" ] ; then
                    echo -e "\nCurrent VRF description:"
                    echo $OUTPUT | jq -r .description
                    echo -e ""
                    read -e -p "Enter the new VRF description: " VRF_DESCRIPTION
                    if [ "$VRF_DESCRIPTION" = "c" ] ; then
                        echo -e ""
                        return
                    fi
                    echo $VRF_DESCRIPTION
                    JSON_PAYLOAD='{"description":"'"$VRF_DESCRIPTION"'"}'
                    echo "Updating VRF description..."

                elif [ $USER_CHOICE = "ip_ranges" ] ; then
                    echo -e "\nCurrent array of IP Ranges in the VRF:"
                    echo $OUTPUT | jq -r -c .ip_ranges
                    echo -e "\nNote: If you do not wish to add or remove IP Ranges, include the full existing list of IP Ranges in the update request."
                    echo -e "Specifying a value of [] will remove all existing IP Ranges from the VRF."
                    echo -e "IPv4 blocks must be between /8 and /29 in size. IPv6 is not supported.\n"
                    read -e -p "Enter the new array of IP Ranges: " IP_RANGES
                    if [ "$IP_RANGES" = "c" ] ; then
                        echo -e ""
                        return
                    fi
                    JSON_PAYLOAD='{"ip_ranges":'"$IP_RANGES"'}'
                    echo "Updating VRF IP Ranges..."

                fi

                sleep 1
                OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/vrfs/$VRF_UUID" \
                        -X PATCH \
                        -H "Content-Type: application/json" \
                        -H "X-Auth-Token: $AUTH_TOKEN" \
                        --data "$JSON_PAYLOAD")
                sleep 1
                if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                       echo $OUTPUT | jq
                else
                       echo $OUTPUT | jq
                        echo "Done..."
                fi

        fi

}

delete_vrf () {
        echo -e "\nDelete VRF\n( Type c to cancel )\n"
        read -e -p "Enter VRF UUID: " VRF_UUID
        if [ "$VRF_UUID" = "c" ] ; then
            echo -e ""
            return
        fi
        echo "Deleting the VRF..."
        sleep 1
        OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/vrfs/$VRF_UUID" \
                -X DELETE \
                -H "Content-Type: application/json" \
                -H "X-Auth-Token: $AUTH_TOKEN"
        )
        sleep 1
        if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                echo $OUTPUT | jq
        else
                echo "Done..."
        fi
}

list_ip_reservations () {

        echo -e "\nChoose an option:"
        PS3=$'\n''Choose an option: '
        options=("Show all IP Reservations" "Show IP Reservations in a specific metro" "Show IP Reservations in a specific VRF" "Show specific IP Reservation by UUID")
        select opt in "${options[@]}"
        do
            case $opt in
                "Show all IP Reservations")
                        USER_CHOICE=all_ips
                        break
                    ;;
                "Show IP Reservations in a specific metro")
                        USER_CHOICE=by_metro
                        break
                    ;;
                "Show IP Reservations in a specific VRF")
                        USER_CHOICE=by_vrf
                        break
                    ;;
                "Show specific IP Reservation by UUID")
                        USER_CHOICE=by_uuid
                        break
                    ;;
                *) echo "invalid option $REPLY";;
            esac
        done
        PS3='Please enter your choice: '


        if [ $USER_CHOICE = "all_ips" ] ; then
            echo "Printing all IP Reservations in the project..."
            sleep 1
            OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/projects/$PROJECT_UUID/ips?per_page=250&types=vrf" \
                    -X GET \
                    -H "Content-Type: application/json" \
                    -H "X-Auth-Token: $AUTH_TOKEN")
            sleep 1
            if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                    echo $OUTPUT | jq
            else
                    echo $OUTPUT | jq -r '.ip_addresses[] | { "IP Reservation ID":.id, "Metro":.metro | "\(.name) (\(.code))", "Subnet":"\(.network)/\(.cidr)"}'
                    echo "Done..."
            fi

        elif [ $USER_CHOICE = "by_metro" ] ; then
            read -e -p "Enter metro code: " METRO
            sleep 1
            OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/projects/$PROJECT_UUID/ips?per_page=250&types=vrf&metro=$METRO" \
                    -X GET \
                    -H "Content-Type: application/json" \
                    -H "X-Auth-Token: $AUTH_TOKEN")
            sleep 1
            if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                    echo $OUTPUT | jq
            else
                    echo $OUTPUT | jq -r '.ip_addresses[] | { "IP Reservation ID":.id, "Metro":.metro | "\(.name) (\(.code))", "Subnet":"\(.network)/\(.cidr)"}'
                    echo "Done..."
            fi

        elif [ $USER_CHOICE = "by_vrf" ] ; then
            read -e -p "Enter VRF UUID: " VRF_UUID
            sleep 1
            OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/vrfs/$VRF_UUID/ips?per_page=250&include=metro" \
                    -X GET \
                    -H "Content-Type: application/json" \
                    -H "X-Auth-Token: $AUTH_TOKEN" )
            sleep 1
            if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                    echo $OUTPUT
            else
                    echo $OUTPUT | jq -r '.ip_addresses[] | { "IP Reservation ID":.id, "Metro":.metro | "\(.name) (\(.code))", "Subnet":"\(.network)/\(.cidr)"}'
                    echo "Done..."
            fi

        elif [ $USER_CHOICE = "by_uuid" ] ; then
            read -e -p "Enter VRF UUID: " VRF_UUID
            read -e -p "Enter IP Reservation UUID: " IP_RESERVATION_UUID
            sleep 1
            OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/vrfs/$VRF_UUID/ips/$IP_RESERVATION_UUID?include=metro" \
                    -X GET \
                    -H "Content-Type: application/json" \
                    -H "X-Auth-Token: $AUTH_TOKEN" )
            sleep 1
            if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                    echo $OUTPUT
            else
                    echo $OUTPUT | jq -r '{ "IP Reservation ID":.id, "Metro":.metro | "\(.name) (\(.code))", "Subnet":"\(.network)/\(.cidr)"}'
                    echo "Done..."
            fi

        fi

}

create_ip_reservation () {
        echo -e "\nCreate IP Reservation\n( Type c to cancel )\n"
        read -e -p "Enter Metro Code: " METRO_CODE
        if [ "$METRO_CODE" = "c" ] ; then
            echo -e ""
            return
        fi
        read -e -p "Enter VRF UUID: " VRF_UUID
        if [ "$VRF_UUID" = "c" ] ; then
            echo -e ""
            return
        fi
        read -e -p "Enter Network Address: " IP_NETWORK
        if [ "$IP_NETWORK" = "c" ] ; then
            echo -e ""
            return
        fi
        read -e -p "Enter Network CIDR: " IP_CIDR
        if [ "$IP_CIDR" = "c" ] ; then
            echo -e ""
            return
        fi
        echo "Creating the IP Reservation..."
        sleep 1
        OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/projects/$PROJECT_UUID/ips" \
                -X POST \
                -H "Content-Type: application/json" \
                -H "X-Auth-Token: $AUTH_TOKEN" \
                --data '{
                        "type":"vrf",
                        "metro":"'"$METRO_CODE"'",
                        "vrf_id":"'"$VRF_UUID"'",
                        "network":"'"$IP_NETWORK"'",
                        "cidr":'"$IP_CIDR"'
                }')
        sleep 1
        if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                echo $OUTPUT | jq
        else
                echo "Here is the new IP Reservation..."
                echo "$OUTPUT" | jq -r '{ "IP Reservation ID":.id, "Metro":.metro | "\(.name) (\(.code))", "Subnet":"\(.network)/\(.cidr)"}'
                echo "Done..."
        fi
}

delete_ip_reservation () {
        echo -e "\nDelete IP Reservation\n( Type c to cancel )\n"
        read -e -p "Enter IP Reservation UUID: " IP_UUID
        if [ "$IP_UUID" = "c" ] ; then
            echo -e ""
            return
        fi
        echo "Deleting the IP Reservation..."
        sleep 1
        OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/ips/$IP_UUID" \
                -X DELETE \
                -H "Content-Type: application/json" \
                -H "X-Auth-Token: $AUTH_TOKEN"
        )
        sleep 1
        if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                echo $OUTPUT | jq
        else
                echo "Done..."
        fi
}

list_metal_gateways () {

        echo -e "\nChoose an option:"
        PS3=$'\n''Choose an option: '
        options=("Show all Metal Gateways" "Show Metal Gateways in a specific metro" "Show Metal Gateway of a VLAN" "Show specific Metal Gateway by UUID")
        select opt in "${options[@]}"
        do
            case $opt in
                "Show all Metal Gateways")
                        USER_CHOICE=all_metal_gateways
                        break
                    ;;
                "Show Metal Gateways in a specific metro")
                        USER_CHOICE=by_metro
                        break
                    ;;
                "Show Metal Gateway of a VLAN")
                        USER_CHOICE=by_vlan
                        break
                    ;;
                "Show specific Metal Gateway by UUID")
                        USER_CHOICE=by_uuid
                        break
                    ;;
                *) echo "invalid option $REPLY";;
            esac
        done
        PS3='Please enter your choice: '


        if [ $USER_CHOICE = "all_metal_gateways" ] ; then
            echo "Printing all Metal Gateways in the project..."
            sleep 1
            OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/projects/$PROJECT_UUID/metal-gateways?per_page=250&include=virtual_network,ip_reservation" \
                    -X GET \
                    -H "Content-Type: application/json" \
                    -H "X-Auth-Token: $AUTH_TOKEN")
            sleep 1
            if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                    echo $OUTPUT | jq
            else
                    echo $OUTPUT | jq -r '.metal_gateways[] | { "Metal Gateway ID":.id, "Metro":.virtual_network.metro_code, "VLAN":.virtual_network.vxlan, "Subnet":.ip_reservation | "\(.network)/\(.cidr)", "Gateway IP":.ip_reservation.gateway}'
                    echo "Done..."
            fi

        elif [ $USER_CHOICE = "by_metro" ] ; then
            read -e -p "Enter metro code: " METRO
            sleep 1
            OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/projects/$PROJECT_UUID/metal-gateways?per_page=250&include=virtual_network,ip_reservation" \
                    -X GET \
                    -H "Content-Type: application/json" \
                    -H "X-Auth-Token: $AUTH_TOKEN")
            sleep 1
            if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                    echo $OUTPUT | jq
            else
                    echo $OUTPUT | jq -r '.metal_gateways[] | select(.virtual_network.metro_code == "'"$METRO"'") | { "Metal Gateway ID":.id, "Metro":.virtual_network.metro_code, "VLAN":.virtual_network.vxlan, "Subnet":.ip_reservation | "\(.network)/\(.cidr)", "Gateway IP":.ip_reservation.gateway}'
                    echo "Done..."
            fi

        elif [ $USER_CHOICE = "by_vlan" ] ; then
            read -e -p "Enter VLAN ID: " VLAN_ID
            sleep 1
            OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/projects/$PROJECT_UUID/metal-gateways?include=virtual_network,ip_reservation" \
                    -X GET \
                    -H "Content-Type: application/json" \
                    -H "X-Auth-Token: $AUTH_TOKEN")
            sleep 1
            if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                    echo $OUTPUT | jq
            else
                    echo $OUTPUT | jq -r '.metal_gateways[] | select(.virtual_network.vxlan == '"$VLAN_ID"' ) | { "Metal Gateway ID":.id, "Metro":.virtual_network.metro_code, "VLAN":.virtual_network.vxlan, "Subnet":.ip_reservation | "\(.network)/\(.cidr)", "Gateway IP":.ip_reservation.gateway}'
                    echo "Done..."
            fi

        elif [ $USER_CHOICE = "by_uuid" ] ; then
            read -e -p "Enter Metal Gateway UUID: " METAL_GATEWAY_UUID
            sleep 1
            OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/metal-gateways/$METAL_GATEWAY_UUID?include=virtual_network,ip_reservation" \
                    -X GET \
                    -H "Content-Type: application/json" \
                    -H "X-Auth-Token: $AUTH_TOKEN" )
            sleep 1
            if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                    echo $OUTPUT | jq
            else
                    echo $OUTPUT | jq -r '{ "Metal Gateway ID":.id, "Metro":.virtual_network.metro_code, "VLAN":.virtual_network.vxlan, "Subnet":.ip_reservation | "\(.network)/\(.cidr)", "Gateway IP":.ip_reservation.gateway}'
                    echo "Done..."
            fi

        fi

}

create_metal_gateway () {
        echo -e "\nCreate Metal Gateway\n( Type c to cancel )\n"
        read -e -p "Enter Metro Code: " METRO_CODE
        if [ "$METRO_CODE" = "c" ] ; then
            echo -e ""
            return
        fi
        read -e -p "Enter VLAN ID: " VLAN_NUMBER
        if [ "$VLAN_NUMBER" = "c" ] ; then
            echo -e ""
            return
        fi
        read -e -p "Enter IP Reservation UUID: " IP_UUID
        if [ "$IP_UUID" = "c" ] ; then
            echo -e ""
            return
        fi
        echo "Creating the Metal Gateway..."
        sleep 1
        VLAN_UUID=$(curl -s "https://api.equinix.com/metal/v1/projects/$PROJECT_UUID/virtual-networks?metro=$METRO_CODE" \
                -X GET \
                -H "Content-Type: application/json" \
                -H "X-Auth-Token: $AUTH_TOKEN" \
                | jq -r '.virtual_networks[] | select(.vxlan=='"$VLAN_NUMBER"') | .id')

        OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/projects/$PROJECT_UUID/metal-gateways?include=virtual_network,ip_reservation" \
                -X POST \
                -H "Content-Type: application/json" \
                -H "X-Auth-Token: $AUTH_TOKEN" \
                --data '{
                        "virtual_network_id":"'"$VLAN_UUID"'",
                        "ip_reservation_id":"'"$IP_UUID"'"
                }')
        sleep 1
        if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                echo $OUTPUT | jq
        else
                echo "Here is the new Metal Gateway..."
                echo "$OUTPUT" | jq -r '{ "Metal Gateway ID":.id, "Metro":.virtual_network.metro_code, "VLAN":.virtual_network.vxlan, "Subnet":.ip_reservation | "\(.network)/\(.cidr)", "Gateway IP":.ip_reservation.gateway}'
                echo "Done..."
        fi
}

delete_metal_gateway () {
        echo -e "\nDelete Metal Gateway\n( Type c to cancel )\n"
        read -e -p "Enter Metal Gateway UUID: " GATEWAY_UUID
        if [ "$GATEWAY_UUID" = "c" ] ; then
            echo -e ""
            return
        fi
        echo "Deleting the Metal Gateway..."
        sleep 1
        OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/metal-gateways/$GATEWAY_UUID" \
                -X DELETE \
                -H "Content-Type: application/json" \
                -H "X-Auth-Token: $AUTH_TOKEN")
        sleep 1
        if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                echo $OUTPUT | jq
        else
                echo "Done..."
        fi
}

list_vrf_vcs () {

        echo -e "\nChoose an option:"
        PS3=$'\n''Choose an option: '
        options=("Show all VRF VCs" "Show VRF VCs in a specific metro" "Show VRF VCs in a specific VRF" "Show VRF VCs in a Dedicated Port" "Show specific VRF VC by UUID")
        select opt in "${options[@]}"
        do
            case $opt in
                "Show all VRF VCs")
                        USER_CHOICE=all_vrf_vcs
                        break
                    ;;
                "Show VRF VCs in a specific metro")
                        USER_CHOICE=by_metro
                        break
                    ;;
                "Show VRF VCs in a specific VRF")
                        USER_CHOICE=by_vrf
                        break
                    ;;
                "Show VRF VCs in a Dedicated Port")
                        USER_CHOICE=by_port
                        break
                    ;;
                "Show specific VRF VC by UUID")
                        USER_CHOICE=by_uuid
                        break
                    ;;
                *) echo "invalid option $REPLY";;
            esac
        done
        PS3='Please enter your choice: '


        if [ $USER_CHOICE = "all_vrf_vcs" ] ; then
            echo "Printing all VRF VCs in the project..."
            sleep 1
            OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/projects/$PROJECT_UUID/vrfs?per_page=250&include=metro" \
                    -X GET \
                    -H "Content-Type: application/json" \
                    -H "X-Auth-Token: $AUTH_TOKEN" )
            sleep 1
            if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                    echo $OUTPUT
            else
                    echo $OUTPUT | jq -r '.vrfs[].virtual_circuits[] | {"VC ID":.id, "VC Name":.name, "VC NNI":.nni_vnid, "Peer ASN":.peer_asn, "Peering Subnet":.subnet, "Metal Peer IP":.metal_ip, "Customer Peer IP":.customer_ip, "BGP Password":.md5}'
                    echo "Done..."
            fi

        elif [ $USER_CHOICE = "by_metro" ] ; then
            read -e -p "Enter metro code: " METRO
            sleep 1

            OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/projects/$PROJECT_UUID/vrfs?per_page=250&metro=$METRO&include=metro" \
                    -X GET \
                    -H "Content-Type: application/json" \
                    -H "X-Auth-Token: $AUTH_TOKEN" )
            sleep 1
            if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                    echo $OUTPUT
            else
                    echo $OUTPUT | jq -r '.vrfs[].virtual_circuits[] | {"VC ID": .id, "VC Name":.name, "VC NNI":.nni_vnid, "Peer ASN":.peer_asn, "Peering Subnet":.subnet, "Metal Peer IP":.metal_ip, "Customer Peer IP":.customer_ip, "BGP Password":.md5}'
                    echo "Done..."
            fi

        elif [ $USER_CHOICE = "by_vrf" ] ; then
            read -e -p "Enter VRF UUID: " VRF_UUID
            sleep 1

            OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/vrfs/$VRF_UUID?per_page=250&include=metro" \
                    -X GET \
                    -H "Content-Type: application/json" \
                    -H "X-Auth-Token: $AUTH_TOKEN" )
            sleep 1
            if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                    echo $OUTPUT
            else
                    echo $OUTPUT | jq -r '.virtual_circuits[] | {"VC ID": .id, "VC Name":.name, "VC NNI":.nni_vnid, "Peer ASN":.peer_asn, "Peering Subnet":.subnet, "Metal Peer IP":.metal_ip, "Customer Peer IP":.customer_ip, "BGP Password":.md5}'
                    echo "Done..."
            fi

        elif [ $USER_CHOICE = "by_port" ] ; then
            read -e -p "Enter Connection UUID: " CONNECTION_UUID
            read -e -p "Enter Port UUID: " PORT_UUID
            echo "Printing VRF VCs..."
            sleep 1
            OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/connections/$CONNECTION_UUID/ports/$PORT_UUID/virtual-circuits?per_page=250&include=vrf" \
                    -X GET \
                    -H "Content-Type: application/json" \
                    -H "X-Auth-Token: $AUTH_TOKEN")
            sleep 1
            if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                    echo $OUTPUT | jq
            else
                    echo $OUTPUT | jq -r '.virtual_circuits[] | select(.vrf) | {"VC ID": .id, "VC Name":.name, "VC NNI":.nni_vnid, "Peer ASN":.peer_asn, "Peering Subnet":.subnet, "Metal Peer IP":.metal_ip, "Customer Peer IP":.customer_ip, "BGP Password":.md5}'
                    echo "Done..."
            fi

        elif [ $USER_CHOICE = "by_uuid" ] ; then
            read -e -p "Enter VRF VC UUID: " VRF_VC_UUID
            sleep 1

            OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/virtual-circuits/$VRF_VC_UUID?include=metro" \
                    -X GET \
                    -H "Content-Type: application/json" \
                    -H "X-Auth-Token: $AUTH_TOKEN" )
            sleep 1
            if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                    echo $OUTPUT
            else
                    echo $OUTPUT | jq -r '{"VC ID": .id, "VC Name":.name, "VC NNI":.nni_vnid, "Peer ASN":.peer_asn, "Peering Subnet":.subnet, "Metal Peer IP":.metal_ip, "Customer Peer IP":.customer_ip, "BGP Password":.md5}'
                    echo "Done..."
            fi

        fi

}

create_vrf_vc () {
        echo -e "\nCreate VRF VC - Dedicated Port\n( Type c to cancel )\n"
        read -e -p "Enter Connection UUID: " CONNECTION_UUID
        if [ "$CONNECTION_UUID" = "c" ] ; then
            echo -e ""
            return
        fi
        read -e -p "Enter Port UUID: " PORT_UUID
        if [ "$PORT_UUID" = "c" ] ; then
            echo -e ""
            return
        fi
        read -e -p "Enter VRF UUID: " VRF_UUID
        if [ "$VRF_UUID" = "c" ] ; then
            echo -e ""
            return
        fi
        read -e -p "Enter VC Name: " VC_NAME
        if [ "$VC_NAME" = "c" ] ; then
            echo -e ""
            return
        fi
        read -e -p "Enter VC NNI VLAN ID: " VC_NNI
        if [ "$VC_NNI" = "c" ] ; then
            echo -e ""
            return
        fi
        read -e -p "Enter Peer ASN: " PEER_ASN
        if [ "$PEER_ASN" = "c" ] ; then
            echo -e ""
            return
        fi
        read -e -p "Enter VC Subnet: " VC_SUBNET
        if [ "$VC_SUBNET" = "c" ] ; then
            echo -e ""
            return
        fi
        read -e -p "Enter Metal Peer IP: " METAL_PEER_IP
        if [ "$METAL_PEER_IP" = "c" ] ; then
            echo -e ""
            return
        fi
        read -e -p "Enter Customer Peer IP: " CUSTOMER_PEER_IP
        if [ "$CUSTOMER_PEER_IP" = "c" ] ; then
            echo -e ""
            return
        fi
        echo "Creating the VC..."
        sleep 1
        OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/connections/$CONNECTION_UUID/ports/$PORT_UUID/virtual-circuits?include=vrf" \
                -X POST \
                -H "Content-Type: application/json" \
                -H "X-Auth-Token: $AUTH_TOKEN" \
                --data '{
                        "name":"'"$VC_NAME"'",
                        "project_id":"'"$PROJECT_UUID"'",
                        "vrf_id":"'"$VRF_UUID"'",
                        "nni_vlan":'"$VC_NNI"',
                        "peer_asn":'"$PEER_ASN"',
                        "subnet":"'"$VC_SUBNET"'",
                        "metal_ip":"'"$METAL_PEER_IP"'",
                        "customer_ip":"'"$CUSTOMER_PEER_IP"'"
                }')
        sleep 1
        if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                echo $OUTPUT | jq
        else
                echo "Here is the new VC..."
                echo "$OUTPUT" | jq -r '{"VC ID": .id, "VC Name":.name, "VC NNI":.nni_vnid, "Peer ASN":.peer_asn, "Peering Subnet":.subnet}'
                echo "Done..."
        fi
}

create_vrf_vc_shared () {
        echo -e "\nCreate VRF VC - Shared Port\n( Type c to cancel )\n"
        read -e -p "Enter VRF UUID: " VRF_UUID
        if [ "$VRF_UUID" = "c" ] ; then
            echo -e ""
            return
        fi
        read -e -p "Enter Metro Code: " METRO_CODE
        if [ "$METRO_CODE" = "c" ] ; then
            echo -e ""
            return
        fi

        echo -e "\nChoose VC Type:"
        PS3=$'\n''Choose VC Type: '
        options=("Metal Billed" "Fabric Billed")
        select opt in "${options[@]}"
        do
            case $opt in
                "Metal Billed")
                        VC_TYPE=a_side
                        break
                    ;;
                "Fabric Billed")
                        VC_TYPE=z_side
                        break
                    ;;
                *) echo "invalid option $REPLY";;
            esac
        done
        PS3='Please enter your choice: '

        echo -e "\nChoose VC Redundancy:"
        PS3=$'\n''Choose VC Redundancy: '
        options=("Single" "Redundant")
        select opt in "${options[@]}"
        do
            case $opt in
                "Single")
                        VC_REDUNDANCY=primary
                        break
                    ;;
                "Redundant")
                        VC_REDUNDANCY=redundant
                        break
                    ;;
                *) echo "invalid option $REPLY";;
            esac
        done
        PS3='Please enter your choice: '

        echo -e "\nChoose VC Speed:"
        PS3=$'\n''Choose VC Speed: '
        options=("50mbps" "200mbps" "500mbps" "1gbps" "2gbps" "5gbps" "10gbps")
        select opt in "${options[@]}"
        do
            case $opt in
                "50mbps")
                        VC_SPEED=50mbps
                        break
                    ;;
                "200mbps")
                        VC_SPEED=200mbps
                        break
                    ;;
                "500mbps")
                        VC_SPEED=500mbps
                        break
                    ;;
                "1gbps")
                        VC_SPEED=1gbps
                        break
                    ;;
                "2gbps")
                        VC_SPEED=2gbps
                        break
                    ;;
                "5gbps")
                        VC_SPEED=5gbps
                        break
                    ;;
                "10gbps")
                        VC_SPEED=10gbps
                        break
                    ;;
                *) echo "invalid option $REPLY";;
            esac
        done
        PS3='Please enter your choice: '

        read -e -p "Enter VC Name: " VC_NAME
        if [ "$VC_NAME" = "c" ] ; then
            echo -e ""
            return
        fi

        if [ $VC_REDUNDANCY == "redundant" ]; then
                VRF_UUID=[\"${VRF_UUID}\",\"${VRF_UUID}\"]

                echo -e "\n"
#                read -e -p "Enter Primary VC VLAN ID: " PRIMARY_VC_VLAN
                echo "Subnet size can only be /30 or /31"
                read -e -p "Enter Primary VC Subnet: " PRIMARY_VC_SUBNET
                if [ "$PRIMARY_VC_SUBNET" = "c" ] ; then
                    echo -e ""
                    return
                fi
                read -e -p "Enter Primary VC Metal Peer IP: " PRIMARY_VC_METAL_PEER_IP
                if [ "$PRIMARY_VC_METAL_PEER_IP" = "c" ] ; then
                    echo -e ""
                    return
                fi
                read -e -p "Enter Primary VC Customer Peer IP: " PRIMARY_VC_CUSTOMER_PEER_IP
                if [ "$PRIMARY_VC_CUSTOMER_PEER_IP" = "c" ] ; then
                    echo -e ""
                    return
                fi


                echo -e "\n"
#                read -e -p "Enter Secondary VC VLAN ID: " SECONDARY_VC_VLAN
                echo "Subnet size can only be /30 or /31"
                read -e -p "Enter Secondary VC Subnet: " SECONDARY_VC_SUBNET
                if [ "$SECONDARY_VC_SUBNET" = "c" ] ; then
                    echo -e ""
                    return
                fi
                read -e -p "Enter Secondary VC Metal Peer IP: " SECONDARY_VC_METAL_PEER_IP
                if [ "$SECONDARY_VC_METAL_PEER_IP" = "c" ] ; then
                    echo -e ""
                    return
                fi
                read -e -p "Enter Secondary VC Customer Peer IP: " SECONDARY_VC_CUSTOMER_PEER_IP
                if [ "$SECONDARY_VC_CUSTOMER_PEER_IP" = "c" ] ; then
                    echo -e ""
                    return
                fi
#                VC_VLANS=[${PRIMARY_VC_VLAN},${SECONDARY_VC_VLAN}]
        else
                VRF_UUID=[\"${VRF_UUID}\"]
                echo -e "\n"
#                read -e -p "Enter VC VLAN ID: " VC_VLAN
                echo "Subnet size can only be /30 or /31"
                read -e -p "Enter VC Subnet: " VC_SUBNET
                if [ "$VC_SUBNET" = "c" ] ; then
                    echo -e ""
                    return
                fi
                read -e -p "Enter Metal Peer IP: " METAL_PEER_IP
                if [ "$METAL_PEER_IP" = "c" ] ; then
                    echo -e ""
                    return
                fi
                read -e -p "Enter Customer Peer IP: " CUSTOMER_PEER_IP
                if [ "$CUSTOMER_PEER_IP" = "c" ] ; then
                    echo -e ""
                    return
                fi
        fi
        echo -e "\n"
        read -e -p "Enter Peer ASN: " PEER_ASN
        if [ "$PEER_ASN" = "c" ] ; then
            echo -e ""
            return
        fi
        read -e -p "Enter BGP Password (leave empty if you don't want a password for the BGP session: " BGP_PASSWORD
        if [ "$BGP_PASSWORD" = "c" ] ; then
            echo -e ""
            return
        fi
        echo -e "\nCreating the VC..."
        sleep 1
        OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/projects/$PROJECT_UUID/connections" \
                -X POST \
                -H "Content-Type: application/json" \
                -H "X-Auth-Token: $AUTH_TOKEN" \
                --data '{
                        "type":"'"shared"'",
                        "name":"'"$VC_NAME"'",
                        "metro":"'"$METRO_CODE"'",
                        "service_token_type":"'"$VC_TYPE"'",
                        "redundancy":"'"$VC_REDUNDANCY"'",
                        "speed":"'"$VC_SPEED"'",
                        "vrfs":'"$VRF_UUID"'
                }')
        sleep 1
        if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                echo "You got an API error"
                echo $OUTPUT | jq
        else
                echo "VC created successfully."
#                echo "$OUTPUT" | jq -r '{"VC ID": .id, "VC Name":.name, "VC NNI":.nni_vnid, "Peer ASN":.peer_asn, "Peering Subnet":.subnet}'
                echo "Applying VRF BGP peering settings..."

                if [ $VC_REDUNDANCY == "redundant" ]; then

                        PRIMARY_VC_UUID=$(echo "$OUTPUT" | jq -r .ports[0].virtual_circuits[0].id)
                        SECONDARY_VC_UUID=$(echo "$OUTPUT" | jq -r .ports[1].virtual_circuits[0].id)

                        OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/virtual-circuits/$PRIMARY_VC_UUID?include=vrf.metro" \
                                -X PUT \
                                -H "Content-Type: application/json" \
                                -H "X-Auth-Token: $AUTH_TOKEN" \
                                --data '{
                                        "peer_asn":'"$PEER_ASN"',
                                        "subnet":"'"$PRIMARY_VC_SUBNET"'",
                                        "metal_ip":"'"$PRIMARY_VC_METAL_PEER_IP"'",
                                        "customer_ip":"'"$PRIMARY_VC_CUSTOMER_PEER_IP"'",
                                        "md5":"'"$BGP_PASSWORD"'"
                                }')
                        sleep 1
                        if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                                echo "There was an error while applying VRF BGP peering settings on the primary VC."
                                echo $OUTPUT | jq
                        else
                                echo "Here is the primary VC..."
                                echo "$OUTPUT" | jq -r '{"VC ID": .id, "VC Name":.name, "Metro":.vrf.metro.code, "VC NNI":.nni_vnid, "Peer ASN":.peer_asn, "Peering Subnet":.subnet, "Metal Peer IP":.metal_ip, "Customer Peer IP":.customer_ip, "BGP Password":.md5}'
                        fi

                        OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/virtual-circuits/$SECONDARY_VC_UUID" \
                                -X PUT \
                                -H "Content-Type: application/json" \
                                -H "X-Auth-Token: $AUTH_TOKEN" \
                                --data '{
                                        "peer_asn":'"$PEER_ASN"',
                                        "subnet":"'"$SECONDARY_VC_SUBNET"'",
                                        "metal_ip":"'"$SECONDARY_VC_METAL_PEER_IP"'",
                                        "customer_ip":"'"$SECONDARY_VC_CUSTOMER_PEER_IP"'",
                                        "md5":"'"$BGP_PASSWORD"'"
                                }')
                        sleep 1
                        if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                                echo "There was an error while applying VRF BGP peering settings on the secondary VC."
                                echo $OUTPUT | jq
                        else
                                echo "Here is the secondary VC..."
                                echo "$OUTPUT" | jq -r '{"VC ID": .id, "VC Name":.name, "Metro":.vrf.metro.code, "VC NNI":.nni_vnid, "Peer ASN":.peer_asn, "Peering Subnet":.subnet, "Metal Peer IP":.metal_ip, "Customer Peer IP":.customer_ip, "BGP Password":.md5}'

                        fi

                else
                        VC_UUID=$(echo "$OUTPUT" | jq -r .ports[0].virtual_circuits[0].id)
                        OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/virtual-circuits/$VC_UUID" \
                                -X PUT \
                                -H "Content-Type: application/json" \
                                -H "X-Auth-Token: $AUTH_TOKEN" \
                                --data '{
                                        "peer_asn":'"$PEER_ASN"',
                                        "subnet":"'"$VC_SUBNET"'",
                                        "metal_ip":"'"$METAL_PEER_IP"'",
                                        "customer_ip":"'"$CUSTOMER_PEER_IP"'",
                                        "md5":"'"$BGP_PASSWORD"'"
                                }')
                        sleep 1
                        if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                                echo "There was an error while applying VRF BGP peering settings on the VC."
                                echo $OUTPUT | jq
                        else
                                echo "Here is the new VC..."
                                echo "$OUTPUT" | jq -r '{"VC ID": .id, "VC Name":.name, "Metro":.vrf.metro.code, "VC NNI":.nni_vnid, "Peer ASN":.peer_asn, "Peering Subnet":.subnet, "Metal Peer IP":.metal_ip, "Customer Peer IP":.customer_ip, "BGP Password":.md5}'
                        fi

                fi
        fi
}

update_vrf_vc () {
        echo -e "\nUpdate VRF VC\n( Type c to cancel )\n"
        read -e -p "Enter VC UUID: " VC_UUID
        if [ "$VC_UUID" = "c" ] ; then
            echo -e ""
            return
        fi
        read -e -p "Enter VC Subnet: " VC_SUBNET
        if [ "$VC_SUBNET" = "c" ] ; then
            echo -e ""
            return
        fi
        read -e -p "Enter Metal Peer IP: " METAL_PEER_IP
        if [ "$METAL_PEER_IP" = "c" ] ; then
            echo -e ""
            return
        fi
        read -e -p "Enter Customer Peer IP: " CUSTOMER_PEER_IP
        if [ "$CUSTOMER_PEER_IP" = "c" ] ; then
            echo -e ""
            return
        fi
        read -e -p "Enter Peer ASN: " PEER_ASN
        if [ "$PEER_ASN" = "c" ] ; then
            echo -e ""
            return
        fi
        read -e -p "Enter BGP Password (leave empty if you don't want a password for the BGP session: " BGP_PASSWORD
        if [ "$BGP_PASSWORD" = "c" ] ; then
            echo -e ""
            return
        fi
        echo "Updating the VC..."
        sleep 1
        OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/virtual-circuits/$VC_UUID" \
                -X PUT \
                -H "Content-Type: application/json" \
                -H "X-Auth-Token: $AUTH_TOKEN" \
                --data '{
                        "peer_asn":'"$PEER_ASN"',
                        "subnet":"'"$VC_SUBNET"'",
                        "metal_ip":"'"$METAL_PEER_IP"'",
                        "customer_ip":"'"$CUSTOMER_PEER_IP"'",
                        "md5":"'"$BGP_PASSWORD"'"
                }')
        sleep 1
        if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                echo $OUTPUT | jq
        else
                echo $OUTPUT | jq
#                echo "Here is the new VC..."
#                echo "$OUTPUT" | jq -r '{"VC ID": .id, "VC Name":.name, "VC NNI":.nni_vnid, "Peer ASN":.peer_asn, "Peering Subnet":.subnet}'
#                echo "Done..."
        fi
}

delete_vrf_vc () {
        echo -e "\nDelete VRF VC\n( Type c to cancel )\n"
        read -e -p "Enter VC UUID: " VC_UUID
        if [ "$VC_UUID" = "c" ] ; then
            echo -e ""
            return
        fi
        echo "Deleting the VC..."
        sleep 1
        OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/virtual-circuits/$VC_UUID" \
                -X DELETE \
                -H "Content-Type: application/json" \
                -H "X-Auth-Token: $AUTH_TOKEN")
        sleep 1
        if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                echo $OUTPUT | jq
        else
                echo "Done..."
        fi
}

enable_dynamic_bgp () {
        echo -e "\nEnable Dynamic BGP\n( Type c to cancel )\n"
        read -e -p "Enter VRF UUID: " VRF_UUID
        if [ "$VRF_UUID" = "c" ] ; then
            echo -e ""
            return
        fi
        echo "Enabling Dynamic BGP..."
        sleep 1
        OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/vrfs/$VRF_UUID" \
                -X PATCH \
                -H "Content-Type: application/json" \
                -H "X-Auth-Token: $AUTH_TOKEN" \
                --data '{"bgp_dynamic_neighbors_enabled":true}')
        sleep 1
        if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                echo $OUTPUT | jq
        else
                echo "Done..."
        fi
}

disable_dynamic_bgp () {
        echo -e "\nDisable Dynamic BGP\n( Type c to cancel )\n"
        read -e -p "Enter VRF UUID: " VRF_UUID
        if [ "$VRF_UUID" = "c" ] ; then
            echo -e ""
            return
        fi
        echo "Disabling Dynamic BGP..."
        sleep 1
        OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/vrfs/$VRF_UUID" \
                -X PATCH \
                -H "Content-Type: application/json" \
                -H "X-Auth-Token: $AUTH_TOKEN" \
                --data '{"bgp_dynamic_neighbors_enabled":false}')
        sleep 1
        if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                echo $OUTPUT | jq
        else
                echo "Done..."
        fi
}

enable_export_route_map () {
        echo -e "\nEnable Export Route Map\n( Type c to cancel )\n"
        read -e -p "Enter VRF UUID: " VRF_UUID
        if [ "$VRF_UUID" = "c" ] ; then
            echo -e ""
            return
        fi
        echo "Enabling Export Route Map..."
        sleep 1
        OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/vrfs/$VRF_UUID" \
                -X PATCH \
                -H "Content-Type: application/json" \
                -H "X-Auth-Token: $AUTH_TOKEN" \
                --data '{"bgp_dynamic_neighbors_export_route_map":true}')
        sleep 1
        if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                echo $OUTPUT | jq
        else
                echo "Done..."
        fi
}

disable_export_route_map () {
        echo -e "\nDisable Export Route Map\n( Type c to cancel )\n"
        read -e -p "Enter VRF UUID: " VRF_UUID
        if [ "$VRF_UUID" = "c" ] ; then
            echo -e ""
            return
        fi
        echo "Disabling Export Route Map..."
        sleep 1
        OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/vrfs/$VRF_UUID" \
                -X PATCH \
                -H "Content-Type: application/json" \
                -H "X-Auth-Token: $AUTH_TOKEN" \
                --data '{"bgp_dynamic_neighbors_export_route_map":false}')
        sleep 1
        if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                echo $OUTPUT | jq
        else
                echo "Done..."
        fi
}

enable_bfd () {
        echo -e "\nEnable Bidirectional Forwarding Detection (BFD) for BGP Dynamic Neighbors\n( Type c to cancel )\n"
        read -e -p "Enter VRF UUID: " VRF_UUID
        if [ "$VRF_UUID" = "c" ] ; then
            echo -e ""
            return
        fi
        echo "Enabling Bidirectional Forwarding Detection for BGP Dynamic Neighbors..."
        sleep 1
        OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/vrfs/$VRF_UUID" \
                -X PATCH \
                -H "Content-Type: application/json" \
                -H "X-Auth-Token: $AUTH_TOKEN" \
                --data '{"bgp_dynamic_neighbors_bfd_enabled":true}')
        sleep 1
        if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                echo $OUTPUT | jq
        else
                echo "Done..."
        fi
}

disable_bfd () {
        echo -e "\nDisable Bidirectional Forwarding Detection (BFD) for BGP Dynamic Neighbors\n( Type c to cancel )\n"
        read -e -p "Enter VRF UUID: " VRF_UUID
        if [ "$VRF_UUID" = "c" ] ; then
            echo -e ""
            return
        fi
        echo "Disabling Bidirectional Forwarding Detection for BGP Dynamic Neighbors..."
        sleep 1
        OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/vrfs/$VRF_UUID" \
                -X PATCH \
                -H "Content-Type: application/json" \
                -H "X-Auth-Token: $AUTH_TOKEN" \
                --data '{"bgp_dynamic_neighbors_bfd_enabled":false}')
        sleep 1
        if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                echo $OUTPUT | jq
        else
                echo "Done..."
        fi
}

add_dynamic_neighbor () {
        echo -e "\nAdd BGP Dynamic Neighbor\n( Type c to cancel )\n"
        read -e -p "Enter Gateway UUID: " GATEWAY_UUID
        if [ "$GATEWAY_UUID" = "c" ] ; then
            echo -e ""
            return
        fi
        OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/metal-gateways/$GATEWAY_UUID?include=virtual_network.metal_gateways,ip_reservation" \
                -X GET \
                -H "Content-Type: application/json" \
                -H "X-Auth-Token: $AUTH_TOKEN")
        sleep 1
        if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                echo $OUTPUT | jq
        else
                echo $OUTPUT | jq -r '{"Metro":.virtual_network.metro_code, "VLAN":.virtual_network.vxlan, "Subnet":.ip_reservation | "\(.network)/\(.cidr)", "Gateway IP":.ip_reservation.gateway}'
        fi

        read -e -p "Enter BGP Neighbor Range: " NEIGHBOR_RANGE
        if [ "$NEIGHBOR_RANGE" = "c" ] ; then
            echo -e ""
            return
        fi
        read -e -p "Enter BGP Neighbor ASN: " NEIGHBOR_ASN
        if [ "$NEIGHBOR_ASN" = "c" ] ; then
            echo -e ""
            return
        fi
        echo "Adding BGP Dynamic Neighbor..."
        sleep 1
        OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/metal-gateways/$GATEWAY_UUID/bgp-dynamic-neighbors" \
                -X POST \
                -H "Content-Type: application/json" \
                -H "X-Auth-Token: $AUTH_TOKEN" \
                --data '{
                        "bgp_neighbor_range":"'"$NEIGHBOR_RANGE"'",
                        "bgp_neighbor_asn":'"$NEIGHBOR_ASN"'
                }')
        sleep 1
        if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                echo $OUTPUT | jq
        else
                echo "Here is the new BGP Dynamic Neighbor..."
                echo "$OUTPUT" | jq -r '{ "Dynamic Neighbor ID":.id, "BGP Neighbor ASN":.bgp_neighbor_asn, "BGP Neighbor Range":.bgp_neighbor_range}'
                echo "Metal Gateway BGP peering IPs are 169.254.255.1 and 169.254.255.2. You must set up peering sessions with both IPs for redundancy."
                echo "Done..."
        fi
}

list_dynamic_neighbors () {
        echo -e "\nList BGP Dynamic Neighbors\n( Type c to cancel )\n"
        read -e -p "Enter GATEWAY UUID: " GATEWAY_UUID
        if [ "$GATEWAY_UUID" = "c" ] ; then
            echo -e ""
            return
        fi
        echo "Printing Dynamic Neighbors..."
        sleep 1
        OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/metal-gateways/$GATEWAY_UUID/bgp-dynamic-neighbors?per_page=250" \
                -X GET \
                -H "Content-Type: application/json" \
                -H "X-Auth-Token: $AUTH_TOKEN")
        sleep 1
        if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                echo $OUTPUT | jq
        else
                echo $OUTPUT | jq -r '.bgp_dynamic_neighbors[] | { "Dynamic Neighbor ID":.id, "BGP Neighbor ASN":.bgp_neighbor_asn, "BGP Neighbor Range":.bgp_neighbor_range}'
                echo "Done..."
        fi
}

delete_dynamic_neighbor () {
        echo -e "\nDelete BGP Dynamic Neighbor\n( Type c to cancel )\n"
        read -e -p "Enter Dynamic Neighbor UUID: " DYNAMIC_NEIGHBOR_UUID
        if [ "$DYNAMIC_NEIGHBOR_UUID" = "c" ] ; then
            echo -e ""
            return
        fi
        echo "Deleting the Dynamic BGP Neighbor..."
        sleep 1
        OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/bgp-dynamic-neighbors/$DYNAMIC_NEIGHBOR_UUID" \
                -X DELETE \
                -H "Content-Type: application/json" \
                -H "X-Auth-Token: $AUTH_TOKEN")
        sleep 1
        if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
                echo $OUTPUT | jq
        else
                echo "Done..."
        fi
}

echo -e "\nEquinix Metal VRF CLI v4\n"

env | grep METAL_AUTH_TOKEN > /dev/null
if [ $? -eq 0 ]; then
  echo "Reading Equinix Metal API key from METAL_AUTH_TOKEN environment variable"
  AUTH_TOKEN=$METAL_AUTH_TOKEN
else
  read -e -p "Enter Equinix Metal API Key: " AUTH_TOKEN
fi

OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/user/api-keys" \
        -X GET \
        -H "X-Auth-Token: $AUTH_TOKEN")
sleep 1
if (echo $OUTPUT | jq -e 'has("error")' > /dev/null); then
        echo $OUTPUT | jq
        exit
fi

env | grep METAL_ORGANIZATION_ID > /dev/null
if [ $? -eq 0 ]; then
  echo "Reading Equinix Metal Organization ID from METAL_ORGANIZATION_ID environment variable"
fi

echo -e ""

env | grep METAL_PROJECT_ID > /dev/null
if [ $? -eq 0 ]; then
  echo "Reading Equinix Metal Project ID from METAL_PROJECT_ID environment variable"
  PROJECT_UUID=$METAL_PROJECT_ID
else
  read -e -p "Enter Equinix Metal Project UUID: " PROJECT_UUID
fi

if [ "$PROJECT_UUID" == "" ] ; then
    echo -e "\nInvalid Project ID\n"
    exit
fi

OUTPUT=$(curl -s "https://api.equinix.com/metal/v1/projects/$PROJECT_UUID" \
        -X GET \
        -H "X-Auth-Token: $AUTH_TOKEN")
sleep 1
if (echo $OUTPUT | jq -e 'has("errors")' > /dev/null); then
        echo $OUTPUT | jq
        exit
fi

echo -e ""

PS3='Please enter your choice: '
options=("List VRFs" "Update VRF" "List IP Reservations" "List Metal Gateways" "List VRF VCs" "Create VRF" "Create IP Reservation" "Create Metal Gateway" "Create VRF VC - Shared Port" "Create VRF VC - Dedicated Port" "Update VRF VC" "Delete VRF" "Delete IP Reservation" "Delete Metal Gateway" "Delete VRF VC" "Enable Dynamic BGP" "Disable Dynamic BGP" "Enable Export Route Map" "Disable Export Route Map" "Enable BFD" "Disable BFD" "Add Dynamic Neighbor" "List Dynamic Neighbors" "Delete Dynamic Neighbor" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "List VRFs")
                list_vrfs
            ;;
        "Update VRF")
                update_vrf
            ;;
       "List IP Reservations")
                list_ip_reservations
            ;;
        "List Metal Gateways")
                list_metal_gateways
            ;;
        "List VRF VCs")
                list_vrf_vcs
            ;;
        "Create VRF")
                create_vrf
            ;;
        "Create IP Reservation")
                create_ip_reservation
            ;;
        "Create Metal Gateway")
                create_metal_gateway
            ;;
        "Create VRF VC - Shared Port")
                create_vrf_vc_shared
            ;;
        "Create VRF VC - Dedicated Port")
                create_vrf_vc
            ;;
        "Update VRF VC")
                update_vrf_vc
            ;;
        "Delete VRF")
                delete_vrf
            ;;
        "Delete IP Reservation")
                delete_ip_reservation
            ;;
        "Delete Metal Gateway")
                delete_metal_gateway
            ;;
        "Delete VRF VC")
                delete_vrf_vc
            ;;
        "Enable Dynamic BGP")
                enable_dynamic_bgp
            ;;
        "Disable Dynamic BGP")
                disable_dynamic_bgp
            ;;
        "Enable Export Route Map")
                enable_export_route_map
            ;;
        "Disable Export Route Map")
                disable_export_route_map
            ;;
        "Enable BFD")
                enable_bfd
            ;;
        "Disable BFD")
                disable_bfd
            ;;
        "Add Dynamic Neighbor")
                add_dynamic_neighbor
            ;;
        "List Dynamic Neighbors")
                list_dynamic_neighbors
            ;;
        "Delete Dynamic Neighbor")
                delete_dynamic_neighbor
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
