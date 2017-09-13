macrobuild
==========

macrobuild is a software build and release framework for "macro" tasks.

There are many build frameworks for "micro" tasks, such as make, ant,
maven and others. They do a great job at compiling executables and
tasks like that. They aren't so great at pulling together larger
assemblies of things, such as a collection of executables or packages
on a disk (each of which could be created through a "micro" build).

macrobuild was created for the UBOS build and release process,
where we pull together and test a large number of packages. Each of which
is typically built with ant, make, makepkg and/or other tools, as
macrobuild does not even attempt to address "micro" build requirements.

Contributions are welcome.

# Philosphy:

A macrobuild run runs a single Task whose name is specified on the
command-line, like this:
```
macrobuild <taskname>
```
This single task is either a basic Task, or a composite Task. If it
is a composite Task, running the composite Task will run its sub-Tasks,
which in turn again may be basic or composite. This way, larger and
larger Tasks can be assembled.

Each Task may have inputs and outputs. Outputs generally are made
available to subsequent tasks.

For example, a Sequential composite task might first invoke a
Task that determines a set of packages that need to be rebuilt, and
then invoke a second Task that takes the list of packages that need
to be rebuilt, and rebuilds it. A third task may take the output
and e-mail it to a particular address.

macrobuild comes with a set of common pre-defined Tasks, but writing
custom Tasks is common. Writing a Task generally involves subclassing
the Perl class Task.pm and implementing an overridden `run` method.

# How to run

## On UBOS:
```
sudo pacman -S macrobuild
macrobuild <taskname>
```

## On Arch Linux or a derivative:

Add the UBOS tools per
[UBOS documentation](http://ubos.net/docs/developers/install-ubos-tools.html).
Then:

```
sudo pacman -S macrobuild
macrobuild <taskname>
```
