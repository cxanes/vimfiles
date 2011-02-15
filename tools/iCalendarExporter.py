import os, urllib, os.path
import subprocess

import wx
import re
import datetime
import uuid

import icalendar
try:
    from .WikiVim import SERVER_ADDR
except ImportError:
    SERVER_ADDR = None

WIKIDPAD_PLUGIN = (("MenuFunctions", 1), ("Options", 1))

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
    return ((exportICal, "Export iCal\tShift-Ctrl-E", "Export iCal"),)

def _getPriority(priority_string):
    try:
        return int(priority_string)
    except:
        return None

def _getDataTime(date_string):
    try:
        date = datetime.datetime.strptime(date_string, '%Y/%m/%dT%H:%M')
    except:
        try:
            date = datetime.datetime.strptime(date_string, '%Y/%m/%d')
        except:
            date = None

    return date

def _parseTodo(todo):
    pattern_todo_keyword = re.compile(r'^todo(?:\.\w+)*:\s*')
    pattern_setting = re.compile(r'(?:^|(?<=\s))([!#@]\w+)(?:$|\s+)')
    pattern_date1 = re.compile(r'(?:^|(?<=\s))(\d+/\d+/\d+(?:T\d+:\d+)?)(?:-(\d+/\d+/\d+(?:T\d+:\d+)?))?(?:$|\s+)')
    pattern_date2 = re.compile(r'(?:^|(?<=\s))(?:-(\d+/\d+/\d+(?:T\d+:\d+)?))(?:$|\s+)')
    if not pattern_todo_keyword.search(todo):
        return {}
    todo = pattern_todo_keyword.sub('', todo)

    item = {}
    for setting in pattern_setting.findall(todo):
        key = setting[0]
        value = setting[1:]
        if key == '!':
            item['priority'] = _getPriority(value)
        elif key == '#':
            if 'categories' not in item:
                item['categories'] = [ value ]
            else:
                item['categories'].append(value)
        elif key == '@':
            item['location'] = value

    todo = pattern_setting.sub('', todo)
    for date in pattern_date1.findall(todo):
        item['dtstart'] = _getDataTime(date[0])
        item['due'] = _getDataTime(date[1])

    todo = pattern_date1.sub('', todo)

    for date in pattern_date2.findall(todo):
        item['due'] = _getDataTime(date)

    todo = pattern_date2.sub('', todo)

    item['summary'] = todo

    return item

def exportICal(wiki, evt):
    export_dir = wiki.configuration.get("main", "plugin_ical_export_dir", "")
    if export_dir == '':
        config = wiki.getWikiConfigPath()
        if config is None:
            wiki.displayErrorMessage('Please specify the export dir.')
            return
        export_dir = os.path.dirname(config.encode('utf-8'))

    cal = icalendar.Calendar()
    cal.add('prodid', '-//WikidPad Todo List//EN')
    cal.add('version', '2.0')
    for (wikiWord, todo) in wiki.getWikiData().getTodos():
        item = _parseTodo(todo)
        if len(item) == 0:
            continue
        ical_todo = icalendar.Todo()
        ical_todo.add('uid', uuid.uuid4())
        for (key, value) in item.iteritems():
            if value is not None:
                ical_todo.add(key, value)

        if SERVER_ADDR is not None:
            ical_todo.add('url', ('http://%s:%d/' % SERVER_ADDR) + wikiWord)

        cal.add_component(ical_todo)

    export_file = os.path.join(export_dir, wiki.getWikiDocument().getWikiName() + '.ics')
    f = open(export_file, 'wb')
    f.write(cal.as_string())
    f.close()

    wiki.statusBar.SetStatusText('export ical to %s' % (export_file), 0)

def registerOptions(ver, app):
    """
    API function for "Options" plugins
    Register configuration options and their GUI presentation
    ver -- API version (can only be 1 currently)
    app -- wxApp object
    """
    # Register option
    app.getDefaultGlobalConfigDict()[("main", "plugin_ical_export_dir")] = u""
    # Register panel in options dialog
    app.addOptionsDlgPanel(ICalExporterOptionsPanel, u"  iCal Exporter")


class ICalExporterOptionsPanel(wx.Panel):
    def __init__(self, parent, optionsDlg, app):
        """
        Called when "Options" dialog is opened to show the panel.
        Transfer here all options from the configuration file into the
        text fields, check boxes, ...
        """
        wx.Panel.__init__(self, parent)
        self.app = app

        pt = self.app.getGlobalConfig().get("main", "plugin_ical_export_dir", "")

        self.tfPath = wx.TextCtrl(self, -1, pt)

        mainsizer = wx.BoxSizer(wx.VERTICAL)

        inputsizer = wx.BoxSizer(wx.HORIZONTAL)
        inputsizer.Add(wx.StaticText(self, -1, _(u"Export dir:")), 0,
                wx.ALL | wx.EXPAND, 5)
        inputsizer.Add(self.tfPath, 1, wx.ALL | wx.EXPAND, 5)
        mainsizer.Add(inputsizer, 0, wx.EXPAND)

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
        pt = self.tfPath.GetValue()

        self.app.getGlobalConfig().set("main", "plugin_ical_export_dir", pt)


