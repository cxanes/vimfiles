#!/usr/bin/python

from stickies.Stickies import Stickies
import time

def print_message(message):
    print message

def print_reply(reply):
    print ">", reply, "\n"

def main():
    stickies = Stickies(event_callback = print_message)
    stickies.start()

    print_reply(stickies.send('do register'))

    print_reply(stickies.send('do new sticky sticky1'))
    print_reply(stickies.send('do new sticky sticky2'))

    time.sleep(10)
    print_reply(stickies.send('do deregister'))

    stickies.stop()

main()
