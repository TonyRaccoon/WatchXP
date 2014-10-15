WatchXP
=======

Ever get tired of constantly asking your friend or leveling buddy "how close to leveling are you?" or "how many bars in are you?". If so, WatchXP is here to help. Whenever you're in a party with someone else who also has WatchXP installed (more on that below) and isn't max-level, you will see where they are in experience on your experience bar. If you're max level and don't have an experience bar, it'll show on your reputation bar instead. If they're 6 bars into level 45, you'll see a marker at the 6th bar of your experience bar representing them. It'll update automatically as they gain experience, meaning you always know exactly how ahead or behind you they are, and how close they are to dinging!

Unfortunately, there is no way to retrieve how much experience another player has using only the WoW API, so someone else needs WatchXP for you to see their experience. Maybe someday it will be possible without WatchXP, meaning you'll see EVERYONE in your party on your experience bar, even if they don't have WatchXP!

You can also request a marker from a person not in your group (either directly, or through Battle.net), but it won't update automatically. The other person also needs to have WatchXP installed.

You can customize the texture, size, and vertical offset of the marker, and the font face, size, color, and vertical offset of the label (or hide it entirely). You can also control when the label displays the other person's level and realm - either never, always, or only if they differ from your level or realm. Labels will flip around when two markers are near each other to avoid overlapping labels. If there's many markers though, some overlapping is unavoidable.

As of 3.0, support for localization is available. Please submit translations [here](http://wow.curseforge.com/addons/watchxp/localization/)

Submit bugs/suggestions [here](http://wow.curseforge.com/addons/watchxp/create-ticket/)

Commands:
**All the ask commands require the other person to have WatchXP installed!**

* /wxp cfg/config/win/settings/opt/options - Show the configuration panel
* /wxp label[s] - Show the label configuration panel
* /wxp ask \<playername[-realm]\> - Request a marker for a player not in your group
* /wxp ask \<Firstname\> \<Lastname\> - Request a marker for a Battle.net friend
* /wxp ask \<n\> - Request a marker for the nth Battle.net friend in your friend's list
* /wxp toggle - Show or hide WatchXP
* /wxp debug - Show or hide debug information in chat
* /wxp refresh/clear/wipe - Remove all markers from your bar and start fresh. If you're in a party, the markers will be re-created.
* /wxp updatewarning/updwarn - Show or hide warnings when someone in your party is using an incompatible version of WatchXP
* /wxp v/ver/vers/version - Print the version number and date of your copy of WatchXP

Main page: http://www.curse.com/addons/wow/watchxp  
GitHub page: https://github.com/tony311/WatchXP  
Discussion thread: http://forums.curseforge.com/showthread.php?t=21225
