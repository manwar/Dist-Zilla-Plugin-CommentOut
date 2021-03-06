use strict;
use warnings;
use 5.014;

package Dist::Zilla::Plugin::CommentOut {

  # ABSTRACT: Comment out code in your scripts and modules

=head1 SYNOPSIS

 [CommentOut]
 id = dev-only

=head1 DESCRIPTION

This plugin comments out lines of code in your Perl scripts or modules with
the provided identification.  This allows you to have code in your development
tree that gets commented out before it gets shiped by L<Dist::Zilla> as a
tarball.

=head1 MOTIVATION

(with brief editorial)

I use perlbrew and/or perls installed in funny places and I'd like to be able to run
executables out of by git checkout tree without invoking C<perl -Ilib> on
every call.  To that end I write something like this:

 #!/usr/bin/env perl
 
 use strict;
 use warnings;
 use lib::findbin '../lib';  # dev-only
 use App::MyApp;

That is lovely, except that the main toolchain installers EUMM and MB will
convert C</usr/bin/perl> but not C</usr/bin/env perl> to the correct perl
when the distribution is installed.  For some reason this is
a bug in everyone who uses this common convention but not the toolchain.  There
is a handy plugin C<[SetScriptShebang]> that solves that problem but the 
C<use lib::findbin '../lib';> is problematic because C<../lib> relative to
the install location might not be right!  With both C<[SetScriptShebang]>
and this plugin, I can fix both problems:

 [SetScriptShebang]
 [CommentOut]

And my script will be converted to:

 #!perl
 
 use strict;
 use warnings;
 #use lib::findbin '../lib';  # dev-only
 use App::MyApp;

Which is the right thing for CPAN.  Since lines are commented out, line numbers
are retained.

=head1 PROPERTIES

=head2 id

The comment id to search for.

=head2 remove

Remove lines instead of comment them out.

=cut

  use Moose;
  with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
      default_finders => [ ':ExecFiles', ':InstallModules' ],
    },
  );

  use namespace::autoclean;
  
  has id => (
    is      => 'rw',
    isa     => 'Str',
    default => 'dev-only',
  );
  
  has remove => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
  );
  
  sub munge_files
  {
    my($self) = @_;
    $DB::single = 1;
    $self->munge_file($_) for @{ $self->found_files };
    return;
  }
  
  sub munge_file
  {
    my ($self, $file) = @_;
    
    return if $file->is_bytes;
    
    $self->log("commenting out @{[ $self->id ]} in @{[ $file->name ]}");
    
    my $content = $file->content;
    
    my $id = $self->id;
    
    if($self->remove)
    { $content =~ s/^(.*?#\s*\Q$id\E\s*)$/\n/mg }
    else
    { $content =~ s/^(.*?#\s*\Q$id\E\s*)$/#$1/mg }
    
    $file->content($content);
    return;
  }
  
  __PACKAGE__->meta->make_immutable;

}

1;
