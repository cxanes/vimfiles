# The rc.tcl Start-up File for Source-Navigator 
#
# http://sourcenav.sourceforge.net/online-docs/progref/custom.html
# http://sourcenav.berlios.de/

proc sn_socket_command {channel} {
    if {[gets ${channel} cmd] == -1} {
        global sn_socket

        unset sn_socket
        catch {close ${channel}}

        sn_log "Client has terminated"

        return
    }
    set cmd [string trim ${cmd}]
    sn_log "Client command:${cmd}"
    # If the "paf_db_f" command does not exist, we have "hidden" the
    # project, so we hace to restore it to open the database files.
    if {[info commands "paf_db_f"] == ""} {
        sn_hide_show_project deiconify
    }

    set ret [eval ${cmd}]

    update idletasks
}

proc sn_socket_accept {channel ip port} {
    global sn_socket sn_options

    set sn_socket ${channel}
    fconfigure ${channel} \
        -encoding $sn_options(def,system-encoding) \
        -blocking 0 \
        -buffering line
    fileevent ${channel} readable "sn_socket_command ${channel}"
}

proc sn_ensure_server_running {} {
    global sn_options
    global sn_socket
    upvar #0 sn_options(def,localhost) host

    if {![info exist sn_socket]} {
        set port [sn_create_access_handler sn_socket_accept socketfd]
        if {${port} == -1} {
            return
        }

        tk_messageBox -message "port: ${port}" -icon info -title "Server"
        vwait sn_socket
        close ${socketfd}
    }
}

proc sn_rc_symbolbrowser {top menu} {
    global tcl_platform

    set tool_frame $top.exp

    set info $top.msg.msg

    set cmdline "sn_ensure_server_running"
    set description Server

    button $tool_frame.server -text $description -command $cmdline -pady 8

    balloon_bind_info $tool_frame.server "Starts $description"
    bind $tool_frame.server <Leave> "set $top.msg {}"
    pack $tool_frame.server -side left
}

