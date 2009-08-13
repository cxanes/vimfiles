#!python

# SyncTeX supported
# PDF Viewer (Windows version): Sumatra PDF
#
# Reference: https://seattle.cs.washington.edu/browser/seattle/trunk/dist/win/python/Lib/site-packages/win32/Demos/dde/ddeclient.py?rev=73

try:
    import win32ui
    import dde
except ImportError:
    raise RuntimeError('Cannot find module win32ui/dde')

class SumatraPDF:
    # forward-search command
    #  format: [ForwardSearch("<pdffilepath>","<sourcefilepath>",<line>,<column>[,<newwindow>, <setfocus>])]
    #    if newwindow = 1 then a new window is created even if the file is already open
    #    if focus = 1 then the focus is set to the window
    #  eg: [ForwardSearch("c:\file.pdf","c:\folder\source.tex",298,0)]
    @staticmethod
    def ForwardSearch(pdffilepath, sourcefilepath , line, column, newwindow = 0, setfocus = 0):
        SumatraPDF._Exec('[ForwardSearch("%s","%s",%d,%d,%d,%d)]' % (
            pdffilepath.replace('"', '\\"'),
            sourcefilepath.replace('"', '\\"'), 
            int(line), int(column), int(newwindow), int(setfocus)))

    # open file command
    #  format: [Open("<pdffilepath>"[,<newwindow>,<setfocus>,<forcerefresh>])]
    #    if newwindow = 1 then a new window is created even if the file is already open
    #    if focus = 1 then the focus is set to the window
    #  eg: [Open("c:\file.pdf", 1, 1)]
    @staticmethod
    def Open(pdffilepath, newwindow = 0, setfocus = 0, forcerefresh = 0):
        SumatraPDF._Exec('[Open("%s",%d,%d,%d)]' % (
            pdffilepath.replace('"', '\\"'),
            int(newwindow), int(setfocus), int(forcerefresh)))

    # jump to named destination command
    #  format: [GoToNamedDest("<pdffilepath>","<destination name>")]
    #  eg: [GoToNamedDest("c:\file.pdf", "chapter.1")]. pdf file must be already opened
    @staticmethod
    def GoToNamedDest(pdffilepath, destination_name):
        SumatraPDF._Exec('[Open("%s","%s")]' % (
            pdffilepath.replace('"', '\\"'),
            destination_name.replace('"', '\\"')))

    # jump to page command
    #  format: [GoToPage("<pdffilepath>",<page number>)]
    #  eg: [GoToPage("c:\file.pdf", 37)]. pdf file must be already opened
    @staticmethod
    def GoToPage(pdffilepath, page_number):
        SumatraPDF._Exec('[Open("%s",%d)]' % (
            pdffilepath.replace('"', '\\"'),
            int(page_number)))

    @staticmethod
    def _Exec(command):
        client = dde.CreateServer()
        client.Create("SumatraPDFClient")
        c = dde.CreateConversation(client)
        c.ConnectTo("SUMATRA", "control")

        if c.Connected() == 1:
            c.Exec(command)
            client.Shutdown()
        else:
            client.Shutdown()
            raise RuntimeError('Cannot find SumatraPDF')


if __name__ == '__main__':
    import sys
    argv = list(sys.argv)
    del argv[0]
    if len(argv) < 1:
        sys.exit(0)

    commond = argv.pop(0)
    if   commond == 'ForwardSearch':
        SumatraPDF.ForwardSearch(*argv);
    elif commond == 'Open':
        SumatraPDF.Open(*argv);
    elif commond == 'GoToNamedDest':
        SumatraPDF.GoToNamedDest(*argv);
    elif commond == 'GoToPage':
        SumatraPDF.GoToPage(*argv);

