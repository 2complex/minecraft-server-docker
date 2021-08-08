#!/bin/bash

#config_dir="$(pwd)"

title="$(echo -e "Minecraft \u2661 Docker")"
: ${config_dir="$HOME/.mc"}
: ${active_names="$config_dir/active-names"}
: ${all_names="$config_dir/all-names"}
: ${mc_history="$config_dir/history.log"}
: ${mc_images="$config_dir/images"}
: ${mc_image_ref="$config_dir/image-ref"}
: ${mc_motd_ref="$config_dir/motd-ref"}
: ${mc_docker_compose="$config_dir/docker-compose.yml"}
: ${mc_data="$config_dir/data"}
: ${mc_data_standalone="$config_dir/data-standalone"}
: ${build_docker=1}

directory="$(dirname "$0")"
echo "$directory" | grep -P "^\." > /dev/null && \
    directory="$(pwd)/${directory}"

: ${path_mk_docker="$directory/../mk-mc-base.sh"}
: ${path_valid="$directory/valid.sh"}

[ ! -d "$mc_image_ref" ] && mkdir -p "$mc_image_ref"
[ ! -d "$mc_motd_ref" ] && mkdir -p "$mc_motd_ref"
[ ! -d "$mc_data" ] && mkdir -p "$mc_data"
[ ! -d "$mc_data_standalone" ] && mkdir -p "$mc_data_standalone"

show_msg () {
    dialog \
        --backtitle "$title" \
        --title "$1" \
        --clear \
        --msgbox "$2" 0 0 \
        || return 1
}

show_info () {
    dialog \
        --backtitle "$title" \
        --title "$1" \
        --infobox "$2" 0 0
}

insert_mc_name () {
    while true; do

        exec 3>&1
        mc_name=$(dialog \
            --backtitle "$title" \
            --title "Insert Server Name" \
            --clear \
            --inputbox "Only letters from a to z and numbers are allowed" 0 0 \
            2>&1 1>&3 \
        )
        exit_status=$?
        exec 3>&-

        case $exit_status in
            1)
                return 1
                ;;
            255)
                clear
                echo "Program aborted." >&2
                exit
                ;;
        esac

        if [[ "$(echo "$mc_name" | grep -Px "[a-zA-Z0-9]+")" = "" ]]; then
            show_msg "Invalid name" \
                "Only letters from a to z and numbers are allowed" \
                || return 1
            continue
        fi

        [[ ! -f "$all_names" ]] && touch "$all_names"

        if grep -x "$mc_name" "$all_names"; then
            show_msg "Used name" \
                "This name is already used. Use a different one" \
                || return 1
            continue
        fi

        break

    done
}

insert_mc_motd () {
    while true; do

        exec 3>&1
        mc_motd=$(dialog \
            --backtitle "$title" \
            --title "Insert Motd for the server ${mc_name}" \
            --clear \
            --inputbox "For the motd are any printable letters allowed" 0 0 \
            2>&1 1>&3 \
        )
        exit_status=$?
        exec 3>&-

        case $exit_status in
            1)
                return 1
                ;;
            255)
                clear
                echo "Program aborted." >&2
                exit
                ;;
        esac

        break

    done
}

supported_mc_kinds () {
    for file in $(ls "$(dirname "$path_mk_docker")"); do
        extension=`sed 's/^\w\+.//' <<< "$file"`

        if [[ "Dockerfile.${extension}" = "${file}" ]]; then
            echo $extension 
        fi
    done
}

insert_mc_version () {
    while true; do

        exec 3>&1
        mc_kind=$(dialog \
            --backtitle "$title" \
            --title "Select Server Kind" \
            --clear \
            --no-items \
            --menu "Please select:" 0 0 1 \
            $(supported_mc_kinds | tr '\n' ' ') \
            2>&1 1>&3 \
        )
        exit_status=$?
        exec 3>&-

        case $exit_status in
            1)
                return 1
                ;;
            255)
                clear
                echo $mc_kind
                echo "Program aborted." >&2
                exit
                ;;
        esac

        exec 3>&1
        mc_version=$(dialog \
            --backtitle "$title" \
            --title "Insert version for $mc_kind server $mc_name" \
            --clear \
            --inputbox "The version like 1.16.0 or 1.16.4-alpha" 0 0 \
            2>&1 1>&3 \
        )
        exit_status = $?
        exec 3>&-

        case $exit_status in
            1)
                return 1
                ;;
            255)
                clear
                echo "Program aborted." >&2
                exit
                ;;
        esac

        show_info "Checking ..." "Check online if the version is available."

        "$path_valid" "$mc_kind" "$mc_version"

        case $? in
            1)
                show_msg "Invalid version" \
                    "The selected version $mc_version is not available to download for $mc_kind server." \
                    || return 1
                continue
                ;;
        esac

        break
    done
}

insert_mc_java_version () {
    exec 3>&1
    mc_java_version=$(dialog \
        --backtitle "$title" \
        --title "Select Java Version" \
        --clear \
        --no-items \
        --menu "Please select:" 0 0 10 \
        openjdk-8-jre \
        openjdk-16-jre \
        2>&1 1>&3 \
    )
    exit_status=$?
    exec 3>&-

    case $exit_status in
        1)
            return 1
            ;;
        255)
            clear
            echo $mc_kind
            echo "Program aborted." >&2
            exit
            ;;
    esac
}

build_docker_compose () {
    show_info "Rebuild docker compose" \
        "Rebuilding docker compose file. Please wait a moment."
    
    echo "# This file is automaticly generated. DO NOT CHANGE THIS MANUALLY!" > $mc_docker_compose
    echo "# Use util.sh to update and edit this file." >> $mc_docker_compose
    echo "version: \"3.9\"" >> $mc_docker_compose
    echo "services:" >> $mc_docker_compose

    # add game server
    for name in $(cat $active_names); do
        # check if data dir exists
        mkdir -p "$mc_data/$name"
        # add test start script
        echo "#!/bin/bash" > "$mc_data/$name/start.sh"
        echo "sh -c \"screen -dmS ${name} java -Xmx4096M -jar server.jar\"" >> "$mc_data/$name/start.sh"
        # add entry
        echo "  mc-${name}:" >> $mc_docker_compose
        echo "    image: $(cat "${mc_image_ref}/${name}")" >> $mc_docker_compose
        echo "    container_name: mc-${name}" >> $mc_docker_compose
        echo "    restart: unless-stopped" >> $mc_docker_compose
        echo "    volumes:" >> $mc_docker_compose
        echo "      - ${mc_data}/${name}:/data" >> $mc_docker_compose
        echo "    environment:" >> $mc_docker_compose
        echo "      - bungeecord=true" >> $mc_docker_compose
        echo "      - motd=$(cat "${mc_motd_ref}/${name}")" >> $mc_docker_compose
    done

    # check if bungee data dir exists
    mkdir -p "$mc_data/$bungee"
    # add bungeecord proxy
    echo "  bungeecord:" >> $mc_docker_compose
    echo "    image: itzg/docker-bungeecord" >> $mc_docker_compose
    echo "    container_name: bungeecord" >> $mc_docker_compose
    echo "    restart: unless-stopped" >> $mc_docker_compose
    echo "    volumes:" >> $mc_docker_compose
    echo "      - ${mc_data}/bungee/:/server" >> $mc_docker_compose
    echo "    ports:" >> $mc_docker_compose
    echo "      - 25565:25565" >> $mc_docker_compose
}

exec_add_mc () {    

    insert_mc_name || return 1
    insert_mc_motd || return 1
    insert_mc_version || return 1
    insert_mc_java_version || return 1

    [[ ! -f "$mc_images" ]] && touch "$mc_images"
    if grep -x "${mc_kind} ${mc_version}" "${mc_images}"; then
        :
    else
        if [[ "$build_docker" = "1" ]]; then
            show_info "Add Server" "Create docker image..."

            clear
            pushd "$(dirname "$path_mk_docker")"
            "./$(basename "$path_mk_docker")" "$mc_kind" "$mc_version" "$mc_java_version" \
                || exit 1
            popd

            echo "${mc_kind} ${mc_version}" >> "${mc_images}"
        fi
    fi

    show_info "Add Server" "Register server to local database"

    # echo "$mc_name" >> "$active_names"
    echo "$mc_name" >> "$all_names"
    echo "$(date -Is) $(whoami) ${mc_name} ${mc_kind} ${mc_version}" >> "$mc_history"
    echo "2complex/mc-${mc_kind}:${mc_version}" > "${mc_image_ref}/${mc_name}"
    echo "$mc_motd" > "${mc_motd_ref}/${mc_name}"

    build_docker_compose

    show_msg "$mc_name added" \
        "The $mc_kind ($mc_version) server is successfuly added." \
        || return 1
}

exec_add_standalone () {

    insert_mc_name || return 1
    insert_mc_motd || return 1
    insert_mc_java_version || return 1

    show_msg "Warning!" "$( \
        echo "You are required to add a server.jar in the target directory!"; \
        echo "There is no server.jar right now!" \
    )"

    mc_kind="custom"
    mc_version="$mc_java_version"

    [[ ! -f "$mc_images" ]] && touch "$mc_images"
    if grep -x "${mc_kind} ${mc_version}" "${mc_images}"; then
        :
    else
        if [[ "$build_docker" = "1" ]]; then
            show_info "Add Server" "Create docker image..."

            clear
            pushd "$(dirname "$path_mk_docker")"
            "./$(basename "$path_mk_docker")" "$mc_kind" "$mc_version" "$mc_java_version" \
                || exit 1
            popd

            echo "${mc_kind} ${mc_version}" >> "${mc_images}"
        fi
    fi

    show_info "Add Server" "Register server to local database"

    echo "$mc_name" >> "$all_names"
    echo "$(date -Is) $(whoami) ${mc_name} ${mc_kind} ${mc_version}" >> "$mc_history"
    echo "2complex/mc-${mc_kind}:${mc_version}" > "${mc_image_ref}/${mc_name}"
    echo "$mc_motd" > "${mc_motd_ref}/${mc_name}"

    mkdir -p "$mc_data_standalone/$mc_name"
    echo "#!/bin/bash" > "$mc_data_standalone/$mc_name/start.sh"
    echo "sh -c \"screen -dmS ${name} java -Xmx4096M -jar server.jar\"" >> "$mc_data_standalone/$mc_name/start.sh"

    compose="$mc_data_standalone/$mc_name/docker-compose.yml"
    echo "# This file is automaticly generated. DO NOT CHANGE THIS MANUALLY!" > $compose
    echo "# Use util.sh to update and edit this file." >> $compose
    echo "version: \"3.9\"" >> $compose
    echo "services:" >> $compose
    echo "  mc-${mc_name}:" >> $compose
    echo "    image: $(cat "${mc_image_ref}/${mc_name}")" >> $compose
    echo "    container_name: mc-${mc_name}" >> $compose
    echo "    restart: unless-stopped" >> $compose
    echo "    volumes:" >> $compose
    echo "      - ${mc_data_standalone}/${mc_name}:/data" >> $compose
    echo "      - ${mc_data_standalone}/${mc_name}/server.jar:/home/minecraft/server.jar" >> $compose
    echo "    environment:" >> $compose
    echo "      - bungeecord=false" >> $compose
    echo "      - motd=$(cat "${mc_motd_ref}/${mc_name}")" >> $compose
    echo "    ports:" >> $compose
    echo "      - 23000:25565" >> $compose

    show_msg "$mc_name added" \
        "The $mc_kind ($mc_version) server is successfuly added." \
        || return 1

}

exec_change_active () {
    local options=""
    for entry in $(cat "$all_names"); do
        options="${options} \"${entry}\" \"${entry}\" $(grep -x "$entry" "$active_names" > /dev/null &&\
            echo "on" || echo "off")"
    done

    echo "$options"

    exec 3>&1
    local new_list=$(dialog \
        --backtitle "$title" \
        --title "Change active Server" \
        --clear \
        --visit-items \
        --separate-output \
        --buildlist "Move active server with the spacebar to the right." 0 0 10 \
        $options \
        2>&1 1>&3 \
        | sed 's/"//g' \
    )
    exit_status=$?
    exec 3>&-

    case $exit_status in
        1)
            return 1
            ;;
        255)
            clear
            echo "Program aborted." >&2
            exit
            ;;
    esac

    echo "$new_list" > $active_names

    build_docker_compose
}

exec_change_motd () {
    exec 3>&1
    mc_name=$(dialog \
        --backtitle "$title" \
        --title "Menu" \
        --clear \
        --no-items \
        --menu "Select server to change Motd:" 0 0 1 \
        $(cat "${all_names}" | tr '\n' ' ') \
        2>&1 1>&3 \
    )
    exit_status=$?
    exec 3>&-

    case $exit_status in
        1)
            return 1
            ;;
        255)
            clear
            echo $mc_kind
            echo "Program aborted." >&2
            exit
            ;;
    esac

    unset mc_motd
    insert_mc_motd || return 1

    if [[ ! -z "${mc_motd}" ]]; then
        echo "$mc_motd" > "${mc_motd_ref}/${mc_name}"
        show_msg "Motd changed" \
            "The Motd is successfuly changed for the server ${mc_name}" \
            || return 1
    fi
}

# Main exec loop

while true; do
    exec 3>&1
    selection=$(dialog \
        --backtitle "$title" \
        --title "Menu" \
        --clear \
        --cancel-label "Exit" \
        --no-tags \
        --menu "Please select:" 0 0 4 \
        "1" "Add new server" \
        "3" "Change active server" \
        "4" "Change Motd of one server" \
        "2" "Rebuild docker-compose.yml" \
        "5" "Add custom server" \
        2>&1 1>&3 \
    )
    exit_status=$?
    exec 3>&-

    case $exit_status in
        1)
            clear
            exit
            ;;
        255)
            clear
            echo "Program aborted." >&2
            exit
            ;;
    esac

    case $selection in
        0)
            clear
            exit
            ;;
        1)
            exec_add_mc
            ;;
        2)
            build_docker_compose
            ;;
        3)
            exec_change_active
            ;;
        4)
            exec_change_motd
            ;;
        5)
            exec_add_standalone
            ;;
    esac
done
