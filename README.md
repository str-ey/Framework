Hello,

Today I present to you my new framework.
It's a mix between ESX-V1 Final, ESX-LEGACY and CALIF (much more optimized and with more options).

Make sure you have configured your server.cfg like this:

add_ace resource.es_extended command allow
add_principal group.admin group.user
add_ace group.admin command allow

Then go to server/classes/group.lua and add your groups at the bottom of the code as in server.cfg:

ESX.AddGroup('user', '')
ESX.AddGroup('admin', 'user')

Make sure you have an empty one before the default group (ex: 'user', 'leave empty')

Start your resource making sure to use oxmysql