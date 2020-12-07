---
layout: docs
title: Installing
permalink: /installing/
categories: docs toc
order: 1
---

{% raw %}

Instructions for installing Nelua on Windows or Linux.
{: .lead}

To install Nelua you need a system with the following:

* Git (for cloning Nelua)
* A C compiler (GCC or Clang are recommended)
* Build tools (such as make)
* GDB debugger (in case you want to debug runtime errors)

## Installing on Linux

Use your system's package manager to install all of the required tools first,
then clone, compile the dependencies, and install using make.

For example, in Ubuntu:

```bash
sudo apt-get install build-essential git gcc gdb
git clone https://github.com/edubart/nelua-lang.git && cd nelua-lang
sudo make install
```

This will install to `/usr/local` by default.
You can install somewhere else using the `PREFIX` argument.
For example, suppose you want to install in your home directory.
Then you would use `sudo make install PREFIX=~/nelua`,
and the Nelua compiler would be available at `~/nelua/bin/nelua`.

Alternatively you can run the `nelua.sh` file to run Nelua directly if you do not wish
to install it anywhere on your system.

Proceed to the [testing section](#testing).

## Installing on Windows

MSYS2 is the recommended and supported environment to use Nelua on Windows.
Although you could use other tools, MSYS2 makes using Nelua very easy on Windows,
plus there are many useful C packages on MSYS2 that you can install with ease, such as
SDL2.

Download and install [MSYS2](https://www.msys2.org/).
After installing open the **64 bit terminal**, that is,
**msys64**, and update:

```bash
pacman -Syu
```

You may need close and reopen the terminal and update a second time using the same command.

Now install all the required tools first,
then clone, compile the dependencies, and install using make.

```bash
pacman -S base-devel git mingw-w64-x86_64-toolchain gdb
git clone https://github.com/edubart/nelua-lang.git && cd nelua-lang
make install
```

Proceed to the [testing section](#testing).

## Installing with LuaRocks

If you already have a [LuaRocks](https://luarocks.org/)
installation, you can install Nelua with it.
However, this is not recommended,
because it will not use the Lua interpreter bundled with Nelua,
so you will have worse compile speeds, and if your system does not have Lua 5.3+
it will not work. Also, trying this on Windows is not recommend
because getting LuaRocks to work there is troublesome.

With a proper LuaRocks setup do:

```bash
luarocks install https://raw.githubusercontent.com/edubart/nelua-lang/master/rockspecs/nelua-dev-1.rockspec
```

After installing, Nelua should be available in the LuaRocks binary path, ready to be run.

Proceed to the [testing section](#testing).

## Testing

Nelua should be installed. Run `nelua -h` in your terminal to check if it is working.
If doesn't work, your environment `PATH` variable is missing the `bin` folder of the Nelua installation.
Add it or find and execute the full path to the installed Nelua compiler to use it.

Run the hello world example:

```bash
nelua examples/helloworld.nelua
```

You can run any file in the `examples` or `tests` directories,
play with them to test or to learn how to code in Nelua.

The most interesting examples are perhaps the graphical ones,
such as `snakesdl.nelua` and `condots.nelua`.

To run the Snake SDL game demo, for example, you will need to have the SDL2 library installed.
Install it using your system's package manager and run the example:

```bash
# install SDL2 on MSYS2
pacman -S mingw-w64-x86_64-SDL2
# install SDL2 on Ubuntu
sudo apt-get install libsdl2-dev
# run it
nelua examples/snakesdl.nelua
```

<a href="/tutorial/" class="btn btn-outline-primary btn-lg float-right">Tutorial >></a>

{% endraw %}
