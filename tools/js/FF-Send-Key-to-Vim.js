/* Send key to Vim in Firefox
 *
 * Vim requires +clientserver feature.
 *
 * http://developer.mozilla.org/en/docs/Code_snippets:Running_applications
 */

/* Determine the OS name
 *
 * Return:
 *
 *     "Windows"    for all versions of Windows
 *     "MacOS"      for all versions of Macintosh OS
 *     "Linux"      for all versions of Linux
 *     "UNIX"       for all other UNIX flavors 
 *     "Unknown OS" indicates failure to detect the OS
 *
 * http://www.javascripter.net/faq/operatin.htm
 */
function OSName() {
    if (navigator.appVersion.indexOf("Win")  != -1) return "Windows";
    if (navigator.appVersion.indexOf("Mac")  != -1) return "MacOS";
    if (navigator.appVersion.indexOf("X11")  != -1) return "UNIX";
    if (navigator.appVersion.indexOf("Linux")!= -1) return "Linux";
    return "Unknown OS";
}

function vimSendKey(servername, key) {
    // Since we don't install this script, we need some privilege to run
    // this functions
    netscape.security.PrivilegeManager.enablePrivilege("UniversalXPConnect"); 

    // Create an nsILocalFile for the executable
    var file = Components.classes["@mozilla.org/file/local;1"]
                    .createInstance(Components.interfaces.nsILocalFile);

    // The fullpath of GVIM executable
    var osName = OSName();
    var gvim = osName == "Windows"
                ? "C:\\Program Files\\Vim\\vim72\\gvim.exe"
                : "/usr/bin/gvim";

    file.initWithPath(gvim);

    // Create an nsIProcess
    var process = Components.classes["@mozilla.org/process/util;1"]
                    .createInstance(Components.interfaces.nsIProcess);
    process.init(file);

    // Run the process.
    // If first param is true, calling thread will be blocked until
    // called process terminates.
    // Second and third params are used to pass command-line arguments
    // to the process.
    var args = ["--servername", servername, "--remote-send", key];
    process.run(false, args, args.length);
}

function vimSendText(servername, text) {
    vimSendKey(servername, "<C-\\><C-N>a" + text);
}
