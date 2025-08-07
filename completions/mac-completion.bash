#!/bin/bash

# Mac Power Tools bash completion

_mac_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Main commands
    local commands="help version update info maintenance clean trash cache downloads duplicates large-files large-dirs logs dns spotlight hidden permissions memory privacy security awake sleep restart shutdown kill-apps sort-downloads watch-downloads downloads-status backup uninstall migrate-mas"

    case "${prev}" in
        mac)
            COMPREPLY=($(compgen -W "${commands}" -- ${cur}))
            return 0
            ;;
        update)
            local targets="macos brew mas npm ruby pip"
            COMPREPLY=($(compgen -W "${targets}" -- ${cur}))
            return 0
            ;;
        info)
            local types="system memory disk network battery temp cpu"
            COMPREPLY=($(compgen -W "${types}" -- ${cur}))
            return 0
            ;;
        downloads)
            local dl_commands="sort sort-file setup status watch analyze clean disable help"
            COMPREPLY=($(compgen -W "${dl_commands}" -- ${cur}))
            return 0
            ;;
        privacy)
            case "${COMP_WORDS[COMP_CWORD-2]}" in
                clean)
                    local targets="safari chrome firefox system all"
                    COMPREPLY=($(compgen -W "${targets}" -- ${cur}))
                    ;;
                *)
                    local privacy_commands="clean audit scan permissions protect help"
                    COMPREPLY=($(compgen -W "${privacy_commands}" -- ${cur}))
                    ;;
            esac
            return 0
            ;;
        security)
            local security_commands="audit scan protect"
            COMPREPLY=($(compgen -W "${security_commands}" -- ${cur}))
            return 0
            ;;
        awake)
            local awake_opts="--screensaver --status --stop -t --time -w --wait-for --help"
            COMPREPLY=($(compgen -W "${awake_opts}" -- ${cur}))
            return 0
            ;;
        memory)
            local memory_opts="--optimize --status --help"
            COMPREPLY=($(compgen -W "${memory_opts}" -- ${cur}))
            return 0
            ;;
        clean)
            local clean_opts="--analyze --dry-run --help"
            COMPREPLY=($(compgen -W "${clean_opts}" -- ${cur}))
            return 0
            ;;
        uninstall)
            if [[ ${cur} == -* ]]; then
                local uninstall_opts="--list --dry-run --help"
                COMPREPLY=($(compgen -W "${uninstall_opts}" -- ${cur}))
            else
                # Complete application names
                local apps=$(find /Applications -name "*.app" -maxdepth 1 -exec basename {} .app \; 2>/dev/null)
                COMPREPLY=($(compgen -W "${apps}" -- ${cur}))
            fi
            return 0
            ;;
        duplicates)
            # Complete directory names
            COMPREPLY=($(compgen -d -- ${cur}))
            return 0
            ;;
    esac

    # Global options
    if [[ ${cur} == -* ]]; then
        local global_opts="-h --help -v --version"
        COMPREPLY=($(compgen -W "${global_opts}" -- ${cur}))
        return 0
    fi
}

# Register the completion function
complete -F _mac_completion mac