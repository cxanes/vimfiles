# plugin for wikidPad <http://wikidpad.sourceforge.net/>
#
# Edit wiki page in Vim.
#
# Files:
#   autoload/wikidpad.vim
#   syntax/wikidpad.vim

import sys
import os
import os.path
from stat import *

import threading
import subprocess

from SimpleXMLRPCServer import SimpleXMLRPCServer
import xmlrpclib
import time

from pwiki.Configuration import isUnicode, isWin9x
from pwiki.StringOps import *
from .wikidPadParser.WikidPadParser import _TheHelper

import wx

WIKIDPAD_PLUGIN = (("MenuFunctions",1), 
                   ("hooks", 1), 
                   ("Options", 1))

def describeMenuItems(wiki):
    """
    wiki -- Calling PersonalWikiFrame
    Returns a sequence of tuples to describe the menu items, where each must
    contain (in this order):
        - callback function
        - menu item string
        - menu item description (string to show in status bar)
    It can contain the following additional items (in this order), each of
    them can be replaced by None:
        - icon descriptor (see below, if no icon found, it won't show one)
        - menu item id.
        - update function
        - kind of menu item (wx.ITEM_NORMAL, wx.ITEM_CHECK)


    The  callback function  must take 2 parameters:
        wiki - Calling PersonalWikiFrame
        evt - wx.CommandEvent

    If the  menu item string  contains one or more vertical bars '|' these
        are taken as delimiters to describe a "path" of submenus where
        the item should be placed. E.g. the item string
        "Admin|Maintenance|Reset Settings" will create in plugins menu
        a submenu "Admin" containing a submenu "Maintenance" containing
        the item "Reset Settings".

    An  icon descriptor  can be one of the following:
        - a wx.Bitmap object
        - the filename of a bitmap (if file not found, no icon is used)
        - a tuple of filenames, first existing file is used
    """
    return ((StartVim,  "Edit with Vim|Start\tShift-Ctrl-V",  "Start Vim"),
            (StopVim,   "Edit with Vim|Stop\tShift-Ctrl-S",   "Stop Vim"),
            (UpdateVim, "Edit with Vim|Update\tShift-Ctrl-U", "Update Vim"),
           )


SERVER_ADDR = ('localhost', 8000)

WikidPadServer = None
Wiki = None

WikiPageCond = threading.Condition()

Flag_SendToVim = False
Flag_EventHandler = True

def StartVim(wiki, evt):
    global Wiki

    Wiki = wiki
    StartWikidPadServer()

    Vim(Wiki).Start()
    
def StopVim(wiki, evt):
    global Flag_SendToVim
    Flag_SendToVim = False

def UpdateVim(wiki, evt):
    if wiki is not None:
        Vim(wiki).GetCurrentPage()

def bytelenSct_utf8(us):
    """
    us -- unicode string
    returns: Number of bytes us requires in Scintilla (with UTF-8 encoding=Unicode)
    """
    return len(utf8Enc(us)[0])


def bytelenSct_mbcs(us):
    """
    us -- unicode string
    returns: Number of bytes us requires in Scintilla (with mbcs encoding=Ansi)
    """
    return len(mbcsEnc(us)[0])

bytelenSct = bytelenSct_utf8 if isUnicode() else bytelenSct_mbcs


def _UpdateCurrentPage(text):
    global Flag_EventHandler
    Flag_EventHandler = False
    with Wiki.getCurrentDocPage().getTextOperationLock():
        Wiki.getCurrentDocPage().replaceLiveText(text)
    Wiki.saveDocPage(Wiki.getCurrentDocPage())
    Wiki.openWikiPage(Wiki.getCurrentWikiWord(), 
            addToHistory = False,
            forceTreeSyncFromRoot = True, 
            forceReopen = True)
    Flag_EventHandler = True


def _GetCurrentPage():
    config = Wiki.getWikiConfigPath()
    config = '' if config is None else os.path.dirname(config.encode('utf-8'))
    return (xmlrpclib.Binary(Wiki.getCurrentWikiWord().encode('utf-8')),
            xmlrpclib.Binary(Wiki.getActiveEditor().GetText().encode('utf-8')),
            xmlrpclib.Binary(config))


def _OpenWikiPage(word):
    global Flag_EventHandler
    Flag_EventHandler = False
    with WikiPageCond:
        Wiki.openWikiPage(word, motionType = 'child', anchor = None)
        WikiPageCond.notify()
    Flag_EventHandler = True


def _GetCompleteWords(line):
    tofind = ''
    acresultTuples = []

    wikiDocument = Wiki.getWikiDocument()
    closingBracket = Wiki.getConfig().getboolean("main",
            "editor_autoComplete_closingBracket", False)

    text = line
    charPos = len(text)
    lineStartCharPos = 0

    editor = Wiki.getActiveEditor()
    try:
        acresult = editor.wikiLanguageHelper.prepareAutoComplete(editor, text,
                    charPos, lineStartCharPos, wikiDocument,
                    {"closingBracket": closingBracket})

    except:
        self.wiki.displayErrorMessage(GetUni(sys.exc_info()[0]))
        acresult = []

    tofind = 0 if len(acresult) == 0 else acresult[0][2]

    return [tofind, map(lambda v: xmlrpclib.Binary(v[1].encode('utf-8')), acresult)]


class WikiMethod:
    def VimClosed(self):
        global Flag_SendToVim
        Flag_SendToVim = False
        return 0

    def OpenWikiPage(self, word, anchor):
        anchor = unicode(anchor.data, 'utf-8')
        if anchor == u'':
            anchor = None

        with WikiPageCond:
            # GUI operations must be run in the main thread.
            wx.CallAfter(_OpenWikiPage, unicode(word.data, 'utf-8'))
            WikiPageCond.wait()
            return _GetCurrentPage()

    def GetCurrentPage(self):
        return _GetCurrentPage()

    def UpdateCurrentPage(self, text):
        wx.CallAfter(_UpdateCurrentPage, unicode(text.data, 'utf-8'))
        return 0

    def GetCompleteWords(self, line):
        return _GetCompleteWords(unicode(line.data, 'utf-8'))


class WikidPadServerThread(threading.Thread):
    def __init__(self, addr):
        threading.Thread.__init__(self)

        self.server = SimpleXMLRPCServer(addr, logRequests = False)
        self.server.register_introspection_functions()
        self.server.register_multicall_functions()
        self.server.register_instance(WikiMethod())

    def run(self):
        global WikidPadServer
        WikidPadServer = self.server
        self.server.serve_forever()

def StartWikidPadServer():
    global WikidPadServer
    if WikidPadServer is None:
        thread = WikidPadServerThread(SERVER_ADDR)
        thread.setDaemon(True)
        thread.start()
        while True:
            time.sleep(0.05)
            if WikidPadServer is not None:
                break

mswindows = (sys.platform == "win32")

def GetUni(text):
    uni = None
    for enc in ('big5', 'utf-8'):
        try:
            uni = unicode(text, enc,"strict")
        except:
            pass
        else:
            return uni
    return unicode(text, errors='ignore')

class Vim:
    def __init__(self, wiki):
        self.gVimExe = wiki.configuration.get("main", "plugin_gvim_exePath", "")
        self.vimExe = wiki.configuration.get("main", "plugin_vim_exePath", "")

        if self.vimExe == '':
            self.vimExe = self.gVimExe

        self.wiki = wiki
        self.error = False
        self.servername = 'WIKIDPAD'

        if self.gVimExe == "":
            wiki.displayErrorMessage('Please specify the exe path of gVim.')
            self.error = True

    def Start(self):
        if self.error:
            return

        try:
            subprocess.Popen([self.gVimExe, 
                '--servername', self.servername, 
                '-c', ('if wikidpad#StartVim("%s:%d") == 1|q|endif' % SERVER_ADDR)])
            global Flag_SendToVim
            Flag_SendToVim = True
        except OSError, e:
            self.wiki.displayErrorMessage(GetUni(e.strerror))

    def SendCommand(self, command):
        if self.error:
            return

        if Flag_SendToVim and Flag_EventHandler:
            try:
                if mswindows:
                    STARTF_USESHOWWINDOW = 1
                    startupinfo = subprocess.STARTUPINFO()
                    if self.vimExe == self.gVimExe:
                        show_window = 7  # SW_SHOWMINNOACTIVE
                    else:
                        show_window = 0  # SW_HIDE
                    startupinfo.dwFlags = STARTF_USESHOWWINDOW
                    startupinfo.wShowWindow = show_window

                    subprocess.call([self.vimExe, '-u', 'NONE', 
                        '-c', command, '-c', 'q'],
                        startupinfo=startupinfo)
                else:
                    subprocess.call([self.vimExe, '-u', 'NONE', 
                        '-c', command, '-c', 'q'])
            except OSError, e:
                self.wiki.displayErrorMessage(GetUni(e.strerror))

    def GetCurrentPage(self):
        self.SendCommand('call wikidpad#RemoteGetCurrentPage()')

    def ExitWikidPad(self):
        self.SendCommand('call wikidpad#RemoteExitWikidPad()')


# ===============================================
# Following are event handlers for specific events

def openedWikiWord(docPagePresenter, wikiWord):
    """
    Called when a new or existing wiki word was opened successfully.

    wikiWord -- name of the wiki word to create
    """
    if Wiki is not None:
        Vim(Wiki).GetCurrentPage()

def savedWikiWord(wikidPad, wikiWord):
    """
    Called when a wiki word was saved successfully

    wikidPad -- PersonalWikiFrameObject
    wikiWord -- name of the wiki word to create
    """
    if Wiki is not None:
        Vim(Wiki).GetCurrentPage()

def renamedWikiWord(wikidPad, fromWord, toWord):
    """
    Called when a wiki word was renamed successfully.

    The changed data is already saved in the fileset,
    the GUI is not updated yet, the renamed page is not yet loaded.

    wikidPad -- PersonalWikiFrameObject
    fromWord -- name of the wiki word before renaming
    toWord -- name of the wiki word after renaming
    """
    if Wiki is not None:
        Vim(Wiki).GetCurrentPage()

def deletedWikiWord(wikidPad, wikiWord):
    """
    Called when a wiki word was deleted successfully.

    The changed data is already saved in the fileset,
    the GUI is not updated yet, another page (normally
    the last in history before the deleted one) is not yet loaded.

    wikidPad -- PersonalWikiFrameObject
    wikiWord -- name of the deleted wiki word
    """
    if Wiki is not None:
        Vim(Wiki).GetCurrentPage()

def exit(wikidPad):
    """
    Called when the application is about to exit.

    The global and the wiki configuration (if any) are saved already,
    the current wiki page (if any) is saved already.
    """
    if Wiki is not None:
        Vim(Wiki).ExitWikidPad()

# ===============================================

def registerOptions(ver, app):
    """
    API function for "Options" plugins
    Register configuration options and their GUI presentation
    ver -- API version (can only be 1 currently)
    app -- wxApp object
    """
    # Register option
    app.getDefaultGlobalConfigDict()[("main", "plugin_gvim_exePath")] = u""
    app.getDefaultGlobalConfigDict()[("main", "plugin_vim_exePath")] = u""

    # Register panel in options dialog
    app.addOptionsDlgPanel(VimOptionsPanel, u"  Vim")


class VimOptionsPanel(wx.Panel):
    def __init__(self, parent, optionsDlg, app):
        """
        Called when "Options" dialog is opened to show the panel.
        Transfer here all options from the configuration file into the
        text fields, check boxes, ...
        """
        wx.Panel.__init__(self, parent)
        self.app = app

        pt = self.app.getGlobalConfig().get("main", "plugin_gvim_exePath", "")
        self.gVimExePath = wx.TextCtrl(self, -1, pt, size = (250, -1))

        pt = self.app.getGlobalConfig().get("main", "plugin_vim_exePath", "")
        self.vimExePath = wx.TextCtrl(self, -1, pt, size = (250, -1))

        mainsizer = wx.FlexGridSizer(2, 2, 0, 0)

        mainsizer.Add(wx.StaticText(self, -1, "Path to gVim:"), 0,
                wx.ALL | wx.EXPAND, 5)
        mainsizer.Add(self.gVimExePath, 1, wx.ALL | wx.EXPAND, 5)

        mainsizer.Add(wx.StaticText(self, -1, "Path to Vim:"), 0,
                wx.ALL | wx.EXPAND, 5)
        mainsizer.Add(self.vimExePath, 1, wx.ALL | wx.EXPAND, 5)

        self.SetSizer(mainsizer)
        self.Fit()

    def setVisible(self, vis):
        """
        Called when panel is shown or hidden. The actual wxWindow.Show()
        function is called automatically.

        If a panel is visible and becomes invisible because another panel is
        selected, the plugin can veto by returning False.
        When becoming visible, the return value is ignored.
        """
        return True

    def checkOk(self):
        """
        Called when "OK" is pressed in dialog. The plugin should check here if
        all input values are valid. If not, it should return False, then the
        Options dialog automatically shows this panel.

        There should be a visual indication about what is wrong (e.g. red
        background in text field). Be sure to reset the visual indication
        if field is valid again.
        """
        return True

    def handleOk(self):
        """
        This is called if checkOk() returned True for all panels. Transfer here
        all values from text fields, checkboxes, ... into the configuration
        file.
        """
        pt = self.gVimExePath.GetValue()
        self.app.getGlobalConfig().set("main", "plugin_gvim_exePath", pt)

        pt = self.vimExePath.GetValue()
        self.app.getGlobalConfig().set("main", "plugin_vim_exePath", pt)


