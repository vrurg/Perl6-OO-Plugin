NAME
====

OO::Plugin – framework for working with OO plugins.

SYNOPSIS
========

    use OO::Plugin;
    use OO::Plugin::Manager;

    class Foo is pluggable {
        has $.attr;
        method bar is pluggable {
            return 42;
        }
    }

    plugin Fubar {
        method a-bar ( $msg ) is plug-around( Foo => 'bar' ) {
            $msg.set-rc( pi ); # Will override &Foo::bar return value and prevent its execution.
        }
    }

    my $manager = OO::Plugin::Manager.new.initialize;
    my $instance = $manager.create( Foo, attr => 'some value' );
    say $instance.bar;  # 3.141592653589793

DESCRIPTION
===========

With this framework any application can have highly flexible and extensible plugin subsystem with which plugins would be capable of:

  * method overriding

  * class overriding (inheriting)

  * callbacks

  * asynchronous event handling

The framework also supports:

  * automatic loading of plugins with a predefined namespace

  * managing plugin ordering and dependencies

Not yet supported but planned for the future is plugin compatibility management.

Read more in [OO::Plugin::Manual](https://github.com/vrurg/Perl6-OO-Plugin/blob/v0.0.903/docs/md/OO/Plugin/Manual.md).

SEE ALSO
========

[OO::Plugin::Manual](https://github.com/vrurg/Perl6-OO-Plugin/blob/v0.0.903/docs/md/OO/Plugin/Manual.md), [OO::Plugin](https://github.com/vrurg/Perl6-OO-Plugin/blob/v0.0.903/docs/md/OO/Plugin.md), [OO::Plugin::Manager](https://github.com/vrurg/Perl6-OO-Plugin/blob/v0.0.903/docs/md/OO/Plugin/Manager.md), [OO::Plugin::Class](https://github.com/vrurg/Perl6-OO-Plugin/blob/v0.0.903/docs/md/OO/Plugin/Class.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

