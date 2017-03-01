#Liskel OS

A basic [OpenComputers][1] operating system that is fast and lightweight.

===
Current version: OS 2.1

Previous version: OS 1.8

##Features
 * Basic lightweight file input and output library.
 * Basic lightweight graphics library.
 * Shuts down and starts up instantly on any computer.
 * Console history and command recall function.
 * Scroll up and down your console history using mousewheel (requires compatible monitor).
 * Load custom libraries and programs using liskel's built in autorun capability.
 * Lightweight enough that it can run on a potato.
 * Does not change much of the core lua libraries and does not load any unnecessary libraries into memory.
 * Perfect as a test bootloader for another operating system.
 * Basically a barebones operating system designed for use with developing custom BIOS'es and OS'es
 * Liskel 2.1 offers a modular design and an improved system management

##How to use
*Note: Some commands in OpenOS are not available in Liskel since they are implemented in OpenOS and thus are not
in the core libraries.*

*Based on OS 2.1*

Print to console:
```lua
print("hello world!")
```

Getting a file handler
```lua
-- returns a file handler which can be used as a parameter for other commands
f.open("openfile.txt")
```

Reading a file:
```lua
-- read file contents to console
print(f.readfile(f.open("afile.txt")))
```

Writing to file:
```lua
f.write(f.open("newfile.txt"),"text to write out")
```

Run a lua file:
```lua
-- no need to put .lua on the end of the filename
f.run("luafile")
```

Print a table
```lua
-- prints the table named 'mytable'
print(mytable)

-- alternatively this can be used to print out the functions in a table like 'component'
-- examples:
print(component) -- prints out functions provided by component
print(f) -- prints all functions provided by the built in file IO library
print(component.filesystem.address) -- prints out filesystem UUID
print(_G) -- prints out all functions and tables in global (2.1 only)
````
And much more! Just use the print feature above!

[1]:https://oc.cil.li/
