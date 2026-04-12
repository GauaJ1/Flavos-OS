import gi
gi.require_version('Gtk', '3.0')
gi.require_version('Wnck', '3.0')
from gi.repository import Gtk, Gdk, Wnck
import sys

Wnck.set_client_type(Wnck.ClientType.PAGER)
screen = Wnck.Screen.get_default()
if not screen:
    print("NO SCREEN")
    sys.exit(1)

tasklist = Wnck.Tasklist.new()
print(tasklist)
