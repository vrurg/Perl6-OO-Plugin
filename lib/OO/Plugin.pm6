use v6;

module OO::Plugin:ver<0.0.0>:auth<cpan:VRURG> {
    use OO::Plugin::Exception;

    our proto plugin-meta (|) is export {*}
    multi plugin-meta ( *%meta ) {
        use OO::Plugin::Registry;
        Plugin::Registry.instance.plugin-meta( %meta, CALLER::<::?CLASS> )
    }
    multi plugin-meta ( %meta ) {
        use OO::Plugin::Registry;
        Plugin::Registry.instance.plugin-meta( %meta, CALLER::<::?CLASS> )
    }

    sub plug-last ( $rc? ) is export {
        CX::Plugin::Last.new(
            plugin => $*CURRENT-PLUGIN,
            :$rc,
        ).throw
    }
}

sub EXPORT {
    use nqp;
    use NQPHLL:from<NQP>;
    use OO::Plugin::Class;
    use OO::Plugin::Registry;
    use OO::Plugin::Declarations;
    use OO::Plugin::Metamodel::PluginHOW;
    use OO::Plugin::Metamodel::PlugRoleHOW;

    my role PluginGrammar {
        token package_declarator:sym<plugin> {
            :my $*OUTERPACKAGE := self.package;
            :my $*PKGDECL := 'plugin';
            :my $*LINE_NO := HLL::Compiler.lineof(self.orig(), self.from(), :cache(1));
            :my $*CURRENT-PLUGIN-CLASS; # Must be set by corresponding HOW
            :my %*CURRENT-PLUGIN-META;
            <sym><.kok> <package_def>
            <.set_braid_from(self)>
        }

        token package_declarator:sym<plug-class> {
            :my $*OUTERPACKAGE := self.package;
            :my $*PKGDECL := 'role';
            :my $*LINE_NO := HLL::Compiler.lineof(self.orig(), self.from(), :cache(1));
            :my $*IN-PLUG-CLASS = True;
            :my @*PLUG-CLASS-EXTENDING;
            <sym><.kok>
            {
                use nqp;
                note "DECLARAND IN plug-class: ", $*DECLARAND.^name;
                note "PACKAGE IN plug-class: ", $*PACKAGE.^name;
                self.panic( "plug-class must only be declared within scope of a plugin" )
                    unless try $*CURRENT-PLUGIN-CLASS.HOW ~~ OO::Plugin::Metamodel::PluginHOW;
                $*LANG.set_how('role', OO::Plugin::Metamodel::PlugRoleHOW);
            }
            <package_def>
            <.set_braid_from(self)>
            {
                # XXX Possible problem if package_def fails - not sure if role's HOW would be restored.
                $*LANG.set_how('role', Metamodel::ParametricRoleHOW);
            }
        }

        rule trait_mod:sym<for> {
            [ <sym> {} <.in-plug-class( 'for' )> ]
            <ptype-name-list( 'class' )>
        }

        token in-plug-class ( Mu $sym ) {
            {
                # Declarand is NQPMu upon trait declarations when in package declaration.
                # NOTE We consider any NQP type in $*DECLARAND as 'uninitialized' because this is not a Perl6 role
                # declaration by definition.
                ( $*IN-PLUG-CLASS && !nqp::istype( $*DECLARAND, Mu ) ) || self.panic( "Modificator '$sym' is only applicable to a plug-class" )
            }
        }

        rule trait_mod:sym<after> {
            <sym> <.in-plugin( 'after' )>
            <ptype-name-list('plugin')>
        }

        rule trait_mod:sym<before> {
            <sym> <.in-plugin( 'before' )>
            <ptype-name-list('plugin')>
        }

        rule trait_mod:sym<demand> {
            <sym> <.in-plugin( 'demand' )>
            <ptype-name-list('plugin')>
        }

        token in-plugin ( Str:D $sym ) {
            {
                # Declarand is NQPMu upon trait declarations when in package declaration.
                # NOTE We consider any NQP type in $*DECLARAND as 'uninitialized' because this is not a Perl6 role
                # declaration by definition.
                ( $*PKGDECL eq 'plugin' and !nqp::istype( $*DECLARAND, Mu ) ) || self.panic( "Modificator '$sym' is only applicable to a plugin" )
            }
        }

        rule ptype-name-list ( Mu:D $name-type ) {
            ( <longname> | <.panic("Expecting a $name-type here")> )+ % ','
        }
    }

    my role PluginActions {

        sub mkey ( Mu $/, Str:D $key ) {
            nqp::atkey(nqp::findmethod($/, 'hash')($/), $key)
        }

        method package_declarator:sym<plugin>(Mu $/) {
            $/.make( mkey($/, 'package_def').ast );
        }

        method package_declarator:sym<plug-class>(Mu $/) {
            $/.make( mkey($/, 'package_def').ast );
        }

        method ptype-name-list ( Mu $/ ) {
            $/.make: $/.list[0].list.map: { mkey( $_, 'longname' ).Str };
        }

        method trait_mod:sym<for> (Mu $/) {
            @*PLUG-CLASS-EXTENDING.append: mkey( $/, 'ptype-name-list' ).ast;
        }

        method trait_mod:sym<after> ( Mu $/ ) {
            %*CURRENT-PLUGIN-META<after>.append: mkey( $/, 'ptype-name-list' ).ast;
        }

        method trait_mod:sym<before> ( Mu $/ ) {
            %*CURRENT-PLUGIN-META<before>.append: mkey( $/, 'ptype-name-list' ).ast;
        }

        method trait_mod:sym<demand> ( Mu $/ ) {
            %*CURRENT-PLUGIN-META<demand>.append: mkey( $/, 'ptype-name-list' ).ast;
        }
    }

    unless $*LANG.^does( PluginGrammar ) {
        $*LANG.set_how( 'plugin', OO::Plugin::Metamodel::PluginHOW );
        $ = $*LANG.define_slang(
            'MAIN',
            $*LANG.HOW.mixin( $*LANG.WHAT, PluginGrammar ),
            $*LANG.actions.^mixin(PluginActions)
        );
    }


    return %(
        OO::Plugin::Declarations::EXPORT::ALL::,
        'Plugin' => Plugin,
        'PlugRecord' => PlugRecord,
        # '&plugin-meta' => &OO::Plugin::plugin-meta,
    );
}
