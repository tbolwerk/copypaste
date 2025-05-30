# CopyPaste

This application is heavily inspired by Paste Ref: https://pasteapp.io/about

Currently only support MacOS, it requires permissions set privacy / security enabled for terminal, when ran in terminal. Otherwise an error occurs eventTap cannot be created. Mainly the input monitoring must be enabled for the terminal that is used.

It reads from system event CMD-C to write pbpaste to file.


It currently supports 10 entries.

Using CMD-2 followed by CMD-V will paste the content of entry 2.

CMD-[N]
N:= [0..9]

With CMD SHIFT V a window will pop up, showing a entry select using above mentioned selection method CMD-[1..9]


## Debian12 X11
apt-get install libxtst-dev