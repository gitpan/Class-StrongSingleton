#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { 
    use_ok('Class::StrongSingleton');
}

can_ok("Class::StrongSingleton", '_init');
can_ok("Class::StrongSingleton", 'instance');
can_ok("Class::StrongSingleton", 'DESTROY');

{
	package My::Singleton;
	
	our @ISA = 'Class::StrongSingleton';
	
	sub new {
		my $self = bless({});
		$self->_init();
		return $self;
	}
}

my $instance = My::Singleton->new();
isa_ok($instance, 'My::Singleton');
isa_ok($instance, 'Class::StrongSingleton');

# is our instance safe
is($instance, My::Singleton->new(),      '... got the same object');
is($instance, $instance->new(),          '... got the same object');
is($instance, My::Singleton->instance(), '... got the same object');
is($instance, $instance->instance(),     '... got the same object');

# make sure DESTROY works
$instance->DESTROY();

# NOTE: let instance create the singleton this time
isnt($instance, My::Singleton->instance(), '... got the same object');
isnt($instance, $instance->instance(),     '... got the same object');
isnt($instance, My::Singleton->new(),      '... got the same object');
isnt($instance, $instance->new(),          '... got the same object');

# check some errors
eval {
	$instance->_init();
};
like($@, qr/Illegal Operation \: _init can only be called by a subclass of Class\:\:StrongSingleton/, 
	'... got the error we expected');

# check some dumb coding errors too

{
	package My::Broken::Singleton;
	
	our @ISA = 'Class::StrongSingleton';
	
	sub new {}
	
	sub new_Class_init {
		my $class = shift;
		$class->_init();
	}
	
	sub new_doubleInit {
		my $class = shift;
		my $self = bless({}, $class);
		$self->_init();
		$self->_init();
		return $self;
	}	
	
}

eval {
	My::Broken::Singleton->new_Class_init();
};
like($@, qr/Illegal Operation \: _init can only be called as an instance method/, 
	'... got the error we expected');

# clear things out
My::Broken::Singleton->DESTROY();

eval {
	My::Broken::Singleton->new_doubleInit();
};
like($@, qr/Illegal Operation \: cannot call _init with a valid Singleton instance/, 
	'... got the error we expected');

# and some not so dumb coding errors

{
	package My::NextBroken::Singleton;
	
	our @ISA = 'Class::StrongSingleton';
	
	sub withoutNew {
		my $class = shift;
		my $self = bless({}, $class);
		$self->_init();
		return $self;
	}
	
}
# now test it
eval {	
	My::NextBroken::Singleton->withoutNew();
};
like($@, qr/Illegal Operation \: Singleton objects must have a \'new\' method/, 
	'... got the error we expected');

